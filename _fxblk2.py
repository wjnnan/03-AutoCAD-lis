data = open("atlisp-packages/base/block.lsp", "rb").read()

# Fix 1: get-dynamic-properties - add vl-catch-all-apply + error check
old1 = b"(setq props (vlax-invoke oblk 'getdynamicblockproperties))"
new1 = (b"(setq props (vl-catch-all-apply 'vlax-invoke"
        b" (list oblk 'getdynamicblockproperties)))\r\n"
        b"\t(if (or (vl-catch-all-error-p props) (not props))\r\n"
        b"\t    nil")
if old1 in data:
    data = data.replace(old1, new1)
    print("Fix 1 OK")

# Fix 2: set-dynprop - restructure to check error before vl-some
# Find the vl-some block and restructure it
old2_start = b"\t  (vl-some\r\n\t   '(lambda (x)\r\n"
old2_end = b"\t   (vlax-invoke (vlax-ename->vla-object blk) 'getdynamicblockproperties)\r\n\t  )"

# Find the lambda block between vl-some and vlax-invoke
vl_some_pos = data.find(old2_start)
vl_invoke_pos = data.find(b"(vlax-invoke (vlax-ename->vla-object blk) 'getdynamicblockproperties)", vl_some_pos)

if vl_some_pos >= 0 and vl_invoke_pos >= 0:
    # Extract the lambda body
    lambda_body_end = data.find(b"\r\n\t   (vlax-invoke", vl_some_pos)
    lambda_body = data[vl_some_pos + len(b"\t  (vl-some\r\n"):lambda_body_end]
    
    # Build the new structure
    new_block = (b"\t  (setq _dynprops (vl-catch-all-apply 'vlax-invoke"
                 b" (list (vlax-ename->vla-object blk) 'getdynamicblockproperties)))\r\n"
                 b"\t  (if (or (vl-catch-all-error-p _dynprops) (not _dynprops))\r\n"
                 b"\t      nil\r\n"
                 b"\t      (vl-some\r\n"
                 + lambda_body +
                 b"\r\n\t       _dynprops))\r\n")
    
    # Find the end of the old block (after vlax-invoke and closing parens)
    old_end = data.find(b"\r\n\t  )", vl_invoke_pos)
    if old_end >= 0:
        old_end += len(b"\r\n\t  )")
        data = data[:vl_some_pos] + new_block + data[old_end:]
        print("Fix 2 OK")
    else:
        print("Fix 2 end not found")
else:
    print(f"Fix 2 not found: vl_some={vl_some_pos}, vl_invoke={vl_invoke_pos}")

open("atlisp-packages/base/block.lsp", "wb").write(data)
print("Done")
