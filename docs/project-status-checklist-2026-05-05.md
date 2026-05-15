# 项目总状态清单（2026-05-05）

## 一、整体进度

```
基础设施      ████████████████████ 100%  核心库、工具库、统一函数库全部就绪
函数收敛      ████████████████████ 100%  26 项收敛改动已落地，现有 15 个 verification 脚本已全部通过
变量公害      ████████████████████ 100%  let/let* 、裸全局变量、嵌套 defun 全部收口
括号平衡      ████████████████████ 100%  31 个 .lsp 文件全部平衡
应用模块      ████████████████░░░░  90%  钢筋、中心线、批量打印等已实现，部分模块待补
实机验证      ███░░░░░░░░░░░░░░░░░  15%  accoreconsole 冒烟已通过，P0 GUI 任务 1-6 仍需真实 AutoCAD 宿主
```

**当前结论**：项目尚不能标记为“可交付”。现有脚本验证已恢复全绿，但真实 AutoCAD GUI 的任务 1-6 仍未完成。

### 2026-05-05 复核结论

- 已重新复跑现有 `verify_*.py` 脚本，结果为 `15 通过 / 0 失败`。
- `tests/verify_bbox_activex_runtime.py` 已修复并重新验证通过。
- 已重新执行 `tests/autocad_2024_smoke.scr`，AutoCAD 2024 `accoreconsole` 冒烟结果为 `PASS`，但这不能替代 GUI 交互验证。
- `T13` 已执行并完成验证；`T9` 已完成代码收敛并通过专项验证。
- `tests/autocad_2024_smoke.lsp` 已对齐 `sb:get-effective-name` 最新签名，避免控制台冒烟脚本继续调用旧接口。

---

## 二、已完成工作总表

### 2.1 基础设施（tb-core / unified-lib）

| # | 完成项 | 状态 | 证据 |
|---|--------|------|------|
| I1 | 参数体系三层分级（SYS/PRJ/TMP） | ✅ | `tb-core.lsp` |
| I2 | 错误处理机制（err:wrap / uc:guard-*） | ✅ | `tb-core.lsp`, `uc-core.lsp` |
| I3 | 平台检测（ZWCAD / GStarCAD / AutoCAD） | ✅ | `tb-core.lsp` sys:detect-platform |
| I4 | 安全输入验证（safe:get-real / safe:get-int / safe:get-dist） | ✅ | `tb-core.lsp` |
| I5 | 防死循环机制（safe:while） | ✅ | `tb-core.lsp` |
| I6 | Undo 管理（sys:undo-begin → uc:undo-begin） | ✅ | 已收敛，verification 通过 |
| I7 | 系统变量快照/恢复（uc:snapshot-sysvars / uc:restore-sysvars） | ✅ | `uc-core.lsp` |
| I8 | 非 COM Undo 安全回退（uc:command-safe） | ✅ | `uc-core.lsp` |
| I9 | 运行时函数检测（uc:function-defined-p） | ✅ | `uc-core.lsp` |
| I10 | 存在性判断（uc:layer-exists-p / uc:style-exists-p / uc:block-exists-p） | ✅ | `uc-core.lsp` |

### 2.2 元素操作库（lib-*）

| # | 完成项 | 函数数 | 状态 |
|---|--------|--------|------|
| L1 | `tb-lib-point.lsp`（点操作 13 个） | 13 | ✅ |
| L2 | `tb-lib-curve.lsp`（曲线操作 14 个） | 14 | ✅ |
| L3 | `tb-lib-sel.lsp`（选择集操作 6 个） | 6 | ✅ |
| L4 | `tb-lib-lay.lsp`（图层操作 11 个） | 11 | ✅ |
| L5 | `tb-lib-entity.lsp`（实体创建/查询 26 个） | 26 | ✅ |
| L6 | `tb-lib-txt.lsp`（文字操作） | ~10 | ✅ |
| L7 | `tb-lib-blk.lsp`（图块操作） | ~10 | ✅ |
| L8 | `tb-lib-dim.lsp`（标注操作） | ~10 | ✅ |
| L9 | `tb-lib-rebar.lsp`（钢筋几何库） | ~15 | ✅ |
| L10 | `tb-lib-rebar-edit.lsp`（钢筋标注库） | ~10 | ✅ |

### 2.3 应用命令模块

| # | 命令 | 模块 | 状态 |
|---|------|------|------|
| M1 | `c:RE` 钢筋智能编辑 | `tb-mod-rebar-edit.lsp` | ✅ |
| M2 | `c:RA` 实时配筋面积 | `tb-mod-rebar-edit.lsp` | ✅ |
| M3 | `c:RN` 钢筋编号管理 | `tb-mod-rebar-edit.lsp` | ✅ |
| M4 | `c:RM` 钢筋镜像 | `tb-mod-rebar-edit.lsp` | ✅ |
| M5 | `c:RED` / `c:REDB` 双击编辑 | `tb-mod-rebar-edit.lsp` | ✅ |
| M6 | `c:RB` 画任意钢筋 | `tb-mod-rebar.lsp` | ✅ |
| M7 | `c:RS` 画箍筋 | `tb-mod-rebar.lsp` | ✅ |
| M8 | `c:RH` / `c:RDH` 添加/删除弯钩 | `tb-mod-rebar.lsp` | ✅ |
| M9 | `c:RW` 改钢筋线宽 | `tb-mod-rebar.lsp` | ✅ |
| M10 | `c:RO` 偏移钢筋 | `tb-mod-rebar.lsp` | ✅ |
| M11 | `c:RL` 线变钢筋 | `tb-mod-rebar.lsp` | ✅ |
| M12 | `c:RD` 钢筋标注 | `tb-mod-rebar.lsp` | ✅ |
| M13 | `c:RCC` 钢筋编号 | `tb-mod-rebar.lsp` | ✅ |
| M14 | `c:RBR` 板底筋 | `tb-mod-rebar.lsp` | ✅ |
| M15 | `c:RBF` 板负筋 | `tb-mod-rebar.lsp` | ✅ |
| M16 | `c:ce` 智能中心线 | `tb-mod-centerline.lsp` | ✅ |
| M17 | 批量打印全套命令 | `tb-mod-batchprint.lsp` | ✅ |
| M18 | `c:TB` / `c:TBSETTING` / `c:TBHELP` 主界面 | `tb-main.lsp` | ✅ |

### 2.4 代码质量收口

| # | 完成项 | 涉及范围 | 状态 | 证据 |
|---|--------|---------|------|------|
| Q1 | `let`/`let*` → AutoLISP 兼容模式 | 全项目 31 文件 | ✅ | 前期会话完成 |
| Q2 | 括号平衡 | 全项目 31 文件 | ✅ | Perl 脚本批验证 |
| Q3 | tb-mod-batchprint.lsp 四项修复 | 1 文件 | ✅ | 本会话完成 |
| Q4 | 函数复用审计 | 421 个 defun 跨 4 项目 | ✅ | `function-reuse-audit-2026-05-05.md` |
| Q5 | 未用库函数分类 | 289 个可能未用函数 | ✅ | `unused-library-functions-triage-2026-05-05.md` |
| Q6 | 命令级变量泄漏收口 | DiffCheck 3 处 + SyncBlock 2 处 | ✅ | 6 个 verification 脚本 |
| Q7 | DCL 失败路径修复 | tb-main.lsp + DiffCheck + SyncBlock | ✅ | 3 个 verification 脚本 |
| Q8 | 旧错误恢复链审计 | tb-core.lsp 5 个函数 | ✅ | 本会话任务 7 |
| Q9 | 存在性判断 4 项收敛 | tb-core.lsp, tb-lib-lay.lsp | ✅ | `verify_symbol_exists_runtime.py` |
| Q10 | 数据结构 3 项收敛 | alist-put, bbox, point:3d | ✅ | `verify_alist_put_runtime.py`、`verify_bbox_activex_runtime.py` 通过 |
| Q11 | defun 形参表规范化 | tb-main.lsp, tb-mod-rebar-edit.lsp | ✅ | 2 个 verification 脚本 |

---

## 三、审计决策记录

### 决策 1：删除旧错误恢复链函数

**背景**（本会话任务 7）：

`tb-core.lsp` 中定义了以下旧保护链函数：

| 函数 | 行号 | 调用者数量 |
|------|------|-----------|
| `err:handler` | 187 | **0**（从未绑定到 `*error*`） |
| `err:save-sysvars` | 201 | **0** |
| `err:restore-sysvars` | 212 | **1**（仅 `err:handler` 内部，同样不会触发） |

**决策**：删除 `err:handler`、`err:save-sysvars`、`err:restore-sysvars` 三个遗留定义。

**保留**：`sys:undo-begin` / `sys:undo-end`（作为兼容包装，已转调 `uc:undo-begin` / `uc:undo-end`）。

**风险**：极低。三个函数无任何直接或间接调用者，删除不会影响任何命令路径。

### 决策 2：块名解析函数收敛

**背景**（本会话任务 9）：

| 维度 | `uc:block-effective-name` | `sb:get-effective-name` |
|------|--------------------------|------------------------|
| 入参 | `ename` | VLA 对象 |
| 无 COM 回退 | DXF 2 | 无（会崩溃） |
| 匿名块处理 | 有 | 无 |

**决策**：`sb:get-effective-name` 改为内部调用 `uc:block-effective-name`，上游改为传入 `ename`。

**收益**：获得 DXF 回退和无 COM 降级能力；SyncBlock 在 ZWCAD 中不会因 COM 不可用而崩溃。

### 决策 3：图层创建三入口不合并

**背景**（本会话任务 10）：

| 入口 | 职责 | 已存在时行为 |
|------|------|------------|
| `lay:make` | 图层域管理 | 更新颜色 |
| `entity:make-layer` | 实体域 + plot 标志 | 处理 plot |
| `uc:ensure-layer` | 统一核心纯创建 | 不更新 |

**决策**：保留三者，不合并。职责清晰、语义独立，强制合并会引入不必要的条件分支。

---

## 四、待完成任务

### P0 — 阻塞交付（需要真实 AutoCAD）

| # | 任务 | 涉及命令 | 验证模板 |
|---|------|---------|---------|
| T1 | TB-Toolbox 真实交互验证 | `TB`, `TBSETTING`, `TBHELP` | `unified-cancel-path-validation-template.md` §1 |
| T2 | DiffCheck 真实交互验证 | `DFC`, `DFCC`, `DFCT` | 同上 §2 |
| T3 | SyncBlock 真实交互验证 | `SyncNow` | 同上 §3 |
| T4 | 非标准路径加载测试 | 全部 | — |
| T5 | 跨平台验证（ZWCAD / GStarCAD） | 全部 | — |
| T6 | UNDO 行为验证 | 全部命令 | 同上 V1/V2 行 |

**请在验证模板中逐项填写结果。全部 PASS 后，本清单可标记为 `可交付`。**

### P1 — 建议性任务（不需要 CAD）

| # | 任务 | 状态 |
|---|------|------|
| T7 | 旧错误恢复链审计 | ✅ 已完成 |
| T8 | TB 切换到 uc:guard-* 决策 | ✅ 决策已出 |
| T9 | 块名解析收敛评估 | ✅ 已完成：`sb:get-effective-name` 已改为统一调用 `uc:block-effective-name` |
| T10 | 图层创建边界评估 | ✅ 结论已出 |
| T11 | 统一验证模板 | ✅ 已创建 |
| T12 | 收敛证据映射 | ✅ 已创建 |
| T13 | 删除 err:handler/err:save-sysvars/err:restore-sysvars | ✅ 已完成 |

**`T9` 与 `T13` 已完成并通过当前专项验证。** 当前 P1 项已全部闭环，剩余均为 P0 实机验证任务。

---

## 五、文件清单

### 源文件（31 个 .lsp）

```
TB-Toolbox/
  tb-core.lsp, tb-lib-point.lsp, tb-lib-curve.lsp, tb-lib-entity.lsp,
  tb-lib-sel.lsp, tb-lib-lay.lsp, tb-lib-txt.lsp, tb-lib-blk.lsp,
  tb-lib-dim.lsp, tb-lib-rebar.lsp, tb-lib-rebar-edit.lsp,
  tb-mod-edit.lsp, tb-mod-text.lsp, tb-mod-dim.lsp, tb-mod-layer.lsp,
  tb-mod-block.lsp, tb-mod-cloud.lsp, tb-mod-select.lsp,
  tb-mod-centerline.lsp, tb-mod-beam.lsp, tb-mod-column.lsp,
  tb-mod-bubble.lsp, tb-mod-misc.lsp, tb-mod-calc.lsp,
  tb-mod-batchprint.lsp, tb-mod-rebar.lsp, tb-mod-rebar-edit.lsp,
  tb-main.lsp, build.lsp, test-core.lsp, load.lsp

unified-lib/        → uc-core.lsp
DiffCheck/          → DiffCheck.lsp
SyncBlock/          → SyncBlock.lsp
```

### 文档（10 个）

| 文件 | 用途 |
|------|------|
| `project-status-checklist-2026-05-05.md` | 本清单 — 唯一总索引 |
| `task-resume-log.md` | 历史执行记录 |
| `adversarial-review-followup-checklist-2026-05-05.md` | 原始 13 任务定义 |
| `manual-validation-checklist-2026-05-04.md` | 手动验证初始清单 |
| `function-merge-checklist-2026-05-05.md` | 函数合并实施清单 |
| `convergence-evidence-mapping-2026-05-05.md` | 26 项收敛证据映射 |
| `code-audit-tasks-7-9-10-2026-05-05.md` | 任务 7/9/10 审计详情 |
| `unified-cancel-path-validation-template.md` | P0 实机验证模板 |
| `function-reuse-audit-2026-05-05.md` | 函数复用审计报告 |
| `unused-library-functions-triage-2026-05-05.md` | 未用函数分类 |

### 测试脚本（16 个）

```
tests/
  verify_uc_core_error_safety.py
  verify_tb_dcl_cleanup.py
  verify_syncblock_name_fallback.py
  verify_syncblock_helper_locals.py
  verify_diffcheck_command_locals.py
  verify_diffcheck_helper_locals.py
  verify_diffcheck_no_nested_helper_defun.py
  verify_tb_main_defuns.py
  verify_tb_rebar_edit_helper_defs.py
  verify_uc_function_defined_runtime.py
  verify_tb_main_balance.py
  verify_alist_put_runtime.py
  verify_symbol_exists_runtime.py
  verify_bbox_activex_runtime.py
  verify_autocad_smoke_syncblock_call.py
  verify_tb_core_legacy_guard_wrappers.py
```

### 最新复核证据

| 日期 | 验证 | 结果 | 备注 |
|------|------|------|------|
| 2026-05-05 | `py tests/verify_*.py` 全量复跑 | 15 PASS / 0 FAIL | 包含 `verify_bbox_activex_runtime.py` 修复后回归 |
| 2026-05-05 | `accoreconsole.exe /s tests/autocad_2024_smoke.scr` | PASS | 仅覆盖控制台宿主加载与基础命令冒烟 |
| 2026-05-05 | `python tests/verify_syncblock_name_fallback.py` | PASS | 已升级为“统一核心收敛”约束，覆盖 `sb:get-effective-name -> uc:block-effective-name` 与 `c:SyncNow` 上游传 `ename` |
| 2026-05-05 | `python tests/verify_autocad_smoke_syncblock_call.py` | PASS | 控制台冒烟脚本已对齐 `sb:get-effective-name` 最新 `ename` 入参签名 |

---

## 六、下一步行动

```
第一优先：获取真实 AutoCAD GUI 宿主 → 按验证模板执行任务 1-6
第二优先：跨平台验证（ZWCAD / GStarCAD）
第三优先：跨平台编译测试 → 生成 .vlx → 交付
```
