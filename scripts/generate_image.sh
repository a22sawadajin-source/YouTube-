#!/usr/bin/env bash
# 使い方: scripts/generate_image.sh <prompt> <output_png_path>
set -euo pipefail

PROMPT="$1"
OUTPUT_PATH="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/../.env" ] && source "$SCRIPT_DIR/../.env"

if [ -z "${IMAGE_GEN_API_KEY:-}" ]; then
  echo "IMAGE_GEN_API_KEY が未設定です（.env を確認してください）" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"

curl -sS -X POST "$IMAGE_GEN_API_URL" \
  -H "Authorization: Bearer $IMAGE_GEN_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg p "$PROMPT" '{prompt: $p, width: 1280, height: 720}')" \
  -o "$OUTPUT_PATH"

echo "生成完了: $OUTPUT_PATH"
