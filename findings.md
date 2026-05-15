# 统一函数库重构发现记�?
## 模块现状

### `TB-Toolbox`

- 已形成局部函数库，但历史加载路径�?DCL 资源定位方式较脆弱�?- 本轮已改为先加载统一核心，再加载工具箱模块�?- `load.lsp` 已去�?`exit` 式中断，根路径失败时只提示并返回�?
### `DiffCheck`

- 算法主体适合保留，通用保护逻辑应上收至统一核心�?- 本轮已接入统一 guard、图层准备和公共边界框能力�?- 静态检查未发现新增语法问题�?
### `SyncBlock`

- 原实现的高风险点集中在：
  - 依赖 COM 但无宿主能力判断
  - 命令内多�?`exit`
  - 目标块定义解析失败时可能直接中断
  - 复制失败、回填失败、刷新失败的提示不足
- 本轮已补齐上述失败路径的显式处理与统一退出�?
## 已处理风�?
1. `SyncBlock`：COM 不可用时现在会明确提示并安全返回�?2. `SyncBlock`：主块定义解析失败时现在会中止并恢复环境�?3. `SyncBlock`：目标块名称或定义解析失败时现在会跳过，并计�?`Skipped`�?4. `SyncBlock`：已移除本轮范围内命令级 `exit`，避免异常早退污染状态�?5. `TB-Toolbox/load.lsp`：根目录解析失败时不再强�?`exit`�?6. `SyncBlock`：`CopyObjects` 已改�?safearray 输入、variant 输出解包，贴�?Autodesk 官方示例�?7. `unified-lib/uc-core.lsp`：统一错误恢复现已按大写模式匹配取消类消息，避免大小写不一致导致取消路径误报为普通错误�?8. `unified-lib/uc-core.lsp`：已增加 `uc:command-safe`，Undo 的非 COM 回退路径不再直接裸用 `command`�?9. `TB-Toolbox/tb-main.lsp`：`TB` �?`TBSETTING` �?`new_dialog` 初始化失败时现已显式释放 `dcl-id`，降低重复失败后的资源泄漏风险�?10. `SyncBlock/SyncBlock.lsp`：块名解析现已在 `EffectiveName` 失败时回退�?`Name`，降低兼容宿主误判“无法解析块名”的概率�?11. `DiffCheck/DiffCheck.lsp`：`DFCC` �?`DFCT` 的临时变量现已局部化，降低长会话与重复执行时的全局状态污染风险�?12. `DiffCheck/DiffCheck.lsp`：`dc:offset` �?`dc:diff` 的多处辅助变量现已局部化，降低辅助函数执行后污染全局符号空间的风险�?13. `SyncBlock/SyncBlock.lsp`：`sb:object-list->safearray` �?`sb:apply-sync` �?`obj` 现已局部化，降低复制事务辅助函数污染全局符号空间的风险�?
## 仍需人工复核

1. AutoCAD / 兼容宿主是否都支持当�?`CopyObjects` 返回值遍历方式�?2. `DiffCheck` �?`REVCLOUD` 交互在不�?CAD 宿主中的 `CMDACTIVE` 行为是否一致�?3. `TB-Toolbox` �?DCL 资源查找在真实部署路径下是否完整可用�?
## 当前判断

- 代码层已完成首轮统一接入和静态风险收口�?- 实机验证步骤已整理为独立清单：`docs/manual-validation-checklist-2026-05-04.md`
- 由于缺少真实 CAD 宿主验证，当前不能宣称达到可提交�?`0 bug` 状态�?
## 2026-05-04 补充发现

14. `DiffCheck/DiffCheck.lsp`：`dc:diff` 内仍残留嵌套辅助函数 `dc:collect-diff-box`，会继续放大外层状态耦合与重复执行时的作用域风险�?15. 该问题已修复为顶层辅助函�?+ 显式参数传�?+ 返回值回写，相关静态回归脚本现已通过�?
## 2026-05-05 补充发现

16. `unified-lib/uc-core.lsp`：`uc:function-defined-p` 依赖 `fboundp`，�?`fboundp` �?AutoCAD 2024 `accoreconsole` 中会直接触发 `函数错误: FBOUNDP`，导致统一函数存在性判断失效�?17. `TB-Toolbox/tb-main.lsp`：文件整体括号数不平衡，导致 `tb-main.lsp` 在尾部加载失败，`TBHELP` 未被注册�?18. `TB-Toolbox/tb-mod-rebar-edit.lsp`：`c:RM` 缺少分支闭合，导�?`c:RED` �?`c:REDB` 被错误嵌套进前一层结构�?19. `tests/autocad_2024_smoke.lsp`：原先将空白控制台会话中的宿主前置条件不足误判为功能失败，放大了冒烟结果噪声�?
## 2026-05-05 处理结果

20. `uc:function-defined-p` 已改为基�?`atoms-family 1 + vl-symbol-name` 的兼容实现，`tests/verify_uc_function_defined_runtime.py` 通过�?21. `tb-main.lsp` 已补齐尾部括号，`tests/verify_tb_main_balance.py` 通过，`TBHELP` �?`accoreconsole` 中已恢复注册和调用�?22. `tb-mod-rebar-edit.lsp` 已修�?`c:RM` 结构闭合问题，`tests/verify_tb_rebar_edit_helper_defs.py` 通过�?23. `autocad_2024_smoke.lsp` 已将宿主前置条件不足改为 `SKIP`，当�?`accoreconsole` 冒烟结果�?`PASS`�?24. 未复用库函数已补充三类分诊，并形�?`docs/unused-library-functions-triage-2026-05-05.md`�?25. “已有等价实现，建议合并”已细化�?`docs/function-merge-checklist-2026-05-05.md`，便于按批次收敛�?26. 第一批低风险收敛已开始落地：旧存在性判断入口与旧包围盒入口已优先转调统一实现，`point:3d` 已改为复�?`point:create`�?
## 2026-05-05 alist-put ��������
27. `TB-Toolbox/tb-core.lsp` �� `sys:alist-put` �� `unified-lib/uc-core.lsp` �� `uc:alist-put` ���ظ�ʵ�֣���������Ϊ��ͳһ����ʵ�� + ���ݰ�װ����
28. ���� `tests/verify_alist_put_runtime.py`�������滻���м���׷���¼����� alist ׷�ӡ���װһ��������·��������ʱ���ͨ����

## 2026-05-05 �������ж���������
29. `uc-core` ������ `uc:style-exists-p` �� `uc:block-exists-p`���������жϿ�ʼ��ģ�黥��ص�����Ϊͳһ����ʵ�֡�
30. `sys:style-exists?`��`sys:block-exists?`��`lay:exists?` �Ѳ����ֵ��·������ `tblsearch/tblobjname` �� `nil` �����ϴ��� `stringp nil`��
31. `TB-Toolbox/tb-lib-txt.lsp` �� `TB-Toolbox/tb-lib-blk.lsp` �ڱ����޸�����������գ����Ѱ��ֿ�������ؽ���ͨ������ʱ��֤��
32. ���� `tests/verify_symbol_exists_runtime.py`������ͼ��/������ʽ/ͼ������������жϵ��Ѵ��ڡ�δ�������ֵ·�������ͨ����

## 2026-05-05 �ɱ�������������
33. `TB-Toolbox/tb-core.lsp` �� `err:save-sysvars`��`err:restore-sysvars` ��ǰ�Ը���ά��ϵͳ����������ָ��߼����Ѹ�Ϊ���ȸ��� `uc:snapshot-sysvars`��`uc:restore-sysvars`��
34. `TB-Toolbox/tb-core.lsp` �� `sys:undo-begin`��`sys:undo-end` ��ǰ�Ա������� Undo ��֧����������Ϊ����ת��ͳһ���� `uc:undo-begin`��`uc:undo-end`�����ڶ���·�������ȸ��� `uc:command-safe`��
35. ���� `tests/verify_tb_core_legacy_guard_wrappers.py`����̬Լ���ɱ������ӿڱ�����Ϊͳһ���ļ��ݰ�װ���ڣ���ǰ���ͨ����36. uc:ensure-layer?lay:make ? entity:make-layer ???????????????????lay:make ??????entity:make-layer -> uc:ensure-layer ??????????????????????????????
37. ???????uc:ensure-layer ?????????????????lay:make ?????????????entity:make-layer ?? plot ????
38. ?? 	ests/verify_layer_make_convergence.py ? 	ests/verify_layer_make_runtime.py?????? ccoreconsole ????????????