# AutoCAD Lisp 统一函数库重构 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 以 `atlisp-lib` 为系统函数库基座，完成 `TB-Toolbox`、`DiffCheck`、`SyncBlock` 的首轮统一函数库接入与风险收口。

**Architecture:** 采用“三层函数库 + 薄模块入口”方案。系统库优先复用 `atlisp-lib`，项目库新增统一核心适配层，业务模块只保留命令入口与领域流程，逐步移除重复基础实现。

**Tech Stack:** AutoLISP、Visual LISP、DCL、ActiveX/COM、PowerShell 静态检查

---

### Task 1: 建立重构台账与函数映射

**Files:**
- Create: `task_plan.md`
- Create: `findings.md`
- Create: `progress.md`
- Modify: `docs/superpowers/specs/2026-05-04-autocad-lisp-unified-function-library-design.md`

- [ ] **Step 1: 记录当前目标、范围与限制**

将以下要点写入台账文件：

```text
目标：统一首轮模块函数库，减少重复实现，收口错误恢复。
范围：TB-Toolbox、DiffCheck、SyncBlock。
限制：优先复用 atlisp-lib；不做无关模块大迁移；存在已知缺陷时不得宣称 0 bug。
```

- [ ] **Step 2: 记录已知高风险问题**

将以下项目写入 `findings.md`：

```text
TB-Toolbox: 加载路径、DCL 查找、批量打印逻辑缺陷
DiffCheck: 无统一 *error* 恢复、UNDO 不闭环、匿名块折叠
SyncBlock: 先删后拷、COM 强依赖、失败恢复缺失
```

- [ ] **Step 3: 更新设计文档中的函数映射结论**

补充每个旧函数的处理方式：

```text
直接复用 atlisp-lib
保留模块私有
迁入项目函数库
删除旧重复实现
```

- [ ] **Step 4: 自查文档覆盖**

检查设计文档是否覆盖：

```text
分层
模块边界
实施顺序
验证清单
```

### Task 2: 梳理统一函数库文件结构

**Files:**
- Create: `TB-Toolbox/tb-unified-core.lsp`
- Create: `TB-Toolbox/tb-unified-adapter.lsp`
- Modify: `TB-Toolbox/load.lsp`

- [ ] **Step 1: 定义统一核心文件职责**

文件职责应明确为：

```text
tb-unified-core.lsp: 平台、错误恢复、Undo、sysvar、配置、COM 安全调用
tb-unified-adapter.lsp: 对 atlisp-lib 的统一包装与兼容入口
```

- [ ] **Step 2: 调整加载顺序设计**

目标顺序：

```text
统一核心 -> 统一适配层 -> 旧模块库保留层 -> 业务模块 -> 命令入口
```

- [ ] **Step 3: 列出要替换的旧基础函数**

至少包括：

```text
sys:get / sys:set / sys:undo-begin / sys:undo-end
err:save-sysvars / err:restore-sysvars / err:handler
entity:get-bbox
图层存在与创建辅助
```

### Task 3: 改造 TB-Toolbox 基础层

**Files:**
- Modify: `TB-Toolbox/tb-core.lsp`
- Modify: `TB-Toolbox/tb-lib-entity.lsp`
- Modify: `TB-Toolbox/tb-main.lsp`
- Modify: `TB-Toolbox/load.lsp`

- [ ] **Step 1: 收口路径与配置来源**

重点处理：

```text
工具箱根目录
DCL 资源查找
系统配置路径
加载后全局变量生命周期
```

- [ ] **Step 2: 将重复实体/点/图层能力改为调用统一适配层**

重点处理：

```text
entity:get-dxf
entity:get-layer
entity:get-color
entity:get-bbox
entity:make-layer
```

- [ ] **Step 3: 收口命令分发与命令存在性判断**

重点处理：

```text
tb:bind
主界面按钮分发
命令是否已定义的判断方式
```

- [ ] **Step 4: 本地静态验证**

检查点：

```text
加载顺序无明显循环依赖
旧命令入口仍存在
DCL 路径不再只依赖 DWGPREFIX
```

### Task 4: 改造 DiffCheck

**Files:**
- Modify: `DiffCheck/DiffCheck.lsp`

- [ ] **Step 1: 接入统一错误恢复与 Undo**

覆盖：

```text
命令入口
云线绘制阶段
图层切换阶段
用户取消路径
```

- [ ] **Step 2: 替换通用能力为统一调用**

覆盖：

```text
边界框获取
图层准备
选择集转列表
sysvar 快照与恢复
```

- [ ] **Step 3: 保持差异算法局部不动**

保留：

```text
签名算法
框合并逻辑
偏移推导逻辑
```

- [ ] **Step 4: 本地静态验证**

检查点：

```text
空选择集不直接 exit 污染环境
REVCLOUD 中断可恢复
UNDO Begin/End 闭环
```

### Task 5: 改造 SyncBlock

**Files:**
- Modify: `SyncBlock/SyncBlock.lsp`

- [ ] **Step 1: 抽离危险操作为统一事务流程**

覆盖：

```text
主块校验
目标块过滤
删除旧对象
复制新对象
偏移与颜色映射
```

- [ ] **Step 2: 补失败恢复与保护**

至少处理：

```text
CopyObjects 失败
目标定义为空
非块对象误选
用户取消
COM 调用失败
```

- [ ] **Step 3: 改为统一错误恢复与 Undo**

目标：

```text
中途失败不留半损坏状态
统一使用恢复出口
避免散落 exit
```

- [ ] **Step 4: 本地静态验证**

检查点：

```text
先删后拷路径被保护
失败提示不再只依赖 Ctrl+Z
主块与目标块重名、空选、无有效几何时行为明确
```

### Task 6: 对抗性复审与收尾

**Files:**
- Modify: `findings.md`
- Modify: `progress.md`
- Modify: `task_plan.md`

- [ ] **Step 1: 逐模块复盘剩余风险**

按以下分类记录：

```text
已修复
待验证
已知残留
不在本轮范围
```

- [ ] **Step 2: 整理验证结果**

至少记录：

```text
静态检查结果
本地命令级检查结果
未能验证的 AutoCAD 实机路径
```

- [ ] **Step 3: 形成交付结论**

输出时必须区分：

```text
已完成内容
未闭环内容
是否允许继续下一轮
```
