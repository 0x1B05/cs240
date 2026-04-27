#import "@local/cheatsheet:0.1.0": *

#show: doc => cheatsheet(
  title: "CS240 Midterm Cheatsheet",
  authors: ((name: "0x1B05"),),
  date: datetime(year: 2026, month: 4, day: 26),
  columns-count: 5,
  font-size: 7pt,
  doc,
)

#set text(lang: "zh")

== P1. 增长阶排序

```
constant < log n < n < n log n < n^a < n^(log n) < 2^n / poly(n) < a^(b^n)
```

== P3. 单位区间覆盖点

#smallcaps[题意.] 用最少长度为 1 的闭区间覆盖实线上所有点。

#smallcaps[Algorithm.]
Sort `A` in ascending order. Maintain `R`, the right endpoint of the last interval selected. Scan from left to right. If the current point is to the right of `R`, start a new unit interval `[A[i], A[i]+1]`.
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
The minimum number of unit intervals is `|I|`.

#smallcaps[Correctness.(*Exchange argument*)]
Let `[l1,r1], ..., [lp,rp]` with `r1 < ... < rp` be the greedy solution. Let `[l1',r1'], ..., [lq',rq']` with `r1' < ... < rq'` be an optimal solution, and assume the two solutions agree for the largest possible prefix length `k`.

The greedy algorithm places intervals as right as possible. Let `x` be the leftmost point to the right of `r_k`. Then greedy chooses `[x,x+1]`, so `l_(k+1)=x` and `r_(k+1)=x+1`. Since the optimal solution must also cover `x`, we have `r'_(k+1) <= x+1 = r_(k+1)`.

Replace `[l'_(k+1), r'_(k+1)]` in the optimal solution with `[l_(k+1), r_(k+1)]`. The replacement can only extend the covered region to the right, so it preserves feasibility and increases the common prefix by one. Repeating this exchange makes an optimal solution agree with greedy. If greedy used more intervals than optimal, the left endpoint of its last interval would be an uncovered point for the optimal solution, a contradiction. Hence the greedy solution is optimal.

#smallcaps[Complexity.] Sorting costs `O(n log n)` and the scan costs `O(n)`, so the total time is `O(n log n)`.

== P4. 最少加油次数

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
Assume an optimal solution `OPT` uses fewer refuels than the greedy algorithm. Suppose both solutions make the same choices for the first `i` refuels and reach position `p_i`. For the next refuel, `OPT` chooses some position `p_opt`, while greedy chooses a reachable position that maximizes the next reach, denoted `p_greedy`. By the greedy choice, `p_greedy >= p_opt` in terms of reachable progress.

Therefore after each refuel, greedy reaches at least as far as the corresponding optimal choice. Greedy can never need more refuels than `OPT`, contradicting the assumption. Hence greedy is optimal.

#smallcaps[Complexity.] The array is traversed once, so the time complexity is `O(n)`.

== P5. 网格局部最小值

#smallcaps[题意.] 只能调用 `V(i,j)` 查询 `n x n` 网格值，用 `O(n)` 次查询找一个上下左右局部最小。

#smallcaps[High-level idea.]
Divide the grid into four quadrants using the middle row and middle column. Let `B` be the boundary positions, i.e. cells on the middle row or middle column, and compute `m in argmin_(b in B) V(b)`.

If `m` is not already a local minimum, then it has a strictly smaller neighbor in its own quadrant; following strictly decreasing neighbors from `m` reaches a local minimum that cannot cross back to the boundary. To make this precise, strengthen the recursion: given a starting position `t`, return a local minimum with value at most `V(t)`.

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
Base case: if the current grid is `1 x 1`, return `t`. Otherwise split by the middle row and column, find boundary minimum `m`, and recurse into the quadrant containing the smaller seed among `t` and `m`.

#smallcaps[Correctness.]
We prove by induction on the side length of the current grid that `FindGridLocalMinimum(G,t)` returns a local minimum `x` of `G` with `V(x) <= V(t)`.

The base case `1 x 1` is immediate. For the inductive step, let `m` be the minimum cell on the boundary `B`. The algorithm recurses into a quadrant containing a seed cell `u`, where `u` is either `t` or `m`, such that `V(u) <= V(t)` and `V(u) <= V(b)` for every boundary cell `b` in `B`.

By the induction hypothesis, the recursive call returns a local minimum `x` inside the chosen quadrant with `V(x) <= V(u) <= V(t)`. Any neighbor of `x` either also lies inside the same quadrant, where local minimality is guaranteed by the recursive call, or lies on the boundary `B`. Every boundary cell has value at least `V(u)`, and `V(x) <= V(u)`, so no boundary neighbor is smaller than `x`. Therefore `x` is also a local minimum of the whole current grid.

#smallcaps[Complexity.]
At side length `l`, the middle row and column contain `O(l)` cells. The recursion keeps one quadrant with side length about `l/2`.
```
T(n) = O(n) + O(n/2) + O(n/4) + ... = O(n).
```
Thus the algorithm uses `O(n)` calls to `V`.

== P6. 链表归并排序

#smallcaps[Solution.]
Use merge sort. It is well suited for linked lists because splitting can be done with fast and slow pointers, and two sorted lists can be merged by pointer rewiring.

#smallcaps[Steps.]
1. Divide the linked list into two halves until each sublist has at most one node.
2. Use fast and slow pointers to find the middle, then disconnect the list at the middle.
3. Recursively sort the left and right sublists.
4. Merge two sorted linked lists using two pointers and a dummy head.
5. Return the final sorted list.

#smallcaps[Complexity.] Merge sort on a linked list takes `O(n log n)` time and uses `O(log n)` recursion stack space.

== P1. 最大和递增子序列

#smallcaps[题意.] 找递增子序列的最大可能元素和，不是最长长度。

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

== P2. 分组课程背包

#smallcaps[题意.] 有 `m` 个课程组，每组最多选一门课，总学分不超过 `W`，最大化收益。

#smallcaps[DP state.]
Let `dp[i][w]` be the maximum benefit using the first `i` groups with credit limit `w`.

#smallcaps[Transition.]
Base case: if no group is considered, no course can be selected:
```
dp[0][w] = 0 for all 0 <= w <= W
```
For group `i`, either choose no course from this group or choose exactly one course `(c,v)`:
```
dp[i][w] = dp[i-1][w]
if w >= c: dp[i][w] = max(dp[i][w], dp[i-1][w-c] + v)
```
Complete recurrence:
```
dp[i][w] = max(dp[i-1][w], max over course (c,v) in group i and c <= w of dp[i-1][w-c] + v)
```
The answer is `dp[m][W]`.

#smallcaps[Pseudocode.]
```
CourseSelection(groups, m, W):
    create dp[0..m][0..W], initialized with 0
    for i = 1 to m:
        for w = 0 to W:
            dp[i][w] = dp[i-1][w]
            for each course (c, v) in group i:
                if w >= c:
                    dp[i][w] = max(dp[i][w], dp[i-1][w-c] + v)
    return dp[m][W]
```

#smallcaps[Correctness.]
The state `dp[i][w]` stores the maximum total benefit obtainable from the first `i` groups under credit limit `w`. Any feasible solution for the first `i` groups either selects no course from group `i`, in which case the value is `dp[i-1][w]`, or selects exactly one course from group `i`, say `(c,v)`, in which case the remaining credit is `w-c` and the value is `dp[i-1][w-c] + v`. Since the transition examines all valid choices from group `i` and takes the maximum, it correctly computes the best value. After all `m` groups are processed, `dp[m][W]` is the desired optimum.

#smallcaps[Complexity.]
Let `K` be the total number of courses. Time is `O(WK)`; table space is `O(mW)`.

== P3. 涂色机器人

#smallcaps[题意.] 每次可用一种颜色涂一段连续区间，允许覆盖，求涂出字符串 `s` 的最少次数。

#smallcaps[DP state.]
Let `f[i][j]` be the minimum number of operations needed to paint substring `s[i..j]`.

#smallcaps[Transition.]
Boundary condition:
```
f[i][i] = 1
```
Same-color case: if `s[i] == s[j]`, the robot can cover `s[j]` while painting `s[i]`, so it is enough to finish `s[i..j-1]`:
```
if s[i] == s[j]:
    f[i][j] = f[i][j-1]
```
Different-color case: if `s[i] != s[j]`, split the interval into `[i,k]` and `[k+1,j]`:
```
if s[i] != s[j]:
    f[i][j] = min over i <= k < j of f[i][k] + f[k+1][j]
```
Answer: `f[0][n-1]`.

#smallcaps[Pseudocode.]
```
RobotPainter(s):
    n = length(s)
    f = n by n array initialized with 0
    for i = n - 1 downto 0:
        f[i][i] = 1
        for j = i + 1 to n - 1:
            if s[i] == s[j]:
                f[i][j] = f[i][j-1]
            else:
                min_value = infinity
                for k = i to j - 1:
                    min_value = min(min_value, f[i][k] + f[k+1][j])
                f[i][j] = min_value
    return f[0][n-1]
```

#smallcaps[Correctness.]
The state `f[i][j]` represents the minimum number of painting operations needed for section `i..j`. For `i == j`, exactly one operation is needed. If `s[i] == s[j]`, a plan that paints `s[i]` can be arranged to cover `s[j]` at the same time, so completing `i..j` costs no more than completing `i..j-1`, and `f[i][j] = f[i][j-1]`. If `s[i] != s[j]`, the two endpoints cannot be finished by the same final same-color continuous operation, so the solution can be split at some `k`; the algorithm checks every possible split and chooses the minimum. Because the table is filled from shorter intervals to longer intervals, all needed subproblems are already available. Therefore `f[0][n-1]` is the minimum number of painting operations.

#smallcaps[Complexity.] `O(n^3)` time and `O(n^2)` space.

== P5. 选课注册网络流

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

== P6. 动森收集材料最少天数

#smallcaps[题意.] 每个事件需要完成 `c_i` 次，只在若干星期几开放；每天最多完成 `e` 次事件。从周一开始，求最少天数。

#smallcaps[Main idea.]
Use binary search on the answer. Initialize the range as `[0, 10^9 / e]`. For each trial value `mid`, build a flow network to check whether all event requirements can be satisfied within `mid` days.

#smallcaps[Counting weekdays.]
For weekday `d` in `1..7`, the number of occurrences in the first `D` days is:
```
cnt[d] = D // 7 + (1 if d <= D % 7 else 0)
```
The capacity contributed by weekday `d` is `cnt[d] * e`, equivalently `(floor(D/7) + [D mod 7 >= d]) * e`.

#smallcaps[Feasibility network for fixed D.]
Nodes: source `S`, seven weekday nodes, one event node per event, sink `T`.

Edges:
- `S -> weekday d` with capacity `(floor(D/7) + [D mod 7 >= d]) * e`.
- `weekday d -> event i` with capacity `INF` if event `i` is available on weekday `d`.
- `event i -> T` with capacity `c_i`.

Let `need = sum_i c_i`. The schedule is feasible within `D` days iff the maximum flow is at least `need`.

#smallcaps[Pseudocode.]
```
Feasible(D):
    create flow network with source S and sink T
    for d = 1 to 7:
        cnt[d] = D // 7 + (1 if d <= D % 7 else 0)
        add edge S -> weekday[d] with capacity cnt[d] * e
    for each event i:
        for each weekday d in availability[i]:
            add edge weekday[d] -> event[i] with capacity INF
        add edge event[i] -> T with capacity c[i]
    return MaxFlow(S, T) >= sum_i c[i]
MinimumDays():
    low = 0
    high = 10^9 / e
    while low < high:
        mid = (low + high) // 2
        if Feasible(mid):
            high = mid
        else:
            low = mid + 1
    return low
```

#smallcaps[Correctness.]
For a fixed `D`, source-to-weekday capacities represent the total number of event completions possible on each weekday during the first `D` days. Weekday-to-event edges represent the days on which each event can be completed and have infinite capacity because an event may be completed multiple times on valid days. Event-to-sink edges have capacity `c_i`, forcing the required number of completions for every event.

If max flow is at least `sum_i c_i`, all requirements can be met within `D` days; otherwise they cannot. This feasibility condition is monotone in `D`, so binary search returns the minimum feasible number of days.

#smallcaps[Complexity.]

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
