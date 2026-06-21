#import "@preview/charged-ieee:0.1.4": ieee
#import "@preview/tablem:0.3.0": three-line-table

#show: ieee.with(
  title: [Budgeted Submodular Context Selection for Retrieval-Augmented Generation],
  abstract: [
    We study the context-packing step in retrieval-augmented generation (RAG): given retrieved documents with unequal token costs, select a subset that fits in the language-model context. We formulate this as knapsack-constrained monotone submodular maximization and adapt the Lin--Bilmes coverage/diversity framework from summarization to evidence selection. On a deterministic 200-query MultiHop-RAG slice, relevance-per-token and top-ranked retrieval remain strong baselines, while the submodular objectives provide a principled recall-oriented selector. A lambda ablation shows that larger diversity weight improves evidence recovery in this setup, and lazy greedy preserves the same objective while reducing marginal-gain evaluations by roughly one to two orders of magnitude.
  ],
  authors: (
    (name: "Junqi Liu - 2025234339", email: "liujq2025@shanghaitech.edu.cn"),
    (name: "Xu Zhu - 2025234378", email: "zhuxu2025@shanghaitech.edu.cn"),
    (name: "Yuxuan Fu - 2025234266", email: "fuyx2025@shanghaitech.edu.cn"),
    (
      name: "Zhixin Xiao - 2025234366",
      email: "xiaozhx2025@shanghaitech.edu.cn",
    ),
    (name: "Ledu Zhang - 2025234374", email: "zhangld2025@shanghaitech.edu.cn"),
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

= Introduction and Related Work

RAG systems retrieve external documents, but only a limited subset can be placed in the prompt. Rank-only packing ignores token costs and can repeat near-duplicate evidence. This project treats context packing as a classical algorithmic problem: select documents under a knapsack-style budget while maximizing coverage and diversity. The connection is direct: the context window is the budget, evidence recovery resembles maximum coverage, and redundancy control follows the diminishing-returns structure of submodular functions.

The central question is whether Lin--Bilmes-style monotone submodular objectives can improve evidence coverage or reduce redundant context compared with rank-only and reranking baselines. The study is deliberately independent of live LLM calls: retrieval features, candidate sets, random seeds, and tie-breaking are deterministic, so the behavior of the selector can be analyzed as an algorithmic object rather than as a noisy end-to-end generation pipeline.

This work makes four contributions. First, it gives a formal reduction from RAG context packing to budgeted monotone submodular maximization. Second, it adapts the Lin--Bilmes coverage/diversity objective family from summarization to evidence selection with explicit token costs. Third, it evaluates the resulting selectors against rank-based, cost-normalized, random, and corrected MMR baselines, including exhaustive optimal checks on small instances. Fourth, it adds two engineering-oriented extensions: a $lambda$ ablation for the combined objective and lazy greedy acceleration for marginal-gain evaluation.

Our method-level reproduction adapts Lin and Bilmes's submodular summarization objective @lin2011submodular to RAG evidence selection. RAG motivates the setting @lewis2020rag, MultiHop-RAG supplies questions and gold evidence lists @tang2024multihoprag, MMR is a diversity reranking baseline @carbonell1998mmr, and budgeted maximum coverage provides the theoretical analogue @khuller1999budgeted. The goal is not SOTA RAG accuracy; it is to show how a modern LLM context-selection problem instantiates greedy approximation, knapsack constraints, and submodular maximization.

The reproduction target is method-level rather than benchmark-identical. The central object reproduced from Lin and Bilmes is the coverage/diversity submodular optimization framework under a length budget, not a particular summarization benchmark. The adaptation changes the unit of selection from summary sentences to retrieved RAG documents and changes the evaluation signal from human summary quality to gold-evidence recovery.

= Formulation and Method

For a query $q$, the retriever returns candidates $C={d_1,...,d_n}$. Document $d_i$ has token cost $c_i$, relevance $r_i>=0$, and pairwise similarity $w_(i,j)>=0$. The selector outputs a feasible subset:

$ max_(S subset.eq C) F_q(S) quad "subject to" quad sum_(d_i in S)c_i <= B. $

We use the coverage objective

$ L_q(S)=sum_(i=1)^n r_i max_(j in S) w_(i,j), $

which rewards selected documents that represent relevant candidates, and the concave diversity objective

$ R_q(S)=sqrt(sum_(i in S) r_i). $

The combined objective is $F_q(S)=L_q(S)+lambda R_q(S)$. We define $max_(j in emptyset) w_(i,j)=0$, so $L_q(emptyset)=R_q(emptyset)=F_q(emptyset)=0$. For a set function $F$, the marginal gain of adding $x$ is $Delta_x^F(S)=F(S union {x})-F(S)$.

The implemented direct selector repeatedly adds the feasible document with largest marginal gain per token, $Delta_x^F(S)/c_x$, then compares the result with the best feasible singleton.

#block(
  width: 100%,
  stroke: 0.65pt + black,
  inset: 5pt,
  breakable: false,
)[
  *Algorithm 1: Budgeted greedy context selection* \
  *Input:* candidates $C$, costs $c_i$, budget $B$, objective $F_q$. \
  *Initialize:* $S=emptyset$. \
  *Repeat:* choose the feasible unselected document with maximum marginal density $Delta_x^F(S)/c_x$ and add it when the gain is positive. \
  *Return:* the better set under $F_q$ between the greedy solution and the best feasible singleton.
]

The lazy greedy variant uses the same objective but caches marginal-gain densities in a priority queue. By submodularity, old marginal gains are upper bounds after the selected set grows, so many candidates do not need to be recomputed every round.

*Proposition 1 (coverage).* $L_q(S)$ is monotone submodular.

*Proof.* For each candidate $d_i$, define $m_i(S)=max_(j in S) w_(i,j)$ with $m_i(emptyset)=0$. If $A subset.eq B$, then $m_i(A)<=m_i(B)$ for every $i$. Hence $L_q(A)<=L_q(B)$ because all relevance weights $r_i$ are nonnegative, proving monotonicity. For any $x in C - B$, the marginal coverage gain is

$ Delta_x^L(S)=sum_i r_i (max(m_i(S), w_(i,x))-m_i(S)). $

For a fixed $i$ and $x$, let $g_i(m)=max(m, w_(i,x))-m$. This term is $w_(i,x)-m$ when $m<w_(i,x)$ and $0$ otherwise, so it is nonincreasing in $m$. Since $m_i(A)<=m_i(B)$, we have $g_i(m_i(A))>=g_i(m_i(B))$. Multiplying by $r_i>=0$ and summing over $i$ gives $Delta_x^L(A)>=Delta_x^L(B)$. This is the diminishing-returns condition, so $L_q$ is submodular. $square$

*Proposition 2 (concave relevance term).* $R_q(S)=sqrt(sum_(i in S) r_i)$ is monotone submodular.

*Proof.* Let $a(S)=sum_(i in S) r_i$. Since $r_i>=0$, $a(S)$ is a nonnegative modular function and $A subset.eq B$ implies $a(A)<=a(B)$. Because $sqrt(.)$ is nondecreasing, $R_q(A)<=R_q(B)$. The marginal gain of adding $x$ is

$ Delta_x^R(S)=sqrt(a(S)+r_x)-sqrt(a(S)). $

For $r_x>=0$, this quantity is nonnegative. It also decreases as $a(S)$ increases because $sqrt(.)$ is concave: the same increment $r_x$ gives a smaller increase when the base value is larger. Thus $A subset.eq B$ implies $Delta_x^R(A)>=Delta_x^R(B)$, so $R_q$ is submodular. $square$

*Corollary 1 (combined objective).* For $lambda>=0$, $F_q(S)=L_q(S)+lambda R_q(S)$ is nonnegative, monotone, and submodular. This follows because nonnegative linear combinations preserve these three properties. The exact optimization problem is NP-hard: if all costs are unit costs, $lambda=0$, and similarities encode set coverage, the problem contains maximum coverage as a special case; with unequal costs, it contains budgeted maximum coverage @khuller1999budgeted.

*Theorem 1 (budgeted greedy justification).* For nonnegative monotone submodular maximization under one knapsack constraint, marginal-density greedy with a best-feasible-singleton comparison is a constant-factor approximation in the standard budgeted-coverage setting @khuller1999budgeted.

*Proof sketch.* Items with $c_i>B$ can be ignored. Let $O$ be an optimal feasible set. Consider the conceptual density-greedy order before any overflow is discarded: at prefix $S_t$, the next item $x_t$ maximizes $Delta_x^F(S_t)/c_x$. By monotonicity, $F_q(O)<=F_q(O union S_t)$. By submodularity, adding the elements of $O - S_t$ one at a time to $S_t$ gives

$ F_q(O union S_t)-F_q(S_t) <= sum_(x in O - S_t) Delta_x^F(S_t). $

The total cost of $O$ is at most $B$, so the weighted-average density of the optimal residual is at least $(F_q(O)-F_q(S_t))/B$. The greedy density is at least this average. If the next greedy item has cost $c_t$, then the residual gap contracts as

$ F_q(O)-F_q(S_(t+1)) <= (1-c_t/B)(F_q(O)-F_q(S_t)). $

Iterating this inequality until the first item $x_h$ whose addition would exceed $B$ gives the standard fractional bound $F_q(S_h union {x_h}) >= (1-1\/e) F_q(O)$. Since $F_q(S_h union {x_h}) <= F_q(S_h)+F_q({x_h})$ by submodularity and normalization, at least one of the prefix $S_h$ and singleton ${x_h}$ has value at least half of this bound. The implemented selector keeps a feasible greedy set whose value is no smaller than the pre-overflow prefix and explicitly compares it with the best feasible singleton, so it inherits a constant-factor guarantee from this standard analysis @khuller1999budgeted. We do not claim the tightest possible $1-1\/e$ submodular-knapsack ratio, which requires more elaborate enumeration; the point here is to reproduce and analyze the course-relevant greedy approximation rule. $square$

*Lemma 2 (lazy greedy correctness).* Lazy greedy returns the same greedy choice as direct greedy under the same deterministic tie-breaking; it changes evaluation cost, not the objective.

*Proof.* Suppose an item's marginal density was last computed for set $A$ and the current selected set is $B$ with $A subset.eq B$. By submodularity, $Delta_x^F(A)>=Delta_x^F(B)$, so the cached density is an upper bound on the current density. Lazy greedy stores these upper bounds in a priority queue. When an item is popped and recomputed for the current $B$, if it remains at the top, every other item has true density no larger than its cached upper bound, which is no larger than the recomputed top key. Therefore the popped item is exactly the item direct greedy would select. If it is not still on top, the algorithm pushes back the updated lower key and repeats. Thus lazy evaluation preserves the greedy sequence and only avoids unnecessary marginal-gain recomputations. $square$

Direct greedy has a conservative uncached cost of $O(k n^2)$ objective work for $k$ selected documents when each marginal recomputes coverage over $n$ candidates. Lazy greedy has the same worst-case bound but often performs far fewer recomputations because stale marginal densities are valid upper bounds. Exhaustive search is exponential, so we use it only for small top-10 validation instances.

#place(
  top,
  float: true,
  scope: "parent",
  figure(
    image("figures/method_overview.png", width: 70%),
    caption: [Pipeline. A retriever supplies candidates, feature extraction computes relevance/cost/similarity, greedy submodular selection packs a feasible context set, and the selected documents are compared with MultiHop-RAG gold evidence.],
  ),
)

= Experimental Setup

Experiments are offline and deterministic. TF-IDF retrieval supplies candidate sets; TF-IDF cosine scores also define query relevance and pairwise similarity. We evaluate 200 MultiHop-RAG queries sampled with seed 13, candidate sizes $N in {10,20,40}$, and document-level budgets $B in {1600,3200,6400}$ simple word tokens. The baselines are top-ranked selection, relevance-per-token, seeded random, and corrected MMR. Proposed methods are direct and lazy budgeted greedy with coverage, diversity, and combined objectives, including $lambda in {0.1,0.5,1.0,2.0}$.

#figure(
  kind: table,
  three-line-table[
    | *Component* | *Setting* |
    | :-------- | :------ |
    | Dataset | MultiHop-RAG questions with nonempty evidence lists. |
    | Sample | 200 queries selected with seed 13. |
    | Candidate sizes | $N in {10,20,40}$. |
    | Budgets | $B in {1600,3200,6400}$ simple word tokens. |
    | Features | TF-IDF query relevance and pairwise cosine similarity. |
    | Baselines | Top-ranked, relevance/token, seeded random, corrected MMR. |
    | Proposed methods | Direct/lazy greedy with coverage, diversity, combined objectives. |
    | Combined lambdas | $lambda in {0.1,0.5,1.0,2.0}$. |
  ],
  caption: [Main experimental configuration.],
)

Metrics compare selected document IDs with gold evidence IDs: evidence recall, precision, and $F_1$. We also report mean pairwise redundancy, budget utilization, deterministic runtime proxy units, and exhaustive greedy-vs-optimal checks for small top-10 instances. The official corpus contains full news articles, so small passage-level budgets would admit no documents; the chosen budgets model selecting one to several articles.

= Results

== Budget Sensitivity

@budget_sensitivity shows the main budget trend. At $B=3200$, relevance/token reaches recall 0.393 and $F_1$ 0.400, while submodular diversity reaches recall 0.391 and $F_1$ 0.397. At $B=6400$, the combined objective with $lambda=2$ reaches the highest reported recall among the highlighted direct submodular variants, 0.524, but its $F_1$ is 0.364 because it includes more non-evidence articles. Top-ranked has lower recall at this budget, 0.492, but better $F_1$ of 0.407. Thus the submodular objective is best read as recall-oriented evidence coverage, not a strict precision optimizer.

#figure(
  image(
    "figures/multihop_q200_docbudget_s13/budget_sensitivity.png",
    width: 100%,
  ),
  caption: [Budget sensitivity for top-10 candidates. Recall rises as the budget admits more articles; $F_1$ reflects the precision cost of adding extra non-evidence documents.],
)<budget_sensitivity>

// #figure(
//   kind: table,
//   three-line-table[
//     | *Budget* | *Method* | *Recall* | *Precision* | *$F_1$* |
//     | :------: | :------- | :------: | :---------: | :----: |
//     | 3200 | Top-ranked | 0.320 | 0.450 | 0.360 |
//     | 3200 | Relevance/token | 0.393 | 0.439 | 0.400 |
//     | 3200 | Submodular diversity | 0.391 | 0.433 | 0.397 |
//     | 6400 | Top-ranked | 0.492 | 0.374 | 0.407 |
//     | 6400 | Combined, $lambda=2$ | 0.524 | 0.290 | 0.364 |
//   ],
//   caption: [Representative evidence-selection results for top-10 candidates.],
// )

== Lambda and Precision--Recall Trade-off

For the direct combined selector with top-10 candidates, increasing $lambda$ improves evidence recovery in this run. At budget 3200, $F_1$ rises from 0.320 for $lambda=0.1$ to 0.374 for $lambda=2.0$; at budget 6400, it rises from 0.349 to 0.364. Redundancy also increases slightly, from 0.428 to 0.441 at budget 6400, because the square-root diversity term rewards additional relevance mass rather than explicitly penalizing pairwise similarity.

// #figure(
//   kind: table,
//   three-line-table[
//     | *Budget* | *$lambda$* | *Recall* | *Precision* | *$F_1$* | *Redund.* |
//     | :------: | :--------: | :------: | :---------: | :----: | :-------: |
//     | 3200 | 0.1 | 0.314 | 0.347 | 0.320 | 0.407 |
//     | 3200 | 0.5 | 0.325 | 0.357 | 0.330 | 0.414 |
//     | 3200 | 1.0 | 0.338 | 0.368 | 0.342 | 0.416 |
//     | 3200 | 2.0 | 0.370 | 0.402 | 0.374 | 0.426 |
//     | 6400 | 0.1 | 0.502 | 0.278 | 0.349 | 0.428 |
//     | 6400 | 0.5 | 0.506 | 0.280 | 0.351 | 0.432 |
//     | 6400 | 1.0 | 0.508 | 0.283 | 0.354 | 0.437 |
//     | 6400 | 2.0 | 0.524 | 0.290 | 0.364 | 0.441 |
//   ],
//   caption: [Ablation of the combined-objective weight $lambda$ for direct budgeted greedy with top-10 candidates.],
// )

@precision_recall_tradeoff makes the trade-off explicit. The submodular selectors recover more evidence as budget grows, but gold-evidence precision drops when they include extra context. This behavior is useful when missing evidence is more harmful than adding distractors; if strict precision is preferred, the objective should add stronger cost penalties or a learned evidence-likelihood term.

#figure(
  image(
    "figures/multihop_q200_docbudget_s13/precision_recall_tradeoff.png",
    width: 80%,
  ),
  caption: [Precision--recall trade-off as the budget increases from 1600 to 3200 to 6400 for top-10 candidates. Methods that fill more budget tend to move rightward in recall and downward in precision.],
)<precision_recall_tradeoff>

== Scalability and Greedy Validation

@scalability_optimality explains the main engineering result. At budget 6400, direct combined greedy with $lambda=2$ uses 452.0, 2040.0, and 8464.0 runtime-proxy units for $N=10,20,40$. Lazy greedy uses 23.6, 47.5, and 93.6 units on the same settings, because most cached marginal-gain upper bounds do not need full recomputation. The right panel is intentionally zoomed: the mean greedy/optimal ratios are about 0.991 for coverage, 0.990 for diversity, and 0.990 for the combined objective, with medians equal to 1.0.

#figure(
  image(
    "figures/multihop_q200_docbudget_s13/scalability_optimality.png",
    width: 100%,
  ),
  caption: [Scalability and greedy validation. Panel (a) compares deterministic runtime proxy units at budget 6400. Panel (b) zooms in on exhaustive top-10 checks; the ratios cluster near 1.0, so the direct greedy solutions are usually very close to exact optima on tested instances.],
)<scalability_optimality>

= Discussion and Conclusion

The strongest baseline is relevance/token, which shows that cost normalization is hard to beat when the retriever ranks evidence early. Top-ranked selection remains attractive when precision matters, but it has no explicit model of cost or redundancy. MMR adds local novelty control, while the submodular objectives optimize a global set function under a budget and expose the algorithmic structure of the problem.

The main deviation from Lin and Bilmes is the application domain. Their items are summarization units; our items are retrieved documents for a query. Their summary length budget becomes an LLM context-token budget, and the primary metric becomes evidence recovery instead of human summary quality. The method-level reproduction remains the same: compare coverage-only, diversity-only, and combined objectives under greedy budgeted selection.

The results also clarify what the current objective optimizes. Coverage over the retrieved candidate pool is not identical to gold-evidence precision. When the budget grows, submodular selectors often recover additional gold documents but also include more distractors, so recall can improve while $F_1$ falls behind top-ranked selection. This is an objective-design issue rather than a failure of submodularity. A stricter downstream system could add learned evidence probabilities, stronger cost penalties, or a direct negative redundancy term.

The limitations are deliberate. Retrieval is TF-IDF rather than dense or hybrid retrieval, and evaluation stops at evidence selection rather than final answer generation. These choices isolate the course-relevant optimization question and keep the experiment reproducible. Overall, the project connects RAG context packing to budgeted maximum coverage and monotone submodular maximization, shows the precision--recall consequences of the objective, and demonstrates that lazy greedy can preserve the objective while making the selector much cheaper to evaluate.

= Reproducibility

The code, commands, fixtures, and experiment notes are in the project repository: `https://github.com/0x1B05/cs240`. The main run uses a deterministic 200-query MultiHop-RAG cache, fixed seed 13, candidate sizes 10/20/40, and budgets 1600/3200/6400. The source code implements data preparation, retrieval, feature construction, objectives, selectors, metrics, exhaustive checks, and artifact generation.
