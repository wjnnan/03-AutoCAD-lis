# Bug 清单 — 第10轮对抗性审查

> 审查日期：2026-05-16
> 审查范围：atlisp-packages/ 除零风险全局分析 + getpoint/entsel nil 检查深度审查
> 总计发现：18 个 Bug

## 修复状态汇总

| 严重级别 | 发现 | 已修复 | 残留 |
|----------|------|--------|------|
| HIGH | 8 | 8 | 0 |
| MEDIUM | 10 | 10 | 0 |
| LOW | 0 | 0 | 0 |
| **总计** | **18** | **18** | **0** |

---

## 第1部分：除零风险 (6个Bug)

### at-3d/at-3d.lsp

| ID | 行号 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| AAZ-01 | 123 | `(setq len-pre (/ (curve:length route) n))` — n 来自 getint，用户输入0时除零崩溃 | HIGH | ✅ |

修复：`(setq n ...)` 后增加 `(if (or (null n) (<= n 0)) (progn (princ "\n分段数必须为正整数 -- 退出.") (quit)))`

### at-dim/dimarc.lsp

| ID | 行号 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| AAZ-02 | 30 | `(/ ang-all n)` — n 来自 getint，用户输入0时除零崩溃 | HIGH | ✅ |

修复：`(setq n ...)` 后增加 `(if (or (null n) (<= n 0)) (progn (princ "\n等分数量必须为正整数 -- 退出.") (quit)))`

### at-text/inc-word.lsp

| ID | 行号 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| AAZ-03 | 24 | `(/ zc len)` — len 来自 strlen，空文本实体导致 len=0 除零 | MEDIUM | ✅ |

修复：除法前增加 `(if (<= len 0)(setq len 1))` 兜底保护

### composing/cluster-composing.lsp

| ID | 行号 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| AAZ-04 | 23 | `(1- (length clusters))` — 只有一个分堆时返回0，除零 | MEDIUM | ✅ |
| AAZ-05 | 76 | `(1- (length ents))` — 只选一个实体时返回0，除零 | MEDIUM | ✅ |
| AAZ-06 | 120 | `(1- (length clusters))` — 同AAZ-04，composing:group 函数 | MEDIUM | ✅ |

修复：除法前增加 `(if (<= (length clusters/ents) 1) (progn (princ "\n至少需要2个... -- 退出.") (quit)))`

### 已确认安全（非Bug）

以下除零候选经分析确认安全（常量除数或已有保护）：
- sp2pl.lsp:23 — `(if(< segcount 1) (exit))` 已在除法前保护
- bst.lsp:48 — `(/ (length lst) 2)` 常量除数
- hst.lsp:306,316 — 常量除数
- functions.lsp:356 — 工具函数，调用者负责传参
- BlockView.lsp:199,715-717,777 — 常量除数(30, 1024.0, 16)
- jifen.lsp:115-225 — 常量除数(2.0, 1.4)或循环保证非零
- dcl-2.lsp:625,633 — if 分支保护
- rd.lsp:870 — 常量除数 2.0
- dyn-adjust.lsp:156,284-285 — 常量除数 2, 0.01

---

## 第2部分：getpoint/entsel/getdist nil检查缺失 (12个Bug)

### at-cnc/refer.lsp (G代码生成)

| ID | 行号 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| AAZ-07 | 8-10 | 初始刀具参数 getstring/getdist/getreal 均无 nil 检查，取消后 strcat/rtos 传入 nil 崩溃 | HIGH | ✅ |
| AAZ-08 | 19-21 | 换刀分支中同样 getstring/getdist/getreal 无 nil 检查 | HIGH | ✅ |
| AAZ-09 | 200 | getpoint 无 nil 检查，nil 直接传给 `(command ".text" ...)` | HIGH | ✅ |

修复方式：每个输入后立即 nil 检查 + (quit) 退出

### ole/ole.lsp (OLE图片插入)

| ID | 行号 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| AAZ-10 | 26 | `ole:multi-insert` 中 getpoint "插入点" 无 nil 检查 | MEDIUM | ✅ |
| AAZ-11 | 70 | `ole:insert-img` 中 getpoint "插入点" 无 nil 检查 | MEDIUM | ✅ |
| AAZ-12 | 129 | `ole:multi-rasteriamge` 中 getpoint "插入点" 无 nil 检查 | MEDIUM | ✅ |

修复：每个 getpoint 后增加 `(if (null pt-ins) (progn (princ "\n未指定插入点 -- 退出.") (quit)))`

### flange/flange.lsp (法兰绘制)

| ID | 行号 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| AAZ-13 | 57 | getpoint "点选要绘制的位置坐标" 无 nil 检查，nil 直接传给 flange:make | HIGH | ✅ |

修复：增加 `(if (null pt-c) (progn (princ "\n未指定坐标 -- 退出.") (quit)))`

### at-lab/stat.lsp (统计表格)

| ID | 行号 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| AAZ-14 | 76 | `@lab:stat-table` 中 getpoint "表格绘制位置点" 无 nil 检查 | HIGH | ✅ |
| AAZ-15 | 169 | `@lab:stat-table-all` 中 getpoint 同样问题 | HIGH | ✅ |

修复：两个 getpoint 均增加 nil 检查 + quit

### list-rec-wxh/list-rec-wxh.lsp (矩形统计列表)

| ID | 行号 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| AAZ-16 | 99 | getpoint "请点取列表位置" 无 nil 检查，nil 传给 entity:make-text | MEDIUM | ✅ |

修复：增加 `(if (null pt1) (progn (princ "\n未指定位置 -- 退出.") (quit)))`

### at-block/at-block.lsp (块操作)

| ID | 行号 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| AAZ-17 | 370 | `@block:change-base-pt` 中 entsel 的 `(if ...)` 为空体，缺少 progn 包裹后续代码；用户取消后 blkref=nil 导致崩溃 | MEDIUM | ✅ |
| AAZ-18 | 453-454 | `@block:explode-all` 中 getpoint/getcorner 无 nil 检查，nil 传给 `(ssget "c" ...)` | MEDIUM | ✅ |

修复：AAZ-17 改用 progn 包裹 if 体；AAZ-18 增加两个 nil 检查 + quit

---

## 第10轮关键修复说明

1. **除零分析策略**：对 atlisp-packages/ 下 40+ 处 `/` 除法逐一分析，排除常量除数和已有保护的代码，确认 6 处实际可触发除零 Bug。

2. **getpoint/getdist 修复模式**：统一使用 `(if (null var) (progn (princ "\n提示信息") (quit)))` 模式，与第7-9轮保持一致。

3. **编码处理**：at-cnc/refer.lsp 使用 UTF-8 中文，ole.lsp/list-rec-wxh/flange 使用 GBK 中文，修复时精确匹配字节序列。

---

## 跨轮累计

| 轮次 | 发现Bug | 已修复 | 残留 |
|------|---------|--------|------|
| 第1轮 | 27 | 19 | 8 |
| 第2轮 | 1 | 1 | 7 |
| 第3轮 | 0 | 0 | 7 |
| 第4轮 | 65 | 51 | 22 |
| 第5轮 | 45 | 19 | 48 |
| 第6轮 | 49 | 48 | 61 |
| 第7轮 | 17 | 13 | 65 |
| 第8轮 | 13 | 13 | 52 |
| 第9轮 | 10 | 10 | 45 |
| **第10轮** | **18** | **18** | **45** |
| **累计** | **245** | **200** | **45** |

---

## 待第11轮处理

- atlisp-packages/ 剩余 ~300 个 .lsp 文件继续深度审查
- atlisp-core/ 目录全面审查
- XDrx-API/ 目录全面审查
- unified-lib/ 全面审查
- 第4-5轮残留 MED/LOW Bug 复检（45个）
- 全项目 `vla-SendCommand` / 命令注入风险审查
- 全项目 `nentsel` 使用审查
- 全项目 `ssget` 过滤条件有效性审查
- 大型文件逻辑审查（墨鱼工具箱.lsp 9485行、align-array.lsp 等）
