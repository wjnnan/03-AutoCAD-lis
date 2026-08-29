;;; tb-mod-hotkey.lsp — 快捷键设置模块
;;; 提供：命令目录派生、快捷键映射读取、动态命令别名、主界面按钮 label 刷新、快捷键设置对话框
;;; 依赖：tb-core.lsp(sys:get/set)、tb-main.lsp(*TB:CMD-CATALOG*/*TB:PAGE-NAMES*)、uc-core.lsp(uc:function-defined-p)

;; ============================================================================
;; 辅助全局变量
;; ============================================================================

(setq *TB:HOTKEY-EDITS* nil   ; 对话框状态：cmd -> 有效快捷键
      *TB:HOTKEY-ROWS*  nil   ; 对话框列表行：(显示文本 . cmd)
      *TB:HOTKEY-CUR*   nil   ; 当前选中命令
      *TB:ALIAS-SYMBOLS* nil) ; 已注册的别名符号表

;; 命令索引：cmd -> (功能名 . 页号)
(setq *TB:CMD-INDEX* (mapcar '(lambda (e) (cons (cadr e) (cddr e))) *TB:CMD-CATALOG*))

;; ============================================================================
;; 快捷键读取与归一化
;; ============================================================================

(defun tb:cfg-str (v)
  "cfg 值归一化为字符串（读回可能是符号）。"
  (cond ((null v) nil)
        ((eq (type v) 'STR) v)
        (t (vl-princ-to-string v))))

(defun tb:hotkey-key (cmd)
  "构造快捷键配置键符号。"
  (read (strcat "*SYS:HOTKEY-" cmd "*")))

(defun tb:effective-shortcut (cmd / v)
  "读取命令有效快捷键，默认=内部命令名（大写）。内联实现，不依赖辅助函数。"
  (setq v (cdr (assoc (read (strcat "*SYS:HOTKEY-" cmd "*")) *SYS:CONFIG*)))
  (cond ((null v) (strcase cmd))
        ((eq (type v) 'STR) v)
        (t (vl-princ-to-string v))))

(defun tb:alnum-only-p (s / i ok)
  "仅字母数字校验。"
  (setq i 1 ok T)
  (while (and ok (<= i (strlen s)))
    (if (wcmatch (substr s i 1) "@#")
      (setq i (1+ i))
      (setq ok nil)))
  ok)

(defun tb:conflict-p (cmd sh / su)
  "检查快捷键是否与其他命令冲突（含对方原命令名占用）。"
  (setq su (strcase sh))
  (or
    (vl-some
      '(lambda (o)
         (and (/= (strcase o) (strcase cmd))
              (= (strcase (tb:cfg-str (cdr (assoc o *TB:HOTKEY-EDITS*)))) su)))
      (mapcar 'car *TB:HOTKEY-EDITS*))
    (vl-some
      '(lambda (e)
         (and (/= (strcase (cadr e)) (strcase cmd))
              (= (strcase (cadr e)) su)))
      *TB:CMD-CATALOG*)))

(defun tb:hotkey-validate (cmd sh)
  "校验快捷键合法性。返回错误消息或 nil。"
  (cond
    ((or (null sh) (= (strlen sh) 0)) "快捷键不能为空。")
    ((> (strlen sh) 6) "快捷键长度不能超过 6 个字符。")
    ((not (tb:alnum-only-p sh)) "快捷键只能包含字母或数字。")
    ((member (strcase sh) '("TB" "TBSETTING" "TBHELP" "TBSETTING2" "BUILD-TB"))
     "该名称是系统保留命令，不能用作快捷键。")
    ((tb:conflict-p cmd sh) "该快捷键已被其他命令占用。")
    (t nil)))

;; ============================================================================
;; 目录校验与应用
;; ============================================================================

(defun tb:verify-catalog (/ flat n ok)
  "校验目录与 PAGE-BINDS 一致性（加载期调用，纯内存）。"
  (setq flat (apply 'append *TB:PAGE-BINDS*)
        n 0
        ok T)
  (if (= (length flat) (length *TB:CMD-CATALOG*))
    (progn
      (foreach pair flat
        (if (and (equal (car pair) (car (nth n *TB:CMD-CATALOG*)))
                 (equal (strcase (cdr pair)) (strcase (cadr (nth n *TB:CMD-CATALOG*)))))
          (setq n (1+ n))
          (progn (setq ok nil)
                 (princ (strcat "\n[TB] 目录与绑定不一致: " (vl-princ-to-string pair))))))
      (if ok
        (princ (strcat "\n[TB] 目录校验通过: " (itoa n) "/" (itoa (length flat))))
        (princ (strcat "\n[TB] 目录校验未完全通过: " (itoa n) "/" (itoa (length flat))))))
    (princ (strcat "\n[TB] 目录数量不符: 目录 " (itoa (length *TB:CMD-CATALOG*))
                   " vs 绑定 " (itoa (length flat)))))
  ok)

(defun tb:apply-shortcuts (/ used aliases new-aliases entry cmd sh sym target)
  "从 *SYS:CONFIG* 读取快捷键并创建命令别名。
   仅对"快捷键 != 内部命令名"的命令注册 (defun c:快捷键 nil (c:内部命令))。"
  (setq used (mapcar 'strcase (mapcar 'cadr *TB:CMD-CATALOG*))
        aliases *TB:ALIAS-SYMBOLS*
        new-aliases nil)
  (foreach entry *TB:CMD-CATALOG*
    (setq cmd    (cadr entry)
          sh     (strcase (tb:effective-shortcut cmd))
          target (read (strcat "c:" cmd))
          sym    (read (strcat "c:" sh)))
    (cond
      ((= sh (strcase cmd)) nil)  ; 默认，无需别名
      ((not (tb:alnum-only-p sh))
       (princ (strcat "\n[TB] 快捷键含非法字符，跳过: " cmd " -> " sh)))
      ((member sh '("TB" "TBSETTING" "TBHELP" "TBSETTING2" "BUILD-TB"))
       (princ (strcat "\n[TB] 保留命令，跳过: " sh)))
      ((member sh used)
       (princ (strcat "\n[TB] 快捷键冲突，跳过: " sh)))
      ((not (uc:command-defined-p target))
       (princ (strcat "\n[TB] 原命令未定义，跳过: " cmd)))
      ((and (uc:function-defined-p sym)
            (not (member sym aliases)))
       (princ (strcat "\n[TB] 与已有 c: 函数冲突，跳过: " sh)))
      (t
       (eval (list 'defun sym nil (list target)))
       (setq used (cons sh used)
             new-aliases (cons sym new-aliases)))))
  ;; 中和不再需要的旧别名
  (foreach sym aliases
    (if (not (member sym new-aliases))
      (eval (list 'defun sym nil '(princ)))))
  (setq *TB:ALIAS-SYMBOLS* new-aliases)
  (princ (strcat "\n[TB] 快捷键别名已应用: " (itoa (length new-aliases)) " 个"))
  T)

;; ============================================================================
;; 主界面按钮 label 刷新
;; ============================================================================

(defun tb:update-page-labels (page / e cmd sh)
  "按配置刷新当前页按钮 label（功能名 + 用户快捷键）。"
  (foreach e *TB:CMD-CATALOG*
    (if (= (cadddr e) page)
      (progn
        (setq cmd (cadr e)
              sh  (strcase (tb:effective-shortcut cmd)))
        (set_tile (car e) (strcat (caddr e) " " sh))))))

;; ============================================================================
;; 快捷键设置对话框
;; ============================================================================

(defun tb:hotkey-status (msg)
  "更新对话框状态栏。"
  (set_tile "hk_status" msg))

(defun tb:hotkey-refresh-list (/ rows prev cmd sh e)
  "重建命令列表（含页分组标题）。"
  (setq rows nil
        prev -1)
  (foreach e *TB:CMD-CATALOG*
    (setq cmd (cadr e)
          sh  (strcase (cdr (assoc cmd *TB:HOTKEY-EDITS*))))
    (if (/= (cadddr e) prev)
      (progn
        (setq rows (append rows (list (cons (strcat "── " (nth (cadddr e) *TB:PAGE-NAMES*) " ──") nil)))
              prev (cadddr e))))
    (setq rows (append rows (list (cons (strcat (caddr e) " - " sh) cmd)))))
  (setq *TB:HOTKEY-ROWS* rows)
  (start_list "cmd_list")
  (foreach r rows (add_list (car r)))
  (end_list))

(defun tb:hotkey-init ()
  "初始化对话框状态与列表。"
  (setq *TB:HOTKEY-EDITS* nil)
  (foreach e *TB:CMD-CATALOG*
    (setq *TB:HOTKEY-EDITS*
      (cons (cons (cadr e) (tb:effective-shortcut (cadr e))) *TB:HOTKEY-EDITS*)))
  (setq *TB:HOTKEY-EDITS* (reverse *TB:HOTKEY-EDITS*)
        *TB:HOTKEY-CUR* nil)
  (tb:hotkey-refresh-list)
  (tb:hotkey-status "已加载 125 个命令。请选择命令后编辑快捷键。"))

(defun tb:hotkey-select (/ row cmd)
  "列表选中联动。"
  (setq row (nth (atoi (get_tile "cmd_list")) *TB:HOTKEY-ROWS*))
  (if (and row (cdr row))
    (progn
      (setq cmd (cdr row)
            *TB:HOTKEY-CUR* cmd)
      (set_tile "cur_fn"  (car (cdr (assoc cmd *TB:CMD-INDEX*))))
      (set_tile "cur_cmd" cmd)
      (set_tile "shortcut" (strcase (cdr (assoc cmd *TB:HOTKEY-EDITS*)))))))

(defun tb:hotkey-apply-one (/ cmd sh err)
  "应用当前命令的快捷键。"
  (setq cmd *TB:HOTKEY-CUR*)
  (cond
    ((null cmd) (tb:hotkey-status "请先在左侧列表选择一个命令。"))
    ((setq err (tb:hotkey-validate cmd (get_tile "shortcut")))
     (alert err)
     (mode_tile "shortcut" 2))
    (t
     (setq sh (get_tile "shortcut"))
     (sys:set (tb:hotkey-key cmd) sh)
     (setq *TB:HOTKEY-EDITS*
       (subst (cons cmd sh) (assoc cmd *TB:HOTKEY-EDITS*) *TB:HOTKEY-EDITS*))
     (tb:hotkey-refresh-list)
     (tb:hotkey-status
       (strcat "已应用: " (car (cdr (assoc cmd *TB:CMD-INDEX*))) " -> " (strcase sh))))))

(defun tb:hotkey-reset-one (/ cmd)
  "重置当前命令快捷键为默认。"
  (setq cmd *TB:HOTKEY-CUR*)
  (if cmd
    (progn
      (sys:set (tb:hotkey-key cmd) cmd)
      (setq *TB:HOTKEY-EDITS*
        (subst (cons cmd cmd) (assoc cmd *TB:HOTKEY-EDITS*) *TB:HOTKEY-EDITS*))
      (tb:hotkey-refresh-list)
      (tb:hotkey-status (strcat "已重置: " cmd " -> " (strcase cmd))))
    (tb:hotkey-status "请先在左侧列表选择一个命令。")))

(defun tb:hotkey-reset-all (/ p)
  "恢复全部命令默认快捷键。"
  (foreach p *TB:HOTKEY-EDITS*
    (sys:set (tb:hotkey-key (car p)) (car p)))
  (setq *TB:HOTKEY-EDITS*
    (mapcar '(lambda (p) (cons (car p) (car p))) *TB:HOTKEY-EDITS*))
  (tb:hotkey-refresh-list)
  (tb:hotkey-status "已恢复全部默认，点「保存并应用」生效。"))

(defun tb:hotkey-save (/ p)
  "保存全部快捷键并应用。"
  (foreach p *TB:HOTKEY-EDITS*
    (sys:set (tb:hotkey-key (car p)) (cdr p)))
  (tb:apply-shortcuts)
  (done_dialog 1))

(defun c:TBSETTING2 (/ dcl-fn dcl-id result olderror)
  "打开快捷键设置对话框。"
  (setq olderror *error*
        *error* (lambda (msg)
                  (if dcl-id (vl-catch-all-apply 'unload_dialog (list dcl-id)))
                  (setq *error* olderror)
                  (princ (strcat "\n[TB] 快捷键设置异常: " (if msg msg "")))
                  (princ)))
  (setq dcl-fn (tb:resolve-dcl "tb-dcl-hotkey.dcl"))
  (if (and dcl-fn (setq dcl-id (load_dialog dcl-fn)))
    (if (new_dialog "tb_hotkey" dcl-id)
      (progn
        (tb:hotkey-init)
        (action_tile "cmd_list" "(tb:hotkey-select)")
        (action_tile "btn_apply" "(tb:hotkey-apply-one)")
        (action_tile "btn_reset_one" "(tb:hotkey-reset-one)")
        (action_tile "btn_reset_all" "(tb:hotkey-reset-all)")
        (action_tile "save" "(tb:hotkey-save)")
        (action_tile "btn_gen" "(done_dialog 5)")
        (action_tile "cancel" "(done_dialog 0)")
        (setq result (start_dialog))
        (unload_dialog dcl-id)
        (cond
          ((= result 1) (princ "\n[TB] 快捷键已保存并生效。"))
          ((= result 5) (c:TBSETTING))))
      (progn
        (unload_dialog dcl-id)
        (princ "\n[TB] 无法初始化快捷键设置对话框。")))
    (princ "\n[TB] 找不到快捷键设置 DCL 文件。"))
  (setq *error* olderror)
  (princ))

;; ============================================================================
;; 加载时：目录校验（纯内存，不触发文件操作）
;; ============================================================================

(vl-catch-all-apply 'tb:verify-catalog)
(princ "\n[TB] 快捷键模块加载完成 (c:TBSETTING2)")
(princ)
