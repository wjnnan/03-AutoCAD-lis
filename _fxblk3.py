data = open("atlisp-packages/base/block.lsp", "rb").read()
start = data.find(b'  (vl-some\r\n')
invoke_pos = data.find(b"(vlax-invoke (vlax-ename->vla-object blk) 'getdynamicblockproperties)", start)
close_pos = data.find(b'\r\n  )', invoke_pos)
if close_pos >= 0:
    close_pos += len(b'\r\n  )')

# lambda body: everything between "  (vl-some\r\n" and the line before vlax-invoke
lambda_body_start = start + len(b'  (vl-some\r\n')
lambda_body_end = invoke_pos - len(b'\r\n   ')
lambda_body = data[lambda_body_start:lambda_body_end]

new_block = (b'  (setq _dynprops (vl-catch-all-apply '
             b"'vlax-invoke"
             b' (list (vlax-ename->vla-object blk) '
             b"'getdynamicblockproperties)))\r\n"
             b'  (if (or (vl-catch-all-error-p _dynprops) (not _dynprops))\r\n'
             b'      nil\r\n'
             b'      (vl-some\r\n'
             + lambda_body +
             b'\r\n       _dynprops))\r\n')

data = data[:start] + new_block + data[close_pos:]
open("atlisp-packages/base/block.lsp", "wb").write(data)
print("Fix 2 done")
