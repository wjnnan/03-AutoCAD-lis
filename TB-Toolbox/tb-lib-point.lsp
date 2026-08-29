;;; tb-lib-point.lsp — 点操作库
;;; 所有点运算的统一入口。其他模块中不再重复实现取中点、求距离等基础操作。
;;; 依赖：tb-core.lsp（需先加载）

;; ============================================================================
;; 创建与转换
;; ============================================================================

(defun point:create (x y z)
  "创建三维点。z 可省略，默认为 0.0。"
  (list x y (if z z 0.0)))

(defun point:2d (pt)
  "三维点转为二维（去掉 Z 坐标）。"
  (list (car pt) (cadr pt)))

(defun point:3d (pt z)
  "二维点转为三维，z 默认为 0.0。"
  (point:create (car pt) (cadr pt) z))


;; ============================================================================
;; 基本计算
;; ============================================================================

(defun point:mid (pt1 pt2)
  "求两点中点。所有需要中点的地方统一调用此函数。"
  (mapcar '(lambda (a b) (* 0.5 (+ a b))) pt1 pt2))

(defun point:polar (pt ang dist)
  "从 pt 出发，沿 ang 方向，距离 dist 的点。
等价于内置 polar 函数，提供一致的命名空间。"
  (polar pt ang dist))

(defun point:dist (pt1 pt2)
  "两点间距离。"
  (distance pt1 pt2))

(defun point:angle (pt1 pt2)
  "从 pt1 指向 pt2 的角度（弧度）。"
  (angle pt1 pt2))

(defun point:offset (pt dx dy)
  "点偏移。返回 (x+dx, y+dy, z)。2D 点时 z 默认为 0.0。"
  (list (+ (car pt) dx) (+ (cadr pt) dy) (if (caddr pt) (caddr pt) 0.0)))


;; ============================================================================
;; 几何判断
;; ============================================================================

(defun point:between? (pt pt1 pt2 / d d1 d2)
  "判断 pt 是否在线段 pt1-pt2 上（含端点）。
使用距离法：d1 + d2 ≈ d 即在线段上。"
  (setq d  (point:dist pt1 pt2)
        d1 (point:dist pt1 pt)
        d2 (point:dist pt2 pt))
  (equal d (+ d1 d2) 0.001))

(defun point:in-polygon? (pt pts)
  "判断点是否在多边形内（射线法）。
pts 为顶点表，自动处理闭合。"
  (equal pi
    (abs (apply '+
      (mapcar '(lambda (a b)
        (rem (- (angle pt a) (angle pt b)) pi))
        (reverse (cdr (reverse (cons (last pts) pts))))
        pts)))
    0.00001))


;; ============================================================================
;; 集合运算
;; ============================================================================

(defun point:bbox (pts)
  "计算点集的包围盒。返回 (最小点 最大点)，空点集返回 nil。"
  (if pts
    (list
      (list (apply 'min (mapcar 'car pts))
            (apply 'min (mapcar 'cadr pts))
            0.0)
      (list (apply 'max (mapcar 'car pts))
            (apply 'max (mapcar 'cadr pts))
            0.0))
    nil))

(defun point:center (pts)
  "求点集的几何中心（各分量平均值）。空点集返回 nil。"
  (if pts
    (list
      (/ (float (apply '+ (mapcar 'car pts)))   (length pts))
      (/ (float (apply '+ (mapcar 'cadr pts)))  (length pts))
      0.0)
    nil))

(defun point:sort (pts mode)
  "点集排序。mode = 'X 按 X 升序，'Y 按 Y 升序，'XY 先 Y 后 X。
vl-sort 可能破坏原表且去重，先 copy 确保安全。"
  (setq pts (append pts nil))  ; 复制列表防止破坏原表
  (cond
    ((eq mode 'X)  (vl-sort pts '(lambda (a b) (< (car a)  (car b)))))
    ((eq mode 'Y)  (vl-sort pts '(lambda (a b) (< (cadr a) (cadr b)))))
    ((eq mode 'XY) (vl-sort pts
                     '(lambda (a b)
                        (if (equal (cadr a) (cadr b) 0.01)
                          (< (car a) (car b))
                          (< (cadr a) (cadr b))))))
    (t pts)))

(defun point:nearest (pt pts)
  "在点集中找到离 pt 最近的点。copy 后排序防止破坏原表。"
  (car (vl-sort (append pts nil)
         '(lambda (a b) (< (point:dist pt a) (point:dist pt b))))))


;; ============================================================================
;; 四边形相关
;; ============================================================================

(defun point:rect-2pt->4pt (p1 p3 / pts pmin pmax)
  "由矩形对角两点 p1、p3 推出四个角点（左下、右下、右上、左上）。
返回两个点：先对 p1/p3 排序保证 (minx miny) (maxx maxy)，再生成四个角点。"
  (setq pts (point:sort (list p1 p3) 'X)
        pmin nil pmax nil)
    (setq pmin (car pts) pmax (cadr pts))
    (list pmin
          (list (car pmax) (cadr pmin) 0.0)  ; 右下
          pmax                                 ; 右上
          (list (car pmin) (cadr pmax) 0.0))) ; 左上

(defun point:rect-pts (p1 p3)
  "由对角两点返回矩形四个角点。与 point:rect-2pt->4pt 相同，为命名一致保留。"
  (point:rect-2pt->4pt p1 p3))


(princ "\n[TB] 点操作库加载完成 (point:*)")
(princ)
