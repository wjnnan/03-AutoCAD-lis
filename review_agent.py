# -*- coding: utf-8 -*-
"""审查 agent：消费 review_requested 事件，调用 Codex 做对抗审查，写回 review_completed。

用法：python review_agent.py [--once|--watch]
  --once   处理当前所有未完成的 review_requested 后退出
  --watch  持续监听（默认）
"""
import glob
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime, timezone

PROTO = os.path.expanduser('~/.ccxp2/protocol')
EVENTS_CODEX = os.path.join(PROTO, 'events', 'codex')
EVENTS_CLAUDE = os.path.join(PROTO, 'events', 'claude')
ARTIFACTS = os.path.join(PROTO, 'artifacts')
MANIFEST = os.path.join(PROTO, 'manifest.json')
PROJECT = os.getcwd()
REPORT = os.path.join(PROJECT, '代码对抗审核报告.md')
CODEX_CMD = os.path.expanduser('~/AppData/Roaming/npm/codex.cmd')

REVIEW_PROMPT = """你是独立对抗代码审核员。请对 TB-Toolbox 工具箱重构做对抗式静态审查，寻找漏洞、边界问题、异常处理缺陷和业务偏差。

严格按顺序读取审查材料（当前工作目录下，均为 UTF-8 编码）：
1. _codex-review/README.md —— 审查上下文、范围、编码说明
2. _codex-review/任务实现结构清单.md —— 需求、方案、文件更改列表、已知风险
3. _codex-review/TB-Toolbox/*.lsp、*.dcl、_codex-review/unified-lib/*.lsp —— 源码

本次重构包含三类改动，逐类重点审查：
- 主界面 6→7 标签页、125 命令铺入：重点查 DCL 的 key 与 tb-main.lsp 的 bind 是否双向一致、有无遗漏按钮。
- 函数统一瘦身：重点查删除的 5 个存在性判断入口 + 2 个 uc 本地定义是否有残留调用。
- 2004~最新版兼容：重点查 GBK 转码后中文是否完整、vl-load-com 修复、4 处括号修复（sys:load-config / curve:area / c:rt / c:RL）是否正确。

审查维度：逻辑漏洞、边界 case（nil/空选择集/除零/越界）、异常处理、函数删除残留、DCL-lsp 一致性、编码完整性、2004 API 兼容性、业务匹配。

输出要求：只输出《代码对抗审核报告》的 markdown 正文，不要任何额外说明。结构如下：

# 代码对抗审核报告

## 总体结论
- 高风险：N 项（必须修复）
- 中风险：N 项（建议修复）
- 低风险：N 项（可选优化）

## 问题清单
| 编号 | 风险等级 | 文件路径 | 代码位置 | 问题描述 | 触发条件 | 修改建议 |
|---|---|---|---|---|---|---|
| BUG-01 | 高 | ... | ... | ... | ... | ... |

## 业务匹配审查
（对比原始需求，指出实现偏差、遗漏、错误）

## 复审要求
（说明哪些问题必须修复才能闭环）
"""


def parse_frontmatter(text):
    m = re.search(r'^---\n(.*?)\n---', text, re.DOTALL)
    if not m:
        return {}
    fm = {}
    for line in m.group(1).split('\n'):
        if ':' in line:
            k, v = line.split(':', 1)
            fm[k.strip()] = v.strip().strip("'\"")
    return fm


def load_manifest():
    with open(MANIFEST, encoding='utf-8') as f:
        return json.load(f)


def save_manifest(m):
    with open(MANIFEST, 'w', encoding='utf-8') as f:
        json.dump(m, f, ensure_ascii=False, indent=2)


def is_processed(event_id):
    """检查该 review_requested 是否已有对应 review_completed 回传。"""
    slug = event_id.replace('evt-', '').replace('-requested', '')
    completed = glob.glob(os.path.join(EVENTS_CLAUDE, f'evt-{slug}-completed.md'))
    return bool(completed) or os.path.exists(REPORT)


def run_codex_review():
    """调用 codex exec 执行审查，返回输出文本。"""
    try:
        result = subprocess.run(
            [CODEX_CMD, 'exec', REVIEW_PROMPT],
            capture_output=True, text=True, encoding='utf-8',
            cwd=PROJECT, timeout=1800,
            stdin=subprocess.DEVNULL,  # 关键：避免 codex 阻塞等待 stdin 输入
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip(), None
        return result.stdout.strip(), result.stderr.strip() or f'codex 退出码 {result.returncode}'
    except subprocess.TimeoutExpired:
        return '', 'codex 审查超时（1800s）'
    except Exception as e:
        return '', f'codex 执行异常: {e}'


def process_one(event_file):
    with open(event_file, encoding='utf-8') as f:
        content = f.read()
    fm = parse_frontmatter(content)
    event_id = fm.get('event_id', os.path.basename(event_file).replace('.md', ''))
    slug = event_id.replace('evt-', '').replace('-requested', '')

    if is_processed(event_id):
        return False

    print(f'[审查 agent] 处理 {event_id}，调用 Codex 审查...', flush=True)
    output, err = run_codex_review()

    # 保存报告
    with open(REPORT, 'w', encoding='utf-8') as f:
        f.write(output if output else f'# 代码对抗审核报告\n\n审查失败：{err}\n')

    # 写 review_completed 事件
    manifest = load_manifest()
    now = datetime.now(timezone.utc).isoformat()
    completed_id = f'evt-{slug}-completed'
    completed = f"""---
protocol: CCXP-2
conversation_id: {manifest['conversation_id']}
round: {manifest['current_round']}
event_id: {completed_id}
parent_event_id: {event_id}
from: codex
to: claude
phase: stage2-review
event_type: review_completed
artifact_ref: 代码对抗审核报告.md
receipt_required: false
created_at: '{now}'
---

对抗审查完成，报告见 {REPORT}。
"""
    os.makedirs(EVENTS_CLAUDE, exist_ok=True)
    with open(os.path.join(EVENTS_CLAUDE, f'{completed_id}.md'), 'w', encoding='utf-8') as f:
        f.write(completed)

    # 更新 manifest
    manifest['current_phase'] = 'stage3-fix'
    manifest['current_owner'] = 'claude'
    manifest['latest_event_id'] = completed_id
    manifest['latest_artifact'] = '代码对抗审核报告.md'
    manifest['updated_at'] = now
    save_manifest(manifest)

    print(f'[审查 agent] 完成，报告已写入 {REPORT}，事件 {completed_id} 已发出', flush=True)
    return True


def main():
    mode = '--watch'
    if len(sys.argv) > 1:
        mode = sys.argv[1]

    print(f'[审查 agent] 启动（{mode}），监听 events/codex/ 的 review_requested', flush=True)

    while True:
        files = sorted(glob.glob(os.path.join(EVENTS_CODEX, 'evt-review-*-requested.md')))
        handled = False
        for f in files:
            try:
                if process_one(f):
                    handled = True
            except Exception as e:
                print(f'[审查 agent] 处理 {f} 出错: {e}', flush=True)

        if mode == '--once':
            if files and not handled:
                print('[审查 agent] 所有 review_requested 均已处理或已有回传。', flush=True)
            elif not files:
                print('[审查 agent] 无 review_requested 事件。', flush=True)
            return

        time.sleep(20)


if __name__ == '__main__':
    main()
