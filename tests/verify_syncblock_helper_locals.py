from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
SYNCBLOCK = ROOT / "SyncBlock" / "SyncBlock.lsp"


def locals_of(text: str, name: str) -> set[str]:
    pattern = re.compile(rf"\(defun\s+{re.escape(name)}\s*\([^/]*\/([^)]*)\)", re.IGNORECASE)
    match = pattern.search(text)
    if not match:
        raise AssertionError(f"未找到或未声明局部变量的函数: {name}")
    return {item for item in re.split(r"\s+", match.group(1).strip()) if item}


def main() -> int:
    text = SYNCBLOCK.read_text(encoding="utf-8")

    object_array_locals = locals_of(text, "sb:object-list->safearray")
    apply_sync_locals = locals_of(text, "sb:apply-sync")

    assert "obj" in object_array_locals, "sb:object-list->safearray 必须将 obj 声明为局部变量"
    assert "obj" in apply_sync_locals, "sb:apply-sync 必须将 obj 声明为局部变量"

    print("PASS: SyncBlock 辅助函数局部变量检查通过")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL: {exc}")
        raise SystemExit(1)
