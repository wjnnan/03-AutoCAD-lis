;;; tb-lib-curve.lsp — 曲线操作库
;;; 统一封装 vlax-curve-* 系列函数。vlax-curve-* 在三个平台均可用。
;;; 依赖：tb-core.lsp, tb-lib-point.lsp（需先加载）

;; ============================================================================
;; 属性查询
;; ============================================================================

(defun curve:length (ename)
  "获取曲线长度。支持 LINE、ARC、CIRCLE、*POLYLINE、SPLINE 等。"
  (vlax-curve-getdistatparam ename (vlax-curve-getendparam ename)))

(defun curve:area (ename / obj)
  "获取曲线面积。仅对闭合多段线/圆/椭圆有意义。
AutoCAD/GStarCAD 先检查面积属性；ZWCAD 无 COM 则直接调 vlax-curve-getarea。"
  (if (null ename) 0.0
    (if *SYS:HAS-ACTIVEX*
    (progn
      (setq obj (vl-catch-all-apply 'vlax-ename->vla-object (list ename)))
      (if (and (not (vl-catch-all-error-p obj))
               (vlax-property-available-p obj 'area))
        (vla-get-area obj)
        0.0))
    (or (vlax-curve-getarea ename) 0.0))))

(defun curve:startpt (ename)
  "获取曲线起点。"
  (vlax-curve-getstartpoint ename))

(defun curve:endpt (ename)
  "获取曲线终点。"
  (vlax-curve-getendpoint ename))

(defun curve:midpt (ename)
  "获取曲线中点（按参数中点计算，非几何中点）。"
  (vlax-curve-getpointatdist ename
    (* 0.5 (curve:length ename))))


;; ============================================================================
;; 参数与点互转
;; ============================================================================

(defun curve:param-at-pt (ename pt)
  "获取曲线上点 pt 对应的参数值。pt 应尽可能在曲线上。"
  (vlax-curve-getparamatpoint ename pt))

(defun curve:pt-at-param (ename param)
  "根据参数值获取曲线上对应点。"
  (vlax-curve-getpointatparam ename param))

(defun curve:pt-at-dist (ename dist)
  "获取曲线上距起点指定距离的点。"
  (vlax-curve-getpointatdist ename dist))


;; ============================================================================
;; 几何计算
;; ============================================================================

(defun curve:closest-pt (ename pt)
  "求曲线上离 pt 最近的点。"
  (vlax-curve-getclosestpointto ename pt))

(defun curve:tangent (ename pt)
  "获取曲线上 pt 处的切线方向角（弧度）。"
  (angle '(0 0 0)
    (vlax-curve-getfirstderiv ename
      (vlax-curve-getparamatpoint ename
        (curve:closest-pt ename pt)))))


;; ============================================================================
;; 判断
;; ============================================================================

(defun curve:closed? (ename)
  "判断曲线是否闭合。"
  (vlax-curve-isclosed ename))

(defun curve:clockwise? (pts / sum)
  "判断点集方向。T = 顺时针，nil = 逆时针。
使用叉积法（Shoelace 公式变体）。"
  (setq sum 0.0)
    (mapcar '(lambda (a b)
              (setq sum (+ sum (* (- (car b) (car a)) (+ (cadr b) (cadr a))))))
      pts
      (append (cdr pts) (list (car pts))))
    (> sum 0.0))


;; ============================================================================
;; 顶点操作
;; ============================================================================

(defun curve:vertices (ename / typ obj pts n)
  "获取曲线的所有顶点。返回点表。
LWPOLYLINE: 从 DXF 组码 10 读取（最快）。
POLYLINE: 遍历子实体。
其他曲线: 取起点终点。"
  (if (null ename)
    nil
    (progn
      (setq typ (cdr (assoc 0 (setq obj (entget ename)))))
      (if (null typ)
        nil
        (cond
          ;; 优化多段线：直接从 DXF 读取
    ((= typ "LWPOLYLINE")
     (setq pts nil
           obj (entget ename))
     (foreach pair obj
       (if (= (car pair) 10)
         (setq pts (append pts (list (cdr pair))))))
     pts)
    ;; 传统多段线：遍历子图元
    ((= typ "POLYLINE")
     (setq pts nil
           n  ename)
     (while (and (setq n (entnext n))
                 (= (cdr (assoc 0 (entget n))) "VERTEX"))
       (if (not (member (cdr (assoc 70 (entget n))) '(16 64)))
         (setq pts (append pts
           (list (cdr (assoc 10 (entget n))))))))
     pts)
    ;; 其他曲线：起点+终点
    (t (list (curve:startpt ename) (curve:endpt ename))))))))


;; ============================================================================
;; 线段相交（纯 Lisp，不依赖 ActiveX）
;; ============================================================================

(defun curve:inters-lines (p1 p2 p3 p4)
  "计算两条线段 p1-p2 和 p3-p4 的交点。
onseg=T 确保交点必须在线段上（非无限延长线）。"
  (inters p1 p2 p3 p4 T))


(princ "\n[TB] 曲线操作库加载完成 (curve:*)")
(princ)
