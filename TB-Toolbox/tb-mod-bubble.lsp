;;; tb-mod-bubble.lsp — 球标编号模块
;;; 创建带圆圈和引线的编号标记。不使用反应器，跨平台兼容。
;;; 组合 entity:* point:* curve:* 库函数

(defun c:qb (/ pt text-h radius inspt endpt leader-en number circ-en text-en)
  (uc:guard-begin '())
  "球标编号。指定位置 → 自动创建编号圆圈 + 引线。
数字自动递增（基于图纸中已存在的编号块）。"
  ;; 初始化参数
  (setq text-h    (sys:get '*SYS:TEXT-HEIGHT*)
        radius    (* 0.6 text-h)  ; 圆半径 = 0.6倍字高
        blk-name  "TB_BUBBLE")

  ;; 创建球标块定义（如果不存在）
  (if (not (uc:block-exists-p blk-name))
    (progn
      ;; 先确保 TSSD_Rein 文字样式存在，避免 ATTDEF 引用缺失样式
      (entity:make-style "TSSD_Rein" "tssdeng.shx" "hztxt.shx" 0.7)
      (setq circ-en (entity:make-circle '(0 0 0) radius "0")
            text-en (entmakex (list '(0 . "ATTDEF")
                               '(100 . "AcDbEntity")
                               '(100 . "AcDbText")
                               '(100 . "AcDbAttributeDefinition")
                               (cons 1 "1")
                               (cons 2 "NUMS")
                               (cons 10 '(0.0 0.0 0.0))
                               (cons 40 text-h)
                               (cons 7 "TSSD_Rein")
                               (cons 8 "0")
                               '(72 . 1)
                               '(73 . 2)
                               (cons 11 '(0.0 0.0 0.0)))))
      (if (and circ-en text-en)
        (progn
          (entity:set-dxf text-en 72 1)  ; 水平居中
          (entity:set-dxf text-en 73 2)  ; 垂直居中
          (entity:set-dxf text-en 11 '(0 0 0))  ; 对齐点
          ;; 用 entmake 建块（避免 _.BLOCK 对话框命令）
          (entity:make-block blk-name (list circ-en text-en) '(0 0 0))))))

  ;; 用户交互
  (if (setq inspt (getpoint "\n球标位置: "))
    (progn
      ;; 计算编号（当前图纸中 +1）
      (setq ss (ssget "X" (list '(0 . "INSERT") (cons 2 blk-name))))
      (setq number (1+ (sel:count ss)))

      ;; 插入带属性的球标（entmake INSERT + ATTRIB + SEQEND，DXF 66=1）
      (if (entmakex (list '(0 . "INSERT") '(100 . "AcDbEntity")
                          '(100 . "AcDbBlockReference") '(66 . 1)
                          (cons 2 blk-name) (cons 10 inspt)
                          '(41 . 1.0) '(42 . 1.0) '(43 . 1.0) '(50 . 0.0)))
        (progn
          (entmake (list '(0 . "ATTRIB") '(100 . "AcDbEntity")
                         '(100 . "AcDbText") '(100 . "AcDbAttribute")
                         (cons 10 inspt) (cons 40 text-h)
                         (cons 1 (itoa number)) (cons 2 "NUMS")
                         (cons 7 "TSSD_Rein") '(72 . 1) '(73 . 2)
                         (cons 11 inspt)))
          (entmake '((0 . "SEQEND")))))

      ;; 绘制引线
      (if (setq endpt (getpoint inspt "\n引线终点（回车跳过）: "))
        (progn
          (setq leader-en (entity:make-line inspt endpt "0"))
          ;; 引线端点用箭头
          (command "_.LEADER" endpt (point:polar endpt (angle endpt inspt) 10) "" "_N")))

      (princ (strcat "\n球标编号: " (itoa number)))))
  (princ)
  (uc:guard-end))


(princ "\n[TB] 球标编号模块加载完成 (bubble: 1命令)")
(princ)
