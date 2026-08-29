;;; tb-mod-layer.lsp — 图层管理模块
;;; 组合 lay:* 库函数，提供用户交互的图层命令。
;;; 不依赖 ActiveX——全部通过 entmod 实现。
;;;
;;; 原文件来源：F:\结构插件\图层.lsp（12命令）— 100% ActiveX → 全部重写

;; ============================================================================
;; 图层关闭 / 反关
;; ============================================================================

(defun c:tg (/ ss lays)
  (uc:guard-begin '())
  "选择实体，关闭其所在图层。"
  (if (setq ss (ssget))
    (progn
      (sel:for-each ss
        '(lambda (e) (lay:off (entity:get-layer e))))
      (princ "\n已关闭所选对象的图层。")))
  (princ)
  (uc:guard-end))

(defun c:tgf (/ ss keep-lays)
  (uc:guard-begin '())
  "选择实体，关闭除所选图层外的所有图层（图层隔离-关闭方式）。"
  (if (setq ss (ssget))
    (progn
      (setq keep-lays (mapcar 'entity:get-layer (sel:to-list ss)))
      (lay:off-all-except keep-lays)
      (princ "\n已关闭除所选外的所有图层。")))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 图层冻结 / 反冻
;; ============================================================================

(defun c:td (/ ss current)
  (uc:guard-begin '())
  "选择实体，冻结其所在图层（不能冻结当前层）。"
  (setq current (getvar "CLAYER"))
  (if (setq ss (ssget))
    (sel:for-each ss
      '(lambda (e / l)
         (setq l (entity:get-layer e))
         (if (/= l current) (lay:freeze l)))))
  (princ "\n已冻结所选对象的图层（当前层除外）。")
  (princ)
  (uc:guard-end))

(defun c:tdf (/ ss keep-lays)
  (uc:guard-begin '())
  "选择实体，冻结除所选外的所有图层。"
  (if (setq ss (ssget))
    (progn
      (setq keep-lays (mapcar 'entity:get-layer (sel:to-list ss)))
      (lay:thaw-all)
      (lay:foreach
        '(lambda (name)
           (if (not (member name keep-lays))
             (lay:freeze name))))
      (princ "\n已冻结除所选外的所有图层。")))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 图层锁定 / 反锁
;; ============================================================================

(defun c:ts (/ ss)
  (uc:guard-begin '())
  "选择实体，锁定其所在图层。"
  (if (setq ss (ssget))
    (progn
      (sel:for-each ss '(lambda (e) (lay:lock (entity:get-layer e))))
      (princ "\n已锁定所选对象的图层。")))
  (princ)
  (uc:guard-end))

(defun c:tsf (/ ss keep-lays)
  (uc:guard-begin '())
  "选择实体，锁定除所选外的所有图层。"
  (if (setq ss (ssget))
    (progn
      (setq keep-lays (mapcar 'entity:get-layer (sel:to-list ss)))
      (lay:unlock-all)
      (lay:foreach
        '(lambda (name)
           (if (not (member name keep-lays))
             (lay:lock name))))
      (princ "\n已锁定除所选外的所有图层。")))
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 全局操作
;; ============================================================================

(defun c:tdj nil
  (uc:guard-begin '())
  "解冻所有图层。"
  (lay:thaw-all)
  (princ "\n所有图层已解冻。")
  (princ)
  (uc:guard-end))

(defun c:tsj nil
  (uc:guard-begin '())
  "解锁所有图层。"
  (lay:unlock-all)
  (princ "\n所有图层已解锁。")
  (princ)
  (uc:guard-end))

(defun c:tx nil
  (uc:guard-begin '())
  "显示全部图层（全部打开+解冻+解锁）。"
  (lay:foreach
    '(lambda (name)
       (lay:thaw name)
       (lay:unlock name)
       (lay:on name)))
  (princ "\n所有图层已显示+解冻+解锁。")
  (princ)
  (uc:guard-end))


;; ============================================================================
;; 图层切换
;; ============================================================================

(defun c:tq (/ e lay)
  (uc:guard-begin '("CLAYER"))
  "选实体，将其所在图层设为当前图层。"
  (if (setq e (car (entsel "\n选择实体以切换当前图层: ")))
    (progn
      (setq lay (entity:get-layer e))
      (lay:current lay)
      (princ (strcat "\n当前图层: " lay))))
  (princ)
  (uc:guard-end))

(defun c:gtc (/ ss lay)
  (uc:guard-begin '())
  "选择实体，将其改到当前图层。"
  (setq lay (getvar "CLAYER"))
  (if (setq ss (ssget))
    (progn
      (sel:for-each ss '(lambda (e) (entity:set-dxf e 8 lay)))
      (princ (strcat "\n已改到当前图层: " lay))))
  (princ)
  (uc:guard-end))


(princ "\n[TB] 图层管理模块加载完成 (layer: 10命令)")
(princ)
