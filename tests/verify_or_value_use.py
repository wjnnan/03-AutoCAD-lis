#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""静态检查：把 (or A B) 当作"取第一个非 nil 值"使用的地方。

AutoLISP 的 or 与 Common Lisp 不同 —— 它**只返回 T 或 NIL**：
  "Returns T if one of the expressions evaluates to a non-NIL value; otherwise, returns NIL."
（见 autolisp-spec；实测 (or nil 5) 与 (or 5 nil) 均得符号 T）

因此 (or 值 默认值) 这种"取默认值"写法是错的：只要第一个表达式非 nil 就返回 T，
下游的 itoa/rtos/strcat/算术/函数参数收到 T 即报错 —— 且**有值时才崩，没值反而正常**，
极易漏测。

正确写法（cond-as-or 惯用法）：
  (if A A B)                 ; 两个候选
  (cond (A) (B) (C))         ; 多个候选，各子句单独成项

本检查只报"or 的结果会被当数据使用"的位置；作为 if/while/cond 的条件判断是安全的。

历史案例：tb-mod-batchprint / tb-mod-rebar / tb-mod-rebar-edit / tb-lib-rebar /
tb-mod-dim / tb-mod-block 共 14 处，导致批量打印比例、钢筋等级直径显示等出错。

退出码: 0 无问题；1 发现问题。
"""

from __future__ import annotations

import glob
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
from run_tb_functional import read_src, strip_comments_strings  # noqa: E402

# 这些位置里 or 只作真假判断，安全
COND_PARENTS = {"if", "while", "and", "or", "cond", "not", "null",
                "foreach", "unless", "until", "setq-test"}
# 这些位置里 or 的结果会被当数据用，危险
VALUE_PARENTS = {"setq", "set", "strcat", "list", "cons", "itoa", "rtos",
                 "princ", "float", "fix", "abs", "*", "+", "-", "/", "=",
                 "vl-princ-to-string", "vl-string-right-trim"}


def sexp_end(s: str, i: int) -> int:
    depth = 0
    for j in range(i, len(s)):
        if s[j] == "(":
            depth += 1
        elif s[j] == ")":
            depth -= 1
            if depth == 0:
                return j
    return len(s)


def innermost_encloser(s: str, pos: int) -> str:
    """返回直接包含 pos 的最内层列表的头部符号名（小写）。"""
    stack = []
    for i, ch in enumerate(s[:pos]):
        if ch == "(":
            m = re.match(r"\(\s*([^\s()]*)", s[i:i + 40])
            stack.append((m.group(1) if m else "").lower())
        elif ch == ")" and stack:
            stack.pop()
    return stack[-1] if stack else ""


def main() -> int:
    files = sorted(glob.glob(str(ROOT / "TB-Toolbox" / "*.lsp"))) + \
            sorted(glob.glob(str(ROOT / "unified-lib" / "*.lsp")))
    problems = []
    for f in files:
        raw = read_src(Path(f))
        clean = strip_comments_strings(raw)
        for m in re.finditer(r"\(or\b", clean):
            parent = innermost_encloser(clean, m.start())
            if parent in COND_PARENTS:
                continue
            if parent in VALUE_PARENTS or parent.startswith(("safe:", "entity:", "vla-")):
                end = sexp_end(clean, m.start())
                ln = clean[:m.start()].count("\n") + 1
                call = " ".join(raw[m.start():end + 1].split())[:70]
                problems.append((Path(f).name, ln, parent, call))

    if problems:
        print("发现 %d 处 or 被当作取值使用（AutoLISP 的 or 只返回 T/NIL）：" % len(problems))
        for name, ln, parent, call in problems:
            print("  %s:%d  父=%s  %s" % (name, ln, parent, call))
        print()
        print("改用 cond-as-or 惯用法：(if A A B) 或 (cond (A) (B) (C))")
        return 1
    print("or 用法检查通过（未发现把 or 当取值的写法）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
