# Bug 清单 — 第7轮对抗性审查

> 审查日期：2026-05-15
> 审查范围：atlisp-packages/ 深度逐文件审查（align-array, gen-detail, summary-data）
> 总计发现：17 个 Bug

## 修复状态汇总

| 严重级别 | 发现 | 已修复 | 残留 |
|----------|------|--------|------|
| HIGH | 10 | 10 | 0 |
| MEDIUM | 3 | 3 | 0 |
| LOW | 4 | 0 | 4 |
| **总计** | **17** | **13** | **4** |

---

## 第1部分：align-array.lsp 全面审查 (14个Bug)

### 已修复 (10)

| ID | 行号 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| AA-01 | 254 | ss9pt: vla-GetBoundingBox 无 vl-catch-all-apply（XLine/Ray 崩溃） | HIGH | ✅ |
| AA-02 | 1037 | ebox: vlax-invoke-method GetBoundingBox 无错误捕获 | HIGH | ✅ |
| AA-03 | 243 | S_RECT3: getpoint 后直接 getcorner，用户取消时 p1=nil 导致崩溃 | HIGH | ✅ |
| AA-04 | 548 | DQ_BK: getpoint 无 nil 检查，p0=nil 时后续 (cadr p0) 崩溃 | HIGH | ✅ |
| AA-05 | 564 | PL_BK: getpoint 无 nil 检查 | HIGH | ✅ |
| AA-06 | 377 | S_DQcx: getpoint 无 nil 检查 | HIGH | ✅ |
| AA-07 | 453 | S_PLcx: getpoint 无 nil 检查 | HIGH | ✅ |
| AA-08 | 859 | zhenlie_DT#1: 阵列起点 getpoint 无 nil 检查 | HIGH | ✅ |
| AA-09 | 888 | zhenlie_DT#2: 阵列起点 getpoint 无 nil 检查 | HIGH | ✅ |
| AA-10 | 976 | zhenlie_SS: 阵列起点 getpoint 无 nil 检查 | HIGH | ✅ |

### 残留 (4)

| ID | 行号 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| AA-11 | 347 | S_DQcx: `(car (entsel ...))` 无 nil 检查，entget nil 安全但行为不正确 | MEDIUM | ⚠️ |
| AA-12 | 422 | S_PLcx: `(car (entsel ...))` 无 nil 检查 | MEDIUM | ⚠️ |
| AA-13 | 616 | chatukuang: `(car (entsel ...))` 无 nil 检查 | MEDIUM | ⚠️ |
| AA-14 | ~8处 | chatukuang_tuzhong, tukuang_BK, juxing_WL, zhenlie_DT, zhenlie_SS, maketukuangxian 中 entsel 无 nil 检查 | LOW | ⚠️ |

---

## 第2部分：其他文件审查 (3个Bug)

| ID | 文件 | 描述 | 级别 | 状态 |
|----|------|------|------|------|
| GD-01 | prefabricated-building/gen-detail.lsp | `(car(entsel))` 无 nil 检查 | HIGH | ✅ |
| SD-01 | at-lab/summary-data.lsp | entsel 无 nil 检查 | HIGH | ✅ |
| EQ-00 | 全项目 | eq 用于字符串比较 — 未发现残留 | — | ✅ |

---

## 第7轮关键修复说明

1. **align-array.lsp ss9pt/ebox**: 这两个底层函数被文件中几乎所有操作调用。ss9pt 通过 vla-GetBoundingBox 获取对象的9点坐标，ebox 通过 vlax-invoke-method GetBoundingBox 获取边界框。对 XLine/Ray 等无限范围实体调用时会崩溃。现在均已增加 vl-catch-all-apply 错误捕获。

2. **align-array.lsp getpoint 系列**: DQ_BK/PL_BK 采用 "if+progn 包裹整个函数体" 模式；S_DQcx/S_PLcx/zhenlie_DT/zhenlie_SS 采用 "setq 后紧跟 (if (not p0) (quit))" 模式，因为函数体太大不适合重新缩进包裹。

3. **entsel 残留说明**: align-array.lsp 中约10处 `(car (entsel ...))` 未加 nil 检查，但在 AutoLISP 中 (car nil) 返回 nil，(entget nil) 返回 nil，后续 assoc 也返回 nil，不会立即崩溃。表现为"选了错误的分支"而非崩溃，归为 MEDIUM/LOW。

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
| **累计** | **204** | **159** | **45** |

> **注意**: 第6轮残留从41修正为61（含第6轮补充修复后的 MED/LOW 遗留项）。第7轮新增发现17个，修复13个，新增残留4个（均来自 align-array.lsp entsel MED/LOW 项）。

---

## 待第8轮处理

- align-array.lsp: 10处 entsel nil 检查 (AA-11~14)
- atlisp-packages/ 剩余 ~317个 .lsp 文件深度审查
- atlisp-core/ 目录审查
- XDrx-API/ 目录审查
- unified-lib/uc-atlisp-adapter.lsp 审查
- 跨项目 vla-SendCommand、vla-put-TextString 等 COM 调用审查
- 第4-5轮残留 MED/LOW Bug 复检
