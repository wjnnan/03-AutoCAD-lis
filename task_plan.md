# 统一函数库重构任务看�?
## 目标

�?`atlisp-lib` 为系统函数库底座，完�?`TB-Toolbox`、`DiffCheck`、`SyncBlock` 的首轮统一函数库接入，减少重复实现，并补齐高风险失败路径的恢复链路�?
## 当前阶段

- [x] 设计方案确认
- [x] 首轮范围确认
- [x] 函数映射梳理
- [x] 项目级统一核心落地
- [x] `TB-Toolbox` 接入改�?- [x] `DiffCheck` 接入改�?- [x] `SyncBlock` 接入改�?- [x] 静态与对抗性复�?- [x] 统一错误恢复取消路径补修
- [x] 统一 Undo 回退安全层补�?- [x] TB 对话框失败分支资源释放补�?- [x] SyncBlock 块名解析回退补修
- [x] DiffCheck 命令局部变量污染补�?- [x] DiffCheck 辅助函数局部变量污染补�?- [x] SyncBlock 辅助函数局部变量污染补�?- [ ] AutoCAD / 兼容宿主实机验证

## 约束

1. 优先复用 `atlisp-lib`
2. 模块调用统一函数，不重复造基础轮子
3. 不做与本轮目标无关的大规模迁�?4. 必须覆盖异常路径、失败路径、恢复路径、重复操作等风险�?5. 在缺少实机验证前，不宣称达到可提交的 `0 bug` 状�?
## 当前结论

- 代码层面的统一接入已完成�?- 已补�?`SyncBlock` �?COM 不可用、块定义解析失败、目标块异常、回退出口等失败路径�?- 已移除本轮范围内新接入文件中�?`exit` 早退点，避免命令级污染环境�?- 仍缺�?AutoCAD / 兼容 CAD 实机加载与交互验证，因此暂不具备“可提交/可交付”结论�?## 2026-05-04 继续补充

- [x] 复跑现有 Python 静态验证脚�?- [x] 修复 `DiffCheck` �?`dc:diff` 嵌套定义 `dc:collect-diff-box` 的问�?- [x] 全量复跑现有静态验证脚本并确认通过
- [ ] AutoCAD / 兼容宿主实机验证

### 本次补充结论

- `DiffCheck` 已改为顶层辅助函�?+ 显式状态传递，减少外层作用域耦合�?- 当前仓库内现有静态验证脚本均已通过�?- 仍缺真实 CAD 宿主验证，因此依旧不能宣称“可提交”“可交付”或�? bug”�?
## 2026-05-05 继续补充

- [x] 复现 `accoreconsole` �?`uc:function-defined-p` 宿主兼容性问�?- [x] 新增 `verify_uc_function_defined_runtime.py`
- [x] 修复 `uc:function-defined-p`
- [x] 修复 `tb-main.lsp` 尾部括号缺失并恢�?`TBHELP`
- [x] 修复 `tb-mod-rebar-edit.lsp` 结构闭合问题
- [x] 调整 `autocad_2024_smoke.lsp`，将宿主前置条件不足改为 `SKIP`
- [x] 全量复跑现有 Python 校验脚本
- [x] 通过 AutoCAD 2024 `accoreconsole` 冒烟
- [x] 完成函数名盘点与复用率统�?- [x] 完成未复用库函数三类分诊
- [~] 按“建议合并”清单执行第一批低风险收敛
- [ ] AutoCAD / 兼容 CAD 真实图纸交互验证

### 本次补充结论

- 代码层新增暴露出�?`accoreconsole` 兼容性缺陷与 TB 结构性缺陷已修复
- 当前仓库内现�?Python 校验脚本�?AutoCAD 2024 控制台冒烟均已通过
- 但真实图纸上的人工交互验证仍未完成，因此依旧不能宣称“可提交”“可交付”或�? bug�?- 函数复用审计已经从统计阶段推进到收敛阶段，但命令层错误恢复链与真实图纸行为尚未完成闭�?
## 2026-05-05 alist-put ��������
- [x] `uc:alist-put` / `sys:alist-put` ��ͳһΪ������ʵ�� + ���ݰ�װ��
- ��ǰ�Բ������ơ����ύ�����ɽ�������0 bug������Ϊ��ʵ CAD �˹�������֤δ���

## 2026-05-05 �������ж���������
- [x] `sys:style-exists?` / `sys:block-exists?` ��ͳһת������ʵ��
- [x] `lay:exists?` �Ѳ����ֵ��·
- [x] `tb-lib-txt.lsp` / `tb-lib-blk.lsp` �ѻָ���ͨ����ǰ����ʱ��֤
- ��ǰ�Բ������ơ����ύ�����ɽ�������0 bug������Ϊ��ʵ CAD �˹�������֤δ���

## 2026-05-05 �ɱ��������ݰ�װ��������
- [x] `err:save-sysvars` / `err:restore-sysvars` ������Ϊͳһ���ļ��ݰ�װ
- [x] `sys:undo-begin` / `sys:undo-end` ������Ϊͳһ���ļ��ݰ�װ
- [x] ������ͨ�� `tests/verify_tb_core_legacy_guard_wrappers.py`
- ��ǰ�Բ������ơ����ύ�����ɽ�������0 bug������Ϊ��ʵ CAD �˹�������֤δ���## 2026-05-10 ??????????
- [x] uc:ensure-layer ????????????????
- [x] lay:make ????????????
- [x] entity:make-layer ??? plot ????????????
- [x] ????? 	ests/verify_layer_make_convergence.py
- [x] ????? 	ests/verify_layer_make_runtime.py
- [ ] AutoCAD / ?? CAD ??????????
- ???????????????????0 bug?????? CAD ?????????