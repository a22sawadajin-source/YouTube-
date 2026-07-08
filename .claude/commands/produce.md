---
description: 1本分の動画を企画から投稿まで自動生産する
---

以下を順番に、各ステップの成果物の絶対パスを次のステップに渡しながら実行して。
自動デリゲーションには頼らず、必ずこの順序どおりに Agent ツールでサブエージェントを呼び出すこと。

1. **trend-researcher** サブエージェントで企画ブリーフを作る。
   - 出力: `briefs/<YYYY-MM-DD>-brief.md`
2. 1 の出力ファイルの絶対パスをプロンプトに明記して渡し、**script-writer** で台本を作る。
   - 出力: `scripts/<YYYY-MM-DD>-script.md`
3. 2 の台本の絶対パスを渡し、**title-thumbnail-strategist** でタイトル案・サムネ構成案を作る。
   - 出力: `meta/<YYYY-MM-DD>-title-thumbnail.md`
4. 2 の台本と 3 のサムネ構成案の絶対パスを渡し、以下の3エージェントを**並列**に実行する。
   - **voice-synthesizer**: 台本のナレーションからナレーション音声を生成 → `assets/<YYYY-MM-DD>/voice/`
   - **visual-asset-collector**: シーンごとのB-roll/画像素材を収集 → `assets/<YYYY-MM-DD>/visuals/`
   - **thumbnail-designer**: サムネイル画像を生成 → `assets/<YYYY-MM-DD>/thumbnail/`
5. 4 の3つの成果物ディレクトリの絶対パスを渡し、**video-assembler** で動画を合成する。
   - 出力: `output/<YYYY-MM-DD>-video.mp4`
6. 2・3・5 の成果物の絶対パスを渡し、**metadata-seo** で投稿用メタデータ（説明文・タグ・チャプター等）を作成する。
   - 出力: `meta/<YYYY-MM-DD>-metadata.md`
7. 5 の動画と 6 のメタデータの絶対パスを渡し、**qa-guardian** で審査する。
   - 出力: `qa/<YYYY-MM-DD>-qa.md`（`verdict: pass` または `verdict: fail` と `fix_hint` を含む）
   - `verdict` が `fail` の場合、`fix_hint` が指す工程（1〜6のいずれか）に差し戻し、該当ステップからやり直す。
   - 差し戻しは**最大3回**まで。3回失敗した場合は自動投稿せず、失敗理由を添えて処理を中断し、ユーザーに報告する。
8. `verdict: pass` になったら、5 の動画と 6 のメタデータの絶対パスを渡し、**publisher** で `channel/schedule.md` の次の投稿枠に予約投稿する。
   - 投稿完了後、`channel/published.md` に1行追記する。
9. 最後に、各ステップの成果物パス・所要時間・差し戻し回数・最終結果（投稿済み／中断）を含む結果サマリを報告する。

## 注意事項
- 各サブエージェントを呼び出す際は、前工程が保存したファイルの**絶対パス**を必ずプロンプト内に明記して渡すこと（相対パスや「さっきの台本」のような曖昧な参照はしない）。
- `channel/CLAUDE.md`（全体ルール・トーン・禁止事項）と `channel/concept.md`（コンセプト・ターゲット・トーン）は全工程で前提として厳守する。
- ステップ4の並列実行は、3エージェントの完了を待ってからステップ5に進む。
