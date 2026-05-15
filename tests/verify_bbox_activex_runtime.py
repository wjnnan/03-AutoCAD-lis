from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
UC_CORE = ROOT / "unified-lib" / "uc-core.lsp"
TB_CORE = ROOT / "TB-Toolbox" / "tb-core.lsp"
TB_POINT = ROOT / "TB-Toolbox" / "tb-lib-point.lsp"
TB_CURVE = ROOT / "TB-Toolbox" / "tb-lib-curve.lsp"
TB_ENTITY = ROOT / "TB-Toolbox" / "tb-lib-entity.lsp"


def build_probe_lsp() -> str:
    uc_core = str(UC_CORE).replace("\\", "\\\\")
    tb_core = str(TB_CORE).replace("\\", "\\\\")
    tb_point = str(TB_POINT).replace("\\", "\\\\")
    tb_curve = str(TB_CURVE).replace("\\", "\\\\")
    tb_entity = str(TB_ENTITY).replace("\\", "\\\\")
    return f"""(vl-load-com)
(load "{uc_core}")
(load "{tb_core}")
(load "{tb_point}")
(load "{tb_curve}")
(load "{tb_entity}")
(setq cc:line (entmakex '((0 . "LINE") (10 1.0 2.0 0.0) (11 4.0 6.0 0.0))))
(setq cc:box-wrap (entity:bbox-activex cc:line))
(princ (strcat "\\n[BBOX] nil=" (if (entity:bbox-activex nil) "T" "NIL")))
(princ (strcat "\\n[BBOX] wrapper=" (if cc:box-wrap "T" "NIL")))
(princ (strcat "\\n[BBOX] min=" (vl-princ-to-string (car cc:box-wrap))))
(princ (strcat "\\n[BBOX] max=" (vl-princ-to-string (cadr cc:box-wrap))))
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
        raise AssertionError("未找到 accoreconsole.exe，无法执行 bbox-activex 运行时验证")

    with tempfile.TemporaryDirectory(prefix="cc_bbox_") as temp_dir:
        temp_path = Path(temp_dir)
        probe_lsp = temp_path / "verify_bbox_activex_runtime.lsp"
        probe_scr = temp_path / "verify_bbox_activex_runtime.scr"

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

    assert "[BBOX] nil=NIL" in output, "entity:bbox-activex 对 nil 输入未安全返回 NIL"
    assert "[BBOX] wrapper=T" in output, "entity:bbox-activex 未返回有效包围盒"
    assert "[BBOX] min=(1.0 2.0 0.0)" in output, "entity:bbox-activex 最小点结果异常"
    assert "[BBOX] max=(4.0 6.0 0.0)" in output, "entity:bbox-activex 最大点结果异常"

    print("PASS: bbox-activex 运行时验证通过")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
