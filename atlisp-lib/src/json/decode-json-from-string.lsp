(defun json:decode-json-from-string (str)
  "½«json×Ö·û´®½âÂë³Élist"
  "list"
  (read (@::post (strcat (@::uri)"/api/decode-json")
	   str)))
