# 低风险收敛项"未回归"证据链映射表（2026-05-05）

## 目的

为每一项已完成的收敛改动建立 `改动 → 测试 → 结论` 映射，
让后续审查不再需要重复追问"这项改动有没有测过"。

---

## 一、统一核心能力构建

| # | 改动 | 涉及文件 | 测试脚本 | 覆盖路径 | 结论 |
|---|------|---------|---------|---------|------|
| 1 | 新增 `uc:command-safe`（Undo 安全回退） | `uc-core.lsp` | `verify_uc_core_error_safety.py` | 非 COM + 异常恢复分支不再裸用 `command` | PASS |
| 2 | 新增 `uc:function-defined-p`（运行时函数检测） | `uc-core.lsp` | `verify_uc_function_defined_runtime.py` | `accoreconsole` 中可识别已加载函数、未定义函数、nil 输入 | PASS |
| 3 | 新增 `uc:snapshot-sysvars` / `uc:restore-sysvars` | `uc-core.lsp` | `verify_uc_core_error_safety.py` | 多变量快照 + 逐一恢复 + vl-catch-all-apply 守卫 | PASS |
| 4 | 新增 `uc:guard-begin` / `uc:guard-end` / `uc:guard-fail` | `uc-core.lsp` | `verify_uc_core_error_safety.py` | 正常结束、异常结束、*error* 重置、Undo 生命周期 | PASS |

---

## 二、存在性判断收敛

| # | 改动 | 涉及文件 | 测试脚本 | 覆盖路径 | 结论 |
|---|------|---------|---------|---------|------|
| 5 | `sys:layer-exists?` → `uc:layer-exists-p` | `tb-core.lsp` | `verify_symbol_exists_runtime.py` | 存在/不存在/nil 输入 | PASS |
| 6 | `lay:exists?` → `uc:layer-exists-p` | `tb-lib-lay.lsp` | `verify_symbol_exists_runtime.py` | 存在/不存在/nil 输入/COM 不可用 | PASS |
| 7 | `sys:style-exists?` → `txt:style-exists?` | `tb-core.lsp` | `verify_symbol_exists_runtime.py` | 存在/不存在/nil 输入 | PASS |
| 8 | `sys:block-exists?` → `blk:exists?` | `tb-core.lsp` | `verify_symbol_exists_runtime.py` | 存在/不存在/nil 输入 | PASS |

---

## 三、数据结构收敛

| # | 改动 | 涉及文件 | 测试脚本 | 覆盖路径 | 结论 |
|---|------|---------|---------|---------|------|
| 9 | `sys:alist-put` → `uc:alist-put` | `tb-core.lsp`, `test-core.lsp` | `verify_alist_put_runtime.py` | 新键追加、同名覆盖、nil 输入、空表、`accoreconsole` 运行时 | PASS |
| 10 | `entity:bbox-activex` → 安全包装 `uc:entity-bbox`，失败时回退 `entity:bbox-pure` | `tb-lib-entity.lsp` | `verify_bbox_activex_runtime.py` | 正常几何体、nil 输入、`uc:entity-bbox` 异常时纯几何回退、`accoreconsole` 运行时 | PASS |
| 11 | `point:3d` → 复用 `point:create` | `tb-lib-point.lsp` | （纯数据变换，无独立运行时脚本） | 三点坐标构造、z 默认值、二维点兼容 | 静态通过 |

---

## 四、旧保护链收敛

| # | 改动 | 涉及文件 | 测试脚本 | 覆盖路径 | 结论 |
|---|------|---------|---------|---------|------|
| 12 | 删除 `err:handler` / `err:save-sysvars` / `err:restore-sysvars` 遗留错误链 | `tb-core.lsp` | `verify_tb_core_legacy_guard_wrappers.py` | 三个旧函数已不存在，避免继续维护失效恢复链 | PASS |
| 13 | 保留 `sys:undo-begin` / `sys:undo-end` 为兼容包装 | `tb-core.lsp` | `verify_tb_core_legacy_guard_wrappers.py` | `uc:undo-begin` / `uc:undo-end` 仍为唯一核心入口 | PASS |
| 14 | `sys:undo-begin` → 优先转调 `uc:undo-begin` | `tb-core.lsp` | `verify_tb_core_legacy_guard_wrappers.py` | COM/非COM/统一核心三种降级 | PASS |
| 15 | `sys:undo-end` → 优先转调 `uc:undo-end` | `tb-core.lsp` | `verify_tb_core_legacy_guard_wrappers.py` | 同上 | PASS |

---

## 五、命令级变量泄漏收口

| # | 改动 | 涉及文件 | 测试脚本 | 覆盖路径 | 结论 |
|---|------|---------|---------|---------|------|
| 16 | `DFCC`/`DFCT` 临时变量 `ss`/`v` 声明为局部 | `DiffCheck.lsp` | `verify_diffcheck_command_locals.py` | 静态检查变量是否在 defun / 形参中声明 | PASS |
| 17 | `dc:offset`/`dc:diff` 辅助变量声明为局部 | `DiffCheck.lsp` | `verify_diffcheck_helper_locals.py` | `c/en/a/b/v` / `en/s/box` 局部声明检查 | PASS |
| 18 | `dc:collect-diff-box` 提升为顶层函数 | `DiffCheck.lsp` | `verify_diffcheck_no_nested_helper_defun.py` | 无嵌套 defun、`ofs`/`totalW`/`totalH` 改为显式入参 | PASS |
| 19 | `sb:object-list->safearray` 中 `obj` 声明为局部 | `SyncBlock.lsp` | `verify_syncblock_helper_locals.py` | `obj` 局部声明检查 | PASS |
| 20 | `sb:apply-sync` 中 `obj` 声明为局部 | `SyncBlock.lsp` | `verify_syncblock_helper_locals.py` | `obj` 局部声明检查 | PASS |

---

## 六、失败路径修复

| # | 改动 | 涉及文件 | 测试脚本 | 覆盖路径 | 结论 |
|---|------|---------|---------|---------|------|
| 21 | `TB`/`TBSETTING` DCL 初始化失败时补 `unload_dialog` | `tb-main.lsp` | `verify_tb_dcl_cleanup.py` | 正常成功、初始化失败分支、字符串中 DCL 代码不被误判 | PASS |
| 22 | `sb:get-effective-name` 增加 `vla-get-Name` 回退 | `SyncBlock.lsp` | `verify_syncblock_name_fallback.py` | EffectiveName 可用/不可用两种分支 | PASS |
| 23 | `uc:function-defined-p` 修复 accoreconsole 误判 | `uc-core.lsp` | `verify_uc_function_defined_runtime.py` | 已加载函数、未定义函数、nil 符号 | PASS |

---

## 七、结构性修复

| # | 改动 | 涉及文件 | 测试脚本 | 覆盖路径 | 结论 |
|---|------|---------|---------|---------|------|
| 24 | `tb-main.lsp` 尾部括号缺失 | `tb-main.lsp` | `verify_tb_main_balance.py` | 括号深度归零、无未闭合字符串、line comment 跳过 | PASS |
| 25 | `tb-mod-rebar-edit.lsp` `c:RM` 分支闭合 | `tb-mod-rebar-edit.lsp` | `verify_tb_rebar_edit_helper_defs.py` | 括号深度归零、字符串状态正确 | PASS |
| 26 | `tb-main.lsp` `defun` 不使用 `nil` 形参表 | `tb-main.lsp` | `verify_tb_main_defuns.py` | `tb:run-bound-command`/`c:TBHELP` 检查 | PASS |

---

## 八、覆盖汇总

| 分类 | 改动数 | 有测试 | 无测试 | 测试通过 |
|------|--------|--------|--------|---------|
| 统一核心能力构建 | 4 | 4 | 0 | 4 |
| 存在性判断收敛 | 4 | 4 | 0 | 4 |
| 数据结构收敛 | 3 | 2 | 1* | 2 |
| 旧保护链收敛 | 4 | 4 | 0 | 4 |
| 变量泄漏收口 | 5 | 5 | 0 | 5 |
| 失败路径修复 | 3 | 3 | 0 | 3 |
| 结构性修复 | 3 | 3 | 0 | 3 |
| **总计** | **26** | **25** | **1** | **25** |

\* `point:3d` 复用 `point:create` 为纯数据变换，不涉及宿主或图元，无需独立运行时脚本。

---

## 九、仍需运行时验证的项

以下改动已通过静态/accoreconsole 验证，但尚未在真实 CAD GUI 中测试：

| 改动 | 真实 GUI 风险 | 优先级 |
|------|-------------|--------|
| DCL 清理修复 | 对话框交互是否正确（焦点、z-order） | P0 |
| `uc:command-safe` | 命令回显、CMDECHO 交互 | P0 |
| `sb:get-effective-name` 回退 | 动态块/匿名块真实返回行为 | P0 |
| `uc:function-defined-p` | 加载顺序对函数可见性的影响 | P1 |

这四项已归入验证模板（`docs/unified-cancel-path-validation-template.md`）的对应命令验证项中。
