#!/usr/bin/env python3
"""Transparency breakdown: of the proved programs, how many does the encoder model
in FULL, and how many involve control flow the shared parser flattens (loops, file
I/O, or conditions collapsed to a constant)? For the latter, the proof still holds
as an emission-fidelity statement (both sides are flattened identically), but a
reader is entitled to know the split behind the headline proof rate.

A proved program is FULLY MODELED iff:
  - its source contains no PERFORM ... UNTIL loop and no file I/O verb, AND
  - none of its encoded output expressions contains a flattened If(True/False)
    (i.e. a guard the parser could not translate and collapsed to a constant).
Otherwise it is EMISSION-FIDELITY (partially modeled).

Re-derive:  PYTHONHASHSEED=0 python3 papers/modeled_breakdown.py
Determinism is by construction (see paper Repro paragraph); the seed is not required
but is pinned here for byte-stability of the printout.
"""
import sys, glob, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from ironproof_core import (IronproofParser, PythonGen, _build_cobol_z3,
    _build_python_z3, prove_equivalence, is_expr, cibles_non_declarees, pic_declares_dans_la_source,)

def run():
    p, g = IronproofParser(), PythonGen()
    full, emis = 0, 0
    corpus = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                          "benchmark", "cobol_programs")
    for f in sorted(glob.glob(os.path.join(corpus, "*.cbl"))):
        src = open(f).read().upper()
        loop_or_io = ("PERFORM" in src and "UNTIL" in src) or \
                     "READ " in src or "OPEN " in src or "WRITE " in src
        try:
            _src = open(f).read()
            prog = p.parse(_src); py = g.generate(prog)
            _rep = {}
            inp, out, allv = _build_cobol_z3(prog, _rep)
            prov = {k: v for k, v in out.items() if is_expr(v)}
            if not prov:
                continue
            pyo = _build_python_z3(py, allv)
            pyu = {k.upper(): v for k, v in pyo.items()}
            # CABLAGE DU DISCRIMINANT (2026-08-27) -- ce script produit des chiffres du
            # papier et n'en passait aucun. Voir ironproof_core.py::prove_equivalence.
            proofs = prove_equivalence(prov, pyo, inp, variables=prog.variables,
                                   source_vars=set(prog.variables),
                                   unverified=set(_rep.get('dropped_outputs', [])),
                                   cibles_invalides=cibles_non_declarees(prog),
                                   pic_declares=pic_declares_dans_la_source(_src))
        except Exception:
            continue
        if not (proofs and all(r.proved for r in proofs)):
            continue  # only classify PROVED programs
        flat = any("If(True" in str(v) or "If(False" in str(v) for v in prov.values()) or \
               any("If(True" in str(pyu.get(k, "")) for k in prov)
        if loop_or_io or flat:
            emis += 1
        else:
            full += 1
    return full, emis

if __name__ == "__main__":
    full, emis = run()
    total = full + emis
    print(f"PROVED total          : {total}")
    print(f"  fully modeled       : {full}")
    print(f"  emission-fidelity   : {emis}   (loops / file I/O / flattened guard)")
    if total:
        print(f"  fully-modeled share : {full/total*100:.1f}%")
