#!/usr/bin/env python3
r"""Plumbing: mechanically diff every number/percentage/citation in the paper
against the deterministic run and against internal arithmetic. Built because
hand-editing kept leaving stale numbers across passes (Table 3, a stray "7", ...).

WHAT IT CHECKS
  A. Ground-truth counts  — proved/refuted/partial/pipeline_failure/no_encodable/
                            checking/total re-derived from the actual pipeline, and
                            every textual mention of the refuted/partial counts must
                            equal them (catches a stray "refuted 7" anywhere).
  B. Fraction vs percent  — every explicit "N/M (X%)" or "N of M (X%)" must satisfy
                            round(N/M*100,1) == X (catches 76.8 vs 76.3, 23.1 vs 24).
  C. Citations            — every \cite{key} must resolve in the .bib (catches Pnueli).
  D. Refutation table     — the row count in tab:refuted must equal the refuted count.
  E. Targeted asserts     — specific computed values the reviewer flagged that have
                            no literal fraction in the text (kept explicit, sourced).
  F. Prompt identity      — appendix A.1 states the feedback-loop and baseline system
                            prompts are "character-identical". That is a falsifiable
                            claim over three hardcoded copies (ironproof_core.py twice,
                            run_baseline.py once) with nothing enforcing it. This guard
                            re-derives it from source so the claim cannot silently rot
                            the day someone edits one copy.
  G. LOC stats            — the min/max/median/mean line counts of the full benchmark
                            and the proved fragment are quoted in prose with no guard;
                            re-derived from the run (non-empty-line method) and confronted.
                            Caught the stale proved-fragment mean (paper 31, run 35).

Exit 0 = clean, 1 = at least one inconsistency, 2 = could not measure.
Run:  PYTHONHASHSEED=0 python3 papers/check_paper_consistency.py
"""
import os
import re
import statistics
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
TEX = os.path.join(HERE, "ironproof_cobol.tex")
BIB = os.path.join(HERE, "ironproof_cobol.bib")
CORPUS = os.path.join(REPO, "benchmark", "cobol_programs")
REQUIRED_SEED = "0"


def ground_truth():
    """Re-run the pipeline; return authoritative counts (no cache).

    Classification comes from papers/classify.py, the ONE definition every paper
    script imports (2026-09-30: four copies had drifted apart in silence). LOC =
    non-empty physical lines, the count under which the benchmark statistics are
    stated; the proved fragment is collected under the same method.
    """
    sys.path.insert(0, HERE)
    from classify import counts, iter_corpus
    recs = list(iter_corpus(CORPUS))
    k = counts(recs)
    c = {"total": k["total"], "proved": k["proved"], "refuted": k["refuted"],
             "partial": k["partial"], "pipeline_failure": k["pipeline_failure"],
             "no_encodable": k["no_encodable_output"], "checking": k["checking_path"]}
    indep = [r for r in recs if r["independent"] and r["state"] != "no_encodable_output"]
    c["indep_checking"] = len(indep)
    c["indep_proved"] = sum(1 for r in indep if r["state"] == "proved")
    c["indep_failure"] = sum(1 for r in indep if r["state"] == "pipeline_failure")
    c["all_loc"] = [r["loc"] for r in recs]
    c["proved_loc"] = [r["loc"] for r in recs if r["state"] == "proved"]
    return c


def check_counts(tex, gt):
    """Every textual mention of the TOTAL refuted / partial count must equal ground
    truth. The provenance paragraph is excluded: it legitimately reports the
    independent-subset counts, checked separately in check_targeted."""
    # drop the provenance paragraph (independent-subset numbers, not totals)
    texg = re.sub(r'\\paragraph\{Provenance of the proof rate\.\}.*?(?=\\paragraph\{)',
                  '', tex, flags=re.DOTALL)
    # A sentence dated to an earlier snapshot reports THAT snapshot, not the current
    # total; it must say so in its own words (the date), or it is checked as current.
    texg = re.sub(r'[^.]*(2026-08-26|April 2026|in April)[^.]*\.', '', texg)
    problems = []
    ref_pats = [r'(\d+)\s+are refuted', r'refute\s+(\d+)\s+by', r'The\s+(\d+)\s+refutations',
                r'the\s+(\d+)\s+counterexamples', r'(\d+)\s+defects of its own',
                r'(\d+)\s+programs on which Z3 refuted', r'It is reached on\s+(\d+)\s+programs',
                r'introduces\s+(\d+)\s+defects', r'Z3 refuted\s+(\d+)\s+of',
                r'SAT \(counterexample found\)\s*&\s*(\d+)',  # tab:rq2 cell
                r'Six programs are refuted', r'Seven programs are refuted']
    for pat in ref_pats:
        for m in re.finditer(pat, texg):
            if not m.groups():  # word-form guard ("Seven programs are refuted")
                word = m.group(0).split()[0]
                n = {"Six": 6, "Seven": 7}.get(word)
            else:
                n = int(m.group(1))
            if n is not None and n != gt["refuted"]:
                problems.append(f"[refuted] '{m.group(0).strip()}' says {n}, run={gt['refuted']}")
    part_pats = [r'(\d+)\s+match partially', r'(\d+)\s+partially matched', r'(\d+)\s+partial[,\.]',
                 r'Partial \(some outputs (?:unmatched|not verified)\)\s*&\s*(\d+)',
                 r'(\d+)\s+(?:are\s+)?(?:only\s+)?partially verified']
    for pat in part_pats:
        for m in re.finditer(pat, texg):
            n = int(m.group(1))
            if n != gt["partial"]:
                problems.append(f"[partial] '{m.group(0).strip()}' says {n}, run={gt['partial']}")
    return problems


def check_fraction_percent(tex):
    """Every 'N of M (X%)' or 'N/M (X%)' must satisfy round(N/M*100,1)==X."""
    problems = []
    # normalise LaTeX thousands separators 1{,}687 -> 1687 for parsing
    def num(s): return int(re.sub(r'\D', '', s))
    pat = re.compile(r'(\d[\d,]*(?:\{,\}\d+)*)\s*(?:/|\s+of\s+|\s+of the\s+)\s*(\d[\d,]*(?:\{,\}\d+)*)[^()]{0,40}?\(([\d.]+)\\?%\)')
    for m in re.finditer(pat, tex):
        stated = m.group(3)
        n, d, pct = num(m.group(1)), num(m.group(2)), float(stated)
        if d == 0: continue
        real = n / d * 100
        # allow whole-number rounding when the text states an integer percentage
        expected = round(real, 1) if '.' in stated else float(round(real))
        if abs(expected - pct) > 0.05:
            problems.append(f"[frac%] '{m.group(0).strip()[:60]}' : {n}/{d}={round(real,1)}% but text says {pct}%")
    return problems


def check_citations(tex, bibtext):
    problems = []
    keys = set()
    for m in re.finditer(r'\\cite[a-z]*\{([^}]+)\}', tex):
        for k in m.group(1).split(','):
            keys.add(k.strip())
    bibkeys = set(re.findall(r'@\w+\{([^,]+),', bibtext))
    for k in sorted(keys):
        if k and k not in bibkeys:
            problems.append(f"[cite] \\cite{{{k}}} not found in .bib")
    return problems


def check_refuted_table(tex, gt):
    problems = []
    m = re.search(r'\\label\{tab:refuted\}.*?\\begin\{tabular\}(.*?)\\end\{tabular\}', tex, re.DOTALL)
    if not m:
        problems.append("[table] tab:refuted not found")
        return problems
    body = m.group(1)
    rows = [r for r in body.split(r'\\') if r'\texttt' in r and 'Program' not in r and 'Refuted' not in r]
    cap = re.search(r'\\caption\{([^}]*(?:\{[^}]*\}[^}]*)*)\}\s*\\label\{tab:refuted\}', tex)
    if cap and "2026-08-26" in cap.group(1):
        # Historical table: it may list refutations the current run no longer has,
        # but then every row must say how the current pipeline classifies it.
        if not re.search(r'\\textbf\{Now\}', body):
            problems.append("[table] tab:refuted is dated but has no 'Now' column")
        return problems
    if len(rows) != gt["refuted"]:
        problems.append(f"[table] tab:refuted has {len(rows)} program rows, refuted count={gt['refuted']}")
    return problems


def latex_int(n):
    """2345 -> 2{,}345, the paper's thousands separator."""
    return f"{n:,}".replace(",", "{,}")


def check_ground_truth_anchors(tex, gt):
    """Key run numbers must appear as claimed. Every pattern is computed from the
    run: a pattern written with a number in it keeps confronting the old number."""
    problems = []
    rate = f"{gt['proved'] / gt['checking'] * 100:.1f}" if gt["checking"] else "NaN"
    anchors = {
        "proved": (gt["proved"], rf'{gt["proved"]}\D{{0,20}}{re.escape(rate)}\\%'),
        "checking": (gt["checking"], rf'{gt["checking"]} programs (that enter|entering) the checking path'),
        "no_encodable": (gt["no_encodable"], rf'{re.escape(latex_int(gt["no_encodable"]))} (programs )?yield no'),
        "total": (gt["total"], re.escape(latex_int(gt["total"]))),
        "pipeline_failure": (gt["pipeline_failure"], rf'{gt["pipeline_failure"]} fail inside our'),
    }
    for key, (val, pat) in anchors.items():
        if not re.search(pat, tex):
            problems.append(f"[anchor] expected {key}={val} pattern /{pat}/ not found in .tex")
    return problems


def check_targeted(gt, tex):
    """Reviewer-flagged computed values: the provenance figures must appear in the
    text exactly as the run computes them."""
    problems = []
    ick = gt["indep_checking"]
    if ick:
        rate = f"{gt['indep_proved'] / ick * 100:.1f}"
        want = f"\\textbf{{{gt['indep_proved']} prove equivalent ({rate}\\%)}}"
        if want not in tex:
            problems.append(f"[targeted] independent proof rate {gt['indep_proved']}/{ick}={rate}% "
                            f"not stated as '{want}' in the provenance paragraph")
    want = f"{gt['indep_failure']} of the {gt['pipeline_failure']} pipeline failures"
    if want not in tex:
        problems.append(f"[targeted] '{want}' not found -- independent share of our failures")
    return problems


def check_loc_stats(tex, gt):
    """The LOC distribution numbers (min/max/median/mean of the full benchmark and of
    the proved fragment) are quoted in prose and no other guard covers them, so they
    drift silently when the corpus changes -- exactly what happened to the proved-
    fragment mean (paper said 31, actual 35). Re-derive from the run and confront.
    Method = non-empty physical lines (ground_truth), the only count under which the
    full-benchmark quartet 4/7693/18/68 all reproduce."""
    problems = []
    allx, prx = gt.get("all_loc") or [], gt.get("proved_loc") or []
    if not allx or not prx:
        problems.append("[loc] LOC lists empty -- cannot MEASURE (ground_truth changed?)")
        return problems

    def stat(xs):
        return {"mn": min(xs), "mx": max(xs),
                    "med": round(statistics.median(xs)), "mean": round(statistics.mean(xs))}
    full, prov = stat(allx), stat(prx)

    def n(s):  # normalise LaTeX 1{,}762 -> 1762
        return int(re.sub(r'\D', '', s))

    # Full benchmark: "range from 4 to 7{,}693 lines (median: 18, mean: 68)"
    m = re.search(r'range from (\d[\d,{}]*) to (\d[\d,{}]*) lines '
                  r'\(median: (\d+), mean: (\d+)\)', tex)
    if not m:
        problems.append("[loc] full-benchmark stat sentence not found -- cannot confront")
    else:
        for label, got, want in [("min", full["mn"], n(m.group(1))),
                                 ("max", full["mx"], n(m.group(2))),
                                 ("median", full["med"], int(m.group(3))),
                                 ("mean", full["mean"], int(m.group(4)))]:
            if got != want:
                problems.append(f"[loc] full {label}: paper={want} run={got}")

    # Proved fragment appears twice; both must agree with the run.
    #  (a) "proved fragment (587 programs) ranges from 9 to 1{,}762 lines (median: 21, mean: 31)"
    m = re.search(r'proved fragment \(\d[\d,{}]* programs\) ranges from (\d[\d,{}]*) '
                  r'to (\d[\d,{}]*) lines \(median: (\d+), mean: (\d+)\)', tex)
    if not m:
        problems.append("[loc] proved-fragment stat sentence (Benchmark) not found")
    else:
        for label, got, want in [("min", prov["mn"], n(m.group(1))),
                                 ("max", prov["mx"], n(m.group(2))),
                                 ("median", prov["med"], int(m.group(3))),
                                 ("mean", prov["mean"], int(m.group(4)))]:
            if got != want:
                problems.append(f"[loc] proved(Benchmark) {label}: paper={want} run={got}")
    #  (b) "median 21 lines, mean 31, max 1{,}762 lines"
    m = re.search(r'median (\d+) lines, mean (\d+), max (\d[\d,{}]*) lines', tex)
    if not m:
        problems.append("[loc] proved-fragment stat sentence (Threats) not found")
    else:
        for label, got, want in [("median", prov["med"], int(m.group(1))),
                                 ("mean", prov["mean"], int(m.group(2))),
                                 ("max", prov["mx"], n(m.group(3)))]:
            if got != want:
                problems.append(f"[loc] proved(Threats) {label}: paper={want} run={got}")
    return problems


def check_prompt_identity(tex):
    """Appendix A.1 claims the LLM system prompt is 'character-identical' across the
    feedback-loop path (ironproof_core.py) and the baseline (run_baseline.py). Three
    hardcoded copies exist and nothing enforces they agree; this re-derives the claim
    from source. Only fires when the paper actually makes the claim (so removing the
    sentence retires the guard rather than orphaning it)."""
    problems = []
    if "character-identical" not in tex:
        return problems  # claim not made -> nothing to back
    src_files = [os.path.join(REPO, "ironproof_core.py"),
                 os.path.join(REPO, "benchmark", "run_baseline.py")]
    prompts = []
    for path in src_files:
        if not os.path.exists(path):
            problems.append(f"[prompt] source absent, cannot MEASURE identity: {path}")
            return problems
        with open(path, encoding="utf-8") as fh:
            src = fh.read()
        found = re.findall(r'Expert COBOL.*?Python only, no explanation\.', src, re.DOTALL)
        if not found:
            problems.append(f"[prompt] no 'Expert COBOL...' prompt found in {os.path.basename(path)} "
                            f"-- template moved; appendix A.1 reference is stale")
            return problems
        prompts.extend((os.path.basename(path), p) for p in found)
    ref = prompts[0][1]
    diverged = [name for name, p in prompts if p != ref]
    if diverged:
        problems.append(f"[prompt] appendix A.1 says 'character-identical' but {len(diverged)} of "
                        f"{len(prompts)} copies differ ({', '.join(sorted(set(diverged)))}) "
                        f"-- either re-sync the prompts or remove the claim")
    return problems


def main():
    if os.environ.get("PYTHONHASHSEED") != REQUIRED_SEED:
        print(f"REFUS DE CONCLURE -- relancer avec PYTHONHASHSEED={REQUIRED_SEED} "
              f"(déterminisme par construction, mais on épingle pour byte-stabilité)")
        # not fatal: determinism is by construction; continue but warn
    if not os.path.isdir(CORPUS):
        print(f"CORPUS ABSENT: {CORPUS} -- impossible de MESURER"); return 2
    print("Re-run pipeline (ground truth) ...")
    gt = ground_truth()
    print(f"  proved={gt['proved']} refuted={gt['refuted']} partial={gt['partial']} "
          f"failure={gt['pipeline_failure']} no_encodable={gt['no_encodable']} "
          f"checking={gt['checking']} total={gt['total']}")
    print(f"  independent: proved={gt['indep_proved']} checking={gt['indep_checking']} "
          f"failure={gt['indep_failure']}")
    with open(TEX, encoding="utf-8") as fh:
        tex = fh.read()
    bib = ""
    if os.path.exists(BIB):
        with open(BIB, encoding="utf-8") as fh:
            bib = fh.read()
    problems = (check_counts(tex, gt) + check_fraction_percent(tex)
                + check_citations(tex, bib) + check_refuted_table(tex, gt)
                + check_ground_truth_anchors(tex, gt) + check_targeted(gt, tex)
                + check_prompt_identity(tex) + check_loc_stats(tex, gt))
    if problems:
        print(f"\n{len(problems)} INCONSISTENCE(S):")
        for p in problems:
            print(f"  {p}")
        return 1
    print("\nOK -- paper coherent with the deterministic run and internally consistent.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
