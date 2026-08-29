;;; tb-lib-rebar-edit.lsp — 钢筋标注解析与编辑库
;;; 钢筋标注解析、配筋面积计算、编号规则引擎
;;; 依赖：tb-core.lsp, tb-lib-entity.lsp, tb-lib-txt.lsp
;;;
;;; 标注格式支持：
;;;   纵筋: "4%%13225" → 4Φ25        腰筋: "G4%%13212" → G4Φ12
;;;   箍筋: "%%1328@200" → Φ8@200    板筋: "%%13210@150" → Φ10@150
;;;   多层: "4%%13225 2/2" → 4Φ25 2/2 加密: "%%13210@100/200"


;; ============================================================================
;; 钢筋符号映射
;; ============================================================================

(setq *REBAR:CODES*
  '(("%%130" . 1)   ; 一级钢 Φ (HPB300)
    ("%%131" . 2)   ; 二级钢 Φ (HRB335)
    ("%%132" . 3))) ; 三级钢 Φ (HRB400)

(defun rebar:code-to-grade (code)
  "钢筋代号 → 等级。\"%%130\"→1, \"%%131\"→2, \"%%132\"→3。"
  (cdr (assoc code *REBAR:CODES*)))

(defun rebar:find-code-in-str (str)
  "在字符串中查找钢筋代号，返回 (code . grade) 或 nil。"
  (car (vl-remove nil
    (mapcar '(lambda (pair)
      (if (vl-string-search (car pair) str) pair nil))
      *REBAR:CODES*))))


;; ============================================================================
;; 标注解析
;; ============================================================================

(defun rebar:parse-annotation (str / code grade count d s top-row bot-row
                                    waist-type brace raw code-pair clean pos
                                    brace-pos brace-count d-str i at-pos
                                    slash-pos type area total-area area-per-m
                                    prefix parts)
  "解析钢筋标注文字，返回属性表。
  返回: ((type . \"longitudinal\") (count . 4) (diameter . 25) (grade . 3)
         (spacing . nil) (top-row . 2) (bot-row . 2) (waist . nil)
         (area . 1963.5) (raw . \"4%%13225\"))"

  (setq raw str)

  ;; 查找钢筋符号
  (setq code-pair (rebar:find-code-in-str str))
  (if (not code-pair)
    (list (cons 'type "unknown") (cons 'raw str))
    (progn
      (setq code  (car code-pair)
            grade (cdr code-pair)
            ;; 将符号替换为占位符方便解析
            clean (vl-string-subst "|" code str))

      ;; 初始化
      (setq count nil d nil s nil top-row nil bot-row nil waist-type nil)

      ;; 检测腰筋前缀 G/N
      (cond
        ((wcmatch clean "G*")
         (setq waist-type "G" clean (substr clean 2)))
        ((wcmatch clean "N*")
         (setq waist-type "N" clean (substr clean 2))))

      ;; 解析数量前缀（跳过 "|" 占位符: +2 = 跳过 "|"）
      (if (setq pos (vl-string-search "|" clean))
        (progn
          (setq prefix (substr clean 1 pos))
          (if (and (> (strlen prefix) 0)
                   (numberp (read prefix)))
            (setq count (atoi prefix)
                  clean (substr clean (+ pos 2)))
            (setq clean (substr clean (+ pos 2))))))

      ;; 检测箍筋肢数 "(2)"
      (if (setq brace-pos (vl-string-search "(" clean))
        (progn
          (setq brace-count (atoi (substr clean (1+ brace-pos))))
          (setq clean (substr clean 1 brace-pos))))

      ;; 解析直径
      (setq d-str "")
      (setq i 1)
      (while (and (<= i (strlen clean))
                  (or (<= 48 (ascii (substr clean i 1)) 57)
                      (= (ascii (substr clean i 1)) 46)))
        (setq d-str (strcat d-str (substr clean i 1)))
        (setq i (1+ i)))
      (if (> (strlen d-str) 0)
        (setq d (atof d-str)))

      ;; 解析间距 @
      (if (setq at-pos (vl-string-search "@" clean))
        (setq s (atoi (substr clean (+ at-pos 2)))))

      ;; 解析分排 2/2（只有不包含 @ 时才是分排格式）
      (if (and (not (vl-string-search "@" clean))
               (setq slash-pos (vl-string-search "/" clean)))
        (progn
          (setq parts (str:split clean "/"))
          (if (and (cadr parts) (numberp (read (cadr parts))))
            (setq top-row (atoi (car parts))
                  bot-row (atoi (cadr parts))))))

      ;; 判断类型
      (setq type
        (cond
          (s "stirrup")           ; 有@间距 → 箍筋/板筋
          (waist-type "waist")    ; G/N腰筋
          (count (if (> count 1) "longitudinal" "single"))
          (t "longitudinal")))

      ;; 计算面积
      (if d
        (setq area (* pi 0.25 d d)                        ; 单根面积
              total-area (if count (* count area) area)   ; 总配筋面积
              area-per-m (if s (* area (/ 1000.0 s)) nil)))   ; 每米面积

      ;; 返回属性表
      (list
        (cons 'type       type)
        (cons 'grade      grade)
        (cons 'diameter   d)
        (cons 'count      count)
        (cons 'spacing    s)
        (cons 'area       total-area)
        (cons 'area-per-m area-per-m)
        (cons 'top-row    top-row)
        (cons 'bot-row    bot-row)
        (cons 'waist      waist-type)
        (cons 'brace      brace-count)
        (cons 'raw        raw)))))


;; ============================================================================
;; 面积计算
;; ============================================================================

(defun rebar:calc-area (d)
  "单根钢筋面积 mm2。"
  (* pi 0.25 d d))

(defun rebar:calc-total-area (n d)
  "总配筋面积 mm2。"
  (* n (rebar:calc-area d)))

(defun rebar:calc-area-per-meter (d s)
  "每米配筋面积 mm2/m。"
  (if (and d s (> s 0))
    (* (rebar:calc-area d) (/ 1000.0 s))
    0.0))

(defun rebar:find-min-diameter (area-required grade / dias found)
  "根据所需面积反推最小直径。常用直径: 6,8,10,12,14,16,18,20,22,25,28,32"
  (setq dias '(6 8 10 12 14 16 18 20 22 25 28 32)
        found nil)
    (foreach d dias
      (if (and (not found) (>= (rebar:calc-area d) area-required))
        (setq found d)))
    found)


;; ============================================================================
;; 钢筋标注格式化
;; ============================================================================

(defun rebar:format-annotation (props / code type count d s waist top bot brace)
  "将解析后的属性表格式化为钢筋标注字符串。"
  (setq code (cond ((= (cdr (assoc 'grade props)) 1) "%%130")
                   ((= (cdr (assoc 'grade props)) 2) "%%131")
                   (t "%%132"))
        type (cdr (assoc 'type props))
        count (cdr (assoc 'count props))
        d     (cdr (assoc 'diameter props))
        s     (cdr (assoc 'spacing props))
        waist (cdr (assoc 'waist props))
        top   (cdr (assoc 'top-row props))
        bot   (cdr (assoc 'bot-row props))
        brace (cdr (assoc 'brace props)))

  (strcat
    ;; 腰筋前缀
    (if waist waist "")
    ;; 根数 + 代号 + 直径
    (if count (strcat (itoa count) code (rtos d 2 0)) (strcat code (rtos d 2 0)))
    ;; 间距
    (if s (strcat "@" (itoa s)) "")
    ;; 肢数
    (if brace (strcat "(" (itoa brace) ")") "")
    ;; 分排
    (if (and top bot) (strcat " " (itoa top) "/" (itoa bot)) "")))


;; ============================================================================
;; 常用配筋方案推荐
;; ============================================================================

(defun rebar:suggest-alternatives (props / d area type target-area n dias alts)
  "根据当前配筋推荐替代方案。（更大/更小直径或不同间距）"
  (setq d    (cdr (assoc 'diameter props))
        area (cdr (assoc 'area props))
        type (cdr (assoc 'type props)))

  (if (not d) nil
    (progn
      (setq dias  '(6 8 10 12 14 16 18 20 22 25 28 32)
            alts  nil
            target-area (if area area (rebar:calc-area d)))

      (if (eq type 'stirrup)
        ;; 箍筋：推荐不同间距
        (progn
          (foreach sp '(100 125 150 200 250)
            (setq alts (cons
              (list (cons 'diameter d) (cons 'spacing sp)
                    (cons 'area-per-m (rebar:calc-area-per-meter d sp)))
              alts))))
        ;; 纵筋：推荐不同直径/根数
        (progn
          (foreach d2 dias
            (if (not (= d2 d))
              (progn
                (setq n (max 1 (fix (+ 0.5 (/ target-area (rebar:calc-area d2))))))
                (setq alts (cons
                  (list (cons 'diameter d2) (cons 'count n)
                        (cons 'area (rebar:calc-total-area n d2)))
                  alts)))))))
      (reverse alts))))


;; ============================================================================
;; 工具函数：字符串分割
;; ============================================================================

(defun str:split (str delim / pos result)
  "按分隔符分割字符串。"
  (if (= (strlen delim) 0)
    (list str)
    (progn
      (while (setq pos (vl-string-search delim str))
        (setq result (cons (substr str 1 pos) result)
              str    (substr str (+ pos (strlen delim) 1))))
      (reverse (cons str result)))))


(princ "\n[TB] 钢筋标注解析库加载完成 (rebar:parse/calc/format)")
(princ)
