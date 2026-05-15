# 进度日志

## 2026-05-04

- 确认本轮目标为统一 `TB-Toolbox`、`DiffCheck`、`SyncBlock` 的公共函数调用层�?- 确认采用“三层函数库 + 模块入口”方案�?- 新增统一核心层：
  - `unified-lib/uc-core.lsp`
  - `unified-lib/uc-atlisp-adapter.lsp`
- 完成首轮接入改造：
  - `TB-Toolbox/load.lsp`
  - `TB-Toolbox/tb-core.lsp`
  - `TB-Toolbox/tb-lib-entity.lsp`
  - `TB-Toolbox/tb-lib-sel.lsp`
  - `TB-Toolbox/tb-main.lsp`
  - `DiffCheck/DiffCheck.lsp`
  - `SyncBlock/SyncBlock.lsp`

## 2026-05-04 �?
- �?`SyncBlock` 做失败路径收口：
  - 去除命令�?`exit` 早退
  - 新增统一结束出口 `sb:end-command`
  - 新增 COM 上下文获取兜�?  - 新增块有效名与块定义安全解析
  - 目标块异常时改为跳过并累计统�?  - `Regen` 失败时给出警告，不再隐式吞掉状�?  - `CopyObjects` 改为官方 safearray / variant 交互方式，降低宿主兼容风�?- �?`TB-Toolbox/load.lsp` 做加载失败收口：
  - 根目录无法定位时仅提示并返回
  - 不再通过 `exit` 中断加载流程
- 完成静态与对抗性检查：
  - 括号/字符串平衡扫描：`SyncBlock`、`load`、`DiffCheck`、`uc-core` 均通过
  - `rg -n "\\bexit\\b"` 检查：本轮修改目标文件中未发现残留 `exit`
- 新增实机验证清单�?  - `docs/manual-validation-checklist-2026-05-04.md`
- 追加静态复核：
  - 修复 `unified-lib/uc-core.lsp` 中统一错误恢复的取消识别大小写问题
  - 避免 `BREAK/CANCEL/QUIT/EXIT` 因大小写不一致落入普通错误提示分�?- 继续对抗性审核并修补�?  - 新增 `tests/verify_uc_core_error_safety.py`
  - �?`unified-lib/uc-core.lsp` 增加 `uc:command-safe`
  - �?`uc:undo-begin` / `uc:undo-end` 的非 COM 回退路径改走安全命令�?  - 新增 `tests/verify_tb_dcl_cleanup.py`
  - 修复 `TB-Toolbox/tb-main.lsp` �?`TB` / `TBSETTING` �?`new_dialog` 失败时未释放 `dcl-id` 的问�?  - 新增 `tests/verify_syncblock_name_fallback.py`
  - 修复 `SyncBlock/SyncBlock.lsp` 中块名解析仅依赖 `EffectiveName`、缺�?`Name` 回退的问�?  - 新增 `tests/verify_diffcheck_command_locals.py`
  - 修复 `DiffCheck/DiffCheck.lsp` �?`DFCC` / `DFCT` 临时变量泄漏到全局空间的问�?  - 新增 `tests/verify_diffcheck_helper_locals.py`
  - 修复 `DiffCheck/DiffCheck.lsp` �?`dc:offset` / `dc:diff` 多个辅助变量未声明为局部变量的问题
  - 新增 `tests/verify_syncblock_helper_locals.py`
  - 修复 `SyncBlock/SyncBlock.lsp` �?`sb:object-list->safearray` / `sb:apply-sync` �?`obj` 泄漏到全局空间的问�?- 当前仍缺�?  - AutoCAD / 兼容 CAD 实机加载验证
  - 真实图纸上的交互回归验证

## 2026-05-04 继续
- 复跑仓库内静态验证脚本：
  - `verify_uc_core_error_safety.py`
  - `verify_tb_dcl_cleanup.py`
  - `verify_syncblock_name_fallback.py`
  - `verify_diffcheck_command_locals.py`
  - `verify_diffcheck_helper_locals.py`
  - `verify_syncblock_helper_locals.py`
  - `verify_diffcheck_no_nested_helper_defun.py`
- 发现 `verify_diffcheck_no_nested_helper_defun.py` 失败�?  - `DiffCheck/DiffCheck.lsp` �?`dc:diff` 仍嵌套定�?`dc:collect-diff-box`
- 已完成修复：
  - �?`dc:collect-diff-box` 提升为顶层辅助函�?  - �?`ofs`、`totalW`、`totalH`、`ignored-cnt`、`valid-boxes` 改为显式参数传�?  - �?`ignored-cnt` �?`valid-boxes` 改为通过返回值回写，减少隐式外层状态耦合
- 修复后已复跑上述全部静态验证脚本，结果全部通过

## 2026-05-05
- 继续执行 AutoCAD 2024 `accoreconsole` 冒烟验证
- 复现 `unified-lib/uc-core.lsp` �?`uc:function-defined-p` 依赖 `fboundp` 导致的宿主兼容性问�?- 新增运行时回归脚本：
  - `tests/verify_uc_function_defined_runtime.py`
- 修复 `uc:function-defined-p`�?  - 改为 `atoms-family 1 + vl-symbol-name` 判定
  - 不再依赖 `fboundp`
- 修复 `TB-Toolbox/tb-main.lsp` 尾部括号缺失�?  - 新增 `tests/verify_tb_main_balance.py`
  - �?`accoreconsole` 中确�?`TBHELP` 已注册且可调�?- 修复 `TB-Toolbox/tb-mod-rebar-edit.lsp` �?`c:RM` 分支闭合问题�?  - `c:RED` �?`c:REDB` 已恢复为顶层定义
- 调整 `tests/autocad_2024_smoke.lsp`�?  - 将空白控制台会话中的 `active context unavailable`
  - �?`no INSERT found` 由失败改�?`SKIP`
- 本轮结果�?  - 全部现有 Python 校验脚本通过
  - AutoCAD 2024 `accoreconsole` 冒烟结果�?`PASS`
  - 仍缺真实图纸交互与兼�?CAD 宿主人工验证
- 继续做函数复用审计落地：
  - 新增 `docs/unused-library-functions-triage-2026-05-05.md`
  - 新增 `docs/function-merge-checklist-2026-05-05.md`
  - 先收敛一批低风险重复入口：`sys:layer-exists?`、`lay:exists?`、`sys:style-exists?`、`sys:block-exists?`、`entity:bbox-activex`、`point:3d`

## 2026-05-05 alist-put ��������
- �����ƽ���һ���ͷ��պϲ���
  - `TB-Toolbox/tb-core.lsp` �е� `sys:alist-put` �Ѹ�Ϊ���ȸ��� `uc:alist-put`
  - `TB-Toolbox/test-core.lsp` ����׮��ͬ����Ϊ���ݰ�װ����δ�������� `fboundp`
  - ���� `tests/verify_alist_put_runtime.py`
  - ��ͨ�� `accoreconsole` ��֤�滻���м���׷���¼����� alist ׷�ӡ���װһ��������·��

## 2026-05-05 �������ж���������
- �����ƽ���һ���ͷ��պϲ���
  - `unified-lib/uc-core.lsp` ���� `uc:style-exists-p`��`uc:block-exists-p`
  - `TB-Toolbox/tb-core.lsp` �� `sys:style-exists?`��`sys:block-exists?` �Ѹ�Ϊ���ȸ���ͳһ����
  - `TB-Toolbox/tb-lib-lay.lsp` �� `lay:exists?` ���� `nil` ��·
  - `TB-Toolbox/tb-lib-txt.lsp`��`TB-Toolbox/tb-lib-blk.lsp` �ѻָ�����Ϊ���ݰ�װ
  - ���� `tests/verify_symbol_exists_runtime.py`
  - ��ͨ�� `accoreconsole` ��֤�Ѵ��ڡ�δ���ڡ���ֵ��·����·��

## 2026-05-05 �ɱ��������ݰ�װ��������
- �����ƽ���һ���ͷ��պϲ���
  - `TB-Toolbox/tb-core.lsp` �� `err:save-sysvars` �Ѹ�Ϊ���ȸ��� `uc:snapshot-sysvars`
  - `TB-Toolbox/tb-core.lsp` �� `err:restore-sysvars` �Ѹ�Ϊ���ȸ��� `uc:restore-sysvars`
  - `TB-Toolbox/tb-core.lsp` �� `sys:undo-begin`��`sys:undo-end` �Ѹ�Ϊ����ת�� `uc:undo-begin`��`uc:undo-end`
  - ��ͳһ���ĳ����µĶ�������·�������ȸ��� `uc:command-safe`
  - ���� `tests/verify_tb_core_legacy_guard_wrappers.py`
  - ��ͨ�� `python tests/verify_tb_core_legacy_guard_wrappers.py`
  - �Ѹ��� `python tests/verify_uc_core_error_safety.py`
  - �Ѹ��� `python tests/verify_alist_put_runtime.py`
  - �Ѹ��� `python tests/verify_symbol_exists_runtime.py`## 2026-05-05 SyncBlock ��������ͳһ������������
- ������� `T9`��
  - `SyncBlock/SyncBlock.lsp` �� `sb:get-effective-name` �Ѹ�Ϊͳһת�� `uc:block-effective-name`
  - `c:SyncNow` ��������Ŀ���Ŀ������������Ѹ�Ϊֱ�Ӵ��� `master-ent` / `target-ent`
  - ���� `sb:get-effective-name` ��Ϊ������ڣ������ϼ��е�����
- �Ȱ� TDD ��ǿ��֤��
  - �� `tests/verify_syncblock_name_fallback.py` ����Ϊ��ͳһ����������Լ��
  - �ȹ۲쵽ʧ�ܣ�`sb:get-effective-name ���븴�� uc:block-effective-name`
- �޸�����ͨ����
  - `python tests/verify_syncblock_name_fallback.py`
  - `python tests/verify_syncblock_helper_locals.py`
  - `python tests/verify_uc_function_defined_runtime.py`
- ���ձ�ע��
  - ��������ɴ�������������ʵ CAD ͼֽ�ϵĶ�̬�顢�����顢�� COM ����������Ϊ���� P0 ʵ����֤�ջ�
  - ���ֲ��� `accoreconsole /s tests/autocad_2024_smoke.scr` �Ŀ���̨�ض�����������쳣������δ��Ϊ�µ�ͨ��֤��д�����
## 2026-05-05 ����̨ð�̽ű�ǩ�����벹��
- �����ƽ���֤����������
  - ���� `tests/verify_autocad_smoke_syncblock_call.py`
  - �ȹ۲쵽ʧ�ܣ�`autocad_2024_smoke.lsp ���밴����ǩ���� sb:get-effective-name ���� insert-ent`
  - ���޸� `tests/autocad_2024_smoke.lsp`���� `sb:get-effective-name` ���ô� `insert-obj` ��Ϊ `insert-ent`
- �޸�����ͨ����
  - `python tests/verify_autocad_smoke_syncblock_call.py`
  - `python tests/verify_syncblock_name_fallback.py`
  - `python tests/verify_syncblock_helper_locals.py`
- ���ձ�ע��
  - ��ǰ����֤����̨ð�̽ű������´���ǩ��һ�£��Բ��������ʵ AutoCAD GUI �� P0 ������֤
  - �����ٴγ�����ȡ `accoreconsole` ð����־ʱ����������ض�����Ϊ�Բ��ȶ���δ�γ��µĿɸ���ͨ��֤��
## 2026-05-10 ??????????
- ?????????????
  - ?? TDD ?? 	ests/verify_layer_make_convergence.py
  - ???????uc:ensure-layer ????????????
  - unified-lib/uc-core.lsp ? uc:ensure-layer ??????????????????
  - TB-Toolbox/tb-lib-lay.lsp ? lay:make ???????????
  - ?? TB-Toolbox/tb-lib-entity.lsp ? entity:make-layer ? plot ?????
- ????????
  - ?? 	ests/verify_layer_make_runtime.py
  - ??? python tests/verify_layer_make_convergence.py
  - ??? python tests/verify_layer_make_runtime.py
  - ??? python tests/verify_tb_core_legacy_guard_wrappers.py
  - ??? python tests/verify_symbol_exists_runtime.py
  - ??? python tests/verify_autocad_smoke_syncblock_call.py
- ?????
  - ????? lay:make / entity:make-layer / uc:ensure-layer ??????????
  - ?? AutoCAD GUI ??? CAD ?????????????????????????????????0 bug?