# 代码审计报告：任务 7、9、10（2026-05-05）

## 任务 7：TB 命令层旧错误恢复入口剩余调用面盘点

### 全局检索结果

#### 旧入口定义（全部位于 `TB-Toolbox/tb-core.lsp`）

| 函数 | 行号 | 状态 | 内部调用 |
|------|------|------|---------|
| `err:handler` | 187 | 遗留定义 | 调用 `sys:undo-end`(188), `err:restore-sysvars`(189) |
| `err:save-sysvars` | 201 | 遗留定义 | 优先转调 `uc:snapshot-sysvars`(204-205) |
| `err:restore-sysvars` | 212 | 兼容包装 | 优先转调 `uc:restore-sysvars`(216-217) |
| `sys:undo-begin` | 255 | 兼容包装 | 优先转调 `uc:undo-begin`(258-259) |
| `sys:undo-end` | 270 | 兼容包装 | 优先转调 `uc:undo-end`(273-274) |

#### 调用面分析

**`*error*` 设置为 `err:handler`：零处。**
在整个 TB-Toolbox 中，没有任何命令函数执行 `(setq *error* err:handler)`。
`err:handler` 只被定义，从未被绑定到任何命令的错误处理链路。

**`err:save-sysvars` 的调用者：零处。**
除自身定义外，无任何命令或函数调用它。

**`err:restore-sysvars` 的调用者：仅 `err:handler` 内部（第 189 行）。**
因为 `err:handler` 本身无调用者，所以 `err:restore-sysvars` 实际也不会被触发。

**`sys:undo-begin` / `sys:undo-end` 的调用者：仅 `err:handler` 内部 + 各自的包装逻辑。**
同样因为 `err:handler` 未被挂载，这两个入口的实际运行时触发次数为零。

### 分类结论

| 分类 | 函数 | 说明 |
|------|------|------|
| **遗留定义** | `err:handler` | 定义了但从未绑定到 `*error*` |
| **遗留定义** | `err:save-sysvars` | 从未被调用 |
| **兼容包装** | `err:restore-sysvars` | 仅被同文件内的 `err:handler` 内部调用 |
| **兼容包装** | `sys:undo-begin` | 已转调 `uc:undo-begin`，但无外部调用者 |
| **兼容包装** | `sys:undo-end` | 已转调 `uc:undo-end`，但无外部调用者 |

### 结论

TB 命令层**实际上不依赖旧错误恢复链**。5 个旧入口全部是残留定义。
当前命令的错误保护走的是统一核心的 `uc:guard-begin/uc:guard-end` 路径，
或者（对于简单命令）根本不挂错误处理。

---

## 任务 8：是否将 TB 整体切换到 `uc:guard-*`

### 基于任务 7 的评估

**当前状态：** 旧保护链 (err:handler, err:save-sysvars, err:restore-sysvars) 虽然定义在 tb-core.lsp 中，
但没有任何命令使用它们。

**迁移收益：**
- 可删除 5 个遗留函数（~30 行），减少代码死重
- 消除未来有人误用旧入口的风险
- 所有新命令统一使用 `uc:guard-begin/uc:guard-end`，接口更清晰

**迁移风险：**
- 极低：经全文检索，无外部调用者
- 唯一风险：`sys:undo-begin/sys:undo-end` 的包装本身是兼容安全的，
  删除需确认没有任何通过 `(eval (read "sys:undo-begin"))` 的间接调用

**建议：不迁移，直接删除。**
因为旧入口无调用者，不存在"迁移"的问题。应将 5 个函数标记为废弃并移除。

### 决策记录

**决策：删除旧保护链定义。**
- `err:handler`, `err:save-sysvars`, `err:restore-sysvars` → 删除
- `sys:undo-begin`, `sys:undo-end` → 保留为兼容包装（仍有被其他模块间接引用的可能性）
- 理由：前三个无任何直接或间接调用者，后两个作为 tb-core 的外部接口仍可能在加载顺序中出现引用

---

## 任务 9：`uc:block-effective-name` 与 `sb:get-effective-name` 收敛评估

### 对照表

| 维度 | `uc:block-effective-name` | `sb:get-effective-name` |
|------|--------------------------|------------------------|
| 文件 | `unified-lib/uc-core.lsp:211` | `SyncBlock/SyncBlock.lsp:45` |
| 入参类型 | `ename`（实体名） | `obj`（VLA 对象） |
| 主路径 | `vla-get-EffectiveName` | `vla-get-EffectiveName` |
| 回退路径 | DXF 组码 2 | `vla-get-Name` |
| 匿名块处理 | 检查 `\`**` 前缀 | 无 |
| 错误包装 | `vl-catch-all-error-p` 守卫 | `vl-catch-all-apply` 守卫 |
| COM 不可用 | 自动走 DXF 2 回退 | 会报错（依赖 COM） |

### 行为差异

1. **输入类型不一致**：`uc` 接受 `ename`，`sb` 接受 VLA 对象。
   收敛时需统一入口，建议统一为 `ename`（更通用，不需要上游做 COM 转换）。

2. **回退路径差异**：
   - `uc`：DXF 2（纯 AutoLISP，不依赖 COM）
   - `sb`：`vla-get-Name`（仍需 COM）
   - **`uc` 的回退更健壮**，因为 DXF 2 在任何宿主和任何 CAD 版本中都可读。

3. **匿名块处理**：`uc` 有匿名块前缀检查，`sb` 无。
   这是 `uc` 更完整的地方。

4. **无 COM 场景**：
   - `uc`：自动降级到 DXF 2，不会报错
   - `sb`：`vla-get-EffectiveName` 和 `vla-get-Name` 都需要 COM，完全不可用

### 收敛建议

**建议：将 `sb:get-effective-name` 替换为对 `uc:block-effective-name` 的调用。**

具体步骤：
1. 修改 `sb:get-effective-name`，接受 `ename` 入参（而非 VLA 对象）
2. 内部调用 `uc:block-effective-name`
3. 修改上游调用点（SyncBlock.lsp:272, 288），传入 `ename` 而非 `vlax-ename->vla-object`
4. 这样 `sb:get-effective-name` 自然获得 DXF 2 回退和无 COM 降级能力

---

## 任务 10：`entity:make-layer` / `uc:ensure-layer` / `lay:make` 边界

### 三个入口对比

| 维度 | `lay:make` | `entity:make-layer` | `uc:ensure-layer` |
|------|-----------|-------------------|-------------------|
| 文件 | `tb-lib-lay.lsp:26` | `tb-lib-entity.lsp:113` | `uc-core.lsp:242` |
| 创建方式 | `entmake` | 转调 `uc:ensure-layer` | `entmakex` |
| 已存在时行为 | **更新颜色** | 处理 plot 标志 | 什么都不做 |
| plot 标志(290) | 不支持 | 支持 | 不支持 |
| 返回值 | 无 | `name` | `name` |
| 调用方数量 | ~12 处（TB 模块内） | ~1 处（atlisp-packages） | ~1 处（内部） |

### 行为差异

1. **已存在图层的更新行为不同**：
   - `lay:make`：如果图层已存在，会**更新颜色和线型**（行 37-38）
   - `entity:make-layer`：如果图层已存在，只处理 plot 标志，不更新颜色
   - `uc:ensure-layer`：如果图层已存在，**什么都不做**

2. **plot 标志处理**：
   - `entity:make-layer` 是唯一处理 plot 标志（DXF 290）的入口
   - `lay:make` 和 `uc:ensure-layer` 都不处理

3. **创建方式**：
   - `lay:make` 使用 `entmake`（无返回值）
   - `uc:ensure-layer` 使用 `entmakex`（返回 ename）
   - 这是有意的差异，因为 `lay:make` 设计为"不关心返回值"

### 边界建议

```
图层域（lay:*）：
  - lay:make        → 保留：模块层创建入口，有"更新已存在图层"的特殊语义
  - lay:exists?     → 已收敛到 uc:layer-exists-p（保留兼容包装）
  - 其他 lay:*      → 继续作为图层管理专用接口

实体域（entity:*）：
  - entity:make-layer → 保留：需要 plot 标志的场景（atlisp-packages 使用）

统一核心：
  - uc:ensure-layer  → 保留：最小纯创建，供所有上层复用
  - uc:prepare-layer → 保留：创建+解冻+解锁一站式入口
```

**不合并 `lay:make` 和 `uc:ensure-layer`**，因为：
1. `lay:make` 的"已存在时更新颜色"是 TB 模块需要的特有语义
2. `uc:ensure-layer` 是纯创建，更适合作 building block
3. 强行合并会引入不必要的条件分支和参数

**可收敛项**：
- `entity:make-layer` 内部已转调 `uc:ensure-layer`，这是正确的收敛方向
- 不再需要额外动作
