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

## E10 通知文言A/B

| 項目 | 定義 |
| --- | --- |
| ID | `notification_copy_v2` |
| 対象 | 通知許可済みで日次通知を1件以上設定した利用者 |
| 割当 | `SHA256(install_id + experiment_id) % 2`。A=`full`、B=`tease` |
| 開始 | v2公開後、両群への通知予約が確認できた翌日0:00 JST |
| 期間 | 最低14日。各群200配信相当未満なら最大28日まで延長 |
| A | 言葉の本文を通知に表示 |
| B | 「まだ言葉にできない気持ちへ。今日の一枚を、引いてみませんか。」 |

判定指標:

1. 通知タップ率 = `notification_opened / notification_scheduled_eligible`
2. 30分以内の儀式開示率 = `daily_draw_revealed within 30m / notification_opened`
3. 同一セッション保存率 = `quote_saved in session / notification_opened`

勝者は、タップ率を悪化させず、儀式開示率または保存率が相対10%以上改善した群。いずれも満たさない場合はAを維持する。Day 14と、延長時はDay 28に判定し、負けた文言と分岐コードを次版で削除する。

必要イベント: `notification_scheduled_eligible`, `notification_opened`, `daily_draw_revealed`, `quote_saved`。iOSのローカル通知には配信完了コールバックがないため「配信数」と呼ばず、予約対象数を分母名に使う。

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
- D7: Day 0コホートのうちDay 7に `session_start` があるユニーク `install_id` の割合
- 儀式D7/D30: `daily_draw_revealed` 有無のコホート比較

ダッシュボードは率だけでなく分子・分母・対象期間・アプリ版を同じカード内に表示する。ゲートはトライアル開始率8%、転換率25%。7日未満のコホートをD7分母へ入れない。

## 運用チェックリスト

- [ ] Day 0: 本番イベント、variant固定、除外条件を確認
- [ ] Day 1: 両群の件数差が45:55以内か確認
- [ ] Day 7: 欠損・クラッシュ・課金への悪影響だけ確認し、勝敗は決めない
- [ ] Day 14: E10一次判定
- [ ] Day 28: E10延長判定、E15、SNS実験を確定
- [ ] 結果文書に継続/削除/再試験のどれかを明記

