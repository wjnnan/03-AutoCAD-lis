
import os

# 修复 at-select/at-select.lsp
fp = r'atlisp-packages/at-select/at-select.lsp'
with open(fp, 'rb') as f:
    data = f.read()

marker = '(setq en (car (entsel"'.encode()
fixes = 0
pos = 0
while True:
    idx = data.find(marker, pos)
    if idx == -1:
        break
    le = data.find(b'
', idx)
    if le == -1:
        le = len(data)
    nn = data.find(b'
', le+2)
    if nn == -1:
        nn = len(data)
    nl = data[le+2:nn]
    if b'(if (not en) (quit))' in nl:
        pos = le + 1
        continue
    ls = data.rfind(b'
', 0, idx)
    ls = ls + 2 if ls >= 0 else 0
    indent = b''
    j = ls
    while j < idx and data[j:j+1] in (b' ', b'	'):
        indent += data[j:j+1]
        j += 1
    check = b'
' + indent + b'(if (not en) (quit))'
    data = data[:le+2] + check + data[le+2:]
    fixes += 1
    pos = le + len(check)

with open(fp, 'wb') as f:
    f.write(data)
print(f'[5-6] at-select.lsp: {fixes} fixes')

# 修复 base/ss-other.lsp
fp2 = r'atlisp-packages/base/ss-other.lsp'
with open(fp2, 'rb') as f:
    data2 = f.read()

old = b'(setq ss1 (SsgetCP (list(car (entsel))'
idx = data2.find(old)
le2 = data2.find(b'
', idx)
# 构建新行 - 避开引号转义问题
apos = chr(39).encode()
star = b'"*"'
newcode = b'(if (setq ent (car (entsel)))
    (progn (setq ss1 (SsgetCP (list ent ' + apos + b'(0 . ' + star + b') ))) (sssetfirst nil ss1)))'
data2 = data2[:idx] + newcode + data2[le2+2:]
with open(fp2, 'wb') as f:
    f.write(data2)
print('[7] base/ss-other.lsp: fixed')

# 修复 at-text/mtext.lsp
fp3 = r'atlisp-packages/at-text/mtext.lsp'
with open(fp3, 'rb') as f:
    data3 = f.read()

lines = data3.split(b'
')
for i, line in enumerate(lines):
    if b'vla-put-TextString (e2o ent)' in line and not line.strip().startswith(b'(vla-put'):
        lines[i] = line.replace(b'vla-put-TextString (e2o ent)', b'(vla-put-TextString (e2o ent)')
        for j in range(i, min(i+10, len(lines))):
            if lines[j].rstrip().endswith(b'))'):
                stripped = lines[j].rstrip()
                spaces = lines[j][:len(lines[j])-len(stripped)]
                if stripped == b'))':
                    lines[j] = spaces + b')))'
                else:
                    lines[j] = spaces + stripped + b')'
                print(f'[8] mtext.lsp line {i+1}: fixed, close at line {j+1}')
                break
        break

data3 = b'
'.join(lines)
with open(fp3, 'wb') as f:
    f.write(data3)
print('Done')
