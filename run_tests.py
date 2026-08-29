#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""AutoLISP 一键测试入口。

分层执行（默认仅静态层，无需 CAD）：

  1. 静态检查    tests/verify_*.py          —— 括号平衡、未定义符号、局部变量声明等，秒级
  2. 运行时验证  tests/verify_*_runtime.py  —— 需 accoreconsole（真实 CAD 引擎）
  3. 单元测试    _test_harness.lsp          —— accoreconsole 驱动，Round 14 修复回归套件
  4. 冒烟测试    tests/autocad_2024_smoke.lsp

用法:
  python run_tests.py              # 仅静态（pre-commit 钩子默认执行此项）
  python run_tests.py --runtime    # 静态 + 运行时验证
  python run_tests.py --harness    # 静态 + 运行时 + 单元测试
  python run_tests.py --all        # 全部（最完整，需 accoreconsole）
  python run_tests.py --list       # 仅列出将执行的测试，不运行

退出码: 0 全部通过；1 存在失败。

说明:
  - 静态层无需 AutoCAD，秒级完成，适合挂在 pre-commit。
  - 运行时 / harness / 冒烟层需要本机装有 accoreconsole（随 AutoCAD 2013+ 自带）。
  - 未安装 CAD 时，运行时相关脚本会标记为 SKIP，不视为失败。
  - 单个 accoreconsole 调用有超时保护，超时会尝试结束整个进程树，避免 CI 卡死。
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TESTS_DIR = ROOT / "tests"
HARNESS_LSP = ROOT / "_test_harness.lsp"
HARNESS_LOG = ROOT / "_test_results.log"
SMOKE_LSP = TESTS_DIR / "autocad_2024_smoke.lsp"

STATIC_TIMEOUT = 60       # 静态检查单个脚本超时
RUNTIME_TIMEOUT = 300     # 运行时验证单个脚本超时
ACCORE_TIMEOUT = 300      # 单次 accoreconsole 调用超时
PROBE_TIMEOUT = 90        # accoreconsole 探针超时（首启约 30-60s）

NO_ACCORE_MARKER = "未找到 accoreconsole.exe"


# ---------------------------------------------------------------------------
# accoreconsole 定位与进程执行
# ---------------------------------------------------------------------------

def locate_accoreconsole() -> str | None:
    """定位 accoreconsole.exe（PATH 优先，其次常见安装路径）。"""
    found = shutil.which("accoreconsole.exe")
    if found:
        return found
    for version in ("2024", "2025", "2026"):
        candidate = Path(rf"C:\Program Files\Autodesk\AutoCAD {version}\accoreconsole.exe")
        if candidate.exists():
            return str(candidate)
    return None


def decode_accore_output(data: bytes) -> str:
    """accoreconsole 输出编码不稳定（utf-16le / utf-8 / gbk 都可能），逐种尝试。"""
    if data.startswith((b"\xff\xfe", b"\xfe\xff")):
        return data.decode("utf-16", errors="replace")
    for enc in ("utf-16-le", "utf-8", "gbk"):
        try:
            text = data.decode(enc)
        except (UnicodeDecodeError, LookupError):
            continue
        if "\ufffd" not in text:
            return text
    return data.decode("utf-16-le", errors="replace")


def run_subprocess(
    cmd: list[str],
    timeout: int,
    *,
    decode: str | None = None,
) -> tuple[int | None, str]:
    """执行子进程；超时则结束整个进程树，返回 (returncode, 输出)。

    returncode=None 表示超时。decode=None 时按 utf-8 解码；decode 给定
    编码策略名时交给 decode_accore_output 处理。
    """
    env = dict(os.environ)
    env["PYTHONIOENCODING"] = "utf-8"
    proc = subprocess.Popen(
        cmd,
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
    )
    try:
        stdout, stderr = proc.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        # 结束整个进程树，避免残留 accoreconsole
        if proc.pid:
            subprocess.run(
                ["taskkill", "/F", "/T", "/PID", str(proc.pid)],
                capture_output=True,
            )
        try:
            proc.kill()
        except OSError:
            pass
        try:
            proc.wait(timeout=10)
        except (subprocess.TimeoutExpired, OSError):
            pass
        return None, "TIMEOUT"
    raw = (stdout or b"") + (stderr or b"")
    if decode is None:
        output = raw.decode("utf-8", errors="replace")
    else:
        output = decode_accore_output(raw)
    return proc.returncode, output


# ---------------------------------------------------------------------------
# 测试发现
# ---------------------------------------------------------------------------

def discover() -> dict[str, list[Path]]:
    """把 tests/verify_*.py 分成 静态 / 运行时 两类。"""
    all_scripts = sorted(TESTS_DIR.glob("verify_*.py"))
    runtime = [
        p for p in all_scripts
        if "accoreconsole" in p.read_text(encoding="utf-8", errors="replace")
    ]
    static = [p for p in all_scripts if p not in runtime]
    return {"static": static, "runtime": runtime}


# ---------------------------------------------------------------------------
# 各层执行
# ---------------------------------------------------------------------------

def run_verify_script(path: Path, is_runtime: bool) -> str:
    """运行单个 verify_*.py，返回结果描述字符串。"""
    name = path.name
    timeout = RUNTIME_TIMEOUT if is_runtime else STATIC_TIMEOUT
    code, output = run_subprocess([sys.executable, str(path)], timeout)
    if code is None:
        return f"  [FAIL] {name}（超时 {timeout}s）"
    if code == 0:
        return f"  [PASS] {name}"
    if NO_ACCORE_MARKER in output:
        return f"  [SKIP] {name}（未找到 accoreconsole.exe，跳过运行时验证）"
    tail = output.strip().splitlines()[-3:]
    detail = "\n".join("      " + line for line in tail) if tail else "      <无输出>"
    return f"  [FAIL] {name}\n{detail}"


def run_layer(title: str, paths: list[Path], is_runtime: bool) -> tuple[int, int, int]:
    """执行一层 verify 脚本，返回 (通过, 失败, 跳过)。"""
    passed = failed = skipped = 0
    print(f"\n[{title}]")
    for path in paths:
        result = run_verify_script(path, is_runtime)
        print(result)
        if "[PASS]" in result:
            passed += 1
        elif "[FAIL]" in result:
            failed += 1
        elif "[SKIP]" in result:
            skipped += 1
    if not paths:
        print("  (无)")
    return passed, failed, skipped


def probe_accoreconsole(accore: str) -> bool:
    """发送最小 ping 命令，确认 accoreconsole 能启动并响应。"""
    with tempfile.TemporaryDirectory(prefix="cc_probe_") as tmp:
        scr_path = Path(tmp) / "probe.scr"
        scr_path.write_text('(princ "ACCORE_PING_OK")\n_.quit _y\n', encoding="ascii")
        code, output = run_subprocess([accore, "/s", str(scr_path)], PROBE_TIMEOUT, decode="accore")
    return code is not None and "ACCORE_PING_OK" in output


def run_harness(accore: str) -> tuple[int, int]:
    """运行 _test_harness.lsp（accoreconsole 驱动），解析 _test_results.log。"""
    passed = failed = 0
    print("\n[单元测试 harness: _test_harness.lsp]")
    if not HARNESS_LSP.exists():
        print(f"  [FAIL] 未找到 {HARNESS_LSP.name}")
        return 0, 1
    scr = (
        '(setvar "SECURELOAD" 0)\n'
        "(vl-load-com)\n"
        f'(load "{HARNESS_LSP.as_posix()}")\n'
        "(run-all-tests)\n"
        "_.quit _y\n"
    )
    with tempfile.TemporaryDirectory(prefix="cc_harness_") as tmp:
        scr_path = Path(tmp) / "harness.scr"
        scr_path.write_text(scr, encoding="ascii")
        code, output = run_subprocess([accore, "/s", str(scr_path)], ACCORE_TIMEOUT, decode="accore")
    if code is None:
        print(f"  [FAIL] accoreconsole 超时 {ACCORE_TIMEOUT}s")
        return 0, 1
    if not HARNESS_LOG.exists():
        print("  [FAIL] 未生成 _test_results.log，CAD 可能未正常运行")
        return 0, 1
    log_text = _decode_log(HARNESS_LOG.read_bytes())
    m_pass = re.search(r"通过\s*[:：]?\s*(\d+)", log_text)
    m_fail = re.search(r"失败\s*[:：]?\s*(\d+)", log_text)
    passed = int(m_pass.group(1)) if m_pass else 0
    failed = int(m_fail.group(1)) if m_fail else 0
    print(f"  [PASS] harness 通过 {passed}，失败 {failed}")
    if failed:
        for line in log_text.splitlines():
            if "[FAIL]" in line:
                print("      " + line.strip())
    return passed, failed


def run_smoke(accore: str) -> tuple[int, int]:
    """运行 tests/autocad_2024_smoke.lsp，检查 [CCSMOKE] Result: PASS。"""
    print("\n[冒烟测试: tests/autocad_2024_smoke.lsp]")
    if not SMOKE_LSP.exists():
        print(f"  [FAIL] 未找到 {SMOKE_LSP.name}")
        return 0, 1
    scr = (
        '(setvar "SECURELOAD" 0)\n'
        f'(load "{SMOKE_LSP.as_posix()}")\n'
    )
    with tempfile.TemporaryDirectory(prefix="cc_smoke_") as tmp:
        scr_path = Path(tmp) / "smoke.scr"
        scr_path.write_text(scr, encoding="ascii")
        code, output = run_subprocess([accore, "/s", str(scr_path)], ACCORE_TIMEOUT, decode="accore")
    if code is None:
        print(f"  [FAIL] accoreconsole 超时 {ACCORE_TIMEOUT}s")
        return 0, 1
    # 判定：没有 FAIL 标记 且 最后结果是 PASS 才算通过；
    # 没有产生结果标记说明脚本未完整执行，按失败处理。
    results = re.findall(r"\[CCSMOKE\] Result: (PASS|FAIL)", output)
    last_result = results[-1] if results else None
    if "[CCSMOKE] FAIL" not in output and last_result == "PASS":
        print("  [PASS] 冒烟测试全部通过")
        return 1, 0
    items = re.findall(r"\[CCSMOKE\] (?:FAIL|Item): (.*)", output)
    for item in items[-5:]:
        print(f"      FAIL: {item.strip()}")
    if last_result is None:
        print("  [FAIL] 冒烟测试未产生结果标记（脚本可能未完整执行）")
    else:
        print(f"  [FAIL] 冒烟测试存在失败（Result: {last_result}）")
    return 0, 1


def _decode_log(data: bytes) -> str:
    """harness 日志是 AutoCAD 按系统代码页写入的，gbk/utf-8 都试。"""
    for enc in ("gbk", "utf-8"):
        try:
            return data.decode(enc)
        except (UnicodeDecodeError, LookupError):
            continue
    return data.decode("gbk", errors="replace")


# ---------------------------------------------------------------------------
# 入口
# ---------------------------------------------------------------------------

def _print_discovery(discovery: dict[str, list[Path]], mode: str) -> None:
    print(f"模式: --{mode}")
    print("\n[静态检查]")
    for p in discovery["static"]:
        print(f"  {p.name}")
    if mode in ("runtime", "harness", "all"):
        print("\n[运行时验证]")
        for p in discovery["runtime"]:
            print(f"  {p.name}")


def main() -> int:
    parser = argparse.ArgumentParser(description="AutoLISP 一键测试入口")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--static", action="store_true", help="仅静态检查（默认）")
    group.add_argument("--runtime", action="store_true", help="静态 + 运行时验证（需 accoreconsole）")
    group.add_argument("--harness", action="store_true", help="静态 + 运行时 + 单元测试 harness")
    group.add_argument("--all", action="store_true", help="静态 + 运行时 + harness + 冒烟")
    parser.add_argument("--list", action="store_true", help="仅列出将执行的测试")
    args = parser.parse_args()

    discovery = discover()
    mode = "all" if args.all else "harness" if args.harness else "runtime" if args.runtime else "static"

    if args.list:
        _print_discovery(discovery, mode)
        return 0

    accore = locate_accoreconsole() if mode != "static" else None

    print("=" * 60)
    print("  AutoLISP 测试入口  run_tests.py")
    print(f"  模式: --{mode}")
    print(f"  accoreconsole: {accore or '未找到（静态模式无需）'}")
    print("=" * 60)

    t0 = time.time()
    total_pass = total_fail = total_skip = 0

    # 1. 静态检查（无需 CAD，恒执行）
    p, f, s = run_layer("静态检查", discovery["static"], is_runtime=False)
    total_pass, total_fail, total_skip = p, f, s

    # 2~4. 需要 accoreconsole 的层
    if mode != "static":
        if not accore:
            print("\n[警告] 未找到 accoreconsole.exe，运行时相关层已跳过（不视为失败）。")
            print("       请在本机安装 AutoCAD 后重试。")
        else:
            print("\n[accoreconsole] 探针测试中（首启约 30-60s，请稍候）...", flush=True)
            if not probe_accoreconsole(accore):
                print("[accoreconsole] 无响应，运行时相关层已跳过（不视为失败）。")
                print("       可能是 CAD 未授权、首启初始化卡住，或当前 shell 环境受限。")
                total_skip += 1
            else:
                if mode in ("runtime", "harness", "all"):
                    p, f, s = run_layer("运行时验证", discovery["runtime"], is_runtime=True)
                    total_pass += p; total_fail += f; total_skip += s
                if mode in ("harness", "all"):
                    p, f = run_harness(accore)
                    total_pass += p; total_fail += f
                if mode == "all":
                    p, f = run_smoke(accore)
                    total_pass += p; total_fail += f

    elapsed = time.time() - t0
    print("\n" + "=" * 60)
    print("  汇总")
    print(f"    通过: {total_pass}")
    print(f"    失败: {total_fail}")
    print(f"    跳过: {total_skip}")
    print(f"    用时: {elapsed:.1f}s")
    if total_fail:
        print("  结果: FAIL")
    elif total_pass == 0 and total_skip == 0:
        print("  结果: FAIL（没有执行任何测试，请检查 discover() 结果）")
    else:
        print("  结果: PASS")
    print("=" * 60)
    return 1 if total_fail else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\n已中断")
        raise SystemExit(130)
