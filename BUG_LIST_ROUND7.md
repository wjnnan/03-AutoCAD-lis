# Bug 清单 — 第9轮对抗性审查

> 审查日期：2026-05-15 ~ 2026-05-16
> 审查范围：Network-Design-Tools/ 深度审查、SyncBlock/ + DiffCheck/ 深度审查、atlisp-packages/ 模式搜索
> 总计发现：10 个 Bug

## 修复状态汇总

| 严重级别 | 发现 | 已修复 | 残留 |
|----------|------|--------|------|
| HIGH | 5 | 5 | 0 |
| MEDIUM | 5 | 5 | 0 |
| LOW | 0 | 0 | 0 |
| **总计** | **10** | **10** | **0** |

---

## 第1部分：Network-Design-Tools/ 深度审查 (3个Bug)

### 审查结果

对 Network-Design-Tools/ 下所有 26 个 .lsp 文件逐一审查。大部分文件代码质量良好，entsel/getpoint 均有 nil 检查保护。SyncBlock.lsp 和 DiffCheck.lsp 代码质量很高，所有 COM 调用已包裹 vl-catch-all-apply。

### 已修复 (3)

| ID | 文件 | 行号 | 描述 | 级别 | 状态 |
|----|------|------|------|------|------|
| NDT-01 | PlaceNAP.lsp | 14 | `c:polestamp`: `(setq stamppos (getpoint ...))` 无 nil 检查，取消时 nil 传入 `(command "_MTEXT" stamppos ...)` 导致异常 | HIGH | ✅ |
| NDT-02 | PoleStamp.lsp | 13 | 与 PlaceNAP.lsp 完全相同的文件（均为 `c:polestamp`），同一个 getpoint nil 检查缺失 | HIGH | ✅ |
| NDT-03 | MeasureCallouts.lsp | 37 | `c:MeasureCallouts`: `(setq midPoint (getpoint ...))` 无 nil 检查，取消时 nil 传入 `(command "_.TEXT" ... midPoint ...)` 导致异常 | HIGH | ✅ |

### 无需修改的文件

以下文件均已正确保护所有 entsel/getpoint 调用：
- InsertNAP.lsp, StreetLabel.lsp, SumFootage.lsp, SidewalkTrim.lsp
- MeasureStationNum.lsp, MeasureArrow.lsp, MoveToCenter.lsp
- AlignToCenter.lsp, DrawFiber.lsp, ObjectInfo.lsp
- ManageLayers.lsp, CenterText.lsp, JustifyTextToCenter.lsp
- ConvertNAPs.lsp, CopyLayouts.lsp, FixPDFImport.lsp
- ImportGeoCSV.lsp, CircleNumber.lsp (Others' Routines)
- MAV.lsp (Alan J. Thompson 库), ReadCSV-V1-3.lsp (Lee Mac 库)
- HelperFunctions.lsp, Create-LSP-Tutorial.lsp
- measure callouts.lsp (Others' Routines 版本)

---

## 第2部分：SyncBlock/ + DiffCheck/ 审查 (0个Bug)

| 文件 | 审查结果 |
|------|----------|
| SyncBlock.lsp | 所有 entsel 有 nil 保护，所有 vla-* 调用包裹 vl-catch-all-apply，`=` 比较使用正确。代码质量很高。 |
| DiffCheck.lsp | getreal 有 nil 保护，entget 使用正确。COMMAND 调用有 CMDACTIVE 保护。代码质量很高。 |

---

## 第3部分：atlisp-packages/ 模式搜索 (7个Bug)

### 已修复 (7)

| ID | 文件 | 行号 | 描述 | 级别 | 状态 |
|----|------|------|------|------|------|
| AT-01 | at-text/at-text.lsp | 53 | `@text:multi-text-align`: `(setq val (getdist "\n行距："))` 无 nil 检查，取消时 val=nil 导致后续 `(* m val)` 算术错误 | HIGH | ✅ |
| AT-02 | at-text/at-text.lsp | 54 | `@text:multi-text-align`: `(setq p (getpoint ...))` 无 nil 检查，取消时 `(car nil)`=nil 导致文本插入位置错误 | MEDIUM | ✅ |
| AT-03 | at-text/at-text.lsp | 75 | `@text:insert-time`: `(setq pt0 (getpoint ...))` 无 nil 检查，取消时 nil 传入 entity:make-text | MEDIUM | ✅ |
| PLOT-01 | at-plot/train.lsp | 8 | `@plot:train`: `(setq pt1 (getpoint "左下角: "))` 无 nil 检查，取消时 `(mapcar '- pt2 pt1)` 中 nil 导致算术错误 | HIGH | ✅ |
| COORD-01 | at-dim/coord.lsp | 7 | `at-dim:menu-zbbz`: `(setq pt-b (getpoint ...))` 无 nil 检查，取消时 `(ssget nil)` 变为通用选择，后续坐标计算全部异常 | MEDIUM | ✅ |
| LAB-01 | at-lab/get-cross-from-2layer.lsp | 11 | `@lab:get-cross-from-2layer`: `(setq pt1 (getpoint ...))` 无 nil 检查，取消时 `(ssget "c" nil pt2 ...)` 选择集失效 | MEDIUM | ✅ |
| QR-01 | qrencode/qrencode.lsp | 48 | `qrencode:make`: `(setq ptbase (getpoint ...))` 无 nil 检查，取消时 nil 传入 polar/entity:make-rectangle 导致二维码位置错误 | MEDIUM | ✅ |

### 无需修改的文件

以下 atlisp-packages/ 子目录中未发现新增问题：
- at-block/, at-color/, at-select/, base/, at-stat/, at-structure/
- at-text/mtext.lsp, at-text/word-lab.lsp — 第8轮已修复
- pdftk/pdftk.lsp — 第8轮已修复
- at-cnc/refer.lsp — 所有 getpoint 在 and 条件内，受短路保护
- at-select/at-select.lsp — 第8轮已修复

### eq 字符串比较搜索

全项目 `(eq (` 函数调用仅剩 2 处，均为正确用法：
- at-block/copy-to-blk.lsp:13 — `(eq ... :vlax-true)`（符号比较）
- at-text/at-text.lsp:252 — `(eq (type ...) 'variant)`（类型符号比较）

---

## 关键修复说明

1. **Network-Design-Tools**: 代码由 Alex McTeague 编写，整体质量很高。27 个文件中 25 个已经正确保护了所有 entsel/getpoint 调用。唯一例外是 PlaceNAP/PoleStamp（相同文件的两份副本）和 MeasureCallouts.lsp。

2. **at-text.lsp 多重修复**: 该文件是作者 VitalGG 的"唯他工具集"文本操作模块，包含 3 个函数在连续行上有未保护的 getdist/getpoint 调用。

3. **train.lsp 修复**: `@plot:train` 中的 pt1 getpoint 如果用户取消，会立即在 `(mapcar '- pt2 pt1)` 中崩溃。改为在取消时打印消息并退出。

4. **coord.lsp**: 坐标标注的核心函数，未保护的 pt-b getpoint 会导致后续所有坐标计算基于错误的选择集。

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
| 第8轮 | 13 | 13 | 45 |
| 第9轮 | 10 | 10 | 45 |
| **累计** | **227** | **182** | **45** |

---

## 待第10轮处理

- atlisp-packages/ 剩余 ~300 个 .lsp 文件深度审查（本次仅模式搜索，未逐文件审查所有函数）
- atlisp-core/ 目录审查
- XDrx-API/ 目录审查
- unified-lib/uc-atlisp-adapter.lsp 审查
- 第4-5轮残留 MED/LOW Bug 持续复检
- 大型文件逻辑审查（zero-division, 无限循环, nil 传播链）
