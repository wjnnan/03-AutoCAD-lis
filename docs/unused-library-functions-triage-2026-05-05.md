# 未复用库函数分诊（2026-05-05）

## 结论口径

- 本清单只针对“未复用的库函数”，不包含 `c:*` 命令入口。
- 判断依据主要来自静态代码结构、现有调用关系、同类函数重叠情况。
- 这不是最终删改指令，而是“下一步收敛路线图”。

三类定义：

1. `建议接入复用`
   - 函数边界清楚、功能有效，但调用方还没统一接入。
2. `已有等价实现，建议合并`
   - 功能已被别的函数、统一层或内置直接写法覆盖。
3. `暂保留，列为删除候选`
   - 当前无调用，且短期内看不到明确接入点；先保留记录，后续再决定是否删除。

---

## 一、建议接入复用

这类函数不是“没用”，而是“还没接上”。

| 函数 | 文件 | 判断理由 |
|---|---|---|
| `blk:list` | `TB-Toolbox/tb-lib-blk.lsp` | 是完整的块清单接口，后续块管理/批量操作界面可直接复用。 |
| `blk:get-attribs` | `TB-Toolbox/tb-lib-blk.lsp` | 已有 `entity:get-attribs` 能力，但以 `blk:*` 语义暴露更适合块模块接入。 |
| `blk:set-attrib` | `TB-Toolbox/tb-lib-blk.lsp` | 同上，块属性修改应优先通过块域接口调用。 |
| `blk:make` | `TB-Toolbox/tb-lib-blk.lsp` | 已完成对 `entity:make-block` 的封装，块创建命令层后续应统一走这里。 |
| `blk:insert` | `TB-Toolbox/tb-lib-blk.lsp` | 已完成对 `entity:make-insert` 的封装，插块命令可优先走这里。 |
| `curve:param-at-pt` | `TB-Toolbox/tb-lib-curve.lsp` | 是曲线定位能力，不是一次性逻辑，后续几何编辑命令值得接入。 |
| `curve:pt-at-param` | `TB-Toolbox/tb-lib-curve.lsp` | 与曲线参数系接口成组出现，适合进入统一曲线工作流。 |
| `curve:pt-at-dist` | `TB-Toolbox/tb-lib-curve.lsp` | 按距离取点在构件布置、标注辅助中很常见，值得优先复用。 |
| `curve:tangent` | `TB-Toolbox/tb-lib-curve.lsp` | 曲线切线是典型可复用几何能力，当前只是还没被上层命令吃到。 |
| `curve:inters-lines` | `TB-Toolbox/tb-lib-curve.lsp` | 纯几何交点工具，适合代替命令层零散交点计算。 |
| `dim:get-text` | `TB-Toolbox/tb-lib-dim.lsp` | 标注文字读取入口完整，后续标注类命令应统一通过它拿值。 |
| `dim:get-height` | `TB-Toolbox/tb-lib-dim.lsp` | 标注高度读取是标准接口，当前未接入不代表无价值。 |
| `dim:get-style` | `TB-Toolbox/tb-lib-dim.lsp` | 标注样式读取与设置应成对保留，并优先给标注命令复用。 |
| `dim:set-style` | `TB-Toolbox/tb-lib-dim.lsp` | 同上，属于明确的底层 API。 |
| `dim:is-overridden?` | `TB-Toolbox/tb-lib-dim.lsp` | 假注/覆写检测是很实用的质量检查点，适合后续审图命令接入。 |
| `dim:make-rotated` | `TB-Toolbox/tb-lib-dim.lsp` | 具备明确创建能力，适合后续自动标注命令复用。 |
| `entity:get-color` | `TB-Toolbox/tb-lib-entity.lsp` | 是标准实体属性接口，读取颜色时不应再直接散写 DXF 62。 |
| `entity:make-point` | `TB-Toolbox/tb-lib-entity.lsp` | 实体创建接口成组存在，点实体创建也应保留统一入口。 |
| `entity:make-mtext` | `TB-Toolbox/tb-lib-entity.lsp` | 多行文字创建是明确能力，后续文字命令可接入。 |
| `lay:get-current` | `TB-Toolbox/tb-lib-lay.lsp` | 当前图层读取是标准图层 API，后续不应再散写 `getvar "CLAYER"`。 |
| `lay:get-from-entity` | `TB-Toolbox/tb-lib-lay.lsp` | 与 `lay:set-to-entity` 成对，适合作为图层迁移命令入口。 |
| `point:between?` | `TB-Toolbox/tb-lib-point.lsp` | 线段包含判断是基础几何能力，后续几何编辑可直接复用。 |
| `point:in-polygon?` | `TB-Toolbox/tb-lib-point.lsp` | 点在多边形内判断是常见工具，值得保留并寻找调用点。 |
| `point:nearest` | `TB-Toolbox/tb-lib-point.lsp` | 最近点查询有稳定语义，后续排序/布置命令可复用。 |
| `rebar:find-min-diameter` | `TB-Toolbox/tb-lib-rebar-edit.lsp` | 钢筋面积反推直径很像“已实现但未接上线”的业务能力。 |
| `sel:by-layer` | `TB-Toolbox/tb-lib-sel.lsp` | 直接封装了图层选择，应替代命令层零散 `ssget "X"` 写法。 |
| `sel:by-type` | `TB-Toolbox/tb-lib-sel.lsp` | 同上，类型选择应统一入口。 |
| `sel:filter` | `TB-Toolbox/tb-lib-sel.lsp` | 通用 DXF 过滤入口很适合替代散落的 `ssget "X" alist`。 |
| `sel:pick` | `TB-Toolbox/tb-lib-sel.lsp` | 交互选择统一入口，目前命令层大多还直接写 `ssget`。 |
| `sel:add` | `TB-Toolbox/tb-lib-sel.lsp` | 选择集增量维护接口成组完整，后续复杂选择工作流可接入。 |
| `sel:delete` | `TB-Toolbox/tb-lib-sel.lsp` | 同上。 |
| `txt:get-height` | `TB-Toolbox/tb-lib-txt.lsp` | 文字尺寸读取应该统一，不必在命令层直接读 DXF 40。 |
| `txt:get-width` | `TB-Toolbox/tb-lib-txt.lsp` | 与 `txt:set-width` 成组，建议文字命令逐步接入。 |
| `txt:get-style` | `TB-Toolbox/tb-lib-txt.lsp` | 与 `txt:set-style` 成组，具备清晰复用价值。 |
| `txt:set-center-align` | `TB-Toolbox/tb-lib-txt.lsp` | 对齐设置有明确语义，适合对齐类命令直接复用。 |
| `txt:set-middle-align` | `TB-Toolbox/tb-lib-txt.lsp` | 同上。 |

---

## 二、已有等价实现，建议合并

这类函数不是“不能用”，而是“仓库里已经有别的入口在做几乎同一件事”。

| 函数 | 文件 | 等价实现 / 覆盖实现 | 判断理由 |
|---|---|---|---|
| `err:handler` | `TB-Toolbox/tb-core.lsp` | `uc:guard-begin / uc:guard-end / uc:guard-fail` | 统一错误恢复已沉到 `unified-lib`，TB 自己这一套正在失去主通道地位。 |
| `err:save-sysvars` | `TB-Toolbox/tb-core.lsp` | `uc:snapshot-sysvars` | 系统变量快照能力已被统一核心覆盖。 |
| `sys:undo-begin` | `TB-Toolbox/tb-core.lsp` | `uc:undo-begin` | Undo 生命周期已经在统一核心实现。 |
| `sys:layer-exists?` | `TB-Toolbox/tb-core.lsp` | `lay:exists?` / `uc:layer-exists-p` | 同类接口重复。 |
| `sys:style-exists?` | `TB-Toolbox/tb-core.lsp` | `txt:style-exists?` | 同类接口重复。 |
| `sys:block-exists?` | `TB-Toolbox/tb-core.lsp` | `blk:exists?` | 同类接口重复。 |
| `entity:make-layer` | `TB-Toolbox/tb-lib-entity.lsp` | `lay:make` / `uc:ensure-layer` | 图层创建已在图层域和统一核心都有更合适入口。 |
| `entity:bbox-activex` | `TB-Toolbox/tb-lib-entity.lsp` | `entity:get-bbox` / `uc:entity-bbox` | 已被更高层包围盒入口覆盖。 |
| `lay:exists?` | `TB-Toolbox/tb-lib-lay.lsp` | `sys:layer-exists?` / `uc:layer-exists-p` | 存在性检测接口重叠。 |
| `point:create` | `TB-Toolbox/tb-lib-point.lsp` | 直接 `list` / `point:3d` | 薄封装，且当前没有形成统一使用习惯。 |
| `point:2d` | `TB-Toolbox/tb-lib-point.lsp` | 直接 `(list (car pt) (cadr pt))` | 极薄封装，常被调用方直接展开。 |
| `point:3d` | `TB-Toolbox/tb-lib-point.lsp` | 直接 `(list (car pt) (cadr pt) z)` / `point:create` | 极薄封装，价值与 `point:create` 重叠。 |
| `rebar:code-to-grade` | `TB-Toolbox/tb-lib-rebar-edit.lsp` | `rebar:parse-annotation` 内部映射逻辑 | 现在真正使用的是解析总入口，这个单函数没有被主流程吃到。 |
| `txt:style-exists?` | `TB-Toolbox/tb-lib-txt.lsp` | `sys:style-exists?` | 存在性检测接口重复。 |
| `txt:get-current-style` | `TB-Toolbox/tb-lib-txt.lsp` | 直接 `(getvar "TEXTSTYLE")` | 薄封装，且当前没有形成统一接入。 |
| `uc:midpoint` | `unified-lib/uc-atlisp-adapter.lsp` | `point:mid` | 当前 TB 已大量直接使用 `point:mid`，统一层这一版没有进入主调用链。 |
| `uc:core-file` | `unified-lib/uc-core.lsp` | `uc:path-join + uc:project-root` | 是组合辅助函数，但目前调用方都直接拼路径。 |
| `uc:alist-put` | `unified-lib/uc-core.lsp` | `sys:alist-put` | 功能重叠明显，且当前主要 alist 写入仍在 TB 自身实现。 |
| `uc:block-effective-name` | `unified-lib/uc-core.lsp` | `sb:get-effective-name` | `SyncBlock` 里已有更贴近业务上下文的实现，统一层版本尚未收口接入。 |

---

## 三、暂保留，列为删除候选

这类函数目前看不到稳定调用点，且不是收敛主线上的关键接口。建议先保留记录，不立即删，但下轮可重点审查。

| 函数 | 文件 | 判断理由 |
|---|---|---|
| `blk:ref-geom` | `TB-Toolbox/tb-lib-blk.lsp` | 算法完整，但当前仓库没有块坐标变换调用链。 |
| `blk:block->insert` | `TB-Toolbox/tb-lib-blk.lsp` | 依赖 `blk:ref-geom` 的坐标变换能力，目前无上层使用。 |
| `blk:insert->block` | `TB-Toolbox/tb-lib-blk.lsp` | 同上。 |
| `curve:clockwise?` | `TB-Toolbox/tb-lib-curve.lsp` | 纯几何工具存在，但当前命令层没有明显顺逆时针决策点。 |
| `dim:make-rotated` | `TB-Toolbox/tb-lib-dim.lsp` | 有价值，但若后续没有自动标注计划，可能长期闲置；先观察。 |
| `entity:make-point` | `TB-Toolbox/tb-lib-entity.lsp` | 点实体创建能力完整，但当前业务几乎不生产 POINT。 |
| `point:in-polygon?` | `TB-Toolbox/tb-lib-point.lsp` | 典型储备型函数，若短期无区域判断需求，可列观察。 |
| `rebar:find-min-diameter` | `TB-Toolbox/tb-lib-rebar-edit.lsp` | 业务上合理，但当前主流程未使用，可能是半成品能力。 |
| `txt:rebar-normalize` | `TB-Toolbox/tb-lib-txt.lsp` | 当前实现是“原样返回”，属于名义接口，尚未形成真实行为。 |

> 注：这一组不是“建议立刻删除”，而是“下轮重构时优先确认是否继续保留”。

---

## 四、需要纠偏的一点

有些函数虽然在上面被分到“建议接入复用”，但如果后续决定不再维持那条抽象层，也可以反向并入或删除。

最典型的是：

- `sel:*`
- `dim:*`
- `txt:*`
- `blk:*`

它们是否值得继续保留，取决于一个更上层的选择：

1. 是否要让 `TB-Toolbox` 真正形成稳定的域函数库
2. 是否要把高复用能力继续往 `unified-lib` 收敛

如果答案是“要”，那这些函数应该继续接入复用。  
如果答案是“不要”，那就应该删掉薄封装和重复封装，只保留最少入口。

---

## 五、我建议的实际动作顺序

1. 先处理“已有等价实现，建议合并”这一组  
   目标：减少重复入口，避免统计上看着函数很多，实际维护口径却分裂。

2. 再处理“建议接入复用”这一组中的高价值函数  
   优先顺序建议：
   - `sel:*`
   - `dim:*`
   - `entity:get-color / entity:make-mtext`
   - `txt:get-height / txt:get-width / txt:get-style`

3. 最后审查“删除候选”  
   只在确认未来 1-2 轮不会接入时再删。
