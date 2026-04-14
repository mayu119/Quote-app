#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/hayashimasaki/Downloads/名言アプリ"
SRC_DIR="$ROOT/スクショ"
OUT_BASE="$SRC_DIR/審査用_20260227"
FONT_REG="/System/Library/Fonts/ヒラギノ角ゴシック W4.ttc"
FONT_BOLD="/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
FONT_HEAVY="/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc"

mkdir -p "$OUT_BASE/6.5" "$OUT_BASE/6.7"

render_slide() {
  local w="$1"
  local h="$2"
  local src="$3"
  local out="$4"
  local kicker="$5"
  local headline="$6"
  local sub="$7"
  local add_widget="${8:-0}"

  local pad_x=$((w * 7 / 100))
  local y_kicker=$((h * 9 / 100))
  local y_head=$((h * 13 / 100))
  local y_sub=$((h * 26 / 100))
  local ps_kicker=$((w * 3 / 100))
  local ps_head=$((w * 5 / 100))
  local ps_sub=$((w * 28 / 1000))

  magick "$src" \
    -resize "${w}x${h}^" -gravity center -extent "${w}x${h}" \
    -fill "#00000055" -colorize 100 \
    \( -size "${w}x${h}" gradient:'#050505EE-#05050522' \) -compose multiply -composite \
    -gravity northwest \
    -fill "#D8D8D8" -font "$FONT_BOLD" -pointsize "$ps_kicker" -annotate "+$pad_x+$y_kicker" "$kicker" \
    -fill "#FFFFFF" -font "$FONT_HEAVY" -pointsize "$ps_head" -annotate "+$pad_x+$y_head" "$headline" \
    -fill "#D0D0D0" -font "$FONT_REG" -pointsize "$ps_sub" -annotate "+$pad_x+$y_sub" "$sub" \
    -fill "#FFFFFF99" -font "$FONT_BOLD" -pointsize "$ps_kicker" -annotate "+$pad_x+$((h * 92 / 100))" "MyWords" \
    "$out"

  if [[ "$add_widget" == "1" ]]; then
    local widget_w=$((w * 42 / 100))
    local widget_h=$((h * 22 / 100))
    local widget_x=$((w * 6 / 100))
    local widget_y=$((h * 56 / 100))
    magick "$out" \
      \( "$SRC_DIR/ウィジェット.png" -resize "${widget_w}x${widget_h}^" -gravity center -extent "${widget_w}x${widget_h}" \) \
      -gravity southeast -geometry "+$widget_x+$widget_y" -composite \
      "$out"
  fi
}

# 6.5-inch (1284x2778)
render_slide 1284 2778 "$SRC_DIR/ホーム画面.PNG" "$OUT_BASE/6.5/01_home.png" \
  "DAILY QUOTE" "毎日、\n整う一言を。" "開くたびに、行動のスイッチを入れる"
render_slide 1284 2778 "$SRC_DIR/ホーム画面２.png" "$OUT_BASE/6.5/02_focus.png" \
  "FOCUS" "考え込みすぎず、\n次の一歩へ。" "短い言葉が、迷いを小さくする"
render_slide 1284 2778 "$SRC_DIR/ホーム画面.PNG" "$OUT_BASE/6.5/03_widget.png" \
  "WIDGET" "ホームで自然に、\n続けられる。" "思い出す負担を減らして、習慣を守る" 1
render_slide 1284 2778 "$SRC_DIR/お気に入り.PNG" "$OUT_BASE/6.5/04_favorite.png" \
  "FAVORITES" "刺さった言葉を、\n自分の資産に。" "あとで読み返せる、あなただけの名言集"
render_slide 1284 2778 "$SRC_DIR/シェア画面.png" "$OUT_BASE/6.5/05_share.png" \
  "SHARE" "想いを、\n美しくシェア。" "大切な一言を、画像でそのまま届ける"

# 6.7-inch (1290x2796)
render_slide 1290 2796 "$SRC_DIR/ホーム画面.PNG" "$OUT_BASE/6.7/01_home.png" \
  "DAILY QUOTE" "毎日、\n整う一言を。" "開くたびに、行動のスイッチを入れる"
render_slide 1290 2796 "$SRC_DIR/ホーム画面２.png" "$OUT_BASE/6.7/02_focus.png" \
  "FOCUS" "考え込みすぎず、\n次の一歩へ。" "短い言葉が、迷いを小さくする"
render_slide 1290 2796 "$SRC_DIR/ホーム画面.PNG" "$OUT_BASE/6.7/03_widget.png" \
  "WIDGET" "ホームで自然に、\n続けられる。" "思い出す負担を減らして、習慣を守る" 1
render_slide 1290 2796 "$SRC_DIR/お気に入り.PNG" "$OUT_BASE/6.7/04_favorite.png" \
  "FAVORITES" "刺さった言葉を、\n自分の資産に。" "あとで読み返せる、あなただけの名言集"
render_slide 1290 2796 "$SRC_DIR/シェア画面.png" "$OUT_BASE/6.7/05_share.png" \
  "SHARE" "想いを、\n美しくシェア。" "大切な一言を、画像でそのまま届ける"

echo "Generated screenshots in: $OUT_BASE"
