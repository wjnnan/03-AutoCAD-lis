;;; tb-lib-struct.lsp — 结构设计参数库
;;; 吸收自 @lisp at-structure 包（VitalGG，GB50010-2010 规范公式）
;;; 提供：混凝土强度参数查询(concrete:*)、抗震参数查询(seismic:*)
;;; 纯函数零依赖，命令入口 c:FCK / c:SEIS

;; ============================================================================
;; 混凝土强度参数（GB50010-2010）
;; ============================================================================

(defun concrete:fck (level / ac1 ac2)
  "混凝土轴心抗压强度标准值 fck。level=混凝土强度等级 C15~C80。"
  (setq ac1 (cond ((<= level 50) 0.76)
                  ((>= level 80) 0.82)
                  (t (+ 0.76 (* (- 0.82 0.76) (/ (- level 50.0) 30.0)))))
        ac2 (cond ((<= level 40) 1.0)
                  ((>= level 80) 0.87)
                  (t (+ 1.0 (* (- 0.87 1.0) (/ (- level 40.0) 40.0))))))
  (* 0.88 ac1 ac2 level))

(defun concrete:ftk (level / fcuk ftk i n)
  "混凝土轴心抗拉强度标准值 ftk（非标准等级线性插值）。"
  (setq fcuk '(15 20 25 30 35 40 45 50 55 60 65 70 75 80 100)
        ftk  '(1.27 1.54 1.78 2.01 2.20 2.39 2.51 2.64 2.74 2.85 2.93 2.99 3.05 3.11 4.0)
        n    (length fcuk)
        i    0)
  (while (and (< i n) (>= level (nth i fcuk)))
    (setq i (1+ i)))
  (cond
    ((<= i 0) (car ftk))
    ((>= i n) (last ftk))
    (t (+ (nth (1- i) ftk)
          (* (- (nth i ftk) (nth (1- i) ftk))
             (/ (float (- level (nth (1- i) fcuk)))
                (float (- (nth i fcuk) (nth (1- i) fcuk)))))))))

(defun concrete:fc (level)
  "混凝土轴心抗压强度设计值 fc。"
  (/ (concrete:fck level) 1.4))

(defun concrete:ft (level)
  "混凝土轴心抗拉强度设计值 ft。"
  (/ (concrete:ftk level) 1.4))

(defun concrete:ec (level)
  "混凝土弹性模量 Ec。"
  (/ 1e5 (+ 2.2 (/ 34.7 level))))

(defun concrete:Gc (level)
  "混凝土剪变模量 Gc。"
  (* 0.4 (concrete:ec level)))

;; ============================================================================
;; 抗震参数（GB50011-2010）
;; ============================================================================

(defun seismic:period-of-ground-motion (group-of-seismic category-of-site / table)
  "地震特征周期 Tg。group=设计地震分组(1/2/3)，category=场地类别(0~4 对应 I0~IV)。"
  (setq table '((0.20 0.25 0.35 0.45 0.65)
                (0.25 0.30 0.40 0.55 0.75)
                (0.30 0.35 0.45 0.65 0.90)))
  (if (and (<= 1 group-of-seismic 3)
           (<= 0 category-of-site 4))
    (nth category-of-site (nth (1- group-of-seismic) table))
    nil))

(defun seismic:amax (liedu duoyu-or-hanyu / table)
  "水平地震影响系数最大值 amax。liedu=设防烈度(6/7/7.5/8/8.5/9)，duoyu=T多遇 nil罕遇。"
  (setq table '((0.04 0.08 0.12 0.16 0.24 0.32)
                (0.28 0.50 0.72 0.90 1.20 1.40)))
  (nth (vl-position liedu '(6 7 7.500 8 8.500 9))
       (if duoyu-or-hanyu (car table) (cadr table))))

(defun seismic:gap-of-seismic (liedu type-of-stru height / table)
  "防震缝宽度。liedu=烈度，type-of-stru=结构类型，height=建筑物高度(m)。"
  (setq table '(("框架结构" . 1.0)
                ("框架-剪力墙结构" . 0.7)
                ("剪力墙结构" . 0.5)))
  (if (cdr (assoc type-of-stru table))
    (max 100.0
         (* (cdr (assoc type-of-stru table))
            (+ 100 (* 20 (/ (float (- height 15)) (float (- 11.0 liedu)))))))
    1000.0))

;; ============================================================================
;; 命令入口
;; ============================================================================

(defun c:FCK (/ level)
  "查询混凝土强度参数。"
  (setq level (getint "\n混凝土强度等级 C15~C80 <30>: "))
  (if (not level) (setq level 30))
  (if (and (>= level 15) (<= level 100))
    (progn
      (princ (strcat "\n混凝土 C" (itoa level) " 强度参数:"))
      (princ (strcat "\n  轴心抗压强度标准值 fck = " (rtos (concrete:fck level) 2 2) " N/mm^2"))
      (princ (strcat "\n  轴心抗拉强度标准值 ftk = " (rtos (concrete:ftk level) 2 2) " N/mm^2"))
      (princ (strcat "\n  轴心抗压强度设计值 fc  = " (rtos (concrete:fc level) 2 2) " N/mm^2"))
      (princ (strcat "\n  轴心抗拉强度设计值 ft  = " (rtos (concrete:ft level) 2 2) " N/mm^2"))
      (princ (strcat "\n  弹性模量 Ec = " (rtos (concrete:ec level) 2 0) " N/mm^2"))
      (princ (strcat "\n  剪变模量 Gc = " (rtos (concrete:Gc level) 2 0) " N/mm^2")))
    (princ "\n[TB] 混凝土等级须在 C15~C100 之间。"))
  (princ))

(defun c:SEIS (/ key level res)
  "查询抗震参数。"
  (initget "T A G")
  (setq key (getkword "\n抗震参数 [特征周期(T)/影响系数(A)/防震缝(G)] <T>: "))
  (if (not key) (setq key "T"))
  (cond
    ((= key "T")
     (initget "1 2 3")
     (setq level (getint "\n设计地震分组 [1/2/3] <2>: "))
     (if (not level) (setq level 2))
     (initget "0 1 2 3 4")
     (setq res (getint "\n场地类别 [0=I0/1=I1/2=II/3=III/4=IV] <2>: "))
     (if (not res) (setq res 2))
     (if (and level res)
       (princ (strcat "\n地震特征周期 Tg = "
                      (rtos (seismic:period-of-ground-motion level res) 2 2) " s"))))
    ((= key "A")
     (initget 4)
     (setq level (getreal "\n设防烈度 [6/7/7.5/8/8.5/9] <7>: "))
     (if (not level) (setq level 7.0))
     (initget "D H")
     (setq res (getkword "\n[多遇(D)/罕遇(H)] <D>: "))
     (if (not res) (setq res "D"))
     (if (and level (member res '("D" "H")))
       (princ (strcat "\n水平地震影响系数最大值 amax = "
                      (rtos (seismic:amax level (= res "D")) 2 2)))))
    ((= key "G")
     (initget "6 7 8 9")
     (setq level (getint "\n设防烈度 [6/7/8/9] <7>: "))
     (if (not level) (setq level 7))
     (initget "K KJ J")
     (setq res (getkword "\n结构类型 [框架(K)/框剪(KJ)/剪力墙(J)] <K>: "))
     (if (not res) (setq res "K"))
     (setq res (cond ((= res "K") "框架结构")
                     ((= res "KJ") "框架-剪力墙结构")
                     (t "剪力墙结构")))
     (princ (strcat "\n防震缝宽度 = "
                    (rtos (seismic:gap-of-seismic level res (getreal "\n建筑物高度(m): ")) 2 0) " mm"))))
  (princ))

;; ============================================================================
;; 截面几何特性（region + ActiveX，吸收自 cadtutor 论坛截面惯性矩功能）
;; ============================================================================

;; ============================================================================
;; 截面几何特性（纯算法，吸收自明经论坛 zml84 的 ZML-JM）
;; ============================================================================

(defun section:props (pts / ax sx ix ay sy iy p0 x0 y0 x1 y1 dx dy
                           ra rb ya yb ia ib cx cy icx icy lx ly
                           maxx maxy minx miny top bot left right)
  "截面几何特性（纯算法）。pts=截面轮廓顶点表。返回面积/形心/静矩/惯性矩/边缘距离。"
  ;; 第一部分：面积、静矩、惯性矩（矩形+三角形分解，格林公式）
  (setq ax 0 ay 0 sx 0 sy 0 ix 0 iy 0)
  (setq p0 (last pts))
  (foreach p pts
    (setq x0 (car p0) y0 (cadr p0) x1 (car p) y1 (cadr p))
    (setq dx (- x1 x0) dy (- y1 y0))
    ;; 对X轴：a为矩形，b为三角形
    (setq ra (* dx y0)
          ya (* 0.5 y0)
          ia (* (/ 1.0 12) dx y0 y0 y0)
          ia (+ ia (* ra ya ya)))
    (setq rb (* 0.5 dx dy)
          yb (+ y0 (/ dy 3.0))
          ib (* (/ 1.0 36) dx dy dy dy)
          ib (+ ib (* rb yb yb)))
    (setq ax (+ ax ra rb)
          sx (+ sx (* ra ya) (* rb yb))
          ix (+ ix ia ib))
    ;; 对Y轴
    (setq ra (* dy x0)
          ya (* 0.5 x0)
          ia (* (/ 1.0 12) dy x0 x0 x0)
          ia (+ ia (* ra ya ya)))
    (setq rb (* 0.5 dy dx)
          yb (+ x0 (/ dx 3.0))
          ib (* (/ 1.0 36) dy dx dx dx)
          ib (+ ib (* rb yb yb)))
    (setq ay (+ ay ra rb)
          sy (+ sy (* ra ya) (* rb yb))
          iy (+ iy ia ib))
    (setq p0 p))
  ;; 形心位置
  (setq cx (/ sy ay)
        cy (/ sx ax))
  ;; 对形心惯性矩（平行轴定理）
  (setq icx (- ix (* ax cy cy))
        icy (- iy (* ay cx cx)))
  ;; 第二部分：截面边缘位置
  (setq lx '() ly '())
  (foreach p pts
    (setq lx (cons (car p) lx)
          ly (cons (cadr p) ly)))
  (setq maxy (apply 'max ly) miny (apply 'min ly)
        maxx (apply 'max lx) minx (apply 'min lx))
  (setq top (- maxy cy) bot (- cy miny)
        right (- maxx cx) left (- cx minx))
  ;; 第三部分：返回结果
  (list (cons "面积" ay)
        (cons "形心" (list cx cy))
        (cons "形心至上" top)
        (cons "形心至下" bot)
        (cons "形心至左" left)
        (cons "形心至右" right)
        (cons "对X轴静矩" (- sx))
        (cons "对Y轴静矩" sy)
        (cons "对X轴惯性矩" (- ix))
        (cons "对Y轴惯性矩" iy)
        (cons "对形心X轴惯性矩" (- icx))
        (cons "对形心Y轴惯性矩" icy)))

(defun c:SECT (/ ss ent pts res area cent icx icy top bot left right wx wy)
  "查询截面几何特性（纯算法，支持挖孔截面轮廓）。选闭合多段线。"
  (setq ss (ssget '((0 . "LWPOLYLINE"))))
  (if (not ss)
    (princ "\n[TB] 未选择闭合多段线。")
    (progn
      (setq ent (ssname ss 0))
      (if (not (curve:closed? ent))
        (princ "\n[TB] 所选多段线未闭合，请先闭合。")
        (progn
          (setq pts (curve:vertices ent)
                res (section:props pts))
          (setq area (cdr (assoc "面积" res))
                cent (cdr (assoc "形心" res))
                icx  (abs (cdr (assoc "对形心X轴惯性矩" res)))
                icy  (abs (cdr (assoc "对形心Y轴惯性矩" res)))
                top  (cdr (assoc "形心至上" res))
                bot  (cdr (assoc "形心至下" res))
                left (cdr (assoc "形心至左" res))
                right (cdr (assoc "形心至右" res)))
          ;; 抵抗矩 W = I / y_max
          (setq wx (if (> top bot) (/ icx top) (/ icx bot))
                wy (if (> left right) (/ icy left) (/ icy right)))
          (princ "\n══════ 截面几何特性 ══════")
          (princ (strcat "\n  面积 A    = " (rtos area 2 2) " mm^2"))
          (princ (strcat "\n  形心 C    = (" (rtos (car cent) 2 2) ", " (rtos (cadr cent) 2 2) ")"))
          (princ (strcat "\n  惯性矩 Ix = " (rtos icx 2 0) " mm^4"))
          (princ (strcat "\n  惯性矩 Iy = " (rtos icy 2 0) " mm^4"))
          (princ (strcat "\n  抵抗矩 Wx = " (rtos wx 2 0) " mm^3"))
          (princ (strcat "\n  抵抗矩 Wy = " (rtos wy 2 0) " mm^3"))
          (princ "\n──────────────────────────")
          (princ "\n  (惯性矩/抵抗矩为对形心主轴)")))))
  (princ))



(princ "\n[TB] 结构参数库加载完成 (concrete:* / seismic:* / section:* / c:FCK / c:SEIS / c:SECT)")
(princ)
