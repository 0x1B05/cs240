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
#let P = math.op("P")
#let OPT = math.op("OPT")
#let ALG = math.op("ALG")
#let O = math.op("O")
#let Theta = math.op("Theta")
#let Omega = math.op("Omega")
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
#let finish = math.op("finish")
#let deg = math.op("deg")
#let ln = math.op("ln")
#let approx = math.op("approx")
#let cap = math.op("cap")
#let Geo = math.op("Geo")
#let reducesto = math.attach($<=$, br: $p$)

Upper bound: $O(...)$; lower bound: $Omega(...)$; tight bound: $Theta(...)$.

$"constant" < log n < n < n log n < n^a < n^(log n) < 2^n / poly(n) < a^(b^n)$

= Greedy Review

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

== Greedy Cases

#smallcaps[Interval scheduling.]
Goal: maximum number of non-overlapping intervals. Rule: sort by finish time, repeatedly choose interval with earliest finish compatible with previous choice.

Stays-ahead proof: let greedy intervals be $g_1,...$ and optimal intervals be $o_1,...$ sorted by finish time. Prove by induction $finish(g_i) <= finish(o_i)$ for each $i$. Hence if optimal can schedule $k$ intervals, greedy can also keep room for at least $k$.

#smallcaps[Minimize maximum lateness.]
Jobs with processing time $t_j$, deadline $d_j$. Completion $C_j$; lateness $L_j=max(0, C_j-d_j)$. Rule: earliest deadline first. Exchange adjacent inversion: if $d_i <= d_j$ but $j$ before $i$, swapping them does not increase max lateness. Repeated swaps transform any optimal schedule into EDF.

#smallcaps[MST.]
Cut property: for any cut, a lightest edge crossing the cut is safe for some MST. Cycle property: if an edge is strictly heaviest on a cycle, it is in no MST.

Kruskal: sort edges increasing; add if no cycle. Prim: grow connected component by lightest outgoing edge. Reverse-delete: sort decreasing; delete if graph stays connected.

#smallcaps[Clustering.]
For maximum spacing $k$-clustering, run Kruskal until exactly $k$ connected components remain. Spacing is next edge connecting different components.

#example(title: "用最少长度为 1 的闭区间覆盖实线上所有点。")[
  #smallcaps[Algorithm.]
  Sort $A$ in ascending order. Maintain $R$, the right endpoint of the last interval selected. Scan from left to right. If the current point is to the right of $R$, start a new unit interval $[A[i], A[i]+1]$.
  ```
  Find-Unit-Intervals(A):
      Sort A in ascending order
      I = empty set
      R = -infinity
      for i = 1 to n:
          if A[i] > R:
              I = I union {[A[i], A[i] + 1]}
              R = A[i] + 1
      return I
  ```
  The minimum number of unit intervals is $|I|$.

  #smallcaps[Correctness.(*Exchange argument*)]
  Let $[l_1,r_1], ..., [l_p,r_p]$ with $r_1 < ... < r_p$ be the greedy solution. Let $[l'_1,r'_1], ..., [l'_q,r'_q]$ with $r'_1 < ... < r'_q$ be an optimal solution, and assume the two solutions agree for the largest possible prefix length $k$.

  The greedy algorithm places intervals as right as possible. Let $x$ be the leftmost point to the right of $r_k$. Then greedy chooses $[x,x+1]$, so $l_(k+1)=x$ and $r_(k+1)=x+1$. Since the optimal solution must also cover $x$, we have $r'_(k+1) <= x+1 = r_(k+1)$.

  Replace $[l'_(k+1), r'_(k+1)]$ in the optimal solution with $[l_(k+1), r_(k+1)]$. The replacement can only extend the covered region to the right, so it preserves feasibility and increases the common prefix by one. Repeating this exchange makes an optimal solution agree with greedy. If greedy used more intervals than optimal, the left endpoint of its last interval would be an uncovered point for the optimal solution, a contradiction. Hence the greedy solution is optimal.

  #smallcaps[Complexity.] Sorting costs $O(n log n)$ and the scan costs $O(n)$, so the total time is $O(n log n)$.
]
#example(title: "最少加油次数")[
  #smallcaps[题意.] `stations[i]` 表示在 `i` 加油后最多可前进距离，求到终点的最少加油次数；样例把起点出发计入次数。

  #smallcaps[Greedy idea.]
  Since the last station is always reachable, minimize refuels by maximizing progress at each step: among all stations reachable with the current number of refuels, choose the station that allows reaching the farthest possible point after one more refuel.

  #smallcaps[Algorithm.]
  Maintain:
  - `current_end`: farthest station reachable with the current number of refuels;
  - `farthest`: farthest station reachable with one more refuel from scanned stations;
  - `refuels`: number of refuels used.

  ```
  MinRefuels(stations):
      n = length(stations)
      if n <= 1:
          return 0
      refuels = 0
      current_end = 0
      farthest = 0
      for i = 0 to n - 2:
          farthest = max(farthest, i + stations[i])
          if i == current_end:
              refuels = refuels + 1
              current_end = farthest
              if current_end >= n - 1:
                  break
      return refuels
  ```

  #smallcaps[Correctness.(*stays ahead*)]
  Assume an optimal solution $OPT$ uses fewer refuels than the greedy algorithm. Suppose both solutions make the same choices for the first $i$ refuels and reach position $p_i$. For the next refuel, $OPT$ chooses some position $p_"opt"$, while greedy chooses a reachable position that maximizes the next reach, denoted $p_"greedy"$. By the greedy choice, $p_"greedy" >= p_"opt"$ in terms of reachable progress.

  Therefore after each refuel, greedy reaches at least as far as the corresponding optimal choice. Greedy can never need more refuels than $OPT$, contradicting the assumption. Hence greedy is optimal.

  #smallcaps[Complexity.] The array is traversed once, so the time complexity is $O(n)$.
]

#example(title: "网格局部最小值")[
  #smallcaps[题意.] 只能调用 $V(i,j)$ 查询 $n times n$ 网格值，用 $O(n)$ 次查询找一个上下左右局部最小。

  #smallcaps[High-level idea.]
  Divide the grid into four quadrants using the middle row and middle column. Let `B` be the boundary positions, i.e. cells on the middle row or middle column, and compute `m in argmin_(b in B) V(b)`.

  If $m$ is not already a local minimum, then it has a strictly smaller neighbor in its own quadrant; following strictly decreasing neighbors from $m$ reaches a local minimum that cannot cross back to the boundary. To make this precise, strengthen the recursion: given a starting position $t$, return a local minimum with value at most $V(t)$.

  ```
  FindGridLocalMinimum(G, t):
      if G has size 1 x 1: return t
      Divide G into four quadrants by the middle row and column
      Let B be the boundary cells on the middle row or middle column
      Let m be a cell in B with minimum value V(m)
      if V(t) >= V(m):
          G' = the quadrant containing m
          return FindGridLocalMinimum(G', m)
      else:
          G' = the quadrant containing t
          return FindGridLocalMinimum(G', t)
  ```

  #smallcaps[Algorithm design.]
  Base case: if the current grid is $1 times 1$, return $t$. Otherwise split by the middle row and column, find boundary minimum $m$, and recurse into the quadrant containing the smaller seed among $t$ and $m$.

  #smallcaps[Correctness.]
  We prove by induction on the side length of the current grid that `FindGridLocalMinimum(G,t)` returns a local minimum $x$ of $G$ with $V(x) <= V(t)$.

  The base case $1 times 1$ is immediate. For the inductive step, let $m$ be the minimum cell on the boundary $B$. The algorithm recurses into a quadrant containing a seed cell $u$, where $u$ is either $t$ or $m$, such that $V(u) <= V(t)$ and $V(u) <= V(b)$ for every boundary cell $b$ in $B$.

  By the induction hypothesis, the recursive call returns a local minimum $x$ inside the chosen quadrant with $V(x) <= V(u) <= V(t)$. Any neighbor of $x$ either also lies inside the same quadrant, where local minimality is guaranteed by the recursive call, or lies on the boundary $B$. Every boundary cell has value at least $V(u)$, and $V(x) <= V(u)$, so no boundary neighbor is smaller than $x$. Therefore $x$ is also a local minimum of the whole current grid.

  #smallcaps[Complexity.]
  At side length $ell$, the middle row and column contain $O(ell)$ cells. The recursion keeps one quadrant with side length about $ell/2$.
  $T(n) = O(n) + O(n/2) + O(n/4) + ... = O(n)$.
  Thus the algorithm uses $O(n)$ calls to `V`.
]

= Divide And Conquer

Break problem into subproblems, solve recursively, combine.

#smallcaps[Mergesort.]
Divide array into two halves, recursively sort, merge. Recurrence:
$T(n) = 2T(n/2) + O(n)$.
Recursion tree: level $i$ has $2^i$ subproblems of size $n/2^i$, total merge cost $n$; height $log n$; total $T(n)=O(n log n)$.

#smallcaps[Master theorem.]
Typical recurrence: $T(n) = a T(n / b) + f(n)$.Master theorem baseline: $n^(log_b a)$.
- If $f(n)$ smaller: $T = Theta(n^(log_b a))$.
- If same up to log factors: balanced. $T(n) = Theta(n^(log_b a) * log n)$
- If $f(n)$ larger and regular: $T = Theta(f(n))$.

= Dynamic Programming

#smallcaps[Basic idea.]
Polynomial number of overlapping subproblems with natural ordering. Optimal solution of a subproblem is built from optimal solutions of smaller subproblems.

#smallcaps[Guideline.]
1. Define subproblem: $OPT(...)$.
2. Write recurrence: e.g. $OPT(i)=max(f(OPT(j)), g(OPT(k)), ...)$ for smaller $j,k$.
3. Set base cases.
4. Compute bottom-up or memoized top-down.
5. Recover solution if needed by storing choices.

#smallcaps[Common states.]
Prefix: $OPT(i)$ first $i$ items. Interval: $OPT(i, j)$ substring/range. Knapsack: $OPT(i, w)$. Tree DP: include/exclude node.

#smallcaps[Proof.]
Induct on subproblem size/order. Show recurrence exhausts all cases of an optimal solution and uses correct smaller optimal values.

DP 常见尝试：
- 从左往右：`f(i)` 表示处理 `i..end`，每次决定当前位置怎么用。例：票价、解码。
- 以某位置结尾：`dp[i]` 表示必须以 `i` 结尾的最优值。例：最长有效括号、递增子序列。
- 前缀匹配：`dp[i][j]` 表示 `s1` 前 `i` 个和 `s2` 前 `j` 个。例：LCS、编辑距离、不同子序列。
- 区间范围：`dp[l][r]` 表示子串/区间 `l..r` 的答案。例：回文子序列、涂色、RNA。
- 背包选择：`dp[i][w]` 表示前 `i` 个物品、容量 `w`。多限制就加维度，如 `dp[i][zero][one]`。
- 网格路径：`dp[i][j]` 表示到达或从 `(i,j)` 出发的答案；若有余数/步数，再加一维。
- 树形/分裂：枚举左边规模、右边规模或切分点。例：二叉树结构数、区间 split。

== Midterm Algorithms Mini-Pack

#smallcaps[Closest pair.]
Sort points by $x$ and $y$. Split by median $x$. Recursively solve left and right; let $delta$ be smaller distance. Only cross pairs inside vertical strip of width $2delta$ can improve. In strip sorted by $y$, compare each point with constant number of following points. Keep sorted lists through recursion for $O(n log n)$.

#smallcaps[FFT / polynomial multiply.]
Coefficient form good for addition; point-value form good for multiplication. Evaluate both polynomials at roots of unity by FFT, multiply values pointwise, inverse FFT to recover coefficients. Recurrence uses:
$A(x)=A_"even"(x^2)+x A_"odd"(x^2)$.
Time $O(n log n)$.

#smallcaps[Grid local minimum.]
Query middle row/column, choose minimum boundary cell `m`, recurse into quadrant containing smaller seed. Recurrence:
$T(n)=T(n/2)+O(n)=O(n)$.
Correctness: recursive local minimum with value no larger than boundary min cannot have smaller neighbor across boundary.

#smallcaps[Linked-list mergesort.]
Split by slow/fast pointers; recursively sort halves; merge by pointer rewiring. Time $O(n log n)$, stack $O(log n)$.

== DP Recurrences

#smallcaps[Weighted interval scheduling.]
Sort jobs by finish time. Let `p(j)` be last job before `j` compatible with `j`.
$OPT(j)=max(v_j+OPT(p(j)), OPT(j-1))$, with $OPT(0)=0$.
Choice: take job $j$ or skip it. Precompute $p(j)$ by binary search; time $O(n log n)$.

#smallcaps[0/1 knapsack.]
$OPT(i, w)$ = max value using first $i$ items within capacity $w$.
If $w_i>w$, $OPT(i, w)=OPT(i-1, w)$; otherwise $OPT(i, w)=max(OPT(i-1, w), v_i+OPT(i-1, w-w_i))$.
Time $O(n W)$, pseudo-polynomial.

#smallcaps[Sequence alignment.]
$OPT(i, j)$ = min cost aligning prefixes $X[1..i]$, $Y[1..j]$.
$OPT(i, j)=min(OPT(i-1, j-1)+alpha(x_i, y_j), OPT(i-1, j)+delta, OPT(i, j-1)+delta)$.
Base $OPT(i, 0)=i delta$, $OPT(0, j)=j delta$. Time $Theta(m n)$.

#smallcaps[RNA secondary structure.]
$OPT(i, j)$ = max pairs in substring $i..j$.
$OPT(i, j)=max(OPT(i, j-1), max_t OPT(i, t-1)+1+OPT(t+1, j-1))$.
where $t$ can legally pair with $j$. Time $O(n^3)$.

#smallcaps[Bellman-Ford DP.]
$OPT(i, v)$ = shortest path from $v$ to $t$ using at most $i$ edges.
$OPT(i, v)=min(OPT(i-1, v), min_{(v,w)} c(v,w)+OPT(i-1, w))$.
After $n-1$ rounds shortest simple paths known. If round $n$ improves, reachable negative cycle exists.

#smallcaps[Maximum-sum increasing subsequence.]
$"dp"[i]$ = max sum of increasing subsequence ending at $i$.
$"dp"[i]=max(a[i], max_(j<i, a[j]<a[i]) "dp"[j]+a[i])$, answer $max_i "dp"[i]$.
Time $O(n^2)$.

#smallcaps[Grouped knapsack.]
Groups, at most one item per group. $"dp"[i][w]$ = max value using first $i$ groups under capacity $w$.
$"dp"[i][w]=max("dp"[i-1][w], max_("item " (c,v) " in group " i, c<=w) "dp"[i-1][w-c]+v)$.
Time $O(W K)$ where $K$ total items.

#smallcaps[Interval painting / strange printer.]
$f[i][j]$ = min operations to paint substring $s[i..j]$.
$f[i][i]=1$. If $s[i]==s[j]$, then $f[i][j]=f[i][j-1]$; otherwise $f[i][j]=min_(i<=k<j) f[i][k]+f[k+1][j]$.
Time $O(n^3)$.

#example(title: "找递增子序列的最大可能元素和，不是最长长度。")[
  #smallcaps[DP state.]
  Let `dp[i]` be the maximum sum of an increasing subsequence that ends at index `i`.

  #smallcaps[Transition.]
  Base case: the subsequence contains only `a[i]`, so `dp[i] = a[i]`. Transition case: for every `j < i`, if `a[j] < a[i]`, then `a[i]` can be appended to an increasing subsequence ending at `j`:
  ```
  dp[i] = max(dp[i], dp[j] + a[i])
  ```
  Complete recurrence:
  ```
  dp[i] = max(a[i], max over 0 <= j < i and a[j] < a[i] of dp[j] + a[i])
  ```
  The answer is `max_i dp[i]`.

  #smallcaps[Pseudocode.]
  ```
  MaximumSumIncreasingSubsequence(a):
      n = length(a)
      dp = array of size n
      for i = 0 to n - 1:
          dp[i] = a[i]
          for j = 0 to i - 1:
              if a[j] < a[i]:
                  dp[i] = max(dp[i], dp[j] + a[i])
      ans = dp[0]
      for i = 1 to n - 1: ans = max(ans, dp[i])
      return ans
  ```

  #smallcaps[Correctness.]
  The state `dp[i]` stores the maximum sum of any increasing subsequence ending at position `i`. Such a subsequence either consists only of `a[i]`, giving sum `a[i]`, or is formed by appending `a[i]` to an increasing subsequence ending at some earlier position `j`, where `a[j] < a[i]`. Since the algorithm examines all valid previous positions `j` and takes the maximum among all possibilities, `dp[i]` correctly computes the best sum for an increasing subsequence ending at `i`. Finally, the optimal increasing subsequence may end at any position, so taking the maximum over all `dp[i]` gives the correct answer.

  #smallcaps[Complexity.] `O(n^2)` time and `O(n)` space.
]

= Network Flow

Flow network: directed graph $G=(V,E)$, source $s$, sink $t$, capacities $c(e)>=0$.

Flow constraints: capacity $0<=f(e)<=c(e)$ and conservation at all $v != s,t$.

Residual graph $G_f$: forward residual capacity $c(e)-f(e)$; backward residual capacity $f(e)$.

Augmenting path: $s-t$ path in residual graph. Bottleneck = minimum residual capacity on path.

#smallcaps[Ford-Fulkerson.]
Initialize $f(e)=0$. While residual graph has augmenting path $P$, augment along $P$ by bottleneck. Stop when no augmenting path.

#smallcaps[Max-flow/min-cut.]
Equivalent conditions:
1. There exists cut $(A,B)$ with $v(f)=cap(A, B)$.
2. $f$ is a max flow.
3. There is no augmenting path in residual graph.

Proof when no augmenting path: let $A$ be vertices reachable from $s$ in $G_f$. Then $t " notin " A$. Forward edges $A -> B$ saturated; backward edges carry zero cancelable flow. Thus flow value equals cut capacity.

== Flow Applications

#smallcaps[Bipartite matching.]
Source to each left vertex cap 1; left-right edges cap 1; right vertices to sink cap 1. Integral max flow corresponds to matching. Perfect matching iff flow value equals left side size.

#smallcaps[Edge-disjoint paths.]
Set every edge capacity 1. Max number of edge-disjoint $s-t$ paths equals max flow value.

#smallcaps[Circulation with demands.]
For edge lower bound $l_e <= f_e <= c_e$, send forced $l_e$ first: residual capacity $c_e-l_e$, adjust vertex balances by lower bounds. Add super-source/sink for demands/supplies. Feasible iff all required super-source edges saturated.

#smallcaps[Project selection.]
Positive profit project: edge $s -> v$ with capacity profit. Negative profit/cost: edge $v -> t$ with capacity cost. If $v$ requires $w$, add infinite edge $v -> w$. Min cut chooses closed set maximizing profit.

#smallcaps[Image segmentation.]
Pixel-source/sink edges encode label preference; neighboring-pixel edges encode separation penalty. Min cut gives best foreground/background labeling.

== More Flow Models

#smallcaps[Course registration.]
Source -> student $i$ capacity $k_i$; eligible pair student $i$ -> course $j$ capacity 1; course $j$ -> sink capacity $c_j$. Integral max flow gives assignments.

#smallcaps[Scheduling by days/events.]
For feasibility in $D$ days, source -> weekday $d$ capacity $"cnt"[d] dot e$; weekday -> event if available; event -> sink capacity requirement $c_i$. Feasible iff max flow equals total demand. Binary search smallest $D$ because feasibility monotone.

#smallcaps[Baseball elimination.]
Assume team $z$ wins all remaining. Source -> game nodes for remaining games among other teams; game -> two teams; team -> sink capacity max allowed wins before exceeding $z$. If all game capacities saturated, not eliminated. Min cut gives certificate.

#example(title: "选课注册网络流")[
  #smallcaps[题意.] 学生只能选符合资格的课；学生 `i` 最多选 `k_i` 门；课程 `j` 容量为 `c_j`。求最大合法选课匹配数。

  #smallcaps[Flow model.]
  Create a directed graph with source `S`, sink `T`, one node for each student, and one node for each course.

  Edges:
  - Student capacity constraint: add `S -> student i` with capacity `k_i`. This guarantees student `i` takes at most `k_i` courses.
  - Eligibility constraint: if student `i` is eligible for course `j`, add `student i -> course j` with capacity `1`. This allows a student-course pair at most once.
  - Course capacity constraint: add `course j -> T` with capacity `c_j`. This guarantees course `j` admits at most `c_j` students.

  #smallcaps[Answer.]
  The maximum number of valid student-course assignments equals the value of the maximum `S-T` flow. Since capacities are integral, an integral maximum flow exists. To extract the actual registration result, inspect each edge `student i -> course j`; flow `1` on this edge means student `i` registers for course `j`. Edmonds-Karp, Dinic, or any standard max-flow algorithm can compute the flow.

  #smallcaps[Correctness.]
  The source edges enforce each student's course limit. Eligibility edges allow only valid student-course pairs and capacity `1` prevents duplicate enrollment in the same course. Course-to-sink edges enforce course capacities. Thus every feasible flow is a valid registration plan, and every valid registration plan defines a flow of the same value.
]

= Complexity And Reductions

== Complexity Vocabulary

- *P*: decision problems solvable in polynomial time.
- *NP*: yes-instances have polynomial-size certificates verifiable in polynomial time.
- *co-NP*: complements of NP languages; no-instances have short disqualifiers.
- *NP-hard*: 问题 $Y$ 满足 对任意 $X in "NP"$ 都有 $X reducesto Y$ (`NP` 里的任何问题都能翻译成$Y$ 。)
- *NP-complete*: 问题 $Y$ 满足 $Y in "NP"$；对任意 $X in "NP"$ 都有 $X reducesto Y$ ($Y$ 自己能被快速验证，同时 `NP` 里的任何问题都能翻译成它。)$"NP-complete" = "NP" inter "NP-hard"$

Known relation:
$P subset NP subset PSPACE subset EXPTIME$.
$P=NP$? is open. If any NP-complete problem is in $P$, then $P=NP$.
若 $Y$ 是 NP-complete，则 $Y$ 可在多项式时间内求解，当且仅当 `P = NP`。

#smallcaps[Decision version.]
Complexity theory usually asks yes/no questions. Many search/optimization versions self-reduce to decision versions by repeatedly calling a decision oracle.

== Polynomial Reduction

To prove target problem $A$ hard, reduce from known hard problem $B$:
$B reducesto A$.
Meaning: if we can solve $A$, then we can solve $B$; hence $A$ is at least as hard as $B$.

#smallcaps[Karp reduction.]
Given instance $b$ of $B$, construct one instance $a=f(b)$ of $A$ in polynomial time such that:
$b " is YES for " B <==> a " is YES for " A$.

#smallcaps[NP-complete proof.]
1. Show $A in NP$: certificate + verifier.
2. Choose known NP-complete $B$.
3. Construct $f(b)$ in polynomial time.
4. Prove both directions of iff.
Conclusion: $A$ is NP-hard and in NP, so NP-complete.

#smallcaps[Common mistakes.]
Wrong direction; missing one direction; proving intuition but not certificate/verifier; forgetting construction time.

== NP-complete Problems

#smallcaps[SAT.] 给一个布尔公式，问能否给变量赋值让整个公式为真。
Given Boolean formula $phi$, decide whether there exists truth assignment $alpha$ such that $phi(alpha)="true"$. Certificate: $alpha$. Use as the first satisfiability source; constraints are encoded by clauses/gadgets.

#smallcaps[3-SAT.] SAT 的标准版本；公式是 CNF，每个 clause 恰好 3 个 literal。
Given $phi=C_1 and ... and C_m$, where each $C_i$ has exactly three literals, decide whether some assignment satisfies all clauses. Certificate: assignment. Common use: *variables become choices; clauses become demands that at least one literal choice must satisfy*.

#smallcaps[Independent Set.]
在图里选至少 $k$ 个点，要求选中的点两两之间没有边；适合表示“冲突不能共存”。
Given graph $G=(V,E)$ and integer $k$, decide whether there exists $S subset.eq V$ with $|S|>=k$ and for all $(u,v) in E$, not both $u,v in S$. Certificate: vertex set $S$. Use when feasible objects are choices and edges encode conflicts.

#smallcaps[Vertex Cover.]
在图里选至多 $k$ 个点，要求每条边至少被一个选中端点覆盖；适合表示“每个冲突/需求必须被处理一次”。
English form: Given graph $G=(V,E)$ and integer $k$, decide whether there exists $C subset.eq V$ with $|C|<=k$ such that for every edge $(u,v) in E$, $u in C$ or $v in C$. Certificate: vertex set $C$.
Key relation: $S " independent" <==> V-S " vertex cover"$, so $(G,k)_"IS" -> (G, |V|-k)_"VC"$.

#smallcaps[Set Cover.]
给 universe 和若干集合，问能否用不超过 $k$ 个集合覆盖所有元素；适合表示“需求元素必须被某个选择覆盖”。
Given universe $U$, sets $S_1,...,S_m subset.eq U$, and integer $k$, decide whether there exists index set $I$ with $|I|<=k$ and $union_(i in I) S_i = U$. Certificate: chosen set indices. Use when choices cover demands; VC reduces by setting $U=E$ and one set per vertex.

#smallcaps[Clique.] 在图里选至少 $k$ 个点，要求任意两点之间都有边；适合表示“所有选择必须互相兼容”。
Given graph $G=(V,E)$ and integer $k$, decide whether there exists $K subset.eq V$ with $|K|>=k$ and every pair in $K$ is adjacent. Certificate: vertex set $K$. Key relation: clique in $G$ iff independent set in complement graph $bar(G)$.

#smallcaps[Hamiltonian Cycle / Path.]
问图中是否存在经过每个顶点恰好一次的环/路径；适合表示“必须按一个全局顺序使用所有组件”。
Given graph $G=(V,E)$, decide whether there is a cycle/path visiting every vertex exactly once. Certificate: ordered vertex sequence. Use when construction forces a traversal through gadgets; correctness often shows traversal direction encodes assignment.

#smallcaps[TSP decision.]
旅行商问题的 decision version；问是否有总长度不超过 $D$ 的 tour。
Given complete weighted graph with distances $d(u,v)$ and threshold $D$, decide whether there exists a tour visiting every city once with total length $<=D$. Certificate: tour order. Standard source/target link: Hamiltonian Cycle $<=_p$ TSP by distance 1 for original edges, 2 for nonedges, threshold $D=n$.

#smallcaps[3-Color.]
给图染 3 种颜色，要求相邻点颜色不同；适合用颜色表示 truth values 或状态。
Given graph $G=(V,E)$, decide whether there exists coloring $c:V->{1,2,3}$ such that $c(u)!=c(v)$ for every edge $(u,v)$. Certificate: color assignment. Common gadget: triangle fixes three roles $T,F,B$; literal vertices choose $T/F$; clause gadget forbids all false.

#smallcaps[Subset Sum.]
给一组正整数和目标 $T$，问能否选出若干数和恰好为 $T$；适合数位/容量等“等式约束”。
Given positive integers $a_1,...,a_n$ and target $T$, decide whether there exists $I subset.eq {1,...,n}$ such that $sum_(i in I) a_i = T$. Certificate: index set $I$. Use for numeric reductions; digit gadgets require large base so no carries.

== Reduction Gadgets

#smallcaps[3-SAT to Independent Set.]
For each clause, make 3 vertices for its literals and connect them as a triangle. Connect complementary literals across clauses. Set $k=#"clauses"$.

Triangle forces at most one literal per clause. Since $k$ equals number of clauses, an independent set of size $k$ chooses exactly one literal from each clause. Conflict edges prevent choosing both $x$ and $not x$. Chosen literals define a consistent satisfying assignment.

#smallcaps[Vertex Cover to Set Cover.]
Universe $U=E$. For each vertex $v$, create set $S_v$ containing incident edges. Choosing vertices covering all edges iff choosing corresponding sets covering $U$.

#smallcaps[Hamiltonian to TSP.]
Cities are vertices. Distance 1 for graph edges, 2 for nonedges. Threshold $D=n$. Any tour has $n$ edges, each at least 1; length at most $n$ iff all used adjacencies are original edges.

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
Input $(G,k) -> (G, |V|-k)$. If $S$ independent, then every edge has at least one endpoint outside $S$, so $V-S$ is a vertex cover. If $C$ is vertex cover, no edge has both endpoints in $V-C$, so $V-C$ is independent.

#smallcaps[Clique to Independent Set.]
Map graph `G` to complement `bar(G)`. A set is clique in `G` iff it is independent in `bar(G)`.

#smallcaps[3-SAT to 3-Color.]
Create triangle $T,F,B$. Literal vertices connect to $B$, so they use colors $T/F$. Connect $x$ and $not x$. Clause gadget enforces not all three literals false.

#smallcaps[Dominating Set from Vertex Cover.]
For each edge $e={u,v}$, add new vertex $x_e$ adjacent to $u,v$. A vertex cover dominates all edge vertices; any dominating set can replace $x_e$ by an endpoint; then each $x_e$ forces one endpoint selected, giving vertex cover.

== PSPACE Snapshot

$PSPACE$: decision problems solvable using polynomial space. $P subset NP subset PSPACE$.

QSAT has alternating quantifiers:
$exists x_1 forall x_2 exists x_3 ... Phi$.
Recursive evaluation uses exponential time but polynomial stack space.

Game/planning signal: "first player has winning strategy", "for all opponent responses", "configuration graph exponentially large". Show membership by DFS over states/strategy tree storing only current state and recursion depth. Show hardness by reducing from QSAT, mapping `exists/forall` choices to players.

== HW3 P1

#smallcaps[题意.] 给定通信 links $L={ell_1,...,ell_n}$、冲突对 $I subset.eq L times L$ 和整数 $k$。问是否存在 $L' subset.eq L$，使 $|L'|>=k$，且没有任何一个冲突对的两个端点都在 $L'$ 中。证明 NP-complete。

#smallcaps[NP.] Given $L'$, build a selected-link Boolean array in $O(|L|)$ and scan every pair $(ell_i,ell_j) in I$ to ensure not both endpoints are selected. Verification time $O(|L|+|I|)$.

#smallcaps[Reduction from Independent Set.] *Given $(G=(V,E),k)$, create one link $ell_i$ for every vertex $v_i in V$*:
$L={ell_i | v_i in V}$.
*For every edge $(v_i,v_j) in E$, add interfering pair $(ell_i,ell_j)$*:
$I={(ell_i,ell_j) | (v_i,v_j) in E}$.
Keep the same $k$. Construction time $O(|V|+|E|)$.

#smallcaps[Correctness.] If $S subset.eq V$ is independent and $|S|>=k$, let $L'={ell_i | v_i in S}$. No edge has both endpoints in $S$, so no interfering pair has both links in $L'$, and $|L'|=|S|>=k$.
Conversely, if feasible $L'$ has $|L'|>=k$, let $S={v_i | ell_i in L'}$. *If two vertices in $S$ were adjacent, the corresponding links would form an interfering pair inside $L'$, contradiction.* Thus $S$ is independent and $|S|=|L'|>=k$. Hence iff; with NP membership, NP-complete.

== HW3 P2

#smallcaps[题意.] 校园巡逻点放置问题：给定无向图 $G=(V,E)$ 和整数 $k$，问是否存在 $S subset.eq V$，$|S|<=k$，使每个顶点要么在 $S$ 中，要么与某个 $S$ 中顶点相邻。证明 NP-complete。

#smallcaps[NP.] Given $S$, check $|S|<=k$ and scan adjacency lists to mark vertices monitored by $S$. Time $O(|V|+|E|)$.

#smallcaps[Reduction from Vertex Cover.] Given $(G=(V,E),k)$, construct $G'$. Keep all original vertices and edges. *For every edge $e=(u,v) in E$, add a new vertex $x_e$ and edges $(x_e,u),(x_e,v)$.* Keep parameter $k$. Size/time $O(|V|+|E|)$. Isolated original vertices can be removed before the reduction, since they do not affect vertex cover and would only force trivial patrol points.

#smallcaps[Correctness.] If $C$ is a vertex cover of $G$ with $|C|<=k$, use the same $C$ as patrol points. Every new $x_e$ is adjacent to an endpoint of $e$ in $C$; every non-isolated original vertex not in $C$ has an incident edge whose other endpoint must be in $C$; vertices in $C$ monitor themselves. Thus $C$ dominates $G'$.
Conversely, let $S$ dominate $G'$, $|S|<=k$. *Replace any selected new vertex $x_e$ for $e=(u,v)$ by either endpoint*, obtaining $C subset.eq V$ with $|C|<=|S|<=k$. For every original edge $e=(u,v)$, *vertex $x_e$ is adjacent only to $u,v$*, so domination of $x_e$ forces at least one endpoint into $C$. Thus $C$ is a vertex cover. Hence iff and NP-complete.

== HW3 P3

#smallcaps[题意.] Monotone 3-SAT：每个 clause 恰有三个 literal，且每个 clause 要么全正、要么全负。问公式是否可满足。证明 NP-complete。

#smallcaps[NP.] A truth assignment is checked by evaluating every 3-literal clause in $O(m)$.

#smallcaps[Reduction from 3-SAT.] For a 3-SAT formula $phi=C_1 and ... and C_m$, keep already monotone clauses. *For each mixed clause introduce fresh $u_i$*:
- If $C_i=(x or y or not z)$, *replace it by $(x or y or u_i)$ and $(not z or not u_i or not u_i)$*.
- If $C_i=(x or not y or not z)$, *replace it by $(x or u_i or u_i)$ and $(not y or not z or not u_i)$*.
Every new clause is monotone and has exactly three literals; each old clause creates at most two clauses and one variable, so polynomial size.

#smallcaps[Correctness, forward.] Suppose $phi$ is satisfied by assignment $alpha$. For $(x or y or not z)$: if $x or y$ is true, set $u_i="false"$; otherwise $not z$ is true and set $u_i="true"$. Both replacement clauses hold. For $(x or not y or not z)$: if $x$ is true, set $u_i="false"$; otherwise at least one of $not y,not z$ is true and set $u_i="true"$. Thus $alpha$ extends to satisfy $phi'$.

#smallcaps[Correctness, backward.] Suppose $phi'$ is satisfied. Restrict to original variables. Already monotone clauses are unchanged. For $(x or y or not z)$, if the original clause were false, then $x="false",y="false",not z="false"$. *The first new clause forces $u_i="true"$, while the second forces $u_i="false"$, contradiction.* For $(x or not y or not z)$, if false, then $x="false",not y="false",not z="false"$; the first new clause forces $u_i="true"$, the second forces $u_i="false"$. Hence every original clause is true. Therefore $phi$ satisfiable iff $phi'$ satisfiable; NP-complete.

== HW3 P4

#smallcaps[题意.] Two-bin partition：给定 items $I$，每个 item 有正整数大小 $s(i)$，两个容量 $B_1,B_2$。问能否把 $I$ 划分为 $I_1,I_2$，使 $sum_{i in I_1}s(i)<=B_1$ 且 $sum_{i in I_2}s(i)<=B_2$。证明 NP-complete。

#smallcaps[NP.] Given $I_1,I_2$, scan items to verify they form a partition and compute both sums. Time $O(|I|)$.

#smallcaps[Reduction from Subset Sum.] Given positive integers $a_1,...,a_n$ and target $T$, let $A=sum_{j=1}^n a_j$. If $T>A$, map to any fixed NO instance; otherwise create item $i_j$ with $s(i_j)=a_j$, *set $B_1=T$ and $B_2=A-T$*.

#smallcaps[Correctness.] If subset $S subset.eq {1,...,n}$ has $sum_{j in S}a_j=T$, put $I_1={i_j | j in S}$ and put all remaining items into $I_2$. Then sums are $T=B_1$ and $A-T=B_2$.
Conversely, if a feasible partition exists, then
$sum_{i in I_1}s(i)+sum_{i in I_2}s(i)=A$.
*The constraints give the left side $<=T+(A-T)=A$, so both constraints are tight*; in particular $sum_{i in I_1}s(i)=T$. Thus the corresponding numbers solve Subset Sum. Hence iff and NP-complete.

== HW3 P5

#smallcaps[题意.] 给定一个 $m times n$ grid，每个格子为空、黑棋或白棋。允许删除部分棋子，问能否使每行至少剩一个棋子，且每列不能同时含黑白两色棋子。证明 NP-complete。

#smallcaps[NP.] Given remaining pieces, scan the grid to check each row has a piece and each column is monochromatic. Time $O(m n)$.

#smallcaps[Reduction from 3SAT.] Given 3CNF $Phi$ with clauses $C_1,...,C_m$ and variables $x_1,...,x_n$, build an $m times n$ grid. *Row $i$ corresponds to $C_i$, column $j$ to $x_j$.* If $x_j$ appears positively in $C_i$, put a black piece in cell $(i,j)$; if $not x_j$ appears in $C_i$, put a white piece; otherwise leave it empty. Polynomial construction.

#smallcaps[Correctness.] If $Phi$ is satisfiable, for each variable column $j$: *if $x_j="true"$, remove all white pieces; if $x_j="false"$, remove all black pieces.* Columns become single-color. Since every clause has a true literal, each row keeps at least one corresponding piece.
Conversely, from any valid grid choose assignment: if column $j$ has a remaining black piece set $x_j="true"$; if it has a white piece set $x_j="false"$; if empty choose arbitrarily. *Column single-color makes the assignment well-defined; nonempty rows make clauses satisfied.* Hence iff and NP-complete.

== FPT

For NP-complete problems, cannot expect polynomial-time exact algorithms for arbitrary instances. FPT sacrifices arbitrary instances by using a small parameter.

Definition:
$"time" = f(k) dot poly(n)$.
The exponential part depends only on parameter $k$, not on input size $n$.

#smallcaps[Brute force is not FPT.]
Trying all size-$k$ subsets takes:
$binom(n, k) dot O(k n) approx O(k n^(k+1))$.
This is not FPT because the exponent of $n$ depends on $k$.

#smallcaps[Small Vertex Cover.]
Given $(G,k)$, choose any edge $(u,v)$. Any vertex cover must include $u$ or $v$.
```
VC(G,k):
  if E empty: return YES
  if k=0: return NO
  choose edge (u,v)
  return VC(G-u,k-1) or VC(G-v,k-1)
```
Search tree has depth at most $k$, branching factor 2:
$O(2^k dot poly(n))$.
Better than brute force $n^k$ when $k$ small.

#smallcaps[High-degree rule.]
If degree of $v$ is greater than $k$, then every size-$k$ cover must include $v$; otherwise all its neighbors must be selected, exceeding budget.

#smallcaps[Wavelength / circular arc coloring.]
Paths on a ring become circular arcs. Brute force $k^m$ colorings. FPT idea: scan ring phases; state records colors of arcs crossing current point. If at most $k$ arcs pass a point, at most $k!$ consistent colorings per phase. Running time:
$f(k) dot poly(m, n)$.
Practical for small $k$; polynomial if $k=O(log n / log log n)$.

= Local Search

Template: define search space, neighbor relation, improvement rule, stopping condition.

Proof goals: every step improves potential/objective; finite states imply termination; local optimum gives exact/approx/equilibrium guarantee.

#smallcaps[Vertex Cover deletion.]
Start with $S=V$. If removing one vertex keeps a vertex cover, remove it. Terminates in at most $n$ removals. Only one-delete local optimum, not necessarily global optimum.

#smallcaps[Max-Cut local search.]
Partition vertices into $(A,B)$. If flipping one vertex increases cut size, flip it. At local optimum, for every vertex $v$:
$cross(v) >= same(v)$.
Summing over all vertices:
$2 dot "cut" >= 2 dot "internal"$, $"total edges" <= 2 dot "cut"$, $OPT <= "total edges"$, hence $"cut" >= OPT/2$.
So single-flip local optimum is a $2$-approximation.

#smallcaps[Big improvement flips.]
To bound iterations, accept only sufficiently large improvement. This prevents many tiny gains; approximation weakens to about $2+epsilon$.

== Local Search Details

#smallcaps[Generic termination.]
If every move strictly improves an integer objective bounded by polynomial/exponential range and state space finite, algorithm terminates. But termination need not be polynomial unless improvement size or number of states is bounded.

#smallcaps[Max-Cut weighted.]
For weighted graph, same proof uses weights:
$"cross weight"(v) >= "same-side weight"(v)$.
Sum over vertices; each edge counted twice on one side of inequality. Get $"cut" >= "total_weight"/2 >= OPT/2$.

#smallcaps[Best response.]
Best response dynamics may cycle if no potential exists. In fair cost sharing, Rosenthal potential is an exact potential, so every selfish improvement decreases the same global function.

== Nash / Cost Sharing

Multicast routing: directed graph with edge costs $c_e$, source $s$, agents with terminals $t_j$. Agent $j$ chooses path $P_j$. If $x_e$ agents use edge $e$, each pays:
$c_e / x_e$.

Nash equilibrium: no agent can lower its own cost by unilaterally switching path. Social optimum minimizes total cost of used edges. They need not be equal.

Rosenthal potential:
$Phi(P)=sum_e c_e dot H(x_e)$, where $H(x)=1+1/2+...+1/x$.
When one agent changes path, its cost change equals $Delta Phi$. Therefore strict best response strictly decreases $Phi$; finite strategy space implies convergence to Nash.

Bounds:
$C(P) <= Phi(P) <= H(k) C(P)$.
Starting from social optimum and following best responses gives a Nash equilibrium with cost at most $H(k)$ times optimum. Price of stability $<=H(k)$.

= Amortized Analysis

Amortized analysis is not average-case. It bounds total cost of any operation sequence.

Methods:
- Aggregate: directly bound total cost.
- Accounting: charge operations credits; store credit on objects.
- Potential: store credit in state function.

Potential formula:
$hat(c_i)=c_i + Phi(D_i)-Phi(D_(i-1))$.
If $Phi(D_0)=0$ and $Phi(D_i)>=0$, then:
$sum "actual" <= sum "amortized"$.

#smallcaps[Protocol.]
Show a single call can be large if asked. Identify objects causing large work. Show each object is created and consumed $O(1)$ times. For potential/accounting, choose credit matching stored future work.

== Amortized Templates

#smallcaps[Stack multipop.]
Each item pushed once and popped at most once. Aggregate total $O(m)$. Potential $Phi=|S|$: push actual 1, $Delta Phi=1$; pop/multipop actual $k$, $Delta Phi=-k$.

#smallcaps[Binary counter.]
Increment flips $t$ trailing 1s to 0 and one 0 to 1. Actual $t+1$. Potential $Phi=#"1 bits"$; $Delta Phi <= 1-t$; amortized $<=2$.

#smallcaps[Dynamic table.]
Doubling table: expansions copy sizes $1,2,4,...$, total copy cost $O(n)$ over $n$ inserts. Potential can be $Phi=2 dot "num" - "size"$ when load at least $1/2$.

#smallcaps[Fibonacci heap facts.]
Potential:
$Phi = #"trees" + 2 #"marked nodes"$.
Amortized: insert/find-min/union/decrease-key $O(1)$, delete-min/delete $O(log n)$. Marked nodes pay for cascading cuts.

== HW4 P1. Lazy Disk-Write Queue(*potential method*)

#smallcaps[题意.] Lazy disk-write queue：`Modify(i)` 设置 `dirty[i]=true` 并把 page ID $i$ 加入 FIFO queue；`FlushOne()` 从队首删除 stale entries，遇到 dirty page 就写回并清 dirty。要求构造单次 worst case、证明任意 $m$ 次总成本 $O(m)$，并用 potential method 证摊还 $O(1)$。

*(a)* Execute $k$ operations `Modify(1)`. Then $Q$ contains $k$ copies of page ID $1$ and `dirty[1]=true`. The first `FlushOne()` removes one copy, writes page $1$, and sets `dirty[1]=false`. *The remaining $k-1$ copies are stale.* A second `FlushOne()` removes all $k-1$ stale entries before returning $0$, so this call costs $Theta(k)$. At that point $m=k+2$, hence $Theta(m)$.

*(b)* *Each `Modify` inserts one queue entry; each inserted entry can be removed at most once.* Thus over any $m$ operations, total queue insertions and deletions are both $O(m)$. Other work per external operation is constant except work charged to deleted entries, and each successful flush writes at most one page. Duplicate page IDs do not break the bound: every duplicate is a distinct queue entry created by a distinct `Modify` and removed at most once. Total time $O(m)$.

*(c)* *Let $Phi=C |Q|$* for sufficiently large constant $C$. Initially $Phi=0$ and always $Phi>=0$. For `Modify(i)`, actual cost $O(1)$ and $|Q|$ increases by $1$, so $Delta Phi=C$ and amortized cost $O(1)$. For `FlushOne()`, if it deletes $k$ entries, actual cost is $O(k)+O(1)$ and *$Delta Phi=-C k$ pays for all deleted stale entries*. Hence amortized $O(1)$. Empty queue case is also $O(1)$.

== HW4 P2. Triangular Calibration Monitor(*Aggregate Analysis && Accounting method*)

#smallcaps[题意.] Triangular calibration：每次 `InsertSample` 基础成本为 $1$。当插入总数 $N$ 变成三角数 $T_q=1+...+q=q(q+1)/2$ 时触发第 $q$ 次 calibration，成本为 $q$。求前 $n$ 次插入的 calibration 次数、总成本和 accounting 摊还收费。

*(a)* During first $n$ insertions, *the number of calibrations is the largest integer $q$ with $T_q<=n$*, i.e.
$q=floor((sqrt(8n+1)-1)/2)$.

*(b)* Base insertion cost is $n$. If $q$ calibrations occur, *their total cost is $1+2+...+q=T_q<=n$*. Total cost $<=n+T_q<=2n=O(n)$, so amortized insertion cost is $O(1)$.

*(c)* *Charge each `InsertSample` $2$ units.* One pays the insertion, one is stored as credit. After the $q$-th calibration, the next one costs $q+1$; *there are exactly $T_{q+1}-T_q=q+1$ insertions* before it, saving enough credits. Credits never go negative; amortized charge is $2$.

== HW4 P3. Archive with Tombstone Compaction

#smallcaps[题意.] Archive with tombstones：数组 entry 是 live article 或 tombstone。`Add` 追加 live article；`Remove` 若成功则标记 tombstone；每次 `Remove` 后若 tombstones 数严格大于 live articles 数，则自动 `Compact()` 扫描数组、复制 live articles、丢弃 tombstones。求单次 worst case、总成本和 potential 摊还界。

*(a)* A `Remove` can make tombstones strictly greater than live articles, triggering `Compact()`. If the array length immediately before compaction is $n$, compaction scans the whole array and copies live articles, so *this single `Remove` can cost $Theta(n)$*.

*(b)* Consider one compaction. Let $D$ be tombstones and $L$ live articles just before compaction. Trigger condition gives *$D>L$*, so array length $D+L < 2 D$. Compaction scans $D+L$ entries and copies $L$ live articles, cost *$(D+L)+L=D+2 L < 3 D$*. These $D$ tombstones were created by $D$ effective `Remove` operations since the previous compaction, so charge this compaction to those removals. Basic `Add`/`Remove` costs over $m$ operations are $O(m)$, and all compactions cost $O(m)$ total.

*(c)* Let $D$ be current tombstone count and *$Phi=C D$*, e.g. $C=4$. Initially $0$, always nonnegative. `Add` and ineffective `Remove` do not change $D$: amortized $O(1)$. Effective `Remove` without compaction has actual $O(1)$ and $Delta Phi=C$: amortized $O(1)$. If an effective `Remove` triggers compaction, let $D,L$ be counts after marking but before compaction. Then $D>L$ and compaction cost $<3 D$. Before this remove there were $D-1$ tombstones; after compaction there are $0$, so *$Delta Phi=0-C (D-1)$*. With $C>=4$, the potential drop pays for compaction up to a constant. Thus amortized $O(1)$.

= Randomized Algorithms

- *Las Vegas* 总是输出正确答案，但运行时间是随机变量。分析目标是期望运行时间。
- *Monte Carlo* 运行时间通常固定或有确定上界，但可能输出错误答案。分析目标是错误概率。

Event probability: $Pr[A]$. Independence:
$Pr[A " and " B] = Pr[A] Pr[B]$.

Indicator for event $E$:
$X_E=1$ if $E$ occurs, else $0$; $E[X_E]=Pr[E]$.

Linearity:
$E[X_1+...+X_n]=E[X_1]+...+E[X_n]$.
No independence required.

== Geometric Distribution(*Las Vegas*)

Repeated independent trials until first success. Each trial succeeds with probability $p$. Let $R$ be number of trials until first success.

$Pr[R = k] = (1 - p)^(k - 1) * p$

$E[R] = 1 / p$ Derivation: $E = p * 1 + (1 - p) * (1 + E)$

$(1 - p)^t <= e^(-p t)$:  $Pr[R > t] = (1 - p)^t <= e^(-p t)$

如果每次成功概率是 $p$，重复 $t$ 次。全部失败概率是： $(1 - p)^t$ 如果我们想让失败概率不超过 $delta$，需要大概： $t >= ln(1/delta) / p$

== Tail Bounds

Use more assumptions for stronger concentration.

Markov: for $X>=0$, $Pr[X>=a] <= E[X]/a$.
Rough one-sided bound from expectation only.

Chebyshev: finite variance, $Pr[|X-E[X]|>=a] <= Var[X]/a^2$.
Two-sided deviation without distribution assumptions.

Chernoff: independent 0/1 indicators, $X=sum X_i$, $mu=E[X]$.
For $0<=delta<=1$:
$Pr[X >= (1+delta) mu] <= e^(-mu delta^2/3)$, and $Pr[X <= (1-delta) mu] <= e^(-mu delta^2/2)$.
For $delta>1$:
$Pr[X >= (1+delta) mu] <= e^(-mu delta ln delta/3)$.

Union bound: no independence needed.
$Pr[union_i E_i] <= sum_i Pr[E_i]$.
Use: first bound failure for one fixed object, then extend to any object fails.

=== Tail Bound Use

#smallcaps[Markov.]
Use when only know expectation and variable nonnegative. Example: $Pr[X>=2E[X]]<=1/2$.

#smallcaps[Chebyshev.]
Use when variance known. For $a>0$, deviation by at least $a$ has probability at most $Var[X]/a^2$.

#smallcaps[Chernoff.]
Use for independent indicator sum. To make upper-tail probability $<=epsilon$, ensure:
$mu delta^2/3 >= ln(1/epsilon)$.
for $0<=delta<=1$.

#smallcaps[Union bound.]
For all machines/processes/vertices:
$Pr["any bad"] <= sum Pr["one fixed bad"]$.
No independence needed.

== Hashing / Bloom / Fingerprinting

#smallcaps[Universal hashing.]
Choose hash function $h$ uniformly from family $cal(H)$. For any $x != y$:
$Pr_h[h(x)=h(y)] <= 1/m$.
Use indicators to bound expected collisions or chain length.

#smallcaps[Perfect hashing.]
Static set, two levels. First hash partitions keys into buckets of sizes $n_i$; second-level table for bucket $i$ has size $n_i^2$ and is rehashed until collision-free. Since $E[sum_i n_i^2]=O(n)$, expected total space is $O(n)$ with worst-case $O(1)$ lookup.

#smallcaps[Bloom filter.]
Array of $m$ bits, $k$ hash functions. Insert sets all $k$ positions to 1; query returns yes iff all $k$ positions are 1.
No false negatives. False positives possible:
$Pr["FP"] approx (1-e^(-k n / m))^k$ after $n$ inserts.
Ordinary Bloom filters cannot delete safely; use counting Bloom filters for deletion.

#smallcaps[Fingerprinting.]
For string equality, compare compact randomized fingerprints instead of full strings. If two inputs differ, collision probability is small because the random modulus/evaluation point must hit a limited set of bad choices. Monte Carlo: one-sided error if equal fingerprints are accepted as equal.

== Random Analysis Patterns

#smallcaps[Max-Cut.]
Object = edge. Indicator = edge crosses. Probability = 1/2. Sum over edges.

#smallcaps[MAX-3SAT.]
Object = clause. Random assignment. A 3-literal clause is unsatisfied with prob $1/8$, satisfied with prob $7/8$. Expected satisfied clauses $7m/8$.

#smallcaps[Randomized quicksort.]
Object = pair `(i,j)`. Pair compared iff first pivot among `z_i,...,z_j` is one endpoint.
$Pr["compare " i,j]=2/(j-i+1)$, and $E["comparisons"]=sum_{i<j} 2/(j-i+1)=O(n log n)$.

#smallcaps[Karger min-cut.]
Fix min cut of size $k$. At $n'$ supernodes, min degree at least $k$, so edges $>= k n'/2$; probability of contracting cut edge $<=2/n'$. Survival probability:
$prod_{i=n " down to " 3} (1-2/i)=2/(n(n-1))$.
Repeat $O(n^2 log(1/delta))$ times for failure $<=delta$.

== Probability Quick Facts

#smallcaps[Independence.]
$A,B$ independent iff $Pr[A " and " B]=Pr[A]Pr[B]$. Non-independent example: first die roll is 2 and two rolls sum to 5.

#smallcaps[Birthday pairs.]
$k$ people, $n$ days. Indicator $X_(i j)=1$ if pair same birthday. $E[X_(i j)]=1/n$. Total expected matching pairs:
$E[X]=binom(k, 2)/n = k(k-1)/(2n)$.
Threshold for expected one collision: $k approx sqrt(2n)$.

#smallcaps[Coupon collector.]
When $i$ coupon types collected, probability next coupon is new is $(n-i)/n$; expected wait $n/(n-i)$. Total:
$n(1/n+1/(n-1)+...+1)=Theta(n log n)$.

#example(title: "Contention resolution.")[
  有 n 个 processes。每一轮，每个 process 独立地以概率 p = 1/n 尝试 transmit。如果两个或更多 process 同时 transmit，就会冲突，大家都失败。

  所以对一个固定 process，比如 process i，它某一轮成功的概率是：
  $Pr["success"] = p(1-p)^(n-1) = (1/n)(1-1/n)^(n-1)$, between $1/(e n)$ and $1/(2n)$. $Theta(1/n)$, 即单个 process 每一轮成功概率大概是 1/n。

  对一个固定 process 来说，每轮成功概率至少是： $1/(e n)$ 所以每轮失败概率至多是： $1 - 1/(e n)$. 失败 t 轮的概率: $P <= (1 - 1/(e n))^t$

  如果把 R = 某个固定 process 第一次成功需要的轮数, 那么 R 可以看成近似几何分布，成功概率大概是： $1/n$. 所以它的期望成功时间大概是： $Theta(n)$

  $(1 - x)^t <= e^(-x t)$, $x = 1/(e n)$
  所以： $(1 - 1/(e n))^t <= e^(-t/(e n))$, 取 $t = e n * c ln(n)$

  $e^(-t/(e n)) = e^(-(e n * c ln n)/(e n)) = e^(-c ln n) = n^(-c)$

  所以对一个固定 process： $Pr["这个 process 在 t 轮后还没成功"] <= n^(-c)$ 运行 $O(n log n)$ 轮后，一个固定 process 失败的概率非常小。

  Union Bound: $Pr(E_1 union E_2 union ... union E_n) <= Pr(E_1) + Pr(E_2) + ... + Pr(E_n)$

  一共有 $n$ 个 processes，每个失败概率最多 $n^(-c)$，所以：

  Union Bound over n processes:$Pr["至少一个失败"] <= n * n^(-c) = n^(1-c)$

  如果取 $c = 2$，那么： $Pr["至少一个失败"] <= 1/n$, 所以运行 $O(n log n)$ 轮后，所有 processes 都至少成功一次的概率至少是 $1 - 1/n$。
]
#example(title: "Random load balancing.")[
  有 m 个 jobs, 有 n 台 machines。每个 job 独立、均匀随机地选择一台 machine。也就是说，对每个 job： $Pr["job 被分到 machine i"] = 1/n$

  问题是每台机器最后拿到多少 jobs？最大负载会不会特别大？

  先固定一台机器，比如 machine i。 定义：
  $X_i = "machine i 得到的 job 数量"$

  对每个 job j，定义：

  $Y_(i j) = 1, "如果 job j 被分到 machine i"$

  $Y_(i j) = 0, "否则"$

  那么 machine i 的总负载就是： $X_i = Y_(i 1) + Y_(i 2) + ... + Y_(i m) = sum_{j=1}^m Y_(i j)$

  $E[X_i] = E[Y_(i 1) + Y_(i 2) + ... + Y_(i m)] = E[Y_(i 1)] + E[Y_(i 2)] + ... + E[Y_(i m)] = m * (1/n) = m/n$

  Chernoff upper bound 是： $Pr[X_i >= (1 + d) * mu] <= exp(-mu * d^2 / 3)$

  我们通常把单个对象的失败概率压到 $1/n^c$， 例如 $1/n^3$。然后n 个对象 union bound 后仍然很小。

  所以如果我们想让右边小于等于：$1/n^3$
  那就希望： $e^(-(mu * d^2) / 3) <= 1/n^3 = e^(-3 ln n)$
  所以只要： $mu * d^2 / 3 >= 3 ln n$
  所以这一步本质是： 选择 $d$ 足够大，使得 $mu * d^2$ 至少是 $9 ln(n)$。
]

== HW4 P4. Random Audit without Replacement

#smallcaps[题意.] Random audit without replacement：共有 $n$ 份作业，其中恰有 $r$ 份有格式违规；随机不放回抽取 $s$ 份审查。令 $X$ 为抽中违规份数。求 $E[X]$、$Pr[X=0]$，以及指数上界和保证发现至少一个违规的充分样本量。

*(a)* Let bad submissions be $B={b_1,...,b_r}$. Define $X_i=1$ if $b_i$ is selected, else $0$. Then $X=sum_{i=1}^r X_i$. For any fixed submission, *$Pr[X_i=1]=s/n$*, so $E[X_i]=s/n$. By linearity,
$E[X]=sum_{i=1}^r E[X_i]=r s/n$.
Independence is not needed.

*(b)* *No violation means all $s$ selected submissions are chosen from the $n-r$ clean ones*:
$Pr[X=0]=binom(n-r, s)/binom(n, s)$,
interpreting the numerator as $0$ if $s>n-r$.

*(c)* For $s<=n-r$,
$Pr[X=0]=prod_{i=0}^{s-1} frac {n-r-i}{n-i} <= (1-r/n)^s <= e^(-r s/n)$.
The same bound is trivial when $s>n-r$ since the left side is $0$. To get $Pr[X>=1]>=1-delta$, it suffices that $e^(-r s/n)<=delta$, i.e.
*$s >= (n/r) ln(1/delta)$*.
If the required integer exceeds $n$, audit all $n$ submissions; when $r>0$, failure probability is $0$.

== HW4 P5. One-Round Random-Priority Conflict Filter

#smallcaps[题意.] Random-priority conflict filter：冲突图 $G=(V,E)$ 中每个顶点独立从 $[0,1]$ 取 priority $p(v)$，数值越小优先级越高；若 $p(v)$ 小于所有邻居的 priority，则选中 $v$。令选中集合为 $S$。证明 $S$ 独立，求固定点被选概率和 $E[|S|]$。

*(a)* If adjacent vertices $u,v$ were both selected, then $u$ selected implies $p(u) < p(v)$, while $v$ selected implies $p(v) < p(u)$, impossible. Hence *$S$ is independent*.

*(b)* Vertex $v$ is selected exactly when it has the smallest priority in *${v} union N(v)$*, whose size is $deg(v)+1$. By symmetry,
$Pr[v in S]=1/(deg(v)+1)$.
For isolated $v$, this gives probability $1$.

*(c)* Define $X_v=1$ if $v in S$, else $0$. Then $X=|S|=sum_{v in V}X_v$. By linearity,
$E[X]=sum_{v in V}E[X_v]=sum_{v in V}Pr[v in S]=sum_{v in V}1/(deg(v)+1)$.
Linearity does not require independence. If $G$ is $d$-regular and $|V|=n$, then $E[X]=n/(d+1)$.

// == Extra Probability Examples
//
// #smallcaps[Contention resolution.]
// $n$ processes, each transmits with probability $p=1/n$. Fixed process succeeds in a round if it transmits and all others do not:
// $Pr["success"] = p(1-p)^(n-1) = (1/n)(1-1/n)^(n-1)$, between $1/(e n)$ and $1/(2n)$.
// Failure for fixed process after `t` rounds:
// $<= (1-1/(e n))^t$.
// With $t=e n dot c ln n$, failure $<=n^(-c)$. Union bound over $n$ processes.
//
// #smallcaps[Random load balancing.]
// `m` jobs to `n` machines uniformly. Fixed machine load:
// $X_i=sum_{j=1}^m Y_(i j)$, $E[X_i]=m/n$.
// Chernoff for one machine, union bound for max load across all machines.


= Approximation Ratio

#smallcaps[Deterministic approximation.]
Every run/input satisfies ratio, e.g. list scheduling output $M<=2M^*$.

#smallcaps[Expected approximation.]
Only expectation over random choices satisfies ratio, e.g. random Max-Cut $E[ALG]>=OPT/2$.

For maximization: $ALG >= OPT / alpha$.
For minimization: $ALG <= alpha dot OPT$.
$alpha >= 1$; closer to 1 is better.

Expected approximation: for randomized algorithms, replace $ALG$ by $E[ALG]$.

#smallcaps[Proof protocol.]
Maximization: upper bound $OPT$, lower bound $ALG$. Minimization: lower bound $OPT$, upper bound $ALG$. State ratio explicitly.

== Set Cover Greedy

Input: collection $F$ of sets, each with cost; union is universe $X$. Output subcollection covering $X$. Goal: minimize total cost. Minimum set cover is NP-complete.

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
Let optimal cost be $V=OPT$, $n=|X|$. When $k$ elements remain uncovered, the optimal cover of cost $V$ covers those $k$ elements, so some optimal set has average uncovered cost at most $V/k$. Greedy chooses a set with no larger average cost.

Charge each newly covered element the average cost of the set that first covers it. The `j`-th covered element is charged at most:
$V/(n-j+1)$.
Total greedy cost:
$<= V(1/n + 1/(n-1) + ... + 1) = V H_n <= V(1+ln n)$.
So greedy is $H_n$-approximation, i.e. $O(log n)$.

== Scheduling Approx

Makespan scheduling: $n$ jobs, $m$ identical machines, processing times $p_j$. Minimize max load $M$.

Lower bounds:
$M^* >= max_j p_j$ and $M^* >= (sum_j p_j)/m$.

#smallcaps[List Scheduling.]
Assign each job to currently least loaded/first available machine. Let last finishing job have start time $T$, processing time $t$. Output $M=T+t$.

Before $T$, no machine was idle, so optimal must satisfy $M^*>=T$. Also $M^*>=t$.
$M=T+t <= 2 max(T, t) <= 2M^*$.
Thus list scheduling is $2$-approximation.

#smallcaps[LPT.]
Sort jobs decreasing by processing time, then list schedule. Offline; ratio $4/3$. Key idea: last-starting job is smallest. If $t <= M^* / 3$, then $M <= M^* + t <= 4 M^* / 3$; otherwise all jobs are large and each optimal machine has at most two jobs.

== Random Max-Cut

Put each vertex independently into left/right with probability $1/2$.

For each edge $e=(u,v)$, define indicator $X_e=1$ if edge crosses the cut.
$Pr[e " crosses"] = Pr[u " L, " v " R"]+Pr[u " R, " v " L"] = 1/4+1/4=1/2$, so $E[X_e]=1/2$.
Cut size $X=sum_e X_e$. If graph has $m$ edges:
$E[X]=m/2$.
Since $OPT<=m$, randomized cut is expected $2$-approximation:
$E[ALG] = m/2 >= OPT/2$.

== More Approximation

#smallcaps[Random vs local-search Max-Cut.]
Random assignment gives an expected guarantee:
$E[ALG] >= OPT/2$.
One run can be worse. Local search gives a deterministic actual `2`-approximation because every local optimum satisfies $"cut" >= OPT/2$.

#smallcaps[Set cover tight proof shape.]
Always define charges so total charge equals algorithm cost. Then bound each element's charge by $OPT / (#" uncovered at that moment")$.

#smallcaps[Scheduling tight example.]
Many small jobs first, one big job last makes list scheduling approach ratio 2. LPT avoids this by sorting long jobs first.

= Final Exam Writing

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
State ratio definition and prove inequality against $OPT$.

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

== Exam Failure Modes

Reduction direction: to prove `A` hard, reduce known hard `B` to `A`, not `A` to `B`.

Decision vs optimization: NP-complete statements are about yes/no versions. State threshold `k,D,B` explicitly.

Pseudo-polynomial: $O(n W)$ is not polynomial in input length if $W$ is binary encoded.

Expected value: $E[ALG]>=OPT/2$ does not mean every run is $2$-approx.

Linearity: does not require independence. Chernoff does require independent indicator sum.

Potential: must be nonnegative and initially zero or account for initial/final difference.

Set cover: overlapping coverage is allowed; this is not exact cover.

Vertex cover vs independent set: cover chooses points touching every edge; independent set chooses points containing no edge.

== Compact Formula Box

$H_n = 1+1/2+...+1/n <= 1+ln n$; $(1-x) <= e^(-x)$.
