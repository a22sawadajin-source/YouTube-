#!/usr/bin/env bash
# 使い方: tools/upload.sh <動画.mp4> <メタデータ.md> <公開日時ISO8601>
# publisher サブエージェントから呼び出される想定のラッパー。
# 実際のYouTube Data API呼び出し（予約投稿含む）に置き換えて使う。
set -euo pipefail

VIDEO="${1:?usage: upload.sh <video.mp4> <metadata.md> <publish_at_iso8601>}"
METADATA="${2:?usage: upload.sh <video.mp4> <metadata.md> <publish_at_iso8601>}"
PUBLISH_AT="${3:?usage: upload.sh <video.mp4> <metadata.md> <publish_at_iso8601>}"

echo "[upload.sh] TODO: ${VIDEO} を ${METADATA} のメタデータで ${PUBLISH_AT} に予約投稿する処理を実装してください" >&2
exit 1
