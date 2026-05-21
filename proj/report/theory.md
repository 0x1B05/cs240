# Theory Notes

## Formal Problem

For a query `q`, let the retriever return candidate passages `C = {d_1, ..., d_n}`. Each passage has positive token cost `c_i`, and the context budget is `B`. The context selection problem is:

```text
maximize F_q(S)
subject to S subseteq C and sum_{d_i in S} c_i <= B
```

The implementation represents candidates by document IDs, token costs, query relevance scores, and nonnegative pairwise similarities.

## Objectives

The experiment pipeline implements three method-level objectives:

- coverage-only: rewards selected passages that represent many candidates through pairwise similarity;
- diversity-only: applies a concave square-root reward to selected relevance mass;
- combined: adds coverage plus a weighted diversity reward.

With nonnegative similarities and relevance scores, adding an item cannot reduce coverage or diversity. Coverage has diminishing returns because each candidate is represented by the maximum similarity to the selected set. The square-root diversity term is concave over accumulated nonnegative relevance, so additional relevance has smaller marginal benefit as selected relevance grows.

## Complexity

Let `n` be the candidate count for one query.

| Method | Time per query | Notes |
|---|---:|---|
| Top-ranked | `O(n)` | scans candidates in retrieval order |
| Relevance ratio | `O(n log n)` | sorts by relevance per token |
| Random seeded | `O(n)` | shuffles and scans |
| MMR | `O(n^2)` | recomputes redundancy against selected items |
| Direct greedy | `O(n^3)` worst case | up to `n` rounds, scans `n` candidates, objective recomputes coverage over `n` representatives |
| Exhaustive optimal | `O(2^n n)` | only for candidate sets under `--optimal-max-items` |

Lazy greedy is not required for the current report pipeline. If added, it should preserve direct greedy selections on deterministic fixtures.

## Reproduction and Adaptation

The implementation reproduces the Lin-Bilmes method-level comparison between coverage-only, diversity-only, and combined submodular objectives under a fixed budget. It adapts the original summarization setting to RAG by treating retrieved passages as candidate sentences/documents and token budget as the knapsack constraint.

The runner emits greedy-vs-optimal checks for small instances. If the candidate count is at or below the configured threshold, exhaustive search reports the optimal objective value, greedy objective value, costs, and approximation ratio. If the optimum is zero, the ratio is left undefined rather than reported as a misleading numeric value. Larger or baseline-only cases are written as skipped rows with machine-readable reasons.

## Report Artifacts

The aggregate metrics are grouped by selector, objective, lambda, budget, and candidate size. For every reported metric the runner writes mean and population standard deviation:

- evidence recall;
- evidence precision;
- evidence F1;
- redundancy;
- budget utilization;
- selected count;
- deterministic runtime units.

`proj/src/artifacts.py` converts the aggregate and optimal-check outputs into report-ready Markdown tables for method comparison, metric-vs-budget behavior, candidate-size runtime scaling, and optimal-check summaries.
