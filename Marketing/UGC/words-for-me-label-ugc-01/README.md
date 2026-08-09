# Words For Me ラベリングUGC 01

## 企画

- 人物ラベル: `人には優しいのに、自分には厳しい人`
- 欲望設計: 見抜かれたい → 許されたい → いい自分でいたい
- UGC構成: 人物ラベル → 投稿者の自己開示 → 使用習慣 → 保存価値 → 差別化 → アプリ開示
- トーン: 友達が夜に見つけたアプリを静かに勧める個人投稿

## ページコピー

1. `人には優しいのに、自分には厳しい人にやってほしいアプリ`
2. `人が落ち込んでる時はいくらでも優しいことを言えるのに、自分が落ち込むと急に全部ダメに見える。`
3. `最近、寝る前にその日の自分へ言葉を一枚だけ引いてる。`
4. `刺さった言葉は自分の棚に残せる。インスタの保存みたいに埋もれないのがよかった。`
5. `無理に前向きにさせてくる感じじゃなくて、「今日はここまででいい」って言ってくれる言葉が多い。`
6. `自分には厳しくなっちゃう人ほど、一回やってみてほしい。`

## 生成プロンプトの核

```text
Japanese 9:16 creator-style UGC app recommendation carousel.
Warm fibrous cream paper, charcoal-plum Mincho typography, imperfect marker strokes,
one dusty-pink tape accent, restrained mature feminine personal-notebook composition.
Start with a positive identity label, continue in first-person experience,
show supplied real app screenshots as final UI artwork, and reveal the supplied official icon only on the last page.
Do not make it look like an official advertisement.
No ratings, store badges, QR codes, download buttons, people, faces, or platform chrome.
Render all Japanese copy verbatim.
```

## 参照素材

- 公式アイコン: `QuoteApp/Sources/Assets.xcassets/AppIcon.appiconset/Icon-1024.png`
- 今日の一枚: `QuoteApp/fastlane/screenshots/ja/daily-card-redesign/12-card-revealed-night-approved.png`
- 言葉の棚: `QuoteApp/fastlane/screenshots/ja/store-v113-b9/raw/04-calendar-shelf.png`
- 夜の言葉: `QuoteApp/fastlane/screenshots/ja/store-v113-b9/raw/03-night-revealed.png`

## 注意

画像生成は公式アイコンを参照して再生成しているが、最終ページのアイコンには元データにないごく薄い明暗が残っている。公開前にピクセル完全一致が必要なら、ユーザー承認後に公式アイコンへ差し替える。
