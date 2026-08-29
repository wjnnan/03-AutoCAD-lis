(defun p:curvep (obj)
  "ÊÇ·ñÊÇÇúÏß"
  (if (vlap obj)
    (and (member (vla-get-objectname obj)
        (quote ("AcDbPolyline"
            "AcDbSpline"
            "AcDb3dPolyline"
            "AcDb2dPolyline"
            "AcDbLine"
            "AcDbCircle"
            "AcDbArc"
            "AcDbEllipse"))))
    nil))
