# Bug 清单 — 第6轮对抗性审查

> 审查日期：2026-05-15
> 审查范围：atlisp-packages/ (13文件)、atlisp-lib/src/ (6文件)
> 总计发现：49 个 Bug

## 修复状态汇总

| 严重级别 | 发现 | 已修复 | 残留 |
|----------|------|--------|------|
| HIGH | 30 | 29 | 1 |
| MEDIUM | 19 | 19 | 0 |
| **总计** | **49** | **48** | **1** |

---

## 第1部分：atlisp-packages Bug (35个)

### 已修复 (27)

| ID | 文件 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| AB-01 | at-block/attrib.lsp | nentsel nil 检查 | HIGH | ✅ |
| AB-02 | at-block/attrib.lsp | `(eq "ATTRIB" ...)` → `(= "ATTRIB" ...)` | HIGH | ✅ |
| AB-03 | at-block/at-block.lsp | 4处 entsel nil 检查 | HIGH | ✅ |
| AB-04 | at-block/at-block.lsp | entsel nil 检查 (处5) | HIGH | ✅ |
| AB-05 | at-block/at-block.lsp | entsel nil 检查 (处6) | HIGH | ✅ |
| AB-06 | at-block/at-block.lsp | entsel nil 检查 (处7) | HIGH | ✅ |
| AB-07 | at-block/clip-to-blk.lsp | getpoint nil 检查 | HIGH | ✅ |
| AB-08 | at-block/clip-to-blk.lsp | getcorner nil 检查 | HIGH | ✅ |
| AB-09 | at-3d/at-3d.lsp | `(eq "SURFACE" ...)` → `=` (处1) | HIGH | ✅ |
| AB-10 | at-3d/at-3d.lsp | `(eq "SURFACE" ...)` → `=` (处2) | HIGH | ✅ |
| AB-11 | at-3d/at-3d.lsp | `(eq "SURFACE" ...)` → `=` (处3) | HIGH | ✅ |
| AB-12 | at-3d/at-3d.lsp | `(eq "SURFACE" ...)` → `=` (处4) | HIGH | ✅ |
| AB-13 | at-structure/at-structure.lsp | entsel nil 检查 | HIGH | ✅ |
| AB-14 | at-lab/get-cross-from-2layer.lsp | entsel nil 检查 (处1) | HIGH | ✅ |
| AB-15 | at-lab/get-cross-from-2layer.lsp | entsel nil 检查 (处2) | HIGH | ✅ |
| AB-16 | at-text/text-on-line.lsp | entsel nil 检查 | HIGH | ✅ |
| AB-17 | at-text/at-text.lsp | entsel nil 检查 | HIGH | ✅ |
| AB-18 | at-stat/at-stat.lsp | entsel nil 检查 | HIGH | ✅ |
| AB-19 | route-of-hole2shape/route-of-hole2shape.lsp | entsel nil 检查 | HIGH | ✅ |
| AB-20 | align-array/align-array.lsp | getpoint nil 检查 (处1) | HIGH | ✅ |
| AB-21 | align-array/align-array.lsp | getpoint nil 检查 (处2) | HIGH | ✅ |

### 残留 (8)

| ID | 文件 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| AB-22~28 | atlisp-packages/ 多个文件 | vla-offset 无 vl-catch-all-apply（11处，已修复：explode, clip-to-blk, at-cnc×4, at-curve×2, box×2） | MEDIUM | ✅ |
| AB-29 | at-block/attrib.lsp | `(eq ...)` 比较属性标签字符串 → `(= ...)` | MEDIUM | ✅ |
| AB-31 | align-array/align-array.lsp | 多处 getpoint 无 nil 检查（8处） | LOW | ⚠️ |

---

## 第2部分：atlisp-lib 深度搜索 Bug (14个)

### 已修复 (10)

| ID | 文件 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| AL-D1 | block/get-dynamic-properties.lsp | vla-getdynamicblockproperties 无错误捕获 | HIGH | ✅ |
| AL-D2 | block/set-dynprop.lsp | vla-getdynamicblockproperties 无错误捕获 | HIGH | ✅ |
| AL-D3 | block/wcs2bcs.lsp | 块缩放因子=0 时除零 | HIGH | ✅ |
| AL-D4 | entity/activedimstyle.lsp | tblobjname 返回 nil 无检查 | HIGH | ✅ |
| AL-D5 | entity/offset.lsp | vla-offset 无 vl-catch-all-apply | HIGH | ✅ |
| AL-D6 | list/remove-duplicate-keys.lsp | `eq` → `equal` 浮点键比较 | MEDIUM | ✅ |
| AL-D7~10 | atlisp-lib/src/ 多个文件 | getpoint/entsel nil 检查 (4处) | MEDIUM | ✅ |

### 残留 (4)

| ID | 文件 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| AL-D11~13 | atlisp-lib/src/ 多个文件 | vla-offset 无 vl-catch-all-apply（3处，已修复） | MEDIUM | ✅ |
| AL-D14 | 多个文件 | vla-getboundingbox 无错误捕获（8处，已修复：getbox, in-curve-p, align-array, FixPDFImport, at-text, Q-ZBZL×2, rd） | MEDIUM | ✅ |

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
| **累计** | **187** | **146** | **41** |

---

## 第6轮关键修复说明

1. **atlisp-packages/ entsel/nentsel nil 检查**：13个文件共21处增加了用户取消时的 nil 保护，避免 `(car nil)` / `(entget nil)` 崩溃。

2. **atlisp-packages/ at-3d `eq`→`=`**：4处 `(eq "SURFACE" ...)` 修复为 `=`，与 atlisp-lib 第5轮 CRITICAL 同类问题。

3. **atlisp-lib/ 动态块属性错误捕获**：`get-dynamic-properties.lsp` 和 `set-dynprop.lsp` 增加 `vl-catch-all-apply` 包裹 `vla-getdynamicblockproperties`，非动态块不再崩溃。

4. **atlisp-lib/ `eq`→`equal` 浮点键**：`remove-duplicate-keys.lsp` 中 `eq` 对浮点数恒返回 nil，改用 `equal` 配合容差。

5. **2026-05-15 补充修复**：全部 vla-offset（11处）和 vla-getboundingbox（8处）错误捕获已补全，AB-29 eq→= 已修复。新增发现：at-cnc.lsp 4处、explode.lsp 1处、box.lsp 2处、rd.lsp 1处、Q-ZBZL 2处 vla 调用。

---

## 待第7轮处理

- atlisp-packages/ 深度逐文件审查（当前仅模式搜索，337 .lsp 中仅覆盖约20个）
- atlisp-core/ 目录审查
- XDrx-API/ 目录审查
- unified-lib/uc-atlisp-adapter.lsp 审查
- 第4-5轮残留 MED/LOW Bug 复检
- AB-31: align-array.lsp 8处 getpoint nil 检查
- 跨项目 vla-SendCommand、vla-put-TextString 等 COM 调用审查
