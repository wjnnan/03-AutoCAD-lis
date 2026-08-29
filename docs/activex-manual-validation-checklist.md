# ActiveX 人工验证清单

> 用途：accoreconsole（无头测试环境）**没有 COM/ActiveX 对象模型**（`vlax-get-acad-object` 返回 nil），
> 以下功能依赖 ActiveX，无法在 `run_tests.py --all` 中自动测试。需在**完整 AutoCAD GUI** 中人工验证。
> 生成日期：2026-08-17（依据 accoreconsole 实测：`vlax-ename->vla-object`、`vla-*`、`vlax-curve-getLength` 均不可用/缺失）。

## 验证环境

- 完整 AutoCAD（GUI），建议用与生产一致的版本（本机为 AutoCAD 2024）
- 在命令行加载被测 lsp，逐个执行以下检查项

## 待验证功能清单

| # | 功能 | 涉及代码 | 为什么 accoreconsole 测不了 | 验证方式 |
|---|------|----------|------------------------------|----------|
| 1 | 批量打印（vla-PlotToFile） | TB-Toolbox/tb-mod-batchprint.lsp | COM Application 对象 nil，vla-* 全部失败 | 加载工具箱，BPT/BPSET 打印一个含图框的测试图纸，检查多格式输出 |
| 2 | 实体求交（vla-intersectwith） | TB-Toolbox 曲线/实体库、atlisp curve:inters | vla-intersectwith 依赖 COM | 画 XLine×Polyline，调 curve:inters，比对交点坐标 |
| 3 | 实体偏移（vla-Offset） | TB-Toolbox、route-of-hole2shape:offset-shape | vla-Offset 依赖 COM | 对直线/圆/多段线调 vla-Offset，检查偏移结果 |
| 4 | 实体属性写入（vla-put-layer/truecolor/StyleName） | 原 harness test-vlaput | vla-put-* 依赖 COM | 对实体调 vla-put-layer 等，检查特性面板变化 |
| 5 | 动态块属性（block:get-dynamic-properties / set-dynprop） | atlisp-packages/base/block.lsp | 需真实动态块 + COM | 插入含动态块的图纸，调 block:get-dynamic-properties 检查可用参数 |
| 6 | curve:area 的 COM 分支（vla-get-area） | TB-Toolbox/tb-lib-curve.lsp | accoreconsole 下 HAS-ACTIVEX 已修正为 nil，走纯函数；COM 分支未测 | 画闭合多段线/圆，调 curve:area 与属性面板面积比对 |
| 7 | vlax-curve-getLength | 项目内依赖此函数的代码 | accoreconsole 的 VLISP 函数集裁剪掉了此函数 | 确认生产环境可用，验证 curve:length 结果正确 |
| 8 | 动态/块相关 ActiveX（vla-InsertBlock 等） | tb-lib-entity make-insert / make-block | COM 依赖 | 调 entity:make-block + make-insert 检查块参照 |

## 已修正的相关发现（2026-08-17）

- `TB-Toolbox/tb-core.lsp` 的 `*SYS:HAS-ACTIVEX*` 已从**平台启发式**（非 ZWCAD 即 true）改为**实测 `vlax-get-acad-object`**。
  修复前 accoreconsole 误报 ActiveX 可用 → `curve:area` 走 COM 分支失败返回 0.0；修复后走纯函数 `vlax-curve-getarea`。
- accoreconsole 的 `and`/`or` 返回**符号 T** 而非第一个真值（`(or 28.27 0.0)` → T），依赖 `(or ...)` 返回值语义的封装在 accoreconsole 无法断言正确值。

## 建议节奏

- 每次大改 / 发布前，在完整 AutoCAD 跑一遍本清单（约 15-20 分钟）。
- 与 `test-all.bat --all`（自动，45 项）互补：自动层覆盖纯函数/封装回退路径，本清单覆盖 ActiveX 路径。
