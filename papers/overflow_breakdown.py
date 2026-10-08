#!/usr/bin/env python3
r"""Reproduce the PIC-bounded overflow numbers of the evaluation (RQ5 / \S5.7):
of the checking-path programs, how many complete the overflow analysis and how many
flag at least one out-of-range output, and how they distribute. The figures are
printed, never cited here: a docstring that quotes a run goes stale when the code moves.

Run:  PYTHONHASHSEED=0 python3 papers/overflow_breakdown.py
"""
import glob
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from ironproof_core import IronproofParser, _build_cobol_z3, check_overflow, is_expr


def run():
    p = IronproofParser()
    corpus = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                          "benchmark", "cobol_programs")
    complete = failed = flagged = flagged_vars = 0
    not_encoded = 0        # parse ou encodage COBOL qui leve : compte, plus avale
    per_prog = []          # nombre de variables signalees par programme signale
    for f in sorted(glob.glob(os.path.join(corpus, "*.cbl"))):
        try:
            with open(f) as fh:
                prog = p.parse(fh.read())
            inp, out, _allv = _build_cobol_z3(prog)
        except Exception:  # noqa: BLE001 -- tout echec d'encodage est compte ci-dessous
            not_encoded += 1
            continue
        if not {k: v for k, v in out.items() if is_expr(v)}:
            continue
        try:
            res = check_overflow(out, inp, prog.variables)
        except Exception:  # noqa: BLE001 -- requete d'overflow qui echoue : comptee
            failed += 1
            continue
        complete += 1
        ov = [r for r in res if r.can_overflow]
        if ov:
            flagged += 1
            flagged_vars += len(ov)
            per_prog.append(len(ov))
    return complete, flagged, flagged_vars, failed, per_prog, not_encoded


if __name__ == "__main__":
    complete, flagged, flagged_vars, failed, per_prog, not_encoded = run()
    print(f"complete_overflow_analysis={complete}  overflow_query_failed={failed}  "
          f"cobol_encoding_raised={not_encoded}")
    share = f"{flagged / complete * 100:.1f}%" if complete else "NOT MEASURED"
    print(f"programs_flagged={flagged} ({share} of complete)  flagged_variables={flagged_vars}")
    # Distribution : le papier la cite (1 variable / 2 / 3 et plus / maximum).
    if per_prog:
        un = sum(1 for n in per_prog if n == 1)
        deux = sum(1 for n in per_prog if n == 2)
        plus = sum(1 for n in per_prog if n >= 3)
        srt = sorted(per_prog)
        print(f"distribution: one={un} two={deux} three_or_more={plus} "
              f"median={srt[len(srt) // 2]} max={srt[-1]}")
