# 子供が育ってわかったこと7選

Words For Me向けの縦型スライドショー投稿アセットです。採用版は参照動画に合わせた単色グレー＋白文字です。

## Deliverables

- `generated/background-imagegen-source.png`
  - Codex built-in image_genで生成した固定背景の元画像
  - 941×1672 PNG
- `slides/01.png`〜`slides/09.png`
  - 旧版。生成背景＋茶系文字のため不採用
  - 採用版は `slides-solid-gray/01.png`〜`09.png`
- `slides-solid-gray/01.png`〜`slides-solid-gray/09.png`
  - 単色グレー背景＋白文字の採用スライド
  - 各1080×1920 PNG
- `slideshow.mp4`
  - BGMなしの横スライド正式版
  - 1080×1920 / H.264 / 42.4秒 / 30fps
  - 各ページ4.0秒保持、横スライド0.8秒
  - 可聴BGM・ナレーションなし
- `slideshow-horizontal-slide-v1.mp4`
  - 正式版の元出力。`slideshow.mp4`と同一内容
- `slideshow-bgm-v1.mp4`
  - BGM試作。ボス判断により不採用
- `remotion-page-turn/`
  - 編集可能なRemotionプロジェクト
  - Composition: `KodomoSodatteWakattaHorizontalSlide`
- `preview/contact-sheet.jpg`
  - 9枚一覧確認用
- `compose_slides.py`
  - 固定背景から9枚を再生成する組版スクリプト
- `caption.txt`
  - 投稿本文案
- `imagegen_prompt.md`
  - 背景生成プロンプト

## Rejected previous version

画像生成背景版は参照動画の型から外れていたため不採用です。`generated/` と旧 `slides/` は失敗版として保存し、投稿には使用しません。

## Image generation evidence

- tmux session: `words-kodomo-bg`
- Codex session: `019ffa43-9011-7ac3-9171-7935b63073ee`
- Generated source: `/Users/mac2-mayu/.codex/generated_images/019ffa43-9011-7ac3-9171-7935b63073ee/exec-71a9dbd3-1727-4e74-8723-d295c17547ff.png`
- Final copied source: `generated/background-imagegen-source.png`

## Verification

- `file`でPNG/MP4形式を確認済み
- `sips`で9枚すべて1080×1920を確認済み
- `ffprobe`で正式版MP4の1080×1920、42.4秒、30fps、H.264、可聴BGMなしを確認済み
- 元出力由来の無音AACストリームは残っているが、BGM・ナレーションは含まない
- BGM試作 `slideshow-bgm-v1.mp4` はボス判断により不採用
- RemotionのComposition一覧で9枚構成、全体42.4秒を確認済み
- 保持中・横スライド途中・横スライド後・締めの実動画フレームを目視確認済み
- 切り替えは前ページが左へ抜け、次ページが右から入るだけの単純な横スライドであることを確認済み
- 紙の折れ目、3D回転、影、ハイライトなどの演出は使用していない
- 締めの名言が左右にはみ出した初稿は破棄し、3行組みに修正済み

## Posting state

投稿・予約・外部SNSへのアップロードはまだ実施していません。`slideshow.mp4` と `slides-solid-gray/` が投稿用の正式アセットです。動画編集の正本は `remotion-page-turn/` です。前回の立体ページターン版は不採用です。
