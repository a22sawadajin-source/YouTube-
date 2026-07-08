#!/usr/bin/env bash
# cron / 手動トリガー用のオーケストレーター。/produce スラッシュコマンドのシェル版。
# 各工程を非対話モードの `claude -p` で個別に呼び出し、順序と再現性を保証する。
#
# 使い方:
#   scripts/orchestrate.sh                      # run_id を自動採番、テーマ自動選定
#   scripts/orchestrate.sh "" "テーマ: 家庭用サーバーの選び方"
#   RUN_ID=2026-07-08_1200 scripts/orchestrate.sh   # 既存 run_id を再開
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

RUN_ID="${RUN_ID:-$(date +%Y-%m-%d_%H%M)}"
TOPIC="${1:-}"
PIPELINE_DIR="pipeline/$RUN_ID"
mkdir -p "$PIPELINE_DIR"

run_agent() {
  local agent="$1"
  local prompt="$2"
  echo "=== [$agent] 開始 ==="
  claude -p "$prompt" --agent "$agent"
  echo "=== [$agent] 完了 ==="
}

FEEDBACK_HINT=""
if [ -f "feedback/latest.md" ]; then
  FEEDBACK_HINT=" 前回の分析フィードバック=feedback/latest.md を必ず読み、企画に反映すること。"
fi

run_agent trend-researcher \
  "run_id=$RUN_ID, 出力先=$PIPELINE_DIR/01_research.md。テーマ指定: ${TOPIC:-指定なし（あなたが選定）}。${FEEDBACK_HINT}"

run_agent script-writer \
  "run_id=$RUN_ID。前工程の成果物: $PIPELINE_DIR/01_research.md を読み、出力先=$PIPELINE_DIR/02_script.md に台本を書く。"

run_agent title-thumbnail-strategist \
  "run_id=$RUN_ID。前工程の成果物: $PIPELINE_DIR/02_script.md を読み、出力先=$PIPELINE_DIR/03_titles_thumbnails.md にタイトル案とサムネ設計を書く。"

run_agent voice-synthesizer \
  "run_id=$RUN_ID。前工程の成果物: $PIPELINE_DIR/02_script.md を読み、出力先=$PIPELINE_DIR/04_narration.mp3 に音声を生成する。" &
PID_VOICE=$!

run_agent visual-asset-collector \
  "run_id=$RUN_ID。前工程の成果物: $PIPELINE_DIR/02_script.md を読み、出力先=$PIPELINE_DIR/04_assets/ に素材を収集する。" &
PID_ASSETS=$!

run_agent thumbnail-designer \
  "run_id=$RUN_ID。前工程の成果物: $PIPELINE_DIR/03_titles_thumbnails.md を読み、出力先=$PIPELINE_DIR/04_thumbnail.png にサムネイルを生成する。" &
PID_THUMB=$!

wait "$PID_VOICE" "$PID_ASSETS" "$PID_THUMB"

run_agent video-assembler \
  "run_id=$RUN_ID。前工程の成果物: $PIPELINE_DIR/02_script.md, $PIPELINE_DIR/04_narration.mp3, $PIPELINE_DIR/04_assets/ を読み、出力先=$PIPELINE_DIR/05_video.mp4 に合成する。"

run_agent metadata-seo \
  "run_id=$RUN_ID。前工程の成果物: $PIPELINE_DIR/01_research.md, $PIPELINE_DIR/02_script.md, $PIPELINE_DIR/03_titles_thumbnails.md, $PIPELINE_DIR/05_video.mp4 を読み、出力先=$PIPELINE_DIR/06_metadata.json にメタデータを書く。"

QA_OUTPUT=$(claude -p "run_id=$RUN_ID。$PIPELINE_DIR/ 以下の全成果物を審査し、QAレポートを返答してください。" --agent qa-guardian)
echo "$QA_OUTPUT" > "$PIPELINE_DIR/07_qa_report.md"

if grep -qi "REJECT" "$PIPELINE_DIR/07_qa_report.md"; then
  echo "QAゲートで REJECT されました。publisher は呼び出しません。詳細: $PIPELINE_DIR/07_qa_report.md" >&2
  exit 1
fi

run_agent publisher \
  "run_id=$RUN_ID。$PIPELINE_DIR/07_qa_report.md が PASS であることを確認した上で、$PIPELINE_DIR/06_metadata.json を使ってアップロードする。"

run_agent analytics-optimizer \
  "run_id=$RUN_ID。直近以前に公開した run があれば、その 08_publish_result.json を対象に分析し、$PIPELINE_DIR/09_analytics_feedback.md と feedback/latest.md（次回 trend-researcher が読む、上書き）の両方に次回企画への指示をまとめる。"

echo "パイプライン完了: $PIPELINE_DIR"
