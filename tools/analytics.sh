#!/usr/bin/env bash
# YouTube Analytics 取得ツール
# Usage: tools/analytics.sh <video_id> [days]
#
# 指定した動画のインプレッション、CTR、平均視聴時間、視聴維持率カーブ、
# 流入経路、登録転換を YouTube Analytics API から取得し、JSON を標準出力に返す。
# 認証は OAuth アクセストークンを YT_ACCESS_TOKEN で渡す。
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <video_id> [days]" >&2
  exit 1
fi

VIDEO_ID="$1"
DAYS="${2:-28}"

if [ -z "${YT_ACCESS_TOKEN:-}" ]; then
  echo "Error: YT_ACCESS_TOKEN must be set (OAuth token with yt-analytics.readonly scope)" >&2
  exit 1
fi

END_DATE=$(date -u +%Y-%m-%d)
START_DATE=$(date -u -d "-${DAYS} days" +%Y-%m-%d 2>/dev/null || date -u -v-"${DAYS}"d +%Y-%m-%d)

# インプレッション・CTR・平均視聴時間・視聴回数・登録転換
curl -sS -G "https://youtubeanalytics.googleapis.com/v2/reports" \
  --data-urlencode "ids=channel==MINE" \
  --data-urlencode "startDate=${START_DATE}" \
  --data-urlencode "endDate=${END_DATE}" \
  --data-urlencode "metrics=impressions,impressionsClickThroughRate,averageViewDuration,averageViewPercentage,views,subscribersGained" \
  --data-urlencode "filters=video==${VIDEO_ID}" \
  -H "Authorization: Bearer ${YT_ACCESS_TOKEN}" > /tmp/analytics_summary.json

# 視聴維持率カーブ（elapsedVideoTimeRatio ごとの audienceWatchRatio）
curl -sS -G "https://youtubeanalytics.googleapis.com/v2/reports" \
  --data-urlencode "ids=channel==MINE" \
  --data-urlencode "startDate=${START_DATE}" \
  --data-urlencode "endDate=${END_DATE}" \
  --data-urlencode "metrics=audienceWatchRatio,relativeRetentionPerformance" \
  --data-urlencode "dimensions=elapsedVideoTimeRatio" \
  --data-urlencode "filters=video==${VIDEO_ID}" \
  -H "Authorization: Bearer ${YT_ACCESS_TOKEN}" > /tmp/analytics_retention.json

# 流入経路（トラフィックソース）
curl -sS -G "https://youtubeanalytics.googleapis.com/v2/reports" \
  --data-urlencode "ids=channel==MINE" \
  --data-urlencode "startDate=${START_DATE}" \
  --data-urlencode "endDate=${END_DATE}" \
  --data-urlencode "metrics=views" \
  --data-urlencode "dimensions=insightTrafficSourceType" \
  --data-urlencode "filters=video==${VIDEO_ID}" \
  -H "Authorization: Bearer ${YT_ACCESS_TOKEN}" > /tmp/analytics_traffic.json

jq -n \
  --arg video_id "$VIDEO_ID" \
  --slurpfile summary /tmp/analytics_summary.json \
  --slurpfile retention /tmp/analytics_retention.json \
  --slurpfile traffic /tmp/analytics_traffic.json \
  '{video_id: $video_id, summary: $summary[0], retention_curve: $retention[0], traffic_sources: $traffic[0]}'
