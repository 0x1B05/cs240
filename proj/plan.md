# Budgeted Submodular Context Selection Experiment Plan

## Goal Description

Implement the experiment described in `proj/proposal/proposal.typ`: evaluate budgeted submodular context selection for retrieval-augmented generation. The implementation should turn retrieved candidate passages into fixed-budget context sets, compare Lin-Bilmes-style submodular objectives against classical baselines, and produce reproducible metrics and plots/tables for the final course report.

The project must demonstrate the algorithmic connection between a modern RAG context selection problem and classical knapsack, coverage, greedy approximation, and submodular optimization ideas. The target deliverable is a runnable experiment pipeline under `proj/` with tests, scripts, cached outputs, and documentation sufficient for another team member to reproduce the core results.

## Acceptance Criteria

Following TDD philosophy, each criterion includes positive and negative tests for deterministic verification.

- AC-1: Project package and command-line entry points are present and runnable
  - Positive Tests (expected to PASS):
    - `uv run pytest proj/tests` discovers and runs unit tests without import errors.
    - `uv run python -m proj.src.cli --help` prints available commands for data preparation, retrieval, selection, evaluation, and experiment execution.
    - `uv run python -m proj.src.cli run-smoke --output-dir proj/out/smoke` completes on a tiny fixture dataset and writes metrics JSON.
  - Negative Tests (expected to FAIL):
    - Running an unknown CLI command exits nonzero and prints a concise usage error.
    - Running a command with a missing required input path exits nonzero instead of silently creating empty outputs.

- AC-2: Dataset loading supports deterministic local fixtures and MultiHop-RAG-style records
  - Positive Tests (expected to PASS):
    - A fixture dataset with queries, corpus documents, gold evidence IDs, and answers loads into typed records.
    - Loader validation accepts records containing `query`, `answer`, `evidence_list`, and candidate corpus text or IDs.
    - Re-running fixture loading produces stable query/document IDs and identical normalized text.
  - Negative Tests (expected to FAIL):
    - A query with no ID or no query text is rejected.
    - A gold evidence ID missing from the corpus is reported as a validation error.
    - Empty corpus input is rejected before retrieval or selection begins.

- AC-3: Retrieval candidate generation produces reproducible top-N candidates
  - Positive Tests (expected to PASS):
    - BM25 or TF-IDF retrieval returns at most `N` candidates per query in deterministic score order.
    - Ties are broken by stable document ID ordering.
    - Candidate files include query ID, document ID, retrieval rank, retrieval score, text, and token cost.
  - Negative Tests (expected to FAIL):
    - Passing `N <= 0` is rejected.
    - Candidate generation rejects documents with nonpositive token costs.
    - Candidate files missing required columns are rejected by downstream selection.

- AC-4: Similarity and feature construction are deterministic and reusable
  - Positive Tests (expected to PASS):
    - Pairwise similarity matrices are square, symmetric, and aligned with candidate ordering.
    - Query relevance scores are present for every candidate.
    - Token costs are positive integers and are stable across repeated runs.
  - Negative Tests (expected to FAIL):
    - A similarity matrix whose shape does not match the candidate set is rejected.
    - A candidate with missing relevance score is rejected.
    - Negative or NaN similarities are rejected unless explicitly normalized before use.

- AC-5: Submodular objective implementations behave correctly on controlled examples
  - Positive Tests (expected to PASS):
    - Coverage-only, diversity-only, and combined objectives return `0` for the empty set.
    - Adding an item never decreases the monotone coverage and diversity objectives on nonnegative features.
    - Marginal gains show diminishing returns on a hand-crafted example where an aspect is already covered.
    - Combined objective equals coverage plus `lambda` times diversity for tested selections.
  - Negative Tests (expected to FAIL):
    - Objectives reject item indices outside the candidate range.
    - Objectives reject negative `lambda`.
    - Objectives reject feature matrices with inconsistent dimensions.

- AC-6: Budgeted greedy selection enforces the knapsack constraint and uses marginal-gain-per-cost ranking
  - Positive Tests (expected to PASS):
    - Selected item costs never exceed the configured budget.
    - On a small hand-crafted instance, greedy selects the item with the largest feasible marginal gain per token at each step.
    - If no item fits the budget, the selection is empty and the status explains why.
    - Lazy greedy, if implemented, returns the same selected set and objective value as direct greedy on deterministic fixtures.
  - Negative Tests (expected to FAIL):
    - A budget of `0` or less is rejected unless a command explicitly supports empty-output smoke behavior.
    - Items with cost greater than budget are never selected.
    - Greedy rejects objective objects that do not expose marginal gain evaluation.

- AC-7: Baselines are implemented for fair comparison
  - Positive Tests (expected to PASS):
    - Top-ranked retrieval baseline selects candidates in retrieval-rank order until the budget is full.
    - Relevance-only baseline selects by relevance-to-cost ratio with stable tie-breaking.
    - Random baseline is deterministic when a seed is provided.
    - MMR baseline penalizes redundancy and respects the same token budget.
  - Negative Tests (expected to FAIL):
    - Random baseline without an explicit seed is rejected in experiment mode.
    - MMR rejects `lambda` values outside the configured range.
    - Baselines cannot read candidate files generated for a different query set without a validation error.

- AC-8: Evidence coverage and redundancy metrics are computed consistently
  - Positive Tests (expected to PASS):
    - Evidence recall is `1.0` when all gold evidence IDs are selected and `0.0` when none are selected.
    - Evidence precision/F1 handle empty selections without division-by-zero crashes.
    - Redundancy metrics increase on a fixture where selected passages are near duplicates.
    - Metrics JSON includes per-query values and aggregate mean/std values.
  - Negative Tests (expected to FAIL):
    - Metrics reject selections containing document IDs outside the candidate set.
    - Metrics reject queries whose gold evidence list is missing.
    - Aggregate metrics reject mixed experiment configurations unless grouped explicitly.

- AC-9: Small-instance optimal checks validate greedy behavior against exhaustive search
  - Positive Tests (expected to PASS):
    - Exhaustive search finds the optimal feasible subset for tiny instances.
    - Greedy objective value is reported alongside optimal objective value and approximation ratio.
    - Exhaustive search is only enabled when candidate count is below a configured safety threshold.
  - Negative Tests (expected to FAIL):
    - Exhaustive search refuses candidate sets above the threshold.
    - Optimal-check code rejects non-deterministic objectives.
    - Approximation ratio is not reported when the optimal value is zero unless handled explicitly.

- AC-10: Experiment runner produces reproducible outputs for the main comparisons
  - Positive Tests (expected to PASS):
    - A single command runs the main grid over budgets, candidate sizes, selectors, and objectives.
    - Output directories contain config snapshots, per-query selections, metrics, aggregate tables, and logs.
    - Re-running the same config with the same seed produces identical selection and metric files on the fixture dataset.
  - Negative Tests (expected to FAIL):
    - The runner refuses to overwrite existing outputs unless `--overwrite` is set.
    - Invalid budget or candidate-size grids are rejected.
    - A run with missing intermediate files fails with an actionable error.

- AC-11: Report artifacts summarize algorithmic and empirical findings
  - Positive Tests (expected to PASS):
    - Scripts generate at least one table comparing evidence recall/F1, redundancy, budget utilization, and runtime across methods.
    - Scripts generate scalability data over increasing candidate set sizes.
    - Generated artifacts are stored under `proj/out/` or `proj/report/figures/` with stable filenames.
  - Negative Tests (expected to FAIL):
    - Artifact generation rejects metrics files with incompatible schemas.
    - Plot/table generation fails fast if a required selector or objective is absent from the results.

- AC-12: Documentation explains how to reproduce the experiment
  - Positive Tests (expected to PASS):
    - `proj/README-EXPERIMENTS.md` documents environment setup, data download/preparation, smoke test, main run, and artifact generation.
    - The documentation lists expected runtime/storage assumptions and how to run a small fixture-only workflow without network access.
    - The documentation maps outputs back to the proposal requirements.
  - Negative Tests (expected to FAIL):
    - Documented commands that refer to nonexistent files or modules are caught by a smoke verification script.
    - Missing dataset prerequisites are reported before the main experiment starts.

- AC-13: Theoretical analysis artifact is produced for the final report
  - Positive Tests (expected to PASS):
    - `proj/report/theory.md` states the formal optimization problem, input/output, objective, and budget constraint.
    - The artifact explains why the coverage, diversity, and combined objectives are monotone submodular under the implementation's nonnegative feature assumptions.
    - The artifact derives or tabulates the time complexity of direct greedy, lazy greedy if implemented, top-ranked selection, relevance-only selection, MMR, and exhaustive search.
    - The artifact states which Lin-Bilmes method-level results are reproduced and what is adapted from summarization to RAG context selection.
  - Negative Tests (expected to FAIL):
    - The artifact omits the token-budget constraint or the selected-subset optimization objective.
    - The artifact claims an approximation guarantee without stating required assumptions and the relationship to budgeted maximum coverage or monotone submodular maximization.
    - The artifact describes the RAG application without connecting it back to knapsack, coverage, greedy approximation, or submodularity.

- AC-14: Final report skeleton and result integration are prepared
  - Positive Tests (expected to PASS):
    - `proj/report/report.typ` or `proj/report/report.md` contains sections for background, related work, method, implementation, experiments, discussion, and optional extensions.
    - The report skeleton references generated tables and figures using stable paths under `proj/out/` or `proj/report/figures/`.
    - The report includes a subsection explaining deviations from the original Lin-Bilmes summarization setup.
    - The report includes a reproducibility appendix with commands, configuration files, seeds, dataset sample size, and output locations.
  - Negative Tests (expected to FAIL):
    - The report references missing result files or figure paths.
    - The report omits baseline comparison, method-level objective comparison, or scalability analysis.
    - The report omits the implementation details needed to reproduce the core experiment.

- AC-15: Python dependencies and experiment commands are managed with `uv`
  - Positive Tests (expected to PASS):
    - `proj/pyproject.toml` declares the project package, runtime dependencies, and development test dependencies.
    - `uv sync` creates or updates the project environment without requiring ad hoc `pip install` commands.
    - `uv run pytest proj/tests` is the documented test command.
    - `uv run python -m proj.src.cli run-smoke --output-dir proj/out/smoke` is the documented smoke command.
    - `proj/README-EXPERIMENTS.md` documents dependency setup and experiment execution using `uv`.
  - Negative Tests (expected to FAIL):
    - Documentation instructs users to install required packages manually with untracked `pip install` commands.
    - Tests or experiment commands rely on undeclared packages.
    - A clean environment cannot run the fixture smoke test after `uv sync`.

## Path Boundaries

Path boundaries define the acceptable range of implementation quality and choices.

### Upper Bound (Maximum Acceptable Scope)

The most comprehensive acceptable implementation includes a Python package under `proj/src/`, deterministic fixture tests under `proj/tests/`, a CLI covering data preparation through artifact generation, BM25 or TF-IDF retrieval, Lin-Bilmes-style coverage/diversity/combined objectives, direct greedy plus lazy greedy, top-ranked/relevance-only/random/MMR baselines, evidence and redundancy metrics, brute-force optimal checks for tiny instances, experiment grids for MultiHop-RAG, and report-ready CSV/Markdown/PNG artifacts.

Optional extensions may include dense embedding similarity and a small LLM answer-quality evaluation, but only after all required acceptance criteria are satisfied.

### Lower Bound (Minimum Acceptable Scope)

The minimum viable implementation includes deterministic fixture tests, a local fixture dataset, a candidate-generation path using TF-IDF or BM25, token-budgeted greedy selection for coverage-only/diversity-only/combined objectives, top-ranked/relevance-only/MMR/random baselines, evidence recall/F1 and runtime metrics, a smoke experiment, and documentation showing how to run the core workflow.

The minimum implementation may use a sampled subset of MultiHop-RAG if downloading or processing the full dataset is too expensive, as long as the sampling is reproducible and clearly documented.

### Allowed Choices

- Can use: `uv` for dependency, virtual environment, test, and experiment command management.
- Can use: Python 3, `numpy`, `scipy`, `pandas`, `scikit-learn`, `pytest`, `matplotlib`, `seaborn`, `tqdm`, `datasets`, `rank-bm25`, `typer`, `argparse`, `pydantic`, JSONL/CSV/Parquet caches.
- Can use: TF-IDF cosine similarity as the default similarity feature; BM25 or TF-IDF retrieval as the default retriever.
- Can use: sentence embeddings only as an optional extension after the deterministic pipeline is complete.
- Can use: a sampled MultiHop-RAG split for the main report if full-corpus processing is too slow.
- Can use: a clearly documented MultiHop-style fallback fixture or a HotpotQA/BEIR subset if MultiHop-RAG download or schema processing blocks progress; the fallback must preserve gold evidence IDs, candidate passages, budgets, baselines, and runtime reporting.
- Cannot use: unstated manual filtering of results to improve metrics.
- Cannot use: non-deterministic experiment settings without recording and fixing seeds.
- Cannot use: live LLM API calls as a required part of the core experiment.
- Cannot use: undocumented manual dependency installation as a required setup step.
- Cannot use: code paths outside `proj/` for project implementation, except shared tooling or environment files if explicitly documented.

## Feasibility Hints and Suggestions

> **Note**: This section is for reference and understanding only. These are conceptual suggestions, not prescriptive requirements.

### Conceptual Approach

One practical architecture is:

1. Store normalized data as JSONL:
   - `proj/data/raw/` for downloaded or manually placed source files.
   - `proj/data/processed/queries.jsonl`
   - `proj/data/processed/corpus.jsonl`
   - `proj/data/processed/qrels.jsonl`
2. Generate candidate sets:
   - rank corpus documents for each query using TF-IDF or BM25.
   - write `proj/out/candidates/top{N}.jsonl`.
3. Build features:
   - token cost: simple whitespace/tokenizer count.
   - relevance: retrieval score or query-document TF-IDF cosine.
   - similarity: candidate-candidate TF-IDF cosine.
   - optional clusters: KMeans over TF-IDF vectors or threshold-based grouping.
4. Run selectors:
   - `top_ranked`
   - `relevance_ratio`
   - `random_seeded`
   - `mmr`
   - `submodular_coverage`
   - `submodular_diversity`
   - `submodular_combined`
5. Evaluate:
   - evidence recall, precision, F1.
   - budget utilization.
   - average pairwise selected similarity.
   - objective value.
   - runtime per query.
6. Generate report artifacts:
   - aggregate comparison tables.
   - metric-vs-budget plots.
   - runtime-vs-candidate-size plots.
   - small optimal-check table.

### Relevant References

- `proj/proposal/proposal.typ` - source proposal defining the algorithms, baselines, dataset, and evaluation plan.
- `proj/README.md` - course requirements and deliverables.
- `proj/proposal/papers/lin-bilmes-2011-submodular-summarization.pdf` - main method paper.
- `proj/proposal/papers/carbonell-goldstein-1998-mmr.pdf` - MMR baseline paper.
- `proj/proposal/papers/khuller-moss-naor-1999-budgeted-maximum-coverage.pdf` - budgeted coverage theory background.
- `proj/proposal/papers/tang-etal-2024-multihop-rag.pdf` - dataset background.

## Dependencies and Sequence

### Milestones

1. Repository scaffolding and deterministic fixtures
   - Create `proj/pyproject.toml` for `uv`-managed runtime and development dependencies.
   - Create `proj/src/` Python package structure and `proj/tests/`.
   - Add a tiny fixture dataset with 2-3 queries, 6-10 documents, and known evidence IDs.
   - Add CLI skeleton and smoke command runnable through `uv run`.

2. Data loading and retrieval candidates
   - Implement typed data records and validation.
   - Implement fixture loading first.
   - Implement MultiHop-RAG preparation path with local-cache support.
   - Implement deterministic top-N retrieval and candidate serialization.

3. Feature construction
   - Implement token-cost counting.
   - Implement query relevance scores.
   - Implement candidate-candidate similarity matrices.
   - Add validation for matrix alignment and nonnegative features.

4. Objective functions and selectors
   - Implement coverage-only, diversity-only, and combined submodular objectives.
   - Implement budgeted greedy selection.
   - Implement top-ranked, relevance-only, random, and MMR baselines.
   - Add lazy greedy only after direct greedy tests pass.

5. Metrics and optimal checks
   - Implement evidence recall/precision/F1.
   - Implement redundancy and budget utilization.
   - Implement runtime recording.
   - Implement exhaustive optimal search for small candidate sets.

6. Experiment runner and artifacts
   - Implement configuration-driven run command.
   - Run smoke fixtures first.
   - Run sampled MultiHop-RAG experiments.
   - Generate aggregate tables and plots.

7. Documentation and final report support
   - Write `proj/README-EXPERIMENTS.md`.
   - Document `uv sync`, `uv run pytest proj/tests`, and `uv run python -m proj.src.cli ...` as the supported commands.
   - Write `proj/report/theory.md` with formalization, submodularity assumptions, complexity analysis, and reproduction/adaptation notes.
   - Create `proj/report/report.typ` or `proj/report/report.md` as the final report skeleton.
   - Record exact commands and outputs used for the report.
   - Link generated tables and figures into the report skeleton.
   - Summarize deviations from the proposal, if any.

## Task Breakdown

Each task includes exactly one routing tag:
- `coding`: implemented by Claude
- `analyze`: executed via Codex (`/humanize:ask-codex`)

| Task ID | Description | Target AC | Tag (`coding`/`analyze`) | Depends On |
|---------|-------------|-----------|----------------------------|------------|
| task1 | Scaffold `proj/pyproject.toml`, `proj/src/`, `proj/tests/`, fixture data, and CLI skeleton with `--help` and `run-smoke` placeholders runnable through `uv run` | AC-1, AC-12, AC-15 | coding | - |
| task2 | Implement typed dataset records, fixture loader, and validation errors | AC-2 | coding | task1 |
| task3 | Analyze MultiHop-RAG field schema and decide the smallest robust local cache format | AC-2, AC-3 | analyze | task2 |
| task4 | Implement retrieval candidate generation and candidate file schema | AC-3 | coding | task2, task3 |
| task5 | Implement token cost, relevance, similarity feature construction, and validation | AC-4 | coding | task4 |
| task6 | Implement coverage, diversity, combined objective classes and marginal gain tests | AC-5 | coding | task5 |
| task7 | Implement direct budgeted greedy selector and optional lazy greedy equivalence tests | AC-6 | coding | task6 |
| task8 | Implement top-ranked, relevance-only, seeded random, and MMR baselines | AC-7 | coding | task5 |
| task9 | Implement evidence metrics, redundancy metrics, budget utilization, and runtime aggregation | AC-8 | coding | task7, task8 |
| task10 | Implement exhaustive search for tiny optimal checks and approximation reporting | AC-9 | coding | task6 |
| task11 | Analyze experimental grid choices for budgets, candidate sizes, and sampled MultiHop-RAG size to fit course timeline | AC-10, AC-11 | analyze | task9 |
| task12 | Implement configuration-driven experiment runner and output layout | AC-10 | coding | task9, task10, task11 |
| task13 | Implement table/plot artifact generation for report-ready comparisons | AC-11 | coding | task12 |
| task14 | Write `proj/README-EXPERIMENTS.md` and `uv`-based smoke verification command list | AC-12, AC-15 | coding | task12, task13 |
| task15 | Run fixture smoke tests, then sampled real-data experiments, and document any deviations | AC-10, AC-11, AC-12 | coding | task14 |
| task16 | Write `proj/report/theory.md` with formalization, submodularity assumptions, complexity analysis, and reproduction/adaptation notes | AC-13 | coding | task6, task7, task8, task10 |
| task17 | Create final report skeleton and link generated result artifacts | AC-14 | coding | task13, task15, task16 |

## Claude-Codex Deliberation

### Agreements

- The implementation should prioritize deterministic algorithmic comparisons over live LLM answer generation.
- The first runnable milestone should use local fixtures so tests and smoke runs do not depend on network access.
- MultiHop-RAG should be treated as the main real dataset, but a reproducible sampled subset is acceptable if full processing is too slow.
- Evidence recall/F1, redundancy, budget utilization, and runtime are required outputs; no fixed target metric threshold is promised by the proposal.
- The core reproduction target is method-level comparison of coverage-only, diversity-only, and combined submodular objectives under a token budget.

### Resolved Disagreements

- Full DUC summarization reproduction vs RAG adaptation: choose RAG adaptation because the approved proposal frames Lin-Bilmes as the main method to reproduce and adapt, not as a commitment to reproduce the original DUC benchmark.
- Dense embeddings vs TF-IDF default features: choose TF-IDF/BM25 as default because they are deterministic, lightweight, and sufficient for demonstrating the classical algorithmic connection; dense embeddings remain optional.
- Full MultiHop-RAG vs sampled experiments: choose sampled experiments as acceptable for the first implementation, with full-data support as an upper-bound extension.

### Convergence Status

- Final Status: `converged`

## Pending User Decisions

- DEC-1: Final team member names and student IDs for reports and documentation
  - Claude Position: Keep placeholders in code/docs until names are provided.
  - Codex Position: Same; placeholders should not block algorithm implementation.
  - Tradeoff Summary: Real names are needed for submission polish, but not for experiment correctness.
  - Decision Status: `ACCEPTED: use placeholders until final member information is available`

- DEC-2: Default real-data experiment size
  - Claude Position: Start with a small reproducible sampled subset, then scale if runtime permits.
  - Codex Position: Same; fixture-first and sampled-first reduces risk.
  - Tradeoff Summary: Smaller samples are easier to debug and enough for initial report figures, while larger samples strengthen empirical credibility.
  - Decision Status: `ACCEPTED: start with a reproducible sampled subset, then scale if runtime permits`

- DEC-3: Whether to include optional LLM answer-quality evaluation
  - Claude Position: Defer until deterministic evidence metrics and runtime analysis are complete.
  - Codex Position: Same; live LLM evaluation is not necessary for the algorithm course requirements.
  - Tradeoff Summary: Answer-quality evaluation may make the project more modern, but it adds cost, nondeterminism, and implementation time.
  - Decision Status: `ACCEPTED: defer LLM answer-quality evaluation until core deterministic experiments are complete`

## Implementation Notes

### Code Style Requirements

- Implementation code and comments must NOT contain plan-specific terminology such as "AC-", "Milestone", "Step", "Phase", or similar workflow markers.
- These terms are for plan documentation only, not for the resulting codebase.
- Use descriptive, domain-appropriate naming in code instead.
- Keep implementation under `proj/` unless a future decision explicitly expands the boundary.
- Manage dependencies with `uv` in `proj/pyproject.toml`; do not rely on undocumented global packages.
- Document and run commands through `uv run` unless a command is independent of the Python environment.
- Prefer small, testable modules:
  - `proj/src/data.py`
  - `proj/src/retrieval.py`
  - `proj/src/features.py`
  - `proj/src/objectives.py`
  - `proj/src/selectors.py`
  - `proj/src/metrics.py`
  - `proj/src/experiments.py`
  - `proj/src/cli.py`
- Keep generated data and results out of source modules:
  - `proj/data/raw/`
  - `proj/data/processed/`
  - `proj/out/`
  - `proj/report/figures/`
- Keep report support artifacts separate from executable experiment code:
  - `proj/report/theory.md`
  - `proj/report/report.typ` or `proj/report/report.md`
- Use explicit random seeds and write the effective config into every experiment output directory.
