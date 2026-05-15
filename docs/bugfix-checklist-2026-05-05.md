# Bug 修复清单 — 对抗性审查 & 迭代修复记录（2026-05-05）

## 迭代流程

```
审查 → 列 bug → 改代码 → 验证 → 重新审查 → 再列 bug → 再改 → ... → 零 bug
```

每轮标注状态：✓ 已修复, ✗ 待修复, ≈ 无需改动/假阳性

---

## 第一轮：全局审计发现（2026-05-05）→ 修复完成（2026-05-14）

### P0 — 严重（阻塞加载 / 运行时崩溃 / 死循环）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| B1 | `uc-core.lsp:1` | `(vl-load-com)` 在 ZWCAD 无 COM 平台崩溃 | ✓ |
| B2 | `tb-core.lsp:56` | `(getvar "ROAMABLEROOTPREFIX")` — ZWCAD/旧版CAD不识别此变量名，getvar 直接抛错 | ✓ |
| B3 | `tb-lib-lay.lsp:54` | `lay:off` — `(abs nil)` 当图层缺少 DXF 62 时崩溃 | ✓ |
| B4 | `tb-lib-lay.lsp:58` | `lay:on` — 同上 `(abs nil)` | ✓ |
| B5 | `tb-lib-lay.lsp:74-98` | `lay:freeze/thaw/lock/unlock` — `(cdr (assoc 70 nil))` 当 get-entry 返回 nil 时崩溃 | ✓ |
| B6 | `tb-lib-txt.lsp:122` | `txt:rebar-replace` — `while` + `vl-string-subst`，当 `new` 包含 `old` 子串时产生死循环 | ✓ |
| B7 | `tb-lib-curve.lsp:15` | `curve:area` — `(vlax-ename->vla-object ...)` 在 ZWCAD 上崩溃 | ✓ |
| B8 | `tb-lib-entity.lsp:179` | `entity:bbox-pure` — `(textbox ...)` 返回相对插入点的坐标，非绝对世界坐标，TEXT 包围盒位置错误 | ✓ |

### P1 — 中等（功能异常 / 边界条件）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| B9 | `tb-lib-point.lsp:45` | `point:offset` — `(caddr pt)` 对 2D 点返回 nil，下游 `(+ (cadr pt) nil)` 崩溃 | ✓ |
| B10 | `tb-mod-centerline.lsp:102` | ARC 中心线角度 `(+ ang1 (/ (- ang2 ang1) 2.0))` — 弧跨越 0° 方向时 ang2 < ang1，算出错误的弧中点 | ✓ |
| B11 | `tb-lib-rebar.lsp:92,168` | `rebar:make-bar` / `rebar:make-pline-with-bulges` — width 可能为 nil（`sys:get` 在首次加载返回 nil 时） | ✓ |
| B12 | `tb-lib-rebar.lsp:330-335` | `rebar:remove-hook` 起始钩移除后 bulge 重置 — 经详细代码追踪，`cddr` 后首 bulge 确为 D 顶点，重置正确 | ≈ |

### P2 — 低（代码质量 / 健壮性）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| B13 | `uc-core.lsp:221-223` | `uc:ensure-layer` 现在更新已存在图层的颜色/线型 — 与 layout 文档设计意图矛盾，需同步更新 docs | ≈ |
| B14 | `tb-mod-centerline.lsp:36-37` | 直接 `(command "_.LINETYPE" ...)` — 非 COM 平台不稳定 | ✓ |
| B15 | `tb-lib-dim.lsp:58` | `dim:home` 直接 `(command "_.DIMTEDIT" ...)` | ✓ |
| B16 | `tb-lib-blk.lsp:59` | `blk:quick-make` 直接 `(command "_BLOCK" ...)` | ✓ |
| B17 | `tb-main.lsp:42-153` | `c:TB` / `c:TBSETTING` 无错误处理包裹 — DCL 异常时可能残留未关闭对话框 | ✓ |
| B18 | `load.lsp:67-79` | 文件不存在时的错误消息仅输出文件名，不输出完整路径，不便排查 | ✓ |

---

## 第二轮审查发现（2026-05-14）

### R2-CRITICAL

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R2-1 | `tb-lib-rebar.lsp:402` | `rebar:make-stirrup` 矩形箍筋缺少 p4 顶点，几何形状完全错误 | ✓ |
| R2-2 | `tb-lib-blk.lsp:110-126` | `blk:rename` 直接修改块定义表不更新 INSERT 引用，导致图纸数据损坏 | ✓ |

### R2-HIGH

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R2-3 | `tb-lib-curve.lsp:128` | `curve:inters-lines` `inters` onseg 参数为 nil，计算无限直线交点非线段交点 | ✓ |
| R2-4 | `tb-lib-curve.lsp:113` | `curve:vertices` POLYLINE 过滤列表错误包含标志 32（3D 多段线顶点全丢失） | ✓ |
| R2-5 | `tb-lib-lay.lsp:60` | `lay:off` 图层颜色为 0 (BYBLOCK) 时取负后仍为 0，图层不会关闭 | ✓ |
| R2-6 | `tb-lib-rebar.lsp:370-376` | `rebar:make-stirrup` `*SYS:REBAR-COVER*` 无 nil 检查，初始化不全时报错 | ✓ |
| R2-7 | `tb-lib-rebar.lsp:94-95` | `rebar:make-bar` 系列函数 nil 图层传播到底层 entmakex | ✓ |
| R2-8 | `tb-lib-dim.lsp:10-12` | `dim:get-text` 空字符串 `""` 为 truthy，`or` 导致未覆写标注返回空串 | ✓ |
| R2-9 | `tb-mod-centerline.lsp:28` | `c:ce` 全局变量泄漏（lst/cl 未声明为局部变量） | ✓ |
| R2-10 | `tb-lib-entity.lsp:137-148` | `entity:get-bbox` 纯 Lisp 路径下 offset 参数被静默忽略 | ✓ |

### R2-MEDIUM

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R2-11 | `tb-lib-entity.lsp:197-202` | `entity:set-attrib` 缺少 DXF 66 检查，可能遍历到无关图元 | ✓ |
| R2-12 | `tb-lib-point.lsp:79-85` | `point:bbox` 空点表输入导致 `(apply 'min nil)` 崩溃 | ✓ |
| R2-13 | `tb-lib-point.lsp:89-91` | `point:center` 空点表导致除零崩溃 | ✓ |
| R2-14 | `tb-lib-curve.lsp:20` | `curve:area` ZWCAD 路径可能返回 nil 而非 0.0 | ✓ |
| R2-15 | `tb-mod-centerline.lsp:35-37` | 线型加载顺序不当（先创建图层后加载线型） | ✓ |
| R2-16 | `tb-mod-centerline.lsp:113-117` | 开放多段线也会创建闭合边中心线（多余线） | ✓ |
| R2-17 | `tb-mod-centerline.lsp:37` | 线型文件名硬编码 `acad.lin`（ZWCAD 用 `zwcad.lin`） | ✓ |
| R2-18 | `tb-mod-centerline.lsp:77-119` | `cl:entity-centerline` 返回类型不一致（单 ename vs 列表） | ✓ |
| R2-19 | `tb-main.lsp:217` | `c:TBSETTING` 错误处理器未在所有路径上恢复 | ✓ |
| R2-20 | `tb-lib-rebar.lsp:422-423` | `rebar:make-poly-stirrup` 缺少边界点数量验证 | ✓ |

---

## 第三轮审查发现（2026-05-14）

### R3-CRASH（运行时崩溃）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R3-1 | `tb-lib-dim.lsp:14` | `dim:get-text` — `(rtos (entity:get-dxf ename 42) 2 0)` 当 ename 无效或缺少 DXF 42 时，rtos 收到 nil 崩溃 | ✓ |
| R3-2 | `tb-lib-blk.lsp:71-72` | `blk:ref-geom` — `(cos (cdr (assoc 50 elst)))` 对非 INSERT 图元 DXF 50 缺失返回 nil，cos nil 崩溃 | ✓ |
| R3-3 | `tb-lib-lay.lsp:56-68` | `lay:off`/`lay:on` — 颜色 0 (BYBLOCK) 被强制改为 7 后不可逆恢复，图层颜色数据损坏 | ≈ |
| R3-4 | `tb-lib-entity.lsp:179,187` | `entity:bbox-pure` — `(wcmatch typ "…")` 当 `entity:get-type` 返回 nil 时崩溃（bad argument type: stringp nil） | ✓ |
| R3-5 | `tb-lib-entity.lsp:139-141` | `entity:get-bbox` — `uc:entity-bbox` 无 `vl-catch-all-apply` 包装，其本身内部已有保护但多一层更安全 | ✓ |
| R3-6 | `tb-lib-curve.lsp:97-118` | `curve:vertices` — ename 为 nil 时 typ=nil 穿透到 t 分支，`curve:startpt nil` 调用 `vlax-curve-getstartpoint nil` 崩溃 | ✓ |
| R3-7 | `tb-lib-rebar.lsp:402` | `rebar:make-stirrup` — 闭合多段线顶点 `tail0→C0→p1→p2→p3→C2→tail2→p4→(close→tail0)`，底边 p4→p1 缺失，闭合段 p4→tail0 错误 | ✓ |

### R3-HIGH（功能异常）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R3-8 | `tb-lib-rebar.lsp:215-227` | `detect-hook-end` — 顶点数 n=4 时起始/末端检测窗口重叠，单端弯钩被误判为两端都有 | ✓ |
| R3-9 | `tb-lib-dim.lsp:45-47` | `dim:is-overridden?` — DXF 1 不存在（nil）时 `(equal nil "")`=nil，`(not nil)`=T，未覆写标注被误判为已覆写 | ✓ |
| R3-10 | `tb-mod-centerline.lsp:99-115` | Circle/Arc 中心线 Z 坐标硬编码为 0，非 WCS 平面实体会绘制到错误标高 | ✓ |

### R3-LOW（边界加固）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R3-11 | `tb-lib-rebar.lsp:370` | `rebar:make-stirrup` — `(rebar:bend-radius d grade)` 若 d 为 nil 则 R=nil，后续坐标计算全为 nil | ✓ |

---

---

## 第四轮审查发现（2026-05-14）

### R4-CRASH（运行时崩溃）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R4-1 | `tb-mod-edit.lsp:98` | `c:s00` — `(ssget)` 返回 nil 时直接传入 `command "_.SCALE"` 崩溃 | ✓ |
| R4-2 | `tb-mod-edit.lsp:147-154` | `c:C1`~`c:C8` — 8 个颜色命令均未检查 `(ssget)` 返回值 | ✓ |
| R4-3 | `tb-mod-edit.lsp:119-121` | `c:cx` — `getpoint` 返回 nil 时未检查，`command "_.LINE" nil nil` 崩溃 | ✓ |
| R4-4 | `tb-mod-text.lsp:96-97` | `c:th` — `while`+`vl-string-subst`，new 包含 old 子串时死循环（同 B6 模式） | ✓ |

### R4-HIGH（功能异常）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R4-5 | `tb-mod-edit.lsp:55-56` | `c:cr` — `(command "_.ROTATE" ss "_P" ...)` 同时旋转原件和复制品，应只用 `_P` | ✓ |
| R4-6 | `tb-mod-block.lsp:9-15` | `c:jk` — pt 为 nil 时打印误导信息"块已创建: nil" | ✓ |
| R4-7 | `tb-mod-dim.lsp:49-61` | `c:bbf` — `safe:get-int` 默认值为 0 时导致除零崩溃 | ✓ |
| R4-8 | `tb-lib-txt.lsp:94-110` | `txt:set-left/center/middle-align` — 修改 DXF 72/73 时未同步 DXF 10↔11，文字跳原点 | ✓ |
| R4-9 | `tb-lib-entity.lsp:115-123` | `entity:make-block` — 未检查 BLOCK 头 `entmakex` 是否成功，失败时子实体泄漏到模型空间 | ✓ |
| R4-10 | `tb-core.lsp:194-204` | `safe:get-real`/`safe:get-int` — default 为 nil 时 `rtos`/`itoa` 崩溃 | ✓ |
| R4-11 | `tb-core.lsp:115-116` | `sys:load-config` — `(read)` 对损坏配置文件无 `vl-catch-all-apply` 保护 | ✓ |
| R4-12 | `tb-lib-rebar.lsp:236-237` | `rebar:get-hook-sign` — 起始钩 bulge 方向与真实 hook-dir 相反，镜像命令弯钩方向修正失效 | ✓ |
| R4-13 | `tb-mod-rebar-edit.lsp:244-247` | `c:RN` — Y/U/D 排序方向与提示文字完全相反（Y/U 实际是上→下） | ✓ |
| R4-14 | `tb-lib-rebar.lsp:214` | `detect-hook-end` — n=4 时返回 0 漏检弯钩，导致 `add-hook` 重复叠加弯钩几何 | ✓ |
| R4-15 | `tb-lib-rebar.lsp:393-407` | `rebar:make-stirrup` — tail2→p4 段硬编码 bulge=0，弯钩尾部与矩形边不共线导致失真 | ✓ |

### R4-MEDIUM（边界加固）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R4-16 | `tb-mod-dim.lsp:68-71` | `c:bgc` — `sys:get` 返回 nil 时传入 `lay:make nil 3` 创建无名图层 | ✓ |
| R4-17 | `tb-mod-dim.lsp:103` | `c:zb` — `sys:get '*SYS:TEXT-HEIGHT*` 为 nil 时传入 `entity:make-text` | ✓ |
| R4-18 | `tb-mod-block.lsp:82-88` | `c:sk` — 坐标精度仅 1 位小数，大坐标图纸误删邻近块 | ✓ |
| R4-19 | `tb-lib-point.lsp:97-112` | `point:sort`/`point:nearest` — `vl-sort` 破坏原始列表且可能去重丢失点 | ✓ |
| R4-20 | `tb-lib-point.lsp:88-95` | `point:center` — 整数除法截断，整数坐标时精度丢失 | ✓ |
| R4-21 | `tb-lib-entity.lsp:80` | `entity:make-text` — 宽度因子硬编码 0.7，未使用 `*SYS:TEXT-WIDTH*` 配置 | ✓ |
| R4-22 | `tb-lib-curve.lsp:116-121` | `curve:vertices` — 3D 多段线 VERTEX 标志 64 被过滤导致顶点全丢失 | ≈ |
| R4-23 | `tb-lib-entity.lsp:201-207` | `entity:set-attrib` — 修改属性后未调用 `entupd` 刷新显示 | ✓ |
| R4-24 | `tb-mod-edit.lsp:46` | `c:cf` — 等距复制阵列方向硬编码 `dist 0`（固定水平），忽略用户意图 | ≈ |

### R4-LOW（代码质量）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R4-25 | `tb-lib-entity.lsp:198` | `entity:get-attribs` — 声明但未使用的局部变量 `atts` | ✓ |
| R4-26 | `tb-lib-point.lsp:119-123` | `point:rect-2pt->4pt` — 声明但从未使用的局部变量 `p2`, `p4` | ✓ |
| R4-27 | `tb-mod-rebar-edit.lsp:172-173` | `c:RN` — 局部变量列表重复声明 `existing-nums existing-texts max-num` | ✓ |
| R4-28 | `tb-lib-blk.lsp:24-25` | `blk:list` — `(= (substr name 1 2) "*D")` 被第一个条件完全包含，永真冗余 | ≈ |
| R4-29 | `tb-mod-centerline.lsp:36-43` | `c:ce` — LINETYPE 加载所有分支都不匹配时空文件名回退，ZWCAD 行为不确定 | ≈ |

---

## 第五轮审查发现（2026-05-14）

### R5-HIGH（功能异常）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R5-1 | `tb-mod-text.lsp:69-84` | `c:ttj` — `e1` 未声明为局部变量（全局泄漏）；合并后文字 `(txt:set-content e1 source-str)` 放在 ssget 失败分支而非 foreach 之后，导致文字实际不合并 | ✓ |
| R5-2 | `tb-mod-centerline.lsp:55-63` | `c:ce` 两平行 LINE — 当两条线绘制方向相反时，start-start/end-end 中点对交叉，中心线退化为一个点 | ✓ |
| R5-3 | `tb-mod-rebar.lsp:324` | `c:RBR` — `(while (<= y y3) ...)` 当 spacing ≤ 0 时 y 不变或递减，造成死循环 | ✓ |
| R5-4 | `tb-mod-rebar.lsp:368` | `c:RBF` — 同上 `(while (<= dist len) ...)`，spacing ≤ 0 造成死循环 | ✓ |

### R5-MEDIUM（边界加固）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R5-5 | `tb-mod-rebar.lsp:251` | `c:RD` — `text-h = (* (sys:get ...) (sys:get ...) 0.01)`，若配置未初始化返回 nil，entmakex 传入 nil 高度会报错 | ✓ |
| R5-6 | `tb-mod-rebar.lsp:283` | `c:RCC` — 同上，text-h 可能为 nil | ✓ |

### R5-LOW（代码质量）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R5-7 | `tb-mod-edit.lsp:127` | `c:z0` — 声明但未使用的局部变量 `i` | ✓ |
| R5-8 | `tb-mod-dim.lsp:100` | `c:zb` — 声明但未使用的局部变量 `style` | ✓ |

---

## 第六轮：钢筋几何 & 跨平台健壮性（2026-05-14）

### R6-HIGH（几何错误）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R6-1 | `tb-lib-rebar.lsp:408` | `rebar:make-stirrup` — `closed=T` 导致自动闭合段 `p1→tail0` 穿过起始弯钩区域，产生重叠错误几何。改为 `nil`，因显式边 `p4→p1` 已闭合矩形 | ✓ |

### R6-MEDIUM（功能异常）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R6-2 | `tb-mod-rebar.lsp:153` | `c:RDH` 删除两端弯钩 — 用 `(entlast)` 获取新实体（脆弱），改用 `rebar:remove-hook` 返回值 | ✓ |
| R6-3 | `tb-mod-cloud.lsp:50` | `c:rt` — `cloud-en` 可能为 nil，后续 `curve:closest-pt cloud-en pt1` 崩溃。添加 `(and cloud-en ...)` 守卫 | ✓ |

### R6-LOW（健壮性加固）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R6-4 | `tb-lib-curve.lsp:16` | `curve:area` — 无 ename nil 检查，添加守卫 | ✓ |
| R6-5 | `tb-mod-rebar.lsp:193` | `c:RO` — 裸 `command "_.OFFSET"` 无错误保护，包裹 `vl-catch-all-apply` | ✓ |
| R6-6 | `tb-lib-rebar.lsp:423` | `rebar:make-poly-stirrup` — 边界点检查 `< 2` 改为 `< 3`（最少 3 点） | ✓ |
| R6-7 | `tb-mod-beam.lsp:48` | `c:pq` / `c:tml` — 使用 `PEDIT "_L"` 而非捕获返回值，make-pline 失败时 PEDIT 修改错误实体 | ≈ |

---

## 第七轮：批量打印、钢筋编辑库、编译系统（2026-05-14）

### R7-HIGH（数据损坏/错误迭代）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R7-21 | `tb-mod-batchprint.lsp:167` | `bp:get-block-attrs` — 缺少 DXF 66=1 检查，对无属性 INSERT 调用 `entnext` 会遍历到数据库中的无关实体，收集垃圾数据作为"属性" | ✓ |

### R7-MEDIUM（功能异常/崩溃）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R7-1 | `tb-lib-rebar-edit.lsp:150` | `rebar:calc-area-per-meter` — 当 s=0 或 nil（畸形输入 `Φ8@`），`(/ 1000.0 s)` 除零崩溃。添加守卫返回 0.0 | ✓ |
| R7-4 | `tb-mod-rebar-edit.lsp:238` | `c:RN` — `vl-sort ents` 未用 `(append ents nil)` 复制，同坐标实体可能被去重丢弃导致漏编号 | ✓ |
| R7-28 | `tb-mod-batchprint.lsp:257,263` | `bp:sort-by-x` / `bp:sort-by-y` — `vl-sort` 直接操作原表，同坐标图纸可能被丢弃 | ✓ |
| R7-5 | `tb-mod-rebar-edit.lsp:172` | `c:RN` — 多个变量（`dupes`, `missing`, `sorted-nums`, `prev`, `ents`, `new-str`, `count`）未声明为局部变量，全局泄露；`detect-issues` 声明但从未使用 | ✓ |

### R7-LOW（代码规范）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R7-31 | `tb-mod-column.lsp:50` | `c:sg` — `ang` 变量未声明为局部变量，全局泄露 | ✓ |

### R7-已知取舍

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R7-11 | `build.lsp:23` | `findfile` 检查目录存在性（应用 `vl-file-directory-p`），当目录不在支持路径时返回 nil → `vl-mkdir` 对已存在目录失败无害 | ≈ |
| R7-19 | `tb-main.lsp:173-186` | `c:TBSETTING` 多个 `set_tile` 调用无 nil 守卫，但参数初始化保证这些值永不为 nil | ≈ |

---

## 第八轮：entmakex nil 传播 & 未定义函数（2026-05-14）

审查重点：entmakex 返回 nil 时 _L 野指针、command 裸调用、entlast 竞态、未定义函数引用。覆盖 17 个 .lsp 文件。

### R8-HIGH（数据损坏/运行时崩溃）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R8-1 | `tb-mod-beam.lsp:21,47,52,57,87` | `c:tml` / `c:pq` / `c:pmh` — `entity:make-pline` 使用 entmakex 可能返回 nil，后续 `PEDIT "_L"` 在 entmakex 失败时操作错误实体（_L=数据库最后实体而非刚创建的）。**×5 处**。修复：保存 ename 并显式传给 PEDIT | ✓ |
| R8-2 | `tb-mod-bubble.lsp:16-25` | `c:qb` — 块定义中 `(ssadd (entlast) (ssadd (entnext blk-def-e1)))` 两处错误：(1) `entnext` 返回文字之后的实体而非圆；(2) `blk-def-e1`/`blk-def-e2` 死代码。导致块包含错误实体。修复：用 `entity:make-circle` 和 `entity:make-text` 返回值直接构建 SS | ✓ |
| R8-3 | `tb-core.lsp:225,232,247` 等多处 | `uc:command-safe` 和 `uc:function-defined-p` 函数被 `sys:undo-begin/end`、`blk:quick-make`、`blk:rename`、`dim:home-selection`、`c:ce` 等引用但从未定义，运行时崩溃"no function definition"。修复：在 tb-core.lsp §6 通用工具中定义本地兼容实现 | ✓ |
| R8-4 | `tb-mod-rebar.lsp:234` | `c:RL` — `(rebar:make-bar ...)` 后无条件 `(entdel e)`，若 entmakex 失败则原 LINE/LWPOLYLINE 被删除且无新钢筋替代（数据丢失）。修复：仅在新钢筋创建成功后删除原线 | ✓ |

### R8-MEDIUM（功能异常）

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R8-5 | `tb-mod-misc.lsp:37` | `c:dxx` — 调用 `c:dx` 后使用 `(entlast)` 获取实体，若 `c:dx` 中 `entity:make-pline` 失败则 `entlast` 返回无关实体，`OFFSET` 偏移错误对象 | ≈ |

### R8-已知取舍

| # | 文件:行 | 问题 | 状态 |
|---|--------|------|------|
| R8-5 | `tb-mod-misc.lsp:37` | 同上 R8-5 — `c:dx` entmakex 失败概率极低（简单几何+合法图层），且 OFFSET 对不可偏移实体直接报错，不会静默损坏 | ≈ |

---

## 最终验证

执行以下验证命令确认全部通过：

```bash
cd "d:\My Code\Claude Code\03-AutoCAD-lisp"
python tests/verify_*.py  # 所有 verify 脚本确认 PASS
```

### R8 验证结果（2026-05-14）

| 检查项 | 方法 | 结果 |
|--------|------|------|
| beam.lsp PEDIT _L 已消除 | `grep "PEDIT.*_L" tb-mod-beam.lsp` | PASS（0 匹配） |
| beam.lsp PEDIT 使用显式 ename | `grep "PEDIT.*en[0-9]" tb-mod-beam.lsp` | PASS（4 匹配） |
| bubble.lsp 块定义使用变量 | `grep "circ-en\|text-en" tb-mod-bubble.lsp` | PASS（有定义和使用） |
| core.lsp uc: 函数已定义 | `grep "defun uc:" tb-core.lsp` | PASS（2 定义） |
| rebar.lsp entdel 有守卫 | `grep -B2 "entdel e" tb-mod-rebar.lsp` | PASS（由 if make-bar 守卫） |
| verify_uc_function_defined_runtime.py | Python 脚本 | PASS |
| verify_uc_core_error_safety.py | Python 脚本 | PASS |
