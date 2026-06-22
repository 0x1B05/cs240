#import "@local/cheatsheet:0.1.0": *

#show: doc => cheatsheet(
  title: "CS240 Final Cheatsheet",
  authors: ((name: "0x1B05"),),
  date: datetime(year: 2026, month: 6, day: 22),
  columns-count: 5,
  font-size: 7pt,
  doc,
)

#set text(lang: "zh")
#let Pr = math.op("Pr")
#let E = math.op("E")
#let Var = math.op("Var")
#let OPT = math.op("OPT")
#let ALG = math.op("ALG")
#let O = math.op("O")
#let Theta = math.op("Theta")
#let cost = math.op("cost")
#let poly = math.op("poly")
#let NP = math.op("NP")
#let PSPACE = math.op("PSPACE")
#let EXPTIME = math.op("EXPTIME")
#let Phi = math.op("Phi")
#let Delta = math.op("Delta")
#let cross = math.op("cross")
#let same = math.op("same")
#let prod = math.op("prod")
#let binom = math.op("binom")
#let floor = math.op("floor")
#let max = math.op("max")
#let min = math.op("min")
#let deg = math.op("deg")
#let ln = math.op("ln")
#let approx = math.op("approx")

== Greedy Review

#smallcaps[Core idea.]
Build solution step by step. Make the best local choice and never revisit earlier decisions. Greedy is correct only when the local rule is *safe*.

#smallcaps[General framework.]
1. Order candidates by local priority: finish time, deadline, edge weight, future request time.
2. Test feasibility: keep choice only if compatible with partial solution.
3. Update small state: last finish time, components, cache, current cover.
4. Prove correctness and complexity.

#smallcaps[When it works.]
Greedy-choice property: some optimal solution starts with greedy choice. Optimal substructure: after greedy choice, remaining subproblem is same type.

#smallcaps[Proof toolkit.]
*Stays ahead*: compare greedy prefix with any solution after each step. Show greedy is never worse.

*Exchange*: start from optimal solution. If it lacks greedy choice, swap in greedy choice; show feasibility and value no worse.

*Structural*: use theorem/invariant, e.g. MST cut/cycle property.

#smallcaps[Exam checklist.]
objective -> local rule -> feasibility condition -> counterexample to tempting wrong rules -> proof template -> complexity.

== Divide And Conquer

Break problem into subproblems, solve recursively, combine.

#smallcaps[Mergesort.]
Divide array into two halves, recursively sort, merge. Recurrence:
$T(n) = 2T(n/2) + O(n)$.
Recursion tree: level $i$ has $2^i$ subproblems of size $n/2^i$, total merge cost $n$; height $log n$; total $T(n)=O(n log n)$.

#smallcaps[Master theorem.]
For $T(n)=a T(n/b)+f(n)$, baseline is $n^(log_b a)$. Compare $f(n)$ with baseline.

Case 1 bottom dominates: `f(n)` polynomially smaller than baseline, `T(n)=Theta(n^(log_b a))`.

Case 2 balanced: `f(n)=Theta(n^(log_b a) log^k n)`, then `T(n)=Theta(n^(log_b a) log^(k+1)n)`.

Case 3 top dominates: `f(n)` polynomially larger plus regularity, `T(n)=Theta(f(n))`.

#smallcaps[Slide warnings.]
Exact match matters. `n` vs `n log n` is not equal. For `a=2,b=2`, baseline `n`: `f(n)=1` -> Case 1; `f(n)=n` -> balanced; `f(n)=n^2` -> Case 3.

== Dynamic Programming

#smallcaps[Basic idea.]
Polynomial number of overlapping subproblems with natural ordering. Optimal solution of a subproblem is built from optimal solutions of smaller subproblems.

#smallcaps[Guideline.]
1. Define subproblem: `OPT(...)`.
2. Write recurrence: e.g. `OPT(i)=max(f(OPT(j)),g(OPT(k)),...)` for smaller `j,k`.
3. Set base cases.
4. Compute bottom-up or memoized top-down.
5. Recover solution if needed by storing choices.

#smallcaps[Common states.]
Prefix: `OPT(i)` first `i` items. Interval: `OPT(i,j)` substring/range. Knapsack: `OPT(i,w)`. Tree DP: include/exclude node.

#smallcaps[Proof.]
Induct on subproblem size/order. Show recurrence exhausts all cases of an optimal solution and uses correct smaller optimal values.

== Network Flow

Flow network: directed graph `G=(V,E)`, source `s`, sink `t`, capacities `c(e)>=0`.

Flow constraints: capacity `0<=f(e)<=c(e)` and conservation at all `v != s,t`.

Residual graph `G_f`: forward residual capacity `c(e)-f(e)`; backward residual capacity `f(e)`.

Augmenting path: `s-t` path in residual graph. Bottleneck = minimum residual capacity on path.

#smallcaps[Ford-Fulkerson.]
Initialize `f(e)=0`. While residual graph has augmenting path `P`, augment along `P` by bottleneck. Stop when no augmenting path.

#smallcaps[Max-flow/min-cut.]
Equivalent conditions:
1. There exists cut `(A,B)` with `v(f)=cap(A,B)`.
2. `f` is a max flow.
3. There is no augmenting path in residual graph.

Proof when no augmenting path: let `A` be vertices reachable from `s` in `G_f`. Then `t notin A`. Forward edges `A->B` saturated; backward edges carry zero cancelable flow. Thus flow value equals cut capacity.

== Complexity Vocabulary

`P`: decision problems solvable in polynomial time.

`NP`: yes-instances have polynomial-size certificates verifiable in polynomial time.

`co-NP`: complements of NP languages; no-instances have short disqualifiers.

`NP-hard`: every `X in NP` reduces to this problem.

`NP-complete`: in NP and NP-hard.

Known relation:
$P subset NP subset PSPACE subset EXPTIME$.
`P=NP?` is open. If any NP-complete problem is in `P`, then `P=NP`.

#smallcaps[Decision version.]
Complexity theory usually asks yes/no questions. Many search/optimization versions self-reduce to decision versions by repeatedly calling a decision oracle.

== Polynomial Reduction

To prove target problem `A` hard, reduce from known hard problem `B`:
$B <=_p A$.
Meaning: if we can solve `A`, then we can solve `B`; hence `A` is at least as hard as `B`.

#smallcaps[Karp reduction.]
Given instance `b` of `B`, construct one instance `a=f(b)` of `A` in polynomial time such that:
$b " is YES for " B <==> a " is YES for " A$.

#smallcaps[NP-complete proof.]
1. Show `A in NP`: certificate + verifier.
2. Choose known NP-complete `B`.
3. Construct `f(b)` in polynomial time.
4. Prove both directions of iff.
Conclusion: `A` NP-hard and in NP, so NP-complete.

#smallcaps[Common mistakes.]
Wrong direction; missing one direction; proving intuition but not certificate/verifier; forgetting construction time.

== NP-complete Problems

`SAT`: Boolean formula satisfiable? Certificate = truth assignment.

`3-SAT`: CNF, each clause has exactly 3 literals.

`Independent Set`: choose `|S|>=k` vertices with no edge inside `S`.

`Vertex Cover`: choose `|C|<=k` vertices so every edge has at least one endpoint in `C`.

Complement relation:
$S " independent" <==> V-S " vertex cover"$.

`Set Cover`: universe `U`, subsets `S_i`, choose at most `k` sets whose union covers `U`.

`Clique`: clique in `G` iff independent set in complement graph.

`Hamiltonian Cycle/Path`: visit every vertex exactly once.

`TSP decision`: tour length at most `D`.

`3-Color`: color vertices with 3 colors, adjacent vertices different.

`Subset Sum`: choose subset summing exactly to `T`.

== Reduction Gadgets

#smallcaps[3-SAT to Independent Set.]
For each clause, make 3 vertices for its literals and connect them as a triangle. Connect complementary literals across clauses. Set `k=#clauses`.

Triangle forces at most one literal per clause. Since `k` equals number of clauses, an independent set of size `k` chooses exactly one literal from each clause. Conflict edges prevent choosing both `x` and `not x`. Chosen literals define a consistent satisfying assignment.

#smallcaps[Vertex Cover to Set Cover.]
Universe `U=E`. For each vertex `v`, create set `S_v` containing incident edges. Choosing vertices covering all edges iff choosing corresponding sets covering `U`.

#smallcaps[Hamiltonian to TSP.]
Cities are vertices. Distance 1 for graph edges, 2 for nonedges. Threshold `D=n`. Any tour has `n` edges, each at least 1; length at most `n` iff all used adjacencies are original edges.

== FPT

For NP-complete problems, cannot expect polynomial-time exact algorithms for arbitrary instances. FPT sacrifices arbitrary instances by using a small parameter.

Definition:
$"time" = f(k) dot poly(n)$.
The exponential part depends only on parameter `k`, not on input size `n`.

#smallcaps[Small Vertex Cover.]
Given `(G,k)`, choose any edge `(u,v)`. Any vertex cover must include `u` or `v`.
```
VC(G,k):
  if E empty: return YES
  if k=0: return NO
  choose edge (u,v)
  return VC(G-u,k-1) or VC(G-v,k-1)
```
Search tree has depth at most `k`, branching factor 2:
$O(2^k dot poly(n))$.
Better than brute force `n^k` when `k` small.

#smallcaps[Wavelength / circular arc coloring.]
Paths on a ring become circular arcs. Brute force `k^m` colorings. FPT idea: scan ring phases; state records colors of arcs crossing current point. If at most `k` arcs pass a point, at most `k!` consistent colorings per phase. Running time:
$f(k) dot poly(m, n)$.
Practical for small `k`; polynomial if `k=O(log n / log log n)`.

== Local Search

Template: define search space, neighbor relation, improvement rule, stopping condition.

Proof goals: every step improves potential/objective; finite states imply termination; local optimum gives exact/approx/equilibrium guarantee.

#smallcaps[Vertex Cover deletion.]
Start with `S=V`. If removing one vertex keeps a vertex cover, remove it. Terminates in at most `n` removals. Only one-delete local optimum, not necessarily global optimum.

#smallcaps[Max-Cut local search.]
Partition vertices into `(A,B)`. If flipping one vertex increases cut size, flip it. At local optimum, for every vertex `v`:
$cross(v) >= same(v)$.
Summing over all vertices:
$2 dot "cut" >= 2 dot "internal"$, $"total edges" <= 2 dot "cut"$, $OPT <= "total edges"$, hence $"cut" >= OPT/2$.
So single-flip local optimum is a `2`-approximation.

#smallcaps[Big improvement flips.]
To bound iterations, accept only sufficiently large improvement. This prevents many tiny gains; approximation weakens to about `2+epsilon`.

== Nash / Cost Sharing

Multicast routing: directed graph with edge costs `c_e`, source `s`, agents with terminals `t_j`. Agent `j` chooses path `P_j`. If `x_e` agents use edge `e`, each pays:
$c_e / x_e$.

Nash equilibrium: no agent can lower its own cost by unilaterally switching path. Social optimum minimizes total cost of used edges. They need not be equal.

Rosenthal potential:
$Phi(P)=sum_e c_e dot H(x_e)$, where $H(x)=1+1/2+...+1/x$.
When one agent changes path, its cost change equals `Delta Phi`. Therefore strict best response strictly decreases `Phi`; finite strategy space implies convergence to Nash.

Bounds:
$C(P) <= Phi(P) <= H(k) C(P)$.
Starting from social optimum and following best responses gives a Nash equilibrium with cost at most `H(k)` times optimum. Price of stability `<=H(k)`.

== Amortized Analysis

Amortized analysis is not average-case. It bounds total cost of any operation sequence.

Methods:
- Aggregate: directly bound total cost.
- Accounting: charge operations credits; store credit on objects.
- Potential: store credit in state function.

Potential formula:
$hat(c_i)=c_i + Phi(D_i)-Phi(D_(i-1))$.
If `Phi(D_0)=0` and `Phi(D_i)>=0`, then:
$sum "actual" <= sum "amortized"$.

#smallcaps[Protocol.]
Show a single call can be large if asked. Identify objects causing large work. Show each object is created and consumed `O(1)` times. For potential/accounting, choose credit matching stored future work.

== HW4 P1 Lazy Queue

`Modify(i)`: set dirty and append `i` to FIFO queue, even duplicates. `FlushOne`: remove entries until a dirty page is found and written back; stale entries discarded.

#smallcaps[Bad call.]
Do `k` times `Modify(1)`. First `FlushOne` writes page 1. Next `FlushOne` discards `k-1` stale entries before returning 0. One call costs `Theta(k)=Theta(m)`.

#smallcaps[Aggregate.]
Each queue insertion is caused by one `Modify`. Each queue entry is deleted at most once. Duplicates are separate inserted entries, so they do not break the bound. Total queue work over `m` operations is `O(m)`.

#smallcaps[Potential.]
Use $Phi = 3|Q|$.
`Modify`: actual `O(1)`, queue length increases by 1 -> amortized `O(1)`.

If `FlushOne` removes `t` entries, actual `<=2t+O(1)` and `Delta Phi=-3t`, so amortized `O(1)`.

== HW4 P2 Calibration

Triangular numbers:
$T_q = 1+2+...+q = q(q+1)/2$.
Calibration occurs when insertion count `N=T_q`; q-th calibration cost `q`.

#smallcaps[Count calibrations.]
Largest `q` with:
$q(q+1)/2 <= n$, so $q = floor((sqrt(8n+1)-1)/2)$.

#smallcaps[Aggregate.]
Base insertion cost `n`. Total calibration cost:
$1+2+...+q = T_q <= n$.
Total `<=2n`.

#smallcaps[Accounting.]
Charge 2 per insertion. One pays base insertion; one saved as calibration credit. Between calibration `q-1` and `q`, exactly `q` insertions occur, saving `q` credits to pay cost `q`.

== HW4 P3 Compaction

Array entries are live articles or tombstones. `Add` appends live; successful `Remove` marks tombstone. After remove, if tombstones `D` strictly exceed live articles `L`, run `Compact`: scan all entries, copy live entries, discard tombstones.

#smallcaps[Worst case.]
One `Remove` can trigger compaction; if array length is `n`, scan alone costs `Theta(n)`.

#smallcaps[Aggregate.]
At trigger time `D>L`. Compaction cost:
$"scan" + "copy live" = (D+L)+L = D+2L < 3D$.
Successful removes create tombstones; tombstones present at compaction can pay for cleanup. Total cost of `m` external operations is `O(m)`.

#smallcaps[Potential.]
Use $Phi = 3D$.
Add/unsuccessful remove: no change. Successful remove without compact: `Delta Phi=3`.

Trigger compact: after marking, let counts be `D',L'` with `D'>L'`. Actual `<O(1)+3D'`. Potential drops from `3(D'-1)` to 0. Amortized `O(1)`.

== Randomized Algorithms

Las Vegas: always correct, random running time; minimize expected running time.

Monte Carlo: fixed/bounded running time, may err; minimize error probability.

Event probability: `Pr[A]`. Independence:
$Pr[A " and " B] = Pr[A] Pr[B]$.

Random variable: value depends on random choices. Expectation:
$E[X] = sum_x x dot Pr[X=x]$.

Indicator for event `E`:
$X_E=1$ if $E$ occurs, else $0$; $E[X_E]=Pr[E]$.

Linearity:
$E[X_1+...+X_n]=E[X_1]+...+E[X_n]$.
No independence required.

== Geometric Distribution

Repeated independent trials until first success. Each trial succeeds with probability `p`. Let `R` be number of trials until first success.

Probability:
$Pr[R=k] = (1-p)^(k-1) p$.

Expectation:
$E[R] = 1/p$.

Derivation:
$E = p dot 1 + (1-p)(1+E)$, so $E = 1 + (1-p)E$, hence $p E = 1$.

Examples: coin head `p=1/2` -> expected 2 flips. Die rolling 6 `p=1/6` -> expected 6 rolls. Algorithm success probability `0.1` per restart -> expected 10 runs.

== HW4 P4 Random Audit

`n` submissions, exactly `r` violations. Choose `s` distinct submissions without replacement. `X` = number of violations found.

#smallcaps[Expectation.]
For each violating submission `i`, indicator `X_i=1` if selected. Then:
$X=sum_{i=1}^r X_i$, $Pr[X_i=1]=s/n$, and $E[X]=r s/n$.
Linearity works without replacement.

#smallcaps[No violation.]
All selected submissions are clean:
$Pr[X=0] = binom(n-r, s) / binom(n, s)$.
Equivalently:
$Pr[X=0] = product_{i=0}^{s-1} (n-r-i)/(n-i)$.

#smallcaps[Exponential bound.]
For `s<=n-r`:
$ (n-r-i)/(n-i) = 1 - r/(n-i) <= 1-r/n $, and $Pr[X=0] <= (1-r/n)^s <= e^(-r s/n)$.
To get `Pr[X>=1] >= 1-delta`, sufficient:
$s >= (n/r) ln(1/delta)$.

== HW4 P5 Priority Filter

Each vertex independently chooses continuous priority. Vertex `v` selected iff its priority is smaller than every neighbor's priority.

#smallcaps[Independent set.]
If adjacent `u,v` both selected, then `p(u)<p(v)` and `p(v)<p(u)`, impossible. Thus selected set `S` is always independent.

#smallcaps[Selection probability.]
In closed neighborhood `{v} union N(v)`, there are `deg(v)+1` iid continuous priorities. Each vertex is equally likely to have minimum priority:
$Pr[v in S] = 1/(deg(v)+1)$.

#smallcaps[Expected size.]
Let `X_v=1[v in S]`. Then:
$|S| = sum_v X_v$, and $E[|S|] = sum_v 1/(deg(v)+1)$.
If graph is `d`-regular:
$E[|S|] = |V|/(d+1)$.

== Tail Bounds

Use more assumptions for stronger concentration.

Markov: for `X>=0`,
$Pr[X>=a] <= E[X]/a$.
Rough one-sided bound from expectation only.

Chebyshev: finite variance,
$Pr[|X-E[X]|>=a] <= Var[X]/a^2$.
Two-sided deviation without distribution assumptions.

Chernoff: independent 0/1 indicators, `X=sum X_i`, `mu=E[X]`.
For `0<=delta<=1`:
$Pr[X >= (1+delta) mu] <= e^(-mu delta^2/3)$, and $Pr[X <= (1-delta) mu] <= e^(-mu delta^2/2)$.
For `delta>1`:
$Pr[X >= (1+delta) mu] <= e^(-mu delta ln delta/3)$.

Union bound: no independence needed.
$Pr[union_i E_i] <= sum_i Pr[E_i]$.
Use: first bound failure for one fixed object, then extend to any object fails.

== Approximation Ratio

For maximization:
$ALG >= OPT / alpha$.
For minimization:
$ALG <= alpha dot OPT$.
`alpha >= 1`; closer to 1 is better.

Expected approximation: for randomized algorithms, replace `ALG` by `E[ALG]`.

#smallcaps[Proof protocol.]
Maximization: upper bound `OPT`, lower bound `ALG`. Minimization: lower bound `OPT`, upper bound `ALG`. State ratio explicitly.

== Set Cover Greedy

Input: collection `F` of sets, each with cost; union is universe `X`. Output subcollection covering `X`. Goal: minimize total cost. Minimum set cover is NP-complete.

Greedy maintains:
- `U`: uncovered elements.
- `C`: chosen sets.

Algorithm:
```
U = X; C = empty
while U != empty:
    choose S in F-C minimizing cost(S)/|S inter U|
    C = C union {S}
    U = U - S
return C
```

#smallcaps[Correctness.]
The loop continues until `U` empty, so output is a set cover.

#smallcaps[Approximation proof.]
Let optimal cost be `V=OPT`, `n=|X|`. When `k` elements remain uncovered, the optimal cover of cost `V` covers those `k` elements, so some optimal set has average uncovered cost at most `V/k`. Greedy chooses a set with no larger average cost.

Charge each newly covered element the average cost of the set that first covers it. The `j`-th covered element is charged at most:
$V/(n-j+1)$.
Total greedy cost:
$<= V(1/n + 1/(n-1) + ... + 1) = V H_n <= V(1+ln n)$.
So greedy is `H_n`-approximation, i.e. `O(log n)`.

== Scheduling Approx

Makespan scheduling: `n` jobs, `m` identical machines, processing times `p_j`. Minimize max load `M`.

Lower bounds:
$M^* >= max_j p_j$ and $M^* >= (sum_j p_j)/m$.

#smallcaps[List Scheduling.]
Assign each job to currently least loaded/first available machine. Let last finishing job have start time `T`, processing time `t`. Output `M=T+t`.

Before `T`, no machine was idle, so optimal must satisfy `M*>=T`. Also `M*>=t`.
$M=T+t <= 2 max(T, t) <= 2M^*$.
Thus list scheduling is `2`-approximation.

#smallcaps[LPT.]
Sort jobs decreasing by processing time, then list schedule. Offline; ratio `4/3`. Key idea: last-starting job is smallest. If `t<=M*/3`, then `M<=M*+t<=4M*/3`; otherwise all jobs are large and each optimal machine has at most two jobs.

== Random Max-Cut

Put each vertex independently into left/right with probability `1/2`.

For each edge `e=(u,v)`, define indicator `X_e=1` if edge crosses the cut.
$Pr[e " crosses"] = Pr[u " L, " v " R"]+Pr[u " R, " v " L"] = 1/4+1/4=1/2$, so $E[X_e]=1/2$.
Cut size `X=sum_e X_e`. If graph has `m` edges:
$E[X]=m/2$.
Since `OPT<=m`, randomized cut is expected `2`-approximation:
$E[ALG] = m/2 >= OPT/2$.

== Final Exam Writing

#smallcaps[Greedy.]
State objective/local rule/feasibility. Use stays-ahead, exchange, or structural proof. Give complexity.

#smallcaps[DP.]
Define state, recurrence, base cases, computation order, answer, complexity.

#smallcaps[Flow.]
Model nodes/edges/capacities. Explain integral flow if using matching/assignment. Correctness: feasible solution <-> flow.

#smallcaps[NP-complete.]
Membership in NP; known source problem; construction; iff proof; polynomial time.

#smallcaps[Amortized.]
Single bad operation if asked; aggregate count or potential. Check nonnegative initial potential.

#smallcaps[Random.]
Define indicators; compute individual probability; sum expectations. For failure probability, write exact bad event first, then bound.

#smallcaps[Approx.]
State ratio definition and prove inequality against `OPT`.

== Greedy Cases

#smallcaps[Interval scheduling.]
Goal: maximum number of non-overlapping intervals. Rule: sort by finish time, repeatedly choose interval with earliest finish compatible with previous choice.

Stays-ahead proof: let greedy intervals be `g_1,...` and optimal intervals be `o_1,...` sorted by finish time. Prove by induction `finish(g_i) <= finish(o_i)` for each `i`. Hence if optimal can schedule `k` intervals, greedy can also keep room for at least `k`.

#smallcaps[Minimize maximum lateness.]
Jobs with processing time `t_j`, deadline `d_j`. Completion `C_j`; lateness `L_j=max(0,C_j-d_j)`. Rule: earliest deadline first. Exchange adjacent inversion: if `d_i <= d_j` but `j` before `i`, swapping them does not increase max lateness. Repeated swaps transform any optimal schedule into EDF.

#smallcaps[MST.]
Cut property: for any cut, a lightest edge crossing the cut is safe for some MST. Cycle property: if an edge is strictly heaviest on a cycle, it is in no MST.

Kruskal: sort edges increasing; add if no cycle. Prim: grow connected component by lightest outgoing edge. Reverse-delete: sort decreasing; delete if graph stays connected.

#smallcaps[Clustering.]
For maximum spacing `k`-clustering, run Kruskal until exactly `k` connected components remain. Spacing is next edge connecting different components.

== DP Recurrences

#smallcaps[Weighted interval scheduling.]
Sort jobs by finish time. Let `p(j)` be last job before `j` compatible with `j`.
$OPT(j)=max(v_j+OPT(p(j)), OPT(j-1))$, with $OPT(0)=0$.
Choice: take job `j` or skip it. Precompute `p(j)` by binary search; time `O(n log n)`.

#smallcaps[0/1 knapsack.]
`OPT(i,w)` = max value using first `i` items within capacity `w`.
If $w_i>w$, $OPT(i, w)=OPT(i-1, w)$; otherwise $OPT(i, w)=max(OPT(i-1, w), v_i+OPT(i-1, w-w_i))$.
Time `O(nW)`, pseudo-polynomial.

#smallcaps[Sequence alignment.]
`OPT(i,j)` = min cost aligning prefixes `X[1..i]`, `Y[1..j]`.
$OPT(i, j)=min(OPT(i-1, j-1)+alpha(x_i, y_j), OPT(i-1, j)+delta, OPT(i, j-1)+delta)$.
Base `OPT(i,0)=i delta`, `OPT(0,j)=j delta`. Time `Theta(mn)`.

#smallcaps[RNA secondary structure.]
`OPT(i,j)` = max pairs in substring `i..j`.
$OPT(i, j)=max(OPT(i, j-1), max_t OPT(i, t-1)+1+OPT(t+1, j-1))$.
where `t` can legally pair with `j`. Time `O(n^3)`.

#smallcaps[Bellman-Ford DP.]
`OPT(i,v)` = shortest path from `v` to `t` using at most `i` edges.
$OPT(i, v)=min(OPT(i-1, v), min_{(v,w)} c(v,w)+OPT(i-1, w))$.
After `n-1` rounds shortest simple paths known. If round `n` improves, reachable negative cycle exists.

== Flow Applications

#smallcaps[Bipartite matching.]
Source to each left vertex cap 1; left-right edges cap 1; right vertices to sink cap 1. Integral max flow corresponds to matching. Perfect matching iff flow value equals left side size.

#smallcaps[Edge-disjoint paths.]
Set every edge capacity 1. Max number of edge-disjoint `s-t` paths equals max flow value.

#smallcaps[Circulation with demands.]
For edge lower bound `l_e <= f_e <= c_e`, send forced `l_e` first: residual capacity `c_e-l_e`, adjust vertex balances by lower bounds. Add super-source/sink for demands/supplies. Feasible iff all required super-source edges saturated.

#smallcaps[Project selection.]
Positive profit project: edge `s -> v` with capacity profit. Negative profit/cost: edge `v -> t` with capacity cost. If `v` requires `w`, add infinite edge `v -> w`. Min cut chooses closed set maximizing profit.

#smallcaps[Image segmentation.]
Pixel-source/sink edges encode label preference; neighboring-pixel edges encode separation penalty. Min cut gives best foreground/background labeling.

== NP Gadget Patterns

#smallcaps[Conflict graph.]
If two choices cannot coexist, make them adjacent and reduce to Independent Set or Coloring.

#smallcaps[Cover graph.]
If every demand must be touched by at least one chosen object, reduce from Vertex Cover or Set Cover.

#smallcaps[Variable-choice gadget.]
Force exactly one of `x` or `not x` by making choices mutually exclusive and setting total required size.

#smallcaps[Clause gadget.]
Force each clause to be satisfied: construction should become feasible iff at least one literal input is true. In 3-color, clause gadget forbids all three literal colors being `F`.

#smallcaps[Digit gadget.]
For numeric reductions to Subset Sum, each digit/column represents one constraint. Choose base large enough so no carry occurs; equality of numbers means every column constraint is met.

== More NP Reductions

#smallcaps[Independent Set to Vertex Cover.]
Input `(G,k)` -> `(G, |V|-k)`. If `S` independent, then every edge has at least one endpoint outside `S`, so `V-S` is a vertex cover. If `C` is vertex cover, no edge has both endpoints in `V-C`, so `V-C` is independent.

#smallcaps[Clique to Independent Set.]
Map graph `G` to complement `bar(G)`. A set is clique in `G` iff it is independent in `bar(G)`.

#smallcaps[3-SAT to 3-Color.]
Create triangle `T,F,B`. Literal vertices connect to `B`, so they use colors `T/F`. Connect `x` and `not x`. Clause gadget enforces not all three literals false.

#smallcaps[Dominating Set from Vertex Cover.]
For each edge `e={u,v}`, add new vertex `x_e` adjacent to `u,v`. A vertex cover dominates all edge vertices; any dominating set can replace `x_e` by an endpoint; then each `x_e` forces one endpoint selected, giving vertex cover.

== PSPACE Snapshot

`PSPACE`: decision problems solvable using polynomial space. `P subset NP subset PSPACE`.

QSAT has alternating quantifiers:
$exists x_1 forall x_2 exists x_3 ... Phi$.
Recursive evaluation uses exponential time but polynomial stack space.

Game/planning signal: "first player has winning strategy", "for all opponent responses", "configuration graph exponentially large". Show membership by DFS over states/strategy tree storing only current state and recursion depth. Show hardness by reducing from QSAT, mapping `exists/forall` choices to players.

== FPT Details

#smallcaps[Why FPT.]
For NP-complete problems, usually cannot have all three: polynomial time, optimality, arbitrary inputs. FPT keeps optimality but assumes small parameter.

#smallcaps[Vertex Cover brute force.]
Try all size-`k` subsets:
$binom(n, k) dot O(k n) approx O(k n^(k+1))$.
Not practical for `n=1000,k=10`.

#smallcaps[Branch algorithm.]
Pick edge `(u,v)`. Branch on selecting `u` or selecting `v`; decrease `k`.
$T(k) <= 2T(k-1)+poly(n) = O(2^k poly(n))$.
Correct because every cover must cover edge `(u,v)`.

#smallcaps[High-degree rule.]
If degree of `v` is greater than `k`, then every size-`k` cover must include `v`; otherwise all its neighbors must be selected, exceeding budget.

== Local Search Details

#smallcaps[Generic termination.]
If every move strictly improves an integer objective bounded by polynomial/exponential range and state space finite, algorithm terminates. But termination need not be polynomial unless improvement size or number of states is bounded.

#smallcaps[Max-Cut weighted.]
For weighted graph, same proof uses weights:
$"cross weight"(v) >= "same-side weight"(v)$.
Sum over vertices; each edge counted twice on one side of inequality. Get `cut >= total_weight/2 >= OPT/2`.

#smallcaps[Best response.]
Best response dynamics may cycle if no potential exists. In fair cost sharing, Rosenthal potential is an exact potential, so every selfish improvement decreases the same global function.

== Amortized Templates

#smallcaps[Stack multipop.]
Each item pushed once and popped at most once. Aggregate total `O(m)`. Potential `Phi=|S|`: push actual 1, `Delta Phi=1`; pop/multipop actual `k`, `Delta Phi=-k`.

#smallcaps[Binary counter.]
Increment flips `t` trailing 1s to 0 and one 0 to 1. Actual `t+1`. Potential `Phi=#1 bits`; `Delta Phi <= 1-t`; amortized `<=2`.

#smallcaps[Dynamic table.]
Doubling table: expansions copy sizes `1,2,4,...`, total copy cost `O(n)` over `n` inserts. Potential can be `Phi=2*num-size` when load at least 1/2.

#smallcaps[Fibonacci heap facts.]
Potential:
$Phi = #"trees" + 2 #"marked nodes"$.
Amortized: insert/find-min/union/decrease-key `O(1)`, delete-min/delete `O(log n)`. Marked nodes pay for cascading cuts.

== HW4 Full Protocols

#smallcaps[P1 queue.]
Worst-case one call: duplicates become stale after first write; next flush discards many. Sequence bound: inserted entries <= modifies; deleted entries <= inserted entries. Potential `3|Q|`.

#smallcaps[P2 calibration.]
Need exact `q` formula if asked; otherwise use `T_q<=n`. Accounting charge 2 per insertion is simplest.

#smallcaps[P3 tombstones.]
The key inequality is:
$D>L ==> D+2L < 3D$.
This is the whole reason `Phi=3D` works.

#smallcaps[P4 audit.]
Expectation by indicators over bad submissions; exact failure probability by choosing all samples from clean submissions; exponential bound via `(1-x)^s<=e^{-xs}`.

#smallcaps[P5 priority.]
Closed neighborhood size `deg(v)+1`; iid continuous priorities imply unique minimum with probability 1.

== Random Analysis Patterns

#smallcaps[Max-Cut.]
Object = edge. Indicator = edge crosses. Probability = 1/2. Sum over edges.

#smallcaps[MAX-3SAT.]
Object = clause. Random assignment. A 3-literal clause is unsatisfied with prob `1/8`, satisfied with prob `7/8`. Expected satisfied clauses `7m/8`.

#smallcaps[Randomized quicksort.]
Object = pair `(i,j)`. Pair compared iff first pivot among `z_i,...,z_j` is one endpoint.
$Pr["compare " i,j]=2/(j-i+1)$, and $E["comparisons"]=sum_{i<j} 2/(j-i+1)=O(n log n)$.

#smallcaps[Karger min-cut.]
Fix min cut of size `k`. At `n'` supernodes, min degree at least `k`, so edges `>=kn'/2`; probability of contracting cut edge `<=2/n'`. Survival probability:
$prod_{i=n " down to " 3} (1-2/i)=2/(n(n-1))$.
Repeat `O(n^2 log(1/delta))` times for failure `<=delta`.

== Probability Quick Facts

#smallcaps[Independence.]
`A,B` independent iff `Pr[A and B]=Pr[A]Pr[B]`. Non-independent example: first die roll is 2 and two rolls sum to 5.

#smallcaps[Birthday pairs.]
`k` people, `n` days. Indicator `X_ij=1` if pair same birthday. `E[X_ij]=1/n`. Total expected matching pairs:
$E[X]=binom(k, 2)/n = k(k-1)/(2n)$.
Threshold for expected one collision: `k approx sqrt(2n)`.

#smallcaps[Coupon collector.]
When `i` coupon types collected, probability next coupon is new is `(n-i)/n`; expected wait `n/(n-i)`. Total:
$n(1/n+1/(n-1)+...+1)=Theta(n log n)$.

== Tail Bound Use

#smallcaps[Markov.]
Use when only know expectation and variable nonnegative. Example: `Pr[X>=2E[X]]<=1/2`.

#smallcaps[Chebyshev.]
Use when variance known. For `a>0`, deviation by at least `a` has probability at most `Var[X]/a^2`.

#smallcaps[Chernoff.]
Use for independent indicator sum. To make upper-tail probability `<=epsilon`, ensure:
$mu delta^2/3 >= ln(1/epsilon)$.
for `0<=delta<=1`.

#smallcaps[Union bound.]
For all machines/processes/vertices:
$Pr["any bad"] <= sum Pr["one fixed bad"]$.
No independence needed.

== More Approximation

#smallcaps[Random Max-Cut.]
Expected guarantee only:
$E[ALG] >= OPT/2$.
One run can be worse; average over random choices is good.

#smallcaps[Local-search Max-Cut.]
Deterministic local optimum gives actual `2`-approx, not just expectation.

#smallcaps[Set cover tight proof shape.]
Always define charges so total charge equals algorithm cost. Then bound each element's charge by `OPT / (# uncovered at that moment)`.

#smallcaps[Scheduling tight example.]
Many small jobs first, one big job last makes list scheduling approach ratio 2. LPT avoids this by sorting long jobs first.

== Common Syntax For Proofs

NP membership:
```
Certificate: ...
Verifier: check ... in polynomial time.
```

Reduction:
```
Given instance x of known NP-complete B,
construct f(x) as follows...
The construction is polynomial.
(=>) ...
(<=) ...
```

Amortized:
```
Let Phi=...
Initially Phi=0 and Phi>=0 always.
For operation A: actual ..., Delta Phi ..., amortized ...
For operation B: ...
```

Random expectation:
```
Let X_i be indicator of event E_i.
Then X=sum_i X_i.
E[X_i]=Pr[E_i].
By linearity, E[X]=sum_i E[X_i].
```

Approximation:
```
Let OPT be optimal value.
We prove ALG <= alpha OPT   (min)
or ALG >= OPT/alpha         (max).
```

== Midterm Algorithms Mini-Pack

#smallcaps[Closest pair.]
Sort points by `x` and `y`. Split by median `x`. Recursively solve left and right; let `delta` be smaller distance. Only cross pairs inside vertical strip of width `2delta` can improve. In strip sorted by `y`, compare each point with constant number of following points. Keep sorted lists through recursion for `O(n log n)`.

#smallcaps[FFT / polynomial multiply.]
Coefficient form good for addition; point-value form good for multiplication. Evaluate both polynomials at roots of unity by FFT, multiply values pointwise, inverse FFT to recover coefficients. Recurrence uses:
$A(x)=A_"even"(x^2)+x A_"odd"(x^2)$.
Time `O(n log n)`.

#smallcaps[Grid local minimum.]
Query middle row/column, choose minimum boundary cell `m`, recurse into quadrant containing smaller seed. Recurrence:
$T(n)=T(n/2)+O(n)=O(n)$.
Correctness: recursive local minimum with value no larger than boundary min cannot have smaller neighbor across boundary.

#smallcaps[Linked-list mergesort.]
Split by slow/fast pointers; recursively sort halves; merge by pointer rewiring. Time `O(n log n)`, stack `O(log n)`.

== More DP Mini-Pack

#smallcaps[Maximum-sum increasing subsequence.]
`dp[i]` = max sum of increasing subsequence ending at `i`.
$"dp"[i]=max(a[i], max_(j<i, a[j]<a[i]) "dp"[j]+a[i])$, answer $max_i "dp"[i]$.
Time `O(n^2)`.

#smallcaps[Grouped knapsack.]
Groups, at most one item per group. `dp[i][w]` = max value using first `i` groups under capacity `w`.
$"dp"[i][w]=max("dp"[i-1][w], max_("item " (c,v) " in group " i, c<=w) "dp"[i-1][w-c]+v)$.
Time `O(WK)` where `K` total items.

#smallcaps[Interval painting / strange printer.]
`f[i][j]` = min operations to paint substring `s[i..j]`.
$f[i][i]=1$. If $s[i]==s[j]$, then $f[i][j]=f[i][j-1]$; otherwise $f[i][j]=min_(i<=k<j) f[i][k]+f[k+1][j]$.
Time `O(n^3)`.

== More Flow Models

#smallcaps[Course registration.]
Source -> student `i` capacity `k_i`; eligible pair student `i` -> course `j` capacity 1; course `j` -> sink capacity `c_j`. Integral max flow gives assignments.

#smallcaps[Scheduling by days/events.]
For feasibility in `D` days, source -> weekday `d` capacity `cnt[d]*e`; weekday -> event if available; event -> sink capacity requirement `c_i`. Feasible iff max flow equals total demand. Binary search smallest `D` because feasibility monotone.

#smallcaps[Baseball elimination.]
Assume team `z` wins all remaining. Source -> game nodes for remaining games among other teams; game -> two teams; team -> sink capacity max allowed wins before exceeding `z`. If all game capacities saturated, not eliminated. Min cut gives certificate.

== NP Problem Library

#smallcaps[Monotone 3-SAT.]
All literals in each clause same sign. From 3-SAT: mixed `(x or y or not z)` becomes
$ (x or y or u) and (not u or not z or not z) $;
mixed `(x or not y or not z)` becomes
$ (x or u or u) and (not u or not y or not z) $.
Fresh `u` preserves satisfiability.

#smallcaps[Two-bin from Subset Sum.]
Given numbers `a_i`, target `T`, total `A`. Make item sizes `a_i`; capacities:
$B_1=T$, $B_2=A-T$.
Feasible partition iff some subset sums to `T`.

#smallcaps[Grid pieces from Monotone 3-SAT.]
Rows = clauses, columns = variables. Positive clause puts black pieces in variable columns; negative clause puts white. Assignment keeps black columns for true variables and white columns for false variables. Column single-color corresponds to consistency; nonempty row corresponds to satisfied clause.

== Extra Probability Examples

#smallcaps[Contention resolution.]
`n` processes, each transmits with probability `p=1/n`. Fixed process succeeds in a round if it transmits and all others do not:
$Pr["success"] = p(1-p)^(n-1) = (1/n)(1-1/n)^(n-1)$, between $1/(e n)$ and $1/(2n)$.
Failure for fixed process after `t` rounds:
$<= (1-1/(e n))^t$.
With `t=en*c ln n`, failure `<=n^(-c)`. Union bound over `n` processes.

#smallcaps[Random load balancing.]
`m` jobs to `n` machines uniformly. Fixed machine load:
$X_i=sum_{j=1}^m Y_(i j)$, $E[X_i]=m/n$.
Chernoff for one machine, union bound for max load across all machines.

== Approx / Random Distinctions

#smallcaps[Deterministic approximation.]
Every run/input satisfies ratio, e.g. list scheduling output `M<=2M*`.

#smallcaps[Expected approximation.]
Only expectation over random choices satisfies ratio, e.g. random Max-Cut `E[ALG]>=OPT/2`.

#smallcaps[Monte Carlo vs Las Vegas.]
Las Vegas always correct but runtime random, e.g. restart until success with geometric expectation. Monte Carlo runtime bounded but output can be wrong or below target with some probability.

== Exam Failure Modes

Reduction direction: to prove `A` hard, reduce known hard `B` to `A`, not `A` to `B`.

Decision vs optimization: NP-complete statements are about yes/no versions. State threshold `k,D,B` explicitly.

Pseudo-polynomial: `O(nW)` is not polynomial in input length if `W` is binary encoded.

Expected value: `E[ALG]>=OPT/2` does not mean every run is `2`-approx.

Linearity: does not require independence. Chernoff does require independent indicator sum.

Potential: must be nonnegative and initially zero or account for initial/final difference.

Set cover: overlapping coverage is allowed; this is not exact cover.

Vertex cover vs independent set: cover chooses points touching every edge; independent set chooses points containing no edge.

== Compact Formula Box

$sum_{i=1}^n i = n(n+1)/2$; $H_n = 1+1/2+...+1/n <= 1+ln n$; $(1-x) <= e^(-x)$; $binom(k, 2)=k(k-1)/2$; Geometric$(p)$: $E[R]=1/p$; Master baseline: $n^(log_b a)$.

$"Max-flow" = "min-cut"$; no augmenting path $<==>$ max flow; integral capacities imply integral max flow.

Markov: $Pr[X>=a] <= E[X]/a$. Chebyshev: $Pr[|X-E[X]|>=a] <= Var[X]/a^2$. Chernoff upper: $Pr[X>=(1+d)mu] <= e^(-mu d^2/3)$. Union: $Pr[union_i E_i] <= sum_i Pr[E_i]$.
