#import "@preview/theorion:0.4.1": *
#import "@preview/tablem:0.3.0": three-line-table

= 第十九章 Hashing 与 Bloom Filters

#tip-box(title: "这一章的主线")[
  Hashing 用随机化思想把大 universe 映射到小表中，目标是在节省空间的同时保持期望 `O(1)` 查询。
  Bloom filter 更进一步：为了更省空间，接受 false positive，但绝不接受 false negative。
]

== Direct Addressing 的问题

如果 key 来自有限 universe：

`U = {0, 1, ..., m - 1}`

最直接的数据结构是开一个大小为 $m$ 的数组：

- `insert(k, v)`：把 $v$ 放到位置 $k$；
- `find(k)`：访问位置 $k$；
- `delete(k)`：清空位置 $k$。

所有操作都是 `O(1)`。问题是空间太浪费：若 key 是 32-bit 或 64-bit 整数，universe 巨大，
但实际存的 key 可能很少。

Hash table 的想法是：用一个 hash function 把 key 映射到较小数组中。

== Hash Table 与 Collision

一个 hash table 包含：

- key universe $U$；
- 大小为 $m$ 的数组 $T$；
- hash function `h: U -> {0, 1, ..., m - 1}`。

操作变成：

- `insert(k)`：放到 `T[h(k)]`；
- `find(k)`：查 `T[h(k)]`；
- `delete(k)`：从 `T[h(k)]` 删除。

如果 $m << |U|$，空间就比 direct addressing 小得多。

但 collision 不可避免：只要 `|U| > m`，抽屉原理保证存在不同 key 映射到同一位置。

== Closed Addressing 与 Load Factor

Closed addressing，也叫 separate chaining：

- 表中每个位置指向一个链表；
- 所有 hash 到同一位置的 key 都放在这个链表里；
- `find`、`insert`、`delete` 都在对应链表中完成。

若最长链表长度为 `n_hat`，最坏操作成本是 `O(n_hat)`。
若平均链表长度为 `n_bar`，随机 key 的平均操作成本是 `O(n_bar)`。

设表中有 $n$ 个 key，数组大小为 $m$，定义 load factor：

`alpha = n / m`

在 uniform hashing 假设下，每个位置平均有 `alpha` 个 key，因此操作的期望时间是 `O(alpha)`。
实际使用中常保持 `alpha = O(1)`，这样期望操作时间就是 `O(1)`。

== Heuristic Hash Functions

hash function 必须是确定性的：同一个 key 每次要映射到同一个位置，否则无法查找。
但我们又希望它表现得像随机函数，把 key 均匀打散。

常见 heuristic 方法包括：

- division method：`h(k) = k mod m`，通常选 $m$ 为不接近 2 的幂的素数；
- multiplication method：`h(k) = floor(m * (k A mod 1))`，Knuth 建议 `A = (sqrt(5) - 1) / 2`。

这些方法实践中常用，但如果 adversary 知道固定 hash function，仍可以选择一组 key 让冲突严重。

== Universal Hashing

Universal hashing 的思想是：不要固定一个 hash function，而是从一族 hash functions 中随机选一个。

#definition[
  一族 hash functions $H$ 称为 universal hash family，如果对任意不同 key $x != y$，
  从 $H$ 中均匀随机选 $h$ 时都有：

  `Pr[h(x) = h(y)] = 1/m`
]

这里随机的是“选哪一个函数”，不是函数每次计算结果随机。选定以后，$h(k)$ 对同一个 key 仍然固定。

#theorem(title: "universal hashing 的期望冲突数")[
  设 $S$ 是 $n$ 个 key 的集合，$x in S$。若 $h$ 从 universal family 中随机选择，
  则与 $x$ 冲突的 key 的期望个数是 `n / m`。
]

证明用 indicator variables。对每个 $x_i in S$，令 $X_i = 1$ 表示 `h(x_i) = h(x)`。
由 universal hashing，`E[X_i] = 1/m`。所以：

`E[X] = E[X_1 + ... + X_n] = n / m`

这说明无论输入 key 集合是什么，期望链长都可控。

== 一个 universal family 的构造

选一个素数 $p$，满足 $p > m$ 且 $p$ 大于所有 key。

定义：

`h_(a,b)(k) = ((a k + b) mod p) mod m`

其中：

- $a in {1, 2, ..., p - 1}$；
- $b in {0, 1, ..., p - 1}$。

令 $H_(p,m)$ 为所有这样的函数。slides 证明它是 universal。

证明直觉是：对两个不同 key $x$ 和 $y$，先看模 $p$ 后的值：

`r = a x + b mod p`

`s = a y + b mod p`

由于 $p$ 是素数且 $a != 0$，有 $r != s$。并且随机选择 $(a, b)$ 会让不同的 $(r, s)$ 对均匀出现。
最后再对 $m$ 取模，两个值落到同一个桶的概率就是 `1/m`。

== Perfect Hashing

普通 hash table 能保证期望 `O(1)`，但最坏情况下链表仍可能很长。
如果 key 集合是静态的，也就是不需要 `insert`，可以用 perfect hashing 消除所有冲突。

Perfect hashing 使用两层 universal hashing：

1. 第一层表大小取 `m = n`；
2. 第一层 hash function $h$ 把 key 分到各个 bucket；
3. 若第 $j$ 个 bucket 有 $n_j$ 个 key，就建立一个大小为 `n_j^2` 的二级表；
4. 对每个二级表独立随机选择 hash function，直到没有 collision。

为什么二级表取平方大小？若把 $n_j$ 个 key 放进大小 `n_j^2` 的表中，用 universal hashing，
发生任意 collision 的概率至多为 `1/2`。所以期望尝试两次就能找到无冲突的二级 hash function。

空间方面，关键是证明：

`E[sum_j n_j^2] < 2n`

也就是说，虽然每个二级表大小是平方，但所有 bucket 的平方和期望仍然是线性的。
因此 perfect hashing 可以在静态集合上同时做到：

- worst-case `O(1)` find；
- 线性期望空间；
- 不支持一般 insert。

== Bloom Filter：近似集合

Bloom filter 用于实现一个空间很小的 set。

它支持：

- `insert(x)`；
- `find(x)`。

它不支持普通删除，且是 approximate：

- 可能出现 false positive：说 $x$ 在集合里，但其实不在；
- 不会出现 false negative：说 $x$ 不在集合里，那就一定不在。

典型应用是数据库或 P2P 网络中的预过滤：

- 若 Bloom filter 说“不在”，就避免一次昂贵查询；
- 若 Bloom filter 说“在”，再去真实系统查；
- 少量 false positive 只会造成额外查询，不会漏掉真正存在的元素。

== Bloom Filter 的结构

Bloom filter 包含：

- 一个大小为 $m$ 的 bit array，初始全 0；
- $k$ 个独立 hash functions `h_1, ..., h_k`，每个映射到 `{1, ..., m}`。

插入 key $x$：

- 把 `A[h_1(x)]`、`A[h_2(x)]`、...、`A[h_k(x)]` 全部设为 1。

查询 key $x$：

- 读取这 $k$ 个位置；
- 若全为 1，回答“可能在集合中”；
- 若至少一个为 0，回答“不在集合中”。

为什么没有 false negative？如果 $x$ 曾经被插入过，它对应的 $k$ 个位置都被设成了 1。
因此查询时只要看到某个位置为 0，就能确定 $x$ 从未插入。

false positive 来自其它 key 把这 $k$ 个位置都碰巧置成了 1。

== False Positive 概率

假设已经插入 $n$ 个 key，bit array 大小为 $m$，hash function 数量为 $k$。

固定某个位置 $i$。一次 hash 没有打到它的概率是：

`1 - 1/m`

插入 $n$ 个 key 总共做了 $n k$ 次 hash，所以它仍为 0 的概率是：

`p = (1 - 1/m)^(n k) ~= e^(-n k / m)`

因此某个位置为 1 的概率约为：

`1 - e^(-n k / m)`

一次查询出现 false positive，需要 $k$ 个位置全都是 1，所以概率约为：

`f = (1 - e^(-n k / m))^k`

这个式子体现了 Bloom filter 的核心 trade-off：

- $m/n$ 越大，每个元素分到的 bit 越多，false positive 越低；
- $k$ 太小，检查位置太少；
- $k$ 太大，插入时把太多位置置 1，反而让表更快变满。

对 $k$ 求最优，可得：

`k = (m / n) * ln 2`

此时 false positive rate 大约是：

`(1/2)^k ~= 0.6185^(m/n)`

也就是说，错误率随每个元素占用的 bit 数指数下降。

== 删除为什么麻烦

普通 Bloom filter 不能直接删除。若删除 $x$ 时把它对应的 $k$ 个位置设回 0，可能会破坏其它 key：
那些 key 可能也依赖这些位置为 1。

一种改进是 counting Bloom filter：

- 把 bit array 换成 counter array；
- 插入时对应 counter 加 1；
- 删除时对应 counter 减 1；
- 查询时检查 counter 是否全大于 0。

代价是空间更大，并且还要处理 counter overflow。

== 本章小结

#figure(
  caption: [Hashing 到 Bloom filter 的设计取舍],
  three-line-table[
    | 结构 | 支持 | 保证 | 代价 |
    |:---|:---|:---|:---|
    | Direct addressing | find/insert/delete | worst-case `O(1)` | 空间 `O(|U|)` |
    | Chained hash table | find/insert/delete | 期望 `O(1)`，取决于 load factor | 最坏可能 `O(n)` |
    | Universal hashing | 随机选 hash function | 任意 key 集合上期望冲突可控 | 需要 hash family |
    | Perfect hashing | 静态 find/delete | worst-case `O(1)` | 不支持普通 insert |
    | Bloom filter | insert/find | 无 false negative，低 false positive | 不存值，普通版本不能 delete |
  ],
)

#tip-box(title: "选择数据结构时这样想")[
  需要有序操作就不要用 hash table；只要 find/insert/delete 且希望快，hash table 很合适。
  若只想用很小空间预判“不存在”，Bloom filter 往往比精确集合更合适。
]
