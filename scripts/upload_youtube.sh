#!/usr/bin/env bash
# 使い方: scripts/upload_youtube.sh <metadata.json> [publish_at_iso8601]
set -euo pipefail

METADATA_PATH="$1"
PUBLISH_AT="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/../.env" ] && source "$SCRIPT_DIR/../.env"

for v in YOUTUBE_OAUTH_CLIENT_ID YOUTUBE_OAUTH_CLIENT_SECRET YOUTUBE_OAUTH_REFRESH_TOKEN; do
  if [ -z "${!v:-}" ]; then
    echo "$v が未設定です（.env を確認してください）" >&2
    exit 1
  fi
done

TITLE=$(jq -r '.title' "$METADATA_PATH")
HASHTAGS=$(jq -r '(.hashtags // []) | join(" ")' "$METADATA_PATH")
DESCRIPTION=$(jq -r '.description' "$METADATA_PATH")
if [ -n "$HASHTAGS" ]; then
  DESCRIPTION="${DESCRIPTION}"$'\n\n'"${HASHTAGS}"
fi
TAGS_JSON=$(jq -c '.tags' "$METADATA_PATH")
CATEGORY=$(jq -r '.category // "22"' "$METADATA_PATH")
VIDEO_PATH=$(jq -r '.video_path' "$METADATA_PATH")
THUMBNAIL_PATH=$(jq -r '.thumbnail_path' "$METADATA_PATH")

ACCESS_TOKEN=$(curl -sS -X POST https://oauth2.googleapis.com/token \
  -d client_id="$YOUTUBE_OAUTH_CLIENT_ID" \
  -d client_secret="$YOUTUBE_OAUTH_CLIENT_SECRET" \
  -d refresh_token="$YOUTUBE_OAUTH_REFRESH_TOKEN" \
  -d grant_type=refresh_token \
  | jq -r '.access_token')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo "OAuthトークンの取得に失敗しました" >&2
  exit 1
fi

STATUS="public"
PRIVACY_JSON="{\"privacyStatus\": \"$STATUS\"}"
if [ -n "$PUBLISH_AT" ]; then
  PRIVACY_JSON="{\"privacyStatus\": \"private\", \"publishAt\": \"$PUBLISH_AT\"}"
fi

SNIPPET_JSON=$(jq -n --arg title "$TITLE" --arg desc "$DESCRIPTION" \
  --argjson tags "$TAGS_JSON" --arg cat "$CATEGORY" \
  '{title: $title, description: $desc, tags: $tags, categoryId: $cat}')

RESPONSE=$(curl -sS -X POST \
  "https://www.googleapis.com/upload/youtube/v3/videos?uploadType=multipart&part=snippet,status" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -F "metadata={\"snippet\":$(echo "$SNIPPET_JSON"),\"status\":$(echo "$PRIVACY_JSON")};type=application/json" \
  -F "video=@$VIDEO_PATH;type=video/mp4")

VIDEO_ID=$(echo "$RESPONSE" | jq -r '.id')

if [ -z "$VIDEO_ID" ] || [ "$VIDEO_ID" = "null" ]; then
  echo "アップロードに失敗しました: $RESPONSE" >&2
  exit 1
fi

if [ -f "$THUMBNAIL_PATH" ]; then
  curl -sS -X POST \
    "https://www.googleapis.com/upload/youtube/v3/thumbnails/set?videoId=$VIDEO_ID" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: image/png" \
    --data-binary "@$THUMBNAIL_PATH" > /dev/null
fi

OUTPUT_DIR="$(dirname "$METADATA_PATH")"
jq -n --arg id "$VIDEO_ID" --arg url "https://youtu.be/$VIDEO_ID" \
  --arg status "$STATUS" --arg publish_at "$PUBLISH_AT" \
  '{video_id: $id, url: $url, status: $status, published_at: $publish_at}' \
  > "$OUTPUT_DIR/08_publish_result.json"

echo "アップロード完了: https://youtu.be/$VIDEO_ID"
