;;; tb-mod-rebar-edit.lsp — 钢筋标注编辑模块
;;; 组合 rebar:* entity:* txt:* sel:* point:* 库函数
;;; 提供：智能编辑、实时面积、编号管理、镜像、双击编辑

;; ============================================================================
;; c:RE — 钢筋标注智能编辑器
;; ============================================================================

(defun c:RE (/ e str props d count s grade type area area-m new-str choice alt
              new-count new-d new-s new-grade alts i idx new-props)
  "智能编辑钢筋标注。选文字 → 自动解析 → 交互修改。
   c:RED/c:REDB 可通过 *RE:EDIT-ENTITY* 传入预选实体。"
  (setq e (or *RE:EDIT-ENTITY* (car (entsel "\n选择钢筋标注文字: ")))
        *RE:EDIT-ENTITY* nil)
  (if e
    (if (wcmatch (entity:get-type e) "TEXT,MTEXT")
      (progn
        (setq str   (txt:get-content e)
              props (rebar:parse-annotation str))

        ;; 显示解析结果
        (princ (strcat
          "\n═══════ 钢筋标注解析 ═══════"
          "\n  原文:   " str
          "\n  类型:   " (cdr (assoc 'type props))
          "\n  等级:   " (itoa (cdr (assoc 'grade props))) "级钢"
          "\n  直径:   " (rtos (cdr (assoc 'diameter props)) 2 0) "mm"))

        (if (cdr (assoc 'count props))
          (princ (strcat "\n  根数:   " (itoa (cdr (assoc 'count props))))))

        (if (cdr (assoc 'spacing props))
          (princ (strcat "\n  间距:   @" (itoa (cdr (assoc 'spacing props))))))

        (if (cdr (assoc 'area props))
          (princ (strcat "\n  总面积: " (rtos (cdr (assoc 'area props)) 2 1) " mm²")))

        (if (cdr (assoc 'area-per-m props))
          (princ (strcat "\n  每米面积: " (rtos (cdr (assoc 'area-per-m props)) 2 1) " mm²/m")))

        (princ "\n──────────────────────────")

        ;; 推荐替代方案
        (setq alts (rebar:suggest-alternatives props))
        (if alts
          (progn
            (princ "\n  备选方案：")
            (setq i 0)
            (foreach alt alts
              (setq i (1+ i))
              (princ (strcat "\n  [" (itoa i) "] "
                (if (cdr (assoc 'count alt))
                  (strcat (itoa (cdr (assoc 'count alt))) "%%132" (rtos (cdr (assoc 'diameter alt)) 2 0)))
                (if (cdr (assoc 'spacing alt))
                  (strcat "@" (itoa (cdr (assoc 'spacing alt)))))
                "  As=" (rtos (or (cdr (assoc 'area alt))
                                  (cdr (assoc 'area-per-m alt))) 2 1) "mm²")))))

        (princ "\n══════════════════════════")
        (princ "\n  [M]手动修改  [数字]选方案  [回车]退出")

        ;; 获取用户选择
        (setq choice (getstring "\n选择: "))

        (cond
          ;; 手动修改
          ((= (strcase choice) "M")
           (setq new-d (safe:get-real "直径(mm)" (or (cdr (assoc 'diameter props)) 8)))

           (initget "1 2 3")
           (setq new-grade (getint (strcat "\n等级 [1一级/2二级/3三级] <"
                                          (itoa (cdr (assoc 'grade props))) ">: ")))
           (if (not new-grade) (setq new-grade (cdr (assoc 'grade props))))

           (if (eq (cdr (assoc 'type props)) 'stirrup)
             (setq new-s (safe:get-real "间距(mm)" (or (cdr (assoc 'spacing props)) 200)))
             (setq new-count (safe:get-int "根数" (or (cdr (assoc 'count props)) 4))))

           ;; 构建新标注
           (setq new-props (list
             (cons 'grade new-grade)
             (cons 'diameter new-d)
             (cons 'type (cdr (assoc 'type props)))
             (cons 'count (if new-count new-count (cdr (assoc 'count props))))
             (cons 'spacing (if new-s new-s (cdr (assoc 'spacing props))))))
           (setq new-str (rebar:format-annotation new-props)))

          ;; 选择替代方案
          ((and choice (numberp (read choice)))
           (setq idx (atoi choice))
           (if (and alts (>= idx 1) (<= idx (length alts)))
             (progn
               (setq alt (nth (1- idx) alts))
               (setq new-props (list
                 (cons 'grade (cdr (assoc 'grade props)))
                 (cons 'diameter (cdr (assoc 'diameter alt)))
                 (cons 'type (cdr (assoc 'type props)))
                 (cons 'count (cdr (assoc 'count alt)))
                 (cons 'spacing (cdr (assoc 'spacing alt)))))
               (setq new-str (rebar:format-annotation new-props)))))))

        ;; 应用修改
        (if new-str
          (progn
            (txt:set-content e new-str)
            (entity:update e)
            (princ (strcat "\n已更新: " new-str)))))

    (princ "\n所选不是文字实体。"))
  (princ))


;; ============================================================================
;; c:RA — 实时配筋面积显示
;; ============================================================================

(defun c:RA (/ gr pt ss e str props area type d)
  "实时配筋面积显示。鼠标悬停在钢筋标注上，状态栏显示配筋面积。
  按ESC或右键退出。"
  (princ "\n[实时面积] 鼠标移动到钢筋标注上查看配筋面积...")
  (princ "\n[实时面积] 按ESC或鼠标右键退出。")

  (setq *RA:ACTIVE* T)
  (while *RA:ACTIVE*
    (setq gr (grread T 4 2))  ; 跟踪鼠标，允许右键

    (cond
      ;; 鼠标移动 (code=5)
      ((= (car gr) 5)
       (setq pt (cadr gr))
       ;; 检测光标下的文字
       (if (setq ss (ssget pt '((0 . "TEXT,MTEXT"))))
         (progn
           (setq e   (ssname ss 0)
                 str (txt:get-content e)
                 props (rebar:parse-annotation str))

           (if (and props (cdr (assoc 'diameter props)))
             (progn
               (setq type (cdr (assoc 'type props))
                     d    (cdr (assoc 'diameter props)))

               (princ (strcat "\r[面积] " str "  →  "))

               (if (cdr (assoc 'area props))
                 (princ (strcat "As=" (rtos (cdr (assoc 'area props)) 2 1) "mm²")))

               (if (cdr (assoc 'area-per-m props))
                 (princ (strcat "  As/m=" (rtos (cdr (assoc 'area-per-m props)) 2 1) "mm²/m")))

               (princ "    "))  ; 防止残留字符
             (princ (strcat "\r[面积] 未识别钢筋标注    "))))))

      ;; 鼠标点击 (code=3) 或按键 → 退出
      ((= (car gr) 3)
       (setq *RA:ACTIVE* nil))

      ((= (car gr) 2)  ; 键盘输入
       (setq *RA:ACTIVE* nil))

      ;; 右键或 ESC
      ((or (= (car gr) 11) (= (car gr) 25))
       (setq *RA:ACTIVE* nil))))
  (princ "\n[实时面积] 已退出。")
  (princ))


;; ============================================================================
;; c:RN — 钢筋编号管理
;; ============================================================================

(defun c:RN (/ ss prefix start-num sort-dir e midpt num num-str existing-nums existing-texts max-num
              dupes missing sorted-nums prev ents new-str count)
  "钢筋编号管理系统。框选钢筋标注 → 自动编号 → 检测重号/漏号。"
  (princ "\n[钢筋编号] 选择要编号的钢筋标注文字...")

  (if (setq ss (ssget '((0 . "TEXT,MTEXT"))))
    (progn
      ;; 获取编号参数
      (setq prefix (getstring T "\n编号前缀（如 GJ-, RB-, 回车无前缀）: "))

      ;; 检测已有编号
      (setq existing-nums nil
            existing-texts nil
            max-num 0)
      (sel:for-each ss
        '(lambda (e / str num)
           (setq str (txt:get-content e))
           ;; 尝试匹配已有编号格式：前缀+数字+#
           (if (wcmatch str "*#")
             (progn
               (setq num-str (vl-string-right-trim "#" str))
               (if (numberp (read num-str))
                 (progn
                   (setq num (atoi num-str))
                   (setq existing-nums (cons num existing-nums)
                         existing-texts (cons (cons num e) existing-texts))
                   (if (> num max-num) (setq max-num num)))))))))

      ;; 检测问题
      (if existing-nums
        (progn
          ;; 检测重号
          (setq dupes (duplicates existing-nums))
          (if dupes
            (princ (strcat "\n⚠ 发现重号: " (vl-princ-to-string dupes))))

          ;; 检测漏号
          (setq sorted-nums (vl-sort existing-nums '<))
          (setq missing nil)
          (setq prev (1- (car sorted-nums)))
          (foreach n sorted-nums
            (if (> (- n prev) 1)
              (setq missing (append missing (range (1+ prev) (1- n)))))
            (setq prev n))
          (if missing
            (princ (strcat "\n⚠ 发现漏号: " (vl-princ-to-string missing))))))

      ;; 询问起始编号
      (setq start-num (safe:get-int
        (strcat "起始编号 <" (itoa (if (> max-num 0) (1+ max-num) 1)) ">")
        (if (> max-num 0) (1+ max-num) 1)))

      ;; 排序方向
      (initget "X Y L R U D")
      (setq sort-dir (getkword "\n排序方向 [X左→右/Y下→上/L左→右/R右→左/U下→上/D上→下] <X>: "))
      (if (not sort-dir) (setq sort-dir "X"))

      ;; 按位置排序
      (setq ents (sel:to-list ss))
      ;; 过滤已有编号的实体
      (setq ents (vl-remove-if
        '(lambda (e) (assoc e (mapcar '(lambda (x) (cons (cdr x) (car x))) existing-texts)))
        ents))
      ;; 按坐标排���
      ;; vl-sort 会破坏原表且去重，先 copy
      (setq ents
        (vl-sort (append ents nil)
          (cond
            ((member sort-dir '("X" "L"))
             '(lambda (e1 e2) (< (car (txt:get-inspt e1)) (car (txt:get-inspt e2)))))
            ((= sort-dir "R")
             '(lambda (e1 e2) (> (car (txt:get-inspt e1)) (car (txt:get-inspt e2)))))
            ((= sort-dir "D")
             '(lambda (e1 e2) (> (cadr (txt:get-inspt e1)) (cadr (txt:get-inspt e2)))))
            (t  ;; Y, U: 下→上 (Y 值从小到大)
             '(lambda (e1 e2) (< (cadr (txt:get-inspt e1)) (cadr (txt:get-inspt e2))))))))

      ;; 执行编号
      (setq num start-num
            count 0)
      (foreach e ents
        (setq midpt (txt:get-inspt e)
              new-str (strcat prefix (itoa num) "#"))
        (txt:set-content e new-str)
        (entity:update e)
        (setq num (1+ num)
              count (1+ count)))

      (princ (strcat "\n[钢筋编号] 已编号 " (itoa count) " 个，"
                     (if existing-nums (strcat "保留 " (itoa (length existing-nums)) " 个已有编号") "")
                     (if dupes "\n  请手动处理重号！" "")
                     (if missing "\n  请手动处理漏号！" "")))
    (princ "\n[钢筋编号] 未选择文字。"))
  (princ))


;; 辅助：检测重复元素
(defun duplicates (lst / seen dups)
  (setq seen nil dups nil)
  (foreach x lst
    (if (member x seen)
      (if (not (member x dups)) (setq dups (cons x dups)))
      (setq seen (cons x seen))))
  (reverse dups))

;; 辅助：生成数字范围
(defun range (from to / lst)
  (while (<= from to)
    (setq lst (cons from lst)
          from (1+ from)))
  (reverse lst))


;; ============================================================================
;; c:RM — 钢筋镜像（弯钩方向自动修正）
;; ============================================================================

(defun c:RM (/ ss p1 p2 ang)
  "钢筋镜像。镜像钢筋并自动修正弯钩方向。"
  (if (setq ss (ssget '((0 . "LWPOLYLINE"))))
    (if (and (setq p1 (getpoint "\n镜像轴第一点: "))
             (setq p2 (getpoint p1 "\n镜像轴第二点: ")))
      (progn
        (setq ang (point:angle p1 p2))

        ;; 镜像 + 自动修正弯钩
        (sel:for-each ss
          '(lambda (e / new-e start-hook end-hook start-sign end-sign
                       d grade width layer)
             (if (rebar:is-rebar? e)
               (progn
                 ;; 保存原始属性（含弯钩方向符号）
                 (setq start-hook (rebar:detect-hook-end e 'start)
                       end-hook   (rebar:detect-hook-end e 'end)
                       start-sign (rebar:get-hook-sign e 'start)
                       end-sign   (rebar:get-hook-sign e 'end)
                       width      (rebar:get-width e)
                       layer      (entity:get-layer e))

                 ;; 执行镜像
                 (command "_.MIRROR" e "" p1 p2 "_N")
                 (setq new-e (entlast))

                 ;; 弯钩方向取反（镜像 = 手性翻转）
                 (if (> start-hook 0)
                   (progn
                     (rebar:remove-hook new-e 'start)
                     (setq new-e (rebar:add-hook new-e 'start start-hook (- start-sign)
                                   (sys:get '*SYS:REBAR-DIAMETER*)
                                   (sys:get '*SYS:REBAR-GRADE*)))))

                 (if (> end-hook 0)
                   (progn
                     (rebar:remove-hook new-e 'end)
                     (setq new-e (rebar:add-hook new-e 'end end-hook (- end-sign)
                                   (sys:get '*SYS:REBAR-DIAMETER*)
                                   (sys:get '*SYS:REBAR-GRADE*)))))))))

        (princ "\n钢筋镜像完成（弯钩已自动修正）。"))
      (princ "\n钢筋镜像已取消。"))
    (princ "\n未选择钢筋。"))
  (princ))


;; ============================================================================
;; c:RED — 双击编辑（注册为双击动作或直接调用）
;; ============================================================================

(defun c:RED (/ e str props)
  "双击钢筋标注编辑。自动识别文字是否为钢筋标注。
  如为钢筋标注则打开编辑器，否则调用标准 DDEDIT。
  可在 AutoCAD CUI 中将 TEXT/MTEXT 双击动作绑定到此命令。"
  (if (setq e (car (entsel)))
    (if (wcmatch (entity:get-type e) "TEXT,MTEXT")
      (progn
        (setq str (txt:get-content e))
        (if (rebar:find-code-in-str str)
          (progn (setq *RE:EDIT-ENTITY* e) (c:RE))
          (command "_.DDEDIT" e "")))
    (princ "\n不是文字实体。")))
  (princ))


;; ============================================================================
;; c:REDB — 双击编辑 + 自动面积比较
;; ============================================================================

(defun c:REDB (/ e str props area new-str new-props new-area)
  "双击编辑（增强版）。编辑前后显示面积变化对比。
  绑定到双击事件可获得 FoolEngineer 式的交互体验。"
  (if (setq e (car (entsel "\n选择钢筋标注（双击编辑模式）: ")))
    (if (wcmatch (entity:get-type e) "TEXT,MTEXT")
      (progn
        (setq str   (txt:get-content e)
              props (rebar:parse-annotation str)
              area  (cdr (assoc 'area props)))

        (if area
          (princ (strcat "\n[当前] " str "  As=" (rtos area 2 1) "mm²")))

        ;; 调用智能编辑器（传入预选实体）
        (setq *RE:EDIT-ENTITY* e)
        (c:RE)

        ;; 显示对比
        (if area
          (progn
            (setq new-str   (txt:get-content e)
                  new-props (rebar:parse-annotation new-str)
                  new-area  (cdr (assoc 'area new-props)))
            (if new-area
              (princ (strcat "\n[修改后] " new-str "  As=" (rtos new-area 2 1) "mm²"
                      "  (变化: " (if (> new-area area) "+" "")
                      (rtos (- new-area area) 2 1) "mm²)"))))))
      (princ "\n不是文字实体。")))
  (princ))


(princ "\n[TB] 钢筋编辑模块加载完成 (rebar-edit: 6命令)")
(princ)
