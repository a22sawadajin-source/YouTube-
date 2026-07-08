#!/usr/bin/env bash
# 使い方: scripts/assemble_video.sh <assets_manifest.md> <narration.mp3> <subtitles.srt> <output.mp4>
# assets_manifest.md は video-assembler が読む記録用。実際の素材ファイルは
# manifest と同じディレクトリ（04_assets/）に置かれている前提。
set -euo pipefail

MANIFEST="$1"
NARRATION="$2"
SUBTITLES="$3"
OUTPUT="$4"

ASSETS_DIR="$(dirname "$MANIFEST")/04_assets"
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

if [ ! -d "$ASSETS_DIR" ] || [ -z "$(ls -A "$ASSETS_DIR" 2>/dev/null)" ]; then
  echo "素材ディレクトリが空です: $ASSETS_DIR" >&2
  exit 1
fi

NARRATION_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$NARRATION")

CONCAT_LIST="$WORKDIR/concat.txt"
: > "$CONCAT_LIST"
i=0
for f in "$ASSETS_DIR"/*; do
  NORM="$WORKDIR/norm_$i.mp4"
  ffmpeg -y -loglevel error -i "$f" \
    -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,fps=30" \
    -an -c:v libx264 -preset veryfast "$NORM"
  echo "file '$NORM'" >> "$CONCAT_LIST"
  i=$((i + 1))
done

RAW_CONCAT="$WORKDIR/raw_concat.mp4"
ffmpeg -y -loglevel error -f concat -safe 0 -i "$CONCAT_LIST" -c copy "$RAW_CONCAT"

VIDEO_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$RAW_CONCAT")

LOOPED="$WORKDIR/looped.mp4"
if (( $(echo "$VIDEO_DURATION < $NARRATION_DURATION" | bc -l) )); then
  LOOP_COUNT=$(echo "($NARRATION_DURATION / $VIDEO_DURATION) + 1" | bc)
  ffmpeg -y -loglevel error -stream_loop "$LOOP_COUNT" -i "$RAW_CONCAT" -t "$NARRATION_DURATION" -c copy "$LOOPED"
else
  ffmpeg -y -loglevel error -i "$RAW_CONCAT" -t "$NARRATION_DURATION" -c copy "$LOOPED"
fi

mkdir -p "$(dirname "$OUTPUT")"

SUB_FILTER=""
if [ -f "$SUBTITLES" ]; then
  SUB_FILTER=",subtitles=$SUBTITLES"
fi

ffmpeg -y -loglevel error -i "$LOOPED" -i "$NARRATION" \
  -vf "null${SUB_FILTER}" \
  -c:v libx264 -preset medium -c:a aac -shortest \
  "$OUTPUT"

echo "合成完了: $OUTPUT"
