#import "@local/cheatsheet:0.1.0": *

#show: doc => cheatsheet(
  title: "CS240 Final Cheatsheet",
  authors: ((name: "0x1B05"),),
  date: datetime(year: 2026, month: 6, day: 15),
  columns-count: 5,
  font-size: 7pt,
  doc,
)

#set text(lang: "zh")
#let Pr = math.op("Pr")
#let E = math.op("E")
#let Var = math.op("Var")
#let OPT = math.op("OPT")
#let poly = math.op("poly")
#let cost = math.op("cost")

#let reducesto = math.attach($<=$, br: $p$)

- uppper bound:$O()$
- lower bound:$Omega()$
- tight bound:$Theta()$

```
constant < log n < n < n log n < n^a < n^(log n) < 2^n / poly(n) < a^(b^n)
```

3-SAT $reducesto$ Independent Set $reducesto$ Vertex Cover $reducesto$ Set Cover。

== Greedy: What To Prove

Proof templates:
- #bluet[Stays ahead]: compare greedy prefix with any optimal prefix.
  ```
  Claim: For every k, after k greedy choices, greedy is at least as good as any solution after k choices.
  Base: k = 1 时成立。
  Induction: 假设 k 成立，证明 k + 1 也成立。
  Conclusion: Since greedy never falls behind, if any solution can achieve the goal in k steps, greedy can also achieve it in k steps. Therefore greedy is optimal.
  ```
- #bluet[Exchange]: modify an optimal solution to include greedy choice, no worse.(一个区间, 一条边, 一个任务, 一个课程, 一个集合中的元素)
  ```
  Let OPT be an optimal solution.If OPT already contains the greedy choice, continue. Otherwise, modify OPT: remove some choice from OPT, add the greedy choice.
  Show:
  1. the modified solution is still feasible;
  2. the modified solution has value no worse than OPT.
  Therefore, there exists an optimal solution containing the greedy choice. Then solve the remaining subproblem recursively.
  ```
- #bluet[Structural]: use cut/cycle/MST property or a bound every solution obeys.

== Greedy Cases

=== Minimizing Maximum Lateness
Jobs have processing time $t_j$, deadline $d_j$. Completion $C_j$; lateness `L_j=max(0,C_j-d_j)`. Goal: minimize `max_j L_j`.
Rule: earliest deadline first.

Proof idea: remove adjacent inversions. If $d_i <= d_j$ but `j` before `i`, swap them; max lateness does not increase. Repeating gives EDF.

=== Offline Caching
Proof: exchange schedule to agree with farthest-in-future one request at a time.

== MST Facts

Cut property：任意一个 cut 上，跨过这个 cut 的最轻边是安全边，存在某棵 MST 包含它。(For any cut, the lightest edge crossing the cut is safe, i.e. it belongs to some MST.)
Cycle property：任意一个环中，如果某条边严格重于环上其他所有边，那么它不可能出现在任何 MST 中。(In any cycle, if an edge is strictly heavier than all other edges in the cycle, then it belongs to no MST.)

Kruskal：边从小到大；不成环就加 Prim：维护一个连通块；每次加最轻出边 Reverse-delete：边从大到小；删了仍连通就删 k-clustering with maximum spacing: *Kruskal 跑到还剩 $k$ 个连通分量时停下*

== Divide And Conquer

Typical recurrence: $T(n) = a T(n / b) + f(n)$.Master theorem baseline: $n^(log_b a)$.
- If $f(n)$ smaller: $T = Theta(n^(log_b a))$.
- If same up to log factors: balanced.
- If $f(n)$ larger and regular: $T = Theta(f(n))$.

== Closest Pair

Sort points by $x$ and $y$. Split by median $x$. Recursively solve left/right, let $delta$ be min. Only cross pairs inside strip width $2 delta$ can improve. In strip sorted by $y$, compare each point with constant number of following points. Time: $O(n log n)$ if sorted lists maintained; re-sorting inside recursion breaks this.

== FFT / Polynomial Multiplication

*系数表示*，加法方便；*点值表示*下，多项式相乘很方便。
(Coefficient form: addition is easy. Point-value form: multiplication is easy, since it is pointwise.)
FFT evaluates at roots of unity fast using $A(x)=A_e(x^2)+x A_o(x^2)$.Pipeline: coefficients -> FFT values -> pointwise multiply -> inverse FFT. Time: $O(n log n)$.

== Dynamic Programming

== Weighted Interval Scheduling

按结束时间排序。`p(j)` = `j` 前最靠右且兼容的任务。`OPT(j)=max(v_j + OPT(p(j)), OPT(j-1))`. 选 `j` / 不选 `j`。Base: `OPT(0)=0`。 恢复方案：看哪一支胜出。二分预处理 `p(j)`，时间 `O(n log n)`。

== 0/1 Knapsack

`OPT(i,w)` = 前 `i` 个物品、容量 `w` 的最大价值。

若 $w_i>w$：`OPT(i,w)=OPT(i-1,w)`。否则：`OPT(i,w)=max(OPT(i-1,w), v_i+OPT(i-1,w-w_i))`。

本质是选 / 不选第 `i` 个。时间 `O(nW)`，伪多项式。

== RNA Secondary Structure

`OPT(i,j)` = 子串 `i..j` 最大配对数。

看 `j`：
- 不配：`OPT(i,j-1)`；
- 与合法 `t` 配：`OPT(i,t-1)+1+OPT(t+1,j-1)`。

对所有合法 `t` 取 max。时间 `O(n^3)`，空间 `O(n^2)`。

== Sequence Alignment

`OPT(i,j)` = `X` 前 `i` 个和 `Y` 前 `j` 个的最小对齐代价。

`OPT(i,j)=min( OPT(i-1,j-1)+alpha(x_i,y_j), OPT(i-1,j)+delta, OPT(i,j-1)+delta)`

三种情况：`x_i/y_j` 对齐，`x_i/gap`，`gap/y_j`。

Base: `OPT(i,0)=i delta`, `OPT(0,j)=j delta`。时间/空间 `Theta(mn)`。

线性空间：算 middle column 的 forward/backward cost，找最优切分点递归。时间 `O(mn)`，空间 `O(m+n)`。

== Bellman-Ford

允许负边，但不允许可达负环。DP 视角：`OPT(i,v)` = 从 `v` 到 `t`，最多用 `i` 条边的最短路。

`OPT(i,v)=min(OPT(i-1,v), min_{(v,w) in E} c(v,w)+OPT(i-1,w))`.

含义：不用第 `i` 条边，或先走 `v->w` 再接最多 `i-1` 条边。

`n-1` 轮后最短简单路确定。第 `n` 轮还能变小 => 有可达负环。

套利：汇率乘积 $>1$，用边权 $-log r$ 变成负环检测。

== Flow Basics

Flow value $v(f)$ = net flow out of $s$ = net flow into $t$.

Augmenting path = $s$-$t$ path in residual graph. Bottleneck = min residual capacity.

== Ford-Fulkerson

Correctness comes from max-flow/min-cut, not from arbitrary greediness.

Integral capacities -> there exists integral max flow. With integer capacities, FF augmentations preserve integrality.

Naive FF can depend on capacity value. Capacity scaling improves to about `O(m^2 log C)`.

== Cuts

$s$-$t$ cut: partition `(A,B)` with $s in A$, $t in B$.
Capacity: sum of capacities of edges from `A` to `B`.

Weak duality: for any flow and cut, `v(f) <= cap(A,B)`.

Max-flow min-cut theorem: `max flow value = min cut capacity`. Equivalent conditions:
1. Some cut has `v(f)=cap(A,B)`. 2. `f` is max flow. 3. Residual graph has no augmenting path.

No augmenting path proof: let `A` be vertices reachable from `s` in residual graph. Then `t notin A`; forward edges from `A` to `B` are saturated, backward edges carry no cancelable flow, so flow value equals cut capacity.

== Flow Applications

=== Bipartite Matching
Source -> left vertices cap 1. Left -> right edges cap 1. Right -> sink cap 1. Integral max flow corresponds to matching.

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

- P：能在多项式时间内直接解出来的问题。
- NP：如果别人给你一个答案，你能在多项式时间内检查它对不对的问题。
- NP-hard：至少和所有 NP 问题一样难的问题。B 是 NP-hard, 对所有 A in NP，都有 A <=p B。
- NP-complete：既在 NP 里面，又是 NP-hard 的问题。

P ⊆ NP, NP-complete = NP ∩ NP-hard, NP-hard 不一定属于 NP

常见 NP-complete decision problems：SAT, 3-SAT, Clique, Vertex Cover, Independent Set, Hamiltonian Cycle, Hamiltonian Path, Subset Sum, Partition, 3-Dimensional Matching, Set Cover, TSP decision version, Graph Coloring decision version, e.g. k-coloring for k >= 3

常见 P 问题：2-SAT, Bipartite Matching, Maximum Flow, Minimum Spanning Tree, Shortest Path, Eulerian Cycle, Topological Sort, Testing if graph is bipartite, 2-coloring

== DP 尝试思路

常见尝试：
- 从左往右：`f(i)` 表示处理 `i..end`，每次决定当前位置怎么用。例：票价、解码。
- 以某位置结尾：`dp[i]` 表示必须以 `i` 结尾的最优值。例：最长有效括号、递增子序列。
- 前缀匹配：`dp[i][j]` 表示 `s1` 前 `i` 个和 `s2` 前 `j` 个。例：LCS、编辑距离、不同子序列。
- 区间范围：`dp[l][r]` 表示子串/区间 `l..r` 的答案。例：回文子序列、涂色、RNA。
- 背包选择：`dp[i][w]` 表示前 `i` 个物品、容量 `w`。多限制就加维度，如 `dp[i][zero][one]`。
- 网格路径：`dp[i][j]` 表示到达或从 `(i,j)` 出发的答案；若有余数/步数，再加一维。
- 树形/分裂：枚举左边规模、右边规模或切分点。例：二叉树结构数、区间 split。

== NP-complete 证明模板

Problem $A$ is NP-complete? *explicitly state each part*:
+ Show that $A in "NP"$: given *a candidate solution*, we can *verify it in polynomial time*.
+ Choose a known NP-complete problem $B$.
+ Give a polynomial-time reduction from $B$ to $A$: for any instance $b$ of $B$, construct an instance $a=f(b)$ of $A$ in polynomial time. In notation, prove $B reducesto A$.
+ Prove correctness of the reduction. Show that $b " is a YES-instance of " B <==> a=f(b) " is a YES-instance of " A$.

== Complexity Vocabulary

`P`: polynomial-time solvable decision problems.

`NP`: yes-instance 有 polynomial-size certificate，可 polynomial-time verify。

`co-NP`: complement 在 `NP` 中；no-instance 有短反证据。

`NP-hard`: 对所有 `X in NP`，`X <=_p Y`；不要求 `Y in NP`。

`NP-complete = NP intersection NP-hard`.

`P subset.eq NP subset.eq PSPACE subset.eq EXPTIME`.

若某个 NP-complete 问题在 `P` 中，则 `P=NP`。若 `NP != co-NP`，则 `P != NP`。

Good characterization: 同时在 `NP` 和 `co-NP`，yes/no 两边都有短证据。例：bipartite perfect matching，yes 给 matching，no 给 Hall violation `|N(S)| < |S|`。

== 常用 NP-complete 起点

`3-SAT`: 每个 clause 3 literals，问是否可满足。

`Independent Set`: 是否有 `|S| >= k` 且无边在 `S` 内。

`Vertex Cover`: 是否有 `|C| <= k` 覆盖所有边。`S` independent iff `V-S` vertex cover。

`Clique`: `S` 是 `G` 的 clique iff `S` 是 complement graph 的 independent set。

`Set Cover`: universe `U`，选 `<=k` 个集合覆盖 `U`。

`Hamiltonian Cycle/Path`: 是否存在经过每点一次的环/路。

`TSP decision`: 是否有 tour 长度 `<=D`。

`3-Color`: 是否可 3 色染色。

`3D-Matching`: 选 `n` 个 triples，使每个元素恰好出现一次。

`Subset Sum`: 是否存在子集和为 `T`。

== 归约类型识别

Packing / conflict: 选一组互不冲突对象。常从 `Independent Set`。

Covering / domination: 用少量对象覆盖需求。常从 `Vertex Cover` 或 `Set Cover`。

Boolean constraints: 变量赋值满足 clauses。常从 `3-SAT`。

Sequencing / tour: 全局顺序、每点一次。常从 `Hamiltonian`。

Partition / coloring: 分到有限类且冲突不同类。常从 `3-Color` 或 SAT gadget。

Numerical exact sum: 整数列编码逻辑。常从 `Subset Sum` 或 `3DM`。

== HW3 P1 通信链路

#smallcaps[Problem.] Links `L`，interfering pairs `I`，问是否有 `|L'| >= k`，且任意冲突对至多选一个。

#smallcaps[Reduction.] From `Independent Set`.

Graph `G=(V,E)` -> link `ell_v` for each `v`; edge `{u,v}` -> interference pair `(ell_u,ell_v)`; keep `k`.

#smallcaps[Iff.]
Independent set `S` -> choose links `{ell_v: v in S}`，无 interference。

Feasible links `L'` -> vertices `{v: ell_v in L'}`，若有 edge，则对应 pair 冲突，矛盾。

== HW3 P2 Patrol / Dominating Set

#smallcaps[Problem.] 在图中选 `|S| <= k` 个 patrol points，使每个点在 `S` 中或邻接 `S`。

#smallcaps[Reduction.] From `Vertex Cover`.

Given `G=(V,E)`，忽略 isolated vertices。构造 `G'`: 保留 `G`，对每条边 `e={u,v}` 加新点 `x_e`，连到 `u,v`。参数 `k` 不变。

#smallcaps[Iff.]
If `C` is vertex cover, then every `x_e` 被某 endpoint dominate；每个 original vertex 非 isolated，若不在 `C`，其 incident edge 的另一端在 `C`，也被 dominate。

If `D` dominates `G'`，把任何新点 `x_e` 替换成某 endpoint，不增大且不破坏 domination。得 `D' subset.eq V`。每个 `x_e` 只能由 `u` 或 `v` dominate，所以每条边至少一端在 `D'`，是 vertex cover。

== HW3 P3 Monotone 3-SAT

Monotone clause: literals 全正或全负。

#smallcaps[Reduction.] From `3-SAT`。已 monotone 的 clause 不动。Mixed clause 用 fresh variable `u` 拆成两个 monotone clauses。

Two positive one negative:
```
(x or y or not z)
=> (x or y or u) and (not u or not z or not z)
```

One positive two negative:
```
(x or not y or not z)
=> (x or u or u) and (not u or not y or not z)
```

#smallcaps[Reason.] `u` 是桥。若原 clause 满足，可选 `u` 让两新 clauses 满足；反向若两新 clauses 满足，则原 mixed clause 必真。Size linear。

== HW3 P4 Two-bin Partition

#smallcaps[Problem.] Items sizes `s(i)>0`，partition into `I_1,I_2` with sums `<=B_1, <=B_2`。

#smallcaps[Reduction.] From `Subset Sum`.

Instance `(a_1,...,a_n,T)`，令 `A=sum_i a_i`。建 items `s(i_j)=a_j`，设
```
B_1 = T,   B_2 = A - T
```
若 `T>A`，可映射到固定 NO instance。

#smallcaps[Iff.]
Subset sum `S` with sum `T` -> `I_1=S`, `I_2=rest`，两边刚好满。

Feasible partition: sums add to `A`，又 `sum I_1 <= T`, `sum I_2 <= A-T`。若 `sum I_1 < T`，则 `sum I_2 > A-T` 矛盾；故 `sum I_1=T`。

== HW3 P5 Grid Pieces

#smallcaps[Problem.] `m x n` grid 有 black/white pieces，可删除若干；要求每行至少剩一个 piece，且每列不能同时有黑白。

#smallcaps[Reduction.] From `3SAT`。

Rows = clauses, columns = variables.

For clause `C_i` and variable `x_j`:
- if `x_j` appears positively in `C_i`, put a black piece in cell `(i,j)`;
- if `not x_j` appears in `C_i`, put a white piece in cell `(i,j)`;
- otherwise leave the cell empty.

#smallcaps[Iff.]
Satisfying assignment -> 若 `x_j=true`，保留 column `j` 的 black、删 white；若 false，保留 white、删 black。每列单色；每个 satisfied clause row 至少剩一个 piece。

Valid remaining grid -> 若 column 有 black，设变量 true；若有 white，设 false；空列任意。每行至少有 piece；剩下的 black 对应 true positive literal，剩下的 white 对应 true negative literal，因此每个 clause satisfied。

== Hamiltonian / TSP / Coloring

`HAM-CYCLE <=_p TSP`: 每个 vertex 是 city。若原图有 edge，distance `1`；否则 `2`；threshold `D=n`。Tour 长度 `<=n` iff 全用长度 1 的边 iff Hamiltonian cycle。

`LONGEST-PATH` 难点是 simple path 的全局约束。Hamiltonian path 是 longest simple path 的特殊情况。

`3-SAT <=_p 3-COLOR` 语义：
- 基准 triangle `T,F,B` 固定三色。
- Literal nodes 连到 `B`，只能取 `T/F`。
- `x` 与 `not x` 相连，强制一真一假。
- Clause gadget 的语义：禁止三个 inputs 全为 `F`，允许至少一个 `T`。

== 3DM / Subset Sum

`3D-MATCHING`: `X,Y,Z` 各 `n` 个，选 `n` 个 triples 覆盖每个元素恰一次。Perfect matching 的“一次用掉三种资源”编码变量二选一和 clause 满足。

`3DM <=_p SUBSET-SUM`: 每个 triple 编成一个大整数；对应 `x_i,y_j,z_k` 的列为 1。目标数每列为 1。选数和为目标 iff 每个元素恰好被覆盖一次。用足够大的 base 防止进位。

`3-SAT <=_p SUBSET-SUM`: 每一列代表变量或 clause 约束；变量列强制 `x_i/not x_i` 恰选一个；clause 列和 dummy numbers 强制每个 clause 至少被某个 true literal 贡献一次；控制每列和防止 carry。

== PSPACE / QSAT

`PSPACE`: polynomial space solvable。时间可指数，空间受限。

`P subset.eq NP subset.eq PSPACE`：NP 证书可逐个枚举，只保存当前证书。

`QSAT`: quantified Boolean formula
```
exists X_1 forall X_2 exists X_3 ... Phi
```
真值代表存在一套策略面对所有对手选择。`QSAT` is PSPACE-complete。

#smallcaps[Recursive evaluation.]
- `exists x`: 两个分支任一 true 即 true。
- `forall x`: 两个分支都 true 才 true。
递归树指数大，但栈深 polynomial，空间 polynomial。

#smallcaps[读题信号.]
如果问“先手是否有必胜策略”“无论对手如何回应”“planning in exponential state graph”，想 `PSPACE`，常从 `QSAT` 归约。

== FPT / Special Cases

`FPT` w.r.t. parameter `k`: time `f(k) * poly(n)`。指数只能依赖 `k`，不能是 `n^k` 这种。

#smallcaps[Small Vertex Cover.]
取未覆盖 edge `(u,v)`。任意 VC 必含 `u` 或 `v`。
```
VC(G,k):
  if E empty: yes
  if k=0: no
  choose edge (u,v)
  return VC(G-u,k-1) or VC(G-v,k-1)
```
Search tree depth `k`，branching 2，time `O(2^k poly(n))`。

#smallcaps[Tree weighted independent set.]
Root tree. For node `u`:
```
IN(u)  = w_u + sum_{child v} OUT(v)
OUT(u) = sum_{child v} max(IN(v), OUT(v))
```
Answer `max(IN(r),OUT(r))`，postorder `O(n)`。

Bounded treewidth intuition: 图像树，只需记住小 boundary 的状态，DP state 数由 width 控制。

== Local Search 模板

定义：
- 搜索空间；
- neighbor relation；
- objective/potential；
- improvement rule；
- stopping condition。

证明：
1. 每步严格改进某个有限取值的目标/势函数 -> 终止。
2. 停下来的 local optimum 满足什么全局保证。
3. 若是博弈，证明个人 cost 改善等于 potential 改善 -> Nash equilibrium。

#smallcaps[Vertex Cover local deletion.]
从 `S=V` 开始，若能删一个点仍是 cover 就删。每步 `|S|` 减 1，最多 `n` 步。只能保证单点删除局部最优，不保证全局最优。

== Max-Cut Local Search

从任意 cut `(A,B)` 出发。若翻转某个点使 cut weight 增加，则翻转；直到无单点改进。

#smallcaps[局部最优性质.]
对每个 vertex `v`：
```
weight(v, opposite side) >= weight(v, same side)
```
否则翻转 `v` 会增加 cut。

对所有点求和：
```
2 * cut_weight >= 2 * internal_weight
=> total_edge_weight <= 2 * cut_weight
```
而 `OPT <= total_edge_weight`，所以
```
cut_weight >= OPT / 2
```
得到 `2`-approximation。

若每次只接受至少 `(epsilon/n)` 级别的相对改进，可控制迭代次数，ratio 变约 `2+epsilon`。

== Nash / Cost Sharing

Fair cost sharing multicast routing:
- agent `j` 选 path `P_j` from `s` to `t_j`。
- edge `e` cost `c_e`，若 `x_e` 个 agents 使用，每人付 `c_e/x_e`。

Nash equilibrium: 固定别人，没人能单方面换 path 降低自己的 cost。

Rosenthal potential:
```
Phi(P) = sum_e c_e * H(x_e)
H(x)=1+1/2+...+1/x
```
当某 agent 改 path 时，`Delta Phi` 正好等于该 agent 自身 cost change。因此 best response 严格降 cost -> `Phi` 严格下降。状态有限 -> 收敛到 Nash。

Cost `C(P)` 与 potential:
```
C(P) <= Phi(P) <= H(k) C(P)
```
从 social optimum `P*` 开始跑 best response 得到 equilibrium `P`：
```
C(P) <= Phi(P) <= Phi(P*) <= H(k) C(P*)
```
Price of Stability `<= H(k)`。

== Amortized Analysis

不是 average-case；是任意 worst-case operation sequence 的总成本。

三种方法：
- Aggregate: 直接上界 `m` 次操作总成本。
- Accounting: 给便宜操作多收费，信用放对象上。
- Potential: 势能 `Phi(D)` 表示系统信用。

Potential formula:

```
hat(c_i) = c_i + Phi(D_i) - Phi(D_{i-1})
sum hat(c_i) = sum c_i + Phi(D_m)-Phi(D_0)
```

若 `Phi(D_0)=0` 且 `Phi(D_i)>=0`，则

```
sum c_i <= sum hat(c_i)
```

常用势能：
- Stack multipop: `Phi=|S|`。
- Binary counter: `Phi=# of 1 bits`。
- Dynamic table doubling: `Phi=2*num-size`。
- Fibonacci heap: `Phi=trees+2*marks`。

== HW4 P1 Lazy Write Queue(*potential method*)

Operations:
- `Modify(i)`: `dirty[i]=true`，append `i` to FIFO `Q`，即使重复也 append。
- `FlushOne()`: pop queue until finds dirty page，write it and set false；stale entries discarded；empty returns 0。

#smallcaps[Bad single operation.]
Do `k` times `Modify(1)`。First `FlushOne` writes page 1; second `FlushOne` discards `k-1` stale copies，cost `Theta(k)=Theta(m)`。

#smallcaps[Aggregate.]
Each `Modify` inserts one queue entry. Every entry is deleted at most once. Over `m` external operations:
```
#insertions <= m, #deletions <= m
```
All checks/writebacks constant per removed or successful entry -> total `O(m)`。Duplicates 不破坏：每个 duplicate 也是由某次 Modify 产生，最多删除一次。

#smallcaps[Potential.]
Use `Phi=3|Q|`。`Modify`: actual `O(1)`, `Delta Phi=3` -> `O(1)` amortized。

If `FlushOne` removes `t` entries: actual `<=2t+O(1)`，`Delta Phi=-3t`，amortized `<=O(1)-t=O(1)`。Empty queue constant。

== HW4 P2 Triangular Calibration(*Aggregate Analysis && Accounting method*)

Insertion count `N`。Calibration at triangular numbers
```
T_q = 1+...+q = q(q+1)/2
```
q-th calibration costs `q`。

#smallcaps[Number in first n insertions.]
Largest `q` with `q(q+1)/2 <= n`:$q = floor((sqrt(8n+1)-1)/2)$

#smallcaps[Aggregate.]
Base cost `n`。Calibration cost `1+...+q=T_q<=n`。Total `<=2n`。

#smallcaps[Accounting.]
Charge each insertion 2. One pays insertion; one saved. Between calibration `q-1` and `q` exactly $T_q - T_{q-1} = q$ insertions, saved `q` credits pay cost `q`。

== HW4 P3 Tombstone Compaction

Array entries live or tombstone. `Add` appends live. Successful `Remove` marks tombstone. After each remove, if tombstones `D` strictly greater than live `L`, run `Compact`: scan all, copy live, discard tombstones.

#smallcaps[Single worst case.]
Remove may trigger compact on array length `n` -> scan `Theta(n)` entries, possibly copy many live -> `Theta(n)`。

#smallcaps[Aggregate.]
Before compact, `D>L`。Compaction cost at most scan + copy live:
```
(D+L)+L = D+2L < 3D
```
Charge constant credits to each successful Remove creating a tombstone; tombstones present at compact pay for scan/copy. Adds and unsuccessful removes are `O(1)`。Total `O(m)`。

#smallcaps[Potential.]
`Phi=3D`。Add/unsuccessful remove: no change, `O(1)`。Successful remove without compact: `Delta Phi=3` -> `O(1)`。

Trigger compact: after marking, `D'>L'`。Actual `< O(1)+D'+2L' < O(1)+3D'`。Potential drops from `3(D'-1)` to `0`:
```
hat c < O(1)+3D' - 3(D'-1) = O(1)
```

== Randomized Algorithms

Las Vegas: always correct, random running time；分析 expected time。

Monte Carlo: bounded time, small error probability；可 amplification。

Indicator:
```
X_i = 1[event i happens],  E[X_i]=Pr[event i]
E[sum_i X_i] = sum_i E[X_i]
```
Linearity 不要求 independence。

Union bound:
```
Pr[union_i A_i] <= sum_i Pr[A_i]
```

Birthday: expected collision pairs among `k` people, `n` days:
```
E[X] = binom(k,2)/n
```

Coupon collector:
```
E[time] = n(1/n + 1/(n-1)+...+1)=Theta(n log n)
```

== HW4 P4 Audit Sampling

`n` submissions, exactly `r` bad, choose `s` distinct without replacement。`X` = selected bad count。

#smallcaps[Expectation.]
For each bad submission `i`, indicator `X_i=1` if selected。
```
Pr[X_i=1]=s/n
E[X]=sum_{i=1}^r E[X_i]=rs/n
```

#smallcaps[No violation.]
All chosen from `n-r` clean:
```
Pr[X=0] = binom(n-r,s)/binom(n,s)
          = product_{i=0}^{s-1} (n-r-i)/(n-i)
```
If `s>n-r` then probability `0`。

#smallcaps[Exponential bound.]
For `s<=n-r`:
```
(n-r-i)/(n-i) = 1 - r/(n-i) <= 1 - r/n
Pr[X=0] <= (1-r/n)^s <= e^{-rs/n}
```
To get `Pr[X>=1] >= 1-delta`，sufficient:
```
s >= (n/r) ln(1/delta)
```

== HW4 P5 Random Priority Filter

Each vertex independently picks continuous priority `p(v) in [0,1]`。Select `v` iff `p(v)` is smaller than all neighbors。`S` selected set。

#smallcaps[Independent set.]
If adjacent `u,v` both selected, need `p(u)<p(v)` and `p(v)<p(u)`，impossible。

#smallcaps[Selection probability.]
For fixed `v`，among `v` plus `deg(v)` neighbors, all priorities iid continuous. Each is equally likely minimum:
```
Pr[v in S] = 1/(deg(v)+1)
```

#smallcaps[Expected size.]
Let `X_v=1[v in S]`:
```
E[|S|] = sum_{v in V} E[X_v]
       = sum_{v in V} 1/(deg(v)+1)
```
If `d`-regular: `E[|S|]=|V|/(d+1)`。

== Randomized Max-Cut / MAX-3SAT

#smallcaps[Max-Cut.]
Put each vertex independently into `A/B` with prob `1/2`。For edge `e`, `Pr[e crosses]=1/2`。
```
E[cut] = |E|/2 >= OPT/2
```
Expected `2`-approximation。

#smallcaps[MAX-3SAT.]
Random assignment. A 3-literal clause is false only if all three literals false, prob `1/8`。Satisfied prob `7/8`。
If `k` clauses:
```
E[#satisfied] = 7k/8
```
Expected `8/7` ratio for max-satisfied objective relative to `OPT<=k`。

== Karger Min-Cut

Repeatedly choose random edge and contract; keep parallel edges, delete self-loops; stop at 2 supernodes。

Fix a min cut `F*` of size `k`。At stage with `n'` supernodes, min degree at least `k`, so
```
|E| >= k n'/2
Pr[contract F* edge] <= k/|E| <= 2/n'
```
Success = never contract an edge in `F*`:
```
prod_{i=n down to 3} (1-2/i)
= 2/(n(n-1)) = Omega(1/n^2)
```
Repeat `O(n^2 log(1/delta))` times to fail with prob `<=delta`。

== Randomized Quicksort

Random pivot。For sorted order `z_1,...,z_n`，let `X_{i,j}=1` if `z_i,z_j` compared。

They are compared iff first pivot chosen from interval `{z_i,...,z_j}` is one endpoint。
```
Pr[X_{i,j}=1] = 2/(j-i+1)
E[#comparisons] = sum_{i<j} 2/(j-i+1) = O(n log n)
```

== Hashing

Chaining load factor:
```
alpha = n/m
```
Uniform hashing -> expected chain length `alpha`，operations expected `O(1+alpha)`，keep `alpha=O(1)`。

Universal family `H`: for any `x != y`,
```
Pr_{h in H}[h(x)=h(y)] <= 1/m
```
Then expected collisions with fixed key among `n` keys:
```
E[X] <= n/m
```

Common family:
```
h_{a,b}(k) = ((a k + b) mod p) mod m
```
where prime `p` larger than universe key max, `a in {1,...,p-1}`, `b in {0,...,p-1}`。

Perfect hashing static set: first table size `n`; bucket `j` with `n_j` keys gets second table size `n_j^2`。Universal hashing gives no-collision probability at least constant; expected tries `O(1)`；expected total second-level space `E[sum n_j^2]=O(n)`。

== Bloom Filter

Array `m` bits, `k` independent hash functions。Insert `x`: set `h_1(x),...,h_k(x)` to 1。Query: if all 1 -> possibly present；if any 0 -> definitely absent。

Guarantees:
- No false negative.
- False positive possible.
- Standard version cannot delete safely。

After inserting `n` keys:
```
Pr[fixed bit still 0] = (1-1/m)^{nk} approx e^{-nk/m}
Pr[bit is 1] approx 1 - e^{-nk/m}
False positive f approx (1 - e^{-nk/m})^k
```
Optimal number of hashes:
```
k = (m/n) ln 2
f approx (1/2)^k approx 0.6185^{m/n}
```

== Fingerprinting

String equality：把 bit string 看作 integer
```
a = sum_{i=1}^n a_i 2^{i-1}
```
Randomly choose prime `p` from primes `< t`，send `F(a)=a mod p`。

If `F(a) != F(b)`，一定 `a != b`。Error only when `a != b` but `p | (a-b)`。

Since `|a-b| < 2^n`，number of distinct prime factors `< n`。Choose `t=n^2 ln n`，there are `Theta(n^2)` primes below `t`，so
```
Pr[false negative] <= O(1/n)
```
Communication:
```
log p = O(log n)
```

== Tail Bounds

Markov: nonnegative `X`
```
Pr[X >= a] <= E[X]/a
```

Chebyshev:
```
Pr[|X-E[X]| >= a] <= Var[X]/a^2
```

Chernoff for independent indicators `X=sum_i X_i`, `mu=E[X]`：
For `0<=delta<=1`:
```
Pr[X >= (1+delta)mu] <= e^{-mu delta^2/3}
Pr[X <= (1-delta)mu] <= e^{-mu delta^2/2}
```
For `delta>1`:
```
Pr[X >= (1+delta)mu] <= e^{-mu delta ln delta/3}
```

Use pattern: prove for fixed object with Chernoff, then all objects via union bound。

== Random Load Balancing

`m` equal jobs，`n` machines，每个 job independent uniform random machine。

For fixed machine `i`:
```
X_i = sum_{j=1}^m Y_{i,j}
E[X_i] = m/n
```
By Chernoff:
```
Pr[X_i >= (1+delta)m/n]
 <= e^{-(m/n)delta^2/3}
```
All machines:
```
Pr[exists i: X_i >= (1+delta)m/n]
 <= n e^{-(m/n)delta^2/3}
```

若 `m/n` 足够大，最大负载 high probability 接近平均负载。

== Approximation Ratio

Minimization: `A(I) <= alpha * OPT(I)`。

Maximization: `A(I) >= OPT(I)/alpha`。

`alpha >= 1`，越接近 1 越好。

常见证明：
- 找 `OPT` 的 lower bound（min problem）或 upper bound（max problem）。
- 用 greedy/local/random 输出与这个 bound 比较。
- Charging argument: 把算法成本分摊给元素，单个 charge 由 `OPT` 控制。

== Set Cover Greedy

Universe `X`, sets `F`, costs `cost(S)`。Greedy chooses set minimizing
```
cost(S) / |S inter U|
```
where `U` is uncovered elements。

Let `V=OPT` and `k=|U|` currently uncovered。Optimal cover can cover these `k` remaining elements with total cost `V`，so some optimal set has average cost `<= V/k` per uncovered element。Greedy no worse。

Charge each newly covered element by selected set's average cost。The `i`-th newly covered element charge at most `V/(n-i+1)`。
```
total cost <= V(1/n+1/(n-1)+...+1)
           = V H_n <= V(1+ln n)
```
Greedy is `H_n`-approximation。

== Makespan Scheduling

`n` jobs processing times `p_j`，`m` identical machines。Minimize maximum machine load `M`。

Useful lower bounds on `OPT=M*`:
```
M* >= max_j p_j
M* >= (sum_j p_j)/m
```

#smallcaps[List Scheduling.]
Jobs arrive in given order; assign next job to currently least-loaded / first available machine。

Let last finishing job `X` start at `T`, length `t`。Then `M=T+t`。
At time before `T` no machine idle, so processed work at least `mT`; hence `M*>=T`。Also `M*>=t`。
```
M=T+t <= 2 max(T,t) <= 2M*
```
So `2`-approximation。Online。

#smallcaps[LPT.]
Sort jobs decreasing by processing time, then list schedule。Offline。Guarantee:
```
M <= (4/3) M*
```
Idea: last-starting job is smallest. If its size `t <= M*/3`，then `M<=M*+t<=4M*/3`；if `t>M*/3`，all jobs large, each optimal machine has at most two jobs, LPT structure avoids worse imbalance。

== Common Exam Proof Fragments

#smallcaps[NP membership.]
Certificate is the chosen set/assignment/path/schedule. Verify size/cost/constraints by scanning graph, clauses, or numbers in polynomial time.

#smallcaps[Reduction correctness.]
Write:
```
(=>) Given a solution to source instance, construct target solution...
(<=) Given a target solution, decode source solution...
```
Mention construction size/time polynomial。

#smallcaps[Amortized.]
Pick potential that grows when delayed work accumulates and drops when expensive cleanup happens. Verify `Phi>=0` and initial `0`。

#smallcaps[Randomized expectation.]
Define indicators for each object, compute individual probability, sum by linearity。

#smallcaps[High probability.]
For a fixed object use Chernoff/Markov/Chebyshev. For all objects add union bound。

#smallcaps[Approximation.]
State `OPT` bound first. Then compare algorithm output to the bound. For greedy set cover, charge elements; for scheduling, inspect last job。

== HW3 Original P1 Links

#smallcaps[Membership in NP.]
Given a subset `L' subset.eq L`, check whether `|L'| >= k` and whether any pair in `I` has both endpoints in `L'`. This is done by scanning all pairs in `I`.

#smallcaps[Known problem.]
Reduce from `Independent Set`, which is NP-complete.

#smallcaps[Construction.]
Given an instance `(G,k)` of Independent Set, where `G=(V,E)`, create one link `ell_v` for every vertex `v in V`. Let
```
L = {ell_v : v in V}.
```
For every edge `{u,v} in E`, add the interfering pair `(ell_u, ell_v)` to `I`. The integer `k` is unchanged. The construction is polynomial.

#smallcaps[Correctness.]
If `G` has an independent set `S` with `|S| >= k`, choose the corresponding links
```
L' = {ell_v : v in S}.
```
No two vertices in `S` are connected by an edge, so no two chosen links form an interfering pair. Therefore `L'` is feasible and has size at least `k`.

Conversely, suppose there is a feasible set of links `L'` with `|L'| >= k`. Take the corresponding vertices
```
S = {v in V : ell_v in L'}.
```
Then `|S|=|L'| >= k`. If two vertices in `S` were adjacent in `G`, their two links would be an interfering pair contained in `L'`, impossible. Hence `S` is an independent set.

Thus the graph has an independent set of size at least `k` iff the constructed link instance has a feasible set of at least `k` links. The problem is NP-hard, and with membership in NP it is NP-complete.

== HW3 Original P2 Patrol

#smallcaps[Membership in NP.]
For a proposed set `S`, check `|S| <= k`; then check every vertex to see whether it is in `S` or has a neighbor in `S`.

#smallcaps[Known problem.]
Reduce from `Vertex Cover`.

#smallcaps[Construction.]
Let `(G,k)` be a Vertex Cover instance, `G=(V,E)`. Ignore isolated vertices, since they are irrelevant for vertex cover. Construct `G'=(V',E')` by keeping all vertices and edges of `G`. For every edge `e={u,v} in E`, add a new vertex `x_e` and edges `{x_e,u}` and `{x_e,v}`. Thus
```
V' = V union {x_e : e in E}.
```
The new parameter is still `k`.

#smallcaps[Forward.]
Suppose `G` has a vertex cover `C` with `|C| <= k`. The same set `C` dominates `G'`. For each new vertex `x_e`, at least one endpoint of `e` is in `C`, so `x_e` is dominated. For an original vertex `v`, either `v in C`, or `v` has an incident edge `{v,u}` and the cover property forces some endpoint of this edge to be in `C`. Since `v notin C`, we must have `u in C`, so `v` is dominated by `u`.

#smallcaps[Backward.]
Let `D` be a dominating set of `G'` with `|D| <= k`. If `D` contains a new vertex `x_e`, where `e={u,v}`, replace `x_e` by one endpoint, say `u`. This does not increase the size and does not destroy domination: `x_e` is dominated by `u`, `u` is dominated by itself, `v` is dominated by `u` through the original edge, and `x_e` has no other neighbors. Repeating, obtain a dominating set `D' subset.eq V` with `|D'| <= k`.

For any original edge `e={u,v}`, the new vertex `x_e` must be dominated by `D'`. Since `D' subset.eq V` and `x_e` is adjacent only to `u` and `v`, at least one of `u,v` belongs to `D'`. Therefore every edge of `G` is covered by `D'`.

So `G` has a vertex cover of size at most `k` iff `G'` has a dominating set of size at most `k`.

== HW3 Original P3 Monotone 3-SAT

#smallcaps[Membership in NP.]
A truth assignment can be checked by evaluating all clauses.

#smallcaps[Known problem.]
Reduce from `3-SAT`.

#smallcaps[Construction.]
Let `phi` be a 3-SAT formula. Transform each clause separately. Clauses already monotone are unchanged. Mixed clauses get one fresh variable `u`.

For a mixed clause with two positive literals and one negative literal,
```
(x or y or not z)
```
replace it by
```
(x or y or u) and (not u or not z or not z).
```
Both clauses are monotone.

For a mixed clause with one positive literal and two negative literals,
```
(x or not y or not z)
```
replace it by
```
(x or u or u) and (not u or not y or not z).
```
The construction adds at most one fresh variable and two clauses per original clause, so the size increases linearly.

#smallcaps[Correctness: two-positive case.]
Let `C=(x or y or not z)` and
```
C'=(x or y or u) and (not u or not z or not z).
```
If `C` is true and at least one of `x,y` is true, set `u=false`. If both `x,y` are false, then `z` must be false, and set `u=true`. In both cases `C'` is true.

Conversely, if `C'` is true, then either `x` or `y` is true, in which case `C` is true; or both `x,y` are false. Then the first clause forces `u=true`, and the second clause forces `z=false`. Thus `C` is true.

#smallcaps[Correctness: one-positive case.]
For
```
C=(x or not y or not z)
C'=(x or u or u) and (not u or not y or not z)
```
if `C` is true, set `u=false` when `x` is true, and set `u=true` otherwise. Conversely, if `C'` is true and `x` is false, then the first clause forces `u=true`, so the second clause forces at least one of `not y, not z` to be true. Hence `C` is true.

Thus `phi` is satisfiable iff the new monotone formula is satisfiable.

== HW3 Original P4 Two Bins

#smallcaps[Membership in NP.]
Given `(I_1,I_2)`, check that it is a partition of `I` and compute both total sizes.

#smallcaps[Known problem.]
Reduce from `Subset Sum`.

#smallcaps[Construction.]
Let `(a_1,...,a_n,T)` be a Subset Sum instance. Let
```
A = sum_{i=1}^n a_i.
```
Assume `T <= A`; if `T>A`, map to a fixed NO instance, e.g. one item of size 3 and capacities `B_1=B_2=1`.

For each number `a_j`, create one item `i_j` with size `s(i_j)=a_j`. Set
```
B_1 = T
B_2 = A - T.
```

#smallcaps[Correctness.]
If the subset sum instance has `S subset.eq {1,...,n}` with
```
sum_{j in S} a_j = T,
```
put the corresponding items into `I_1` and all other items into `I_2`. Then `sum I_1=T=B_1` and `sum I_2=A-T=B_2`.

Conversely, suppose the two-bin instance has a feasible partition `(I_1,I_2)`. Since every item is placed in exactly one bin,
```
sum_{i in I_1} s(i) + sum_{i in I_2} s(i) = A.
```
Feasibility gives `sum I_1 <= T` and `sum I_2 <= A-T`. If `sum I_1 < T`, then `sum I_2 = A - sum I_1 > A-T`, contradiction. Therefore `sum I_1=T`, and the corresponding numbers form a subset summing to `T`.

== HW3 Original P5 Grid Pieces

#smallcaps[Membership in NP.]
After the pieces to be removed are specified, scan all rows and columns to check both requirements.

#smallcaps[Known problem.]
Reduce from `3SAT`.

#smallcaps[Construction.]
Let `phi` have variables `x_1,...,x_n` and clauses `C_1,...,C_m`. Construct an `m x n` grid. Rows correspond to clauses and columns to variables.

For each clause `C_i` and variable `x_j`:
- if `x_j` appears in `C_i`, put a black piece in cell `(i,j)`;
- if `not x_j` appears in `C_i`, put a white piece in cell `(i,j)`;
- otherwise leave cell `(i,j)` empty.

This is exactly the official construction: black encodes a positive occurrence and white encodes a negative occurrence. The grid has polynomial size.

#smallcaps[Forward.]
Suppose `phi` has a satisfying assignment. Remove pieces column by column:
- if `x_j=true`, keep all black pieces in column `j` and remove all white pieces;
- if `x_j=false`, keep all white pieces in column `j` and remove all black pieces.
No column contains both colors. Since every clause has at least one true literal, the corresponding piece remains in that clause row: a true positive literal leaves a black piece, and a true negative literal leaves a white piece. Thus every row remains nonempty.

#smallcaps[Backward.]
Suppose the grid can be made valid. Define an assignment from remaining pieces. If column `j` contains a black piece, set `x_j=true`; if it contains a white piece, set `x_j=false`; if it contains no piece, assign arbitrarily. This is well-defined because a valid column cannot contain both colors.

Each row contains at least one remaining piece. If the remaining piece is black in column `j`, then `x_j` appears positively in that clause and our assignment makes it true. If the remaining piece is white in column `j`, then `not x_j` appears in that clause and our assignment makes it true. Therefore every clause is satisfied.

== HW4 Original P1 Lazy Queue

#smallcaps[Part a.]
Take one page, page 1. Perform `k` operations `Modify(1)`. The queue contains `k` copies of `1`, and `dirty[1]=true`.

Call `FlushOne()` once. It removes the first copy of 1, writes the page back, and sets `dirty[1]=false`. There are still `k-1` copies in the queue, but all are stale.

The next call to `FlushOne()` removes all these `k-1` stale entries before returning 0. Hence this one operation costs `Theta(k)`. The number of external operations so far is `m=k+2`, so the cost is `Theta(m)`.

#smallcaps[Part b aggregate.]
In any sequence of `m` operations, each `Modify` inserts exactly one entry into `Q`, so total queue insertions are at most `m`. Each queue entry, once inserted, can be removed at most once; total queue deletions are also at most `m`.

All other work is charged to these operations. `Modify` does constant work besides insertion. During `FlushOne`, every loop iteration deletes one queue entry and checks the dirty bit. A successful flush performs only constant extra work: one write-back and one assignment to the dirty bit.

Thus total cost is bounded by a constant times external operations plus insertions plus deletions, hence `O(m)`. Duplicate page IDs do not hurt: every duplicate entry was inserted by some previous `Modify` and is deleted at most once.

#smallcaps[Part c potential.]
Let
```
Phi = 3|Q|.
```
It is nonnegative and initially zero. For `Modify(i)`, actual cost is `O(1)` and queue length increases by 1, so amortized cost is `O(1)+3=O(1)`.

For `FlushOne()`, suppose it removes `t` queue entries. The actual cost is at most `2t+O(1)`: for each removed entry, pay for deletion and checking; if a dirty page is written, only constant extra work is needed. Potential decreases by `3t`, so
```
hat c <= (2t+O(1)) - 3t = O(1).
```
If queue is empty, actual cost is constant and potential does not change.

== HW4 Original P2 Triangular

#smallcaps[Part a.]
Calibrations occur at insertion numbers
```
T_1, T_2, ..., T_q
```
that are at most `n`. Thus `q` is the largest integer with
```
T_q = q(q+1)/2 <= n,
q = floor((sqrt(8n+1)-1)/2).
```

#smallcaps[Part b aggregate.]
Let `k=floor((sqrt(8n+1)-1)/2)`. Exactly `k` calibrations occur. Base insertion cost is `n`. Total calibration cost is
```
1+2+...+k = T_k <= n.
```
So total cost is at most `2n`, hence `O(n)`.

#smallcaps[Part c accounting.]
Charge each insertion 2 units. One unit pays for the insertion; the other is saved as credit for future calibration. Between the `(q-1)`-st calibration and the `q`-th calibration, there are
```
T_q - T_{q-1} = q
```
insertions. These `q` insertions save exactly `q` credits, enough to pay for the `q`-th calibration. Credits never become negative, so amortized charge 2 is sufficient.

== HW4 Original P3 Compaction

#smallcaps[Part a.]
A `Remove` may trigger `Compact`. If the array length is `n` immediately before compaction, `Compact` scans the whole array, costing `Theta(n)`, and may also copy many live articles. Thus one `Remove` can cost `Theta(n)`.

#smallcaps[Part b aggregate.]
Let `D` be tombstones and `L` live articles immediately after a remove and before possible compaction. Compaction is triggered only when `D>L`. Its cost is at most scan all entries plus copy live entries:
```
(D+L)+L = D+2L < 3D.
```
Charge a constant number of credits to every successful `Remove` that creates a tombstone. One part pays for the constant remove cost; remaining credits stay with the tombstone. At compaction, each tombstone is discarded, and the inequality above shows the tombstones present can pay for the whole compaction. Adds and unsuccessful removes cost `O(1)`. Hence any `m` external operations cost `O(m)`.

#smallcaps[Part c potential.]
Let
```
Phi = 3D.
```
Initially zero and always nonnegative.

For `Add`, actual cost is `O(1)` and `D` does not change. For unsuccessful `Remove`, only lookup is done and `D` does not change. For successful `Remove` without compaction, actual cost is `O(1)` and `D` increases by 1, so amortized cost is `O(1)+3=O(1)`.

For successful `Remove` triggering compaction, let `D'` and `L'` be counts after the tombstone is created and before compaction. Then `D'>L'`, and compaction cost is at most
```
D' + 2L' < 3D'.
```
Before the remove, tombstones were `D'-1`, so potential was `3(D'-1)`. After compaction, tombstones are 0, so potential is 0. Amortized cost:
```
O(1) + (D'+2L') - 3(D'-1) < O(1)+3 = O(1).
```

== HW4 Original P4 Audit

#smallcaps[Part a.]
Number the `r` violating submissions as `1,...,r`. For each violating submission `i`, define indicator
```
X_i = 1 if submission i is selected, else 0.
```
Then `X=sum_i X_i`. Since the sample contains `s` submissions chosen uniformly without replacement,
```
Pr[X_i=1] = s/n.
```
By linearity:
```
E[X] = sum_{i=1}^r E[X_i] = rs/n.
```

#smallcaps[Part b.]
No violation is found iff all selected submissions are among the `n-r` clean submissions:
```
Pr[X=0] = binom(n-r,s) / binom(n,s),
```
interpreted as 0 if `s>n-r`. Equivalently, for `s<=n-r`,
```
Pr[X=0] = product_{i=0}^{s-1} (n-r-i)/(n-i).
```

#smallcaps[Part c.]
Assume `s<=n-r`; otherwise probability is 0. In the product,
```
(n-r-i)/(n-i) = 1 - r/(n-i) <= 1 - r/n.
```
Therefore
```
Pr[X=0] <= (1-r/n)^s <= e^{-rs/n}.
```
Thus
```
Pr[X>=1] >= 1 - e^{-rs/n}.
```
It is sufficient to choose
```
s >= (n/r) ln(1/delta)
```
to get probability at least `1-delta`. If this exceeds `n`, sampling all `n` submissions finds a violation with probability 1 because `r>0`.

== HW4 Original P5 Priority

#smallcaps[Part a.]
Suppose for contradiction that `S` is not independent. Then there is an edge `{u,v}` with both endpoints selected. Since `u` is selected and `v` is its neighbor, `p(u)<p(v)`. Since `v` is selected and `u` is its neighbor, `p(v)<p(u)`. Impossible. Hence no adjacent vertices are both selected.

#smallcaps[Part b.]
Vertex `v` is selected iff its priority is the smallest among `v` and its `deg(v)` neighbors. These `deg(v)+1` priorities are independent from the same continuous distribution, so each vertex in this closed neighborhood is equally likely to have the minimum. Therefore
```
Pr[v in S] = 1/(deg(v)+1).
```

#smallcaps[Part c.]
For each vertex `v`, define `X_v=1` if `v in S`, else 0. Then
```
X = |S| = sum_{v in V} X_v.
```
By linearity and part b,
```
E[X] = sum_{v in V} E[X_v]
     = sum_{v in V} Pr[v in S]
     = sum_{v in V} 1/(deg(v)+1).
```
If `G` is `d`-regular, then `deg(v)=d` for every `v`, so
```
E[X] = |V|/(d+1).
```

== PSPACE Proof Blocks

#smallcaps[Show problem in PSPACE.]
Use depth-first recursive search over the game/configuration tree. Store only current configuration, recursion depth/counter, and input. Even if the tree has exponentially many nodes, each configuration has polynomial encoding length, and recursion depth is polynomial or can be bounded by number of configurations with repeated-state handling. Hence polynomial space.

#smallcaps[QSAT evaluation.]
For formula
```
Q_1 x_1 Q_2 x_2 ... Q_n x_n Phi
```
define recursive procedure:
```
Eval(i, partial assignment):
  if i=n+1: return Phi(assignment)
  if Q_i = exists:
      return Eval(i+1, x_i=true) or Eval(i+1, x_i=false)
  if Q_i = forall:
      return Eval(i+1, x_i=true) and Eval(i+1, x_i=false)
```
The time is exponential, but stack depth is `n` and each frame stores one variable/value and position, so space is polynomial.

#smallcaps[Show PSPACE-hard.]
Reduce from QSAT. Explain the quantifier game: existential variables are choices of Player 1; universal variables are choices of Player 2/adversary. Gadgets must force alternating choices and make the final winning/feasible condition equivalent to `Phi` being true.

#smallcaps[Planning reachability in PSPACE.]
If states have `b` bits, there are at most `2^b` states. To decide if `c_1` reaches `c_2` within `L`, recursively guess middle state `m`:
```
Reach(c1,c2,L):
  if L=0: return c1=c2
  if L=1: return c1=c2 or one-step(c1,c2)
  for every state m:
      if Reach(c1,m,L/2) and Reach(m,c2,L/2): return true
  return false
```
Depth `O(log L)=O(b)` when `L<=2^b`; each state uses `b` bits; space polynomial.

== FPT Proof Blocks

#smallcaps[Branching recurrence.]
For parameter `k`, if each recursive step creates at most `a` branches and decreases `k` by at least 1:
```
T(k,n) <= a T(k-1,n) + poly(n)
       = O(a^k poly(n)).
```
This is FPT. Avoid `n^k`, because exponent depends on `k`.

#smallcaps[Vertex Cover branching correctness.]
Choose uncovered edge `(u,v)`. Any vertex cover must contain `u` or `v`; otherwise edge `(u,v)` is uncovered. Therefore branching into `include u` and `include v` is exhaustive. Deleting chosen vertex and incident edges preserves equivalence with budget reduced by 1.

#smallcaps[Kernel-style observation.]
If a vertex has degree `>k` in a Vertex Cover instance with budget `k`, then it must be selected; otherwise all its neighbors must be selected, requiring more than `k` vertices. This can reduce instance before branching.

#smallcaps[Tree DP proof.]
Root tree at `r`. Once the decision at node `u` is fixed, subtrees of different children are independent. For weighted independent set:
```
IN(u)=w_u+sum OUT(v)
OUT(u)=sum max(IN(v),OUT(v))
```
Induct on subtree height. Base leaf is immediate. Inductive step follows from independence between child subtrees and the edge constraint between `u` and each child.

== Reduction Gadget Semantics

#smallcaps[3-SAT to Independent Set.]
Make one triangle per clause, vertices are literals. Add conflict edges between complementary literals across clauses. Set `k=#clauses`. Independent set of size `k` selects exactly one literal per clause and no complementary pair, so selected literals define a consistent satisfying assignment.

#smallcaps[Vertex Cover to Set Cover.]
Universe `U=E`. For each vertex `v`, create set `S_v` containing all incident edges. Choosing `k` sets covering `U` iff choosing `k` vertices covering every edge.

#smallcaps[Independent Set to Vertex Cover.]
Map `(G,k)` to `(G, |V|-k)`. If `S` is independent of size at least `k`, then `V-S` is a vertex cover of size at most `|V|-k`. If `C` is vertex cover, then `V-C` is independent.

#smallcaps[Hamiltonian to TSP.]
Use distances 1 for graph edges and 2 for nonedges, threshold `n`. Any tour has exactly `n` edges and each has length at least 1. Length at most `n` forces all chosen city adjacencies to be graph edges.

#smallcaps[Subset Sum digit construction.]
Each decimal/base-`B` column enforces one constraint. Pick base larger than maximum possible column sum so no carries occur. Then equality of total numbers is equivalent to equality column by column.

== Amortized Proof Blocks

#smallcaps[Aggregate pattern.]
Identify a unit of work that happens many times in one operation but only once over its lifetime. Examples: each queue entry is inserted once and deleted once; each pushed stack item is popped once; each tombstone is discarded once.

#smallcaps[Accounting pattern.]
Charge cheap operation extra credits and attach them to objects that will later cause expensive work. Must state invariant: credits stored are always nonnegative and enough to pay future operation.

#smallcaps[Potential pattern.]
Pick `Phi` proportional to delayed work. For operation:
```
amortized = actual + Delta Phi.
```
Cheap operation builds delayed work -> positive `Delta Phi`; expensive operation removes delayed work -> negative `Delta Phi`.

#smallcaps[Binary counter.]
If increment flips `t` trailing 1s to 0 and one 0 to 1, actual cost `t+1`. Potential `Phi=#1 bits`. Change `Delta Phi <= 1-t`. Thus amortized cost `<=2`.

#smallcaps[Dynamic array doubling.]
Potential `Phi=2*num-size`. Insert without expansion: actual 1, `Delta Phi=2`, amortized 3. Insert with expansion when `num=size`: actual `num+1`; after doubling, new `num'=num+1`, `size'=2num`; potential changes from `num` to `2`, so amortized is `O(1)` after constants are chosen carefully.

== Random Proof Blocks

#smallcaps[Linearity without independence.]
Even if events are dependent, for `X=sum_i X_i`:
```
E[X]=sum_i E[X_i]=sum_i Pr[X_i=1].
```
Use this for selected vertices, satisfied clauses, crossing edges, comparisons, collisions.

#smallcaps[Amplification.]
If a Monte Carlo run fails with probability `p<1`, independent repetition `r` times fails with probability `p^r` when success can be recognized or best answer can be kept. Choose
```
r >= ln(1/delta)/ln(1/p)
```
up to constants to make failure `<=delta`.

#smallcaps[Union bound template.]
To prove all `n` objects good:
```
Pr[exists bad object] <= sum_i Pr[object i bad]
```
If each bad probability is `<=delta/n`, all good with probability at least `1-delta`.

#smallcaps[Chernoff parameter solving.]
For `X=sum independent indicators`, `mu=E[X]`:
```
Pr[X >= (1+delta)mu] <= e^{-mu delta^2/3}
```
To make this at most `epsilon`, sufficient:
```
mu delta^2 / 3 >= ln(1/epsilon).
```
For all `n` machines, use `epsilon=delta/n`.

#smallcaps[Sampling without replacement.]
Expectation by indicators still works. For no bad item:
```
binom(n-r,s)/binom(n,s)
= product_{i=0}^{s-1} (1-r/(n-i))
<= (1-r/n)^s <= e^{-rs/n}.
```

== Approximation Proof Blocks

#smallcaps[Maximization.]
To prove `alpha`-approx, show `ALG >= OPT/alpha`. Often show `OPT <= upper_bound` and `ALG >= upper_bound/alpha`.

#smallcaps[Minimization.]
To prove `alpha`-approx, show `ALG <= alpha OPT`. Often show several lower bounds on `OPT`, then express algorithm output by their sum.

#smallcaps[Scheduling lower bounds.]
Always write:
```
M* >= max_j p_j
M* >= (sum_j p_j)/m
```
For list scheduling, last job gives `M=T+t`; `T <= total previous work/m <= M*` because before `T` all machines busy; `t<=M*`; hence `M<=2M*`.

#smallcaps[Set cover charging.]
When `k` elements remain uncovered, optimal solution of cost `OPT` covers all of them, so some set in OPT has average uncovered cost at most `OPT/k`. Greedy's chosen average is no larger. Charge new elements at that average; total charge is harmonic.

#smallcaps[Local-search Max-Cut.]
At local optimum, for every vertex:
```
cross(v) >= same(v).
```
Summing over vertices gives `2 cross >= 2 same`; total edge weight `cross+same <= 2 cross`; since `OPT <= total`, `cross >= OPT/2`.
