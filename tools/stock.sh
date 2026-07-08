#!/usr/bin/env bash
# 使い方: tools/stock.sh <検索キーワード> <出力先ディレクトリ>
# visual-asset-collector から呼び出される想定のラッパー。
# 実際のストック素材API（例: Pexels, Pixabay など）の呼び出しに置き換えて使う。
set -euo pipefail

KEYWORD="${1:?usage: stock.sh <keyword> <output_dir>}"
OUTDIR="${2:?usage: stock.sh <keyword> <output_dir>}"

mkdir -p "${OUTDIR}"
echo "[stock.sh] TODO: キーワード『${KEYWORD}』の素材を検索して ${OUTDIR} に保存する処理を実装してください" >&2
exit 1
