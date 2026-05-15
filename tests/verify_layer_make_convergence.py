from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
UC_CORE = ROOT / "unified-lib" / "uc-core.lsp"
TB_LAY = ROOT / "TB-Toolbox" / "tb-lib-lay.lsp"
TB_ENTITY = ROOT / "TB-Toolbox" / "tb-lib-entity.lsp"


def extract_function(text: str, name: str) -> str:
    pattern = re.compile(rf"\(defun\s+{re.escape(name)}\b", re.IGNORECASE)
    match = pattern.search(text)
    if not match:
        raise AssertionError(f"未找到函数 {name}")

    start = match.start()
    depth = 0
    in_string = False
    escaped = False

    for index in range(start, len(text)):
        char = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue

        if char == '"':
            in_string = True
        elif char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return text[start:index + 1]

    raise AssertionError(f"函数括号不平衡 {name}")


def main() -> int:
    uc_core = UC_CORE.read_text(encoding="utf-8")
    tb_lay = TB_LAY.read_text(encoding="utf-8")
    tb_entity = TB_ENTITY.read_text(encoding="utf-8")

    ensure_layer = extract_function(uc_core, "uc:ensure-layer")
    lay_make = extract_function(tb_lay, "lay:make")
    entity_make_layer = extract_function(tb_entity, "entity:make-layer")

    assert "uc:layer-set-dxf name 62" in ensure_layer, (
        "uc:ensure-layer 必须在图层已存在时也统一更新颜色"
    )
    assert "uc:layer-set-dxf name 6" in ensure_layer, (
        "uc:ensure-layer 必须在图层已存在时也统一更新线型"
    )
    assert "(uc:ensure-layer name color linetype)" in lay_make, (
        "lay:make 必须收敛为 uc:ensure-layer 的兼容包装"
    )
    assert 'entmake (list \'(0 . "LAYER")' not in lay_make, (
        "lay:make 不应继续自维护独立的图层创建实现"
    )
    assert "(uc:ensure-layer name color linetype)" in entity_make_layer, (
        "entity:make-layer 必须继续复用统一核心图层实现"
    )
    assert "uc:layer-set-dxf name 290 1" in entity_make_layer, (
        "entity:make-layer 必须保留 plot 位兼容处理"
    )

    print("PASS: 图层创建入口已收敛到统一核心实现")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
