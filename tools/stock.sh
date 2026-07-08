#!/usr/bin/env bash
# ストック素材検索ツール
# Usage: tools/stock.sh <keyword>
#
# ストック素材APIのキーワード検索を行い、候補素材の情報を標準出力に返す。
# 実際のAPI連携先は STOCK_API_URL / STOCK_API_KEY で設定する。
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <keyword>" >&2
  exit 1
fi

KEYWORD="$1"

if [ -z "${STOCK_API_URL:-}" ] || [ -z "${STOCK_API_KEY:-}" ]; then
  echo "Error: STOCK_API_URL and STOCK_API_KEY must be set" >&2
  exit 1
fi

curl -sS -G "$STOCK_API_URL" \
  --data-urlencode "query=$KEYWORD" \
  -H "Authorization: Bearer $STOCK_API_KEY"
