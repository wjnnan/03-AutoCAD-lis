;;; tb-lib-rebar.lsp — 钢筋几何库
;;; 钢筋 = 等宽多段线 + 弯钩弧段（bulge）
;;; 核心几何：通过多段线组码 43（常量线宽）和 42（弧段凸度）实现
;;; 依赖：tb-core.lsp, tb-lib-point.lsp, tb-lib-entity.lsp, tb-lib-lay.lsp
;;;
;;; 弯钩类型：1=圆钩180°(HPB300)  2=斜钩135°(HRB400抗震)  3=直钩90°  0=无钩
;;; 弯曲直径：一级钢 2.5d，二/三级钢 4d (GB 50010-2010)
;;; 弯后平直段：圆钩 3d，斜钩 5d(非抗震)/10d(抗震)，直钩 12d

;; ============================================================================
;; 弯钩参数计算
;; ============================================================================

(defun rebar:hook-angle (hook-type)
  "弯钩角度（弧度）。1=180°, 2=135°, 3=90°。"
  (cond ((= hook-type 1) pi)
        ((= hook-type 2) (* pi 0.75))
        ((= hook-type 3) (* pi 0.5))
        (t 0.0)))

(defun rebar:hook-bulge (hook-type / ang)
  "弯钩 bulge 值。bulge = tan(angle/4)。"
  (setq ang (rebar:hook-angle hook-type))
  (if (> ang 0)
    (/ (sin (* 0.25 ang)) (cos (* 0.25 ang)))
    0.0))

(defun rebar:bend-radius (d grade)
  "弯曲半径。一级钢(grade=1): 1.25d，二/三级钢: 2.0d。"
  (* 0.5 d (if (= grade 1) 2.5 4.0)))

(defun rebar:hook-tail (hook-type d grade)
  "弯后平直段长度。"
  (cond
    ((= hook-type 1) (* d 3.0))                        ; 圆钩: 3d
    ((= hook-type 2) (* d (if (= grade 1) 5.0 10.0)))  ; 斜钩: 5d/10d
    ((= hook-type 3) (* d 12.0))                       ; 直钩: 12d
    (t 0.0)))


;; ============================================================================
;; 弯钩几何生成
;; ============================================================================

;; 生成末端弯钩的几何数据（bar→tail 方向）。
;; D: 钢筋末端点（弯弧起点）
;; ang: 钢筋在 D 处的方向角（弧度）
;; hook-type: 弯钩类型 1/2/3/0
;; hook-dir: +1=左弯(CCW), -1=右弯(CW)
;; d: 钢筋直径(mm)  grade: 钢筋等级(1/2/3)
;; 返回: ((C . bulge-at-D) (tail-end . bulge-at-C))
;; 调用者将 bulge-at-D 赋给顶点 D，bulge-at-C 赋给顶点 C。
(defun rebar:make-hook-geom (D ang hook-type hook-dir d grade
                             / R hook-angle hook-bulge tail-len perp-ang
                               O start-ang end-ang C tail-dir tail-end)
  (if (= hook-type 0)
    nil  ; 无弯钩
    (progn
      (setq hook-angle (rebar:hook-angle hook-type)
            hook-bulge (rebar:hook-bulge hook-type)
            R          (rebar:bend-radius d grade)
            tail-len   (rebar:hook-tail hook-type d grade)
            perp-ang   (+ ang (* hook-dir (* pi 0.5)))   ; 弯曲内侧方向
            O          (point:polar D perp-ang R)         ; 弯心
            start-ang  (+ perp-ang pi)                    ; 从弯心指向 D 的角度
            end-ang    (+ start-ang (* hook-dir hook-angle)) ; 从弯心指向 C 的角度
            C          (point:polar O end-ang R)          ; 弧段终点
            tail-dir   (+ end-ang (* hook-dir (* pi 0.5))) ; 尾段切线方向
            tail-end   (point:polar C tail-dir tail-len)) ; 尾端
      ;; 返回: (C . bulge-at-D) (tail-end . 0)
      (list (cons C (* hook-dir hook-bulge))
            (cons tail-end 0.0)))))


;; ============================================================================
;; 钢筋创建
;; ============================================================================

;; 创建钢筋多段线。
;; pts: 钢筋路径点表（不含弯钩）
;; hook-start: 起始端弯钩类型 (0/1/2/3)
;; hook-end: 末端弯钩类型 (0/1/2/3)
;; d: 钢筋直径(mm)  grade: 钢筋等级(1/2/3)
;; hook-dir: +1 左弯, -1 右弯
;; width: 多段线常量线宽（nil=自动按 d 计算）
;; layer: 图层名（nil=当前图层）
;; 返回: 多段线 ename
(defun rebar:make-bar (pts hook-start hook-end d grade hook-dir width layer
                       / all-pts all-bulges dir-ang hook-geom
                         D C bulge-D bulge-C tail-end)
  ;; 默认线宽：钢筋直径 × 出图比例系数
  (or width (setq width (* d (or (sys:get '*SYS:DWG-SCALE*) 100) 0.01)))
  ;; 默认图层
  (or layer (setq layer (or (sys:get '*SYS:REBAR-LAYER*) "S_REBAR")))
  (lay:make layer 1)

  ;; === 处理起始端弯钩（方向与行进相反） ===
  (if (> hook-start 0)
    (progn
      (setq dir-ang (point:angle (car pts) (cadr pts))  ; 起始段方向
            D (car pts))                                  ; 弯弧起点 = 钢筋第一点
      (setq hook-geom (rebar:make-hook-geom D (+ dir-ang pi) hook-start hook-dir d grade))
      ;; hook-geom 是正向(bar→tail)的结果，起始钩需要反向：tail → C → D
      ;; 即：tail-end → C(bulge=-bulge) → D(bulge=0, 连接主筋)
      (if hook-geom
        (progn
          (setq tail-end (car (cadr hook-geom))            ; 尾端点
                C       (car (car  hook-geom))             ; 弧段终点
                bulge-C (- (cdr (car hook-geom))))         ; 反向 bulge
          ;; 预置到顶点列表
          (setq all-pts    (list tail-end C D)
                all-bulges (list 0.0 bulge-C 0.0))))))

  ;; === 主筋路径（跳过已用的第一点） ===
  (if all-pts
    ;; 从 D 之后的第 2 个点开始（D 已在列表中）
    (foreach pt (cdr pts)
      (setq all-pts    (append all-pts    (list pt))
            all-bulges (append all-bulges (list 0.0))))
    ;; 无起始钩：全部路径点
    (progn
      (setq all-pts    pts
            all-bulges (mapcar '(lambda (x) 0.0) pts))))

  ;; === 处理末端弯钩 ===
  (if (> hook-end 0)
    (progn
      (setq D (last all-pts)                               ; 主筋最后一点
            dir-ang (point:angle (nth (- (length all-pts) 2) all-pts) D))
      (setq hook-geom (rebar:make-hook-geom D dir-ang hook-end hook-dir d grade))
      (if hook-geom
        (progn
          ;; D 的 bulge = hook-dir * bulge（弧段从 D 到 C）
          (setq bulge-D (cdr (car  hook-geom))
                C       (car (car  hook-geom))
                tail-end (car (cadr hook-geom)))
          ;; 替换 D 的 bulge，追加 C 和 tail-end
          (setq all-bulges (reverse all-bulges)
                all-pts    (reverse all-pts))
          (setq all-bulges (cdr all-bulges)                     ; 去掉旧的 D bulge(0)
                all-bulges (cons bulge-D all-bulges))           ; 设 D 的 bulge
          (setq all-pts    (cdr all-pts)                        ; 去掉旧的 D
                all-pts    (cons D all-pts))                    ; 放回 D
          (setq all-pts    (cons C       all-pts)               ; 加 C
                all-bulges (cons 0.0     all-bulges))           ; C 的 bulge=0
          (setq all-pts    (cons tail-end all-pts)              ; 加 tail-end
                all-bulges (cons 0.0     all-bulges))           ; tail 的 bulge=0
          ;; 反转回来
          (setq all-pts    (reverse all-pts)
                all-bulges (reverse all-bulges))))))

  ;; === 创建多段线（带 bulge 值） ===
  (rebar:make-pline-with-bulges all-pts all-bulges nil width layer))


;; 创建带 bulge 的优化多段线。entmakex 实现。
;; pts: 顶点表  bulges: 每点 bulge 表（长度同 pts）
;; closed: T=闭合  width: 常量线宽  layer: 图层
(defun rebar:make-pline-with-bulges (pts bulges closed width layer)
  (entmakex
    (append
      (list '(0 . "LWPOLYLINE")
            '(100 . "AcDbEntity")
            '(100 . "AcDbPolyline")
            (cons 8 (if layer layer "0"))
            (cons 90 (length pts))
            (cons 70 (if closed 1 0))
            (cons 43 (if width width 0.5)))
      (apply 'append
        (mapcar '(lambda (pt bulge)
                  (list (cons 10 pt) (cons 42 bulge)))
                pts bulges)))))


;; ============================================================================
;; 钢筋查询
;; ============================================================================

(defun rebar:is-rebar? (ename)
  "判断是否为钢筋实体（等宽多段线，组码 43 > 0）。"
  (and (= (entity:get-type ename) "LWPOLYLINE")
       (> (entity:get-dxf ename 43) 0)))

(defun rebar:get-width (ename)
  "获取钢筋线宽。"
  (entity:get-dxf ename 43))

(defun rebar:set-width (ename w)
  "设置钢筋线宽。"
  (entity:set-dxf ename 43 w)
  (entity:update ename))

(defun rebar:get-vertices (ename)
  "获取钢筋所有顶点坐标表。"
  (curve:vertices ename))

(defun rebar:get-bulges (ename / elst bulges)
  "获取钢筋所有顶点 bulge 值表。"
  (setq elst (entget ename))
  (mapcar '(lambda (x) (cdr x))
    (vl-remove-if-not '(lambda (x) (= (car x) 42)) elst)))


;; ============================================================================
;; 弯钩检测与修改
;; ============================================================================

;; 检测钢筋指定端的弯钩类型。
;; end: 'start 或 'end。返回 0(无钩)/1(圆)/2(斜)/3(直)。
(defun rebar:detect-hook-end (ename end / pts bulges n b1 b2 b3)
  (setq pts    (rebar:get-vertices ename)
        bulges (rebar:get-bulges ename)
        n      (length pts))
  (if (< n 4) 0  ; n<4 时顶点不足以形成弯钩结构
    (if (eq end 'start)
      ;; 起始端：检查前 3 个顶点
      (setq b1 (nth 0 bulges)
            b2 (nth 1 bulges))
      (if (and (= b1 0) (not (zerop b2)))
        (rebar:bulge-to-hook-type (abs b2))
        0)
      ;; 末端：检查后 3 个顶点
      (setq b3 (nth (- n 3) bulges)
            b2 (nth (- n 2) bulges))
      (if (and (not (zerop b3)) (= b2 0))
        (rebar:bulge-to-hook-type (abs b3))
        0))))

(defun rebar:get-hook-sign (ename end / pts bulges n b)
  "获取钢筋指定端弯钩的方向符号。+1=左弯(CCW), -1=右弯(CW), 0=无钩。"
  (setq pts    (rebar:get-vertices ename)
        bulges (rebar:get-bulges ename)
        n      (length pts))
  (if (< n 3) 0
    (if (eq end 'start)
      (progn (setq b (nth 1 bulges))
             ;; 起始钩 bulge 取反存储，符号与真实 hook-dir 相反
             (if (and b (not (zerop b))) (if (> b 0) -1 1) 0))
      (progn (setq b (nth (- n 3) bulges))
             (if (and b (not (zerop b))) (if (> b 0) 1 -1) 0)))))

(defun rebar:bulge-to-hook-type (bulge-abs)
  "根据 bulge 绝对值反推弯钩类型。"
  (cond
    ((equal bulge-abs 1.0    0.01) 1)  ; 180°圆钩
    ((equal bulge-abs 0.6682 0.02) 2)  ; 135°斜钩
    ((equal bulge-abs 0.4142 0.02) 3)  ; 90°直钩
    (t 0)))


;; ============================================================================
;; 添加/删除弯钩
;; ============================================================================

(defun rebar:add-hook (ename end hook-type hook-dir d grade
                       / pts bulges n dir-ang D hook-geom C bulge-val tail-end
                         new-pts new-bulges closed? w lay)
  ;; 在已有钢筋指定端添加弯钩。
  ;; end: 'start 或 'end。若该端已有弯钩则先删除再添加。
  ;; 先删除已有弯钩
  (if (> (rebar:detect-hook-end ename end) 0)
    (setq ename (rebar:remove-hook ename end)))
  (if (= hook-type 0) ename  ; 不添加

    (progn
      (setq pts    (rebar:get-vertices ename)
            bulges (rebar:get-bulges ename)
            n      (length pts))

      (if (eq end 'start)
        (progn
          ;; 起始端：方向从第2点指向第1点（反向）
          (setq D       (car pts)
                dir-ang (point:angle (cadr pts) D))
          (setq hook-geom (rebar:make-hook-geom D dir-ang hook-type hook-dir d grade))
          (if hook-geom
            (progn
              (setq C        (car (car  hook-geom))
                    bulge-val (- (cdr (car hook-geom)))  ; 反向 bulge
                    tail-end  (car (cadr hook-geom)))
              (setq new-pts    (list tail-end C D))
              (setq new-bulges (list 0.0 bulge-val 0.0))
              ;; 追加原钢筋其余顶点
              (foreach pt (cdr pts)    (setq new-pts (append new-pts (list pt))))
              (foreach b  (cdr bulges) (setq new-bulges (append new-bulges (list b)))))))

        ;; 末端
        (progn
          (setq D       (last pts)
                dir-ang (point:angle (nth (- n 2) pts) D))
          (setq hook-geom (rebar:make-hook-geom D dir-ang hook-type hook-dir d grade))
          (if hook-geom
            (progn
              (setq bulge-val (cdr (car  hook-geom))
                    C         (car (car  hook-geom))
                    tail-end  (car (cadr hook-geom)))
              ;; 复制前 n-1 个点不变，最后一个(D)设 bulge，加 C 和 tail
              (setq new-pts    (reverse pts)
                    new-bulges (reverse bulges))
              (setq new-pts    (cdr new-pts)              ; 去掉 D
                    new-bulges (cdr new-bulges))
              (setq new-pts    (cons D new-pts)            ; 放回 D (作 arc-start)
                    new-bulges (cons bulge-val new-bulges)) ; D 的 bulge
              (setq new-pts    (cons C new-pts)            ; C (arc-end)
                    new-bulges (cons 0.0 new-bulges))
              (setq new-pts    (cons tail-end new-pts)     ; tail
                    new-bulges (cons 0.0 new-bulges))
              (setq new-pts    (reverse new-pts)
                    new-bulges (reverse new-bulges))))))

      ;; 重建多段线（先读取属性，再删除旧实体）
      (if new-pts
        (progn
          (setq closed? (curve:closed? ename)
                w       (rebar:get-width ename)
                lay     (entity:get-layer ename))
          (entdel ename)
          (rebar:make-pline-with-bulges new-pts new-bulges closed? w lay))
        ename))))


(defun rebar:remove-hook (ename end / pts bulges n new-pts new-bulges closed? w lay)
  "移除钢筋指定端的弯钩（恢复为无钩直段）。"
  (setq pts    (rebar:get-vertices ename)
        bulges (rebar:get-bulges ename)
        n      (length pts))
  (if (< n 4) ename  ; 至少4个点才有弯钩可删
    (progn
      (if (eq end 'start)
        ;; 起始钩：去掉前2个（tail-end 和 C），保留 D
        (progn
          (setq new-pts    (cddr pts))
          (setq new-bulges (cddr bulges))
          ;; 重置暴露的 D 顶点 bulge=0（原为 hook bulge）
          (if new-bulges
            (setq new-bulges (cons 0.0 (cdr new-bulges)))))
        ;; 末端钩：去掉后2个（C 和 tail-end），保留 D
        (progn
          (setq new-pts    (reverse (cddr (reverse pts)))
                new-bulges (reverse (cddr (reverse bulges))))
          ;; 重置暴露的 D 顶点 bulge=0
          (if new-bulges
            (setq new-bulges (reverse (cons 0.0 (cdr (reverse new-bulges))))))))
      ;; 重建（先读取属性，再删除旧实体）
      (setq closed? (curve:closed? ename)
            w       (rebar:get-width ename)
            lay     (entity:get-layer ename))
      (entdel ename)
      (rebar:make-pline-with-bulges new-pts new-bulges closed? w lay))))


;; ============================================================================
;; 箍筋创建
;; ============================================================================

(defun rebar:make-stirrup (p1 p3 hook-type d grade hook-dir width layer
                           / p2 p4 cover R inner-pts pts bulges
                             dir-ang-0 dir-ang-2 hook-geom-0 hook-geom-2
                             C0 bulge0 tail0 C2 bulge2 tail2)
  ;; 创建矩形箍筋（带弯钩在矩形对角两端）。
  ;; p1: 左下角点  p3: 右上角点
  ;; hook-type: 弯钩类型  d: 直径  grade: 等级
  (or width (setq width (* d (or (sys:get '*SYS:DWG-SCALE*) 100) 0.01)))
  (or layer (setq layer (or (sys:get '*SYS:STIRRUP-LAYER*) "S_STIRRUP")))
  (lay:make layer 4)  ; 青色

  ;; 矩形四角（逆时针）
  (setq p2 (list (car p1) (cadr p3) 0.0)   ; 左上
        p4 (list (car p3) (cadr p1) 0.0))  ; 右下
  ;; 钢筋内缘（减去保护层 + 半径）
  (setq cover (or (sys:get '*SYS:REBAR-COVER*) 25)
        d     (or d 8)
        R     (rebar:bend-radius d grade))
  ;; 箍筋尺寸内收保护层+弯曲半径
  (setq p1 (list (+ (car p1) cover R) (+ (cadr p1) cover R) 0.0)
        p2 (list (+ (car p2) cover R) (- (cadr p2) cover R) 0.0)
        p3 (list (- (car p3) cover R) (- (cadr p3) cover R) 0.0)
        p4 (list (- (car p4) cover R) (+ (cadr p4) cover R) 0.0))

  ;; 箍筋路径：p1 → p2 → p3 → p4 → 回到 p1
  ;; 弯钩放在 p1→p2 段和 p3→p4 段（对角线两端）
  ;; 简化：弯钩放在起始段 (p1) 和 p3 处

  ;; 主筋路径（闭合矩形，去掉 p1 重复）
  (setq inner-pts (list p1 p2 p3 p4))

  ;; 计算 p1 处的弯钩（方向从 p1 → p2）
  (setq dir-ang-0  (point:angle p1 p2)
        hook-geom-0 (rebar:make-hook-geom p1 dir-ang-0 hook-type hook-dir d grade))
  ;; 计算 p3 处的弯钩（方向从 p3 → p4）
  (setq dir-ang-2  (point:angle p3 p4)
        hook-geom-2 (rebar:make-hook-geom p3 dir-ang-2 hook-type hook-dir d grade))

  (if (and hook-geom-0 hook-geom-2)
    (progn
      (setq C0      (car (car  hook-geom-0))
            bulge0   (cdr (car  hook-geom-0))
            tail0    (car (cadr hook-geom-0))
            C2      (car (car  hook-geom-2))
            bulge2   (cdr (car  hook-geom-2))
            tail2    (car (cadr hook-geom-2)))

      ;; 顶点序列：tail0 → C0(弧) → p1 → p2 → p3 → C2(弧) → tail2 → p3(回角) → p4 → p1 → 闭合
      ;; tail2→p3 回到角点再连 p4，确保箍筋底边沿 p3→p4 方向（而非斜穿）
      ;; 闭合标志用 nil：显式边 p4→p1 已闭合矩形。
      ;; T 会导致自动闭合段 p1→tail0 穿过起始弯钩区域。
      (setq pts    (list tail0 C0 p1 p2 p3 C2 tail2 p3 p4 p1))
      (setq bulges (list 0.0 (- bulge0) 0.0 0.0 bulge2 0.0 0.0 0.0 0.0 0.0))

      (rebar:make-pline-with-bulges pts bulges nil width layer))
    ;; 无钩简化：纯矩形
    (entity:make-pline (list p1 p2 p3 p4) T layer)))


(defun rebar:make-poly-stirrup (boundary-pts hook-type d grade hook-dir width layer
                                / inner-pts p0 p1 dir-ang hook-geom C bulge-val tail all-pts all-bulges)
  ;; 创建多边形箍筋（沿给定边界）。
  ;; boundary-pts: 箍筋路径点表（闭合多边形顶点）。
  (or width (setq width (* d (or (sys:get '*SYS:DWG-SCALE*) 100) 0.01)))
  (or layer (setq layer (or (sys:get '*SYS:STIRRUP-LAYER*) "S_STIRRUP")))
  (lay:make layer 4)

  (if (or (null boundary-pts) (< (length boundary-pts) 3))
    (princ "\n[TB] 箍筋边界点不足（至少需要2个点）。")
    ;; 简化版：直接以边界点为路径创建闭合多段线
    ;; 弯钩放在起点
    (if (> hook-type 0)
    (progn
      (setq p0 (car boundary-pts)
            p1 (cadr boundary-pts)
            dir-ang (point:angle p0 p1)
            hook-geom (rebar:make-hook-geom p0 dir-ang hook-type hook-dir d grade)
            C (car (car hook-geom))
            bulge-val (- (cdr (car hook-geom)))
            tail (car (cadr hook-geom))
            all-pts (append (list tail C p0) (cdr boundary-pts) (list p0))
            all-bulges (append (list 0.0 bulge-val 0.0)
                        (mapcar '(lambda (x) 0.0) (cdr boundary-pts))
                        '(0.0)))
      (rebar:make-pline-with-bulges all-pts all-bulges T width layer))
    (entity:make-pline boundary-pts T layer))))


(princ "\n[TB] 钢筋几何库加载完成 (rebar:*)")
(princ)
