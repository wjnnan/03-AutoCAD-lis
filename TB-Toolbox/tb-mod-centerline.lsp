;;; tb-mod-centerline.lsp — 智能中心线模块
;;; 自动识别几何关系，绘制中心线。
;;; 支持：单线、双平行线、十字线、L型、圆、弧、矩形
;;; 组合 point:* curve:* entity:* lay:* 库函数

;; 中心线图层和样式
(setq *TB:CL-LAYER* "CENTER"
      *TB:CL-COLOR* 1
      *TB:CL-EXTEND* 500)  ; 中心线出头长度

;; ============================================================================
;; 核心算法：两点间创建中心线
;; ============================================================================

(defun cl:make-line (pt1 pt2 / ang ext)
  "在 pt1-pt2 基础上向外延伸 *TB:CL-EXTEND* 的中心线。"
  (setq ang (point:angle pt1 pt2)
        ext *TB:CL-EXTEND*)
  (entity:make-line
    (point:polar pt1 (+ ang pi) ext)
    (point:polar pt2 ang ext)
    *TB:CL-LAYER*))

;; ============================================================================
;; 主命令 c:ce
;; ============================================================================

(defun c:ce (/ ss e1 e2 cl-enames e1p1 e1p2 e2p1 e2p2 lst cl temp)
  "智能中心线。选择实体自动识别类型并绘制中心线。
支持：LINE, LWPOLYLINE, CIRCLE, ARC, ELLIPSE。
选择两条平行直线 → 绘制中间对称轴。
选择圆形 → 绘制十字中心线。"

  ;; 先加载 CENTER 线型（平台自适应线型文件），再创建图层
  (if (not (tblsearch "LTYPE" "CENTER"))
    (uc:command-safe
      (list "_.LINETYPE" "_L" "CENTER"
        (cond
          ((findfile "acad.lin")  "acad.lin")
          ((findfile "zwcad.lin") "zwcad.lin")
          ((findfile "gcad.lin")  "gcad.lin")
          (t ""))
        "")))
  (lay:make *TB:CL-LAYER* *TB:CL-COLOR* "CENTER")

  (if (setq ss (ssget '((0 . "LINE,LWPOLYLINE,CIRCLE,ARC,ELLIPSE"))))
    (progn
      ;; 根据选择数量判断几何类型
      (cond
        ;; 选择2条——求中心对称轴
        ((= (sel:count ss) 2)
         (setq lst (sel:to-list ss)
               e1  (car lst)
               e2  (cadr lst))
         (if (and (= (entity:get-type e1) "LINE")
                  (= (entity:get-type e2) "LINE"))
           ;; 两条直线 → 中心对称轴
           (progn
             (setq e1p1 (curve:startpt e1) e1p2 (curve:endpt e1)
                   e2p1 (curve:startpt e2) e2p2 (curve:endpt e2))
             ;; 检测两直线方向：若 e2 终点更靠近 e1 起点（反向绘制），交换 e2 端点
             (if (< (+ (point:dist e1p1 e2p2) (point:dist e1p2 e2p1))
                    (+ (point:dist e1p1 e2p1) (point:dist e1p2 e2p2)))
               (setq temp e2p1  e2p1 e2p2  e2p2 temp))
             (cl:make-line
               (point:mid e1p1 e2p1)
               (point:mid e1p2 e2p2))))
           ;; 非两条直线的情况
           (progn
             (setq cl-enames (list))
             (foreach e lst
               (foreach ename (cl:entity-centerline e)
                 (if ename (setq cl-enames (cons ename cl-enames))))))))

        ;; 选择1个或更多——逐个处理
        (t
         (sel:for-each ss
           '(lambda (e)
              (cl:entity-centerline e))))))
    (princ "\n未选择有效实体。"))
  (princ)


;; ============================================================================
;; 单实体中心线生成
;; ============================================================================

(defun cl:entity-centerline (ename / typ p1 p2 center r d ang1 ang2 mid-ang mid-pt pts)
  "根据实体类型生成中心线。"
  (setq typ (entity:get-type ename))
  (cond
    ((= typ "LINE")
     (setq p1 (curve:startpt ename)
           p2 (curve:endpt ename))
     (list (cl:make-line p1 p2)))

    ((= typ "CIRCLE")
     (setq center (entity:get-dxf ename 10)
           r      (entity:get-dxf ename 40)
           d      (+ r *TB:CL-EXTEND*))
     ;; 十字中心线
     (list
       (entity:make-line (list (- (car center) d) (cadr center) (caddr center))
                         (list (+ (car center) d) (cadr center) (caddr center)) *TB:CL-LAYER*)
       (entity:make-line (list (car center) (- (cadr center) d) (caddr center))
                         (list (car center) (+ (cadr center) d) (caddr center)) *TB:CL-LAYER*)))

    ((= typ "ARC")
     (setq center (entity:get-dxf ename 10)
           r      (entity:get-dxf ename 40)
           ang1   (entity:get-dxf ename 50)
           ang2   (entity:get-dxf ename 51))
     ;; 处理弧跨越 0° 方向的情况（ang2 < ang1）
     (if (< ang2 ang1) (setq ang2 (+ ang2 (* 2 pi))))
     (setq mid-ang (+ ang1 (/ (- ang2 ang1) 2.0))
           mid-pt  (point:polar center mid-ang r))
     ;; 圆心 → 弧中点 + 出头
     (list (entity:make-line center
             (point:polar center mid-ang (+ r *TB:CL-EXTEND*)) *TB:CL-LAYER*)))

    ((= typ "LWPOLYLINE")
     (setq pts (curve:vertices ename))
     ;; 闭合多段线：每边+首尾边都画中心线；开放多段线：只画实际边
     (mapcar
       '(lambda (a b)
          (cl:make-line a b))
       pts
       (if (curve:closed? ename)
         (append (cdr pts) (list (car pts)))
         (cdr pts))))

    (t (princ (strcat "\n不支持的实体类型: " typ)) nil)))


(princ "\n[TB] 智能中心线模块加载完成 (centerline: 1命令)")
(princ)
