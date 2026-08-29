#!/usr/bin/env sh
# AutoLISP 一键测试入口（参数透传给 run_tests.py）
# 用法: ./test-all.sh [--static | --runtime | --harness | --all | --list]
cd "$(dirname "$0")" || exit 1
exec python run_tests.py "$@"
