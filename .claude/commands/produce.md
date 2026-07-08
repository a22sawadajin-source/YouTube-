---
description: YouTube動画を企画から投稿・分析まで工程1→9で明示的に生成する量産オーケストレーター
---

あなたはこのYouTube量産パイプラインのオーケストレーターです。`CLAUDE.md` に定義された
工程 1→9 を**固定順序で**、Agent ツールにより各サブエージェントへ明示的に委譲して実行して
ください。自動デリゲーションに頼らず、各工程の呼び出しプロンプトには必ず前工程の成果物
パスを文字列として含めてください（サブエージェントは会話履歴を引き継がない）。

引数: `$ARGUMENTS`（テーマ指定があれば使う。無ければ trend-researcher に一任する）

## 実行手順

1. `run_id` を `date +%Y-%m-%d_%H%M` で決定し、`pipeline/<run_id>/` を作成する。
2. **工程1** `trend-researcher` を呼び出す。テーマ指定（`$ARGUMENTS`）と
   `pipeline/<run_id>/` を渡す。出力: `01_research.md`。
3. **工程2** `script-writer` を呼び出す。`01_research.md` のパスを渡す。
   出力: `02_script.md`。
4. **工程3** `title-thumbnail-strategist` を呼び出す。`02_script.md` のパスを渡す。
   出力: `03_titles_thumbnails.md`。
5. **工程4（並列）** 以下の3エージェントを同時に呼び出す（互いに依存しないため）。
   - `voice-synthesizer`（`02_script.md` を渡す） → `04_narration.mp3`
   - `visual-asset-collector`（`02_script.md` を渡す） → `04_assets/`
   - `thumbnail-designer`（`03_titles_thumbnails.md` を渡す） → `04_thumbnail.png`
6. **工程5** `video-assembler` を呼び出す。`02_script.md`, `04_narration.mp3`,
   `04_assets/` のパスを渡す。出力: `05_video.mp4`, `05_subtitles.srt`。
7. **工程6** `metadata-seo` を呼び出す。`01_research.md`, `02_script.md`,
   `03_titles_thumbnails.md`, `05_video.mp4` のパスを渡す。出力: `06_metadata.json`。
8. **工程7** `qa-guardian` を呼び出す。`pipeline/<run_id>/` 全体を渡す。返答された
   QAレポート本文を、あなた自身が `pipeline/<run_id>/07_qa_report.md` に書き出す
   （qa-guardian は読み取り専用で書き込み権限を持たないため）。
9. 判定を確認する。
   - **REJECT の場合**: `publisher` を呼び出さず、差し戻し指示をユーザーに提示して終了する。
     ユーザーの指示があれば該当工程からやり直す。
   - **PASS の場合**: 次に進む。
10. **工程8** `publisher` を呼び出す。`07_qa_report.md` と `06_metadata.json` の
    パスを渡す。出力: `08_publish_result.json`。
11. **工程9** `analytics-optimizer` を呼び出す。今回は直近公開分の分析データがまだ
    無いため、代わりに**前回以前の run**（あれば）の `08_publish_result.json` を対象に
    分析を行うよう指示する。出力: `09_analytics_feedback.md`。

## 完了報告

各工程の実行結果（PASS/REJECTの判定、生成ファイル一覧、公開URL）を簡潔にまとめて
ユーザーに報告する。工程の内部詳細を逐一書き出さず、要点のみ。
