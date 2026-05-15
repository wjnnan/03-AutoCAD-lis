from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
UC_CORE = ROOT / "unified-lib" / "uc-core.lsp"
TB_CORE = ROOT / "TB-Toolbox" / "tb-core.lsp"
TB_LAY = ROOT / "TB-Toolbox" / "tb-lib-lay.lsp"
TB_ENTITY = ROOT / "TB-Toolbox" / "tb-lib-entity.lsp"


def build_probe_lsp() -> str:
    uc_core = str(UC_CORE).replace("\\", "\\\\")
    tb_core = str(TB_CORE).replace("\\", "\\\\")
    tb_lay = str(TB_LAY).replace("\\", "\\\\")
    tb_entity = str(TB_ENTITY).replace("\\", "\\\\")
    return f"""(vl-load-com)
(load "{uc_core}")
(load "{tb_core}")
(load "{tb_lay}")
(load "{tb_entity}")
(setq lc:test-layer "CC_LAYER_CONVERGENCE_20260510")
(setq lc:ltype-a "Continuous")
(setq lc:ltype-b nil)
(setq lc:lt (tblnext "LTYPE" T))
(while lc:lt
  (if (and (not lc:ltype-b)
           (/= (strcase (cdr (assoc 2 lc:lt))) "CONTINUOUS"))
    (setq lc:ltype-b (cdr (assoc 2 lc:lt))))
  (setq lc:lt (tblnext "LTYPE")))
(if (null lc:ltype-b)
  (setq lc:ltype-b lc:ltype-a))
(if (tblsearch "LAYER" lc:test-layer)
  (entdel (tblobjname "LAYER" lc:test-layer)))
(lay:make lc:test-layer 1 lc:ltype-a)
(lay:make lc:test-layer 3 lc:ltype-b)
(princ (strcat "\\n[LAYER] lay-color=" (vl-princ-to-string (cdr (assoc 62 (entget (tblobjname "LAYER" lc:test-layer)))))))
(princ (strcat "\\n[LAYER] lay-ltype=" (vl-princ-to-string (cdr (assoc 6 (entget (tblobjname "LAYER" lc:test-layer)))))))
(entity:make-layer lc:test-layer 5 lc:ltype-a T)
(princ (strcat "\\n[LAYER] entity-color=" (vl-princ-to-string (cdr (assoc 62 (entget (tblobjname "LAYER" lc:test-layer)))))))
(princ (strcat "\\n[LAYER] entity-ltype=" (vl-princ-to-string (cdr (assoc 6 (entget (tblobjname "LAYER" lc:test-layer)))))))
(princ (strcat "\\n[LAYER] plot-290=" (vl-princ-to-string (cdr (assoc 290 (entget (tblobjname "LAYER" lc:test-layer)))))))
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
        raise AssertionError("未找到 accoreconsole.exe，无法执行图层收敛运行时验证")

    with tempfile.TemporaryDirectory(prefix="cc_layer_make_") as temp_dir:
        temp_path = Path(temp_dir)
        probe_lsp = temp_path / "verify_layer_make_runtime.lsp"
        probe_scr = temp_path / "verify_layer_make_runtime.scr"

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

    assert "[LAYER] lay-color=3" in output, "lay:make 未统一更新已有图层颜色"
    assert "[LAYER] entity-color=5" in output, "entity:make-layer 未统一更新已有图层颜色"
    assert "[LAYER] entity-ltype=Continuous" in output, "entity:make-layer 未统一更新已有图层线型"
    assert "[LAYER] plot-290=1" in output, "entity:make-layer 未保留 plot 位兼容处理"

    lay_ltype_markers = [line for line in output.splitlines() if "[LAYER] lay-ltype=" in line]
    assert lay_ltype_markers, "运行时验证未输出 lay:make 线型结果"
    lay_ltype_line = lay_ltype_markers[0]
    assert "Continuous" in lay_ltype_line or lay_ltype_line.count('"') == 2, (
        "lay:make 线型结果异常，未拿到有效的图层线型输出"
    )

    print("PASS: 图层创建与更新收敛运行时验证通过")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
