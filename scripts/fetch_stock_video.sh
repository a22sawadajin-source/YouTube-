#!/usr/bin/env bash
# 使い方: scripts/fetch_stock_video.sh <search_query> <output_path>
# STOCK_VIDEO_API_KEY が無ければ LOCAL_ASSETS_DIR から手動配置素材を探すフォールバック。
set -euo pipefail

QUERY="$1"
OUTPUT_PATH="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/../.env" ] && source "$SCRIPT_DIR/../.env"

mkdir -p "$(dirname "$OUTPUT_PATH")"

if [ -n "${STOCK_VIDEO_API_KEY:-}" ]; then
  RESULT_URL=$(curl -sS -G "$STOCK_VIDEO_API_URL" \
    -H "Authorization: Bearer $STOCK_VIDEO_API_KEY" \
    --data-urlencode "query=$QUERY" \
    | jq -r '.results[0].download_url')
  if [ -z "$RESULT_URL" ] || [ "$RESULT_URL" = "null" ]; then
    echo "検索結果なし: $QUERY" >&2
    exit 1
  fi
  curl -sS -o "$OUTPUT_PATH" "$RESULT_URL"
else
  echo "STOCK_VIDEO_API_KEY 未設定のため LOCAL_ASSETS_DIR (${LOCAL_ASSETS_DIR:-./assets/local}) から手動確認してください: $QUERY" >&2
  exit 1
fi

echo "取得完了: $OUTPUT_PATH (query: $QUERY)"
