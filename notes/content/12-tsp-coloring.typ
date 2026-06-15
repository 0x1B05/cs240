#import "@local/notes:0.1.0": *

= 第十二章 TSP、最长路与 3-着色

#tip-block(title: "这一章的共同主题")[
  看起来完全不同的三个问题：
  旅行商、最长路、图着色，
  最后都能被放进 NP-complete 的同一张地图里。
  它们表面题意不同，但都在要求一个全局一致的组合结构。
]

== TSP 的 decision version

#definition[
  *TSP*（decision version）：给定 $n$ 个城市、距离函数 $d(u, v)$ 以及阈值 $D$，
  问是否存在一条长度至多为 $D$ 的 tour，恰好访问每个城市一次并回到起点。
]

注意课程这里故意用的是判定版本，而不是“求最短 tour 的长度”。
原因和上一章一样：复杂性理论优先研究 yes/no 形式。

== Hamiltonian cycle 到 TSP

先看 Hamiltonian cycle 到 TSP 的归约：

#theorem(title: "HAM-CYCLE <=_p TSP")[
  Hamiltonian cycle 可多项式归约到 TSP。
]

给定图 $G = (V, E)$，构造 TSP 实例如下：

- 每个顶点变成一个城市；
- 若 $(u, v) in E$，则令 `d(u, v) = 1`；
- 否则令 `d(u, v) = 2`；
- 设阈值 `D = n`。

于是：

- 若原图有 Hamiltonian cycle，那么沿着该环走一圈，正好用了 $n$ 条“长度 1”的边，
  总长度就是 $n$；
- 若某个 TSP tour 长度至多 $n$，由于一共必须走 $n$ 条边，而每条边长度至少为 1，
  所以每条边都只能取 1，这意味着这些边全部对应原图中的真实边，
  从而构成一个 Hamiltonian cycle。

#important-block(title: "这个归约为什么经典")[
  它展示了一个常见技巧：
  用一组非常简单的权重（这里只用 1 和 2），
  把“能不能走”编码成“走了会不会超预算”。
]

== 最短路容易，最长简单路为什么难

接着比较 *shortest path* 与 *longest simple path*。

- 最短路在前面课程里已经是 `P` 中的基本问题；
- 最长简单路却是 NP-complete 风格的问题。

#definition[
  *LONGEST-PATH*：给定有向图 $G = (V, E)$ 与整数 $k$，
  问是否存在一条长度至少为 $k$ 的简单路径。
]

这里困难的根源不是“路径长短”本身，而是“simple”这个限制：

- 如果允许重复顶点/边，很多最长问题会因正环而失去意义；
- 一旦强制 simple，问题又变成一种全局排列/覆盖结构。

可以把 `3-SAT <=_p DIR-HAM-CYCLE` 的构造略作调整：
去掉从终点回到起点的那条回边，就能得到 `3-SAT <=_p LONGEST-PATH`。

所以最长简单路的困难，本质上与 Hamiltonian 式遍历困难是一脉相承的。

== 3-Color：用三种颜色解决所有冲突？

#definition[
  *3-COLOR*：给定无向图 $G$，问是否能把每个顶点染成红、绿、蓝三色之一，
  使任意相邻顶点颜色不同。
]

第一次看它时，很多人会误以为：

- “不就是一个局部冲突约束吗？”
- “是不是能像 BFS 染二分图那样一路贪心下去？”

但关键差别在于：

- 2-color 时只需判断奇环，结构极其刚性；
- 3-color 时每个局部选择都会影响远处可选空间，约束传播变得全局化。

== 一个很实际的应用：寄存器分配

这里特别提到了 *register allocation*。

编译器里，每个变量活跃的时间段可能互相重叠。若两个变量在同一时刻都活跃，
它们就不能被放进同一个寄存器。

于是可以建立 *interference graph*：

- 顶点表示变量；
- 边表示两个变量同时 live，因此不能共用寄存器。

这时：

- 若机器只有 $k$ 个寄存器；
- 是否能完成分配，

就等价于问：

- 这张 interference graph 是否 `k`-colorable。

#remark(title: "为什么这是个好例子")[
  它说明 NP-complete 不是“图论课里自娱自乐的问题”。
  编译器后端里一个非常工程化的任务，抽象出来就是图着色。
]

== 从 3-SAT 到 3-COLOR

这个归约也靠 gadget。先分成三块看：

1. 基准三角形：
   先造三个特殊顶点 `T`、`F`、`B`，并把它们连成三角形。
   因此在任意合法 3-coloring 中，这三点必然使用三种不同颜色。
2. literal gadget：
   对每个 literal 建一个点，并把它连到 `B`。
   这样它只能取 `T` 或 `F` 两种颜色；
   再把 `$x$` 与 `¬x` 相连，于是它们必须一真一假。
3. clause gadget：
   对每个 clause 加入一个更复杂的小图，
   其作用是：若该 clause 的三个 literal 全都取 `F`，则这个 gadget 无法被合法染色；
   反之只要其中至少一个 literal 取 `T`，就能完成染色。

这样就把“每个 clause 至少一个 literal 为真”准确翻译成了“每个 clause gadget 可染色”。

#tip-block(title: "Clause gadget 先记语义")[
  在 `3-SAT <=_p 3-COLOR` 中，
  clause gadget 的唯一使命就是：
  *禁止“三个输入全是假”这一种情况。*
  只要你明白这一点，看到不同教材画法也不会慌。
]

== 这类着色归约为什么自然

图着色特别适合编码“互斥选择”：

- 相连表示“不能相同”；
- 三种颜色可以被解释成三种状态；
- 特殊基准点能把颜色语义固定下来，而不是让整图任意 permute。

所以 3-color 看似是几何/图论味很浓的问题，实质上也能承载布尔逻辑：

- `T/F` 表真假；
- `B` 只是第三种保底颜色；
- clause gadget 则在图论语言里实现逻辑“OR”。

== 本章小结

#figure(
  caption: [三类问题的复杂性直觉],
  three-line-table[
    | 问题 | 表面形式 | 难点 |
    |:---|:---|:---|
    | TSP | 走一圈并控制总长度 | 是否存在覆盖所有点的全局顺序 |
    | LONGEST-PATH | 找尽量长的简单路 | simple 约束带来全局排列难度 |
    | 3-COLOR | 给点染 3 种颜色 | 局部冲突约束会远距离传播 |
  ],
)

#tip-block(title: "读完这一章先检查这些")[
  - 复述 `HAM-CYCLE <=_p TSP` 的 1/2 权重构造；
  - 解释为什么 longest simple path 和 shortest path 的复杂性完全不同；
  - 理解 interference graph 与寄存器分配的关系；
  - 抓住 `3-SAT <=_p 3-COLOR` 中 `T/F/B` 与 clause gadget 的语义。
]
