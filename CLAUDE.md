# チャンネル全体ルール

このリポジトリは YouTube チャンネルの動画を「企画→台本→音声/素材→合成→メタデータ→審査→投稿」まで
サブエージェントのパイプラインで自動生産するためのものです。

## ディレクトリ構成

```
.
├─ CLAUDE.md            # このファイル：全体ルール・トーン・禁止事項
├─ channel/
│  ├─ concept.md         # コンセプト・ターゲット・トーン
│  ├─ published.md       # 公開済み一覧
│  └─ schedule.md        # 投稿枠
├─ .claude/
│  ├─ agents/            # 各サブエージェントの定義 (.md)
│  └─ commands/produce.md # オーケストレーション用スラッシュコマンド
├─ tools/                # tts.sh / imagegen.sh / stock.sh / upload.sh / analytics.sh
├─ assets_library/       # 手持ちBGM・素材
├─ briefs/               # 企画ブリーフ
├─ scripts/              # 台本
├─ meta/                 # タイトル/サムネ設計・メタデータ
├─ assets/               # 生成された音声・画像・B-roll素材
├─ output/               # 合成済み動画
├─ qa/                   # 審査結果
├─ publish/              # 投稿ログ・予約情報
└─ logs/                 # cron実行ログ
```

## トーン・禁止事項

- `channel/concept.md` のターゲット・トーンから逸脱しない。
- 台本・メタデータで未検証の事実主張、誇張、扇動的な表現を追加しない。
- 著作権・肖像権が不明な素材は `visual-asset-collector` / `thumbnail-designer` で採用しない。
- 各エージェントは自分の担当工程の成果物のみを保存し、他工程のファイルを上書きしない。
- `qa-guardian` の `verdict: pass` が出るまで `publisher` は投稿しない。

## パイプラインの実行

1本分の動画を企画から投稿まで自動生産するには `/produce` スラッシュコマンドを使う（`.claude/commands/produce.md`）。

```
claude -p "/produce"
```

### ヘッドレス実行（cron）

無人運用する場合は cron から `claude -p` を叩く。ログは `logs/` 以下に残す。

```cron
# 毎日 朝5時に1本生産
0 5 * * * cd /path/to/channel && claude -p "/produce" >> logs/produce.log 2>&1

# 毎週月曜 朝4時に前週分の分析
0 4 * * 1 cd /path/to/channel && claude -p "analytics-optimizer サブエージェントで先週分を分析して" >> logs/analytics.log 2>&1
```
