#!/usr/bin/env bash
# 使い方: scripts/fetch_analytics.sh <video_id> <output_json_path>
set -euo pipefail

VIDEO_ID="$1"
OUTPUT_PATH="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/../.env" ] && source "$SCRIPT_DIR/../.env"

for v in YOUTUBE_OAUTH_CLIENT_ID YOUTUBE_OAUTH_CLIENT_SECRET YOUTUBE_OAUTH_REFRESH_TOKEN; do
  if [ -z "${!v:-}" ]; then
    echo "$v が未設定です（.env を確認してください）" >&2
    exit 1
  fi
done

ACCESS_TOKEN=$(curl -sS -X POST https://oauth2.googleapis.com/token \
  -d client_id="$YOUTUBE_OAUTH_CLIENT_ID" \
  -d client_secret="$YOUTUBE_OAUTH_CLIENT_SECRET" \
  -d refresh_token="$YOUTUBE_OAUTH_REFRESH_TOKEN" \
  -d grant_type=refresh_token \
  | jq -r '.access_token')

END_DATE=$(date +%Y-%m-%d)
START_DATE=$(date -d "-28 days" +%Y-%m-%d 2>/dev/null || date -v-28d +%Y-%m-%d)

mkdir -p "$(dirname "$OUTPUT_PATH")"

curl -sS -G "https://youtubeanalytics.googleapis.com/v2/reports" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  --data-urlencode "ids=channel==${YOUTUBE_CHANNEL_ID}" \
  --data-urlencode "startDate=$START_DATE" \
  --data-urlencode "endDate=$END_DATE" \
  --data-urlencode "metrics=views,averageViewPercentage,impressions,impressionsClickThroughRate" \
  --data-urlencode "filters=video==${VIDEO_ID}" \
  -o "$OUTPUT_PATH"

echo "分析データ取得完了: $OUTPUT_PATH"
