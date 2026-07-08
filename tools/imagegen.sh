#!/usr/bin/env bash
# 画像生成ツール
# Usage: tools/imagegen.sh <prompt> <out.png>
#
# 画像生成APIにプロンプトを送り、生成された画像を <out.png> に保存する。
# 実際のAPI連携先は IMAGEGEN_API_URL / IMAGEGEN_API_KEY で設定する。
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <prompt> <out.png>" >&2
  exit 1
fi

PROMPT="$1"
OUT="$2"

if [ -z "${IMAGEGEN_API_URL:-}" ] || [ -z "${IMAGEGEN_API_KEY:-}" ]; then
  echo "Error: IMAGEGEN_API_URL and IMAGEGEN_API_KEY must be set" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"

curl -sS -X POST "$IMAGEGEN_API_URL" \
  -H "Authorization: Bearer $IMAGEGEN_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(printf '{"prompt": %s}' "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$PROMPT")")" \
  -o "$OUT"
