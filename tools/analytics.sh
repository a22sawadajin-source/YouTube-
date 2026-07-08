#!/usr/bin/env bash
# 使い方: tools/analytics.sh <開始日> <終了日> <出力先.json>
# analytics-optimizer サブエージェントから呼び出される想定のラッパー。
# 実際のYouTube Analytics API呼び出しに置き換えて使う。
set -euo pipefail

FROM="${1:?usage: analytics.sh <from_date> <to_date> <output.json>}"
TO="${2:?usage: analytics.sh <from_date> <to_date> <output.json>}"
OUTPUT="${3:?usage: analytics.sh <from_date> <to_date> <output.json>}"

echo "[analytics.sh] TODO: ${FROM}〜${TO} の分析データを取得して ${OUTPUT} に保存する処理を実装してください" >&2
exit 1
