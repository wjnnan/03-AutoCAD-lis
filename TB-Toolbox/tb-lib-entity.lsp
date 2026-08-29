(defun entity:get-dxf (ename code)
  (uc:entity-getdxf ename code))

(defun entity:set-dxf (ename code value)
  (uc:entity-putdxf ename code value))

(defun entity:get-type (ename)
  (uc:entity-type ename))

(defun entity:get-layer (ename)
  (uc:entity-layer ename))

(defun entity:get-color (ename)
  (uc:entity-color ename))

(defun entity:handle (ename)
  (entity:get-dxf ename 5))

(defun entity:get-name (ename)
  (entity:get-dxf ename 2))

(defun entity:make-line (pt1 pt2 layer)
  (entmakex
    (list '(0 . "LINE")
          '(100 . "AcDbEntity")
          '(100 . "AcDbLine")
          (cons 8 (if layer layer "0"))
          (cons 10 pt1)
          (cons 11 pt2))))

(defun entity:make-pline (pts closed layer)
  (entmakex
    (append
      (list '(0 . "LWPOLYLINE")
            '(100 . "AcDbEntity")
            '(100 . "AcDbPolyline")
            (cons 8 (if layer layer "0"))
            (cons 90 (length pts))
            (cons 70 (if closed 1 0)))
      (mapcar '(lambda (pt) (cons 10 pt)) pts))))

(defun entity:make-circle (center radius layer)
  (entmakex
    (list '(0 . "CIRCLE")
          '(100 . "AcDbEntity")
          '(100 . "AcDbCircle")
          (cons 8 (if layer layer "0"))
          (cons 10 center)
          (cons 40 radius))))

(defun entity:make-arc (center radius ang1 ang2 layer)
  (entmakex
    (list '(0 . "ARC")
          '(100 . "AcDbEntity")
          '(100 . "AcDbCircle")
          (cons 8 (if layer layer "0"))
          (cons 10 center)
          (cons 40 radius)
          (cons 50 ang1)
          (cons 51 ang2))))

(defun entity:make-point (pt layer)
  (entmakex
    (list '(0 . "POINT")
          '(100 . "AcDbEntity")
          '(100 . "AcDbPoint")
          (cons 8 (if layer layer "0"))
          (cons 10 pt))))

(defun entity:make-text (str inspt height style layer)
  (entmakex
    (list '(0 . "TEXT")
          '(100 . "AcDbEntity")
          '(100 . "AcDbText")
          (cons 8 (if layer layer "0"))
          (cons 7 (if style style (getvar "TEXTSTYLE")))
          (cons 1 str)
          (cons 10 inspt)
          (cons 40 height)
          (cons 41 (if (sys:get '*SYS:TEXT-WIDTH*) (sys:get '*SYS:TEXT-WIDTH*) 0.7))
          (cons 72 0)
          (cons 73 0))))

(defun entity:make-mtext (str inspt width style layer)
  (entmakex
    (list '(0 . "MTEXT")
          '(100 . "AcDbEntity")
          '(100 . "AcDbMText")
          (cons 8 (if layer layer "0"))
          (cons 7 (if style style (getvar "TEXTSTYLE")))
          (cons 1 str)
          (cons 10 inspt)
          (cons 40 (getvar "TEXTSIZE"))
          (cons 41 width))))

(defun entity:make-layer (name color linetype plot)
  (uc:ensure-layer name color linetype)
  (if (and (tblobjname "LAYER" name) plot)
    (uc:layer-set-dxf name 290 1))
  name)

(defun entity:make-style (name font bigfont width)
  (if (not (tblobjname "STYLE" name))
    (entmakex
      (list '(0 . "STYLE")
            '(100 . "AcDbSymbolTableRecord")
            '(100 . "AcDbTextStyleTableRecord")
            (cons 2 name)
            '(70 . 0)
            '(40 . 0)
            (cons 41 (if width width 0.7))
            (cons 3 (if font font "tssdeng.shx"))
            (cons 4 (if bigfont bigfont "hztxt.shx"))))))

(defun entity:make-block (name ents basept)
  (if (entmakex
        (list '(0 . "BLOCK")
              (cons 2 name)
              '(70 . 0)
              (cons 10 basept)))
    (progn
      (foreach e ents
        (entmake (entget e)))
      (entmakex '((0 . "ENDBLK")))
      name)
    (progn
      (princ (strcat "\n[TB] 创建块定义失败: " name))
      nil)))

(defun entity:make-insert (name inspt xscale yscale zscale rot)
  (entmakex
    (list '(0 . "INSERT")
          '(100 . "AcDbEntity")
          '(100 . "AcDbBlockReference")
          (cons 2 name)
          (cons 10 inspt)
          (cons 41 (if xscale xscale 1.0))
          (cons 42 (if yscale yscale 1.0))
          (cons 43 (if zscale zscale 1.0))
          (cons 50 (if rot rot 0.0)))))

(defun entity:get-bbox (ename offset / result)
  "获取实体包围盒，统一在 ActiveX 和纯 Lisp 路径上应用偏移量。"
  (setq result
    (if *SYS:HAS-ACTIVEX*
      (progn
        (setq result (vl-catch-all-apply 'uc:entity-bbox (list ename)))
        (if (vl-catch-all-error-p result) nil result))
      nil))
  (if (not result)
    (setq result (entity:bbox-pure ename)))
  (if (and result offset (not (equal offset 0 1e-8)))
    (list
      (list (- (caar result) offset) (- (cadar result) offset) (if (caddar result) (caddar result) 0.0))
      (list (+ (caadr result) offset) (+ (cadadr result) offset) (if (caddadr result) (caddadr result) 0.0)))
    result))

(defun entity:bbox-activex (ename / core-res core-box obj-res obj minpt maxpt bbox-res)
  (cond
    ((null ename) nil)
    ((uc:function-defined-p 'uc:entity-bbox)
     (setq core-res (vl-catch-all-apply 'uc:entity-bbox (list ename)))
     (setq core-box
       (if (vl-catch-all-error-p core-res)
         nil
         core-res))
     (if core-box
       core-box
       (entity:bbox-pure ename)))
    ((not *SYS:HAS-ACTIVEX*) nil)
    (t
     (setq obj-res (vl-catch-all-apply 'vlax-ename->vla-object (list ename)))
     (if (vl-catch-all-error-p obj-res)
       (entity:bbox-pure ename)
       (progn
         (setq obj obj-res)
         (setq bbox-res (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'minpt 'maxpt)))
         (if (vl-catch-all-error-p bbox-res)
           (entity:bbox-pure ename)
           (list (vlax-safearray->list minpt)
                 (vlax-safearray->list maxpt))))))))

(defun entity:block-def-bbox (block-name / ename sub-box minpt maxpt sub-name sub-ins)
  "遍历块定义内实体，递归计算块定义坐标系的合并包围盒。"
  (setq ename (tblobjname "BLOCK" block-name))
  (if (not ename) nil
    (progn
      (setq minpt nil maxpt nil)
      (setq ename (entnext ename))
      (while (and ename (/= (entity:get-type ename) "ENDBLK"))
        ;; 嵌套块：递归取块定义 bbox 后平移（简化：忽略嵌套缩放/旋转）
        (if (= (entity:get-type ename) "INSERT")
          (progn
            (setq sub-name (entity:get-name ename)
                  sub-ins  (entity:get-dxf ename 10))
            (setq sub-box (entity:block-def-bbox sub-name))
            (if (and sub-box sub-ins)
              (setq sub-box
                (list
                  (mapcar '+ (car sub-box) sub-ins)
                  (mapcar '+ (cadr sub-box) sub-ins)))))
          (setq sub-box (entity:bbox-pure ename)))
        (if sub-box
          (progn
            (if (null minpt)
              (setq minpt (car sub-box) maxpt (cadr sub-box))
              (progn
                (setq minpt (mapcar 'min minpt (car sub-box))
                      maxpt (mapcar 'max maxpt (cadr sub-box)))))))
        (setq ename (entnext ename)))
      (if minpt (list minpt maxpt) nil))))

(defun entity:block-bbox-pure (ename / name inspt xscale yscale rot def-box p1 p2 corners)
  "纯 Lisp 计算 INSERT 块引用的包围盒（无 COM 平台用）。
  遍历块定义取块坐标 bbox，应用缩放 + 90 度倍数旋转 + 平移变换。"
  (setq name   (entity:get-name ename)
        inspt  (entity:get-dxf ename 10)
        xscale (if (entity:get-dxf ename 41) (entity:get-dxf ename 41) 1.0)
        yscale (if (entity:get-dxf ename 42) (entity:get-dxf ename 42) 1.0)
        rot    (if (entity:get-dxf ename 50) (entity:get-dxf ename 50) 0.0))
  (setq def-box (entity:block-def-bbox name))
  (if (not def-box)
    (list inspt inspt)
    (progn
      (setq p1 (list (* (caar def-box) xscale) (* (cadar def-box) yscale))
            p2 (list (* (caadr def-box) xscale) (* (cadadr def-box) yscale)))
      ;; 缩放后的 4 个角点
      (setq corners
        (list (list (car p1) (cadr p1))
              (list (car p2) (cadr p1))
              (list (car p2) (cadr p2))
              (list (car p1) (cadr p2))))
      ;; 90 度倍数旋转 + 平移
      (setq corners
        (mapcar
          '(lambda (c / r)
             (setq r
               (cond
                 ((equal (rem rot pi) 0 1e-8) c)  ; 0/180 度：不变
                 ((equal (rem rot (* pi 0.5)) 0 1e-8)  ; 90/270 度：交换坐标
                  (list (- (cadr c)) (car c)))
                 (t c)))  ; 非直角：近似不旋转
             (mapcar '+ r inspt))
          corners))
      (list
        (list (apply 'min (mapcar 'car corners))
              (apply 'min (mapcar 'cadr corners))
              0.0)
        (list (apply 'max (mapcar 'car corners))
              (apply 'max (mapcar 'cadr corners))
              0.0)))))

(defun entity:bbox-pure (ename / typ pts pt inspt)
  "纯 Lisp 包围盒计算。TEXT 的 textbox 返回相对坐标，须加上插入点转为世界坐标。"
  (setq typ (entity:get-type ename))
  (cond
    ((null typ) (list '(0 0 0) '(0 0 0)))
    ((= typ "TEXT")
     (setq inspt (entity:get-dxf ename 10)
           pts (textbox (entget ename)))
     (if pts
       (list (mapcar '+ inspt (car pts))
             (mapcar '+ inspt (cadr pts)))
       (list inspt inspt)))
    ((wcmatch typ "LWPOLYLINE,LINE,CIRCLE,ARC,*POLYLINE,ELLIPSE,SPLINE")
     (point:bbox (curve:vertices ename)))
    ((= typ "INSERT")
     (entity:block-bbox-pure ename))
    (t
     (list '(0 0 0) '(0 0 0)))))

(defun entity:get-attribs (ename)
  (uc:block-attributes ename))

(defun entity:set-attrib (ename tag value)
  (if (and (= (entity:get-type ename) "INSERT")
           (= (entity:get-dxf ename 66) 1))  ; 66=1 表示有属性跟随
    (while (and (setq ename (entnext ename))
                (= (entity:get-type ename) "ATTRIB"))
      (if (= (entity:get-dxf ename 2) tag)
        (progn
          (entity:set-dxf ename 1 value)
          (entupd ename))))))

(defun entity:update (ename)
  (entupd ename))

(princ "\n[TB] entity library loaded (entity:*)")
(princ)
