#!/usr/bin/env python3
"""
IRONPROOF-COBOL — LLM-Only Baseline Experiment
Runs LLM translation + Z3 verification on the Z3-provable fragment
to measure how many translations are correct WITHOUT IRONPROOF's rule-based codegen.

Usage:
  # from the repository root
  ANTHROPIC_API_KEY=sk-... venv/bin/python3 benchmark/run_baseline.py
  ANTHROPIC_API_KEY=sk-... venv/bin/python3 benchmark/run_baseline.py --sample 50
  ANTHROPIC_API_KEY=sk-... venv/bin/python3 benchmark/run_baseline.py --model claude-sonnet-4-6
"""

import json
import os
import sys
import time
import datetime
import random
import traceback
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Optional, List, Dict, Any

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from ironproof_core import (
    IronproofParser, PythonGen, _build_cobol_z3, _build_python_z3,
    prove_equivalence, is_expr, _extract_python_from_response,
)

try:
    import anthropic
except ImportError:
    print("ERROR: pip install anthropic", file=sys.stderr)
    sys.exit(1)


@dataclass
class BaselineResult:
    filename: str
    source_category: str
    num_vars: int = 0
    z3_provable_vars: int = 0
    llm_translation_ok: bool = False
    llm_z3_proved: bool = False
    llm_z3_proved_vars: int = 0
    llm_z3_refuted_vars: int = 0
    llm_z3_no_match_vars: int = 0
    error_types: List[str] = field(default_factory=list)
    counterexamples: List[Dict[str, Any]] = field(default_factory=list)
    llm_time_ms: float = 0.0
    z3_time_ms: float = 0.0
    error: str = ""


def classify_source(filename: str) -> str:
    if filename.startswith("gen_"):
        return "generated"
    elif filename.startswith("dscobol_"):
        return "dscobol"
    elif filename.startswith("nist_") or "ccvs" in filename.lower():
        return "nist"
    elif filename.startswith("gnucobol_") or filename.startswith("gc_"):
        return "gnucobol"
    elif filename.startswith("community_") or filename.startswith("omp_"):
        return "community"
    else:
        return "hand-written"


def classify_error(refuted_results) -> List[str]:
    errors = []
    for r in refuted_results:
        details = (r.details or "").lower()
        if "divide" in details and "into" in details:
            errors.append("DIVIDE_INTO_SEMANTICS")
        elif any(op in details for op in ["<=", ">=", "< ", "> "]):
            errors.append("BOUNDARY_OPERATOR")
        elif "overflow" in details or "truncat" in details:
            errors.append("OVERFLOW_TRUNCATION")
        elif "sign" in details or "negative" in details:
            errors.append("SIGN_ERROR")
        else:
            errors.append("OTHER_SEMANTIC")
    return errors


def translate_llm(cobol_src: str, client, model: str) -> str:
    prompt = f"""Expert COBOL→Python migration. Translate exactly. Rules:
- Single function named after PROGRAM-ID (snake_case)
- All variables use Decimal for numeric types
- Preserve exact conditions (<=, <, etc.)
- Use same variable names (lowercase)
- No comments, no imports

COBOL:
```
{cobol_src}
```
Python only, no explanation."""

    msg = client.messages.create(
        model=model, max_tokens=2048,
        messages=[{"role": "user", "content": prompt}],
    )
    return _extract_python_from_response(msg.content[0].text)


def get_provable_programs(benchmark_json: str) -> List[str]:
    with open(benchmark_json) as f:
        data = json.load(f)
    return [
        r["filename"] for r in data["benchmark"]["results"]
        if r.get("codegen_z3_verdict") == "EQUIVALENT"
    ]


def run_baseline(cobol_dir: Path, provable_files: List[str],
                 client, model: str) -> List[BaselineResult]:
    results = []
    total = len(provable_files)

    print(f"\nIRONPROOF-COBOL LLM-Only Baseline — {total} programs")
    print(f"Model: {model}")
    print("=" * 80)

    for i, filename in enumerate(provable_files, 1):
        filepath = cobol_dir / filename
        result = BaselineResult(
            filename=filename,
            source_category=classify_source(filename),
        )

        if not filepath.exists():
            result.error = "file not found"
            results.append(result)
            continue

        cobol_src = filepath.read_text()

        parser = IronproofParser()
        try:
            program = parser.parse(cobol_src)
        except Exception as e:
            result.error = f"parse: {e}"
            results.append(result)
            continue

        result.num_vars = len(program.variables)

        try:
            _enc_report = {}
            cobol_inputs, cobol_outputs, all_cobol_vars = _build_cobol_z3(program, report=_enc_report)
            _unverified = set(_enc_report.get("dropped_outputs", []))
            provable = {k: v for k, v in cobol_outputs.items() if is_expr(v)}
            result.z3_provable_vars = len(provable)
        except Exception as e:
            result.error = f"z3_build: {e}"
            results.append(result)
            continue

        if not provable:
            result.error = "no provable vars"
            results.append(result)
            continue

        t_llm = time.time()
        try:
            llm_python = translate_llm(cobol_src, client, model)
            result.llm_translation_ok = True
            result.llm_time_ms = (time.time() - t_llm) * 1000
        except Exception as e:
            result.error = f"llm: {e}"
            result.llm_time_ms = (time.time() - t_llm) * 1000
            results.append(result)
            status = f"[{i:3d}/{total}] {filename:45s}"
            print(f"  ❌ {status} → LLM ERROR: {e}")
            continue

        t_z3 = time.time()
        try:
            llm_outputs = _build_python_z3(llm_python, all_cobol_vars)
            bounds = {v: (0.0, 10_000_000.0) for v in cobol_inputs}
            proof_results = prove_equivalence(
                provable, llm_outputs, cobol_inputs, bounds=bounds,
                unverified=_unverified,
            )

            result.z3_time_ms = (time.time() - t_z3) * 1000
            result.llm_z3_proved_vars = sum(1 for r in proof_results if r.proved)
            refuted = [r for r in proof_results if r.status == "REFUTED"]
            result.llm_z3_refuted_vars = len(refuted)
            result.llm_z3_no_match_vars = sum(
                1 for r in proof_results if r.status == "NO_MATCH"
            )
            result.llm_z3_proved = (
                bool(proof_results) and all(r.proved for r in proof_results)
            )

            if refuted:
                result.error_types = classify_error(refuted)
                result.counterexamples = [
                    {"var": r.output_var, "details": r.details,
                     "counterexample": r.counterexample}
                    for r in refuted
                ]

        except Exception as e:
            result.z3_time_ms = (time.time() - t_z3) * 1000
            result.error = f"z3_verify: {e}"

        status = f"[{i:3d}/{total}] {filename:45s}"
        icon = "✅" if result.llm_z3_proved else "❌"
        extra = ""
        if result.error_types:
            extra = f"  errors: {','.join(set(result.error_types))}"
        print(f"  {icon} {status} proved={result.llm_z3_proved_vars}/{result.z3_provable_vars}"
              f"  LLM:{result.llm_time_ms:.0f}ms Z3:{result.z3_time_ms:.0f}ms{extra}")

        results.append(result)

    return results


def print_summary(results: List[BaselineResult]):
    total = len(results)
    llm_ok = sum(1 for r in results if r.llm_translation_ok)
    z3_proved = sum(1 for r in results if r.llm_z3_proved)
    z3_failed = sum(1 for r in results if r.llm_translation_ok and not r.llm_z3_proved)
    errors_found = sum(1 for r in results if r.llm_z3_refuted_vars > 0)

    print("\n" + "=" * 80)
    print("BASELINE SUMMARY: LLM-Only Translation vs IRONPROOF Rule-Based")
    print("=" * 80)

    print(f"\n  Programs tested     : {total}")
    print(f"  LLM translation OK  : {llm_ok}/{total} ({llm_ok/total*100:.1f}%)")
    print(f"  Z3 fully proved     : {z3_proved}/{total} ({z3_proved/total*100:.1f}%)")
    print(f"  Z3 found errors     : {errors_found}/{total} ({errors_found/total*100:.1f}%)")
    print(f"  IRONPROOF codegen   : {total}/{total} (100.0%)")
    print(f"  Δ (IRONPROOF - LLM)    : +{total - z3_proved} programs verified")

    all_errors = []
    for r in results:
        all_errors.extend(r.error_types)
    if all_errors:
        print(f"\n  Error type breakdown:")
        from collections import Counter
        for err_type, count in Counter(all_errors).most_common():
            print(f"    {err_type:30s} : {count}")

    categories = sorted(set(r.source_category for r in results))
    print(f"\n  {'Source':15s} {'Total':>6s} {'LLM OK':>7s} {'Z3 Proved':>10s} {'Errors':>7s}")
    print(f"  {'─'*15} {'─'*6} {'─'*7} {'─'*10} {'─'*7}")
    for cat in categories:
        cat_r = [r for r in results if r.source_category == cat]
        ct = len(cat_r)
        lok = sum(1 for r in cat_r if r.llm_translation_ok)
        zp = sum(1 for r in cat_r if r.llm_z3_proved)
        ef = sum(1 for r in cat_r if r.llm_z3_refuted_vars > 0)
        print(f"  {cat:15s} {ct:6d} {lok:7d} {zp:10d} {ef:7d}")

    print(f"\n  === LATEX TABLE (copy-paste into paper) ===\n")
    print(r"  \begin{tabular}{lrrr}")
    print(r"  \toprule")
    print(r"  \textbf{Approach} & \textbf{Programs} & \textbf{Z3 Proved (\%)} & \textbf{Errors Found} \\")
    print(r"  \midrule")
    print(f"  \\textsc{{Ironproof}} (rule-based) & {total} & {total} (100\\%) & 0 \\\\")
    pct = z3_proved/total*100 if total else 0
    print(f"  LLM-only (no verification) & {total} & {z3_proved} ({pct:.1f}\\%) & {errors_found} \\\\")
    print(r"  \bottomrule")
    print(r"  \end{tabular}")

    total_llm_ms = sum(r.llm_time_ms for r in results)
    total_z3_ms = sum(r.z3_time_ms for r in results)
    print(f"\n  Total LLM time  : {total_llm_ms/1000:.1f}s")
    print(f"  Total Z3 time   : {total_z3_ms/1000:.1f}s")
    print(f"  Avg LLM/program : {total_llm_ms/total:.0f}ms")
    print(f"  Avg Z3/program  : {total_z3_ms/total:.0f}ms")
    print()


def save_results(results: List[BaselineResult], output_dir: str, model: str):
    os.makedirs(output_dir, exist_ok=True)
    ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    output_path = os.path.join(output_dir, f"baseline_{model.replace('/', '_')}_{ts}.json")

    data = {
        "baseline_experiment": {
            "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "model": model,
            "total_programs": len(results),
            "z3_proved": sum(1 for r in results if r.llm_z3_proved),
            "errors_found": sum(1 for r in results if r.llm_z3_refuted_vars > 0),
            "results": [asdict(r) for r in results],
        }
    }

    with open(output_path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"  Results saved: {output_path}")
    return output_path


def main():
    import argparse
    ap = argparse.ArgumentParser(description="IRONPROOF-COBOL LLM Baseline Experiment")
    ap.add_argument("--cobol-dir", default=os.path.join(os.path.dirname(__file__), "cobol_programs"))
    ap.add_argument("--output-dir", default=os.path.join(os.path.dirname(__file__), "results"))
    ap.add_argument("--benchmark-json",
                    default=os.path.join(os.path.dirname(__file__), "results", "benchmark_20260430_055406.json"),
                    help="Benchmark JSON to identify Z3-provable programs")
    ap.add_argument("--model", default="claude-sonnet-4-6",
                    help="Model to use (default: claude-sonnet-4-6)")
    ap.add_argument("--sample", type=int, default=0,
                    help="Sample N programs (0 = all, stratified by source)")
    ap.add_argument("--seed", type=int, default=42, help="Random seed for sampling")
    args = ap.parse_args()

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("ERROR: Set ANTHROPIC_API_KEY environment variable", file=sys.stderr)
        sys.exit(1)

    client = anthropic.Anthropic(api_key=api_key)

    provable_files = get_provable_programs(args.benchmark_json)
    print(f"Found {len(provable_files)} Z3-provable programs from benchmark")

    if args.sample > 0 and args.sample < len(provable_files):
        random.seed(args.seed)
        by_source = {}
        for f in provable_files:
            cat = classify_source(f)
            by_source.setdefault(cat, []).append(f)

        sampled = []
        per_cat = max(1, args.sample // len(by_source))
        for cat, files in sorted(by_source.items()):
            n = min(per_cat, len(files))
            sampled.extend(random.sample(files, n))

        remaining = args.sample - len(sampled)
        if remaining > 0:
            pool = [f for f in provable_files if f not in sampled]
            sampled.extend(random.sample(pool, min(remaining, len(pool))))

        provable_files = sorted(sampled)
        print(f"Sampled {len(provable_files)} programs (stratified, seed={args.seed})")

    cobol_dir = Path(args.cobol_dir)
    results = run_baseline(cobol_dir, provable_files, client, args.model)
    print_summary(results)
    save_results(results, args.output_dir, args.model)


if __name__ == "__main__":
    main()
