from __future__ import annotations

import csv
from dataclasses import dataclass
import hashlib
import json
import math
from pathlib import Path
import random
from statistics import mean, pstdev
import time

from .data import (
    Candidate,
    DataValidationError,
    Dataset,
    Selection,
    candidates_to_rows,
    load_dataset,
    read_jsonl,
    token_cost,
    write_jsonl,
)
from .features import FeatureSet, build_features
from .metrics import evaluate_selection
from .objectives import Objective, combined_objective, coverage_objective, diversity_objective
from .retrieval import retrieve_top_n
from .selectors import budgeted_greedy, exhaustive_optimal, mmr, relevance_ratio, seeded_random, top_ranked


DEFAULT_BUDGET = 18
DEFAULT_TOP_N = 5
DEFAULT_SELECTORS = ("top_ranked", "relevance_ratio", "random_seeded", "mmr", "budgeted_greedy")
DEFAULT_OBJECTIVES = ("coverage", "diversity", "combined")
BASELINE_OBJECTIVE = "none"
BASELINE_LAMBDA = 0.0
AGGREGATE_GROUP_KEYS = ("method_label", "selector", "objective", "lambda_value", "budget", "top_n")
METRIC_COLUMNS = (
    "evidence_recall",
    "evidence_precision",
    "evidence_f1",
    "redundancy",
    "budget_utilization",
    "selected_count",
    "runtime_units",
)
AGGREGATE_COLUMNS = (
    *AGGREGATE_GROUP_KEYS,
    "queries",
    "evidence_recall_mean",
    "evidence_recall_std",
    "evidence_precision_mean",
    "evidence_precision_std",
    "evidence_f1_mean",
    "evidence_f1_std",
    "redundancy_mean",
    "redundancy_std",
    "budget_utilization_mean",
    "budget_utilization_std",
    "selected_count_mean",
    "selected_count_std",
    "runtime_units_mean",
    "runtime_units_std",
)


@dataclass(frozen=True)
class ExperimentConfig:
    data_dir: str
    output_dir: str
    dataset_name: str = "dataset"
    split: str = "test"
    budgets: tuple[int, ...] = (80, 160, 320)
    candidate_sizes: tuple[int, ...] = (10, 20, 40)
    selectors: tuple[str, ...] = DEFAULT_SELECTORS
    objectives: tuple[str, ...] = DEFAULT_OBJECTIVES
    combined_lambdas: tuple[float, ...] = (1.0,)
    mmr_lambda: float = 0.7
    seed: int = 13
    sample_size: int | None = None
    sample_seed: int = 13
    optimal_max_items: int = 16
    overwrite: bool = False


def parse_grid(value: str, *, item_type, label: str, allow_zero: bool = False) -> tuple:
    if not value or not value.strip():
        raise DataValidationError(f"{label} grid must not be empty")
    items = []
    for raw in value.split(","):
        stripped = raw.strip()
        if not stripped:
            raise DataValidationError(f"{label} grid contains an empty value")
        try:
            item = item_type(stripped)
        except ValueError as exc:
            raise DataValidationError(f"{label} grid contains invalid value: {stripped}") from exc
        if isinstance(item, float) and not math.isfinite(item):
            raise DataValidationError(f"{label} grid values must be finite")
        if item < 0 or (item == 0 and not allow_zero):
            qualifier = "nonnegative" if allow_zero else "positive"
            raise DataValidationError(f"{label} grid values must be {qualifier}")
        items.append(item)
    if len(items) != len(set(items)):
        raise DataValidationError(f"{label} grid contains duplicate values")
    return tuple(items)


def parse_name_grid(value: str, *, allowed: tuple[str, ...], label: str) -> tuple[str, ...]:
    names = tuple(item.strip() for item in value.split(","))
    if not any(names):
        raise DataValidationError(f"{label} must not be empty")
    if any(not item for item in names):
        raise DataValidationError(f"{label} grid contains an empty value")
    unknown = sorted(set(names) - set(allowed))
    if unknown:
        raise DataValidationError(f"unknown {label}: {', '.join(unknown)}")
    if len(names) != len(set(names)):
        raise DataValidationError(f"{label} contains duplicate values")
    return names


def run_experiment(config: ExperimentConfig) -> dict:
    dataset = _sample_dataset(load_dataset(Path(config.data_dir)), config.sample_size, config.sample_seed)
    candidates_by_top_n = {top_n: retrieve_top_n(dataset, top_n) for top_n in config.candidate_sizes}
    return _run_with_candidates(dataset, candidates_by_top_n, config, input_paths=(Path(config.data_dir),))


def generate_candidates(data_dir: Path, output_path: Path, top_n: int) -> list[dict]:
    if output_path.is_symlink():
        raise DataValidationError(f"output path is a symlink: {output_path}")
    if output_path.exists() and output_path.is_dir():
        raise DataValidationError(f"output path is not a file: {output_path}")
    _validate_output_file_outside_input_dir(output_path, data_dir)
    dataset = load_dataset(data_dir)
    rows = [{**row, "top_n": top_n} for row in candidates_to_rows(retrieve_top_n(dataset, top_n))]
    write_jsonl(output_path, rows)
    return rows


def select_evaluate(
    data_dir: Path,
    candidates_path: Path,
    output_dir: Path,
    budget: int,
    seed: int,
    overwrite: bool = False,
    selectors: tuple[str, ...] = DEFAULT_SELECTORS,
    objectives: tuple[str, ...] = ("combined",),
    combined_lambdas: tuple[float, ...] = (1.0,),
    mmr_lambda: float = 0.7,
    optimal_max_items: int | None = None,
) -> dict:
    dataset = load_dataset(data_dir)
    candidates_by_top_n = load_candidate_file(candidates_path, dataset)
    candidate_sizes = tuple(sorted(candidates_by_top_n))
    return _run_with_candidates(
        dataset=dataset,
        candidates_by_top_n=candidates_by_top_n,
        config=ExperimentConfig(
            data_dir=str(data_dir),
            output_dir=str(output_dir),
            budgets=(budget,),
            candidate_sizes=candidate_sizes,
            selectors=selectors,
            objectives=objectives,
            combined_lambdas=combined_lambdas,
            mmr_lambda=mmr_lambda,
            seed=seed,
            optimal_max_items=optimal_max_items if optimal_max_items is not None else ExperimentConfig.optimal_max_items,
            overwrite=overwrite,
        ),
        input_paths=(data_dir, candidates_path),
    )


def run_smoke(data_dir: Path, output_dir: Path, budget: int = DEFAULT_BUDGET, top_n: int = DEFAULT_TOP_N, seed: int = 13) -> dict:
    started_at = time.perf_counter()
    summary = run_experiment(
        ExperimentConfig(
            data_dir=str(data_dir),
            output_dir=str(output_dir),
            dataset_name="fixture",
            split="smoke",
            budgets=(budget,),
            candidate_sizes=(top_n,),
            selectors=DEFAULT_SELECTORS,
            objectives=DEFAULT_OBJECTIVES,
            combined_lambdas=(1.0,),
            seed=seed,
            optimal_max_items=top_n,
            overwrite=False,
        )
    )
    runtime_seconds = time.perf_counter() - started_at
    aggregate_rows = _read_aggregate_csv(output_dir / "aggregate_metrics.csv")
    aggregate = {}
    for row in aggregate_rows:
        aggregate[row["method_label"]] = {
            key: _maybe_float(value)
            for key, value in row.items()
            if key.endswith("_mean") or key.endswith("_std") or key == "queries"
        }
    metrics = {
        "config": {"data_dir": str(data_dir), "budget": budget, "top_n": top_n, "seed": seed},
        "runtime_seconds": runtime_seconds,
        "aggregate": aggregate,
    }
    (output_dir / "metrics.json").write_text(json.dumps(metrics, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    (output_dir / "summary.md").write_text(_summary_markdown(metrics), encoding="utf-8")
    return metrics


def load_candidate_file(path: Path, dataset: Dataset) -> dict[int, dict[str, list[Candidate]]]:
    rows = read_jsonl(path)
    required = {"query_id", "doc_id", "rank", "score", "text", "token_cost", "top_n"}
    query_ids = {query.query_id for query in dataset.queries}
    doc_by_id = {doc.doc_id: doc for doc in dataset.corpus}
    doc_ids = set(doc_by_id)
    grouped: dict[int, dict[str, list[Candidate]]] = {}

    for row_number, row in enumerate(rows, 1):
        missing = required - set(row)
        if missing:
            raise DataValidationError(f"missing required candidate columns at row {row_number}: {sorted(missing)}")
        query_id = _candidate_text(row, "query_id", row_number)
        doc_id = _candidate_text(row, "doc_id", row_number)
        if query_id not in query_ids:
            raise DataValidationError(f"candidate row references unknown query_id: {query_id}")
        if doc_id not in doc_ids:
            raise DataValidationError(f"candidate row references unknown doc_id: {doc_id}")
        rank = _candidate_positive_int(row, "rank", row_number)
        top_n = _candidate_positive_int(row, "top_n", row_number)
        token_cost = _candidate_positive_int(row, "token_cost", row_number)
        if rank > top_n:
            raise DataValidationError(f"candidate rank exceeds top_n at row {row_number}")
        try:
            score = float(row["score"])
        except (TypeError, ValueError) as exc:
            raise DataValidationError(f"candidate score must be numeric at row {row_number}") from exc
        text = _candidate_text(row, "text", row_number)
        canonical_doc = doc_by_id[doc_id]
        if text != canonical_doc.text:
            raise DataValidationError(f"candidate text does not match canonical corpus for doc_id={doc_id} at row {row_number}")
        if token_cost != _canonical_token_cost(canonical_doc.text):
            raise DataValidationError(f"candidate token_cost does not match canonical corpus for doc_id={doc_id} at row {row_number}")
        candidate = Candidate(query_id=query_id, doc_id=doc_id, rank=rank, score=score, text=text, token_cost=token_cost)
        grouped.setdefault(top_n, {}).setdefault(query_id, []).append(candidate)

    for top_n, by_query in grouped.items():
        missing_queries = query_ids - set(by_query)
        if missing_queries:
            raise DataValidationError(f"candidate file missing queries for top_n={top_n}: {sorted(missing_queries)}")
        for query_id, candidates in by_query.items():
            candidates.sort(key=lambda item: (item.rank, item.doc_id))
            ranks = [candidate.rank for candidate in candidates]
            if ranks != list(range(1, len(candidates) + 1)):
                raise DataValidationError(f"candidate ranks must be contiguous for query {query_id}, top_n={top_n}")
            expected_count = min(top_n, len(doc_ids))
            if len(candidates) < expected_count:
                raise DataValidationError(f"candidate file has fewer than top_n rows for query {query_id}, top_n={top_n}")
            if len(candidates) > top_n:
                raise DataValidationError(f"candidate file has more than top_n rows for query {query_id}, top_n={top_n}")
            seen_docs = [candidate.doc_id for candidate in candidates]
            if len(seen_docs) != len(set(seen_docs)):
                raise DataValidationError(f"candidate file contains duplicate doc ids for query {query_id}, top_n={top_n}")

    return {top_n: {query_id: list(candidates) for query_id, candidates in sorted(by_query.items())} for top_n, by_query in sorted(grouped.items())}


def aggregate_metric_rows(metric_rows: list[dict]) -> list[dict]:
    if not metric_rows:
        raise DataValidationError("no metric rows to aggregate")
    for row in metric_rows:
        missing = (set(AGGREGATE_GROUP_KEYS) | set(METRIC_COLUMNS)) - set(row)
        if missing:
            raise DataValidationError(f"metric row missing required fields: {sorted(missing)}")
    grouped: dict[tuple, list[dict]] = {}
    for row in metric_rows:
        key = tuple(row[field] for field in AGGREGATE_GROUP_KEYS)
        grouped.setdefault(key, []).append(row)
    rows: list[dict] = []
    for key in sorted(grouped):
        items = grouped[key]
        aggregate = {field: value for field, value in zip(AGGREGATE_GROUP_KEYS, key, strict=True)}
        aggregate["queries"] = len(items)
        for column in METRIC_COLUMNS:
            values = [float(item[column]) for item in items]
            aggregate[f"{column}_mean"] = mean(values)
            aggregate[f"{column}_std"] = pstdev(values) if len(values) > 1 else 0.0
        rows.append(aggregate)
    return rows


def _sample_dataset(dataset: Dataset, sample_size: int | None, sample_seed: int) -> Dataset:
    if sample_size is None or sample_size >= len(dataset.queries):
        return dataset
    if sample_size <= 0:
        raise DataValidationError("sample_size must be positive")
    queries = sorted(dataset.queries, key=lambda item: item.query_id)
    sampled = sorted(random.Random(sample_seed).sample(queries, sample_size), key=lambda item: item.query_id)
    return Dataset(queries=tuple(sampled), corpus=dataset.corpus)


def _candidate_text(row: dict, field: str, row_number: int) -> str:
    value = row.get(field)
    if not isinstance(value, str) or not value.strip():
        raise DataValidationError(f"candidate {field} must be a nonempty string at row {row_number}")
    return value.strip()


def _candidate_positive_int(row: dict, field: str, row_number: int) -> int:
    value = row.get(field)
    if isinstance(value, bool) or not isinstance(value, int):
        raise DataValidationError(f"candidate {field} must be a positive integer at row {row_number}")
    if value <= 0:
        raise DataValidationError(f"candidate {field} must be a positive integer at row {row_number}")
    return value


def _canonical_token_cost(text: str) -> int:
    return token_cost(text)


def _run_with_candidates(
    dataset: Dataset,
    candidates_by_top_n: dict[int, dict[str, list[Candidate]]],
    config: ExperimentConfig,
    input_paths: tuple[Path, ...] = (),
) -> dict:
    _validate_config(config)
    output_dir = Path(config.output_dir)
    _prepare_output_dir(output_dir, overwrite=config.overwrite, input_paths=input_paths)

    query_by_id = {query.query_id: query for query in dataset.queries}
    feature_reference_texts = [doc.text for doc in dataset.corpus]
    features_by_key: dict[tuple[int, str], FeatureSet] = {}
    for top_n, candidates_by_query in candidates_by_top_n.items():
        for query in dataset.queries:
            if query.query_id not in candidates_by_query:
                raise DataValidationError(f"missing candidates for query {query.query_id}, top_n={top_n}")
            features_by_key[(top_n, query.query_id)] = build_features(
                query.query,
                candidates_by_query[query.query_id],
                reference_texts=feature_reference_texts,
            )

    candidate_rows = _candidate_rows(candidates_by_top_n)
    selection_rows: list[dict] = []
    metric_rows: list[dict] = []
    optimal_rows: list[dict] = []

    for top_n in sorted(config.candidate_sizes):
        if top_n not in candidates_by_top_n:
            raise DataValidationError(f"missing candidate set for top_n={top_n}")
        for budget in sorted(config.budgets):
            for query in sorted(dataset.queries, key=lambda item: item.query_id):
                features = features_by_key[(top_n, query.query_id)]
                for selector, objective_name, lambda_value, method_label in _method_specs(config):
                    result, runtime_units = _run_selector(selector, objective_name, lambda_value, features, budget, config)
                    selected_doc_ids = tuple(features.doc_ids[index] for index in result.indices)
                    selection = Selection(
                        query_id=query.query_id,
                        method=method_label,
                        selected_doc_ids=selected_doc_ids,
                        total_cost=result.total_cost,
                        objective_value=result.objective_value,
                    )
                    selection_rows.append(
                        {
                            "budget": budget,
                            "lambda_value": lambda_value,
                            "method_label": method_label,
                            "objective": objective_name,
                            "objective_value": result.objective_value,
                            "query_id": query.query_id,
                            "runtime_units": runtime_units,
                            "seed": config.seed,
                            "selected_doc_ids": list(selected_doc_ids),
                            "selector": selector,
                            "status": "selected" if selected_doc_ids else "empty",
                            "top_n": top_n,
                            "total_cost": result.total_cost,
                        }
                    )
                    metrics = evaluate_selection(query_by_id[query.query_id], features, selection, budget, runtime_units=runtime_units)
                    metric_rows.append(
                        {
                            "budget": budget,
                            "budget_utilization": metrics.budget_utilization,
                            "evidence_f1": metrics.evidence_f1,
                            "evidence_precision": metrics.evidence_precision,
                            "evidence_recall": metrics.evidence_recall,
                            "lambda_value": lambda_value,
                            "method_label": method_label,
                            "objective": objective_name,
                            "query_id": query.query_id,
                            "redundancy": metrics.redundancy,
                            "runtime_units": metrics.runtime_units,
                            "selected_count": metrics.selected_count,
                            "selector": selector,
                            "top_n": top_n,
                        }
                    )
                    optimal_rows.append(_optimal_check_row(features, selector, objective_name, lambda_value, result, budget, top_n, query.query_id, config))

    selection_rows = _sort_long_rows(selection_rows)
    metric_rows = _sort_long_rows(metric_rows)
    optimal_rows = _sort_optimal_rows(optimal_rows)
    aggregate_rows = aggregate_metric_rows(metric_rows)

    _write_config(output_dir / "config.json", config, dataset)
    write_jsonl(output_dir / "sample_manifest.jsonl", [{"query_id": query.query_id} for query in sorted(dataset.queries, key=lambda item: item.query_id)])
    write_jsonl(output_dir / "candidates.jsonl", candidate_rows)
    write_jsonl(output_dir / "selections.jsonl", selection_rows)
    write_jsonl(output_dir / "per_query_metrics.jsonl", metric_rows)
    _write_csv(output_dir / "aggregate_metrics.csv", aggregate_rows, AGGREGATE_COLUMNS)
    (output_dir / "aggregate_metrics.md").write_text(_aggregate_markdown(aggregate_rows), encoding="utf-8")
    _write_csv(output_dir / "optimal_checks.csv", optimal_rows, _optimal_columns())
    (output_dir / "summary.md").write_text(_run_summary_markdown(config, dataset, aggregate_rows, optimal_rows), encoding="utf-8")
    (output_dir / "run.log").write_text(_run_log(config, dataset, aggregate_rows), encoding="utf-8")

    return {
        "queries": len(dataset.queries),
        "candidate_rows": len(candidate_rows),
        "selection_rows": len(selection_rows),
        "metric_rows": len(metric_rows),
        "aggregate_rows": len(aggregate_rows),
        "optimal_rows": len(optimal_rows),
        "output_dir": str(output_dir),
    }


def _validate_config(config: ExperimentConfig) -> None:
    if not config.budgets or any(item <= 0 for item in config.budgets) or len(config.budgets) != len(set(config.budgets)):
        raise DataValidationError("budgets must be positive and unique")
    if not config.candidate_sizes or any(item <= 0 for item in config.candidate_sizes) or len(config.candidate_sizes) != len(set(config.candidate_sizes)):
        raise DataValidationError("candidate_sizes must be positive and unique")
    unknown_selectors = sorted(set(config.selectors) - set(DEFAULT_SELECTORS))
    if unknown_selectors:
        raise DataValidationError(f"unknown selectors: {', '.join(unknown_selectors)}")
    unknown_objectives = sorted(set(config.objectives) - set(DEFAULT_OBJECTIVES))
    if unknown_objectives:
        raise DataValidationError(f"unknown objectives: {', '.join(unknown_objectives)}")
    if not config.selectors:
        raise DataValidationError("selectors must not be empty")
    if not config.objectives:
        raise DataValidationError("objectives must not be empty")
    if not config.combined_lambdas or any(value < 0 for value in config.combined_lambdas) or len(config.combined_lambdas) != len(set(config.combined_lambdas)):
        raise DataValidationError("combined_lambdas must be nonnegative and unique")
    if not 0.0 <= config.mmr_lambda <= 1.0:
        raise DataValidationError("mmr_lambda must be in [0, 1]")
    if config.optimal_max_items <= 0:
        raise DataValidationError("optimal_max_items must be positive")


def _clear_output_dir(output_dir: Path) -> None:
    for path in output_dir.iterdir():
        if path.is_symlink():
            path.unlink()
        elif path.is_dir():
            _clear_output_dir(path)
            path.rmdir()
        else:
            path.unlink()


def _validate_output_file_outside_input_dir(output_path: Path, input_dir: Path) -> None:
    try:
        resolved_output = output_path.resolve(strict=False)
        resolved_input = input_dir.resolve()
    except OSError as exc:
        raise DataValidationError(f"cannot resolve output/input path: {output_path}") from exc
    if resolved_output == resolved_input or resolved_input in resolved_output.parents:
        raise DataValidationError(f"output path must not overwrite dataset inputs: {output_path}")


def _prepare_output_dir(output_dir: Path, *, overwrite: bool, input_paths: tuple[Path, ...] = ()) -> None:
    if output_dir.is_symlink() and not overwrite:
        raise DataValidationError(f"output path is a symlink: {output_dir}")
    if output_dir.exists() and not output_dir.is_dir():
        raise DataValidationError(f"output path is not a directory: {output_dir}")
    _validate_output_does_not_contain_inputs(output_dir, input_paths)
    if output_dir.exists() and any(output_dir.iterdir()) and not overwrite:
        raise DataValidationError(f"output directory exists; pass --overwrite to replace it: {output_dir}")
    if output_dir.exists() and overwrite:
        if output_dir.is_symlink():
            output_dir.unlink()
        else:
            _clear_output_dir(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)


def _validate_output_does_not_contain_inputs(output_dir: Path, input_paths: tuple[Path, ...]) -> None:
    try:
        resolved_output = output_dir.resolve(strict=False)
    except OSError as exc:
        raise DataValidationError(f"cannot resolve output directory: {output_dir}") from exc
    for input_path in input_paths:
        try:
            resolved_input = input_path.resolve(strict=False)
        except OSError as exc:
            raise DataValidationError(f"cannot resolve experiment input path: {input_path}") from exc
        protected_root = resolved_input if input_path.is_dir() else resolved_input
        if (
            resolved_output == resolved_input
            or protected_root in resolved_output.parents
            or resolved_output in resolved_input.parents
        ):
            raise DataValidationError(f"output directory must not contain experiment inputs: {output_dir}")


def _candidate_rows(candidates_by_top_n: dict[int, dict[str, list[Candidate]]]) -> list[dict]:
    rows: list[dict] = []
    for top_n in sorted(candidates_by_top_n):
        for query_id in sorted(candidates_by_top_n[top_n]):
            for candidate in candidates_by_top_n[top_n][query_id]:
                rows.append(
                    {
                        "doc_id": candidate.doc_id,
                        "query_id": candidate.query_id,
                        "rank": candidate.rank,
                        "score": candidate.score,
                        "text": candidate.text,
                        "token_cost": candidate.token_cost,
                        "top_n": top_n,
                    }
                )
    return rows


def _method_specs(config: ExperimentConfig):
    for selector in config.selectors:
        if selector == "budgeted_greedy":
            for objective in config.objectives:
                lambda_values = config.combined_lambdas if objective == "combined" else (BASELINE_LAMBDA,)
                for lambda_value in lambda_values:
                    yield selector, objective, lambda_value, _submodular_label(objective, lambda_value, len(lambda_values))
        else:
            yield selector, BASELINE_OBJECTIVE, BASELINE_LAMBDA, selector


def _submodular_label(objective: str, lambda_value: float, lambda_count: int) -> str:
    if objective == "combined" and lambda_count > 1:
        return f"submodular_combined_lambda_{lambda_value:g}"
    return f"submodular_{objective}"


def _run_selector(
    selector: str,
    objective_name: str,
    lambda_value: float,
    features: FeatureSet,
    budget: int,
    config: ExperimentConfig,
):
    if selector == "top_ranked":
        result = top_ranked(features, budget)
    elif selector == "relevance_ratio":
        result = relevance_ratio(features, budget)
    elif selector == "random_seeded":
        result = seeded_random(features, budget, seed=_query_seed(config.seed, features.query_id))
    elif selector == "mmr":
        result = mmr(features, budget, lambda_value=config.mmr_lambda)
    elif selector == "budgeted_greedy":
        result = budgeted_greedy(features, _objective_for(features, objective_name, lambda_value), budget)
    else:
        raise DataValidationError(f"unknown selector: {selector}")
    runtime_units = _runtime_units(selector, features, result)
    return result, runtime_units


def _query_seed(seed: int, query_id: str) -> int:
    digest = hashlib.sha1(f"{seed}:{query_id}".encode("utf-8")).hexdigest()
    return int(digest[:12], 16)


def _runtime_units(selector: str, features: FeatureSet, result) -> int:
    n = len(features.doc_ids)
    selected = max(1, len(result.indices))
    if selector == "top_ranked":
        return n
    if selector in {"relevance_ratio", "random_seeded"}:
        return n + n * max(1, n.bit_length())
    if selector == "mmr":
        return n * selected + selected * selected
    if selector == "budgeted_greedy":
        return n * n * selected
    return n * selected


def _objective_for(features: FeatureSet, objective_name: str, lambda_value: float) -> Objective:
    if objective_name == "coverage":
        return coverage_objective(features)
    if objective_name == "diversity":
        return diversity_objective(features)
    if objective_name == "combined":
        return combined_objective(features, lambda_value=lambda_value)
    raise DataValidationError(f"unknown objective: {objective_name}")


def _optimal_check_row(
    features: FeatureSet,
    selector: str,
    objective_name: str,
    lambda_value: float,
    greedy_result,
    budget: int,
    top_n: int,
    query_id: str,
    config: ExperimentConfig,
) -> dict:
    base = {
        "approx_ratio": "",
        "budget": budget,
        "greedy_cost": greedy_result.total_cost,
        "greedy_value": greedy_result.objective_value if greedy_result.objective_value is not None else "",
        "lambda_value": lambda_value,
        "objective": objective_name,
        "optimal_cost": "",
        "optimal_value": "",
        "query_id": query_id,
        "reason": "",
        "selector": selector,
        "status": "skipped",
        "top_n": top_n,
    }
    if selector != "budgeted_greedy":
        base["reason"] = "nondeterministic_or_baseline_selector"
        return base
    if len(features.doc_ids) > config.optimal_max_items:
        base["reason"] = "too_many_items"
        return base
    objective = _objective_for(features, objective_name, lambda_value)
    optimal = exhaustive_optimal(features, objective, budget, max_items=config.optimal_max_items)
    ratio = "" if optimal.objective_value == 0 else (greedy_result.objective_value or 0.0) / optimal.objective_value
    base.update(
        {
            "approx_ratio": ratio,
            "optimal_cost": optimal.total_cost,
            "optimal_value": optimal.objective_value,
            "reason": "",
            "status": "executed",
        }
    )
    return base


def _sort_long_rows(rows: list[dict]) -> list[dict]:
    return sorted(
        rows,
        key=lambda row: (
            row["top_n"],
            row["budget"],
            row["method_label"],
            row["objective"],
            row["lambda_value"],
            row["query_id"],
        ),
    )


def _sort_optimal_rows(rows: list[dict]) -> list[dict]:
    return sorted(rows, key=lambda row: (row["top_n"], row["budget"], row["selector"], row["objective"], row["lambda_value"], row["query_id"]))


def _write_config(path: Path, config: ExperimentConfig, dataset: Dataset) -> None:
    payload = {
        "budgets": list(config.budgets),
        "candidate_sizes": list(config.candidate_sizes),
        "combined_lambdas": list(config.combined_lambdas),
        "data_dir": config.data_dir,
        "dataset_name": config.dataset_name,
        "mmr_lambda": config.mmr_lambda,
        "objectives": list(config.objectives),
        "optimal_max_items": config.optimal_max_items,
        "query_ids": [query.query_id for query in sorted(dataset.queries, key=lambda item: item.query_id)],
        "sample_seed": config.sample_seed,
        "sample_size": config.sample_size,
        "seed": config.seed,
        "selectors": list(config.selectors),
        "split": config.split,
    }
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _write_csv(path: Path, rows: list[dict], columns: tuple[str, ...]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(columns), extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def _read_aggregate_csv(path: Path) -> list[dict]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def _aggregate_markdown(rows: list[dict]) -> str:
    lines = [
        "# Aggregate Metrics",
        "",
        "| Method | Budget | Top N | Recall | F1 | Redundancy | Budget Use | Runtime Units |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in rows:
        lines.append(
            "| {method} | {budget} | {top_n} | {recall:.3f} | {f1:.3f} | {redundancy:.3f} | {budget_use:.3f} | {runtime:.1f} |".format(
                method=row["method_label"],
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


def _run_summary_markdown(config: ExperimentConfig, dataset: Dataset, aggregate_rows: list[dict], optimal_rows: list[dict]) -> str:
    executed = sum(1 for row in optimal_rows if row["status"] == "executed")
    skipped = len(optimal_rows) - executed
    best = max(aggregate_rows, key=lambda row: (float(row["evidence_f1_mean"]), float(row["evidence_recall_mean"])))
    return "\n".join(
        [
            "# Experiment Summary",
            "",
            f"Dataset: `{config.dataset_name}` / `{config.split}`",
            f"Queries: `{len(dataset.queries)}`",
            f"Budgets: `{','.join(str(item) for item in config.budgets)}`",
            f"Candidate sizes: `{','.join(str(item) for item in config.candidate_sizes)}`",
            f"Best F1 method: `{best['method_label']}` at budget `{best['budget']}`, top_n `{best['top_n']}`.",
            f"Optimal checks: `{executed}` executed, `{skipped}` skipped.",
            "",
        ]
    )


def _run_log(config: ExperimentConfig, dataset: Dataset, aggregate_rows: list[dict]) -> str:
    return "\n".join(
        [
            "context-selection experiment",
            f"dataset={config.dataset_name}",
            f"split={config.split}",
            f"queries={len(dataset.queries)}",
            f"budgets={','.join(str(item) for item in config.budgets)}",
            f"candidate_sizes={','.join(str(item) for item in config.candidate_sizes)}",
            f"selectors={','.join(config.selectors)}",
            f"objectives={','.join(config.objectives)}",
            f"seed={config.seed}",
            f"aggregate_rows={len(aggregate_rows)}",
            "",
        ]
    )


def _optimal_columns() -> tuple[str, ...]:
    return (
        "query_id",
        "selector",
        "objective",
        "lambda_value",
        "budget",
        "top_n",
        "status",
        "reason",
        "greedy_value",
        "optimal_value",
        "greedy_cost",
        "optimal_cost",
        "approx_ratio",
    )


def _maybe_float(value: str):
    try:
        return float(value)
    except (TypeError, ValueError):
        return value


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
                recall=float(values["evidence_recall_mean"]),
                precision=float(values["evidence_precision_mean"]),
                f1=float(values["evidence_f1_mean"]),
                redundancy=float(values["redundancy_mean"]),
                budget=float(values["budget_utilization_mean"]),
            )
        )
    return "\n".join(lines) + "\n"
