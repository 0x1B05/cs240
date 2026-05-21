#import "@preview/charged-ieee:0.1.4": ieee
#import "@preview/tablem:0.3.0": tablem, three-line-table

#show: ieee.with(
  title: [Budgeted Submodular Context Selection for Retrieval-Augmented Generation],
  abstract: [
    Retrieval-augmented generation (RAG) systems usually retrieve a ranked list of candidate passages and place the top candidates into a language model's context window. This project studies the second step as a budgeted submodular maximization problem: given retrieved passages and a token budget, select a subset that covers the query evidence while avoiding redundant passages. The implementation adapts Lin and Bilmes's submodular summarization objectives to RAG context selection, compares them against top-ranked retrieval, relevance-per-token, seeded random, and MMR baselines, and produces reproducible evidence-coverage, redundancy, budget-utilization, runtime, and greedy-vs-optimal artifacts.
  ],
  authors: (
    (
      name: "Junqi Liu - 2025234339",
      department: [School of Information Science and Technology],
      organization: [ShanghaiTech University],
      location: [Shanghai, China],
      email: "liujq2025@shanghaitech.edu.cn",
    ),
    (
      name: "Team Member 2",
      department: [School of Information Science and Technology],
      organization: [ShanghaiTech University],
      location: [Shanghai, China],
      email: "member2@shanghaitech.edu.cn",
    ),
    (
      name: "Team Member 3",
      department: [School of Information Science and Technology],
      organization: [ShanghaiTech University],
      location: [Shanghai, China],
      email: "member3@shanghaitech.edu.cn",
    ),
    (
      name: "Zhixin Xiao - 2025234366",
      department: [School of Information Science and Technology],
      organization: [ShanghaiTech University],
      location: [Shanghai, China],
      email: "xiaozhx2025@shanghaitech.edu.cn",
    ),
    (
      name: "Team Member 5",
      department: [School of Information Science and Technology],
      organization: [ShanghaiTech University],
      location: [Shanghai, China],
      email: "member5@shanghaitech.edu.cn",
    ),
  ),
  index-terms: (
    "Submodular maximization",
    "budgeted maximum coverage",
    "knapsack constraint",
    "retrieval-augmented generation",
    "context selection",
  ),
  bibliography: bibliography("refs.bib"),
)

= Introduction and Background

RAG systems use retrieval to expose external knowledge to a language model, but the retrieved list still has to be packed into a finite context window. Sending passages by retrieval rank alone ignores token costs and often repeats near-duplicate evidence. This project matches course topic 11, "LLM context selection", by reducing the packing step to a classical optimization problem: select a subset of passages under a knapsack-style token budget while maximizing a coverage/diversity objective.

The algorithmic question is whether Lin-Bilmes-style monotone submodular objectives can improve evidence coverage and reduce redundancy compared with rank-only or reranking baselines. The implementation is deliberately independent of live LLM calls so the core algorithmic behavior is reproducible.

= Related Work

Lin and Bilmes propose a family of submodular objectives for document summarization that combine coverage and diversity under a length budget @lin2011submodular. We reproduce the method-level comparison between coverage-only, diversity-only, and combined objectives, but adapt the items from sentences/documents in summarization to retrieved RAG passages.

MMR reranking trades off query relevance against similarity to already selected items @carbonell1998mmr. It is a strong classical baseline because it directly penalizes redundancy without requiring a full submodular coverage objective. Budgeted maximum coverage provides the theoretical background for choosing valuable sets under item costs and motivates the greedy approximation lens used in the project @khuller1999budgeted. RAG and MultiHop-RAG provide the modern system setting and evidence-based evaluation target @lewis2020rag @tang2024multihoprag.

= Problem Formulation and Method

For a query $q$, a retriever returns candidate passages $C = {d_1, ..., d_n}$. Passage $d_i$ has positive token cost $c_i$, and the context budget is $B$. The context selector outputs $S subset.eq C$:

$ max_(S subset.eq C) F_q(S) quad "subject to" quad sum_(d_i in S)c_i <= B. $

The implementation computes nonnegative query relevance scores and pairwise candidate similarities using TF-IDF cosine similarity. It evaluates three objectives:

+ Coverage-only: selected passages represent the candidate pool through maximum pairwise similarity.
+ Diversity-only: selected relevance mass receives a concave square-root reward.
+ Combined: coverage plus $lambda$ times diversity.

Coverage is monotone submodular because adding an item can only increase the maximum similarity representation of each candidate, and the marginal increase shrinks as more representatives are selected. The square-root diversity term is concave over nonnegative relevance mass, so it also has diminishing returns. The direct budgeted greedy algorithm adds the feasible item with the largest marginal gain per token until no item fits.

= Implementation

The code is under `proj/src/` and is managed with `uv`.

#three-line-table[
  | *Module* | *Role* |
  | :------ | :----- |
  | `data.py` | Typed records, validation, JSONL helpers, and MultiHop-style raw-to-cache preparation. |
  | `retrieval.py` | Deterministic TF-IDF top-$N$ candidate generation with stable tie-breaking. |
  | `features.py` | Token costs, query relevance, and candidate-candidate similarity matrices. |
  | `objectives.py` | Coverage, diversity, and combined submodular objectives. |
  | `selectors.py` | Budgeted greedy, top-ranked, relevance-ratio, seeded-random, MMR, and exhaustive optimal search. |
  | `metrics.py` | Evidence recall/precision/F1, redundancy, budget utilization, selected count, and aggregate statistics. |
  | `experiments.py` | Configuration-driven grid runner, stable output schema, and optimal checks. |
  | `artifacts.py` | Report-ready comparison, budget, runtime, and optimal-check tables. |
]

The command-line interface exposes `prepare-data`, `generate-candidates`, `select-evaluate`, `run-experiment`, `generate-artifacts`, and `run-smoke`. Raw MultiHop-style records are normalized once into `queries.jsonl`, `corpus.jsonl`, and `manifest.json`. The main runner can generate retrieval candidates internally, while the staged `generate-candidates` to `select-evaluate` path validates a saved candidate JSONL file before selection.

= Experiments

== Fixture Smoke Test

The smoke workflow is:

```text
uv run python -m proj.src.cli run-smoke --output-dir proj/out/smoke --budget 18 --top-n 5
```

It writes candidates, selections, per-query metrics, aggregate metrics, optimal checks, `metrics.json`, and a Markdown summary under `proj/out/smoke`.

== MultiHop-Style Evaluation

The local no-network fixture preparation command is:

```text
uv run python -m proj.src.cli prepare-data --raw-queries proj/data/fixtures/multihop_raw.jsonl --schema embedded --output-dir proj/data/processed/fixture-multihop --seed 13 --overwrite
```

The report-oriented fixture run is:

```text
uv run python -m proj.src.cli run-experiment --data-dir proj/data/processed/fixture-multihop --output-dir proj/out/main/fixture_multihop_q3_s13 --dataset-name fixture-multihop --split fixture --budgets 12,18 --candidate-sizes 3,5 --selectors top_ranked,relevance_ratio,random_seeded,mmr,budgeted_greedy --objectives coverage,diversity,combined --combined-lambdas 1.0 --seed 13 --optimal-max-items 5 --overwrite
```

A larger sampled MultiHop-RAG run uses the same command shape with `--data-dir proj/data/processed/multihop-q200`, `--sample-size 200`, `--sample-seed 13`, `--budgets 80,160,320`, and `--candidate-sizes 10,20,40`. The runner applies query-level sampling before retrieval, records the sampled query IDs in `sample_manifest.jsonl`, and writes `config.json`, `candidates.jsonl`, `selections.jsonl`, `per_query_metrics.jsonl`, `aggregate_metrics.csv`, `aggregate_metrics.md`, `optimal_checks.csv`, `summary.md`, and `run.log`.

The staged candidate-file workflow is:

```text
uv run python -m proj.src.cli generate-candidates --data-dir proj/data/fixtures --output-path proj/out/candidates/fixture_top3.jsonl --top-n 3
uv run python -m proj.src.cli select-evaluate --data-dir proj/data/fixtures --candidates-path proj/out/candidates/fixture_top3.jsonl --output-dir proj/out/staged/fixture_top3_b18 --budget 18 --seed 13 --overwrite
```

The downstream stage rejects candidate files missing `query_id`, `doc_id`, `rank`, `score`, `text`, `token_cost`, or `top_n`, and it checks query/document compatibility before evaluating selectors.

== Report Artifacts

Tables are generated from a completed run:

```text
uv run python -m proj.src.cli generate-artifacts --run-dir proj/out/main/fixture_multihop_q3_s13 --output-dir proj/report/figures/fixture_multihop_q3_s13
```

The stable artifact paths are:

+ `proj/report/figures/fixture_multihop_q3_s13/comparison_table.md`
+ `proj/report/figures/fixture_multihop_q3_s13/metric_by_budget.md`
+ `proj/report/figures/fixture_multihop_q3_s13/runtime_by_candidate_size.md`
+ `proj/report/figures/fixture_multihop_q3_s13/optimal_checks.md`

These artifacts cover evidence recall/F1, redundancy, budget utilization, deterministic runtime units, metric-vs-budget trends, candidate-size scalability, and greedy-vs-optimal checks.

= Discussion

Top-ranked selection is simple and often strong when the retriever ranks all gold evidence early, but it has no mechanism for token cost or redundancy. Relevance-ratio adds a knapsack-aware cost normalization. MMR adds a redundancy penalty but optimizes a local reranking score rather than a global coverage objective. The submodular methods explicitly value coverage over the candidate pool and expose the connection to budgeted maximum coverage.

The main deviation from Lin and Bilmes is the application domain. Their items are summarization units; our items are retrieved passages for a query. Their summary length budget becomes an LLM context-token budget, and our primary metric is evidence coverage instead of human summary quality. The method-level reproduction remains the same: compare coverage-only, diversity-only, and combined objectives under greedy budgeted selection.

= Reproducibility

Exact commands and output paths are documented in `proj/README-EXPERIMENTS.md`. The deterministic settings used by the fixture report run are:

#three-line-table[
  | *Field* | *Value* |
  | :---- | :---- |
  | Processed data | `proj/data/processed/fixture-multihop` |
  | Raw fixture | `proj/data/fixtures/multihop_raw.jsonl` |
  | Main run | `proj/out/main/fixture_multihop_q3_s13` |
  | Artifact dir | `proj/report/figures/fixture_multihop_q3_s13` |
  | Seed | `13` |
  | Budgets | `12,18` |
  | Candidate sizes | `3,5` |
  | Selectors | `top_ranked,relevance_ratio,random_seeded,mmr,budgeted_greedy` |
  | Objectives | `coverage,diversity,combined` |
]

The implementation refuses accidental overwrite unless `--overwrite` is passed. With the same input cache and seed, the candidate, selection, metric, aggregate, and optimal-check files are byte-stable.
