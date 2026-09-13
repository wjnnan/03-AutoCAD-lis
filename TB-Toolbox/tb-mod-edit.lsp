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

(defun c:cf (/ ss p1 p2 num dist ang)
  (uc:guard-begin '())
  "等距复制。选择对象 → 指定基点 → 数量 → 间距。"
  (setq ss (ssget))
  (if (and ss (setq p1 (getpoint "\n基点: ")))
    (progn
      (setq p2   (getpoint p1 "\n复制方向: ")
            num  (safe:get-int "复制份数" 2)
            dist (safe:get-dist "间距" nil 300))
      (if (and p2 num dist)
        (progn
          (setq ang (angle p1 p2))
          ;; COPY 阵列：num 份（含原件），最后一份在 基点 + 方向 * dist*(num-1)
          (command "_.COPY" ss "" p1 "_A" num
                   (polar p1 ang (* dist (1- num))) "")))))
  (princ)
  (uc:guard-end))

(defun c:cr (/ ss p1 e-last new-ss)
  (uc:guard-begin '())
  "旋转复制。先原地复制，再旋转复制品。"
  (setq ss (ssget))
  (if (and ss (setq p1 (getpoint "\n旋转基点: ")))
    (progn
      (setq e-last (entlast))
      (command "_.COPY" ss "" p1 p1)     ; 原地复制
      ;; 收集复制出的新实体（不依赖 _P 的 Previous 行为）
      (setq new-ss (ssadd))
      (while (setq e-last (entnext e-last))
        (ssadd e-last new-ss))
      (if (> (sslength new-ss) 0)
        (command "_.ROTATE" new-ss "" p1))))
  (princ)
  (uc:guard-end))

(defun c:cl (/ ss e-last new-ss)
  (uc:guard-begin '())
  "复制到当前图层。选择的实体复制后改到当前层。"
  (setq ss (ssget))
  (if ss
    (progn
      (setq e-last (entlast))
      (command "_.COPY" ss "" '(0 0 0) '(0 0 0))
      (setq new-ss (ssadd))
      (while (setq e-last (entnext e-last))
        (ssadd e-last new-ss))
      (if (> (sslength new-ss) 0)
        (command "_.CHPROP" new-ss "" "_LA" (getvar "CLAYER") ""))))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 倒角/倒圆
;; ============================================================================

(defun c:ff nil
  (uc:guard-begin '("FILLETRAD"))
  "零倒角（r=0 的圆角）。重复执行4次以覆盖十字路口。"
  (setvar "FILLETRAD" 0)
  (repeat 4 (command "_.FILLET" pause pause))
  (princ)
  (uc:guard-end))

(defun c:fr (/ r)
  (uc:guard-begin '("FILLETRAD"))
  "倒圆角，用户指定半径。"
  (setq r (safe:get-real "圆角半径" (sys:ifnil *TMP:LAST-FILLET-R* 50)))
  (setq *TMP:LAST-FILLET-R* r)
  (setvar "FILLETRAD" r)
  (command "_.FILLET" pause pause)
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 缩放预设
;; ============================================================================

(defun c:s1 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint "\n基点: ")) (command "_.SCALE" ss "" pt 0.5)) T)   (princ))  ; 0.5x
(defun c:s2 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint "\n基点: ")) (command "_.SCALE" ss "" pt 2)) T)     (princ))  ; 2x
(defun c:s4 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint "\n基点: ")) (command "_.SCALE" ss "" pt 4)) T)     (princ))  ; 4x
(defun c:s5 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint "\n基点: ")) (command "_.SCALE" ss "" pt 5)) T)     (princ))  ; 5x
(defun c:s0 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint))        (command "_.SCALE" ss "" pt 100)) T)      (princ))  ; 100x
(defun c:s00 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint)) (command "_.SCALE" ss "" pt 1000)) T) (princ))  ; 1000x


;; ============================================================================
;; 旋转预设
;; ============================================================================

(defun c:r4 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint "\n基点: ")) (command "_.ROTATE" ss "" pt -45)) T)  (princ))  ; 顺时针45
(defun c:r9 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint "\n基点: ")) (command "_.ROTATE" ss "" pt -90)) T)  (princ))  ; 顺时针90
(defun c:r5 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint "\n基点: ")) (command "_.ROTATE" ss "" pt 45)) T)   (princ))  ; 逆时针45
(defun c:r0 (/ ss pt) (if (and (setq ss (ssget)) (setq pt (getpoint "\n基点: ")) (command "_.ROTATE" ss "" pt 90)) T)   (princ))  ; 逆时针90


;; ============================================================================
;; 其他编辑工具
;; ============================================================================

(defun c:oo nil (command "_.OFFSET" pause pause pause "") (princ))  ; 偏移

(defun c:cx (/ p1 p2 e-tmp)
  (uc:guard-begin '())
  "单点选线修剪——画临时线，修剪与之交叉的对象。"
  (if (setq p1 (getpoint "\n第一点: "))
    (if (setq p2 (getpoint p1 "\n第二点: "))
      (progn
        (command "_.LINE" p1 p2 "")
        (setq e-tmp (entlast))
        (command "_.TRIM" e-tmp "" pause "")
        (if (entget e-tmp) (entdel e-tmp)))))
  (princ)
  (uc:guard-end))

(defun c:z0 (/ ss ename)
  (uc:guard-begin '())
  "将所选直线的 Z 坐标归零。"
  (if (setq ss (ssget '((0 . "LINE"))))
    (sel:for-each ss
      '(lambda (e / p10 p11)
         (setq p10 (entity:get-dxf e 10)
               p11 (entity:get-dxf e 11))
         (entity:set-dxf e 10 (list (car p10) (cadr p10) 0.0))
         (entity:set-dxf e 11 (list (car p11) (cadr p11) 0.0)))))
  (princ "\nZ坐标已归零。")
  (princ)
  (uc:guard-end))

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


;; ============================================================================
;; 批量向内偏移（吸收明经论坛"批量偏移-画结构大样图"）
;; ============================================================================

(defun c:BOFF (/ ss d i e dir)
  "批量向内偏移。选闭合曲线，自动向内偏移（画结构大样图专用）。"
  (if (not (and *SYS:HAS-ACTIVEX* (uc:com-available-p)))
    (princ "\n[TB] 批量偏移需要 ActiveX 支持。")
    (progn
      (setq d (getdist "\n偏移距离: "))
      (if (and d (setq ss (ssget '((0 . "LWPOLYLINE,CIRCLE,ELLIPSE")))))
        (progn
          (setq i 0)
          (repeat (sslength ss)
            (setq e (ssname ss i)
                  dir (if (curve:clockwise? (curve:vertices e)) -1 1))
            (vl-catch-all-apply 'vla-offset
              (list (vlax-ename->vla-object e) (* dir d)))
            (setq i (1+ i)))
          (princ (strcat "\n[TB] 已偏移 " (itoa (sslength ss)) " 条曲线"))))))
  (princ))

;; ============================================================================
;; 多重偏移（吸收自 AutoCAD-LISP 项目，修复全局变量污染）
;; ============================================================================

(defun c:MOF (/ d oftype ans ss i e cnt)
  "多重偏移：向外/居中/向内，可选删除源对象。"
  (uc:guard-begin '())
  (setq d (getdist "\n偏移距离: "))
  (if (and d (setq ss (ssget '((0 . "LWPOLYLINE,CIRCLE,ELLIPSE,SPLINE,ARC")))))
    (progn
      (initget 1 "Out Center In")
      (setq oftype (getkword "\n偏移方式 [向外(Out)/居中(Center)/向内(In)]: "))
      (initget "Y N")
      (setq ans (getkword "\n删除源对象? [Y/N] <N>: "))
      (setq i 0 cnt 0)
      (repeat (sslength ss)
        (setq e (vlax-ename->vla-object (ssname ss i)))
        (cond
          ((= oftype "Out")
           (vl-catch-all-apply 'vla-offset (list e d)))
          ((= oftype "Center")
           (vl-catch-all-apply 'vla-offset (list e d))
           (vl-catch-all-apply 'vla-offset (list e (- d))))
          (t
           (vl-catch-all-apply 'vla-offset (list e (- d)))))
        (if (= ans "Y")
          (vl-catch-all-apply 'vla-delete (list e)))
        (setq i (1+ i) cnt (1+ cnt)))
      (princ (strcat "\n已偏移 " (itoa cnt) " 个对象。")))
    (princ "\n未选择对象或未输入距离。"))
  (princ)
  (uc:guard-end))

(princ "\n[TB] 绘图编辑模块加载完成 (edit: 45命令)")
(princ)
