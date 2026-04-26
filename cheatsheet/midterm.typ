#import "../../../../typst-template/cheatsheet/lib.typ": *

#show: doc => cheatsheet(
  title: "CS240 Midterm Cheatsheet",
  authors: ((name: "0x1B05"),),
  date: datetime(year: 2026, month: 4, day: 26),
  columns-count: 3,
  font-size: 7pt,
  doc,
)

#set text(lang: "zh")

= Side A: Design Patterns

== Asymptotic Notation

`O(f)`: upper bound. `T(n) <= c f(n)` for large $n$.  
`Omega(f)`: lower bound. `T(n) >= c f(n)`.  
`Theta(f)`: both.  
Usual order: `1 < log n < n < n log n < n^2 < n^3 < 2^n < n!`.

Facts: constants/low terms drop; `log_a n = Theta(log_b n)`; for positive sums, largest term usually dominates.  
Polynomial time means `n^c`, not `2^n` or `n!`. Pseudopolynomial: depends on numeric value, e.g. `O(nW)`, not input length `log W`.

== Greedy: What To Prove

Greedy is safe only if the local rule matches the objective.

Exam proof skeleton:
1. State local rule.
2. State feasibility test.
3. Prove local choice is safe.
4. Reduce to remaining subproblem.
5. Give running time.

Proof templates:
- #bluet[Stays ahead]: compare greedy prefix with any optimal prefix.
- #bluet[Exchange]: modify an optimal solution to include greedy choice, no worse.
- #bluet[Structural]: use cut/cycle/MST property or a bound every solution obeys.

Common failure mode: giving intuition without explaining why an optimal solution can be changed to agree with greedy.

== Greedy Cases

=== Interval Scheduling
Goal: max number of compatible intervals.  
Rule: sort by finish time; take first compatible.  
Proof: exchange first interval of an optimal solution with earliest-finishing compatible interval; leaves at least as much room.

Wrong rules: earliest start, shortest interval, fewest conflicts.

=== Minimizing Maximum Lateness
Jobs have processing time $t_j$, deadline $d_j$. Completion $C_j$; lateness `L_j=max(0,C_j-d_j)`. Goal: minimize `max_j L_j`.  
Rule: earliest deadline first.

Proof idea: remove adjacent inversions. If $d_i <= d_j$ but `j` before `i`, swap them; max lateness does not increase. Repeating gives EDF.

=== Single-Link k-Clustering
Goal: partition into $k$ clusters maximizing spacing.  
Algorithm: Kruskal, stop when exactly $k$ components remain. Equivalent: MST then delete largest $k-1$ edges.

=== Offline Caching
Cache size $k$, known request sequence. On miss, evict item requested farthest in future.  
Proof: exchange schedule to agree with farthest-in-future one request at a time.

== MST Facts

Cut property: for any cut, the lightest edge crossing the cut is safe for some MST.  
Cycle property: in any cycle, the heaviest edge is in no MST if strictly heavier than all other cycle edges.

Kruskal: sort edges, add if connects two components.  
Prim: grow one component, add lightest crossing edge.  
Reverse-delete: sort descending, delete edge if graph stays connected.

== Divide And Conquer

Pattern:
1. Split into independent subproblems.
2. Recursively solve.
3. Combine cheaply.

Typical recurrence: $T(n) = a T(n / b) + f(n)$.

Master theorem baseline: $n^(log_b a)$.
- If $f(n)$ smaller: $T = Theta(n^(log_b a))$.
- If same up to log factors: balanced.
- If $f(n)$ larger and regular: $T = Theta(f(n))$.

Common examples:
- Mergesort: $2T(n/2)+O(n)=O(n log n)$.
- Karatsuba: $3T(n/2)+O(n)=O(n^1.585)$.
- Strassen: $7T(n/2)+O(n^2)=O(n^2.807)$.

== Closest Pair

Sort points by $x$ and $y$. Split by median $x$. Recursively solve left/right, let $delta$ be min. Only cross pairs inside strip width $2 delta$ can improve. In strip sorted by $y$, compare each point with constant number of following points.  
Time: $O(n log n)$ if sorted lists maintained; re-sorting inside recursion breaks this.

== FFT / Polynomial Multiplication

Coefficient form: natural for addition.  
Point-value form: multiplication is pointwise.  
FFT evaluates at roots of unity fast using
$A(x)=A_e(x^2)+x A_o(x^2)$.

Pipeline: coefficients -> FFT values -> pointwise multiply -> inverse FFT.  
Time: $O(n log n)$.

== Dynamic Programming

Use DP when subproblems overlap and optimal solution uses optimal subsolutions.

Writing checklist:
1. Define `OPT(...)` precisely.
2. Identify the last decision / split.
3. Write recurrence and base cases.
4. Specify evaluation order.
5. Give time/space and reconstruction if needed.

DP is not just a formula: the state definition is the solution.

== Weighted Interval Scheduling

Sort by finish time. `p(j)` = rightmost job compatible with `j`.

`OPT(j)=max(v_j + OPT(p(j)), OPT(j-1))`.

Base: `OPT(0)=0`.  
Reconstruct by checking which branch wins.  
Time: `O(n log n)` with binary search for all `p(j)`.

== 0/1 Knapsack

State: `OPT(i, w)` = max value using first `i` items under capacity `w`.

`OPT(i,w)=OPT(i-1,w)` if $w_i>w$.

Otherwise:
`OPT(i,w)=max(OPT(i-1,w), v_i+OPT(i-1,w-w_i))`.

Time/space: `O(nW)`. This is pseudopolynomial.

== RNA Secondary Structure

State: `OPT(i, j)` max pairs in substring $i..j$.  
Cases for $j$:
- unpaired: `OPT(i, j-1)`;
- paired with `t`: `OPT(i, t-1)+1+OPT(t+1, j-1)`, if compatible and no sharp turn.

Take max over valid `t`.  
Usually `O(n^3)` time, `O(n^2)` space.

== Sequence Alignment

State: `OPT(i,j)` min cost aligning prefixes $X_1..X_i$, $Y_1..Y_j$.

```text
OPT(i,j)=min(
  OPT(i-1,j-1)+alpha(x_i,y_j),
  OPT(i-1,j)+delta,
  OPT(i,j-1)+delta
)
```

Base: `OPT(i,0)=i delta`, `OPT(0,j)=j delta`.  
Time/space: `Theta(mn)`.

Linear-space alignment: compute forward/backward costs through middle column, split at best crossing, recurse. Time `O(mn)`, space `O(m+n)`.

== Bellman-Ford

Allows negative edges, not reachable negative cycles.

State version: `OPT(i,v)` = shortest path from `v` to `t` using at most `i` edges.

`OPT(i,v)=min(OPT(i-1,v), min_{(v,w) in E} c(v,w)+OPT(i-1,w))`.

After `n-1` rounds, shortest simple path settled if no negative cycle.  
Negative cycle test: if round `n` still improves, reachable negative cycle exists.

Arbitrage: product of exchange rates $>1$ becomes negative cycle using weights $-log r$.

= Side B: Flow And Complexity

== Flow Basics

Network: directed graph, source $s$, sink $t$, capacity $c(e)>=0$.  
Flow constraints:
- capacity: `0 <= f(e) <= c(e)`;
- conservation: for $v != s,t$, inflow = outflow.

Flow value $v(f)$ = net flow out of $s$ = net flow into $t$.

Residual graph:
- forward residual capacity: `c(e)-f(e)`;
- backward residual capacity: `f(e)`.

Augmenting path = $s$-$t$ path in residual graph. Bottleneck = min residual capacity.

== Ford-Fulkerson

Algorithm:
1. Start with zero flow.
2. Find augmenting path in residual graph.
3. Push bottleneck flow.
4. Stop when no augmenting path.

Correctness comes from max-flow/min-cut, not from arbitrary greediness.

Integral capacities -> there exists integral max flow. With integer capacities, FF augmentations preserve integrality.

Naive FF can depend on capacity value. Capacity scaling improves to about `O(m^2 log C)`.

== Cuts

$s$-$t$ cut: partition `(A,B)` with $s in A$, $t in B$.  
Capacity: sum of capacities of edges from `A` to `B`.

Weak duality: for any flow and cut, `v(f) <= cap(A,B)`.

Max-flow min-cut theorem:
`max flow value = min cut capacity`.

Equivalent conditions:
1. Some cut has `v(f)=cap(A,B)`.
2. `f` is max flow.
3. Residual graph has no augmenting path.

No augmenting path proof: let `A` be vertices reachable from `s` in residual graph. Then `t notin A`; forward edges from `A` to `B` are saturated, backward edges carry no cancelable flow, so flow value equals cut capacity.

== Flow Applications

=== Bipartite Matching
Source -> left vertices cap 1. Left -> right edges cap 1. Right -> sink cap 1.  
Integral max flow corresponds to matching.

Perfect matching: flow value equals left side size.

Hall condition: perfect matching iff for every left subset $S$, `|N(S)| >= |S|`.

=== Edge-Disjoint Paths
Set every edge capacity 1. Max flow value = maximum number of edge-disjoint $s$-$t$ paths.

=== Circulation With Demands
Supplies and demands instead of one source/sink. Add super-source to supplies, demands to super-sink; feasible iff all required edges saturated.

Lower bounds: for edge $(u,v)$ with `l <= f <= c`, set residual capacity `c-l`; account for forced `l` by adjusting node balances.

=== Project Selection
Positive profit project: source -> project cap profit.  
Negative profit/cost: project -> sink cap cost.  
Prerequisite `v needs w`: edge `v -> w` with infinite capacity.  
Min cut chooses closed set maximizing profit.

== Image Segmentation / Baseball

Image segmentation:
- source/sink = foreground/background;
- pixel source/sink edges = label preference;
- neighboring pixel edges = separation penalty;
- min cut = best labeling.

Baseball elimination:
- assume team `z` wins all remaining games;
- game nodes distribute remaining wins among other teams;
- team -> sink cap = wins allowed before exceeding `z`;
- all source edges saturated iff `z` not eliminated.

Min cut can give certificate: subset of teams whose unavoidable wins already beat `z`.

== NP Language

Decision problem: yes/no instances.

`P`: solvable in polynomial time.  
`NP`: yes instances have polynomial-size certificate verifiable in polynomial time.  
`co-NP`: complements of NP problems.

`P subset.eq NP subset.eq EXP`. Also `P subset.eq NP intersection co-NP`.

NP does #redt[not] mean non-polynomial. It means nondeterministic polynomial time / efficiently verifiable.

Examples:
- SAT certificate: assignment.
- Hamiltonian cycle certificate: vertex order.
- Composite certificate: nontrivial factor.

`P ?= NP`: is finding as easy as checking?

== Reductions

`X <=_p Y` means: if you can solve `Y`, you can solve `X`. So `Y` is at least as hard as `X`.

To prove `Y` hard, reduce known hard `X` to `Y`.

Karp transformation: construct `y` from `x` in poly-time such that `x yes iff y yes`.

Transitivity: if `X <=_p Y` and `Y <=_p Z`, then `X <=_p Z`.

Common proof obligations:
1. Construction polynomial size/time.
2. Forward direction: solution of old instance -> solution of new.
3. Backward direction: solution of new -> solution of old.

== NP-Complete / NP-Hard

`Y` is NP-complete iff:
1. `Y in NP`;
2. every `X in NP` reduces to `Y`.

Recipe:
1. Show `Y in NP` via certificate/verifier.
2. Pick known NP-complete `X`.
3. Prove `X <=_p Y`.

NP-hard: every NP problem reduces to it; may not be in NP or even be decision.

If any NP-complete problem is in `P`, then `P=NP`.

== Canonical Reductions

=== Vertex Cover <-> Independent Set
`S` independent iff `V-S` is vertex cover.  
Independent set size `>= k` iff vertex cover size `<= n-k`.

=== Vertex Cover -> Set Cover
Universe `U=E`. For vertex `v`, set `S_v = incident edges`. Cover all edges with `k` sets iff vertex cover size `k`.

=== 3-SAT -> Independent Set
For each clause, make triangle of its literals. Connect contradictory literals across clauses. Need independent set size = number of clauses. One selected literal per clause, no contradictions.

=== HAM-CYCLE -> TSP
Cities = vertices. Distance 1 if graph edge, 2 otherwise. Threshold `D=n`. Tour length `<= n` iff Hamiltonian cycle.

=== Circuit-SAT -> 3-SAT
Variable for every gate/wire. Add constant number of clauses per gate to enforce truth table. Force output true. Satisfying assignment iff circuit can output 1.

== 3-COLOR Sketch

Use three special colors `T, F, B` fixed by a triangle. Literal vertices connect to `B`, so each is `T` or `F`. Connect `x` with `not x` so they are opposite. Clause gadget forbids all three literals being `F`. Thus colorable iff formula satisfiable.

== co-NP And Good Characterizations

Complement flips yes/no.  
SAT in NP; UNSAT in co-NP.  
TAUTOLOGY: formula true under all assignments; `phi UNSAT iff not phi TAUTOLOGY`.

Good characterization: problem in `NP intersection co-NP`; yes and no both have short certificates.

Bipartite perfect matching:
- yes certificate: matching;
- no certificate: Hall violation `|N(S)| < |S|`.

Factoring is in `NP intersection co-NP`, not known in `P`. Primality is in `P`.

== Exam Proof Checklist

Greedy proof: state objective, local rule, feasibility, exchange/stays-ahead/structural proof, complexity.

DP proof: define state precisely; recurrence; base cases; order; complexity; reconstruction if asked.

Flow model: identify what units of flow represent, why capacities encode constraints, why integral flow gives discrete solution.

Reduction proof: direction matters. To prove target hard, reduce from known hard problem to target.

When stuck:
- Is it selecting compatible objects? Try greedy/DP/flow/independent set.
- Is it covering constraints? Try vertex cover/set cover/flow cut.
- Is it assigning truth values? Try SAT/3-SAT gadget.
- Is it path/tour over all vertices? Try Hamiltonian/TSP.
