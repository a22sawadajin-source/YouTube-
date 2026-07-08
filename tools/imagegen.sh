#!/usr/bin/env bash
# 使い方: tools/imagegen.sh <プロンプト> <出力先.png>
# thumbnail-designer / visual-asset-collector から呼び出される想定のラッパー。
# 実際の画像生成API（例: Stable Diffusion, DALL-E など）の呼び出しに置き換えて使う。
set -euo pipefail

PROMPT="${1:?usage: imagegen.sh <prompt> <output.png>}"
OUTPUT="${2:?usage: imagegen.sh <prompt> <output.png>}"

echo "[imagegen.sh] TODO: プロンプト『${PROMPT}』から ${OUTPUT} を生成する処理を実装してください" >&2
exit 1
