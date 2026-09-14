#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""静态检查：实参个数少于形参个数的调用。

AutoLISP 严格校验参数个数 —— 实参少于形参直接报「参数太少」，不会用 nil 补位。
这类错误括号平衡检查发现不了，且常在特定分支才执行，静态审查极易遗漏。

历史案例：
  - lay:make (name color linetype) 被 10 处按两参调用，导致图层创建失效、
    c:RB 画不出钢筋
  - entity:get-bbox (ename offset) 被 2 处按一参调用，批量打印中断

退出码: 0 无问题；1 发现问题。
"""

from __future__ import annotations

import glob
import itertools
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
from run_tb_functional import read_src, strip_comments_strings  # noqa: E402

BS = chr(92)
STR_RE = re.compile('"(?:[^"' + BS + BS + ']|' + BS + BS + '.)*"')

# AutoLISP 内置 c...r 组合最多 4 层
CARCDR = {'c' + ''.join(c) + 'r' for n in range(1, 5) for c in itertools.product('ad', repeat=n)}


def defuns(clean: str) -> dict:
    """提取 {函数名小写: 形参个数}。"""
    out = {}
    for m in re.finditer(r'\(defun\s+([^\s()]+)\s*\(([^)]*)\)', clean):
        params = m.group(2)
        if "/" in params:
            params = params.split("/")[0]
        out[m.group(1).lower()] = len([p for p in params.split() if p])
    return out


def top_level_args(call: str) -> int:
    """数顶层实参个数；无法解析返回 -1。"""
    norm = STR_RE.sub("X", call)
    if not norm.endswith(")"):
        return -1
    body = norm[1:-1]
    m = re.match(r'\s*[^\s()]+', body)
    if not m:
        return 0
    depth = 0
    args = 0
    cur = ""
    for ch in body[m.end():]:
        if ch == "(":
            depth += 1
            cur += ch
        elif ch == ")":
            depth -= 1
            cur += ch
        elif depth == 0 and ch.isspace():
            if cur.strip():
                args += 1
            cur = ""
        else:
            cur += ch
    if cur.strip():
        args += 1
    return args


def main() -> int:
    files = sorted(glob.glob(str(ROOT / "TB-Toolbox" / "*.lsp"))) + \
            sorted(glob.glob(str(ROOT / "unified-lib" / "*.lsp")))

    defs = {}
    for f in files:
        defs.update(defuns(strip_comments_strings(read_src(Path(f)))))

    problems = []
    for f in files:
        raw = read_src(Path(f))
        clean = strip_comments_strings(raw)
        name = Path(f).name
        # 实参不足
        for m in re.finditer(r'\(([a-z][a-zA-Z0-9:_\-\?\!\*>]*)\s', clean):
            fn = m.group(1).lower()
            if fn not in defs:
                continue
            depth = 0
            end = None
            for j in range(m.start(), len(clean)):
                if clean[j] == "(":
                    depth += 1
                elif clean[j] == ")":
                    depth -= 1
                    if depth == 0:
                        end = j
                        break
            if end is None:
                continue
            got = top_level_args(raw[m.start():end + 1])
            need = defs[fn]
            if 0 <= got < need:
                ln = clean[:m.start()].count(chr(10)) + 1
                problems.append((name, ln, "实参不足: %s 需要 %d 个，实给 %d 个" % (fn, need, got)))
        # 非法的 c...r 组合
        for m in re.finditer(r'\((c[ad]{2,}r)\b', clean):
            fn = m.group(1)
            if fn not in CARCDR:
                ln = clean[:m.start()].count(chr(10)) + 1
                problems.append((name, ln, "非法函数: %s（AutoLISP 的 c...r 最多 4 层）" % fn))

    if problems:
        print("发现 %d 个问题：" % len(problems))
        for name, ln, msg in problems:
            print("  %s:%d  %s" % (name, ln, msg))
        return 1
    print("参数个数与 c...r 组合检查通过（对照 %d 个自定义函数定义）" % len(defs))
    return 0


if __name__ == "__main__":
    sys.exit(main())
