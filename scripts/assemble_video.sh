#!/usr/bin/env bash
# 使い方:
#   scripts/assemble_video.sh <run_dir> <narration_audio> <visuals_manifest.json> \
#                              <subtitles.srt|-> <bgm_audio|-> <output.mp4>
#
# visuals_manifest.json の形式（video-assembler が生成する）:
#   [
#     {"index":1,"asset":"pipeline/<run_id>/04_assets/01_x.mp4","duration":8.2,"transition":"cut"},
#     {"index":2,"asset":"pipeline/<run_id>/04_assets/02_y.jpg","duration":14.5,"transition":"fade"}
#   ]
#   transition はそのシーンへの入り方（先頭シーンの transition は無視される）。"fade" か "cut"。
#
# 実行前に、解決済みの具体的な ffmpeg コマンド一式を <run_dir>/build_video.sh に
# 書き出してから、そのファイルを実行する（再現性の担保）。
set -euo pipefail

RUN_DIR="$1"
NARRATION="$2"
MANIFEST="$3"
SUBTITLES="${4:--}"
BGM="${5:--}"
OUTPUT="$6"

command -v ffmpeg >/dev/null || { echo "ffmpeg が見つかりません" >&2; exit 1; }
command -v ffprobe >/dev/null || { echo "ffprobe が見つかりません" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq が見つかりません" >&2; exit 1; }

mkdir -p "$RUN_DIR"
BUILD_SCRIPT="$RUN_DIR/build_video.sh"

SCENE_COUNT=$(jq 'length' "$MANIFEST")
if [ "$SCENE_COUNT" -lt 1 ]; then
  echo "visuals_manifest.json にシーンがありません: $MANIFEST" >&2
  exit 1
fi

NARR_DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$NARRATION")

FADE_DUR=0.6   # transition:"fade" のクロスフェード長(秒)
CUT_DUR=0.04   # transition:"cut" 用。xfadeはduration>0が必須なので瞬時切替に近い極小値を使う

HAS_SUBS=0
[ "$SUBTITLES" != "-" ] && [ -f "$SUBTITLES" ] && HAS_SUBS=1

HAS_BGM=0
[ "$BGM" != "-" ] && [ -f "$BGM" ] && HAS_BGM=1

{
  echo '#!/usr/bin/env bash'
  echo '# 自動生成ファイル: video-assembler が組み立てた具体的な ffmpeg コマンド一式。'
  echo '# このファイル単体を再実行すれば同じ動画を再現できる。'
  echo 'set -euo pipefail'
  echo 'WORKDIR=$(mktemp -d)'
  echo 'trap '"'"'rm -rf "$WORKDIR"'"'"' EXIT'
  echo
} > "$BUILD_SCRIPT"

VF_NORMALIZE="scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,fps=30,setsar=1,format=yuv420p"

# 1) 各シーンを 1920x1080/30fps の映像クリップに正規化する（画像はループ、動画は尺に合わせてループ/トリム）
for i in $(seq 0 $((SCENE_COUNT - 1))); do
  ASSET=$(jq -r ".[$i].asset" "$MANIFEST")
  DURATION=$(jq -r ".[$i].duration" "$MANIFEST")
  EXT=$(echo "${ASSET##*.}" | tr '[:upper:]' '[:lower:]')
  case "$EXT" in
    jpg|jpeg|png|webp|bmp)
      printf 'ffmpeg -y -loglevel error -loop 1 -t %s -i %q -vf %q -an -c:v libx264 -preset veryfast "$WORKDIR/scene_%d.mp4"\n' \
        "$DURATION" "$ASSET" "$VF_NORMALIZE" "$i" >> "$BUILD_SCRIPT"
      ;;
    *)
      printf 'ffmpeg -y -loglevel error -stream_loop -1 -i %q -t %s -vf %q -an -c:v libx264 -preset veryfast "$WORKDIR/scene_%d.mp4"\n' \
        "$ASSET" "$DURATION" "$VF_NORMALIZE" "$i" >> "$BUILD_SCRIPT"
      ;;
  esac
done
echo >> "$BUILD_SCRIPT"

# 2) シーンをトランジション付きで連結する（xfadeを直列に繋ぐ）。1シーンのみなら連結不要。
if [ "$SCENE_COUNT" -eq 1 ]; then
  echo 'cp "$WORKDIR/scene_0.mp4" "$WORKDIR/concatenated.mp4"' >> "$BUILD_SCRIPT"
else
  INPUTS=""
  for i in $(seq 0 $((SCENE_COUNT - 1))); do
    INPUTS="$INPUTS -i \"\$WORKDIR/scene_${i}.mp4\""
  done

  FILTER=""
  CUM_DUR=$(jq -r ".[0].duration" "$MANIFEST")
  PREV_LABEL="0:v"
  for i in $(seq 1 $((SCENE_COUNT - 1))); do
    TRANSITION=$(jq -r ".[$i].transition" "$MANIFEST")
    D_I=$(jq -r ".[$i].duration" "$MANIFEST")
    if [ "$TRANSITION" = "fade" ]; then
      T_DUR="$FADE_DUR"
    else
      T_DUR="$CUT_DUR"
    fi
    OFFSET=$(echo "$CUM_DUR - $T_DUR" | bc -l)
    OUT_LABEL="v$i"
    FILTER="${FILTER}[${PREV_LABEL}][${i}:v]xfade=transition=fade:duration=${T_DUR}:offset=${OFFSET}[${OUT_LABEL}];"
    CUM_DUR=$(echo "$CUM_DUR + $D_I - $T_DUR" | bc -l)
    PREV_LABEL="$OUT_LABEL"
  done
  # 末尾のセミコロンを除去し、最終ラベルをffmpegコマンドのmap先とする
  FILTER="${FILTER%;}"
  printf 'ffmpeg -y -loglevel error%s -filter_complex %q -map "[%s]" -c:v libx264 -preset veryfast "$WORKDIR/concatenated.mp4"\n' \
    "$INPUTS" "$FILTER" "$PREV_LABEL" >> "$BUILD_SCRIPT"
fi
echo >> "$BUILD_SCRIPT"

# 3) ナレーション尺に合わせて末尾を微調整（xfadeの重なり分だけ短くなるため最終フレームを伸ばす）し、字幕を焼き込む
VF_FINAL="tpad=stop_mode=clone:stop_duration=999"
if [ "$HAS_SUBS" -eq 1 ]; then
  ESCAPED_SUBS=$(printf '%s' "$SUBTITLES" | sed "s/:/\\\\:/g")
  VF_FINAL="${VF_FINAL},subtitles=${ESCAPED_SUBS}"
fi
printf 'ffmpeg -y -loglevel error -i "$WORKDIR/concatenated.mp4" -t %s -vf %q -an -c:v libx264 -preset veryfast "$WORKDIR/video_final.mp4"\n' \
  "$NARR_DUR" "$VF_FINAL" >> "$BUILD_SCRIPT"
echo >> "$BUILD_SCRIPT"

# 4) 音声を合成する: ナレーション + BGM（-18〜-22dB、ナレーションでダッキング）
mkdir -p "$(dirname "$OUTPUT")"
if [ "$HAS_BGM" -eq 1 ]; then
  printf 'ffmpeg -y -loglevel error -i "$WORKDIR/video_final.mp4" -i %q -stream_loop -1 -i %q -filter_complex "[2:a]volume=-20dB[bgm];[bgm][1:a]sidechaincompress=threshold=0.05:ratio=8:attack=5:release=300[bgmduck];[1:a][bgmduck]amix=inputs=2:duration=first:dropout_transition=2:normalize=0[aout]" -map 0:v -map "[aout]" -t %s -c:v libx264 -preset medium -c:a aac -b:a 192k -pix_fmt yuv420p %q\n' \
    "$NARRATION" "$BGM" "$NARR_DUR" "$OUTPUT" >> "$BUILD_SCRIPT"
else
  printf 'ffmpeg -y -loglevel error -i "$WORKDIR/video_final.mp4" -i %q -map 0:v -map 1:a -t %s -c:v libx264 -preset medium -c:a aac -b:a 192k -pix_fmt yuv420p %q\n' \
    "$NARRATION" "$NARR_DUR" "$OUTPUT" >> "$BUILD_SCRIPT"
fi

chmod +x "$BUILD_SCRIPT"
echo "再現用スクリプトを生成しました: $BUILD_SCRIPT"
bash "$BUILD_SCRIPT"
echo "合成完了: $OUTPUT"
