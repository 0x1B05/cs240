#import "@preview/theorion:0.4.1": *
#import "@preview/tablem:0.3.0": three-line-table

= 第十八章 Randomized Algorithms：用概率换简单和速度

#tip-box(title: "随机算法的基本问题")[
  随机算法不是“希望运气好”。它允许算法内部抛硬币，然后用期望、失败概率和放大技巧给出可证明的保证。
]

== 从确定性到随机性

到目前为止，课程里的算法大多是 deterministic：同一个输入，总做同样的事情。
随机算法允许在运行过程中做随机选择。因此同一个输入上，多次运行可能走不同路径，甚至得到不同答案。

随机性有几种价值：

- 算法更简单；
- 期望运行时间更快；
- 用更少通信打破对称性；
- 避免固定规则被 adversarial input 卡住。

一个最简单的直觉例子是：长度为 $n$ 的字符串一半是 `A`，一半是 `B`，要找一个 `A`。
确定性算法最坏可能查 `n/2 + 1` 个位置；随机检查位置时，期望只需 2 次。

== Las Vegas 与 Monte Carlo

#definition[
  *Las Vegas algorithm* 总是输出正确答案，但运行时间是随机变量。分析目标是期望运行时间。
]

#definition[
  *Monte Carlo algorithm* 运行时间通常固定或有确定上界，但可能输出错误答案。分析目标是错误概率。
]

直观区别是：

- Las Vegas：答案一定对，时间看运气；
- Monte Carlo：时间可控，答案小概率错。

很多随机算法还会用 amplification：独立重复多次，把成功概率提高。

== 概率工具复习

随机算法分析中最常用的工具是 indicator random variable 和 expectation linearity。

若事件 $E$ 的指示变量 $X$ 定义为：

- 事件发生时 $X = 1$；
- 事件不发生时 $X = 0$；

则：

`E[X] = Pr[E]`

线性期望说：

`E[X + Y] = E[X] + E[Y]`

而且不要求 $X$ 和 $Y$ 独立。这一点非常重要，因为很多算法里事件之间相关，但我们仍然可以把总量拆成许多 indicator 来算期望。

例如随机猜牌：

- 洗好 $n$ 张牌，每次从完整牌堆中均匀随机猜一张；
- 令 $X_i$ 表示第 $i$ 次是否猜对；
- `Pr[X_i = 1] = 1/n`；
- 总猜对数 `X = X_1 + ... + X_n`；
- 所以 `E[X] = 1`。

如果每次都记住已经翻出的牌，并从未见过的牌中随机猜，则第 $i$ 次猜对概率为 `1 / (n - i + 1)`，
期望正确次数变成：

`1/n + 1/(n-1) + ... + 1 = Theta(log n)`

== Birthday Paradox

生日悖论也是线性期望的例子。

假设一年有 $n$ 天，房间里有 $k$ 个人，每个人生日均匀随机。令 $X_(i,j)$ 表示第 $i$ 人和第 $j$ 人生日相同。
则：

`E[X_(i,j)] = 1/n`

总相同生日对数为：

`X = sum_(1 <= i < j <= k) X_(i,j)`

因此：

`E[X] = binom(k, 2) / n = k(k - 1) / (2n)`

当这个值达到 1 左右时，就开始期望看到一对相同生日。对 `n = 365`，阈值大约在 28 人量级。

== Coupon Collector 的直觉

Coupon collector 问题是：有 $n$ 种 coupon，每次开盒均匀随机得到一种，期望开多少盒才能集齐全部？

可以把过程分阶段：

- 已经收集到 $i$ 种时，下一盒是新种类的概率为 `(n - i) / n`；
- 因此等到下一种新 coupon 的期望盒数是 `n / (n - i)`；
- 总期望是 `n * (1/n + 1/(n-1) + ... + 1)`；
- 即 `Theta(n log n)`。

这类分析会反复出现：把等待时间拆成几段几何随机变量，再把期望加起来。

== Randomized Max-Cut

Max-Cut 的随机近似算法极其简单：

1. 对每个点独立抛硬币；
2. 正面放进 $A$，反面放进 $B$；
3. 返回 cut `(A, B)`。

对任意一条边 $(u, v)$，它跨 cut 的概率是：

`Pr[u in A, v in B] + Pr[u in B, v in A] = 1/4 + 1/4 = 1/2`

令 $X_e$ 为边 $e$ 是否跨 cut 的指示变量，$X$ 为 cut 大小。若图有 $m$ 条边：

`E[X] = sum_e E[X_e] = m / 2`

最优 cut 的大小最多是 $m$，因此该算法的期望值至少是最优值的一半。

#theorem(title: "随机 Max-Cut 的期望保证")[
  随机把每个点独立放到两侧，得到的 cut 期望大小为边数的一半，因此是期望意义下的 `2`-approximation。
]

注意这里说的是期望保证。一次具体运行可能比 `m/2` 小，也可能更大。

== Contention Resolution：随机性打破对称性

分布式系统里，多个进程可能竞争同一个共享信道。如果两个或更多进程同时访问，所有人都失败。

假设：

- 有 $n$ 个进程；
- 时间分成 round；
- 进程之间不能通信；
- 进程没有 ID。

没有 ID 且不能通信时，确定性协议很难打破对称性：所有进程会做同样的事。

随机协议是：每个进程在每一轮以概率 `p = 1/n` 请求访问。

对固定进程 $i$ 和固定时刻 $t$，它成功的概率是：

`p * (1 - p)^(n - 1)`

代入 `p = 1/n` 后，这个概率在 `1 / (e n)` 和 `1 / (2n)` 之间。

因此，进程 $i$ 在大约 `e n` 轮里仍没成功的概率至多约 `1/e`；
在 `e n * c ln n` 轮里仍没成功的概率至多 `n^(-c)`。

再用 union bound：

`Pr[至少一个进程失败] <= sum_i Pr[进程 i 失败]`

取 `t = 2 e n ln n`，所有进程都成功过的概率至少是 `1 - 1/n`。

== Global Minimum Cut 与 Karger 收缩算法

#definition[
  *Global minimum cut*：给定连通无向图 $G = (V, E)$，找一个割 `(A, B)`，使跨越两边的边数最小。
]

Karger 的随机收缩算法如下：

1. 均匀随机选一条边 $(u, v)$；
2. 把 $u$ 和 $v$ 收缩成一个 supernode；
3. 保留平行边，删除 self-loop；
4. 重复直到只剩两个 supernode；
5. 返回这两个 supernode 之间的割。

算法成功的条件是：在收缩过程中，从来没有收缩某个固定最小割 $F^*$ 中的边。

设最小割大小为 $k$。因为每个点的度数至少为 $k$，所以图中边数至少为 `k n / 2`。
第一步收缩到 $F^*$ 中边的概率至多：

`k / |E| <= 2/n`

如果前面都没碰到 $F^*$，当还剩 $n'$ 个 supernodes 时，同样有失败概率至多 `2/n'`。
于是整个过程保住 $F^*$ 的概率至少：

`(1 - 2/n)(1 - 2/(n-1)) ... (1 - 2/3) = 2 / (n(n - 1))`

也就是 `Omega(1/n^2)`。

#theorem(title: "Karger contraction 的成功概率")[
  单次随机收缩算法以至少 `2 / n^2` 量级的概率返回一个 global min-cut。
]

这个概率不高，但可以放大。独立运行 `n^2` 次，并取找到的最小 cut，则失败概率被压到常数以下。

== Randomized Quicksort

普通 quicksort 的坏情况来自 pivot 极端不平衡。例如每次都选到最小元素，就得到 `Theta(n^2)`。
随机 quicksort 每次均匀随机选 pivot，避免输入顺序决定坏情况。

一种递推分析写作：

`R(n) <= (2/n) * sum_(k=1)^(n-1) R(k) + Theta(n)`

可用替换法证明：

`R(n) = O(n log n)`

更优雅的分析是数比较次数。

把元素按大小记为 $z_1, z_2, dots, z_n$。令 $X_(i,j)$ 表示 $z_i$ 和 $z_j$ 是否被比较。
只有当区间 `{z_i, ..., z_j}` 中最先被选为 pivot 的元素是 $z_i$ 或 $z_j$ 时，它们才会比较。
因此：

`Pr[z_i 和 z_j 比较] = 2 / (j - i + 1)`

总比较次数 `X = sum_(i < j) X_(i,j)`，所以：

`E[X] = sum_(i < j) 2 / (j - i + 1) = O(n log n)`

#theorem(title: "Randomized Quicksort 的期望复杂度")[
  对互异元素，randomized quicksort 的期望比较次数为 `Theta(n log n)`。
]

== Randomized MAX-3SAT

MAX-3SAT 要最大化被满足的子句数。最简单的随机算法是：

- 对每个变量独立抛硬币；
- 以概率 `1/2` 设为 true；
- 否则设为 false。

每个 3-literal 子句不满足的唯一情况是三个 literal 全假，概率为 `1/8`。
所以被满足概率是 `7/8`。

若公式有 $k$ 个子句，令 $Z_j$ 表示第 $j$ 个子句是否满足。则：

`E[Z] = sum_j E[Z_j] = 7k/8`

因此随机赋值在期望意义下满足 `7/8` 的子句。

slides 还给出一个弱但有用的概率下界：随机赋值满足至少 `7k/8` 个子句的概率至少为 `1/(8k)`。
这意味着重复多次可以以较高概率找到达到期望阈值的赋值。

== 本章小结

#figure(
  caption: [本章随机化例子的保证类型],
  three-line-table[
    | 问题 | 随机选择 | 主要保证 |
    |:---|:---|:---|
    | Max-Cut | 每个点独立进左右侧 | 期望 `2`-approximation |
    | Contention resolution | 每轮以 `1/n` 概率访问 | `O(n log n)` 轮内高概率所有进程成功 |
    | Global min-cut | 随机收缩边 | 单次 `Omega(1/n^2)` 成功，可重复放大 |
    | Quicksort | 随机 pivot | 期望 `Theta(n log n)` 比较 |
    | MAX-3SAT | 随机变量赋值 | 期望满足 `7/8` 子句 |
  ],
)

#tip-box(title: "随机算法分析套路")[
  先把关心的总量拆成 indicator variables，用线性期望算期望；
  如果需要高概率保证，再考虑独立重复、union bound 或更强的 concentration 工具。
]
