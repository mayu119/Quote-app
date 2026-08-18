# v2 実験運用仕様

更新日: 2026-07-13  
対象Issue: #8 / #10 / #15 / #16 / #24

## 共通ルール

- オーナー: 本アプリのリリース担当者
- 開始: v2のApp Store公開日時をDay 0とする
- タイムゾーン: 集計はJST、イベント時刻はUTC
- 除外: 開発ビルド、TestFlight内部テスター、同意前イベント、イベント欠損セッション
- 固定プロパティ: `app_version`, `build`, `install_id`, `experiment_id`, `variant`
- `install_id` はKeychainに生成保存するUUID。IDFVだけで群分けしない
- 結果は `QuoteApp/docs/experiment-results/<experiment-id>.md` に終了7日以内に保存する
- 「有意差なし」は敗北ではない。必要サンプル未達なら延長または終了判断を記録する

## E10 通知文言（終了）

| 項目 | 定義 |
| --- | --- |
| ID | `notification_copy_v2` |
| 対象 | 通知許可済みで日次通知を1件以上設定した利用者 |
| 状態 | 2026-08-17終了。`tease`に統一 |
| 終了理由 | 旧期間は開封delegateが未配線で、群別の勝敗が観測不能だった。通知内で読了させず、アプリを開く理由を残す構造判断で統一 |
| 現行文言 | 「まだ言葉にできない気持ちへ。今日の一枚を、引いてみませんか。」 |

統一後の観測指標:

1. 通知タップ率 = `notification_opened` があるユニーク `install_id` / `notification_scheduled_eligible` があるユニーク `install_id`
2. 30分以内の儀式開示率 = `daily_draw_revealed within 30m / notification_opened`
3. 同一セッション保存率 = `quote_saved in session / notification_opened`

必要イベント: `notification_scheduled_eligible`, `notification_opened`, `daily_draw_revealed`, `quote_saved`。iOSのローカル通知には配信完了コールバックがないため「配信数」と呼ばず、予約対象者数を分母に使う。繰り返し通知の再登録と複数回開封があるため、イベント件数同士は割らない。同一アプリ版・同一観測期間のユニーク `install_id` で集計する。

## E15 深掘り提案

| 項目 | 定義 |
| --- | --- |
| ID | `insight_suggestion_v2` |
| 対象 | 振り返りメモ保存完了セッション |
| 割当 | セッションごとではなく、対象保存回数の安定カウンタで3回に1回 |
| 期間 | v2公開から28日 |

表示率は `insight_suggestion_shown / reflection_note_saved` で30〜36%を正常範囲とする。開封率は `insight_suggestion_opened / insight_suggestion_shown`。比較基準はv2公開前直近28日で、毎回表示していた版の同一定義イベントが無い場合は「比較不能」と記録し、推測値を作らない。

## E16 SNS 4週間投稿

キャンペーンリンク:

- Instagram: `ct=ugc_v2_instagram&pt=<provider-id>&mt=8`
- TikTok: `ct=ugc_v2_tiktok&pt=<provider-id>&mt=8`
- 投稿型は `at=hook_01`〜`hook_06` で分離する

`<provider-id>` はApp Store Connectで取得後に置換し、置換前リンクを公開しない。

| 週 | 投稿 | 目的 |
| --- | --- | --- |
| 1 | hook 01〜03を各2媒体 | 保存墓場、今日の一枚、夜の免罪の初速比較 |
| 2 | hook 04〜06を各2媒体 | 棚、処方箋、言葉のお守りの比較 |
| 3 | 上位3型を別クリエイティブで再投稿 | フック再現性 |
| 4 | 上位2型をCTA違いで再投稿 | インストール効率 |

各投稿の24時間・7日後に、再生数、3秒維持率、完視聴率、保存率、プロフィール遷移、キャンペーン経由インストールを記録する。

続ける型: 2回以上の投稿で保存率が媒体中央値以上、かつキャンペーン経由インストールが1件以上。捨てる型: 2回とも保存率が媒体中央値未満かつインストール0。判定保留: リーチ500未満。フォロワー増加は参考値で、型の勝敗には使わない。

## KPI読み取り契約

- トライアル開始率: `trial_start` を `paywall_view` のユニーク `install_id` で割った集計済みカード
- トライアル転換率: `trial_convert` を `trial_start` のユニーク `install_id` で割った集計済みカード
- D1再訪率: Day 0に `first_open` があるコホートのうち、その翌暦日に `session_start` があるユニーク `install_id` の割合。JST基準で、Day 1が完了していないコホートは分母へ入れない
- D7: Day 0コホートのうちDay 7に `session_start` があるユニーク `install_id` の割合
- 儀式D7/D30: `daily_draw_revealed` 有無のコホート比較

ダッシュボードは率だけでなく分子・分母・対象期間・アプリ版を同じカード内に表示する。ゲートはトライアル開始率8%、転換率25%。7日未満のコホートをD7分母へ入れない。

当面のリテンション判断はD1再訪率に絞る。週次で、全体に加えて `app_version` と新規流入元別の分子・分母を記録する。通知・Day1導線の変更後に成熟した新規コホートが2週分たまるまでは、次の構造変更を勝敗判定しない。

## 運用チェックリスト

- [ ] 本番版で `notification_scheduled_eligible` と `notification_opened` が同一バージョンから発火するか確認
- [ ] 通知タイプ別（daily / premium / weekly）に開封が分類されるか確認
- [ ] 毎週、成熟済みコホートのD1再訪率を分子・分母・アプリ版・流入元付きで記録
- [ ] Day 7: 欠損・クラッシュ・課金への悪影響を確認
- [ ] Day 28: E15、SNS実験を確定
- [ ] 結果文書に継続/削除/再試験のどれかを明記
