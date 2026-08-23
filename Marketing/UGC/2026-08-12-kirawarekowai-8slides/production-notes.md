# 制作ノート — 嫌われるのが怖い人の特徴5選(8枚構成)

- creative-brief.md / design-spec.md(2026-08-13-jibunjiku-7slides流用)/ slides_compose_v2.py(参考実装)に準拠。
- Mayu指示: 却下バッチ`2026-08-12-kirawareta-7slides`の作り直し。タイトルは「嫌われるのが怖い人の特徴5選」、7〜8枚可(8枚採用)、締めは免罪名言+変われそうの予感。

## 写真生成

- codex-image-gen(gpt-image-2, quality high, size 1024x1536)で8枚を**文字なし**一括生成(jobs-file、1セッション)。
- 全プロンプトに `absolutely no text, no letters, no logos, no watermarks` を明記、顔は出さない/伏せ気味の指定を徹底。
- 1回目の一括生成(8枚)は**7枚がそのまま採用**(p01, p02, p03, p05, p06, p07, p08)。目視検品で文字・ロゴ・手指破綻なし、指定シーンとも一致。
- **p04(04特徴3・WFM出演スライド)のみ1回再生成**: 1回目はスマホを顔の高さ近くまで掲げた構図で、画面が画像上部(y≈290〜738 / 1080x1920換算)まで届いてしまい、タイトル文字「会話を思い出してる」の「出」がスクショ合成後に画面領域と衝突(可読性NG)。プロンプトを「スマホ画面の上端は画面中央より上に出さない/上部1/3は完全に空ける」と明示して再生成し、画面領域を下部(y≈1026〜1407)に収めて解決。
- 再生成回数: 8枚中1枚のみ1回再生成(合計9回生成)。

## WFM実画面の合成(スライド04)

- ソース: `/Users/mac2-mayu/Quote-app/スクショ/アプリスクショ/ホーム画面.png`(2026-08-13-jibunjiku-7slidesと同じ、夏目漱石の名言表示画面)。UI無改変、画面領域のみ透視変換。
- 画面四隅はPythonで白マスク検出(明度220以上)→convex corner抽出→1080x1920換算→3%内側にインセットして自動算出(目視合わせではなく数値検出のため誤差が少ない)。
- 最終quad: `[(450.5, 1030.7), (593.7, 1025.9), (595.7, 1406.6), (449.4, 1403.0)]`

## 文字合成

- `slides_compose_v2.py`を本バッチに`slides_compose.py`としてコピーし、写真パス・文言を全差し替え。
- 07(まとめ)の見出しが長い(「嫌われるのが怖い人の特徴5選」)ため、`recap_slide`を1行→複数行対応に拡張(元は「まとめ」の1行想定だった)。
- 08(免罪名言)用に新規`quote_slide`関数を追加。design-spec準拠(写真+統一スクリム、クリーム白+ローズ2色、1枚3色以内)。当初、中央の可読性確保のため線形グラデーションを2枚重ねたところ帯の継ぎ目(バンディング)が見えたため、単一の矩形をGaussianBlur(半径220)でぼかした暗幕に置き換えて解消。
- 名言下の出典表記は「Words For Me」のみをローズ色で小さく配置(quote id等の技術的な文字列はデザイン上画面には出さず、本ノートに記録する形で対応: quote id `women_original_292` / author `Original`)。
- フォント: ヒラギノ明朝ProN W6(タイトル)/ 角ゴW3(本文)/ 明朝W3(番号)。ローズ#EAA3A1、スクリム・グレーディング(彩度88%+ローズ5.5%)は全てdesign-spec通り。

## 最終QA(final 8枚・全数目視)

- 全8枚 1080×1920 を確認。
- 文字の見切れ: なし(fit_sizeによる自動縮小あり、実際の縮小適用なし=全て指定サイズのまま収まった)。
- コントラスト: 06(カフェ)は背景がやや明るいが、上部スクリム+ドロップシャドウで可読性は確保できていることを確認(前バッチ production-notes記載の「明背景での白文字コントラスト」課題を意識してチェック済み)。
- 07まとめ: CTA文言が入っていないことを確認(見出し+5項目のみ)。
- 08名言: 「嫌われない工夫より、\n自分に嘘をつかない工夫を。」で`quotes_full.json`の`women_original_292`と一字一句一致していることを確認。
- 04(WFM出演スライド): 再生成後、タイトルとスクショ合成領域の重なりが解消されたことを確認。

## 投稿

- 予約日時(当初): 2026-08-14 19:00 JST(TikTok/Instagram同日同時刻)
  - 本来は2026-08-13 19:00枠だが、同時刻・TikTokに既存予約(jibunjikuバッチ、postId `cmslude4v001mmj6p4td7k9yr`)があったため衝突を避けて翌日にずらし、TikTok/IGとも2026-08-14 19:00で揃えた。
- **TikTok: 2026-08-12 20:58 JSTにMayu指示で即時アップロードに変更・実行済み**
  - 旧予約(postId `cmsq0fik9001xmj6pok9a62t1`、8/14 19:00・QUEUE)を削除。
  - 同内容(UPLOAD方式・既存メディア8枚・同キャプション/タイトル)で即時日時の新規投稿を作成 → 新postId `cmsq1c1ib001zmj6p1abhzgwf`(integration `cmmwxv838000hp5734ulrbutj`)。
  - Postiz側state: **PUBLISHED**(releaseURL: `https://www.tiktok.com/messages?lang=en`, releaseId: `missing` — UPLOAD方式の標準応答。他バッチのUPLOAD投稿と同一パターン)。
  - TikTok Inbox内での実受信はPostiz側からは直接確認不可のため、**Mayu本人によるアプリ側確認待ち**。
- Instagram: postId `cmsq0fmj2001ymj6pf37zr00a`(integration `cmmwvxjv30001qr74l2knxama`)、**2026-08-14 19:00 JST予約のまま変更なし**(直接公開型のため予約維持)。
- リクエストpayload/レスポンスは `postiz/tiktok-payload.json` / `postiz/tiktok-response.txt`(即時アップロード分、最新)/ `postiz/tiktok-payload-superseded.json` / `postiz/tiktok-response-superseded.txt`(旧8/14予約分)/ `postiz/instagram-payload.json` / `postiz/instagram-response.txt` に保存。アップロード済みメディアのマッピングは `postiz/media-manifest.tsv`(今回のTikTok即時投稿でも同じ8枚を再利用)。
- content-ledger.jsonの`2026-08-12-kirawarekowai`エントリをTikTok新postId/PUBLISHED状態に更新済み(IG側は無改変)。
- caption.txtは既存のものをそのまま使用(brief記載のキャプションと一致確認済み)。
