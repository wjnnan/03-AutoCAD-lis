# 函数合并实施清单（2026-05-05）

## 目标

基于 `docs/unused-library-functions-triage-2026-05-05.md`，把“已有等价实现，建议合并”的函数进一步拆成可执行批次，优先做低风险收敛，再处理会触及命令层的接入调整。

## 本轮已落地

1. `sys:layer-exists?` 优先转调 `uc:layer-exists-p`
2. `lay:exists?` 优先转调 `uc:layer-exists-p`
3. `sys:style-exists?` 优先转调 `txt:style-exists?`
4. `sys:block-exists?` 优先转调 `blk:exists?`
5. `entity:bbox-activex` 优先转调 `uc:entity-bbox`
6. `point:3d` 改为复用 `point:create`

这批改动都属于“保留旧入口、内部收敛到统一实现”，不会直接改变外部调用方式。

## 第一批：继续适合立即收敛

1. `uc:alist-put` 与 `sys:alist-put`
   - 建议：选一处作为唯一实现，另一处改为兼容包装。
   - 风险：低。
   - 原因：逻辑完全一致，且不依赖宿主状态。

2. `txt:get-current-style`
   - 建议：暂不强推复用，只保留为薄包装，等文字模块统一入口时再决定去留。
   - 风险：低。
   - 原因：功能太薄，直接删除收益不大。

3. `point:create` / `point:2d` / `point:3d`
   - 建议：把三者定位成“点构造与转换小接口”，统一由其他点函数内部复用；若长期仍无调用，再转删除候选。
   - 风险：低。
   - 原因：纯数据变换，不涉及图元或命令。

## 第二批：需要确认调用策略后再动

1. `err:handler` / `err:save-sysvars`
   - 建议：先盘点 TB 命令层还有多少地方使用旧错误恢复链，再决定是整体切到 `uc:guard-*`，还是仅保留兼容入口。
   - 风险：中。
   - 关注点：取消路径、重复执行、Undo 结束时机、系统变量恢复。

2. `sys:undo-begin`
   - 建议：如果后续命令层继续向统一保护区迁移，可让旧入口只做 `uc:undo-begin` 包装。
   - 风险：中。
   - 关注点：非 COM 宿主、命令中断、嵌套 Undo。

3. `entity:make-layer`
   - 建议：明确以后是“图层域接口优先”还是“实体域也允许建图层”；未统一之前先保留。
   - 风险：中。
   - 关注点：`plot` 标记位 290 的处理是否要归入 `uc:ensure-layer`。

4. `uc:block-effective-name`
   - 建议：先比对 `sb:get-effective-name` 的回退行为，确认能否抽回统一层。
   - 风险：中。
   - 关注点：动态块、匿名块、无 COM 场景。

## 第三批：更像架构取舍，不急着改

1. `uc:midpoint` vs `point:mid`
   - 这是“统一层门面”与“TB 直接用点库”之间的边界问题，不是单纯重复代码。

2. `uc:core-file`
   - 只有在统一层资源定位开始被上层真实消费后，才有保留价值。

3. `rebar:code-to-grade`
   - 先确认钢筋解析流程是否准备收敛到解析主入口，再决定合并还是删除。

## 我建议的推进顺序

1. 完成 `uc:alist-put` / `sys:alist-put` 收敛
2. 盘点 TB 命令层的旧错误恢复链使用点
3. 再决定是否整体切换到 `uc:guard-*`

## 当前仍未闭环的风险

1. 真实图纸下 `TB` / `TBSETTING` / `DFC` / `SyncNow` 还没做人机交互验证
2. 取消路径、重复执行、Undo 恢复、兼容 CAD 宿主差异仍需人工复核
3. 因为上述验证未完成，当前不能宣称“可提交”或“0 bug”
