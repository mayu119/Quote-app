# 制作ノート

## 8/1 — D: 送れなかったLINE

- 素材: `d-unsent-line/`
- 4枚: `01-cover.png` → `02-confession.png` → `03-reveal.png` → `04-app-proof.png`
- ラベル: 言葉を飲み込みがちな人
- 投稿型: 未送信メッセージを、自分への手紙に返すUGC

## 8/2 — E: 夜の処方箋

- 素材: `e-night-prescription/`
- 4枚: `01-cover.png` → `02-confession.png` → `03-reveal.png` → `04-app-proof.png`
- ラベル: 失敗した夜に自分を採点してしまう人
- 投稿型: 封筒を開いて、眠る前の一言を受け取るUGC

## QA

- 2投稿、各4枚（合計8枚）。
- 全画像1080 × 1920 px。
- 既存の「保存」「メモ」「カレンダー振り返り」型と異なり、どちらも物語のリビールを主役にしている。

## Postiz予約設定

連携先: `stoic -前へ進むための言葉` / TikTok `words_for_me_jp`  
投稿方式: TikTok写真カルーセル / `UPLOAD`

| 日付・時刻（JST） | 投稿 | Postiz ID | 再取得状態 |
| --- | --- | --- | --- |
| 2026-08-01 11:00 | D: 送れなかったLINE | `cms76ejh80009mj6piusiqup3` | `QUEUE` |
| 2026-08-02 11:00 | E: 夜の処方箋 | `cms76ejih000amj6prwbb216a` | `QUEUE` |

- `QUEUE` は予定時刻にTikTok受信箱へ送るための予約済み状態。
- 送信後に `PUBLISHED` とTikTokメッセージURLが発行されたら、TikTok側で最終公開操作を行う。
- API作成応答・アップロード済みメディア・再取得結果: `postiz/`
