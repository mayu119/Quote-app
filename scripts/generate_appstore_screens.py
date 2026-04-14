#!/usr/bin/env python3
from __future__ import annotations

import unicodedata
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

ROOT = Path("/Users/hayashimasaki/Downloads/名言アプリ")
SRC_DIR = ROOT / "スクショ"
OUT_BASE = SRC_DIR / "審査用_20260227"

FONT_REG = "/System/Library/Fonts/ヒラギノ角ゴシック W4.ttc"
FONT_BOLD = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
FONT_HEAVY = "/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc"


def n(s: str) -> str:
    return unicodedata.normalize("NFKC", s)


def find_source(keyword: str) -> Path:
    key = n(keyword)
    for p in SRC_DIR.iterdir():
        if p.is_file() and key in n(p.name):
            return p
    raise FileNotFoundError(f"source not found: {keyword}")


SOURCES = {
    "home1": find_source("ホーム画面.PNG"),
    "home2": find_source("ホーム画面２"),
    "widget": find_source("ウィ"),
    "favorite": find_source("お気に入り"),
    "share": find_source("シェア画面"),
}


def cover_resize(img: Image.Image, w: int, h: int) -> Image.Image:
    sw, sh = img.size
    scale = max(w / sw, h / sh)
    nw, nh = int(sw * scale), int(sh * scale)
    r = img.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - w) // 2
    top = (nh - h) // 2
    return r.crop((left, top, left + w, top + h))


def render_slide(
    size: tuple[int, int],
    src: Path,
    out: Path,
    kicker: str,
    headline: str,
    sub: str,
    add_widget: bool = False,
) -> None:
    w, h = size
    base = cover_resize(Image.open(src).convert("RGB"), w, h)
    base = ImageEnhance.Brightness(base).enhance(0.55)
    base = ImageEnhance.Contrast(base).enhance(1.1)

    # top-to-bottom dark gradient
    grad = Image.new("L", (1, h))
    for y in range(h):
        a = int(200 - (140 * y / h))
        grad.putpixel((0, y), max(40, min(255, a)))
    grad = grad.resize((w, h))
    overlay = Image.new("RGBA", (w, h), (5, 5, 5, 120))
    overlay.putalpha(grad)
    canvas = Image.alpha_composite(base.convert("RGBA"), overlay)

    draw = ImageDraw.Draw(canvas)
    pad_x = int(w * 0.07)
    y_kicker = int(h * 0.09)
    y_head = int(h * 0.13)
    y_sub = int(h * 0.27)

    f_kicker = ImageFont.truetype(FONT_BOLD, int(w * 0.03))
    f_head = ImageFont.truetype(FONT_HEAVY, int(w * 0.056))
    f_sub = ImageFont.truetype(FONT_REG, int(w * 0.028))

    draw.text((pad_x, y_kicker), kicker, font=f_kicker, fill=(220, 220, 220, 255))
    draw.multiline_text(
        (pad_x, y_head),
        headline,
        font=f_head,
        fill=(255, 255, 255, 255),
        spacing=int(w * 0.01),
    )
    draw.text((pad_x, y_sub), sub, font=f_sub, fill=(208, 208, 208, 255))
    draw.text(
        (pad_x, int(h * 0.92)),
        "MyWords",
        font=f_kicker,
        fill=(190, 190, 190, 220),
    )

    if add_widget:
        widget = Image.open(SOURCES["widget"]).convert("RGBA")
        ww, wh = int(w * 0.42), int(h * 0.22)
        widget = cover_resize(widget, ww, wh).filter(ImageFilter.GaussianBlur(0.3))
        x = w - ww - int(w * 0.06)
        y = int(h * 0.56)
        canvas.alpha_composite(widget, (x, y))

    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out, "PNG", optimize=True)


def main() -> None:
    slides = [
        ("01_home.png", "home1", "DAILY QUOTE", "毎日、\n整う一言を。", "開くたびに、行動のスイッチを入れる", False),
        ("02_focus.png", "home2", "FOCUS", "考え込みすぎず、\n次の一歩へ。", "短い言葉が、迷いを小さくする", False),
        ("03_widget.png", "home1", "WIDGET", "ホームで自然に、\n続けられる。", "思い出す負担を減らして、習慣を守る", True),
        ("04_favorite.png", "favorite", "FAVORITES", "刺さった言葉を、\n自分の資産に。", "あとで読み返せる、あなただけの名言集", False),
        ("05_share.png", "share", "SHARE", "想いを、\n美しくシェア。", "大切な一言を、画像でそのまま届ける", False),
    ]

    for label, size in (("6.5", (1284, 2778)), ("6.7", (1290, 2796))):
        for filename, src_key, kicker, head, sub, add_widget in slides:
            render_slide(
                size=size,
                src=SOURCES[src_key],
                out=OUT_BASE / label / filename,
                kicker=kicker,
                headline=head,
                sub=sub,
                add_widget=add_widget,
            )
    print(f"Generated screenshots in: {OUT_BASE}")


if __name__ == "__main__":
    main()
