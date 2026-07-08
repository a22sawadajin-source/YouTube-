# 素材収集レポート

**ステータス**: エラー（APIキー未設定、ローカル素材なし）

## エラー概要

- `STOCK_VIDEO_API_KEY` が `.env` に未設定
- `LOCAL_ASSETS_DIR` (./assets/local) に代替素材なし
- `scripts/fetch_stock_video.sh` の実行に失敗

## 抽出されたB-ROLL注記（未取得）

以下の12個のB-ROLL注記について、素材を取得できませんでした：

| 序番 | 注記 | スラッグ | 状態 |
|------|------|---------|------|
| 1 | 企業のオフィスでAIダッシュボードが並ぶ映像、ニュースヘッドライン風のテロップ合成 | ai_office_dashboard | 未取得 |
| 2 | グラフやパーセンテージを強調するシンプルなインフォグラフィック | graph_percentage_infographic | 未取得 |
| 3 | カフェの店内、バリスタが在庫を確認する様子、雨天の街並み | cafe_inventory_rainy | 未取得 |
| 4 | 天気予報のアイコン、地域イベントのポスター、人流を示す矢印グラフィック | weather_event_flow_graphic | 未取得 |
| 5 | 空港のカウンター、航空券、チャットボットの画面イメージ | airport_ticket_chatbot | 未取得 |
| 6 | チャット画面の吹き出しグラフィック、架空のポリシー文書 | chat_bubble_policy_graphic | 未取得 |
| 7 | ニューヨークの市庁舎、行政サービスの窓口、スマートフォンでチャットする市民 | nyc_city_hall_chatbot | 未取得 |
| 8 | 法律書類、警告マークのグラフィック | law_document_warning_graphic | 未取得 |
| 9 | チェックリストのグラフィック、会議室で議論するビジネスパーソン | checklist_meeting_graphic | 未取得 |
| 10 | 天秤のグラフィック、AIと人間が協働するイメージ | scale_ai_human_cooperation_graphic | 未取得 |
| 11 | 夕暮れのオフィス街、静かに閉じるノートパソコン | sunset_office_laptop | 未取得 |
| 12 | チャンネル登録・関連動画への誘導テロップ | channel_cta_graphic | 未取得 |

## 対応が必要

1. `.env` ファイルに `STOCK_VIDEO_API_KEY` を設定する
2. または `LOCAL_ASSETS_DIR` (./assets/local) に素材ファイルを配置する

どちらかの対応がない限り、video-assembler は素材なしの状態で合成を開始することになります。

---

**収集完了素材**: 0個  
**未取得素材**: 12個  
**実行日時**: 2026-07-08
