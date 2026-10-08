#!/usr/bin/env python3
r"""Re-derive the per-source figures of the evaluation that had no script behind them.

Backs, in the paper: Table 1 (checking path / proved / no encodable output), Table 2
(parse and Python emission by source, RQ1), the composition of the proved fragment,
the line-count statistics of the proved fragment, the split of pipeline failures by
stage, and the RQ4 timing table (per-stage mean / median / p95 over proved programs).

Same five states and same order of stages as check_paper_numbers.py::run_pipeline,
so the counts it prints must equal that guard's counts; it says so at the end.

WHY THIS SCRIPT EXISTS (2026-09-30). The paper's Table 2 claimed 100% parse and
emission on every source and its RQ4 table cited timings, with no script behind
either. After the encoder and generator hardening of late August, 400 programs are
refused by our own generator before encoding: the 100% column had become false
without anything turning red. A figure without a re-derivation is a mirror nobody
guards.

Run:  PYTHONHASHSEED=0 python3 papers/rq_breakdown.py
"""
import os
import statistics
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from classify import (
    CORPUS,
    STATES,
    IronproofParser,
    PythonGen,
    counts,
    iter_corpus,
    source_of,
)

SOURCES = ["GnuCOBOL", "Generated", "dscobol", "NIST", "Hand-written", "Community"]


def pct(values, q):
    """Nearest-rank percentile; None on an empty list (never a fake zero)."""
    if not values:
        return None
    s = sorted(values)
    k = max(0, min(len(s) - 1, round(q / 100.0 * len(s) + 0.5) - 1))
    return s[k]


def rq1_crash_freedom():
    """RQ1 measures parse and emission on EVERY program, in scope or not -- a
    different question from the classification, so it is measured here, not copied."""
    import glob
    parser, gen = IronproofParser(), PythonGen()
    rows = []
    for f in sorted(glob.glob(os.path.join(CORPUS, "*.cbl"))):
        with open(f) as fh:
            src = fh.read()
        row = {"source": source_of(os.path.basename(f)[:-4]), "parse": False, "emit": False}
        try:
            prog = parser.parse(src)
            row["parse"] = True
            gen.generate(prog)
            row["emit"] = True
        except Exception:  # noqa: BLE001, S110 -- a stage that raises is what RQ1 counts
            pass
        rows.append(row)
    return rows


def main():
    rows = list(iter_corpus())
    states = STATES
    tot = counts(rows)
    print(f"total={tot['total']} checking_path={tot['checking_path']} " +
          " ".join(f"{s}={tot[s]}" for s in states))

    print("\nRQ1 -- parse / emission by source (N, parse ok, emission ok)")
    rq1 = rq1_crash_freedom()
    for s in SOURCES:
        sub = [r for r in rq1 if r["source"] == s]
        p = sum(r["parse"] for r in sub)
        e = sum(r["emit"] for r in sub)
        print(f"  {s:13s} N={len(sub):5d} parse={p:5d} ({p / len(sub) * 100:5.1f}%) "
              f"emit={e:5d} ({e / len(sub) * 100:5.1f}%)")
    p = sum(r["parse"] for r in rq1)
    e = sum(r["emit"] for r in rq1)
    print(f"  {'Total':13s} N={len(rq1):5d} parse={p:5d} ({p / len(rq1) * 100:5.1f}%) "
          f"emit={e:5d} ({e / len(rq1) * 100:5.1f}%)")

    print("\nStates by source")
    for s in SOURCES:
        sub = [r for r in rows if r["source"] == s]
        print(f"  {s:13s} " + " ".join(
            f"{st}={sum(1 for r in sub if r['state'] == st)}" for st in states))

    fails = [r for r in rows if r["state"] == "pipeline_failure"]
    by_stage = {}
    for r in fails:
        by_stage[r["stage"]] = by_stage.get(r["stage"], 0) + 1
    print("\nPipeline failures by stage: " +
          ", ".join(f"{k}={v}" for k, v in sorted(by_stage.items(), key=lambda kv: -kv[1])))
    print(f"  of which on independent code: "
          f"{sum(1 for r in fails if r['independent'])} of {len(fails)}")

    proved = [r for r in rows if r["state"] == "proved"]
    loc = [r["loc"] for r in proved]
    allloc = [r["loc"] for r in rows]
    print(f"\nBenchmark lines: min={min(allloc)} max={max(allloc)} "
          f"median={statistics.median(allloc):g} mean={statistics.mean(allloc):.0f}")
    if loc:
        print(f"Proved fragment lines (n={len(loc)}): min={min(loc)} max={max(loc)} "
              f"median={statistics.median(loc):g} mean={statistics.mean(loc):.0f}")
    comp = {s: sum(1 for r in proved if r["source"] == s) for s in SOURCES}
    print("Composition of proved: " + ", ".join(f"{s}={n}" for s, n in comp.items()))
    own = comp["Generated"] + comp["Hand-written"]
    if proved:
        print(f"  generated + hand-written = {own} of {len(proved)} "
              f"({own / len(proved) * 100:.1f}%)")

    print("\nInput domain of the proved programs (what the quantifier ranges over)")
    for label, sub in (("all", proved),
                       ("independent", [r for r in proved if r["independent"]]),
                       ("authored", [r for r in proved if not r["independent"]])):
        nofree = [r for r in sub if r.get("free_inputs", 0) == 0]
        closed = sum(1 for r in nofree if not r["input_surfaces"])
        single_point = len(nofree) - closed
        free = len(sub) - len(nofree)
        dep = sum(1 for r in sub if r.get("dep_outputs", 0) > 0)
        print(f"  {label:12s} n={len(sub):4d} closed(no input surface, no free input)={closed:4d} "
              f"open_but_no_free_input(single point)={single_point:4d} "
              f"free_input={free:4d} output_depends_on_free_input={dep:4d}")

    print(f"\nRQ4 -- per-stage time over the {len(proved)} proved programs (ms)")
    total_mean = 0.0
    for st, label in (("parse", "COBOL parsing"), ("emit", "Python emission"),
                      ("encode", "Z3 encoding (COBOL + Python)"),
                      ("check", "Z3 equivalence check")):
        v = [r["t"][st] for r in proved if st in r["t"]]
        if not v:
            print(f"  {label:30s} NOT MEASURED (no proved program)")
            continue
        m = statistics.mean(v)
        total_mean += m
        print(f"  {label:30s} mean={m:8.2f} median={statistics.median(v):8.2f} "
              f"p95={pct(v, 95):8.2f} max={max(v):9.2f}")
    print(f"  {'Total (sum of means)':30s} mean={total_mean:8.2f}")


if __name__ == "__main__":
    if os.environ.get("PYTHONHASHSEED") != "0":
        print("rq_breakdown: REFUSED -- set PYTHONHASHSEED=0 (see check_paper_numbers.py)")
        sys.exit(2)
    main()
