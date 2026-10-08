#!/usr/bin/env python3
"""Provenance breakdown of the proof rate over the FULL checking-path denominator.

Answers the "self-authored benchmark" concern honestly: the proof rate is reported
by who wrote the code, WITHOUT excluding our own encoding/solving failures from the
denominator (excluding them would make the rate unable to fall). Denominator = the
checking path (total - no_encodable_output), from papers/classify.py, the same
classification check_paper_numbers.py uses (one definition, not a copy).

Independent sources (filename prefix): gnucobol, dscobol, nist, examples, omp, omp2.
Everything else = generated (gen) or hand-written = team-authored.

Re-derive:  PYTHONHASHSEED=0 python3 papers/provenance_breakdown.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from classify import iter_corpus  # the ONE classification shared by every paper script


def run():
    agg = {k: {"total": 0, "proved": 0, "refuted": 0, "partial": 0, "failure": 0,
               "no_encodable": 0} for k in ("independent", "authored")}
    for rec in iter_corpus():
        d = agg["independent" if rec["independent"] else "authored"]
        d["total"] += 1
        key = {"pipeline_failure": "failure",
               "no_encodable_output": "no_encodable"}.get(rec["state"], rec["state"])
        d[key] += 1
    return agg


if __name__ == "__main__":
    agg = run()
    for k in ("independent","authored"):
        d = agg[k]; checking = d["total"] - d["no_encodable"]
        rate = d["proved"] / checking * 100 if checking else float("nan")
        print(f"{k.upper():12} checking={checking:4} proved={d['proved']:4} refuted={d['refuted']} "
              f"partial={d['partial']} failure={d['failure']:3}  proof_rate={d['proved']}/{checking} ({rate:.1f}%)")
    ind = agg["independent"]; ick = ind["total"] - ind["no_encodable"]
    print(f"\nHONEST real-world proof rate: {ind['proved']}/{ick} ({ind['proved']/ick*100:.1f}%) on independently authored code")
    print(f"Pipeline failures on independent code: {ind['failure']} of {ind['failure']+agg['authored']['failure']} total")
