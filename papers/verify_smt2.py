#!/usr/bin/env python3
r"""Demonstrate that IRONPROOF certificates are literally machine-checkable. For each
PROVED variable, IRONPROOF now attaches the SMT-LIB2 obligation (declarations +
assertions + check-sat). This script re-checks each obligation in a FRESH, independent
z3 solver via parse_smt2_string: UNSAT confirms equivalence without trusting
IRONPROOF's own solver call. Run: PYTHONHASHSEED=0 python3 papers/verify_smt2.py [N]
"""
import sys, os, glob
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from ironproof_core import (IronproofParser, PythonGen, _build_cobol_z3,
    _build_python_z3, prove_equivalence, is_expr, cibles_non_declarees, pic_declares_dans_la_source,)
import z3

def run(limit):
    p, g = IronproofParser(), PythonGen()
    corpus = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                          "benchmark", "cobol_programs")
    progs_checked = obligations = confirmed = mismatched = 0
    for f in sorted(glob.glob(os.path.join(corpus, "*.cbl"))):
        if progs_checked >= limit: break
        try:
            _src = open(f).read()
            prog = p.parse(_src); py = g.generate(prog)
            _rep = {}
            inp, out, allv = _build_cobol_z3(prog, _rep)
            prov = {k: v for k, v in out.items() if is_expr(v)}
            if not prov: continue
            pyo = _build_python_z3(py, allv)
            # CABLAGE DU DISCRIMINANT (2026-08-27) -- ce script produit des chiffres du
            # papier et n'en passait aucun. Voir ironproof_core.py::prove_equivalence.
            proofs = prove_equivalence(prov, pyo, inp, variables=prog.variables,
                                   source_vars=set(prog.variables),
                                   unverified=set(_rep.get('dropped_outputs', [])),
                                   cibles_invalides=cibles_non_declarees(prog),
                                   pic_declares=pic_declares_dans_la_source(_src))
        except Exception:
            continue
        proved = [r for r in proofs if r.status == "PROVED" and r.smt2]
        if not proved: continue
        progs_checked += 1
        for r in proved:
            obligations += 1
            fresh = z3.Solver()                       # independent solver
            fresh.add(z3.parse_smt2_string(r.smt2))   # re-parse the obligation from text
            if fresh.check() == z3.unsat:
                confirmed += 1
            else:
                mismatched += 1
    return progs_checked, obligations, confirmed, mismatched

if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 40
    pc, ob, ok, bad = run(n)
    print(f"programs re-checked : {pc}")
    print(f"SMT-LIB2 obligations: {ob}")
    print(f"independently UNSAT : {ok}   mismatched: {bad}")
    print("RESULT:", "ALL obligations re-verified UNSAT by a fresh solver ✓" if bad == 0 and ob > 0
          else "MISMATCH — certificate not machine-checkable!")
