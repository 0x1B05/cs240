#import "@local/notes:0.1.0": *

= 第十六章 Local Search：从局部改进到均衡

#tip-block(title: "这一章的关键词")[
  Local search 的核心不是一次性构造最优解，而是从一个可行解出发，反复找“邻居”里更好的解。
  分析时要问三件事：邻居关系是什么、每一步是否真的改进、什么时候停下来以后能保证什么。
]

== 局部搜索的基本模板

局部搜索通常先定义一个搜索空间和一个邻居关系：

- 搜索空间：所有候选解；
- 邻居关系：一次小修改能到达的解；
- 改进规则：若某个邻居更好，就移动过去；
- 终止条件：当前解没有更好的邻居。

这个过程非常像梯度下降：每一步都朝局部更好的方向走。但它也继承了梯度下降的风险：

- 可能停在局部最优，而不是全局最优；
- 可能需要很久才能停；
- 如果没有一个单调下降的势函数，甚至可能循环。

所以 local search 的证明往往不是证明“它找到最优”，而是证明：

- 它一定会停；
- 停下来的解至少有某种近似保证；
- 或者某个动态过程最终达到稳定状态。

== Vertex Cover 上的梯度下降

先看最简单的例子。

#definition[
  *Vertex Cover*：给定图 $G = (V, E)$，找一个点集 $S$，使每条边至少有一个端点在 $S$ 中，
  并希望 `|S|` 尽量小。
]

定义邻居关系：若 $S'$ 可以由 $S$ 增加或删除一个点得到，就称 $S$ 和 $S'$ 相邻。

从 $S = V$ 开始：

1. 如果存在某个邻居 $S'$ 仍然是 vertex cover，并且 `|S'| < |S|`，就把当前解换成 $S'$；
2. 否则停止。

这个算法一定会停，因为每一步都让 cover 的大小减少 1。最多减少 $n$ 次。

但这也说明它的表达能力很有限：它只允许一次删一个点。如果某个更好的解需要先加入一个点、再删掉多个点，
这个局部搜索就看不到。局部最优的强弱，直接取决于你定义的邻居关系。

#remark(title: "邻居关系不是小细节")[
  邻居关系越小，每一步越便宜，但更容易卡住。
  邻居关系越大，局部最优更有意义，但每一步要检查的候选也更多。
]

== Maximum Cut：局部翻转也能给近似保证

#definition[
  *Maximum Cut*：给定无向图，把点划分成两边 $A$ 和 $B$，最大化跨越两边的边数。
]

Max-Cut 是 NP-hard，但一个非常简单的 local search 能得到常数近似。

算法从任意划分 `(A, B)` 开始。若存在某个点，把它从一边翻到另一边后 cut 的大小变大，就执行这个翻转。
直到没有单点翻转能继续增加 cut。

为什么停下来以后有保证？设当前 cut 的权重为 `w(A, B)`。对任意点 $u$，若把 $u$ 翻边不会带来改进，
就说明：

- $u$ 留在当前侧时，与对侧相连的边已经不少；
- 至少不比它与同侧相连的边少。

把这个条件对所有点加起来：

- 同侧内部的边会被数两次；
- 跨 cut 的边也会被数两次；
- 局部最优推出“内部边总量不超过跨边边总量”。

于是所有边的总权重至多是 `2 * w(A, B)`，而最优 cut 的权重当然不超过所有边的总权重。
所以当前 cut 至少是最优值的一半。

#theorem(title: "Max-Cut 单点局部最优的近似性")[
  若一个 cut 对任意单点翻转都不能改进，则它是 Max-Cut 的 `2`-approximation。
]

课程还提到一个工程上常见的变体：只接受“足够大”的改进，例如每次翻转至少带来 `(epsilon / n)` 级别的相对提升。
这样可以避免很多微小改进拖慢运行时间。代价是最后的保证会从 `2` 变成大约 `2 + epsilon`。

== Nash Equilibrium：没人愿意单方面改变

Local search 的另一个重要面貌是博弈中的 best response dynamics。

#definition[
  *Nash equilibrium*：给定多个参与者的策略组合，若没有任何一个参与者能通过单方面改变自己的策略而获益，
  则这个策略组合是 Nash equilibrium。
]

这里的“局部最优”不是一个全局目标的局部最优，而是对每个参与者而言：

- 固定别人不动；
- 自己没有更好的单步反应。

这和算法优化有明显差别。很多博弈没有一个天然的全局目标函数，因此 best response dynamics 不一定收敛。
本讲的 multicast routing with fair cost sharing 是一个幸运例子：它有势函数。

== Fair Cost Sharing Multicast Routing

问题设置如下：

- 有一个有向图，每条边 $e$ 有成本 $c_e$；
- 源点为 $s$；
- 有 $k$ 个 agent，终点分别为 $t_1, dots, t_k$；
- agent $j$ 需要选一条从 $s$ 到 $t_j$ 的路径 $P_j$；
- 如果一条边被 $x$ 个 agent 使用，每个使用者支付 $c_e / x$。

社会最优解最小化所有被使用边的总成本。但 Nash equilibrium 只要求每个 agent 在别人的路径固定时，
不想单方面改走另一条路径。

这个模型里，均衡可能不唯一，也不一定等于社会最优。于是我们关心：

#definition[
  *Price of Stability* 是“最好 Nash equilibrium 的成本”和“社会最优成本”的比值。
]

注意它不是最坏均衡，而是最好均衡。这个定义问的是：如果系统最后能落到某个好均衡，它离全局最优还差多少？

== Rosenthal 势函数

设 $x_e$ 是使用边 $e$ 的 agent 数量，定义调和数：

`H(x) = 1 + 1/2 + ... + 1/x`

再定义势函数：

`Phi(P_1, ..., P_k) = sum_e c_e * H(x_e)`

当某个 agent $j$ 从路径 $P_j$ 改到 $P'_j$ 时：

- 新增使用的边 $f$ 让势函数增加 `c_f / (x_f + 1)`；
- 不再使用的边 $e$ 让势函数减少 `c_e / x_e`。

这正好等于 agent 自己成本的变化。因此，如果 agent 的 best response 让自己成本严格下降，
势函数也严格下降。

#theorem(title: "best response dynamics 会收敛")[
  在 fair cost sharing multicast routing 中，任意严格改进的 best response dynamics 都会在有限步后停在一个 Nash equilibrium。
]

证明只需要两点：

- 势函数每次严格下降；
- 路径组合总数有限。

不过，这个证明只保证会停，不保证运行时间是多项式。slides 最后特别指出：找到任意一个 Nash equilibrium 的多项式时间算法仍是一个重要开放问题。

== Price of Stability 的上界

设 `C(P_1, ..., P_k)` 是一组路径使用到的边的总成本。对任意路径组合，都有：

`C(P_1, ..., P_k) <= Phi(P_1, ..., P_k) <= H(k) * C(P_1, ..., P_k)`

原因是：若一条边被至少一个 agent 使用，则 `1 <= H(x_e) <= H(k)`。

现在从社会最优路径组合 $P^*$ 出发运行 best response dynamics。由于势函数单调下降，最后得到的均衡 $P$ 满足：

`Phi(P) <= Phi(P^*)`

于是：

`C(P) <= Phi(P) <= Phi(P^*) <= H(k) * C(P^*)`

#theorem(title: "fair cost sharing 的 Price of Stability")[
  对 $k$ 个 agent 的 multicast routing with fair cost sharing，存在一个 Nash equilibrium，
  其总成本至多是社会最优成本的 `H(k)` 倍。
]

== 本章小结

#figure(
  caption: [Local search 中三类常见证明对象],
  three-line-table[
    | 场景 | 停止条件 | 证明重点 |
    |:---|:---|:---|
    | Vertex Cover 梯度下降 | 不能删一个点仍保持可行 | 每步目标值下降，最多 $n$ 步 |
    | Max-Cut 单点翻转 | 没有单点翻转能增加 cut | 局部最优推出 `2`-approximation |
    | Fair cost sharing | 没有 agent 能单方面降低成本 | 势函数严格下降，得到 Nash equilibrium |
  ],
)

#tip-block(title: "读 local search 题时先问")[
  解空间是什么？邻居是什么？每一步优化的量是什么？
  如果停下来，它是全局最优、近似最优，还是只是某种均衡？
]
