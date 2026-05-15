from __future__ import annotations

import csv
from pathlib import Path


class ArtifactValidationError(ValueError):
    """Raised when experiment outputs cannot be converted to report artifacts."""


REQUIRED_AGGREGATE_COLUMNS = {
    "method_label",
    "selector",
    "objective",
    "lambda_value",
    "budget",
    "top_n",
    "queries",
    "evidence_recall_mean",
    "evidence_recall_std",
    "evidence_f1_mean",
    "evidence_f1_std",
    "redundancy_mean",
    "budget_utilization_mean",
    "runtime_units_mean",
}
REQUIRED_METHODS = {"top_ranked", "relevance_ratio", "random_seeded", "mmr", "submodular_combined"}
REQUIRED_SUBMODULAR_OBJECTIVES = {"coverage", "diversity", "combined"}


def generate_artifacts(run_dir: Path, output_dir: Path) -> list[Path]:
    aggregate_rows = _read_csv(run_dir / "aggregate_metrics.csv")
    optimal_rows = _read_csv(run_dir / "optimal_checks.csv")
    _validate_aggregate_rows(aggregate_rows)
    _validate_required_methods(aggregate_rows)
    _validate_submodular_objectives(aggregate_rows)

    output_dir.mkdir(parents=True, exist_ok=True)
    outputs = [
        output_dir / "comparison_table.md",
        output_dir / "metric_by_budget.md",
        output_dir / "runtime_by_candidate_size.md",
        output_dir / "optimal_checks.md",
    ]
    outputs[0].write_text(_comparison_table(aggregate_rows), encoding="utf-8")
    outputs[1].write_text(_metric_by_budget(aggregate_rows), encoding="utf-8")
    outputs[2].write_text(_runtime_by_candidate_size(aggregate_rows), encoding="utf-8")
    outputs[3].write_text(_optimal_summary(optimal_rows), encoding="utf-8")
    return outputs


def _read_csv(path: Path) -> list[dict]:
    if not path.exists():
        raise ArtifactValidationError(f"missing required artifact input: {path}")
    with path.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    if not rows:
        raise ArtifactValidationError(f"empty artifact input: {path}")
    return rows


def _validate_aggregate_rows(rows: list[dict]) -> None:
    missing = REQUIRED_AGGREGATE_COLUMNS - set(rows[0])
    if missing:
        raise ArtifactValidationError(f"missing required columns: {sorted(missing)}")
    for row in rows:
        if set(rows[0]) != set(row):
            raise ArtifactValidationError("aggregate metric rows have incompatible schemas")
        for numeric in [
            "budget",
            "top_n",
            "queries",
            "evidence_recall_mean",
            "evidence_f1_mean",
            "redundancy_mean",
            "budget_utilization_mean",
            "runtime_units_mean",
        ]:
            try:
                float(row[numeric])
            except ValueError as exc:
                raise ArtifactValidationError(f"non-numeric aggregate column: {numeric}") from exc


def _validate_required_methods(rows: list[dict]) -> None:
    observed = {row["method_label"] for row in rows}
    missing = REQUIRED_METHODS - observed
    if missing:
        raise ArtifactValidationError(f"missing required methods: {sorted(missing)}")


def _validate_submodular_objectives(rows: list[dict]) -> None:
    observed = {row["objective"] for row in rows if row["selector"] == "budgeted_greedy"}
    missing = REQUIRED_SUBMODULAR_OBJECTIVES - observed
    if missing:
        raise ArtifactValidationError(f"missing submodular objectives: {sorted(missing)}")


def _comparison_table(rows: list[dict]) -> str:
    best_by_method: dict[str, dict] = {}
    for row in rows:
        current = best_by_method.get(row["method_label"])
        if current is None or _score(row) > _score(current):
            best_by_method[row["method_label"]] = row
    lines = [
        "# Comparison Table",
        "",
        "| Method | Budget | Top N | Recall | F1 | Redundancy | Budget Utilization | runtime_units_mean |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for method in sorted(best_by_method):
        row = best_by_method[method]
        lines.append(
            "| {method} | {budget} | {top_n} | {recall:.3f} | {f1:.3f} | {redundancy:.3f} | {budget_use:.3f} | {runtime:.1f} |".format(
                method=method,
                budget=row["budget"],
                top_n=row["top_n"],
                recall=float(row["evidence_recall_mean"]),
                f1=float(row["evidence_f1_mean"]),
                redundancy=float(row["redundancy_mean"]),
                budget_use=float(row["budget_utilization_mean"]),
                runtime=float(row["runtime_units_mean"]),
            )
        )
    return "\n".join(lines) + "\n"


def _metric_by_budget(rows: list[dict]) -> str:
    lines = [
        "# Metric By Budget",
        "",
        "| Method | Budget | Top N | Evidence Recall Mean | Evidence F1 Mean | Redundancy Mean |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for row in sorted(rows, key=lambda item: (int(float(item["budget"])), int(float(item["top_n"])), item["method_label"])):
        lines.append(
            "| {method} | {budget} | {top_n} | {recall:.3f} | {f1:.3f} | {redundancy:.3f} |".format(
                method=row["method_label"],
                budget=row["budget"],
                top_n=row["top_n"],
                recall=float(row["evidence_recall_mean"]),
                f1=float(row["evidence_f1_mean"]),
                redundancy=float(row["redundancy_mean"]),
            )
        )
    return "\n".join(lines) + "\n"


def _runtime_by_candidate_size(rows: list[dict]) -> str:
    lines = [
        "# Runtime By Candidate Size",
        "",
        "| Method | Top N | Budget | runtime_units_mean | runtime_units_std |",
        "|---|---:|---:|---:|---:|",
    ]
    for row in sorted(rows, key=lambda item: (int(float(item["top_n"])), int(float(item["budget"])), item["method_label"])):
        lines.append(
            "| {method} | {top_n} | {budget} | {runtime:.1f} | {runtime_std:.1f} |".format(
                method=row["method_label"],
                top_n=row["top_n"],
                budget=row["budget"],
                runtime=float(row["runtime_units_mean"]),
                runtime_std=float(row.get("runtime_units_std", 0.0)),
            )
        )
    return "\n".join(lines) + "\n"


def _optimal_summary(rows: list[dict]) -> str:
    required = {"query_id", "selector", "objective", "budget", "top_n", "status", "greedy_value", "optimal_value", "approx_ratio"}
    missing = required - set(rows[0])
    if missing:
        raise ArtifactValidationError(f"missing required columns: {sorted(missing)}")
    lines = [
        "# Optimal Checks",
        "",
        "| Query | Objective | Budget | Top N | Status | Greedy | Optimal | Approx Ratio |",
        "|---|---|---:|---:|---|---:|---:|---:|",
    ]
    for row in sorted(rows, key=lambda item: (item["query_id"], item["objective"], item["budget"], item["top_n"])):
        lines.append(
            "| {query} | {objective} | {budget} | {top_n} | {status} | {greedy} | {optimal} | {ratio} |".format(
                query=row["query_id"],
                objective=row["objective"],
                budget=row["budget"],
                top_n=row["top_n"],
                status=row["status"],
                greedy=_short(row.get("greedy_value", "")),
                optimal=_short(row.get("optimal_value", "")),
                ratio=_short(row.get("approx_ratio", "")),
            )
        )
    return "\n".join(lines) + "\n"


def _score(row: dict) -> tuple[float, float, float]:
    return (float(row["evidence_f1_mean"]), float(row["evidence_recall_mean"]), -float(row["redundancy_mean"]))


def _short(value: str) -> str:
    if value == "":
        return ""
    try:
        return f"{float(value):.3f}"
    except ValueError:
        return value
