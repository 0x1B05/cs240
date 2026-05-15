#import "@preview/charged-ieee:0.1.4": ieee
#import "@preview/tablem:0.3.0": tablem, three-line-table

#show: ieee.with(
  title: [Budgeted Submodular Context Selection for Retrieval-Augmented Generation],
  abstract: [
    Retrieval-augmented generation (RAG) systems usually retrieve a ranked list of candidate passages and place the top candidates into a language model's context window. This simple strategy ignores the token budget and often selects redundant passages. We propose to study RAG context selection as a budgeted submodular maximization problem: given retrieved candidates and a context budget, select a subset that maximizes query-relevant coverage while reducing redundancy. Our project will reproduce the core greedy optimization framework of Lin and Bilmes for submodular document summarization, adapt it to RAG context selection, and compare it with top-ranked retrieval, relevance-only selection, and maximal marginal relevance.
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
      name: "TODO: Team Member 2",
      department: [School of Information Science and Technology],
      organization: [ShanghaiTech University],
      location: [Shanghai, China],
      email: "TODO",
    ),
    (
      name: "TODO: Team Member 3",
      department: [School of Information Science and Technology],
      organization: [ShanghaiTech University],
      location: [Shanghai, China],
      email: "TODO",
    ),
    (
      name: "Zhixin Xiao - 2025234366",
      department: [School of Information Science and Technology],
      organization: [ShanghaiTech University],
      location: [Shanghai, China],
      email: "xiaozhx2025@shanghaitech.edu.cn",
    ),
    (
      name: "TODO: Team Member 5",
      department: [School of Information Science and Technology],
      organization: [ShanghaiTech University],
      location: [Shanghai, China],
      email: "TODO",
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

Retrieval-augmented generation systems must choose which retrieved passages fit into a limited context window. This project studies that choice as a budgeted context selection problem rather than a plain top-$k$ ranking problem.

// TODO: Expand with RAG motivation and the connection to topic 11 in the course project list.

= Related Work

We focus on Lin and Bilmes's submodular summarization framework, MMR reranking, and budgeted maximum coverage.

// TODO: Summarize @lin2011submodular, @carbonell1998mmr, and @khuller1999budgeted.

= Problem Formulation and Method

Given a query $q$, candidate passages $C = {d_1, ..., d_n}$, token costs $c_i$, and budget $B$, select $S subset.eq C$ to maximize a query-aware objective subject to $sum_(d_i in S)c_i <= B$.

The implementation compares coverage-only, diversity-only, and combined Lin-Bilmes-style objectives optimized by budgeted greedy selection.

// TODO: Import polished formalization and complexity notes from `theory.md`.

= Implementation

The current implementation provides:

- deterministic fixture loading;
- TF-IDF retrieval and candidate-candidate similarity;
- budgeted greedy selection;
- top-ranked, relevance-ratio, seeded-random, and MMR baselines;
- evidence coverage, redundancy, and budget-utilization metrics;
- a `uv`-managed smoke workflow.

// TODO: Add module-level implementation details after the real-data path is added.

= Experiments

== Fixture Smoke Test

The smoke workflow is run with:

```text
uv run python -m proj.src.cli run-smoke --output-dir proj/out/smoke --budget 18 --top-n 5
```

It writes candidate sets, selections, per-query metrics, aggregate metrics, and a Markdown summary under `proj/out/smoke`.

== MultiHop-RAG Evaluation

// TODO: Add sampled MultiHop-RAG setup, budgets, candidate sizes, and results.

= Discussion

// TODO: Discuss how the submodular objectives differ from rank-only baselines and explain deviations from the original Lin-Bilmes summarization setup.

= Reproducibility

// TODO: Add final commands, seeds, dataset sample size, and output paths.
