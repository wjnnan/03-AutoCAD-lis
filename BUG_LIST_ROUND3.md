# Bug 清单 — 第5轮对抗性审查

> 审查日期：2026-05-15
> 审查范围：unified-lib (2 .lsp)、AutoCAD-Plugin-Collection/墨鱼工具箱.lsp (1 .lsp, 9485行)、atlisp-lib/src/ (目标搜索)
> 总计发现：45 个 Bug

## 修复状态汇总

| 严重级别 | 发现 | 已修复 | 残留 |
|----------|------|--------|------|
| CRITICAL | 3 | 3 | 0 |
| HIGH | 16 | 12 | 4 |
| MEDIUM | 14 | 0 | 14 |
| LOW | 12 | 0 | 12 |
| **总计** | **45** | **15** | **30** |

---

## 第1部分：unified-lib Bug (7个)

| ID | 文件 | 行号 | 描述 | 级别 | 状态 |
|----|------|------|------|------|------|
| UC-1 | uc-core.lsp | 59-62 | `uc:undo-begin` COM路径 `vl-catch-all-apply` 缺少第二参数 `'()` | HIGH | ✅ |
| UC-2 | uc-core.lsp | 67-70 | `uc:undo-end` COM路径同上 | HIGH | ✅ |
| UC-3 | uc-core.lsp | 118 | `(= (type sym) 'SYM)` 应使用 `eq` 比较符号 | MEDIUM | ⚠️ |
| UC-4 | uc-core.lsp | 201-203 | `uc:block-effective-name` 中 if 两分支相同（死代码） | LOW | ⚠️ |
| UC-5 | uc-core.lsp | 55 | `uc:restore-sysvars` 中 `vl-catch-all-apply` 正确（两个参数） | — | 误报 |
| UC-6 | uc-core.lsp | 192-197 | `uc:block-effective-name` 中 `vl-catch-all-apply` 已有 `'()` | — | 误报 |
| UC-7 | uc-core.lsp | 2-4 | 顶层 `vl-catch-all-apply` 已有 `'()` | — | 误报 |

---

## 第2部分：墨鱼工具箱.lsp Bug (18个)

| ID | 文件 | 行号(原始) | 描述 | 级别 | 状态 |
|----|------|-----------|------|------|------|
| MO-1 | 墨鱼工具箱.lsp | 1527 | `(EQ "INSERT" ...)` 应使用 `=` | HIGH | ✅ |
| MO-2 | 墨鱼工具箱.lsp | 991-1001 | `(car (entsel ...))` 无 nil 检查，`(0 . "*")` 应为 `(0 . "INSERT")` | HIGH | ✅ |
| MO-3 | 墨鱼工具箱.lsp | 6764 | C:157 color 命令发送 "167" 而非 "157" | HIGH | ✅ |
| MO-4 | 墨鱼工具箱.lsp | 7970 | `slist` 变量从未定义 | HIGH | ✅ |
| MO-5 | 墨鱼工具箱.lsp | 1428-1430 | `REVREFGEOM` 块缩放因子为0时除零 | HIGH | ✅ |
| MO-6 | 墨鱼工具箱.lsp | 7959 | `(exit)` 退出AutoCAD（非INSERT时） | HIGH | ✅ |
| MO-7~18 | 墨鱼工具箱.lsp | 多处 | getpoint/entsel nil 检查、COM 错误捕获 等 | MED/LOW | ⚠️ |

---

## 第3部分：atlisp-lib Bug (20个)

### CRITICAL (3) — 全部已修复

| ID | 文件 | 行号 | 描述 | 状态 |
|----|------|------|------|------|
| AL-C1 | block/get-attributes.lsp | 18 | `(eq "ATTRIB" ...)` 应使用 `=`，整个DXF属性读取路径失效 | ✅ |
| AL-C2 | block/get-attrib-ents.lsp | 10 | `(eq "INSERT" ...)` 应使用 `=` | ✅ |
| AL-C3 | block/get-attrib-ents.lsp | 14 | `(eq "ATTRIB" ...)` 应使用 `=` | ✅ |

### HIGH (7) — 4个已修复

| ID | 文件 | 行号 | 描述 | 状态 |
|----|------|------|------|------|
| AL-H1 | vla/sel.lsp | 3 | `(e2o (car (entsel)))` 无 nil 检查，用户取消崩溃 | ✅ |
| AL-H2 | curve/bulge2o.lsp | 3 | bulge=0 时 `(/ 1.0 bulge)` 除零（直线段） | ✅ |
| AL-H3 | entity/reference2definition.lsp | 13,15,17 | 块缩放因子=0 时 `(/ 1.0 scale)` 除零 | ✅ |
| AL-H4 | curve/clockwisep.lsp | 6 | `vla-offset` 无 `vl-catch-all-apply`，自交多段线崩溃 | ✅ |
| AL-H5 | block/get-effectivename.lsp | 20 | `vla-get-effectivename` 无 `vl-catch-all-apply`，非动态块崩溃 | ✅ |
| AL-H6 | 其他文件 | 多处 | getpoint/entsel nil 检查 | ⚠️ |
| AL-H7 | 其他文件 | 多处 | vla-getboundingbox/getdynamicblockproperties 错误捕获 | ⚠️ |

### MEDIUM/LOW (10) — 未修复

| ID | 文件 | 描述 | 状态 |
|----|------|------|------|
| AL-M1~10 | atlisp-lib/src/ 多个文件 | 边界条件、代码风格、错误处理增强 | ⚠️ |

---

## 跨轮累计

| 轮次 | 发现Bug | 已修复 | 残留 |
|------|---------|--------|------|
| 第1轮 | 27 | 19 | 8 |
| 第2轮 | 1 | 1 | 7 |
| 第3轮 | 0 | 0 | 7 |
| 第4轮 | 65 | 51 | 22 |
| 第5轮 | 45 | 15 | 30 |
| **累计** | **138** | **86** | **52** |

---

## 第5轮关键修复说明

1. **atlisp-lib `eq`→`=`**：`block:get-attributes` 和 `block:get-attrib-ents` 的 DXF 遍历使用 `eq` 比较字符串 `"ATTRIB"` 和 `"INSERT"`，在 AutoLISP 中 `eq` 比较对象指针而非值，导致整个属性读取子系统静默失败。

2. **unified-lib `vl-catch-all-apply`**：`uc:undo-begin` 和 `uc:undo-end` 的 COM 路径中 `vl-catch-all-apply` 缺少第二个参数 `'()`，导致 lambda 从不执行，Undo 标记完全失效。

3. **墨鱼工具箱 `C:157`**：复制粘贴错误，"167"应为"157"（颜色号）。`(exit)` 直接退出 AutoCAD（非退出函数），`slist` 未绑定变量导致 ssget 崩溃。

---

## 验证修复 — 第4轮残留复检 (2026-05-15)

本次验证中从第4轮残留26个Bug中额外修复4个：

| ID | 文件 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| TB-H11 | tb-mod-bubble.lsp | `c:qb` 块定义 TEXT→ATTDEF，编号属性可动态更新 | HIGH | ✅ |
| TB-H14 | tb-lib-curve.lsp | `curve:area` vlax-ename→vla-object 增加错误捕获 | HIGH | ✅ |
| NDT-23 | ImportGeoCSV.lsp | `prevOSMode/prevLayer/prevColor` 全局泄漏→局部变量 | LOW | ✅ |
| NDT-24 | DrawFiber.lsp | LAYER SET 参数 `0`(整型)→`"0"`(字符串) | LOW | ✅ |

**误报/无需修复：**
- NDT-21 (ManageLayers.lsp): thaw-before-off 是正确行为（冻结图层需解冻后才能关闭）
- NDT-22 (SidewalkTrim.lsp): `entList` 已在局部变量列表中，nil初始值下 `cons` 正常

**仍需重设计的遗留：**
- TB-H12: `-PLOT` 语言依赖（需多语言版 AutoCAD 兼容方案）
- TB-H13: `entlast` 竞态（低频，需架构调整）
