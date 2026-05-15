;;; tb-mod-edit.lsp — 绘图编辑快捷命令模块
;;; 所有快捷命令用 command 包装，简单可靠，跨平台。
;;; 组合函数：point:* entity:* sel:* lay:*
;;;
;;; 原文件来源：F:\结构插件\修改.lsp（64命令）— 去重、规范注释

;; ============================================================================
;; 基础绘图快捷
;; ============================================================================

(defun c:q  nil (command "_.LINE")     (princ))  ; 直线
(defun c:qw nil (command "_.PLINE")    (princ))  ; 多段线
(defun c:ww nil (command "_.CIRCLE")   (princ))  ; 圆
(defun c:ty nil (command "_.ELLIPSE")  (princ))  ; 椭圆
(defun c:qr nil (command "_.RECTANG")  (princ))  ; 矩形
(defun c:pp nil (command "_.POINT")    (princ))  ; 点


;; ============================================================================
;; 编辑操作快捷
;; ============================================================================

(defun c:te nil (command "_.TRIM")       (princ))  ; 修剪
(defun c:we nil (command "_.EXTEND")     (princ))  ; 延伸
(defun c:a  nil (command "_.MOVE")       (princ))  ; 移动
(defun c:s  nil (command "_.STRETCH" "_C")(princ)) ; 拉伸(交叉窗口)
(defun c:sc nil (command "_.SCALE")      (princ))  ; 缩放
(defun c:r  nil (command "_.ROTATE")     (princ))  ; 旋转
(defun c:de nil (command "_.DDEDIT")     (princ))  ; 编辑文字/属性


;; ============================================================================
;; 复制类
;; ============================================================================

(defun c:cc nil (command "_.COPY" "_M")  (princ))  ; 连续复制

(defun c:cf (/ ss p1 num dist)
  "等距复制。选择对象 → 指定基点 → 数量 → 间距。"
  (setq ss (ssget))
  (if (and ss (setq p1 (getpoint "\n基点: ")))
    (progn
      (setq num  (safe:get-int "复制数量" 2)
            dist (safe:get-dist "间距" nil 300))
      (command "_.COPY" ss "" p1 "_A" num dist 0 "")))
  (princ))

(defun c:cr (/ ss p1)
  "旋转复制。先原地复制，再旋转复制品。"
  (setq ss (ssget))
  (if (and ss (setq p1 (getpoint "\n旋转基点: ")))
    (progn
      (command "_.COPY" ss "" p1 p1)     ; 原地复制
      (command "_.ROTATE" "_P" "" p1) ; 仅旋转复制品
      ))
  (princ))

(defun c:cl (/ ss)
  "复制到当前图层。选择的实体复制后改到当前层。"
  (setq ss (ssget))
  (if ss
    (progn
      (command "_.COPY" ss "" '(0 0 0) '(0 0 0))
      (command "_.CHPROP" "_P" "" "_LA" (getvar "CLAYER") "")))
  (princ))


;; ============================================================================
;; 倒角/倒圆
;; ============================================================================

(defun c:ff nil
  "零倒角（r=0 的圆角）。重复执行4次以覆盖十字路口。"
  (setvar "FILLETRAD" 0)
  (repeat 4 (command "_.FILLET" pause pause))
  (princ))

(defun c:fr (/ r)
  "倒圆角，用户指定半径。"
  (setq r (safe:get-real "圆角半径" (sys:ifnil *TMP:LAST-FILLET-R* 50)))
  (setq *TMP:LAST-FILLET-R* r)
  (setvar "FILLETRAD" r)
  (command "_.FILLET" pause pause)
  (princ))


;; ============================================================================
;; 缩放预设
;; ============================================================================

(defun c:s1 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint "\n基点: ")) (command "_.SCALE" ss "" pt 0.5)))   (princ))  ; 0.5x
(defun c:s2 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint "\n基点: ")) (command "_.SCALE" ss "" pt 2)))     (princ))  ; 2x
(defun c:s4 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint "\n基点: ")) (command "_.SCALE" ss "" pt 4)))     (princ))  ; 4x
(defun c:s5 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint "\n基点: ")) (command "_.SCALE" ss "" pt 5)))     (princ))  ; 5x
(defun c:s0 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint))        (command "_.SCALE" ss "" pt 100)))      (princ))  ; 100x
(defun c:s00 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint)) (command "_.SCALE" ss "" pt 1000))) (princ))  ; 1000x


;; ============================================================================
;; 旋转预设
;; ============================================================================

(defun c:r4 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint "\n基点: ")) (command "_.ROTATE" ss "" pt -45)))  (princ))  ; 顺时针45
(defun c:r9 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint "\n基点: ")) (command "_.ROTATE" ss "" pt -90)))  (princ))  ; 顺时针90
(defun c:r5 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint "\n基点: ")) (command "_.ROTATE" ss "" pt 45)))   (princ))  ; 逆时针45
(defun c:r0 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint "\n基点: ")) (command "_.ROTATE" ss "" pt 90)))   (princ))  ; 逆时针90


;; ============================================================================
;; 其他编辑工具
;; ============================================================================

(defun c:oo nil (command "_.OFFSET" pause pause pause "") (princ))  ; 偏移

(defun c:cx (/ p1 p2)
  "单点选线修剪——画临时线，修剪与之交叉的对象。"
  (if (setq p1 (getpoint "\n第一点: "))
    (if (setq p2 (getpoint p1 "\n第二点: "))
      (progn
        (command "_.LINE" p1 p2 "")
        (command "_.TRIM" (entlast) "" pause)
        (entdel (entlast)))))
  (princ))

(defun c:z0 (/ ss ename)
  "将所选直线的 Z 坐标归零。"
  (if (setq ss (ssget '((0 . "LINE"))))
    (sel:for-each ss
      '(lambda (e / p10 p11)
         (setq p10 (entity:get-dxf e 10)
               p11 (entity:get-dxf e 11))
         (entity:set-dxf e 10 (list (car p10) (cadr p10) 0.0))
         (entity:set-dxf e 11 (list (car p11) (cadr p11) 0.0)))))
  (princ "\nZ坐标已归零。")
  (princ))

(defun c:ee nil (command "_.ZOOM" "_E") (princ))  ; 范围缩放

(defun c:As nil (command "_.QSAVE")     (princ))  ; 快速保存


;; ============================================================================
;; 颜色快速切换（修改-51~58）
;; ============================================================================

(defun c:C1 (/ ss) (if (setq ss (ssget)) (command "_.CHPROP" ss "" "_C" 1 ""))  (princ))  ; 红色
(defun c:C2 (/ ss) (if (setq ss (ssget)) (command "_.CHPROP" ss "" "_C" 2 ""))  (princ))  ; 黄色
(defun c:C3 (/ ss) (if (setq ss (ssget)) (command "_.CHPROP" ss "" "_C" 3 ""))  (princ))  ; 绿色
(defun c:C4 (/ ss) (if (setq ss (ssget)) (command "_.CHPROP" ss "" "_C" 4 ""))  (princ))  ; 青色
(defun c:C5 (/ ss) (if (setq ss (ssget)) (command "_.CHPROP" ss "" "_C" 5 ""))  (princ))  ; 蓝色
(defun c:C6 (/ ss) (if (setq ss (ssget)) (command "_.CHPROP" ss "" "_C" 6 ""))  (princ))  ; 洋红
(defun c:C7 (/ ss) (if (setq ss (ssget)) (command "_.CHPROP" ss "" "_C" 7 ""))  (princ))  ; 白/黑
(defun c:C8 (/ ss) (if (setq ss (ssget)) (command "_.CHPROP" ss "" "_C" 8 ""))  (princ))  ; 灰色


;; ============================================================================
;; 视口
;; ============================================================================

(defun c:v1 nil (command "_.VPORTS" "_SI") (command "_.ZOOM" "_E") (princ))  ; 单视口
(defun c:v2 nil (command "_.VPORTS" "_2" "_V") (princ))  ; 双视口-垂直
(defun c:v3 nil (command "_.VPORTS" "_2" "_H") (princ))  ; 双视口-水平


(princ "\n[TB] 绘图编辑模块加载完成 (edit: 43命令)")
(princ)
