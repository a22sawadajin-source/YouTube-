#!/usr/bin/env bash
# 使い方: scripts/tts.sh <input_text_file> <output_mp3_path>
set -euo pipefail

INPUT_TEXT_FILE="$1"
OUTPUT_PATH="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/../.env" ] && source "$SCRIPT_DIR/../.env"

if [ -z "${TTS_API_KEY:-}" ]; then
  echo "TTS_API_KEY が未設定です（.env を確認してください）" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"

curl -sS -X POST "$TTS_API_URL" \
  -H "Authorization: Bearer $TTS_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -Rn --rawfile text "$INPUT_TEXT_FILE" --arg voice "${TTS_VOICE:-ja-JP-Standard-A}" \
        '{text: $text, voice: $voice, format: "mp3"}')" \
  -o "$OUTPUT_PATH"

echo "生成完了: $OUTPUT_PATH"
