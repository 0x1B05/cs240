#import "@preview/theorion:0.4.1": *
#import "@preview/tablem:0.3.0": three-line-table

= 第十七章 Amortized Analysis：把昂贵操作摊开看

#tip-box(title: "这一章不要和 average-case 混淆")[
  摊还分析不是随机输入上的平均表现。它研究的是最坏操作序列中的总成本，
  只是把总成本平均分摊到每次操作上。
]

== 为什么需要摊还分析

如果一个数据结构的某个操作最坏情况下要 `O(n)`，最粗糙的上界会说：

`n` 次操作总共 `O(n^2)`。

但这常常太悲观。很多数据结构的昂贵操作不可能每次都发生：

- 栈里的元素被 push 以后最多被 pop 一次；
- 二进制计数器低位经常翻转，高位很少翻转；
- 动态数组扩容很贵，但扩容之间会有很多便宜插入；
- Fibonacci heap 的 delete-min 会整理很多树，但 insert、decrease-key 会把工作延后。

摊还分析的目标是证明：任意长度为 `n` 的操作序列，总成本其实只有 `O(n)` 或某个更紧上界。

== 三种方法

课程给了三种摊还分析方式：

- aggregate analysis：直接证明 `n` 次操作的总成本，再除以 `n`；
- accounting method：人为给操作“收费”，多收的信用存到对象上，未来昂贵操作用信用支付；
- potential method：把信用统一写成数据结构状态的势能。

三者本质上是在做同一件事：让便宜操作提前为未来的昂贵操作付账。

== 栈与 MULTIPOP：aggregate analysis

栈支持：

- `PUSH(S, x)`；
- `POP(S)`；
- `MULTIPOP(S, k)`：连续弹出最多 `k` 个元素，直到栈空。

单次 `MULTIPOP` 的最坏成本是 `O(n)`，但一段从空栈开始的 `n` 次操作序列，总成本只有 `O(n)`。

理由很简单：每个对象最多被 push 一次，也最多被 pop 一次。无论是普通 `POP` 还是 `MULTIPOP`，
总弹出次数都不超过总 push 次数。因此：

- 所有 push 的成本总和至多 `n`；
- 所有 pop 的成本总和至多 `n`；
- 总成本 `O(n)`；
- 每次操作的摊还成本 `O(1)`。

== 二进制计数器：不要只看最坏一次

二进制计数器从全 0 开始，每次 `INCREMENT` 会翻转若干位：

- 最低位每次都翻转；
- 第 1 位每两次翻转一次；
- 第 2 位每四次翻转一次；
- 第 $i$ 位每 `2^i` 次翻转一次。

所以前 `n` 次 increment 的总翻转次数至多：

`n + n/2 + n/4 + ... < 2n`

因此每次 increment 的摊还成本是 `O(1)`。

这个例子很重要，因为单次操作最坏可能翻转很多位，但这种最坏情况不会连续出现。

== Accounting method：把信用放到对象上

对栈操作可以这样收费：

- `PUSH` 收 2；
- `POP` 收 0；
- `MULTIPOP` 收 0。

每次 push 一个对象时：

- 1 个单位支付这次 push 的真实成本；
- 1 个单位作为信用放在这个对象上。

以后这个对象被普通 `POP` 或 `MULTIPOP` 弹出时，就用它身上的信用支付弹出成本。
由于一个对象至多被弹出一次，信用不会不够。

对二进制计数器也类似：

- 当某一位从 0 变成 1 时，收 2；
- 1 个单位支付本次翻转；
- 1 个单位存到这个 1 位上；
- 当它以后从 1 变成 0 时，用存好的信用支付。

每次 increment 最多把一个 0 变成 1，因此收 2 足够覆盖所有未来清零。

== Potential method：把信用写成势能

势能法用一个函数 `Phi(D)` 描述数据结构状态 $D$ 中存了多少“未来可用的信用”。

第 $i$ 次操作的真实成本为 $c_i$，操作前后状态分别为 $D_(i-1)$ 和 $D_i$。定义摊还成本：

`c_hat_i = c_i + Phi(D_i) - Phi(D_(i-1))`

把所有操作加起来会发生 telescoping：

`sum c_hat_i = sum c_i + Phi(D_n) - Phi(D_0)`

如果能保证 `Phi(D_0) = 0` 且所有状态都有 `Phi(D_i) >= 0`，那么：

`sum c_i <= sum c_hat_i`

也就是说，摊还成本总和是实际成本总和的上界。

#remark(title: "势能的直觉")[
  当一次操作被多收费时，势能上升，相当于把钱存进系统。
  当一次操作真实成本很高时，势能下降，相当于拿以前存的钱来支付。
]

== 势能法看栈

令势能为栈中对象个数：

`Phi(D) = |S|`

则：

- `PUSH`：真实成本 1，势能增加 1，摊还成本 2；
- `POP`：真实成本 1，势能减少 1，摊还成本 0；
- `MULTIPOP`：若弹出 $k$ 个对象，真实成本 $k$，势能减少 $k$，摊还成本 0。

所以每个操作摊还 `O(1)`。

== 势能法看二进制计数器

令势能为当前计数器中 1 的个数：

`Phi(D_i) = b_i`

假设第 $i$ 次 increment 把 $t_i$ 个连续的 1 变成 0，并把下一个 0 变成 1。真实成本为：

`c_i = t_i + 1`

势能变化至多是：

`Phi(D_i) - Phi(D_(i-1)) <= 1 - t_i`

所以摊还成本：

`c_hat_i <= (t_i + 1) + (1 - t_i) = 2`

这给出了同样的 `O(1)` 摊还成本。

== Dynamic Table：扩容为什么仍是常数摊还

动态数组的典型策略是：

- 若数组没满，插入末尾，成本 `O(1)`；
- 若数组满了，申请两倍大小的新数组，把旧元素复制过去，再插入；
- 这样 load factor 始终至少为 `1/2`。

从 aggregate analysis 看，前 `n` 次插入中，扩容复制的规模是：

`1 + 2 + 4 + ... + n = O(n)`

加上 `n` 次普通插入，总成本还是 `O(n)`，每次插入摊还 `O(1)`。

势能法可以取：

`Phi(D_i) = 2 * num_i - size_i`

其中 `num_i` 是当前元素数，`size_i` 是数组容量。刚扩容后 `num_i = size_i / 2`，势能为 0；
数组越接近满，势能越高，正好为下一次扩容存钱。

== Fibonacci Heap：把整理工作延后

Fibonacci heap 是摊还分析的经典大例子。它的目标是让某些图算法中频繁出现的 `decrease-key` 更便宜。

二叉堆中：

- `insert`、`delete-min`、`decrease-key` 通常都是 `O(log n)`。

Fibonacci heap 的摊还复杂度是：

- `insert`：`O(1)`；
- `find-min`：`O(1)`；
- `union`：`O(1)`；
- `decrease-key`：`O(1)`；
- `delete-min`：`O(log n)`；
- `delete`：`O(log n)`。

这能把 Dijkstra 和 Prim 中大量 `decrease-key` 的代价从 `O(E log V)` 降到摊还 `O(E)`，
得到 `O(E + V log V)` 的理论上界。

== Fibonacci Heap 的结构与势函数

Fibonacci heap 是一组 heap-ordered trees 组成的森林：

- 每棵树满足父节点 key 不大于孩子 key；
- 所有树根放在 root list 中；
- 维护一个指向最小根的指针；
- 节点可以被标记，表示它已经失去过一个孩子；
- root 永远不标记。

记：

- `trees(H)`：root list 中树的数量；
- `marks(H)`：被标记节点的数量。

势函数取：

`Phi(H) = trees(H) + 2 * marks(H)`

这个势函数的含义是：

- root list 中树越多，未来 `delete-min` 需要 consolidate 的工作越多；
- marked nodes 越多，未来 `decrease-key` 触发 cascading cut 时能释放更多势能。

== Insert 与 Union

`insert` 只创建一个 singleton tree，加入 root list，并更新 min 指针。

- 真实成本 `O(1)`；
- 树数增加 1；
- 势能增加 1；
- 摊还成本 `O(1)`。

`union` 只把两个 root list 拼接起来，并取两个 min 指针中较小者。

- 真实成本 `O(1)`；
- 新 heap 的树数和标记数正好是两个旧 heap 相加；
- 势能变化为 0；
- 摊还成本 `O(1)`。

== Delete-Min 与 Consolidate

`delete-min` 是 Fibonacci heap 最贵的操作。流程是：

1. 删除当前最小根；
2. 把它的所有孩子加入 root list，并取消标记；
3. 对 root list 做 consolidate，使任意两个根的 degree 不同；
4. 重新扫描 root list 找到新的 min。

consolidate 的核心是 linking operation：若两个根有相同 degree，就把 key 较大的根连到 key 较小的根下面。
这样 root list 中相同 degree 的树会被合并掉。

设 $D(n)$ 是 heap 中任意节点的最大 degree。delete-min 的真实成本看起来依赖当前 root list 的长度 `trees(H)`，
但这些多出来的树正好会让势能下降。摊还后只剩：

`O(D(n))`

后面会证明 Fibonacci heap 中 $D(n) = O(log n)$，所以 `delete-min` 摊还 `O(log n)`。

== Decrease-Key 与 Cascading Cut

`decrease-key(x)` 先降低节点 $x$ 的 key。

- 如果 heap order 没被破坏，只需更新 min 指针；
- 如果 $x$ 比父节点更小，就把 $x$ 子树切下来放进 root list；
- 若父节点是 root，停止；
- 若父节点未标记，标记它，表示它已经失去一个孩子；
- 若父节点已标记，继续把父节点也切下来，这叫 cascading cut。

标记规则的意义是：一个非 root 节点可以失去一个孩子；一旦失去第二个孩子，就必须被切到 root list。

假设一次 `decrease-key` 触发了 $c$ 次切割：

- 真实成本是 `O(c)`；
- 每次切割会让 root list 多一棵树；
- cascading cut 会清除若干 marked nodes；
- 势函数中的 `2 * marks(H)` 足够支付这些切割。

因此 `decrease-key` 的摊还成本是 `O(1)`。

== 为什么最大 degree 是对数级

最后一个关键引理是：

#theorem(title: "Fibonacci heap 的 degree bound")[
  在含 $n$ 个节点的 Fibonacci heap 中，任意节点的 degree 都是 `O(log n)`。
]

证明直觉是：一个节点 degree 越大，它的子树必须越大。

设节点 $x$ 的孩子按被 link 到 $x$ 的时间顺序为 $y_1, y_2, dots, y_k$。
当 $y_i$ 被 link 到 $x$ 时，$x$ 已经有至少 $i-1$ 个孩子，所以 $y_i$ 当时 degree 至少为 $i-1$。
之后 $y_i$ 最多只能失去一个孩子；如果失去第二个，就会被 cut 到 root list。因此：

- $y_1$ 的 degree 至少 0；
- 对 $i >= 2$，$y_i$ 的 degree 至少 $i-2$。

于是最小子树规模满足 Fibonacci 式增长：

`size(x) >= F_(k+2) >= phi^k`

其中 `phi = (1 + sqrt(5)) / 2`。既然整棵 heap 只有 $n$ 个节点，就有：

`n >= size(x) >= phi^k`

所以：

`k <= log_phi n`

这就证明了 `D(n) = O(log n)`。

== 本章小结

#figure(
  caption: [摊还分析的几种典型势能],
  three-line-table[
    | 数据结构 | 势能/信用 | 昂贵操作为什么能摊开 |
    |:---|:---|:---|
    | 栈 | 栈中对象数 | 每个对象最多弹出一次 |
    | 二进制计数器 | 当前 1 的个数 | 高位很少翻转，1 位为清零存钱 |
    | 动态数组 | `2 * num - size` | 越接近满，越为扩容存钱 |
    | Fibonacci heap | `trees + 2 * marks` | 延迟整理 root list，marked nodes 支付级联切割 |
  ],
)

#tip-box(title: "做摊还分析时的检查点")[
  先找“贵操作为什么不能连续发生”。如果这个原因能绑定到对象上，用 accounting；
  如果能绑定到整个状态上，用 potential method。
]
