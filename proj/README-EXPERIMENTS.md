# Budgeted Context Selection Experiments

This directory contains the implementation for the CS240 project on budgeted submodular context selection for retrieval-augmented generation. The code turns retrieved candidate passages into token-budgeted context sets, compares Lin-Bilmes-style submodular objectives with rank/relevance/MMR/random baselines, and writes reproducible tables for the final report.

## Environment

Use `uv` for dependency management and command execution from the repository root:

```bash
uv sync
```

The core implementation uses Python standard-library code plus `pytest` for tests. No live LLM API call is required for the experiment.

## Test

```bash
uv run pytest proj/tests
```

The test suite covers fixture loading, MultiHop-style raw preparation, retrieval candidates, feature construction, objectives, selectors, metrics, the main experiment runner, artifact validation, overwrite refusal, invalid grids, optimal checks, and deterministic re-runs.

## Local Data Preparation

The canonical processed cache consumed by the runner is:

- `queries.jsonl`: `query_id`, `query`, `answer`, `evidence_ids`
- `corpus.jsonl`: `doc_id`, `text`
- `manifest.json`: source path, schema, sample size, seed, counts, and sampled query IDs

Prepare the bundled MultiHop-style raw fixture without network access:

```bash
uv run python -m proj.src.cli prepare-data \
  --raw-queries proj/data/fixtures/multihop_raw.jsonl \
  --schema embedded \
  --output-dir proj/data/processed/fixture-multihop \
  --seed 13 \
  --overwrite
```

For a split-format local dataset, provide one query file and one corpus file:

```bash
uv run python -m proj.src.cli prepare-data \
  --raw-queries proj/data/raw/multihop_queries.jsonl \
  --raw-corpus proj/data/raw/multihop_corpus.jsonl \
  --schema split \
  --sample-size 200 \
  --seed 13 \
  --output-dir proj/data/processed/multihop-q200 \
  --overwrite
```

Accepted query aliases are `query_id|id`, `query|question`, `answer`, and `evidence_ids|evidence_list`. Accepted document aliases are `doc_id|id` and `text|passage|contents`. Sampling is query-level, deterministic, and never drops evidence documents for kept queries.

## Smoke Experiment

```bash
uv run python -m proj.src.cli run-smoke \
  --output-dir proj/out/smoke \
  --budget 18 \
  --top-n 5
```

Expected outputs:

- `proj/out/smoke/candidates.jsonl`
- `proj/out/smoke/selections.jsonl`
- `proj/out/smoke/per_query_metrics.jsonl`
- `proj/out/smoke/aggregate_metrics.csv`
- `proj/out/smoke/optimal_checks.csv`
- `proj/out/smoke/metrics.json`
- `proj/out/smoke/summary.md`

The smoke workflow uses `proj/data/fixtures`, so it can run without network access.

## Main Experiment

Run the report-oriented fixture grid:

```bash
uv run python -m proj.src.cli run-experiment \
  --data-dir proj/data/processed/fixture-multihop \
  --output-dir proj/out/main/fixture_multihop_q3_s13 \
  --dataset-name fixture-multihop \
  --split fixture \
  --budgets 12,18 \
  --candidate-sizes 3,5 \
  --selectors top_ranked,relevance_ratio,random_seeded,mmr,budgeted_greedy \
  --objectives coverage,diversity,combined \
  --combined-lambdas 1.0 \
  --seed 13 \
  --optimal-max-items 5 \
  --overwrite
```

For a sampled MultiHop-RAG slice, point `--data-dir` at the processed cache from the split-format command above and use the planned report grid:

```bash
uv run python -m proj.src.cli run-experiment \
  --data-dir proj/data/processed/multihop-q200 \
  --output-dir proj/out/main/multihop_q200_s13 \
  --dataset-name multihop-rag \
  --split train-sample \
  --budgets 80,160,320 \
  --candidate-sizes 10,20,40 \
  --selectors top_ranked,relevance_ratio,random_seeded,mmr,budgeted_greedy \
  --objectives coverage,diversity,combined \
  --combined-lambdas 1.0 \
  --seed 13 \
  --sample-size 200 \
  --sample-seed 13 \
  --optimal-max-items 16 \
  --overwrite
```

The runner refuses to overwrite an existing output directory unless `--overwrite` is set. Re-running the same config with the same seed reproduces identical `candidates.jsonl`, `selections.jsonl`, `per_query_metrics.jsonl`, `aggregate_metrics.csv`, and `optimal_checks.csv`.

Stable run outputs:

- `config.json`: config snapshot and query IDs
- `sample_manifest.jsonl`: query IDs in the processed run
- `candidates.jsonl`: query ID, document ID, rank, score, text, token cost, and `top_n`
- `selections.jsonl`: selected document IDs, selector/objective labels, budget, top-N, cost, objective value, and deterministic runtime units
- `per_query_metrics.jsonl`: evidence recall/precision/F1, redundancy, budget utilization, selected count, and runtime units
- `aggregate_metrics.csv` and `aggregate_metrics.md`: grouped mean/std metrics by method, budget, and candidate size
- `optimal_checks.csv`: greedy-vs-optimal checks for candidate sets under the exhaustive-search threshold
- `summary.md` and `run.log`

## Report Artifacts

Generate Markdown artifacts from a completed run:

```bash
uv run python -m proj.src.cli generate-artifacts \
  --run-dir proj/out/main/fixture_multihop_q3_s13 \
  --output-dir proj/report/figures/fixture_multihop_q3_s13
```

Expected artifact files:

- `comparison_table.md`: evidence recall/F1, redundancy, budget utilization, and runtime units across methods
- `metric_by_budget.md`: metric-vs-budget table
- `runtime_by_candidate_size.md`: scalability table over candidate sizes
- `optimal_checks.md`: small-instance greedy-vs-optimal summary

Artifact generation validates required columns and fails fast if required methods are absent.

## Runtime and Storage Assumptions

The bundled fixture workflow runs in under a second and writes small JSONL/CSV/Markdown files. The sampled 200-query MultiHop-RAG grid is designed for local CPU execution; runtime scales with `queries x budgets x candidate_sizes x methods`, and exhaustive optimal checks are skipped above `--optimal-max-items`.

Output directories under `proj/out/` and generated PDFs/figures are ignored by git. The source fixtures, code, tests, proposal, and report skeleton are tracked.

## Proposal Mapping

- Topic 11, LLM context selection: `proj/src/cli.py` and `proj/src/experiments.py`
- Knapsack/budget constraint and greedy approximation: `proj/src/selectors.py`
- Coverage/diversity submodular objectives: `proj/src/objectives.py`
- Retrieval and similarity features: `proj/src/retrieval.py`, `proj/src/features.py`
- Evidence coverage, redundancy, runtime, and aggregate metrics: `proj/src/metrics.py`
- Greedy-vs-optimal validation: `optimal_checks.csv` from `run-experiment`
- Report-ready tables: `proj/src/artifacts.py`
- Reproduction commands: this README and `proj/report/report.typ`
