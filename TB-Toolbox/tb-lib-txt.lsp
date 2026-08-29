;;; tb-lib-txt.lsp -- 文字操作库
;;; 文字样式管理、文字内容读写、钢筋符号转换
;;; 依赖：tb-core.lsp, tb-lib-entity.lsp

;; ============================================================================
;; 文字样式
;; ============================================================================

(defun txt:make-style (name font bigfont width)
  "创建文字样式；若已存在则直接复用。"
  (entity:make-style name font bigfont width))

(defun txt:get-current-style nil
  "获取当前文字样式名称。"
  (getvar "TEXTSTYLE"))


;; ============================================================================
;; TSSD 钢筋文字样式
;; ============================================================================

(defun txt:setup-tssd-style nil
  "创建并设为 TSSD_Rein 文字样式。"
  (entity:make-style "TSSD_Rein" "tssdeng.shx" "hztxt.shx" 0.7)
  (setvar "TEXTSTYLE" "TSSD_Rein")
  (princ "\n文字样式已设为 TSSD_Rein (tssdeng.shx + hztxt.shx)"))


;; ============================================================================
;; 文字内容读写
;; ============================================================================

(defun txt:get-content (ename)
  "获取文字内容。支持 TEXT、MTEXT、ATTRIB、ATTDEF。"
  (entity:get-dxf ename 1))

(defun txt:set-content (ename str)
  "设置文字内容。"
  (entity:set-dxf ename 1 str))

(defun txt:get-height (ename)
  "获取文字高度。"
  (entity:get-dxf ename 40))

(defun txt:set-height (ename h)
  "设置文字高度。"
  (entity:set-dxf ename 40 h))

(defun txt:get-width (ename)
  "获取文字宽高比。"
  (entity:get-dxf ename 41))

(defun txt:set-width (ename w)
  "设置文字宽高比。"
  (entity:set-dxf ename 41 w))

(defun txt:get-rotation (ename)
  "获取文字旋转角。"
  (entity:get-dxf ename 50))

(defun txt:set-rotation (ename ang)
  "设置文字旋转角。"
  (entity:set-dxf ename 50 ang))

(defun txt:get-style (ename)
  "获取文字样式名称。"
  (entity:get-dxf ename 7))

(defun txt:set-style (ename style)
  "设置文字样式。"
  (entity:set-dxf ename 7 style))

(defun txt:get-inspt (ename)
  "获取文字插入点。"
  (entity:get-dxf ename 10))

(defun txt:set-inspt (ename pt)
  "设置文字插入点。"
  (entity:set-dxf ename 10 pt))


;; ============================================================================
;; 对齐
;; ============================================================================

(defun txt:set-left-align (ename)
  "设置单行文字为左对齐。同步 DXF 10/11 防止文字移位。"
  (entity:set-dxf ename 72 0)
  (entity:set-dxf ename 73 0)
  (if (not (equal (entity:get-dxf ename 11) '(0.0 0.0 0.0) 1e-8))
    (progn
      (entity:set-dxf ename 10 (entity:get-dxf ename 11))
      (entity:set-dxf ename 11 '(0.0 0.0 0.0))))
  ename)

(defun txt:set-center-align (ename)
  "设置单行文字为水平居中。将插入点复制到对齐点。"
  (entity:set-dxf ename 72 1)
  (entity:set-dxf ename 73 0)
  (if (equal (entity:get-dxf ename 11) '(0.0 0.0 0.0) 1e-8)
    (entity:set-dxf ename 11 (entity:get-dxf ename 10)))
  ename)

(defun txt:set-middle-align (ename)
  "设置单行文字为居中对齐。将插入点复制到对齐点。"
  (entity:set-dxf ename 72 1)
  (entity:set-dxf ename 73 2)
  (if (equal (entity:get-dxf ename 11) '(0.0 0.0 0.0) 1e-8)
    (entity:set-dxf ename 11 (entity:get-dxf ename 10)))
  ename)


;; ============================================================================
;; 钢筋文字替换
;; ============================================================================

(defun txt:rebar-replace (ename old new / str)
  "替换钢筋文字中的目标片段。
若 new 包含 old 子串则只替换首次出现，防止死循环；
否则循环替换直至全部匹配被替换。"
  (setq str (txt:get-content ename))
  (if (and str old new (/= old ""))
    (progn
      (if (vl-string-search old new)
        ;; new 包含 old，只替换一次防止死循环
        (if (vl-string-search old str)
          (setq str (vl-string-subst new old str)))
        ;; 安全情况：可循环替换所有出现
        (while (vl-string-search old str)
          (setq str (vl-string-subst new old str))))
      (txt:set-content ename str)))
  ename)

(defun txt:rebar-normalize (str)
  "预留的钢筋文字规范化入口；当前保持原样返回。"
  str)


(princ "\n[TB] 文字操作库加载完成 (txt:*)")
(princ)
