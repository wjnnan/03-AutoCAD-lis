;;; tb-mod-text.lsp — 文字处理模块
;;; 组合 txt:* entity:* lay:* 库函数。
;;; 原文件来源：F:\结构插件\文字.lsp（35命令）— 去重改写

;; ============================================================================
;; 文字样式
;; ============================================================================

(defun c:tssd nil
  (uc:guard-begin '("TEXTSTYLE"))
  "创建并设为 TSSD_Rein 文字样式（探索者钢筋标准）。"
  (txt:setup-tssd-style)
  (princ)
  (uc:guard-end))

(defun c:gts (/ ss)
  (uc:guard-begin '())
  "将所选文字样式改为 TSSD_Rein。"
  (if (setq ss (ssget '((0 . "TEXT"))))
    (progn
      (txt:make-style "TSSD_Rein" "tssdeng.shx" "hztxt.shx" 0.7)
      (sel:for-each ss
        '(lambda (e)
           (txt:set-style e "TSSD_Rein")
           (txt:set-width e 0.7))))
    (princ "\n未选择文字。"))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 文字属性修改
;; ============================================================================

(defun c:ttk (/ ss w)
  (uc:guard-begin '())
  "修改所选文字的宽高比。"
  (if (setq ss (ssget '((0 . "TEXT"))))
    (progn
      (setq w (safe:get-real "文字宽高比" (if *TMP:LAST-WIDTH* *TMP:LAST-WIDTH* 0.7)))
      (setq *TMP:LAST-WIDTH* w)
      (sel:for-each ss '(lambda (e) (txt:set-width e w)))))
  (princ)
  (uc:guard-end))

(defun c:ttg (/ ss h)
  (uc:guard-begin '())
  "修改所选文字的高度。"
  (if (setq ss (ssget '((0 . "*TEXT"))))
    (progn
      (setq h (safe:get-real "文字高度" (if *TMP:LAST-TEXT-H* *TMP:LAST-TEXT-H* 350)))
      (setq *TMP:LAST-TEXT-H* h)
      (sel:for-each ss '(lambda (e) (txt:set-height e h)))))
  (princ)
  (uc:guard-end))

(defun c:ttr (/ ss ang)
  (uc:guard-begin '())
  "修改所选文字的旋转角度。"
  (if (setq ss (ssget '((0 . "TEXT"))))
    (progn
      (setq ang (getangle "\n旋转角度<0>: "))
      (if (not ang) (setq ang 0.0))
      (sel:for-each ss '(lambda (e) (txt:set-rotation e ang)))))
  (princ)
  (uc:guard-end))

(defun c:tty nil
  (uc:guard-begin '())
  "设置所选文字为左对齐。"
  (if (setq ss (ssget '((0 . "TEXT"))))
    (sel:for-each ss 'txt:set-left-align))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 文字内容操作
;; ============================================================================

(defun c:ttj (/ e1 ss source-str)
  (uc:guard-begin '())
  "文字合并：将后续文字内容追加到第一个文字。"
  (if (setq e1 (car (entsel "\n选择目标文字(内容追加到此): ")))
    (progn
      (setq source-str (txt:get-content e1))
      (if (setq ss (ssget '((0 . "TEXT"))))
        (progn
          (sel:for-each ss
            '(lambda (e)
               (if (not (eq e e1))
                 (progn
                   (setq source-str (strcat source-str (txt:get-content e)))
                   (entdel e)))))
          ;; 合并完成后更新目标文字
          (txt:set-content e1 source-str)
          (entity:update e1)))))
  (princ)
  (uc:guard-end))

(defun c:th (/ old-str new-str ss)
  (uc:guard-begin '())
  "文字查找替换。"
  (setq old-str (getstring T "\n查找文字: "))
  (if (and old-str (/= old-str ""))
    (progn
      (setq new-str (getstring T "\n替换为: "))
      (if (setq ss (ssget (list '(0 . "*TEXT") (cons 1 (strcat "*" old-str "*")))))
        (sel:for-each ss
          '(lambda (e / str)
             (setq str (txt:get-content e))
             (if (vl-string-search old-str new-str)
               (if (vl-string-search old-str str)
                 (setq str (vl-string-subst new-str old-str str)))
               (while (vl-string-search old-str str)
                 (setq str (vl-string-subst new-str old-str str))))
             (txt:set-content e str)
             (entity:update e)))
        (princ "\n未找到匹配文字。"))))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 文字对齐
;; ============================================================================

(defun c:ttq (/ ss ref-x e1)
  (uc:guard-begin '())
  "文字左对齐到同一 X 坐标。选择文字后，全部对齐到第一个文字的 X。"
  (if (setq e1 (car (entsel "\n选择基准文字 (对齐目标): ")))
    (progn
      (setq ref-x (car (txt:get-inspt e1)))
      (if (setq ss (ssget '((0 . "TEXT"))))
        (sel:for-each ss
          '(lambda (e / pt)
             (setq pt (txt:get-inspt e))
             ;; 先设为左对齐（组码 72/73），否则组码 10 对居中/右对齐文字无效
             (txt:set-left-align e)
             (txt:set-inspt e (list ref-x (cadr pt) (caddr pt))))))))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 钢筋符号转换
;; ============================================================================

(defun c:13 (/ ss)  (uc:guard-begin '())
  ; 一级钢 → 三级钢
  (if (setq ss (ssget '((0 . "*TEXT") (1 . "*%%130*"))))
    (sel:for-each ss '(lambda (e) (txt:rebar-replace e "%%130" "%%132"))))
  (princ)
  (uc:guard-end))

(defun c:23 (/ ss)  (uc:guard-begin '())
  ; 二级钢 → 三级钢
  (if (setq ss (ssget '((0 . "*TEXT") (1 . "*%%131*"))))
    (sel:for-each ss '(lambda (e) (txt:rebar-replace e "%%131" "%%132"))))
  (princ)
  (uc:guard-end))

(defun c:31 (/ ss)  (uc:guard-begin '())
  ; 三级钢 → 一级钢
  (if (setq ss (ssget '((0 . "*TEXT") (1 . "*%%132*"))))
    (sel:for-each ss '(lambda (e) (txt:rebar-replace e "%%132" "%%130"))))
  (princ)
  (uc:guard-end))

(defun c:32 (/ ss)  (uc:guard-begin '())
  ; 三级钢 → 二级钢
  (if (setq ss (ssget '((0 . "*TEXT") (1 . "*%%132*"))))
    (sel:for-each ss '(lambda (e) (txt:rebar-replace e "%%132" "%%131"))))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 文字加框
;; ============================================================================

(defun c:tjk (/ ss e bbox p1 p3)
  (uc:guard-begin '())
  "为所选文字添加矩形外框。"
  (if (setq ss (ssget '((0 . "TEXT"))))
    (sel:for-each ss
      '(lambda (e / bbox p1 p3 lay)
         (setq bbox (entity:get-bbox e 0)
               lay  (entity:get-layer e))
         (entity:make-pline
           (point:rect-2pt->4pt
             (point:offset (car bbox) -10 -10)
             (point:offset (cadr bbox)  10  10))
           T lay))))
  (princ)
  (uc:guard-end))


(princ "\n[TB] 文字处理模块加载完成 (text: 13命令)")
(princ)
