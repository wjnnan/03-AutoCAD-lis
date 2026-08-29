import sys
data = open("atlisp-packages/base/block.lsp", "rb").read()

# Fix 1
tag = b"(setq props (vlax-invoke oblk 'getdynamicblockproperties))"
if tag in data:
    repl = b"(setq props (vl-catch-all-apply 'vlax-invoke (list oblk 'getdynamicblockproperties)))\r\n\t(if (or (vl-catch-all-error-p props) (not props))\r\n\t    nil"
    data = data.replace(tag, repl)
    print("Fix 1 done")
else:
    print("Fix 1 NOT FOUND")

# Fix 2
tag2 = b"(vlax-invoke (vlax-ename->vla-object blk) 'getdynamicblockproperties)"
if tag2 in data:
    repl2 = b"(setq _dynprops (vl-catch-all-apply 'vlax-invoke (list (vlax-ename->vla-object blk) 'getdynamicblockproperties)))\r\n\t   (if (or (vl-catch-all-error-p _dynprops) (not _dynprops))\r\n\t       nil\r\n\t   (vl-some"
    data = data.replace(tag2, repl2)
    print("Fix 2 done")
else:
    print("Fix 2 NOT FOUND")

open("atlisp-packages/base/block.lsp", "wb").write(data)
print("Completed")
