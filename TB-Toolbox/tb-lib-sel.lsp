;;; tb-lib-sel.lsp -- 选择集操作库
;;; 封装 ssget 常用操作，统一转为 ename 列表处理。
;;; 依赖：tb-core.lsp，unified-lib/uc-core.lsp

(defun sel:by-layer (layname / ss)
  "选择指定图层上的所有实体。"
  (ssget "X" (list (cons 8 layname))))

(defun sel:by-type (ent-type / ss)
  "选择指定类型的所有实体。"
  (ssget "X" (list (cons 0 ent-type))))

(defun sel:filter (alist)
  "按 DXF 过滤表选择实体。"
  (ssget "X" alist))

(defun sel:pick (prompt filter)
  "交互选择实体。"
  (princ (strcat "\n" prompt))
  (ssget filter))

(defun sel:to-list (ss / i lst)
  "将选择集转换为实体列表。"
  (uc:pickset->list ss))

(defun sel:for-each (ss callback)
  "遍历选择集中的所有实体。"
  (if ss
    (mapcar callback (sel:to-list ss))))

(defun sel:count (ss)
  "返回选择集中元素的数量。"
  (if ss (sslength ss) 0))

(defun sel:add (ss ename)
  "向选择集中添加一个实体。"
  (ssadd ename ss))

(defun sel:delete (ss ename)
  "从选择集中删除一个实体。"
  (ssdel ename ss))

;; ============================================================================
;; 按颜色选择（吸收明经论坛"按颜色选择"，纯 AutoLISP 跨平台）
;; ============================================================================

(defun sel:get-color (ename / dxf col)
  "获取对象颜色索引。随层(BYLAYER)时取图层颜色。"
  (setq dxf (entget ename))
  (if (setq col (cdr (assoc 62 dxf)))
    col
    (cdr (assoc 62 (tblsearch "layer" (cdr (assoc 8 dxf)))))))

(defun sel:by-color (col / lay laystr ss)
  "获取指定颜色索引的选择集（含随层对象）。col=颜色索引 1-255。"
  (setq laystr "")
  (while (setq lay (tblnext "layer" (not lay)))
    (if (= (abs (cdr (assoc 62 lay))) col)
      (setq laystr (strcat laystr (if (= laystr "") "" ",") (cdr (assoc 2 lay))))))
  (if (= laystr "")
    (ssget "X" (list (cons 62 col)))
    (ssget "X"
      (list '(-4 . "<OR")
            (cons 62 col)
            '(-4 . "<AND")
            (cons 8 laystr)
            '(62 . 256)
            '(-4 . "AND>")
            '(-4 . "OR>")))))

(defun c:SSC (/ en col ss n)
  "按颜色选择。点选对象，选择所有同色对象（含随层、块对象）。"
  (if (setq en (car (entsel "\n请选择颜色参照对象: ")))
    (progn
      (setq col (sel:get-color en)
            ss  (sel:by-color col))
      (if ss
        (progn
          (sssetfirst nil ss)
          (setq n (sslength ss))
          (princ (strcat "\n[TB] 已选择 " (itoa n) " 个同色对象")))
        (princ "\n[TB] 未找到同色对象"))))
  (princ))

;; ============================================================================
;; 重复内容选中（吸收明经论坛"重复内容选中"，选相同文字/块）
;; ============================================================================

(defun sel:escape-wildcard (str)
  "转义块名中的 wcmatch 通配符字符 @ # . ~ *。"
  (vl-string-subst "`@" "@"
    (vl-string-subst "`#" "#"
      (vl-string-subst "`." "."
        (vl-string-subst "`~" "~"
          (vl-string-subst "`*" "*" str))))))

(defun c:SSM (/ ent dxf typ ss name)
  "重复内容选中。点选文字/块，选择所有相同内容的对象。"
  (if (setq ent (car (entsel "\n请选择待匹配的文字或块: ")))
    (progn
      (setq dxf (entget ent)
            typ (cdr (assoc 0 dxf)))
      (cond
        ((member typ '("TEXT" "MTEXT"))
         (setq ss (ssget "_X" (list (cons 1 (cdr (assoc 1 dxf)))))))
        ((= typ "INSERT")
         (setq name (sel:escape-wildcard (cdr (assoc 2 dxf)))
               ss (ssget "_X" (list (cons 2 name)))))
        (t (setq ss nil)))
      (if ss
        (progn
          (sssetfirst nil ss)
          (princ (strcat "\n[TB] 已选择 " (itoa (sslength ss)) " 个相同对象")))
        (princ "\n[TB] 未找到相同对象"))))
  (princ))

(princ "\n[TB] 选择集操作库加载完成 (sel:*)")
(princ)
