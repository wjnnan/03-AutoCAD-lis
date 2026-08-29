# -*- coding: utf-8 -*-
"""生成 *TB:CMD-CATALOG*（key 内部命令名 功能名 页号）并回写 tb-main.lsp。
从 PAGE-BINDS（tb-main.lsp）取 key+命令名，从按钮 label（tb-dcl-launcher.dcl）取功能名。
GBK 读写。--dry 只打印不写。"""
import io, re, sys

MAIN = 'TB-Toolbox/tb-main.lsp'
DCL = 'TB-Toolbox/tb-dcl-launcher.dcl'
PAGE_COUNTS = [45, 14, 11, 5, 8, 23, 19]

def read_gbk(p):
    return io.open(p, encoding='gbk').read()

def write_gbk(p, txt):
    io.open(p, 'wb').write(txt.encode('gbk'))

def parse_pages(expr):
    """expr 是 PAGE-BINDS 值主体（嵌套列表）。返回每页 [(key, cmd)]。"""
    # 去掉最外层括号，再提取顶层页块
    inner = expr[1:-1]
    depth, start, items = 0, None, []
    for i, ch in enumerate(inner):
        if ch == '(':
            if depth == 0:
                start = i
            depth += 1
        elif ch == ')':
            depth -= 1
            if depth == 0 and start is not None:
                items.append(inner[start:i + 1])
                start = None
    pages = []
    for blk in items:
        pairs = re.findall(r'\("(btn_\w+)"\s*\.\s*"([^"]*)"\)', blk)
        pages.append(pairs)
    return pages

def main():
    dry = '--dry' in sys.argv
    main_txt = read_gbk(MAIN)
    dcl = read_gbk(DCL)

    # 1. 解析 PAGE-BINDS
    idx = main_txt.find('*TB:PAGE-BINDS*')
    if idx < 0:
        sys.exit('FAIL: 未找到 *TB:PAGE-BINDS*')
    q = main_txt.find("'", idx)
    open_p = main_txt.find('(', q)
    depth, i = 0, open_p
    while i < len(main_txt):
        if main_txt[i] == '(':
            depth += 1
        elif main_txt[i] == ')':
            depth -= 1
            if depth == 0:
                binds_expr = main_txt[open_p:i + 1]
                break
        i += 1
    pages = parse_pages(binds_expr)
    counts = [len(p) for p in pages]
    print('每页项数:', counts, '| 总数:', sum(counts))
    if counts != PAGE_COUNTS:
        sys.exit('FAIL: 每页项数不符，期望 %s' % PAGE_COUNTS)

    # 2. 解析 DCL 按钮 label
    btns = re.findall(r':button\{label="([^"]+)";key="(btn_\w+)"', dcl)
    label_map = {k: label for label, k in btns}
    print('DCL 按钮数:', len(label_map))

    # 3. 生成目录
    catalog = []
    for page_idx, page in enumerate(pages):
        for key, cmd in page:
            if key not in label_map:
                sys.exit('FAIL: DCL 缺按钮 %s' % key)
            label = label_map[key]
            parts = label.rsplit(' ', 1)
            if len(parts) != 2 or not parts[0]:
                sys.exit('FAIL: label 无法切功能名: %s (%s)' % (key, label))
            fn = parts[0]
            catalog.append((key, cmd, fn, page_idx))

    # 4. 断言
    assert len(catalog) == 125, '总数 %d != 125' % len(catalog)
    for page_idx in range(7):
        n = len([c for c in catalog if c[3] == page_idx])
        assert n == PAGE_COUNTS[page_idx], '页%d 数量 %d' % (page_idx, n)

    # 5. 生成 LISP 字面量
    lines = ["(setq *TB:CMD-CATALOG* '("]
    for key, cmd, fn, page_idx in catalog:
        lines.append('  ("%s" "%s" "%s" %d)' % (key, cmd, fn, page_idx))
    lines.append("))")
    catalog_lisp = '\n'.join(lines)

    if dry:
        print('=== 生成的目录（前 10 项） ===')
        for l in lines[:12]:
            print(l)
        print('... 共 %d 项' % len(catalog))
        # 抽查
        for sample in [('btn_q',), ('btn_bpt',), ('btn_c1',), ('btn_13',)]:
            hit = [c for c in catalog if c[0] == sample[0]]
            if hit:
                print('抽查 %s: %s' % (sample[0], hit[0]))
        return

    # 6. 回写 tb-main.lsp：在 PAGE-BINDS 所在的外层 setq 完全闭合后插入
    # 幂等：已有目录先删除
    if '*TB:CMD-CATALOG*' in main_txt:
        cstart = main_txt.find('(setq *TB:CMD-CATALOG*')
        depth, j = 0, cstart
        while j < len(main_txt):
            if main_txt[j] == '(':
                depth += 1
            elif main_txt[j] == ')':
                depth -= 1
                if depth == 0:
                    main_txt = main_txt[:cstart] + main_txt[j + 1:]
                    break
            j += 1
        print('已移除旧目录，准备重新插入')
    # 定位外层 setq 闭合：*TB:BIND-ID* 10) 是其最后一个参数+闭合
    bidx = main_txt.find('*TB:BIND-ID* 10)')
    if bidx < 0:
        sys.exit('FAIL: 未找到 *TB:BIND-ID* 10) 外层 setq 闭合点')
    line_end = main_txt.find('\n', bidx)
    insert_at = line_end + 1
    new_main = main_txt[:insert_at] + '\n' + catalog_lisp + '\n' + main_txt[insert_at:]
    write_gbk(MAIN, new_main)
    print('已回写', MAIN, '共', len(catalog), '项')

if __name__ == '__main__':
    main()
