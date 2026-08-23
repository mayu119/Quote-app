# 制作ノート

| 日付 | 素材 | 5枚構成 |
| --- | --- | --- |
| 8/10 | l-no-confidence/ | 01-cover → 02-items(01〜03) → 03-items(04〜05) → 04-quote → 05-app-proof |
| 8/11 | m-night-self-blame/ | 01-cover → 02-items(01〜03) → 03-items(04〜05) → 04-quote → 05-app-proof |
| 8/12 | n-stop-comparing/ | 01-cover → 02-items(01〜03) → 03-items(04〜05) → 04-quote → 05-app-proof |

## 生成方法

- codex-image-gen スキル経由で codex exec（gpt-image-2 built-in image_gen）に委託。
- 各投稿の1〜4枚目は jobs-file バッチ（1投稿=1セッション）で生成し、パレットとレイアウトを揃えた。
- 5枚目のみ、公式アイコン `words-for-me-app-catalog/icons/words-for-me-6759647519.jpg` と
  `スクショ/アプリスクショ/` の実画面（カテゴリ.png / ホーム画面.png / お気に入り.png）を `-i` 入力に渡す編集生成。
  画面内UIの改変禁止を明示。

## 名言の出典（`QuoteApp/Sources/Resources/quotes_full.json`）

- 8/10: ココ・シャネル（women_quote_029）
- 8/11: オスカー・ワイルド（women_quote_111）
- 8/12: 黒柳徹子（women_quote_112）

## 前バッチからの変更点

- 8枚型・4枚型をやめ、1カルーセル=5枚に統一。
- 問題提起をアプリのメタな悩み（スクショの海・保存墓場）から、ターゲットの一次Pain（自信のなさ・自責・比較）に変更。
- 図星は2〜3枚目のリストに集約し、免罪は4枚目の実在名言に言わせる（投稿者は説かない）。
- コメント誘発はキャプション側（「何個当てはまった？」）で行い、画像にはCTAを入れない。
