# IRONPROOF: COBOL-to-Python Transpilation with SMT-Based Equivalence Checking

Code, evaluation scripts and redistributable benchmark programs for the paper of the
same name (Dominik Blain, Ironproof, 2026). The LaTeX source is in `papers/`.

## What is here

| Path | Content |
|---|---|
| `ironproof_core.py`, `ratio_valide.py` | Parser, Python generator, Z3 encoding of both sides, equivalence and overflow checks. Console messages are in French. |
| `papers/classify.py` | The single classification of a benchmark program used by every figure of the paper. |
| `papers/check_paper_numbers.py`, `papers/check_paper_consistency.py` | Re-run the pipeline and compare its output with the numbers in the paper. |
| `papers/*_breakdown.py`, `papers/baseline_split.py` | Per-section figures (provenance, input domain, modeled fragment, overflow, LLM baseline split). |
| `papers/verify_smt2.py` | Re-checks the SMT-LIB2 obligations of proved programs in a fresh solver. |
| `papers/motivating/` | The paper's motivating example and the command that produces Listing 3. |
| `benchmark/cobol_programs/` | 600 of the 2,345 benchmark files (see `THIRD_PARTY.md`). |
| `benchmark/CORPUS_TIERS.sha256` | SHA-256 of the 1,745 third-party programs that are not redistributed. |
| `benchmark/run_baseline.py`, `benchmark/results/baseline_*.json` | The April 2026 LLM-only baseline and its raw results. The figures of the paper come from `baseline_claude-opus-4-7_20260430_075738.json` (model `claude-opus-4-7`, 586 programs). Re-running it needs an API key and the model name passed explicitly; its default arguments differ. |

## Requirements

Python 3 and `z3-solver==4.16.0.0` (the paper used Python 3.14). The Z3 version changes
which outputs are Z3 expressions, so other versions can give other counts. `anthropic` only for the
LLM baseline and feedback loop, with `ANTHROPIC_API_KEY` set.

## Run

```bash
PYTHONHASHSEED=0 python3 ironproof_core.py --demo-bug
PYTHONHASHSEED=0 python3 ironproof_core.py --cobol papers/motivating/fed_tax_calc.cbl \
    --python papers/motivating/fed_tax_calc_boundary_error.py
PYTHONHASHSEED=0 python3 papers/verify_smt2.py 40
```

Run everything with `PYTHONHASHSEED=0`. The encoding is deterministic by construction
(see the paper, Section 5.3); the seed is pinned as a precaution, and the two checking scripts (`check_paper_numbers.py`,
`check_paper_consistency.py`) refuse to run without it.

## Reproducing the paper's figures

The headline figures (606 of 782 programs proved, 153 of 291 on independently
authored code) are over the full 2,345-program benchmark. With only the 600
redistributable programs in this repository, the scripts run but report different
counts. To reproduce the paper exactly, add the GnuCOBOL test-suite programs and the
dscobol programs to `benchmark/cobol_programs/` under the names listed in
`benchmark/CORPUS_TIERS.sha256`, and check them with
`cd benchmark/cobol_programs && shasum -a 256 -c ../CORPUS_TIERS.sha256`.
The manifest also lists `LICENSE.GnuCOBOL-GPL-3.0.txt`, the GPL text that accompanies
the GnuCOBOL tests; add it with them.

On the 600 redistributable files alone, `verify_smt2.py 40` re-checks the first 40
proved programs of that subset (119 obligations here, against 113 on the full benchmark).

## Not included

- The harness of the runtime confrontation with GnuCOBOL 3.2.0 (Section 5.5): it was not versioned.
- The CardDemo/GenApp measurement (Section 6): it depends on a separate pipeline.
  The corpora are AWS CardDemo at commit 59cc6c2 and IBM GenApp at commit f6f3f4b.

## What a proof means

A proof is an emission-fidelity statement: the generated Python computes what our
intermediate representation says the COBOL computes. The parser is shared by both
sides and is not checked by the proof. Section 5.4 and 5.5 of the paper state the
limits, including a runtime comparison in which 24 of 49 proved programs disagreed
with GnuCOBOL 3.2.0.

## License

MIT (see `LICENSE`), except the third-party programs listed in `THIRD_PARTY.md`.
