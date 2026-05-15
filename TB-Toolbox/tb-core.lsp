;;; tb-core.lsp — 建筑结构工具箱 核心系统
;;; 包含：平台检测、参数体系、错误处理框架、通用工具函数
;;; 加载顺序：必须第一个加载

;; ============================================================================
;; 第一节：平台检测
;; ============================================================================

;; 检测当前运行的 CAD 平台，设置全局标识变量。
;; 只在加载时执行一次，结果存入 *SYS:PLATFORM* 等变量。
(defun sys:detect-platform (/ product)
  (setq product (strcase (getvar "product")))
  ;; 平台标识
  (setq *SYS:PLATFORM*
    (cond
      ((wcmatch product "*ZWCAD*")    "ZWCAD")     ; 中望CAD
      ((wcmatch product "*GSTARCAD*") "GSTARCAD")  ; 浩辰CAD
      ((wcmatch product "*BRICSCAD*") "BRICSCAD")  ; BricsCAD
      (t                              "AUTOCAD"))) ; AutoCAD 及其他
  ;; ActiveX COM 支持（ZWCAD 不支持）
  (setq *SYS:HAS-ACTIVEX*
    (not (= *SYS:PLATFORM* "ZWCAD")))
  ;; 反应器支持（仅 AutoCAD 完整支持）
  (setq *SYS:HAS-REACTORS*
    (= *SYS:PLATFORM* "AUTOCAD"))
  ;; DWG 格式版本号
  (setq *SYS:ACADVER* (atof (getvar "acadver")))
  (princ (strcat "\n[TB] 平台: " *SYS:PLATFORM*
                 " | ActiveX: " (if *SYS:HAS-ACTIVEX* "是" "否")
                 " | 反应器: " (if *SYS:HAS-REACTORS* "是" "否")))
  (princ))

;; 立即执行平台检测
(sys:detect-platform)


;; ============================================================================
;; 第二节：参数体系 — 系统参数 / 项目参数 / 临时参数
;; ============================================================================

;; --- 内部存储 ---
;; 系统参数存于外部文件，启动时读入内存 *SYS:CONFIG*
;; 项目参数存于图纸 LData，打开图纸时读入 *PRJ:CONFIG*
;; 临时参数只存于内存 *TMP:VARS*，命令结束时清理

(setq *SYS:CONFIG* nil   ; 系统参数 alist
      *PRJ:CONFIG* nil   ; 项目参数 alist
      *TMP:VARS*   nil)  ; 临时参数 alist

;; 系统参数持久化文件路径（ROAMABLEROOTPREFIX 在旧版/国产CAD可能不存在，用 DWGPREFIX 兜底）
;; 用 vl-catch-all-apply 保护 getvar，避免 ZWCAD 等宿主直接抛错
(setq *SYS:CONFIG-FILE*
  (strcat
    (vl-string-right-trim "\\"
      (cond
        (*TB:ROOT*)
        ((not (vl-catch-all-error-p
                (setq *SYS:ROAMABLE-TRY*
                  (vl-catch-all-apply 'getvar (list "ROAMABLEROOTPREFIX")))))
         *SYS:ROAMABLE-TRY*)
        (t (vl-catch-all-apply 'getvar (list "DWGPREFIX")))))
    "\\TB-SysConfig.cfg"))


;; --- 参数读写接口 ---

;; 读取任意层级的参数值。自动在三层中查找：临时 > 项目 > 系统。
;; 参数 key 为符号，如 '*SYS:DWG-SCALE*。
(defun sys:get (key / val)
  ;; 先查临时参数
  (if (setq val (cdr (assoc key *TMP:VARS*))) val
    ;; 再查项目参数
    (if (setq val (cdr (assoc key *PRJ:CONFIG*))) val
      ;; 最后查系统参数
      (cdr (assoc key *SYS:CONFIG*)))))

;; 写入参数值。根据 key 前缀自动判断存储层级。
;; '*SYS:* 写入系统参数，'*PRJ:* 写入项目参数，'*TMP:* 写入临时参数。
(defun sys:set (key value)
  (cond
    ;; 系统参数
    ((wcmatch (vl-symbol-name key) "*SYS:*")
     (setq *SYS:CONFIG* (sys:alist-put *SYS:CONFIG* key value))
     (sys:save-config)  ; 自动持久化
     value)
    ;; 项目参数
    ((wcmatch (vl-symbol-name key) "*PRJ:*")
     (setq *PRJ:CONFIG* (sys:alist-put *PRJ:CONFIG* key value))
     value)
    ;; 临时参数
    ((wcmatch (vl-symbol-name key) "*TMP:*")
     (setq *TMP:VARS* (sys:alist-put *TMP:VARS* key value))
     value)
    (t (princ (strcat "\n[TB] 未知参数前缀: " (vl-symbol-name key))) nil)))


;; --- 系统参数持久化 ---

(defun sys:save-config (/ f)
  "将 *SYS:CONFIG* 保存到外部文件。每行格式：key=value。"
  (if (setq f (open *SYS:CONFIG-FILE* "w"))
    (progn
      (foreach pair *SYS:CONFIG*
        (write-line (strcat (vl-symbol-name (car pair))
                            "="
                            (vl-princ-to-string (cdr pair))) f))
      (close f))))

(defun sys:load-config (/ f line key val pos)
  "从外部文件加载系统参数到 *SYS:CONFIG*。"
  (if (setq f (open *SYS:CONFIG-FILE* "r"))
    (progn
      (while (setq line (read-line f))
        (if (setq pos (vl-string-search "=" line))
          (progn
            (setq key (vl-catch-all-apply 'read (list (substr line 1 pos)))
                  val (vl-catch-all-apply 'read (list (substr line (+ pos 2)))))
            (if (and (not (vl-catch-all-error-p key))
                     (not (vl-catch-all-error-p val)))
              (setq *SYS:CONFIG* (sys:alist-put *SYS:CONFIG* key val)))))
      (close f))))


;; --- 系统参数默认值 ---

(defun sys:init-defaults nil
  "初始化所有系统参数的默认值。仅在首次加载时设置。"
  (or (sys:get '*SYS:DWG-SCALE*)      (sys:set '*SYS:DWG-SCALE* 100))
  (or (sys:get '*SYS:TEXT-STYLE*)     (sys:set '*SYS:TEXT-STYLE* "TSSD_Rein"))
  (or (sys:get '*SYS:TEXT-FONT*)      (sys:set '*SYS:TEXT-FONT* "tssdeng.shx"))
  (or (sys:get '*SYS:TEXT-BIGFONT*)   (sys:set '*SYS:TEXT-BIGFONT* "hztxt.shx"))
  (or (sys:get '*SYS:TEXT-WIDTH*)     (sys:set '*SYS:TEXT-WIDTH* 0.7))
  (or (sys:get '*SYS:TEXT-HEIGHT*)    (sys:set '*SYS:TEXT-HEIGHT* 350))
  (or (sys:get '*SYS:DIM-PRECISION*)  (sys:set '*SYS:DIM-PRECISION* 2))
  (or (sys:get '*SYS:CLOUD-LAYER*)    (sys:set '*SYS:CLOUD-LAYER* "校图云线"))
  (or (sys:get '*SYS:CLOUD-COLOR*)    (sys:set '*SYS:CLOUD-COLOR* 6))
  (or (sys:get '*SYS:CLOUD-ARC*)      (sys:set '*SYS:CLOUD-ARC* 6))
  (or (sys:get '*SYS:CLOUD-PLOT*)     (sys:set '*SYS:CLOUD-PLOT* 0))
  ;; 工具箱路径（用于查找 DCL 等资源文件）
  (or (sys:get '*SYS:LOAD-PATH*)
      (sys:set '*SYS:LOAD-PATH*
        (vl-string-right-trim "\\"
          (cond
            (*TB:ROOT*)
            ((uc:project-root) (uc:path-join (uc:project-root) "TB-Toolbox"))
            (t (or (getvar "DWGPREFIX") ""))))))
  ;; 结构图层默认值
  (or (sys:get '*PRJ:BEAM-LAYER*)     (sys:set '*PRJ:BEAM-LAYER* "S_BEAM"))
  (or (sys:get '*PRJ:COLUMN-LAYER*)   (sys:set '*PRJ:COLUMN-LAYER* "S_COL"))
  (or (sys:get '*PRJ:WALL-LAYER*)     (sys:set '*PRJ:WALL-LAYER* "S_WALL"))
  (or (sys:get '*PRJ:TEXT-LAYER*)     (sys:set '*PRJ:TEXT-LAYER* "S_TEXT"))
  (or (sys:get '*PRJ:DIM-LAYER*)      (sys:set '*PRJ:DIM-LAYER* "S_DIM"))
  ;; 钢筋参数默认值
  (or (sys:get '*SYS:REBAR-LAYER*)     (sys:set '*SYS:REBAR-LAYER* "S_REBAR"))
  (or (sys:get '*SYS:STIRRUP-LAYER*)   (sys:set '*SYS:STIRRUP-LAYER* "S_STIRRUP"))
  (or (sys:get '*SYS:REBAR-TEXT-LAYER*) (sys:set '*SYS:REBAR-TEXT-LAYER* "S_REBAR_TEXT"))
  (or (sys:get '*SYS:REBAR-WIDTH*)     (sys:set '*SYS:REBAR-WIDTH* 0.5))
  (or (sys:get '*SYS:REBAR-DIAMETER*)  (sys:set '*SYS:REBAR-DIAMETER* 8))
  (or (sys:get '*SYS:REBAR-GRADE*)     (sys:set '*SYS:REBAR-GRADE* 3))
  (or (sys:get '*SYS:REBAR-HOOK*)      (sys:set '*SYS:REBAR-HOOK* 2))
  (or (sys:get '*SYS:REBAR-COVER*)     (sys:set '*SYS:REBAR-COVER* 25)))


;; --- 辅助函数 ---

(defun sys:alist-put (alist key value)
  "在 alist 中设置 key 的值。优先复用统一核心实现。"
  (cond
    ((uc:function-defined-p 'uc:alist-put)
     (uc:alist-put alist key value))
    ((assoc key alist)
     (subst (cons key value) (assoc key alist) alist))
    (t
     (append alist (list (cons key value))))))

(defun sys:clear-temp nil
  "清理所有临时参数。在命令结束时调用。"
  (setq *TMP:VARS* nil)
  (gc))


;; --- 初始化 ---
(sys:load-config)
(sys:init-defaults)


;; ============================================================================
;; 第三节：错误处理框架
;; ============================================================================

;; ============================================================================
;; 第四节：安全工具函数
;; ============================================================================

;; 安全获取实数输入。如果用户直接回车，返回默认值。
;; 如果输入非正数，提示并返回默认值。
(defun safe:get-real (prompt default / val)
  (setq val (getreal (strcat "\n" prompt " <" (rtos (if default default 0.0) 2 2) ">:")))
  (cond
    ((null val) (if default default 0.0))
    ((> val 0) val)
    (t (princ "\n输入必须大于0，使用默认值。") (if default default 0.0))))

(defun safe:get-int (prompt default / val)
  "安全获取整数输入。"
  (setq val (getint (strcat "\n" prompt " <" (itoa (if default default 0)) ">:")))
  (if (and val (> val 0)) val (if default default 0)))

(defun safe:get-dist (prompt pt default / val)
  "安全获取距离输入。保证返回正值。"
  (setq val (if pt (getdist pt (strcat "\n" prompt)) (getdist (strcat "\n" prompt))))
  (cond
    ((null val) default)
    ((> val 0) val)
    (t (princ "\n距离必须大于0。") default)))


;; ============================================================================
;; 第五节：Undo 管理
;; ============================================================================

(defun sys:undo-begin nil
  "开始一个 undo 组。后续操作可一键撤销。"
  (cond
    ((uc:function-defined-p 'uc:undo-begin)
     (uc:undo-begin))
    (*SYS:HAS-ACTIVEX*
     (vl-catch-all-apply
       '(lambda nil
         (vla-StartUndoMark
           (vla-get-ActiveDocument (vlax-get-acad-object))))))
    ((uc:function-defined-p 'uc:command-safe)
     (uc:command-safe '("_.UNDO" "_BEGIN")))
    (t
     (apply 'command '("_.UNDO" "_BEGIN")))))

(defun sys:undo-end nil
  "结束当前 undo 组。"
  (cond
    ((uc:function-defined-p 'uc:undo-end)
     (uc:undo-end))
    (*SYS:HAS-ACTIVEX*
     (vl-catch-all-apply
       '(lambda nil
         (vla-EndUndoMark
           (vla-get-ActiveDocument (vlax-get-acad-object))))))
    ((uc:function-defined-p 'uc:command-safe)
     (uc:command-safe '("_.UNDO" "_END")))
    (t
     (apply 'command '("_.UNDO" "_END")))))


;; ============================================================================
;; 第六节：通用工具
;; ============================================================================

;; 如果 var 为 nil，返回 default；否则返回 var。
;; 用于配置变量的懒初始化：(setq x (sys:ifnil x 100))
(defun sys:ifnil (var default)
  (if var var default))

;; uc:* 命名空间兼容层 — 原设计依赖外部 U-CORE 库函数。
;; 在无外部库时提供本地实现。
(defun uc:function-defined-p (sym)
  "检测符号是否绑定为函数。nil=未定义或非函数。"
  (and sym
       (boundp sym)
       (not (vl-catch-all-error-p
              (vl-catch-all-apply 'type (list (eval sym)))))
       (wcmatch (vl-princ-to-string (type (eval sym))) "*SUBR*")))

(defun uc:command-safe (cmd-list)
  "安全执行 command 列表。捕获错误，不中断流程。"
  (vl-catch-all-apply 'command cmd-list))


;; ============================================================================
;; 第七节：符号表快速检测
;; ============================================================================

(defun sys:layer-exists? (name)
  "检测图层是否存在。"
  (cond
    ((null name) nil)
    ((and (uc:function-defined-p 'uc:layer-exists-p) name)
     (uc:layer-exists-p name))
    (t
     (and (tblsearch "LAYER" name) T))))

(defun sys:style-exists? (name)
  "检测文字样式是否存在。"
  (cond
    ((null name) nil)
    ((and (uc:function-defined-p 'uc:style-exists-p) name)
     (uc:style-exists-p name))
    (t
     (and (tblsearch "STYLE" name) T))))

(defun sys:block-exists? (name)
  "检测图块是否存在。"
  (cond
    ((null name) nil)
    ((and (uc:function-defined-p 'uc:block-exists-p) name)
     (uc:block-exists-p name))
    (t
     (and (tblsearch "BLOCK" name) T))))


(princ "\n[TB] 核心系统加载完成。")
(princ)
