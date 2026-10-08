#!/usr/bin/env python3
r"""RQ6, split by provenance and by failure MODE. The LLM baseline's failures are
of two kinds: SAT (Z3 found a concrete semantic error) and UNVERIFIABLE (our encoder
cannot check the emitted Python -- the same class of encoder gap that produces
IRONPROOF's own encoding failures). Reporting them separately lets the comparison be
made SAT-only vs SAT-only, which is the fair one. Reads the cached baseline results
(no LLM call). Run:  python3 papers/baseline_split.py
"""
import json, os, glob
HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(os.path.dirname(HERE), "benchmark", "results")
# Classify by the JSON's own source_category (authoritative for the baseline set),
# consistent with the per-source figures in the paper (\S5.8). The baseline's
# "independently authored" subset is the three real-world sources it was run on;
# the few community programs were grouped with hand-written for this experiment.
INDEP = {"gnucobol", "dscobol", "nist"}

def klass_of(result):
    return "independent" if (result.get("source_category") or "").lower() in INDEP else "authored"

def latest_baseline():
    files = sorted(glob.glob(os.path.join(RES, "baseline_*.json")), key=os.path.getsize)
    return files[-1] if files else None

def run():
    f = latest_baseline()
    d = json.load(open(f))["baseline_experiment"]
    by_src = {}
    agg = {"independent": {"proved":0,"sat":0,"unverif":0},
           "authored": {"proved":0,"sat":0,"unverif":0}}
    for r in d["results"]:
        src = r.get("source_category") or "unknown"
        k = klass_of(r)
        s = by_src.setdefault(src, {"proved":0,"sat":0,"unverif":0})
        if r.get("llm_z3_refuted_vars"):
            s["sat"] += 1; agg[k]["sat"] += 1
        elif r.get("llm_z3_proved"):
            s["proved"] += 1; agg[k]["proved"] += 1
        else:
            s["unverif"] += 1; agg[k]["unverif"] += 1
    return f, d, by_src, agg

if __name__ == "__main__":
    f, d, by_src, agg = run()
    print(f"source file: {os.path.basename(f)}  (model {d['model']}, {d['total_programs']} programs)")
    print(f"{'source':14}{'proved':>8}{'SAT':>6}{'unverif':>9}")
    for s in sorted(by_src):
        v = by_src[s]; print(f"{s:14}{v['proved']:>8}{v['sat']:>6}{v['unverif']:>9}")
    print("-"*40)
    for k in ("independent","authored"):
        v=agg[k]; tot=v['proved']+v['sat']+v['unverif']
        satrate = v['sat']/tot*100 if tot else 0
        print(f"{k.upper():14}{v['proved']:>8}{v['sat']:>6}{v['unverif']:>9}   (n={tot}, SAT-error rate {satrate:.1f}%)")
    ind=agg["independent"]; itot=sum(ind.values())
    print(f"\nLLM on independent: proved {ind['proved']}/{itot} ({ind['proved']/itot*100:.1f}%), "
          f"SAT-errors {ind['sat']}, unverifiable {ind['unverif']}")
