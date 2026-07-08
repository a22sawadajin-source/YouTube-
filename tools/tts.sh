#!/usr/bin/env bash
# 使い方: tools/tts.sh <台本.md または テキストファイル> <出力先.mp3>
# voice-synthesizer サブエージェントから呼び出される想定のラッパー。
# 実際のTTSプロバイダ（例: ElevenLabs, Google Cloud TTS など）のAPI呼び出しに置き換えて使う。
set -euo pipefail

INPUT="${1:?usage: tts.sh <input> <output.mp3>}"
OUTPUT="${2:?usage: tts.sh <input> <output.mp3>}"

echo "[tts.sh] TODO: ${INPUT} を音声合成して ${OUTPUT} に保存する処理を実装してください" >&2
exit 1
