from __future__ import annotations

import json
from pathlib import Path
import time

from .data import Dataset, Selection, candidates_to_rows, load_dataset, selections_to_rows, write_jsonl
from .features import build_features
from .metrics import aggregate_metrics, evaluate_selection
from .objectives import combined_objective, coverage_objective, diversity_objective
from .retrieval import retrieve_top_n
from .selectors import budgeted_greedy, mmr, relevance_ratio, seeded_random, top_ranked


DEFAULT_BUDGET = 18
DEFAULT_TOP_N = 5


def run_smoke(data_dir: Path, output_dir: Path, budget: int = DEFAULT_BUDGET, top_n: int = DEFAULT_TOP_N, seed: int = 13) -> dict:
    dataset = load_dataset(data_dir)
    started = time.perf_counter()
    candidates_by_query = retrieve_top_n(dataset, top_n)

    selections: list[Selection] = []
    metric_rows = []
    for query in dataset.queries:
        candidates = candidates_by_query[query.query_id]
        features = build_features(query.query, candidates)
        index_by_doc_id = {doc_id: index for index, doc_id in enumerate(features.doc_ids)}

        method_results = {
            "top_ranked": top_ranked(features, budget),
            "relevance_ratio": relevance_ratio(features, budget),
            "random_seeded": seeded_random(features, budget, seed=seed),
            "mmr": mmr(features, budget),
            "submodular_coverage": budgeted_greedy(features, coverage_objective(features), budget),
            "submodular_diversity": budgeted_greedy(features, diversity_objective(features), budget),
            "submodular_combined": budgeted_greedy(features, combined_objective(features), budget),
        }

        for method, result in method_results.items():
            selected_doc_ids = tuple(features.doc_ids[index] for index in result.indices)
            selection = Selection(
                query_id=query.query_id,
                method=method,
                selected_doc_ids=selected_doc_ids,
                total_cost=result.total_cost,
                objective_value=result.objective_value,
            )
            # Validate selected ids before evaluating to catch stale mappings early.
            for doc_id in selected_doc_ids:
                if doc_id not in index_by_doc_id:
                    raise AssertionError(f"selected document missing from features: {doc_id}")
            selections.append(selection)
            metric = evaluate_selection(query, features, selection, budget)
            metric_rows.append(metric)

    elapsed = time.perf_counter() - started
    aggregate = aggregate_metrics(metric_rows)
    output_dir.mkdir(parents=True, exist_ok=True)
    write_jsonl(output_dir / "candidates.jsonl", candidates_to_rows(candidates_by_query))
    write_jsonl(output_dir / "selections.jsonl", selections_to_rows(selections))
    write_jsonl(output_dir / "per_query_metrics.jsonl", [_metric_to_dict(item) for item in metric_rows])
    metrics = {
        "config": {
            "data_dir": str(data_dir),
            "budget": budget,
            "top_n": top_n,
            "seed": seed,
        },
        "runtime_seconds": elapsed,
        "aggregate": aggregate,
    }
    (output_dir / "metrics.json").write_text(json.dumps(metrics, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    (output_dir / "summary.md").write_text(_summary_markdown(metrics), encoding="utf-8")
    return metrics


def _metric_to_dict(metric) -> dict:
    return {
        "query_id": metric.query_id,
        "method": metric.method,
        "evidence_recall": metric.evidence_recall,
        "evidence_precision": metric.evidence_precision,
        "evidence_f1": metric.evidence_f1,
        "redundancy": metric.redundancy,
        "budget_utilization": metric.budget_utilization,
        "selected_count": metric.selected_count,
    }


def _summary_markdown(metrics: dict) -> str:
    lines = [
        "# Smoke Experiment Summary",
        "",
        f"Runtime seconds: `{metrics['runtime_seconds']:.6f}`",
        "",
        "| Method | Recall | Precision | F1 | Redundancy | Budget Utilization |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for method, values in metrics["aggregate"].items():
        lines.append(
            "| {method} | {recall:.3f} | {precision:.3f} | {f1:.3f} | {redundancy:.3f} | {budget:.3f} |".format(
                method=method,
                recall=values["evidence_recall_mean"],
                precision=values["evidence_precision_mean"],
                f1=values["evidence_f1_mean"],
                redundancy=values["redundancy_mean"],
                budget=values["budget_utilization_mean"],
            )
        )
    return "\n".join(lines) + "\n"
