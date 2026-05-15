; Written by Alex McTeague
(defun c:TurnOnLayer (/ layerName)
  (setq layerName (getstring T "Layer name: "))
  (command "_.layer" "_thaw" layerName "_on" layerName "")
  (princ)
)
    
(defun c:TurnOffLayer (/ layerName)
  (setq layerName (getstring T "Layer name: "))
  (command "_.layer" "_thaw" layerName "_off" layerName "")
  (princ)
)

(defun c:FreezeLayer (/ layerName)
  (setq layerName (getstring T "Layer name: "))
  (command "_.layer" "_freeze" layerName "_off" layerName "")
)