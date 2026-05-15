from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
UC_CORE = ROOT / "unified-lib" / "uc-core.lsp"
TB_CORE = ROOT / "TB-Toolbox" / "tb-core.lsp"


def build_probe_lsp() -> str:
    uc_core = str(UC_CORE).replace("\\", "\\\\")
    tb_core = str(TB_CORE).replace("\\", "\\\\")
    return f"""(vl-load-com)
(load "{uc_core}")
(load "{tb_core}")
(princ (strcat "\\n[ALIST] wrapper=" (if (equal (sys:alist-put '((A . 1)) 'A 2) (uc:alist-put '((A . 1)) 'A 2)) "T" "NIL")))
(princ (strcat "\\n[ALIST] replace=" (vl-princ-to-string (sys:alist-put '((A . 1) (B . 2)) 'A 9))))
(princ (strcat "\\n[ALIST] append=" (vl-princ-to-string (sys:alist-put '((A . 1) (B . 2)) 'C 3))))
(princ (strcat "\\n[ALIST] nil-base=" (vl-princ-to-string (sys:alist-put nil 'A 1))))
(princ)
"""


def locate_accoreconsole() -> str | None:
    accoreconsole = shutil.which("accoreconsole.exe")
    if accoreconsole:
        return accoreconsole

    candidate = Path(r"C:\Program Files\Autodesk\AutoCAD 2024\accoreconsole.exe")
    if candidate.exists():
        return str(candidate)

    return None


def main() -> int:
    accoreconsole = locate_accoreconsole()
    if not accoreconsole:
        raise AssertionError("未找到 accoreconsole.exe，无法执行 alist-put 运行时验证")

    with tempfile.TemporaryDirectory(prefix="cc_alist_put_") as temp_dir:
        temp_path = Path(temp_dir)
        probe_lsp = temp_path / "verify_alist_put_runtime.lsp"
        probe_scr = temp_path / "verify_alist_put_runtime.scr"

        probe_lsp.write_text(build_probe_lsp(), encoding="utf-8")
        probe_scr.write_text(
            f'(setvar "SECURELOAD" 0)\n(load "{probe_lsp.as_posix()}")\n',
            encoding="ascii",
        )

        result = subprocess.run(
            [accoreconsole, "/s", str(probe_scr)],
            cwd=ROOT,
            capture_output=True,
            text=True,
            encoding="utf-16le",
            errors="replace",
            check=False,
        )

    output = result.stdout + result.stderr

    assert "[ALIST] wrapper=T" in output, "sys:alist-put 未与 uc:alist-put 保持一致"
    assert "[ALIST] replace=((A . 9) (B . 2))" in output, "sys:alist-put 替换已存在键失败"
    assert "[ALIST] append=((A . 1) (B . 2) (C . 3))" in output, "sys:alist-put 追加新键失败"
    assert "[ALIST] nil-base=((A . 1))" in output, "sys:alist-put 在空 alist 上追加失败"

    print("PASS: alist-put 统一包装运行时验证通过")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
