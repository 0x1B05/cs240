from __future__ import annotations

from dataclasses import dataclass
from statistics import mean, pstdev

from .data import DataValidationError, Query, Selection
from .features import FeatureSet


@dataclass(frozen=True)
class QueryMetrics:
    query_id: str
    method: str
    evidence_recall: float
    evidence_precision: float
    evidence_f1: float
    redundancy: float
    budget_utilization: float
    selected_count: int


def evaluate_selection(query: Query, features: FeatureSet, selection: Selection, budget: int) -> QueryMetrics:
    if selection.query_id != query.query_id or features.query_id != query.query_id:
        raise DataValidationError("query, features, and selection query ids must match")
    selected = set(selection.selected_doc_ids)
    feature_docs = set(features.doc_ids)
    if not selected.issubset(feature_docs):
        raise DataValidationError("selection contains document ids outside the candidate set")
    if not query.evidence_ids:
        raise DataValidationError("query must include gold evidence ids")

    evidence = set(query.evidence_ids)
    hits = selected & evidence
    recall = len(hits) / len(evidence)
    precision = len(hits) / len(selected) if selected else 0.0
    f1 = (2 * precision * recall / (precision + recall)) if precision + recall else 0.0
    selected_indices = [features.doc_ids.index(doc_id) for doc_id in selection.selected_doc_ids]
    redundancy = average_pairwise_similarity(features, selected_indices)
    return QueryMetrics(
        query_id=query.query_id,
        method=selection.method,
        evidence_recall=recall,
        evidence_precision=precision,
        evidence_f1=f1,
        redundancy=redundancy,
        budget_utilization=selection.total_cost / budget,
        selected_count=len(selected),
    )


def average_pairwise_similarity(features: FeatureSet, selected_indices: list[int]) -> float:
    if len(selected_indices) < 2:
        return 0.0
    values: list[float] = []
    for pos, left in enumerate(selected_indices):
        for right in selected_indices[pos + 1 :]:
            values.append(features.similarity[left][right])
    return mean(values) if values else 0.0


def aggregate_metrics(metrics: list[QueryMetrics]) -> dict[str, dict[str, float]]:
    grouped: dict[str, list[QueryMetrics]] = {}
    for item in metrics:
        grouped.setdefault(item.method, []).append(item)
    return {method: _aggregate_group(items) for method, items in sorted(grouped.items())}


def _aggregate_group(items: list[QueryMetrics]) -> dict[str, float]:
    return {
        "queries": float(len(items)),
        "evidence_recall_mean": mean(item.evidence_recall for item in items),
        "evidence_recall_std": pstdev(item.evidence_recall for item in items) if len(items) > 1 else 0.0,
        "evidence_precision_mean": mean(item.evidence_precision for item in items),
        "evidence_f1_mean": mean(item.evidence_f1 for item in items),
        "redundancy_mean": mean(item.redundancy for item in items),
        "budget_utilization_mean": mean(item.budget_utilization for item in items),
        "selected_count_mean": mean(item.selected_count for item in items),
    }
