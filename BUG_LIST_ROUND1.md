# 第一轮对抗性审查 — Bug 清单

## 严重 (会导致崩溃或数据损坏)

### 1. BR_Viewport.lsp:80 — eq 比较字符串
`(eq (cdr (assoc 0 (entget newEnt))) "VIEWPORT")` 使用 `eq` 比较字符串。`eq` 比较对象恒等性，不比较字符串值。应改为 `=`。

### 2. BR_Demo.lsp:63 — (* demo-clr -1) 零值问题
`(* demo-clr -1)` 当 demo-clr=0 时结果为 0（BYBLOCK），而非预期的 OFF 颜色。应改为 `(- demo-clr)`。

### 3. ImportGeoCSV.lsp:153-161 — cond 语法错误
```lisp
(cond
  (= kind "Aerial"    (setq layer "Aerial Fiber"))
  (= kind "Underground" (setq layer "UNDERGROUND"))
)
```
正确的 cond 语法需要每对条件用括号包裹。

### 4. MeasureStationNum.lsp:30 — 未初始化变量
当 `dist < 100` 时 `last2digits` 从未被赋值，传入 `padZero` 导致 `(itoa nil)` 崩溃。

### 5. DrawFiber.lsp:161-201 — buffer-num 越界
GetFiberLayer 中 `buffer-num` 仅处理 1-8，`fiber-num` 仅处理 1-12。当 `buffer-num=0` 时 buffer-color 为 nil，strcat 崩溃。

### 6. FixPDFImport.lsp:7-9 — 未检查 ssget 空选择
`(setq hatchSet (ssget))` 后直接 `(ssname hatchSet 0)`，如果图中没有 HATCH 对象则崩溃。

### 7. 多处 entsel/getpoint 未检查 nil
DrawFiber.lsp:5,40,79 / InsertNAP.lsp:3,7 / PlaceNAP.lsp:6,12 / StreetLabel.lsp:33-34 / ObjectInfo.lsp:6 / MoveToCenter.lsp:5-7 / CircleNumber.lsp:2 / AlignToCenter.lsp:9-11 / MeasureStationNum.lsp:5-7

### 8. SidewalkTrim.lsp:117-119 — 数据结构访问错误
`(cadr ent1)` 和 `(caddr ent1)` 对 intList 中存储的 cons cell 结构访问不正确，可能无法正确获取交点坐标。

## 中等 (功能错误或非预期行为)

### 9. BR_Snapshot.lsp:545,592,624 — nil 消息错误打印
`(if (/= msg "Function cancelled") (princ (strcat "\nSnapshot error: " msg)))` 当 msg 为 nil 时仍打印 "Snapshot error: nil"。应先检查 msg。

### 10. SumFootage.lsp:8 — eq 比较字符串
`(eq (cdr (assoc 0 (entget pline))) "LWPOLYLINE")` 同样使用 `eq`，与 Bug #1 相同。

### 11. InsertNAP.lsp:11 — 仅检查 MTEXT 不检查 TEXT
只检查 `"MTEXT"`，但 AutoCAD 中 DTEXT/TEXT 命令创建的是 TEXT 类型。应检查 `"TEXT,MTEXT"`。

### 12. InsertNAP.lsp:62 — "/n" 拼写错误
`"/nError:"` 应为 `"\nError:"`。

### 13. DrawFiber.lsp:9 — EffectiveName 可能不存在
`vla-get-EffectiveName` 仅对动态块有意义。对普通块应使用 `vla-get-Name`。

### 14. DrawFiber.lsp:54,92,102,195 — exit 误用
`(exit)` 退出整个 LISP 解释器，不是仅退出当前函数。应返回 nil。

### 15. PlaceNAP.lsp:40-49 — MTEXT 零宽度
`stamppos` 同时用作第一角和第二角，文本框宽度为零。

### 16. PlaceNAP.lsp:15-22 / ObjectInfo.lsp:24 — 依赖 Map 3D
`ade_odgettables` 和 `ade_odgetfield` 仅在 Map 3D 中可用，未检查可用性。

### 17. ObjectInfo.lsp:11 — vla-get-name 对非块对象无效
Line、Circle 等没有 Name 属性，调用会抛错。

### 18. MeasureArrow.lsp:38 — CECOLOR 空格问题
`"15, 15, 15"` 中空格可能被 command 误解析为多个参数。

### 19. ImportGeoCSV.lsp:67 — osmode 保存位置错误
循环内保存的 osmode 实际读取的是已被置 0 的值。

### 20. CenterText.lsp:5 / JustifyTextToCenter.lsp:6 — 仅处理第一条
`(ssname ss 0)` 只处理选择集中第一个实体。

### 21. StreetLabel.lsp:10-22 — htmlfile 剪贴板已过时
IE htmlfile ActiveX 在新 Windows 版本中可能不可用。

### 22. ConvertNAPs.lsp:46 — 未使用变量 atts
`(setq atts (mapcar ...))` 构建了 atts 但从未使用。

### 23. ManageLayers.lsp — 无错误处理
图层操作命令在图层不存在时静默失败。

## 轻微 (代码质量)

### 24. BR_Insert.lsp:1194 — target-layer 可能含空格
图层名含空格时 command 会把空格当参数分隔符。

### 25. CopyLayouts.lsp:15 — defun 重复定义
`sort-numeric` 每次调用都重新定义。

### 26. measure callouts.lsp — 命令名冲突
`c:MeasureCallouts` 与 `MeasureCallouts.lsp` 中的同名命令冲突。

### 27. DrawFiber.lsp 等 — 空命令调用设置颜色
`(command "_COLOR" "BYLAYER")` 改变当前实体颜色，可能覆盖用户设置。
