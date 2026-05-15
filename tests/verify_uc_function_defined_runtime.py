from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
UC_CORE = ROOT / "unified-lib" / "uc-core.lsp"
DIFFCHECK = ROOT / "DiffCheck" / "DiffCheck.lsp"


def build_probe_lsp() -> str:
    uc_core = str(UC_CORE).replace("\\", "\\\\")
    diffcheck = str(DIFFCHECK).replace("\\", "\\\\")
    return f"""(vl-load-com)
(load "{uc_core}")
(load "{diffcheck}")
(princ (strcat "\\n[UCFDEF] uc:com-available-p=" (if (uc:function-defined-p 'uc:com-available-p) "T" "NIL")))
(princ (strcat "\\n[UCFDEF] c:DFC=" (if (uc:function-defined-p 'c:DFC) "T" "NIL")))
(princ)
"""


def main() -> int:
    accoreconsole = shutil.which("accoreconsole.exe")
    if not accoreconsole:
        candidate = Path(r"C:\Program Files\Autodesk\AutoCAD 2024\accoreconsole.exe")
        if candidate.exists():
            accoreconsole = str(candidate)

    if not accoreconsole:
        raise AssertionError("未找到 accoreconsole.exe，无法执行运行时验证")

    with tempfile.TemporaryDirectory(prefix="cc_ucfdef_") as temp_dir:
        temp_path = Path(temp_dir)
        probe_lsp = temp_path / "verify_uc_function_defined_runtime.lsp"
        probe_scr = temp_path / "verify_uc_function_defined_runtime.scr"

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

    assert "[UCFDEF] uc:com-available-p=T" in output, \
        "uc:function-defined-p 在 accoreconsole 中未识别 uc:com-available-p"
    assert "[UCFDEF] c:DFC=T" in output, \
        "uc:function-defined-p 在 accoreconsole 中未识别 c:DFC"

    print("PASS: uc:function-defined-p 运行时兼容性检查通过")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
