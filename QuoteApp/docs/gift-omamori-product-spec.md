# 「言葉のお守り」ギフト正式仕様

更新日: 2026-07-13  
対象Issue: #14

## 1. 商品定義

「言葉のお守り」は、言葉1枚、贈り主の一言、背景1枚を相手へ届ける都度購入の商品とする。同じ購入者が何度でも贈れる必要があるため、App Storeの商品種別は `CONSUMABLE` とする。商品IDは `com.quoteapp.gift.omamori` を維持する。

購入1回につきギフト1件を発行する。サブスクリプション加入状況による値引きや無料化は行わず、受取側は完全無料とする。

## 2. システム構成

- iOSアプリ: 作成、StoreKit購入、共有、Universal Link受信、棚への保存
- GitHub Pages: `https://mayu119.github.io/Quote-app/gift/<gift-id>` の無料Web受取画面とAASA
- Gift API: Cloudflare Workers
- 永続化: Cloudflare D1
- 購入検証: App Store Server API。検証成功したトランザクションだけ発行する

GitHub Pagesは秘密情報を持たず、`gift-id` をGift APIへ渡して公開可能な表示データだけ取得する。

## 3. データモデル

`gifts`:

| フィールド | 制約 |
| --- | --- |
| `id` | 128bit以上の暗号学的乱数。URLのbearer token |
| `quote_id` | 配信時のカタログID |
| `quote_ja_snapshot` | 削除・改稿後も受取内容を保つスナップショット |
| `author_snapshot` | 表示名スナップショット |
| `sender_note` | 0〜60文字。改行2つまで |
| `background_id` | 許可済み背景IDのみ |
| `created_at` / `expires_at` | UTC。発行から365日でリンク失効 |
| `app_transaction_id_hash` | 購入者を直接識別しないハッシュ |
| `transaction_id` | 冪等発行用。暗号化保存 |
| `status` | `active` / `revoked` / `expired` |
| `first_opened_at` | 初回開封。未開封ならnull |

受取人のメール、Apple ID、広告ID、連絡先、端末IDは保存しない。アクセスログはIPを永続化せず、集計値だけ30日保持する。

## 4. API契約

- `POST /v1/gifts/prepare`: 選んだ内容を検証し、10分有効の `draft_id` を返す
- `POST /v1/gifts/issue`: `draft_id`、StoreKit 2の署名済みトランザクション、クライアント冪等キーを受け、検証後にURLを返す
- `GET /v1/gifts/{id}`: 有効なギフトの公開表示データだけ返す
- `POST /v1/gifts/{id}/opened`: 初回開封を冪等記録する。個人識別子は受け取らない
- `POST /v1/gifts/{id}/report`: 不適切な一言を通報する。レート制限を行う

`issue` は同じ `transaction_id` に常に同じ `gift-id` を返す。APIタイムアウト時に二重購入・二重発行を起こさない。

## 5. 購入状態遷移

1. 内容を選び、プレビューする。
2. `prepare` 成功後にStoreKit購入を開始する。
3. 購入成功後、署名済みトランザクションを `issue` へ送る。
4. URL発行を端末にも保存してからStoreKitトランザクションをfinishする。
5. `issue` 失敗時は「発行待ち」として端末に保持し、次回起動で自動再試行する。再購入は促さない。
6. 発行済みギフトは送信履歴から何度でも再共有できる。

キャンセルは未購入として終了する。返金・購入取消をApp Store Server Notificationsで受けた場合、未開封なら `revoked` にする。開封済みなら新規アクセスを停止しても、受取端末に保存済みの言葉は削除しない。

## 6. 受取体験

- Webとアプリの冒頭は「○○さんから、言葉のお守りが届いています」。贈り主名は任意入力ではなく、個人情報を避けるため既定値「大切な人」にする。将来名前入力を追加する場合は20文字制限と明示同意を追加する。
- アプリ未導入でも、言葉、一言、背景を最後まで無料で見られる。
- アプリ内は `GiftReceiveView` を開き、「棚に置く」「閉じる」だけを置く。
- 保存上限に達していてもギフトは保存できる。
- 受取画面と保存完了画面にペイウォール、価格、Premiumバッジを置かない。
- 期限切れ・取消時は理由と期限だけを静かに表示し、購入を促さない。

## 7. 安全・権利・不正対策

- 贈れる言葉は配信中または権利確認済みのスナップショットに限定する。
- 一言はURL、電話番号、メールアドレスの入力を警告し、禁止語・嫌がらせ語の最小フィルタを通す。
- 公開APIはIP単位とgift単位でレート制限する。
- `gift-id` を解析・列挙できない長さにし、検索エンジンへ `noindex` を返す。
- D1バックアップを日次、保持30日とする。失効データは30日後に削除する。

## 8. 計測契約

| イベント | タイミング | 必須パラメータ |
| --- | --- | --- |
| `gift_compose_started` | 作成開始 | `source` |
| `gift_purchase_initiated` | StoreKit直前 | `product_id` |
| `gift_purchase_succeeded` | 購入検証成功 | `product_id` |
| `gift_issued` | URL発行 | `background_id` |
| `gift_shared` | 共有シート完了候補 | `channel` |
| `gift_opened` | Web/App初回表示 | `surface`, `days_since_issue` |
| `gift_saved` | 受取側が棚へ保存 | `days_since_issue` |
| `gift_issue_retry` | 発行再試行 | `attempt`, `result` |

イベントへ `gift-id`、本文、一言、トランザクションIDを送らない。

## 9. 完了条件

- Sandbox購入を同一購入者が2回行い、別々のURLが発行される。
- APIタイムアウト再試行で二重発行されない。
- アプリあり/なし、期限切れ、取消、オフライン復帰を確認する。
- 2台の実機で「作成→購入→共有→開封→棚へ保存」が通る。
- 受取側の全画面に課金導線がないことをUIテストと目視で確認する。
- App Store Server NotificationsのSandboxで返金イベントを確認する。

