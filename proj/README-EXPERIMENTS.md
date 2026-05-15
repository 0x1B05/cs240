# Budgeted Context Selection Experiments

This directory contains the implementation for the CS240 project on budgeted submodular context selection for retrieval-augmented generation.

## Environment

Use `uv` for dependency management and command execution:

```bash
uv sync
```

The project currently uses Python standard-library code for the deterministic smoke pipeline and declares `pytest` as a development dependency.

## Test

From the repository root:

```bash
uv run pytest proj/tests
```

## Smoke Experiment

From the repository root:

```bash
uv run python -m proj.src.cli run-smoke --output-dir proj/out/smoke --budget 18 --top-n 5
```

Expected outputs:

- `proj/out/smoke/candidates.jsonl`
- `proj/out/smoke/selections.jsonl`
- `proj/out/smoke/per_query_metrics.jsonl`
- `proj/out/smoke/metrics.json`
- `proj/out/smoke/summary.md`

The smoke workflow uses the local fixture data in `proj/data/fixtures`, so it can run without network access.

## Proposal Mapping

- Submodular objectives: `proj/src/objectives.py`
- Budgeted greedy and baselines: `proj/src/selectors.py`
- Evidence and redundancy metrics: `proj/src/metrics.py`
- Reproducible smoke workflow: `proj/src/experiments.py`

The real-data MultiHop-RAG pipeline is intentionally deferred until the deterministic fixture workflow is stable.
