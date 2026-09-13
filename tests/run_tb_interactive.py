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
  "清空当前图形中的所有实体。"
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

(defun it:count (tag)
  "打印当前图形实体数，供外部校验命令是否真的产生了对象。空图时 ssget 返回 nil。"
  (setq *it:cs* (ssget "_X"))
  (princ (strcat (chr 10) "###COUNT:" tag "="
                 (itoa (if *it:cs* (sslength *it:cs*) 0)) "###" (chr 10))))

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
]


def build_scr() -> str:
    """生成驱动交互式命令的 .scr。"""
    lines = [
        '(setvar "SECURELOAD" 0)',
        '(setvar "FILEDIA" 0)',
        '(setvar "CMDECHO" 0)',
        '(vl-load-com)',
        '(setq *TB:PATH* "%s")' % TB_DIR.as_posix(),
        '(setq *UC:ROOT* "%s")' % ROOT.as_posix(),
        '(load "%s")' % (TB_DIR / "load.lsp").as_posix(),
        '(load "%s")' % HELPER_LSP.as_posix(),
    ]
    for c in CASES:
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


def run_scr(accore: str) -> str:
    """执行 .scr 并返回引擎输出（已解码）。"""
    with tempfile.TemporaryDirectory(prefix="tb_inter_") as tmp:
        scr = Path(tmp) / "run.scr"
        scr.write_text(SCR_PATH.read_text(encoding="ascii"), encoding="ascii")
        proc = subprocess.run([accore, "/s", str(scr)], capture_output=True, timeout=600)
    raw = (proc.stdout or b"") + (proc.stderr or b"")
    for enc in ("utf-16-le", "utf-8", "gbk"):
        try:
            text = raw.decode(enc)
            if "\ufffd" not in text:
                return text
        except Exception:
            continue
    return raw.decode("gbk", errors="replace")


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


def run_suite(accore=None):
    """执行全部交互式用例，返回 (通过, 失败, 明细)。找不到引擎时返回 (-1, -1, [])。"""
    HELPER_LSP.write_text(HELPER_SRC, encoding="gbk")
    SCR_PATH.write_text(build_scr(), encoding="ascii")
    if accore is None:
        accore = find_accoreconsole()
    if not accore:
        return -1, -1, []
    # 用例可能改动工具箱配置（如 c:xd 写出图比例），测试前后备份还原，避免污染工作区
    cfg = TB_DIR / "TB-SysConfig.cfg"
    backup = cfg.read_bytes() if cfg.exists() else None
    try:
        output = run_scr(accore)
    finally:
        if backup is not None:
            cfg.write_bytes(backup)
        elif cfg.exists():
            cfg.unlink()
    sections = split_sections(output)
    results, passed, failed = [], 0, 0
    for c in CASES:
        problems = check(c, sections.get(c["name"]))
        results.append((c, problems))
        if problems:
            failed += 1
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
    args = ap.parse_args()

    if args.gen:
        HELPER_LSP.write_text(HELPER_SRC, encoding="gbk")
        SCR_PATH.write_text(build_scr(), encoding="ascii")
        print("已生成: %s（%d 个用例）" % (SCR_PATH.name, len(CASES)))
        return 0

    passed, failed, results = run_suite()
    if passed < 0:
        print("未找到 accoreconsole.exe，跳过交互式测试")
        return 0
    print_report(results, passed, failed)
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
