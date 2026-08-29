from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
UC_CORE = ROOT / "unified-lib" / "uc-core.lsp"
TB_CORE = ROOT / "TB-Toolbox" / "tb-core.lsp"
TB_BLK = ROOT / "TB-Toolbox" / "tb-lib-blk.lsp"


def build_probe_lsp() -> str:
    uc_core = str(UC_CORE).replace("\\", "\\\\")
    tb_core = str(TB_CORE).replace("\\", "\\\\")
    tb_blk = str(TB_BLK).replace("\\", "\\\\")
    return f"""(vl-load-com)
(load "{uc_core}")
(load "{tb_core}")
(load "{tb_blk}")
(setq cc:missing-name "CC_DOES_NOT_EXIST_20260505")
(entmake '((0 . "BLOCK") (2 . "CC_TEST_BLOCK_20260505") (70 . 0) (10 0.0 0.0 0.0)))
(entmake '((0 . "ENDBLK")))
(princ (strcat "\\n[EXISTS] layer-core=" (if (uc:layer-exists-p "0") "T" "NIL")))
(princ (strcat "\\n[EXISTS] layer-missing=" (if (uc:layer-exists-p cc:missing-name) "T" "NIL")))
(princ (strcat "\\n[EXISTS] style-core=" (if (uc:style-exists-p (getvar "TEXTSTYLE")) "T" "NIL")))
(princ (strcat "\\n[EXISTS] style-missing=" (if (uc:style-exists-p cc:missing-name) "T" "NIL")))
(princ (strcat "\\n[EXISTS] block-core=" (if (uc:block-exists-p "CC_TEST_BLOCK_20260505") "T" "NIL")))
(princ (strcat "\\n[EXISTS] block-blk=" (if (blk:exists? "CC_TEST_BLOCK_20260505") "T" "NIL")))
(princ (strcat "\\n[EXISTS] block-missing=" (if (uc:block-exists-p cc:missing-name) "T" "NIL")))
(princ (strcat "\\n[EXISTS] nil-style=" (if (uc:style-exists-p nil) "T" "NIL")))
(princ (strcat "\\n[EXISTS] nil-block=" (if (uc:block-exists-p nil) "T" "NIL")))
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
        raise AssertionError("未找到 accoreconsole.exe，无法执行存在性判断运行时验证")

    with tempfile.TemporaryDirectory(prefix="cc_exists_") as temp_dir:
        temp_path = Path(temp_dir)
        probe_lsp = temp_path / "verify_symbol_exists_runtime.lsp"
        probe_scr = temp_path / "verify_symbol_exists_runtime.scr"

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

    for marker in (
        "[EXISTS] layer-core=T",
        "[EXISTS] layer-missing=NIL",
        "[EXISTS] style-core=T",
        "[EXISTS] style-missing=NIL",
        "[EXISTS] block-core=T",
        "[EXISTS] block-blk=T",
        "[EXISTS] block-missing=NIL",
        "[EXISTS] nil-style=NIL",
        "[EXISTS] nil-block=NIL",
    ):
        assert marker in output, f"存在性判断运行时验证缺少预期结果: {marker}"

    print("PASS: 存在性判断统一包装运行时验证通过")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
