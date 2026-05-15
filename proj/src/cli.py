from __future__ import annotations

import argparse
from pathlib import Path
import sys

from .data import DataValidationError
from .experiments import DEFAULT_BUDGET, DEFAULT_TOP_N, run_smoke


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="context-selection", description="Budgeted context selection experiments.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    smoke = subparsers.add_parser("run-smoke", help="Run the deterministic fixture smoke experiment.")
    smoke.add_argument("--data-dir", type=Path, default=Path("proj/data/fixtures"))
    smoke.add_argument("--output-dir", type=Path, required=True)
    smoke.add_argument("--budget", type=int, default=DEFAULT_BUDGET)
    smoke.add_argument("--top-n", type=int, default=DEFAULT_TOP_N)
    smoke.add_argument("--seed", type=int, default=13)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        if args.command == "run-smoke":
            run_smoke(args.data_dir, args.output_dir, budget=args.budget, top_n=args.top_n, seed=args.seed)
            print(f"wrote smoke outputs to {args.output_dir}")
            return 0
    except DataValidationError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    parser.error(f"unknown command: {args.command}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
