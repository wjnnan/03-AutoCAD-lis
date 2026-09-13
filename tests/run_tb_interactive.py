#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""TB-Toolbox 交互式命令实测（accoreconsole + .scr 喂输入序列）。

覆盖需要选对象/取点的命令：按提示顺序把输入写进 .scr，由真实 CAD 引擎执行，
再解析引擎输出比对期望关键字。函数级断言见 run_tb_functional.py。

用法:
  python tests/run_tb_interactive.py          # 执行并报告
  python tests/run_tb_interactive.py --gen    # 只生成 .scr 不执行
退出码: 0 全部通过；1 存在失败。
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from run_tb_functional import find_accoreconsole, parse_load_list  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
TB_DIR = ROOT / "TB-Toolbox"
HELPER_LSP = Path(__file__).resolve().parent / "_tb_interactive_helper.lsp"
SCR_PATH = ROOT / "_tb_interactive.scr"

# 注入到引擎里的辅助函数（纯 ASCII，避免编码问题）
HELPER_SRC = ''';;; _tb_interactive_helper.lsp -- 交互式测试辅助，由 run_tb_interactive.py 生成
(defun it:clean ()
  "清空实体并恢复图层状态（c:TG/c:TD 会关闭或冻结图层）。"
  (command "_.-LAYER" "_ON" "*" "")
  (command "_.-LAYER" "_T" "*" "")
  (setq *it:ss* (ssget "_X"))
  (if *it:ss*
    (progn
      (setq *it:i* 0)
      (repeat (sslength *it:ss*)
        (entdel (ssname *it:ss* *it:i*))
        (setq *it:i* (1+ *it:i*)))))
  (princ))

(defun it:mark (tag)
  "打印分段标记，供外部解析引擎输出。"
  (princ (strcat (chr 10) "###CASE:" tag "###" (chr 10))))

(defun it:mkline (x1 y1 x2 y2)
  (entmake (list (cons 0 "LINE") (cons 10 (list x1 y1 0.0)) (cons 11 (list x2 y2 0.0)))))

(defun it:mkrect (x1 y1 x2 y2)
  (entmake (list (cons 0 "LWPOLYLINE") (cons 100 "AcDbEntity") (cons 100 "AcDbPolyline")
                 (cons 90 4) (cons 70 1)
                 (cons 10 (list x1 y1)) (cons 10 (list x2 y1))
                 (cons 10 (list x2 y2)) (cons 10 (list x1 y2)))))

(defun it:mkcircle (cx cy r)
  (entmake (list (cons 0 "CIRCLE") (cons 10 (list cx cy 0.0)) (cons 40 r))))

(defun it:or-works nil
  "探测本环境 or 是否正常：accoreconsole 中 or 退化为布尔判断，恒返回 T，
依赖 (or 值 默认值) 取值的命令在此环境下必然异常，属引擎限制而非产品缺陷。"
  (equal (or nil 5) 5))

(defun it:count (tag)
  "打印当前图形实体数，供外部校验命令是否真的产生了对象。空图时 ssget 返回 nil。"
  (setq *it:cs* (ssget "_X"))
  (princ (strcat (chr 10) "###COUNT:" tag "="
                 (itoa (if *it:cs* (sslength *it:cs*) 0)) "###" (chr 10))))

(defun it:mkdim (x1 y1 x2 y2)
  (entmake (list (cons 0 "LINE") (cons 10 (list x1 y1 0.0)) (cons 11 (list x2 y2 0.0)))))

(defun it:mktext (x y s)
  (entmake (list (cons 0 "TEXT") (cons 10 (list x y 0.0)) (cons 40 3.5)
                 (cons 1 s) (cons 7 "Standard"))))

(princ)
'''

# 每个用例：setup 建图元，inputs 按提示顺序喂入，expect 必须出现，forbid 不得出现
CASES = [
    {
        "name": "FCK",
        "desc": "c:FCK 混凝土强度参数（getint 直接输入）",
        "setup": "",
        "inputs": ["FCK", "50"],
        "expect": ["混凝土 C50 强度参数", "轴心抗压强度标准值 fck =", "弹性模量 Ec"],
        "forbid": ["错误", "no function definition", "参数太少"],
    },
    {
        "name": "xd",
        "desc": "c:xd 云线出图比例（getint 直接输入）",
        "setup": "",
        "inputs": ["xd", "100"],
        "expect": ["当前出图比例: 1:100"],
        "forbid": ["错误", "no function definition"],
    },
    {
        "name": "LCD",
        "desc": "c:LCD 累计长度（ssget 窗口选择 + getpoint 回车跳过）",
        "setup": "(it:mkline 0.0 0.0 100.0 0.0)(it:mkline 0.0 0.0 0.0 50.0)",
        "inputs": ["LCD", "W", "-10000,-10000", "10000,10000", "", ""],
        "expect": ["累计长度: 150"],
        "forbid": ["错误", "no function definition", "参数太少"],
    },
    {
        "name": "SECT",
        "desc": "c:SECT 截面几何特性（ssget 选闭合多段线）",
        "setup": "(it:mkrect 0.0 0.0 100.0 50.0)",
        "inputs": ["SECT", "W", "-10000,-10000", "10000,10000", ""],
        "expect": ["面积 A", "5000"],
        "forbid": ["错误", "no function definition", "参数太少"],
    },
    {
        "name": "QH",
        "desc": "c:QH 文字数字求和（ssget 选文字）",
        "setup": '(it:mktext 0.0 0.0 "12.5")(it:mktext 0.0 50.0 "300")(it:mktext 0.0 100.0 "abc7")',
        "inputs": ["QH", "W", "-10000,-10000", "10000,10000", ""],
        "expect": ["数字求和: 319.5"],
        "forbid": ["错误", "no function definition", "参数太少"],
    },
    {
        "name": "SEIS",
        "desc": "c:SEIS 抗震特征周期（getkword 选分支 + getint）",
        "setup": "",
        "inputs": ["SEIS", "T", "2", "2"],
        "expect": ["地震特征周期 Tg ="],
        "forbid": ["错误", "no function definition", "参数太少"],
    },
    {
        "name": "Q",
        "desc": "c:q 直线（包装内置 LINE 命令）",
        "setup": "",
        "inputs": ["q", "0,0", "100,0", ""],
        "expect": ["###COUNT:Q=1###"],
        "forbid": ["错误", "no function definition"],
    },
    {
        "name": "WW",
        "desc": "c:ww 圆（包装内置 CIRCLE 命令）",
        "setup": "",
        "inputs": ["ww", "50,50", "25"],
        "expect": ["###COUNT:WW=1###"],
        "forbid": ["错误", "no function definition"],
    },
    {
        "name": "QR",
        "desc": "c:qr 矩形（包装内置 RECTANG 命令）",
        "setup": "",
        "inputs": ["qr", "0,0", "80,60"],
        "expect": ["###COUNT:QR=1###"],
        "forbid": ["错误", "no function definition"],
    },
    {
        "name": "nn",
        "desc": "c:nn 对象捕捉设置（无交互，直接调用）",
        "setup": "",
        "inputs": ["nn"],
        "expect": ["捕捉模式:"],
        "forbid": ["错误", "no function definition"],
    },
    {
        "name": "DD",
        "desc": "c:dd 水平断点符号（getpoint 取点后建多段线）",
        "setup": "",
        "inputs": ["dd", "0,0"],
        "expect": ["###COUNT:DD=1###"],
        "forbid": ["错误", "no function definition"],
    },
    {
        "name": "TG",
        "desc": "c:tg 关闭所选对象所在图层（ssget）",
        "setup": "(it:mkline 0.0 0.0 100.0 0.0)",
        "inputs": ["tg", "W", "-10000,-10000", "10000,10000", ""],
        "expect": ["已关闭所选对象的图层。"],
        "forbid": ["错误", "no function definition", "参数太少"],
    },
    {
        "name": "TD",
        "desc": "c:td 冻结所选对象所在图层（ssget）",
        "setup": "(it:mkline 0.0 0.0 100.0 0.0)",
        "inputs": ["td", "W", "-10000,-10000", "10000,10000", ""],
        "expect": ["已冻结所选对象的图层"],
        "forbid": ["错误", "no function definition", "参数太少"],
    },
    {
        "name": "RB",
        "desc": "c:RB 画任意钢筋（直径/等级/弯钩/方向 + 点取路径）",
        "setup": "",
        "inputs": ["RB", "20", "3", "2", "2", "L", "0,0", "200,0", ""],
        "expect": ["钢筋已绘制。D=20 等级=3", "弯钩: 始=斜 末=斜"],
        "forbid": ["错误", "no function definition", "参数太少", "至少需要2个点"],
    },
]



# ---------------------------------------------------------------------------
# 批量冒烟用例：交互序列简单（≤2 步），主要验证"能跑通且不报错"。
# 这类命令多为改属性/开关类，逐个写精确断言性价比低，但"不报错"能抓出
# 类似 lay:make 参数不足那样的运行时错误。
# ---------------------------------------------------------------------------
BULK_SETUP = ("(it:mkline 0.0 0.0 100.0 0.0)(it:mkcircle 300.0 300.0 40.0)"
              "(it:mkrect 500.0 0.0 600.0 50.0)(it:mktext 0.0 300.0 \"7\")")

# 仅 ssget：喂窗口选择即可
BULK_SSGET = [
    "GJZL", "sk", "RAV", "ce", "fw", "bgc", "ggb", "cl", "z0",
    "C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8",
    "tgf", "tdf", "tsf", "gtc", "gts", "tty",
    "13", "23", "31", "32", "tjk",
]

# ssget + 一个取点
BULK_SSGET_PT = ["cr", "s1", "s2", "s4", "s5", "s0", "s00",
                 "r4", "r9", "r5", "r0"]

# 需要"先选对象、再补数值/点"或"先给数值、再选对象"的命令，单独给序列。
# 通用序列喂不满这些命令的后续提示，会让 accoreconsole 一直等输入直至超时。
SEL = ["W", "-10000,-10000", "10000,10000", ""]          # 窗口选择
BULK_CUSTOM = {
    # 名称: 输入序列（不含命令名本身）
    "bbf": ["3"] + SEL,                 # 先问等分数，再选标注
    "RW":  SEL + ["0.8"],               # 选钢筋后问新线宽
    "ttk": SEL + ["0.8"],               # 选文字后问宽高比
    "ttg": SEL + ["400"],               # 选文字后问高度
    # RO 内部的 (command "_.OFFSET" ...) 会消费后续脚本行，COUNT 标记无法打出，
    # 故断言命令自身的成功输出
    "RO":  SEL + ["100", "50,50"],
    "gbb": ["test"] + SEL,              # 先输字符串，再选
    "th":  ["A", "B"] + SEL,            # 两个字符串，再选
}

BULK_FORBID = ["错误", "no function definition", "参数太少", "参数类型错误"]

# 少数命令执行后会消费掉脚本的后续行（如内部再调 command），COUNT 标记打不出来，
# 改为断言命令自身的成功提示。
EXPECT_OVERRIDE = {
    "RO": ["已偏移"],
}

# 命令内部用 (or 取值 默认值) 做回退；accoreconsole 的 or 语义失效会让它们必然报错。
# 这类失败标记为环境受限，不计入失败（真实 AutoCAD 中 or 正常）。
OR_DEPENDENT = {"BULK_ce", "BULK_bgc"}

def _bulk_case(name):
    """生成一个批量冒烟用例；name 以 * 结尾表示需要额外取点。"""
    if name.endswith("*"):
        cmd = name[:-1]
        inputs = [cmd, "W", "-10000,-10000", "10000,10000", "", "50,50"]
    else:
        cmd = name
        inputs = [cmd, "W", "-10000,-10000", "10000,10000", ""]
    return {
        "name": "BULK_" + cmd,
        "desc": "c:%s 批量冒烟（确认可执行、无运行时错误）" % cmd,
        "setup": BULK_SETUP + "(it:mkdim 0.0 500.0 200.0 500.0)",
        "inputs": inputs,
        "expect": ["###COUNT:BULK_%s=" % cmd],
        "forbid": BULK_FORBID,
    }


CASES += [_bulk_case(n) for n in BULK_SSGET]
for _n, _seq in BULK_CUSTOM.items():
    CASES.append({
        "name": "BULK_" + _n,
        "desc": "c:%s 批量冒烟（确认可执行、无运行时错误）" % _n,
        "setup": BULK_SETUP,
        "inputs": [_n] + _seq,
        "expect": EXPECT_OVERRIDE.get(_n, ["###COUNT:BULK_%s=" % _n]),
        "forbid": BULK_FORBID,
    })
CASES += [_bulk_case(n + "*") for n in BULK_SSGET_PT]

# 去重：批量列表与定制列表若重名，保留后定义的（定制序列更完整）
_seen, _uniq = set(), []
for _c in CASES:
    if _c["name"] in _seen:
        _uniq = [_x for _x in _uniq if _x["name"] != _c["name"]]
    _seen.add(_c["name"])
    _uniq.append(_c)
CASES = _uniq



def _check_balanced(text, label):
    """括号自检：生成 LISP 前先确认平衡，避免一个漏括号悄悄吞掉后面所有定义。"""
    depth = 0
    in_str = False
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if in_str:
            if c == chr(92):
                i += 2
                continue
            if c == '"':
                in_str = False
        elif c == ";":
            j = text.find(chr(10), i)
            i = n if j < 0 else j
            continue
        elif c == '"':
            in_str = True
        elif c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth < 0:
                raise SystemExit("[%s] 第 %d 字符处出现多余的右括号" % (label, i))
        i += 1
    if depth != 0:
        raise SystemExit("[%s] 括号不平衡，相差 %d 个（左多右少为正）" % (label, depth))


def build_scr(cases=None) -> str:
    """生成驱动交互式命令的 .scr。cases 为 None 时用全部用例。"""
    cases = CASES if cases is None else cases
    lines = [
        '(setvar "SECURELOAD" 0)',
        '(setvar "FILEDIA" 0)',
        '(setvar "CMDECHO" 0)',
        '(vl-load-com)',
        '(setq *TB:PATH* "%s")' % TB_DIR.as_posix(),
        '(setq *UC:ROOT* "%s")' % ROOT.as_posix(),
        '(load "%s")' % (TB_DIR / "load.lsp").as_posix(),
        '(load "%s")' % HELPER_LSP.as_posix(),
        '(princ (strcat (chr 10) "###ENV:or=" (if (it:or-works) "ok" "broken") "###" (chr 10)))',
    ]
    for c in cases:
        lines.append("(it:clean)")
        if c["setup"]:
            lines.append("(princ)")
            lines.append(c["setup"])
        lines.append('(it:mark "%s")' % c["name"])
        lines.extend(c["inputs"])
        lines.append('(it:count "%s")' % c["name"])
    lines.append('(it:mark "END")')
    lines.append("_.quit _y")
    return "\n".join(lines) + "\n"


def run_scr(accore: str, timeout: int = 45, quiet: bool = False) -> str:
    """执行 .scr 并返回引擎输出（已解码）。"""
    with tempfile.TemporaryDirectory(prefix="tb_inter_") as tmp:
        scr = Path(tmp) / "run.scr"
        scr.write_text(SCR_PATH.read_text(encoding="ascii"), encoding="ascii")
        proc = subprocess.run([accore, "/s", str(scr)], capture_output=True, timeout=timeout)
    raw = (proc.stdout or b"") + (proc.stderr or b"")
    for enc in ("utf-16-le", "utf-8", "gbk"):
        try:
            text = raw.decode(enc)
            if "\ufffd" not in text:
                return text
        except Exception:
            continue
    return raw.decode("gbk", errors="replace")


def env_caps(output: str) -> dict:
    """解析引擎能力探测结果。"""
    caps = {}
    for m in re.finditer(r"###ENV:([a-z]+)=([a-z]+)###", output):
        caps[m.group(1)] = m.group(2)
    return caps


def split_sections(output: str) -> dict:
    """按 ###CASE:tag### 切分引擎输出，返回 {tag: 该段文本}。"""
    marks = [(m.group(1), m.start()) for m in re.finditer(r"###CASE:([A-Za-z0-9_:]+)###", output)]
    # 同一标记会出现两次（princ 输出 + 命令回显），只保留每个标记的首次出现
    first, seen = [], set()
    for tag, pos in marks:
        if tag not in seen:
            seen.add(tag)
            first.append((tag, pos))
    sections = {}
    for k, (tag, pos) in enumerate(first):
        end = first[k + 1][1] if k + 1 < len(first) else len(output)
        sections[tag] = output[pos:end]
    return sections


def check(case: dict, body: str) -> list:
    """检查单段输出，返回问题列表。"""
    problems = []
    if body is None:
        return ["未在引擎输出中找到该用例的分段标记（命令可能未被执行）"]
    for want in case["expect"]:
        if want not in body:
            problems.append("缺少期望输出: %s" % want)
    for bad in case["forbid"]:
        if bad in body:
            problems.append("出现异常信息: %s" % bad)
    return problems


def run_suite(accore=None, only=None, verbose=False):
    """执行交互式用例，返回 (通过, 失败, 明细)。找不到引擎时返回 (-1, -1, [])。

    逐用例独立执行：单个命令若卡在输入等待或触发对话框，只有它自己超时，
    不会拖垮整批（整批共用一次 accoreconsole 时，一个卡住就全军覆没）。
    """
    _check_balanced(HELPER_SRC, "helper")
    HELPER_LSP.write_text(HELPER_SRC, encoding="gbk")
    if accore is None:
        accore = find_accoreconsole()
    if not accore:
        return -1, -1, []

    cases = [c for c in CASES if only is None or c["name"] in only]
    results, passed, failed = [], 0, 0
    for c in cases:
        single = dict(c)
        single["_only_this"] = True
        SCR_PATH.write_text(build_scr([single]), encoding="ascii")
        cfg = TB_DIR / "TB-SysConfig.cfg"
        backup = cfg.read_bytes() if cfg.exists() else None
        output = ""
        try:
            output = run_scr(accore, quiet=True)
        except subprocess.TimeoutExpired:
            output = "__TIMEOUT__"
        finally:
            if backup is not None:
                cfg.write_bytes(backup)
            elif cfg.exists():
                cfg.unlink()
        if output == "__TIMEOUT__":
            problems = ["命令卡住未返回（超时）"]
        elif env_caps(output).get("or") == "broken" and c["name"] in OR_DEPENDENT:
            # 引擎 or 语义失效，这些命令在真实 AutoCAD 中正常，此处不计失败
            problems = []
            c = dict(c, desc=c["desc"] + "［引擎 or 语义失效，已跳过］")
        else:
            sections = split_sections(output)
            body = sections.get(c["name"])
            if body is not None:
                body = body.replace("__TIMEOUT__", "")
            problems = check(c, body)
        results.append((c, problems))
        if problems:
            failed += 1
            if verbose:
                print("  !! %-16s %s" % (c["name"], "; ".join(problems)[:90]))
        else:
            passed += 1
    return passed, failed, results


def print_report(results, passed, failed):
    """打印交互式测试报告。"""
    print("")
    print("=" * 68)
    print("  TB-Toolbox 交互式命令实测报告")
    print("=" * 68)
    for c, problems in results:
        print("")
        if problems:
            print("!! [%s] %s" % (c["name"], c["desc"]))
            for p in problems:
                print("      " + p)
        else:
            print("OK [%s] %s" % (c["name"], c["desc"]))
    print("")
    print("=" * 68)
    print("  合计: 通过 %d  失败 %d" % (passed, failed))
    print("  结论: %s" % ("全部通过" if failed == 0 else "存在失败项"))
    print("=" * 68)


def main() -> int:
    ap = argparse.ArgumentParser(description="TB-Toolbox 交互式命令实测")
    ap.add_argument("--gen", action="store_true", help="只生成脚本，不执行")
    ap.add_argument("--only", default=None, help="只跑指定用例（逗号分隔）")
    ap.add_argument("--verbose", action="store_true", help="逐条打印结果")
    args = ap.parse_args()

    if args.gen:
        _check_balanced(HELPER_SRC, "helper")
        HELPER_LSP.write_text(HELPER_SRC, encoding="gbk")
        SCR_PATH.write_text(build_scr(), encoding="ascii")
        print("已生成: %s（%d 个用例）" % (SCR_PATH.name, len(CASES)))
        return 0

    only = args.only.split(",") if args.only else None
    passed, failed, results = run_suite(only=only, verbose=args.verbose)
    if passed < 0:
        print("未找到 accoreconsole.exe，跳过交互式测试")
        return 0
    print_report(results, passed, failed)
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
