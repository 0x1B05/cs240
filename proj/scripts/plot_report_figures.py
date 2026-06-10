#!/usr/bin/env python3
"""Generate publication-quality figures for the CS240 project report."""

from __future__ import annotations

import csv
import os
from pathlib import Path

os.environ.setdefault("MPLCONFIGDIR", "/tmp/matplotlib-cs240")

import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch


RUN_DIR = Path("proj/out/main/multihop_q200_docbudget_s13")
OUT_DIR = Path("proj/report/figures/multihop_q200_docbudget_s13_2")
ARTIFACT_DIR = OUT_DIR
AGGREGATE_CSV = RUN_DIR / "aggregate_metrics.csv"
OPTIMAL_CSV = RUN_DIR / "optimal_checks.csv"

METHODS = (
    "top_ranked",
    "relevance_ratio",
    "mmr",
    "submodular_coverage",
    "submodular_diversity",
    "submodular_combined",
)

SHORT_LABELS = {
    "top_ranked": "Top-ranked",
    "relevance_ratio": "Relevance/token",
    "mmr": "MMR",
    "submodular_coverage": "Coverage",
    "submodular_diversity": "Diversity",
    "submodular_combined": "Combined",
}

COLORS = {
    "top_ranked": "#0072B2",
    "relevance_ratio": "#D55E00",
    "mmr": "#009E73",
    "submodular_coverage": "#CC79A7",
    "submodular_diversity": "#E69F00",
    "submodular_combined": "#56B4E9",
}

MARKERS = {
    "top_ranked": "o",
    "relevance_ratio": "s",
    "mmr": "^",
    "submodular_coverage": "D",
    "submodular_diversity": "v",
    "submodular_combined": "P",
}


def read_csv(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        raise FileNotFoundError(f"Missing required input: {path}")
    with path.open("r", encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def read_markdown_table(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        raise FileNotFoundError(f"Missing required input: {path}")
    rows: list[dict[str, str]] = []
    header: list[str] | None = None
    with path.open("r", encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line.startswith("|"):
                continue
            cells = [cell.strip() for cell in line.strip("|").split("|")]
            if not cells or all(set(cell) <= {"-", ":"} for cell in cells):
                continue
            if header is None:
                header = cells
                continue
            if len(cells) == len(header):
                rows.append(dict(zip(header, cells, strict=True)))
    return rows


def as_int(row: dict[str, str], key: str) -> int:
    return int(float(row[key]))


def as_float(row: dict[str, str], key: str) -> float:
    return float(row[key])


def configure_matplotlib() -> None:
    plt.rcParams.update(
        {
            "font.family": "serif",
            "font.serif": ["DejaVu Serif", "Times New Roman", "Times"],
            "mathtext.fontset": "dejavuserif",
            "axes.titlesize": 11,
            "axes.labelsize": 10,
            "xtick.labelsize": 9,
            "ytick.labelsize": 9,
            "legend.fontsize": 8,
            "figure.dpi": 300,
            "savefig.dpi": 300,
        }
    )


def style_axis(ax) -> None:
    ax.grid(True, linestyle="--", alpha=0.5, color="#b0b0b0")
    ax.tick_params(axis="both", which="both", direction="out", length=4, width=0.9)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)


def save_figure(fig, stem: str) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    png_path = OUT_DIR / f"{stem}.png"
    pdf_path = OUT_DIR / f"{stem}.pdf"
    fig.savefig(png_path, bbox_inches="tight")
    fig.savefig(pdf_path, bbox_inches="tight")
    plt.close(fig)
    print(f"Wrote {png_path}")
    print(f"Wrote {pdf_path}")


def aggregate_subset(
    rows: list[dict[str, str]],
    *,
    method: str,
    top_n: int | None = None,
    budget: int | None = None,
) -> list[dict[str, str]]:
    filtered = [row for row in rows if row["method_label"] == method]
    if top_n is not None:
        filtered = [row for row in filtered if as_int(row, "top_n") == top_n]
    if budget is not None:
        filtered = [row for row in filtered if as_int(row, "budget") == budget]
    return filtered


def plot_method_overview() -> None:
    fig, ax = plt.subplots(figsize=(8.2, 2.9), dpi=300)
    ax.set_axis_off()

    boxes = [
        (0.02, 0.58, 0.18, 0.28, "Retrieved\ncandidates", "$C={d_1,\\ldots,d_n}$"),
        (0.28, 0.58, 0.18, 0.28, "Features", "$r_i,\\ c_i,\\ w_{ij}$"),
        (0.54, 0.58, 0.20, 0.28, "Budgeted greedy", "$\\max F(S)$\n$s.t.\\ \\sum c_i\\leq B$"),
        (0.80, 0.58, 0.18, 0.28, "Selected context", "$S\\subseteq C$"),
        (0.54, 0.10, 0.20, 0.24, "Gold evidence", "MultiHop-RAG\nlabels"),
        (0.80, 0.10, 0.18, 0.24, "Evaluation", "Recall, precision,\n$F_1$, redundancy"),
    ]

    for x, y, width, height, title, detail in boxes:
        patch = FancyBboxPatch(
            (x, y),
            width,
            height,
            boxstyle="round,pad=0.012,rounding_size=0.015",
            linewidth=1.0,
            edgecolor="#4a4a4a",
            facecolor="#f7f7f7",
        )
        ax.add_patch(patch)
        ax.text(x + width / 2, y + height * 0.66, title, ha="center", va="center", fontsize=10)
        ax.text(
            x + width / 2,
            y + height * 0.32,
            detail,
            ha="center",
            va="center",
            fontsize=8.5,
            color="#333333",
        )

    arrows = [
        ((0.205, 0.72), (0.275, 0.72)),
        ((0.465, 0.72), (0.535, 0.72)),
        ((0.745, 0.72), (0.795, 0.72)),
        ((0.89, 0.57), (0.89, 0.37)),
        ((0.745, 0.22), (0.795, 0.22)),
    ]
    for start, end in arrows:
        arrow = FancyArrowPatch(
            start,
            end,
            arrowstyle="-|>",
            mutation_scale=12,
            linewidth=1.1,
            color="#444444",
        )
        ax.add_patch(arrow)

    save_figure(fig, "method_overview")


def plot_budget_sensitivity(aggregate_rows: list[dict[str, str]]) -> None:
    fig, axes = plt.subplots(1, 2, figsize=(8.2, 3.4), dpi=300, sharex=True)
    top_n = 10
    metrics = [
        ("evidence_recall_mean", r"Evidence recall", "(a) Recall"),
        ("evidence_f1_mean", r"Evidence $F_1$", "(b) $F_1$"),
    ]

    for ax, (metric, ylabel, title) in zip(axes, metrics, strict=True):
        for method in METHODS:
            rows = aggregate_subset(aggregate_rows, method=method, top_n=top_n)
            rows.sort(key=lambda row: as_int(row, "budget"))
            ax.plot(
                [as_int(row, "budget") for row in rows],
                [as_float(row, metric) for row in rows],
                marker=MARKERS[method],
                linewidth=1.8,
                markersize=5.5,
                color=COLORS[method],
                label=SHORT_LABELS[method],
            )
        ax.set_title(title)
        ax.set_xlabel(r"Context budget $B$ (simple word tokens)")
        ax.set_ylabel(ylabel)
        ax.set_xticks([1600, 3200, 6400])
        ax.set_ylim(0.0, 0.58 if metric == "evidence_recall_mean" else 0.46)
        style_axis(ax)

    axes[1].legend(
        loc="lower right",
        fontsize=7.2,
        frameon=True,
        shadow=False,
        facecolor="white",
        edgecolor="#d0d0d0",
    )
    fig.tight_layout(w_pad=2.0)
    save_figure(fig, "budget_sensitivity")


def plot_precision_recall(aggregate_rows: list[dict[str, str]]) -> None:
    fig, ax = plt.subplots(figsize=(6.2, 4.6), dpi=300)
    top_n = 10

    for method in METHODS:
        rows = aggregate_subset(aggregate_rows, method=method, top_n=top_n)
        rows.sort(key=lambda row: as_int(row, "budget"))
        recalls = [as_float(row, "evidence_recall_mean") for row in rows]
        precisions = [as_float(row, "evidence_precision_mean") for row in rows]
        ax.plot(
            recalls,
            precisions,
            marker=MARKERS[method],
            linewidth=1.7,
            markersize=6,
            color=COLORS[method],
            label=SHORT_LABELS[method],
        )

    ax.set_title(r"Budget paths in precision--recall space")
    ax.set_xlabel(r"Evidence recall")
    ax.set_ylabel(r"Evidence precision")
    ax.set_xlim(0.16, 0.56)
    ax.set_ylim(0.25, 0.57)
    style_axis(ax)
    ax.legend(
        loc="upper right",
        fontsize=7.5,
        frameon=True,
        shadow=False,
        facecolor="white",
        edgecolor="#d0d0d0",
    )
    ax.text(
        0.17,
        0.265,
        "Each line traces budgets 1600 -> 3200 -> 6400.",
        fontsize=8.2,
        color="#444444",
    )
    fig.tight_layout()
    save_figure(fig, "precision_recall_tradeoff")


def plot_scalability_optimality(
    aggregate_rows: list[dict[str, str]],
    optimal_rows: list[dict[str, str]],
) -> None:
    fig, axes = plt.subplots(1, 2, figsize=(8.2, 3.5), dpi=300)
    budget = 6400
    runtime_methods = ("top_ranked", "relevance_ratio", "mmr", "submodular_combined")

    for method in runtime_methods:
        rows = aggregate_subset(aggregate_rows, method=method, budget=budget)
        rows.sort(key=lambda row: as_int(row, "top_n"))
        axes[0].plot(
            [as_int(row, "top_n") for row in rows],
            [as_float(row, "runtime_units_mean") for row in rows],
            marker=MARKERS[method],
            linewidth=1.8,
            markersize=5.5,
            color=COLORS[method],
            label=SHORT_LABELS[method],
        )
    axes[0].set_title("(a) Runtime proxy")
    axes[0].set_xlabel(r"Candidate set size $N$")
    axes[0].set_ylabel(r"Runtime proxy units (log scale)")
    axes[0].set_xticks([10, 20, 40])
    axes[0].set_yscale("log")
    style_axis(axes[0])
    axes[0].legend(
        loc="upper left",
        fontsize=7.3,
        frameon=True,
        shadow=False,
        facecolor="white",
        edgecolor="#d0d0d0",
    )

    objectives = ("coverage", "diversity", "combined")
    labels = ("Coverage", "Diversity", "Combined")
    data = []
    for objective in objectives:
        values = [
            as_float(row, "approx_ratio")
            for row in optimal_rows
            if row["status"] == "executed"
            and row["selector"] == "budgeted_greedy"
            and row["objective"] == objective
            and row["approx_ratio"]
        ]
        data.append(values)

    box = axes[1].boxplot(
        data,
        tick_labels=labels,
        patch_artist=True,
        widths=0.55,
        showmeans=True,
        meanprops={
            "marker": "o",
            "markerfacecolor": "#333333",
            "markeredgecolor": "#333333",
            "markersize": 4,
        },
        medianprops={"color": "#111111", "linewidth": 1.3},
        boxprops={"linewidth": 1.0},
        whiskerprops={"linewidth": 1.0},
        capprops={"linewidth": 1.0},
        flierprops={
            "marker": ".",
            "markerfacecolor": "#666666",
            "markeredgecolor": "#666666",
            "alpha": 0.30,
        },
    )
    for patch, color in zip(box["boxes"], ("#CC79A7", "#E69F00", "#56B4E9"), strict=True):
        patch.set_facecolor(color)
        patch.set_alpha(0.65)

    axes[1].axhline(1.0, color="#444444", linestyle="--", linewidth=1.0, alpha=0.8)
    axes[1].set_title("(b) Greedy vs. exact optimum")
    axes[1].set_xlabel(r"Objective")
    axes[1].set_ylabel(r"$F(S_{\mathrm{greedy}})/F(S^*)$")
    axes[1].set_ylim(0.0, 1.08)
    style_axis(axes[1])

    fig.tight_layout(w_pad=2.0)
    save_figure(fig, "scalability_optimality")


def plot_scalability_optimality_from_artifacts() -> None:
    runtime_rows = read_markdown_table(ARTIFACT_DIR / "runtime_by_candidate_size.md")
    optimal_rows = read_markdown_table(ARTIFACT_DIR / "optimal_checks.md")

    fig, axes = plt.subplots(1, 2, figsize=(8.6, 3.55), dpi=300)
    budget = 6400
    runtime_methods = (
        ("top_ranked", "Top-ranked", "#0072B2", "o"),
        ("relevance_ratio", "Relevance/token", "#D55E00", "s"),
        ("mmr", "MMR", "#009E73", "^"),
        ("submodular_combined_lambda_2", "Combined, lambda=2", "#56B4E9", "P"),
        ("lazy_submodular_combined_lambda_2", "Lazy combined, lambda=2", "#000000", "X"),
    )

    for method, label, color, marker in runtime_methods:
        rows = [
            row
            for row in runtime_rows
            if row["Method"] == method and int(row["Budget"]) == budget
        ]
        rows.sort(key=lambda row: int(row["Top N"]))
        axes[0].plot(
            [int(row["Top N"]) for row in rows],
            [float(row["runtime_units_mean"]) for row in rows],
            marker=marker,
            linewidth=1.8,
            markersize=5.5,
            color=color,
            label=label,
        )
    axes[0].set_title("(a) Runtime proxy")
    axes[0].set_xlabel(r"Candidate set size $N$")
    axes[0].set_ylabel(r"Runtime proxy units (log scale)")
    axes[0].set_xticks([10, 20, 40])
    axes[0].set_yscale("log")
    style_axis(axes[0])

    objectives = ("coverage", "diversity", "combined")
    labels = ("Coverage", "Diversity", "Combined")
    data = []
    summary = []
    for objective in objectives:
        values = [
            float(row["Approx Ratio"])
            for row in optimal_rows
            if row["Status"] == "executed"
            and row["Selector"] == "budgeted_greedy"
            and row["Objective"] == objective
            and row["Approx Ratio"]
        ]
        data.append(values)
        summary.append((sum(values) / len(values), min(values)))

    box = axes[1].boxplot(
        data,
        tick_labels=labels,
        patch_artist=True,
        widths=0.55,
        showmeans=True,
        meanprops={
            "marker": "o",
            "markerfacecolor": "#333333",
            "markeredgecolor": "#333333",
            "markersize": 4,
        },
        medianprops={"color": "#111111", "linewidth": 1.3},
        boxprops={"linewidth": 1.0},
        whiskerprops={"linewidth": 1.0},
        capprops={"linewidth": 1.0},
        flierprops={
            "marker": ".",
            "markerfacecolor": "#666666",
            "markeredgecolor": "#666666",
            "alpha": 0.28,
        },
    )
    for patch, color in zip(box["boxes"], ("#CC79A7", "#E69F00", "#56B4E9"), strict=True):
        patch.set_facecolor(color)
        patch.set_alpha(0.65)

    axes[1].axhline(1.0, color="#444444", linestyle="--", linewidth=1.0, alpha=0.8)
    axes[1].set_title("(b) Greedy vs. exact optimum")
    axes[1].set_xlabel(r"Objective")
    axes[1].set_ylabel(r"$F(S_{\mathrm{greedy}})/F(S^*)$")
    axes[1].set_ylim(0.82, 1.01)
    axes[1].set_yticks([0.85, 0.90, 0.95, 1.00])
    style_axis(axes[1])
    for idx, (mean_value, min_value) in enumerate(summary, start=1):
        axes[1].text(
            idx,
            0.835,
            f"mean {mean_value:.3f}\nmin {min_value:.3f}",
            ha="center",
            va="bottom",
            fontsize=6.8,
            color="#333333",
        )

    handles, labels_for_legend = axes[0].get_legend_handles_labels()
    fig.legend(
        handles,
        labels_for_legend,
        loc="lower center",
        ncol=3,
        fontsize=7.3,
        frameon=True,
        facecolor="white",
        edgecolor="#d0d0d0",
    )
    fig.tight_layout(rect=(0.0, 0.16, 1.0, 1.0), w_pad=2.1)
    save_figure(fig, "scalability_optimality")


def main() -> None:
    configure_matplotlib()
    plot_method_overview()
    plot_scalability_optimality_from_artifacts()


if __name__ == "__main__":
    main()
