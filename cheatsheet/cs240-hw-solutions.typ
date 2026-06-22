#import "@local/cheatsheet:0.1.0": *

#show: doc => cheatsheet(
  title: "CS240 Solution Cheatsheet",
  authors: ((name: "0x1B05"),),
  date: datetime(year: 2026, month: 6, day: 22),
  columns-count: 5,
  font-size: 7pt,
  doc,
)

#set text(lang: "zh")
#let Pr = math.op("Pr")
#let E = math.op("E")
#let Theta = math.op("Theta")
#let O = math.op("O")
#let prod = math.op("prod")
#let deg = math.op("deg")
#let floor = math.op("floor")

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

== HW3 P1

#smallcaps[题意.] 给定通信 links $L={ell_1,...,ell_n}$、冲突对 $I subset.eq L times L$ 和整数 $k$。问是否存在 $L' subset.eq L$，使 $|L'|>=k$，且没有任何一个冲突对的两个端点都在 $L'$ 中。证明 NP-complete。

#smallcaps[NP.] Given $L'$, build a selected-link Boolean array in $O(|L|)$ and scan every pair $(ell_i,ell_j) in I$ to ensure not both endpoints are selected. Verification time $O(|L|+|I|)$.

#smallcaps[Reduction from Independent Set.] Given $(G=(V,E),k)$, create one link $ell_i$ for every vertex $v_i in V$:
$L={ell_i | v_i in V}$.
For every edge $(v_i,v_j) in E$, add interfering pair $(ell_i,ell_j)$:
$I={(ell_i,ell_j) | (v_i,v_j) in E}$.
Keep the same $k$. Construction time $O(|V|+|E|)$.

#smallcaps[Correctness.] If $S subset.eq V$ is independent and $|S|>=k$, let $L'={ell_i | v_i in S}$. No edge has both endpoints in $S$, so no interfering pair has both links in $L'$, and $|L'|=|S|>=k$.
Conversely, if feasible $L'$ has $|L'|>=k$, let $S={v_i | ell_i in L'}$. If two vertices in $S$ were adjacent, the corresponding links would form an interfering pair inside $L'$, contradiction. Thus $S$ is independent and $|S|=|L'|>=k$. Hence iff; with NP membership, NP-complete.

== HW3 P2

#smallcaps[题意.] 校园巡逻点放置问题：给定无向图 $G=(V,E)$ 和整数 $k$，问是否存在 $S subset.eq V$，$|S|<=k$，使每个顶点要么在 $S$ 中，要么与某个 $S$ 中顶点相邻。证明 NP-complete。

#smallcaps[NP.] Given $S$, check $|S|<=k$ and scan adjacency lists to mark vertices monitored by $S$. Time $O(|V|+|E|)$.

#smallcaps[Reduction from Vertex Cover.] Given $(G=(V,E),k)$, construct $G'$. Keep all original vertices and edges. For every edge $e=(u,v) in E$, add a new vertex $x_e$ and edges $(x_e,u),(x_e,v)$. Keep parameter $k$. Size/time $O(|V|+|E|)$. Isolated original vertices can be removed before the reduction, since they do not affect vertex cover and would only force trivial patrol points.

#smallcaps[Correctness.] If $C$ is a vertex cover of $G$ with $|C|<=k$, use the same $C$ as patrol points. Every new $x_e$ is adjacent to an endpoint of $e$ in $C$; every non-isolated original vertex not in $C$ has an incident edge whose other endpoint must be in $C$; vertices in $C$ monitor themselves. Thus $C$ dominates $G'$.
Conversely, let $S$ dominate $G'$, $|S|<=k$. Replace any selected new vertex $x_e$ for $e=(u,v)$ by either endpoint, obtaining $C subset.eq V$ with $|C|<=|S|<=k$. For every original edge $e=(u,v)$, vertex $x_e$ is adjacent only to $u,v$. Since $x_e$ is dominated, either $x_e in S$ or one endpoint is in $S$; after replacement at least one endpoint lies in $C$. Thus $C$ is a vertex cover. Hence iff and NP-complete.

== HW3 P3

#smallcaps[题意.] Monotone 3-SAT：每个 clause 恰有三个 literal，且每个 clause 要么全正、要么全负。问公式是否可满足。证明 NP-complete。

#smallcaps[NP.] A truth assignment is checked by evaluating every 3-literal clause in $O(m)$.

#smallcaps[Reduction from 3-SAT.] For a 3-SAT formula $phi=C_1 and ... and C_m$, keep already monotone clauses. For each mixed clause introduce fresh $u_i$:
- If $C_i=(x or y or not z)$, replace it by $(x or y or u_i)$ and $(not z or not u_i or not u_i)$.
- If $C_i=(x or not y or not z)$, replace it by $(x or u_i or u_i)$ and $(not y or not z or not u_i)$.
Every new clause is monotone and has exactly three literals; each old clause creates at most two clauses and one variable, so polynomial size.

#smallcaps[Correctness, forward.] Suppose $phi$ is satisfied by assignment $alpha$. For $(x or y or not z)$: if $x or y$ is true, set $u_i="false"$; otherwise $not z$ is true and set $u_i="true"$. Both replacement clauses hold. For $(x or not y or not z)$: if $x$ is true, set $u_i="false"$; otherwise at least one of $not y,not z$ is true and set $u_i="true"$. Thus $alpha$ extends to satisfy $phi'$.

#smallcaps[Correctness, backward.] Suppose $phi'$ is satisfied. Restrict to original variables. Already monotone clauses are unchanged. For $(x or y or not z)$, if the original clause were false, then $x="false",y="false",not z="false"$. The first new clause forces $u_i="true"$, while the second forces $u_i="false"$, contradiction. For $(x or not y or not z)$, if false, then $x="false",not y="false",not z="false"$; the first new clause forces $u_i="true"$, the second forces $u_i="false"$. Hence every original clause is true. Therefore $phi$ satisfiable iff $phi'$ satisfiable; NP-complete.

== HW3 P4

#smallcaps[题意.] Two-bin partition：给定 items $I$，每个 item 有正整数大小 $s(i)$，两个容量 $B_1,B_2$。问能否把 $I$ 划分为 $I_1,I_2$，使 $sum_{i in I_1}s(i)<=B_1$ 且 $sum_{i in I_2}s(i)<=B_2$。证明 NP-complete。

#smallcaps[NP.] Given $I_1,I_2$, scan items to verify they form a partition and compute both sums. Time $O(|I|)$.

#smallcaps[Reduction from Subset Sum.] Given positive integers $a_1,...,a_n$ and target $T$, let $A=sum_{j=1}^n a_j$. If $T>A$, map to any fixed NO instance; otherwise create item $i_j$ with $s(i_j)=a_j$, set $B_1=T$ and $B_2=A-T$.

#smallcaps[Correctness.] If subset $S subset.eq {1,...,n}$ has $sum_{j in S}a_j=T$, put $I_1={i_j | j in S}$ and put all remaining items into $I_2$. Then sums are $T=B_1$ and $A-T=B_2$.
Conversely, if a feasible partition exists, then
$sum_{i in I_1}s(i)+sum_{i in I_2}s(i)=A$.
The constraints give the left side $<=T+(A-T)=A$, so both constraints are tight; in particular $sum_{i in I_1}s(i)=T$. Thus the corresponding numbers solve Subset Sum. Hence iff and NP-complete.

== HW3 P5

#smallcaps[题意.] 给定一个 $m times n$ grid，每个格子为空、黑棋或白棋。允许删除部分棋子，问能否使每行至少剩一个棋子，且每列不能同时含黑白两色棋子。证明 NP-complete。

#smallcaps[NP.] Given remaining pieces, scan the grid to check each row has a piece and each column is monochromatic. Time $O(m n)$.

#smallcaps[Reduction from 3SAT.] Given 3CNF $Phi$ with clauses $C_1,...,C_m$ and variables $x_1,...,x_n$, build an $m times n$ grid. Row $i$ corresponds to $C_i$, column $j$ to $x_j$. If $x_j$ appears positively in $C_i$, put a black piece in cell $(i,j)$; if $not x_j$ appears in $C_i$, put a white piece; otherwise leave it empty. Polynomial construction.

#smallcaps[Correctness.] If $Phi$ is satisfiable, for each variable column $j$: if $x_j="true"$, remove all white pieces in column $j$; if $x_j="false"$, remove all black pieces. Columns become single-color. Since every clause has a true literal, each row keeps at least one corresponding piece.
Conversely, from any valid grid choose assignment: if column $j$ has a remaining black piece set $x_j="true"$; if it has a white piece set $x_j="false"$; if empty choose arbitrarily. Well-defined because no column has both colors. Every row has a remaining piece: black means a positive literal made true, white means a negative literal made true. Thus every clause is satisfied. Hence iff and NP-complete.

== HW4 P1. Lazy Disk-Write Queue(*potential method*)

#smallcaps[题意.] Lazy disk-write queue：`Modify(i)` 设置 `dirty[i]=true` 并把 page ID $i$ 加入 FIFO queue；`FlushOne()` 从队首删除 stale entries，遇到 dirty page 就写回并清 dirty。要求构造单次 worst case、证明任意 $m$ 次总成本 $O(m)$，并用 potential method 证摊还 $O(1)$。

*(a)* Execute $k$ operations `Modify(1)`. Then $Q$ contains $k$ copies of page ID $1$ and `dirty[1]=true`. The first `FlushOne()` removes one copy, writes page $1$, and sets `dirty[1]=false`. The remaining $k-1$ copies are stale. A second `FlushOne()` removes all $k-1$ stale entries before returning $0$, so this call costs $Theta(k)$. At that point $m=k+2$, hence $Theta(m)$.

*(b)* Each `Modify` inserts one queue entry; each inserted entry can be removed at most once. Thus over any $m$ operations, total queue insertions and deletions are both $O(m)$. Other work per external operation is constant except work charged to deleted entries, and each successful flush writes at most one page. Duplicate page IDs do not break the bound: every duplicate is a distinct queue entry created by a distinct `Modify` and removed at most once. Total time $O(m)$.

*(c)* Let $Phi=C |Q|$ for sufficiently large constant $C$. Initially $Phi=0$ and always $Phi>=0$. For `Modify(i)`, actual cost $O(1)$ and $|Q|$ increases by $1$, so $Delta Phi=C$ and amortized cost $O(1)$. For `FlushOne()`, if it deletes $k$ entries, actual cost is $O(k)+O(1)$ and $Delta Phi=-C k$; choose $C$ large enough so the drop pays for all deleted stale entries. Hence amortized $O(1)$. Empty queue case is also $O(1)$.

== HW4 P2. Triangular Calibration Monitor(*Aggregate Analysis && Accounting method*)

#smallcaps[题意.] Triangular calibration：每次 `InsertSample` 基础成本为 $1$。当插入总数 $N$ 变成三角数 $T_q=1+...+q=q(q+1)/2$ 时触发第 $q$ 次 calibration，成本为 $q$。求前 $n$ 次插入的 calibration 次数、总成本和 accounting 摊还收费。

*(a)* During first $n$ insertions, the number of calibrations is the largest integer $q$ with $T_q<=n$, i.e.
$q=floor((sqrt(8n+1)-1)/2)$.

*(b)* Base insertion cost is $n$. If $q$ calibrations occur, their total cost is $1+2+...+q=T_q<=n$. Total cost $<=n+T_q<=2n=O(n)$, so amortized insertion cost is $O(1)$.

*(c)* Charge each `InsertSample` $2$ units. One pays the insertion, one is stored as credit. After the $q$-th calibration, the next one costs $q+1$; from just after the $q$-th calibration through the insertion triggering the $(q+1)$-st, there are exactly $T_{q+1}-T_q=q+1$ insertions, saving $q+1$ credits. Credits never go negative; amortized charge is $2$.

== HW4 P3. Archive with Tombstone Compaction

#smallcaps[题意.] Archive with tombstones：数组 entry 是 live article 或 tombstone。`Add` 追加 live article；`Remove` 若成功则标记 tombstone；每次 `Remove` 后若 tombstones 数严格大于 live articles 数，则自动 `Compact()` 扫描数组、复制 live articles、丢弃 tombstones。求单次 worst case、总成本和 potential 摊还界。

*(a)* A `Remove` can make tombstones strictly greater than live articles, triggering `Compact()`. If the array length immediately before compaction is $n$, compaction scans the whole array and copies live articles, so this single `Remove` can cost $Theta(n)$.

*(b)* Consider one compaction. Let $D$ be tombstones and $L$ live articles just before compaction. Trigger condition gives $D>L$, so array length $D+L < 2 D$. Compaction scans $D+L$ entries and copies $L$ live articles, cost $(D+L)+L=D+2 L < 3 D$. These $D$ tombstones were created by $D$ effective `Remove` operations since the previous compaction, so charge this compaction to those removals. Basic `Add`/`Remove` costs over $m$ operations are $O(m)$, and all compactions cost $O(m)$ total.

*(c)* Let $D$ be current tombstone count and $Phi=C D$, e.g. $C=4$. Initially $0$, always nonnegative. `Add` and ineffective `Remove` do not change $D$: amortized $O(1)$. Effective `Remove` without compaction has actual $O(1)$ and $Delta Phi=C$: amortized $O(1)$. If an effective `Remove` triggers compaction, let $D,L$ be counts after marking but before compaction. Then $D>L$ and compaction cost $<3 D$. Before this remove there were $D-1$ tombstones; after compaction there are $0$, so $Delta Phi=0-C (D-1)$. With $C>=4$, the potential drop pays for compaction up to a constant. Thus amortized $O(1)$.

== HW4 P4. Random Audit without Replacement

#smallcaps[题意.] Random audit without replacement：共有 $n$ 份作业，其中恰有 $r$ 份有格式违规；随机不放回抽取 $s$ 份审查。令 $X$ 为抽中违规份数。求 $E[X]$、$Pr[X=0]$，以及指数上界和保证发现至少一个违规的充分样本量。

*(a)* Let bad submissions be $B={b_1,...,b_r}$. Define $X_i=1$ if $b_i$ is selected, else $0$. Then $X=sum_{i=1}^r X_i$. For any fixed submission, $Pr[X_i=1]=s/n$, so $E[X_i]=s/n$. By linearity,
$E[X]=sum_{i=1}^r E[X_i]=r s/n$.
Independence is not needed.

*(b)* No violation means all $s$ selected submissions are chosen from the $n-r$ clean ones:
$Pr[X=0]=binom(n-r, s)/binom(n, s)$,
interpreting the numerator as $0$ if $s>n-r$.

*(c)* For $s<=n-r$,
$Pr[X=0]=prod_{i=0}^{s-1} frac {n-r-i}{n-i} <= (1-r/n)^s <= e^(-r s/n)$.
The same bound is trivial when $s>n-r$ since the left side is $0$. To get $Pr[X>=1]>=1-delta$, it suffices that $e^(-r s/n)<=delta$, i.e.
$s >= (n/r) ln(1/delta)$.
If the required integer exceeds $n$, audit all $n$ submissions; when $r>0$, failure probability is $0$.

== HW4 P5. One-Round Random-Priority Conflict Filter

#smallcaps[题意.] Random-priority conflict filter：冲突图 $G=(V,E)$ 中每个顶点独立从 $[0,1]$ 取 priority $p(v)$，数值越小优先级越高；若 $p(v)$ 小于所有邻居的 priority，则选中 $v$。令选中集合为 $S$。证明 $S$ 独立，求固定点被选概率和 $E[|S|]$。

*(a)* If adjacent vertices $u,v$ were both selected, then $u$ selected implies $p(u) < p(v)$, while $v$ selected implies $p(v) < p(u)$, impossible. Hence $S$ is independent.

*(b)* Vertex $v$ is selected exactly when it has the smallest priority in ${v} union N(v)$, whose size is $deg(v)+1$. By symmetry,
$Pr[v in S]=1/(deg(v)+1)$.
For isolated $v$, this gives probability $1$.

*(c)* Define $X_v=1$ if $v in S$, else $0$. Then $X=|S|=sum_{v in V}X_v$. By linearity,
$E[X]=sum_{v in V}E[X_v]=sum_{v in V}Pr[v in S]=sum_{v in V}1/(deg(v)+1)$.
Linearity does not require independence. If $G$ is $d$-regular and $|V|=n$, then $E[X]=n/(d+1)$.
