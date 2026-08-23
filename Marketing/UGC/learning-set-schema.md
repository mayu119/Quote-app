# UGC学習セット スキーマ (2026-08-17)

> 目的: タイトル・フォーマット・投稿変数と成績(再生・いいね・将来的にDL)を後から相関分析できる形で溜め続ける。
> 実体: `content-ledger.json`の各エントリに`variables`ブロックを追加し、`performance-log.jsonl`の実測値と`build_learning_set.py`で結合して`Marketing/UGC/learning-set.csv`を生成する。

## なぜ必要か

2026-08-16の恋愛レーン初回投稿(①③)で、Lemon8の保存数順位とTikTokの再生数順位が逆転する事象が発生した。n=2では判断できないが、**今後の投稿すべてに変数タグを付けて溜めれば、10〜15本で相関が見えてくる**。この設計はそのための土台。

## content-ledger.jsonへの追加フィールド: `variables`

各エントリに以下を追加する(新規バッチは作成時に必ず埋める。既存分は分かる範囲で遡及)。

```json
"variables": {
  "title_source": "lemon8-derived",
  "title_source_ref": "勝ちタイトル銀行_2026-08-13.md: フラれないいい女の思考法20選",
  "title_source_metric_saves": 1683,
  "title_char_count": 14,
  "title_has_number": true,
  "title_names_target": true,
  "title_type": "対象指名型",
  "theme_category": "恋愛-向上攻略",
  "format_version": "v3-lineart-10list",
  "list_count": 10,
  "device_slide_index": 4,
  "total_slides": 12,
  "device_position_label": "item4",
  "post_time_slot": "17:00",
  "post_dow": "Sun",
  "lane": "cv-native",
  "appeal_mechanism": "loss-framing"
}
```

### フィールド定義

| フィールド | 型 | 説明 |
| --- | --- | --- |
| `title_source` | enum | `lemon8-verbatim`(原文一字一句流用) / `lemon8-derived`(数を変える等の軽微改変) / `original`(新作) |
| `title_source_ref` | string\|null | 出典ファイルと元タイトル。originalならnull |
| `title_source_metric_saves` | int\|null | Lemon8での元タイトルの保存数。originalならnull |
| `title_char_count` | int | タイトル文字数(数字・記号込み) |
| `title_has_number` | bool | 数字が入っているか |
| `title_names_target` | bool | 対象を名指ししているか(「〜な人」「男性の」等) |
| `title_type` | enum | 勝ちタイトル銀行の分類: `数字リスト型`/`対象指名型`/`断定肯定文型`/`警告禁止型`/`言葉行動描写型`/`感情状態名指し型`/`複合`/`不明` |
| `theme_category` | string | テーマの系統(自由記述だが命名を統一: `恋愛-向上攻略`, `恋愛-確認欲求`, `恋愛-失恋回復`, `自己肯定-Pain型`, 等) |
| `format_version` | string | 台帳既存の`format`と同じ値を複製(結合しやすくするため) |
| `list_count` | int | 項目数(5, 7, 8, 10等) |
| `device_slide_index` | int\|null | WFM実画面/アプリ言及が出る枚数目。ない場合null |
| `total_slides` | int | カルーセル総枚数 |
| `device_position_label` | enum | `item4`/`closing-footnote`/`mid-item`/`none` |
| `post_time_slot` | string | 投稿時刻(JST, "HH:MM") |
| `post_dow` | string | 投稿曜日(自動導出可) |
| `lane` | enum | `cv-native`(自分主語型リスト。WFMを他項目と同一体裁でネイティブ統合、CV狙い) / `impression-independent`(他人主語型リスト。WFMは独立した訴求で登場、インプ・認知狙い) / `quote-collection`(名言集系。lane概念が当てはまらない別構造) |
| `appeal_mechanism` | enum | `loss-framing`(保存墓場等の損失フレーミング。CVレーンの推奨デフォルト) / `personalization-draw`(「今日はこれが出た」型。①③②で使用、体感的にCV弱いとMayu判断・2026-08-17) / `plain-namedrop`(名前+超短属性+アイコンのみ。インプレーンの推奨デフォルト) / `withheld-completion`(ツァイガルニク型。コピーの声が広告臭になりやすく実装難度高) |

不明な項目は**推測で埋めずnullにする**。学習セットの汚染を避けるため。

## 2026-08-17 訴求ルール確定(Mayu決定)

**WFMを独立した専用スライド(カード枠・「今日の言葉」見出し等)として登場させるのは、`impression-independent`レーン以外では徹底NG。**

- **`cv-native`レーン(やめたこと/やってること/思考法など自分主語のリスト)**: WFMは他の項目と完全に同一の体裁(見出しサイズ・線画アイコンの様式)で1項目に混ざる。専用カード枠・専用見出しは禁止。訴求の中身は`personalization-draw`(「今日はこれが出た」)ではなく`loss-framing`(例: 「スクショだけ溜まって、二度と見返さない保存はやめた」→WFMのASO核心訴求「保存墓場」と直結)を優先する。理由: personalization-drawは投稿内で結果を見せてしまい欲望が完結するため、①③②の実測が良くてもCVへの寄与は体感的に弱いとMayuが判断(2026-08-17)。名前+小さいアイコンは残す(「何のアプリか」は必ず分かる状態を維持)。
- **`impression-independent`レーン(③のような他人主語・行動描写型リスト)**: WFMをリスト内に自然統合するのは構造的に不可能(主語が「彼/彼女」であり、読者自身の習慣ではないため)。この型は無理にネイティブ統合を狙わず、独立した訴求(締め脚注等)でよい。ただし過剰な説明は不要。`plain-namedrop`(名前+「名言アプリ」程度の超短属性+アイコン)で十分。目的はCVではなくインプレッション・認知獲得。
- **`quote-collection`レーン(涙が出てくる精神科医の言葉7選など)**: 上記2レーンとは別構造。空欄化(`withheld-completion`)を使う場合、コピーで仕組みを説明しない(「まだ誰にも見せていません」等の宣言口調は広告臭になり失敗した実例あり、2026-08-17)。①③②と同じ一人称の日記調1行に留める。

## performance-log.jsonlの拡張

Upload-Post経由の投稿も同じログに合流させる。既存行との判別のため `source` フィールドを追加(Postiz取得分は`"source": "postiz"`、Upload-Post取得分は`"source": "upload-post"`)。

```json
{"source": "upload-post", "slug": "2026-08-16-furarenai-iionna", "platform": "tiktok",
 "profile": "Wordsforme", "platform_post_id": "7674536565124779272",
 "metrics": {"views": 4976, "likes": 108, "comments": 2, "shares": 2},
 "collected_at": "2026-08-17T14:56:00+09:00"}
```

## 生成物: learning-set.csv

`build_learning_set.py`が`content-ledger.json`(variables込み)と`performance-log.jsonl`(各postの最新スナップショット)を結合し、1投稿1行のフラットなCSVを`Marketing/UGC/learning-set.csv`に出力する。列は variables の全フィールド + `views/likes/comments/shares/engagement_rate` + `app_downloads_same_day`(現状は常にnull、ASC接続後に埋まる)。

## DL数(App Store Connect)接続 — 2026-08-17 認証・接続確認済み、データ生成待ち

`~/.claude/skills/wfm-ugc-ops/scripts/fetch_asc_downloads.py` で App Store Connect Analytics Reports API (`/v1/analyticsReportRequests`) から日別ダウンロード数を取得し、learning-setに結合する。

**セットアップ済み(2026-08-17)**:
- App Store Connect API Key(Key ID: `WA9V8XCLZZ`、ロール: Team Key)をMayuが発行
- `.p8`ファイルは `~/.appstoreconnect/private_keys/AuthKey_WA9V8XCLZZ.p8` に保管(パーミッション600、リポジトリ外)
- `~/.zshrc` に `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_PRIVATE_KEY_PATH` を設定済み
- 依存パッケージ(pyjwt, cryptography, requests)インストール済み

**動作確認結果**: JWT署名・app_id解決(`6759647519`、Words For MeのApp Store ID)・ONGOING analyticsReportRequest作成・「App Store Downloads」レポート特定まで**全部成功**。最後の「日次インスタンス取得」だけ、Appleが初回リクエスト後に集計を開始するまでの待機時間(通常24〜48時間、環境により数日)でデータがまだ存在せず失敗する。これはスクリプトの不具合ではなく仕様通りの待機状態。

**次にやること**: 1〜2日後に再実行(`zsh -ic "python3 ~/.claude/skills/wfm-ugc-ops/scripts/fetch_asc_downloads.py"`)。日次データが生成されていれば`Marketing/UGC/app-downloads-daily.json`が出力され、`build_learning_set.py`を再実行すればlearning-set.csvの`app_downloads_same_day`列が自動で埋まる(結合ロジックは実装済み・検証待ち)。

代替/併用案として、RevenueCatのSecret API Keyがあれば「New Customers(新規顧客)」を install の近似値として取れる可能性がある(恋愛温度計の競合資料でも同指標が使われていた)。こちらは未設定のまま。

## 運用フロー(今後の投稿で必ずやること)

1. バッチ作成時、script.mdまたはREADMEに variables の値をメモしておく
2. 投稿後、content-ledger.jsonのエントリに`variables`ブロックを埋める(postsブロックと同階層)
3. 定期的に `fetch_uploadpost_analytics.py` / 既存 `fetch_analytics.py` を実行して最新値を蓄積
4. `build_learning_set.py` を実行してCSVを更新
5. 10〜15行溜まったら相関を見る(pandasで`title_source_metric_saves` vs `views`/`engagement_rate`等)
