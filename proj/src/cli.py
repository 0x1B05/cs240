from __future__ import annotations

import argparse
from pathlib import Path
import sys

from .artifacts import ArtifactValidationError, generate_artifacts
from .data import DataValidationError, prepare_multihop_cache
from .experiments import (
    DEFAULT_BUDGET,
    DEFAULT_OBJECTIVES,
    DEFAULT_SELECTORS,
    DEFAULT_TOP_N,
    ExperimentConfig,
    generate_candidates,
    parse_grid,
    parse_name_grid,
    run_experiment,
    run_smoke,
    select_evaluate,
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="context-selection", description="Budgeted context selection experiments.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    prepare = subparsers.add_parser("prepare-data", help="Normalize local MultiHop-RAG-style records into a processed cache.")
    prepare.add_argument("--raw-queries", type=Path, required=True)
    prepare.add_argument("--raw-corpus", type=Path)
    prepare.add_argument("--schema", choices=["auto", "split", "embedded"], default="auto")
    prepare.add_argument("--output-dir", type=Path, required=True)
    prepare.add_argument("--sample-size", type=int)
    prepare.add_argument("--seed", type=int, default=13)
    prepare.add_argument("--overwrite", action="store_true")

    candidates = subparsers.add_parser("generate-candidates", help="Generate deterministic TF-IDF top-N candidate passages.")
    candidates.add_argument("--data-dir", type=Path, required=True)
    candidates.add_argument("--output-path", type=Path, required=True)
    candidates.add_argument("--top-n", type=int, required=True)

    select = subparsers.add_parser("select-evaluate", help="Run selection and evaluation for one budget/top-N configuration.")
    select.add_argument("--data-dir", type=Path, required=True)
    select.add_argument("--output-dir", type=Path, required=True)
    select.add_argument("--budget", type=int, default=DEFAULT_BUDGET)
    select.add_argument("--top-n", type=int, default=DEFAULT_TOP_N)
    select.add_argument("--seed", type=int, default=13)
    select.add_argument("--overwrite", action="store_true")

    experiment = subparsers.add_parser("run-experiment", help="Run the full budget/candidate/method experiment grid.")
    experiment.add_argument("--data-dir", type=Path, required=True)
    experiment.add_argument("--output-dir", type=Path, required=True)
    experiment.add_argument("--dataset-name", default="dataset")
    experiment.add_argument("--split", default="test")
    experiment.add_argument("--budgets", default="80,160,320")
    experiment.add_argument("--candidate-sizes", default="10,20,40")
    experiment.add_argument("--selectors", default=",".join(DEFAULT_SELECTORS))
    experiment.add_argument("--objectives", default=",".join(DEFAULT_OBJECTIVES))
    experiment.add_argument("--combined-lambdas", default="1.0")
    experiment.add_argument("--mmr-lambda", type=float, default=0.7)
    experiment.add_argument("--seed", type=int, default=13)
    experiment.add_argument("--sample-size", type=int)
    experiment.add_argument("--sample-seed", type=int, default=13)
    experiment.add_argument("--optimal-max-items", type=int, default=16)
    experiment.add_argument("--overwrite", action="store_true")

    artifacts = subparsers.add_parser("generate-artifacts", help="Generate report-ready Markdown tables from a run directory.")
    artifacts.add_argument("--run-dir", type=Path, required=True)
    artifacts.add_argument("--output-dir", type=Path, required=True)

    smoke = subparsers.add_parser("run-smoke", help="Run the deterministic fixture smoke experiment.")
    smoke.add_argument("--data-dir", type=Path, default=Path("proj/data/fixtures"))
    smoke.add_argument("--output-dir", type=Path, required=True)
    smoke.add_argument("--budget", type=int, default=DEFAULT_BUDGET)
    smoke.add_argument("--top-n", type=int, default=DEFAULT_TOP_N)
    smoke.add_argument("--seed", type=int, default=13)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    try:
        args = parser.parse_args(argv)
    except SystemExit as exc:
        return exc.code if isinstance(exc.code, int) else 2
    try:
        if args.command == "prepare-data":
            prepare_multihop_cache(
                raw_queries=args.raw_queries,
                raw_corpus=args.raw_corpus,
                output_dir=args.output_dir,
                schema=args.schema,
                sample_size=args.sample_size,
                seed=args.seed,
                overwrite=args.overwrite,
            )
            print(f"wrote processed cache to {args.output_dir}")
            return 0
        if args.command == "generate-candidates":
            rows = generate_candidates(args.data_dir, args.output_path, args.top_n)
            print(f"wrote {len(rows)} candidates to {args.output_path}")
            return 0
        if args.command == "select-evaluate":
            select_evaluate(args.data_dir, args.output_dir, args.budget, args.top_n, args.seed, overwrite=args.overwrite)
            print(f"wrote selection/evaluation outputs to {args.output_dir}")
            return 0
        if args.command == "run-experiment":
            config = ExperimentConfig(
                data_dir=str(args.data_dir),
                output_dir=str(args.output_dir),
                dataset_name=args.dataset_name,
                split=args.split,
                budgets=parse_grid(args.budgets, item_type=int, label="budgets"),
                candidate_sizes=parse_grid(args.candidate_sizes, item_type=int, label="candidate_sizes"),
                selectors=parse_name_grid(args.selectors, allowed=DEFAULT_SELECTORS, label="selectors"),
                objectives=parse_name_grid(args.objectives, allowed=DEFAULT_OBJECTIVES, label="objectives"),
                combined_lambdas=parse_grid(args.combined_lambdas, item_type=float, label="combined_lambdas"),
                mmr_lambda=args.mmr_lambda,
                seed=args.seed,
                sample_size=args.sample_size,
                sample_seed=args.sample_seed,
                optimal_max_items=args.optimal_max_items,
                overwrite=args.overwrite,
            )
            run_experiment(config)
            print(f"wrote experiment outputs to {args.output_dir}")
            return 0
        if args.command == "generate-artifacts":
            outputs = generate_artifacts(args.run_dir, args.output_dir)
            print(f"wrote {len(outputs)} report artifacts to {args.output_dir}")
            return 0
        if args.command == "run-smoke":
            run_smoke(args.data_dir, args.output_dir, budget=args.budget, top_n=args.top_n, seed=args.seed)
            print(f"wrote smoke outputs to {args.output_dir}")
            return 0
    except (DataValidationError, ArtifactValidationError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    parser.error(f"unknown command: {args.command}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
