# YouTube 量産パイプライン — オーケストレーター

このリポジトリは、YouTube動画の企画〜投稿〜分析までを Claude Code のサブエージェントで
分業する量産パイプラインです。**自動デリゲーションには頼らず**、`/produce` スラッシュ
コマンド（または `scripts/orchestrate.sh`）で工程 1→9 を固定順序で実行してください。

## パイプライン全体像

```
[cron / 手動トリガー]
        │
        ▼
┌─────────────────────────────────────────┐
│ オーケストレーター（本ファイル + /produce） │
└─────────────────────────────────────────┘
        │
 1. trend-researcher            … 企画・ネタ選定
 2. script-writer                … 台本
 3. title-thumbnail-strategist   … タイトル案・サムネ設計
 4. voice-synthesizer            … ナレーション音声（TTS）        ┐ 並列可
    visual-asset-collector       … 映像/画像素材（B-roll）         ┤
    thumbnail-designer           … サムネ画像生成                 ┘
 5. video-assembler              … ffmpegで合成・字幕焼き込み
 6. metadata-seo                 … 概要欄・タグ・チャプター
 7. qa-guardian                  … 品質＋ポリシー審査（公開ゲート）★ここで止められる
 8. publisher                    … YouTube Data API でアップロード/予約投稿
 9. analytics-optimizer          … 数値分析 → 次回企画へフィードバック
```

## 設計上の3原則

1. **明示的オーケストレーション** — 自動デリゲーションに頼らず、`/produce` や
   `scripts/orchestrate.sh` で「1→9」を順に実行する。量産ラインでは順序と再現性が命。
2. **権限の最小化** — 各エージェントの `tools` は必要最小限に。特に `qa-guardian` は
   読み取り専用、`publisher` だけがアップロード権限を持つ。
3. **コスト最適化** — 探索/整形など軽い処理は `model: haiku`、創作・審査など質が要る処理は
   `model: sonnet`（重要局面のみ `opus`）。`qa-guardian` は公開ゲートという重要局面のため
   `opus` を割り当てている。

## 各エージェントは「まっさら」から始まる

サブエージェントは親の会話履歴を引き継ぎません。渡すべきファイルパス・前工程の成果物・
制約は、呼び出しプロンプトの文字列に必ず全部含めてください。各工程の成果物は
`pipeline/<run_id>/` 以下に固定のファイル名で保存する設計にしているので、次のエージェント
を呼ぶときは必ずそのパスを明示してください。

## 成果物ディレクトリ規約

各実行は `pipeline/<run_id>/`（例: `pipeline/2026-07-08_1200/`）に以下を生成します。

| ファイル | 生成工程 |
|---|---|
| `01_research.md` | trend-researcher |
| `02_script.md` | script-writer |
| `03_titles_thumbnails.md` | title-thumbnail-strategist |
| `04_narration.mp3` | voice-synthesizer |
| `04_assets/` | visual-asset-collector |
| `04_thumbnail.png` | thumbnail-designer |
| `05_video.mp4` | video-assembler |
| `06_metadata.json` | metadata-seo |
| `07_qa_report.md` | qa-guardian（`PASS` / `REJECT` を明記） |
| `08_publish_result.json` | publisher |
| `09_analytics_feedback.md` | analytics-optimizer |

## 必要な外部ツール／API（Claude Code本体とは別に用意）

- **TTS**: 任意の音声合成API（読み上げ） → `scripts/tts.sh`
- **画像生成**: 任意の画像生成API（サムネ・挿絵） → `scripts/generate_image.sh`
- **映像素材**: ストック動画API or 生成AI、または手持ち素材フォルダ → `scripts/fetch_stock_video.sh`
- **合成**: `ffmpeg`（必須） → `scripts/assemble_video.sh`
- **投稿**: YouTube Data API v3（OAuth 認証済みトークン） → `scripts/upload_youtube.sh`

各APIキーは `.env`（`.env.example` を参照）に置き、Bashスクリプト経由で叩きます。
`.env` はコミットしないでください。

## 運用上の注意（YouTubeポリシー）

完全自動の量産は「反復的・低付加価値コンテンツ」として収益化が却下されるリスクがあります。
`qa-guardian` に独自性・情報の正確性・ポリシー適合のゲートを必ず入れ、テンプレ丸出しの
量産を避けています。**このゲートを飛ばさないことが長期運用の鍵です。** `qa-guardian` が
`REJECT` を出した実行は `publisher` を呼ばないでください。

## 使い方

```
/produce                      # 新規テーマで 1→9 を通しで実行
/produce "テーマ: 家庭用サーバーの選び方"   # テーマ指定
scripts/orchestrate.sh <run_id>   # シェルスクリプト版オーケストレーター
```
