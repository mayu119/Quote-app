#!/usr/bin/env python3
from __future__ import annotations

import math
import unicodedata
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

ROOT = Path("/Users/hayashimasaki/Downloads/名言アプリ")
SRC = ROOT / "スクショ"
OUT = SRC / "審査用_20260227_promo"

FONT_R = "/System/Library/Fonts/ヒラギノ角ゴシック W4.ttc"
FONT_B = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
FONT_H = "/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc"


def n(s: str) -> str:
    return unicodedata.normalize("NFKC", s)


def pick(name: str) -> Path:
    key = n(name)
    for p in SRC.iterdir():
        if p.is_file() and key in n(p.name):
            return p
    raise FileNotFoundError(name)


ASSETS = {
    "home1": pick("ホーム画面.PNG"),
    "home2": pick("ホーム画面２"),
    "share": pick("シェア画面"),
    "fav": pick("お気に入り"),
    "widget": pick("ウィ"),
}


SLIDES = [
    {
        "file": "01_home.png",
        "left_title": "毎日、整う一言",
        "left_sub": "朝の起動直後に、\n行動へ切り替える",
        "right_title": "静かな強さを\n積み上げる",
        "right_sub": "広告なしの没入体験",
        "left_img": "home1",
        "right_img": "home2",
    },
    {
        "file": "02_focus.png",
        "left_title": "考え込みすぎず\n次の一歩へ",
        "left_sub": "短い言葉で、迷いを減らす",
        "right_title": "タップするだけの\nシンプル設計",
        "right_sub": "必要な機能にすぐ届く",
        "left_img": "home2",
        "right_img": "home1",
    },
    {
        "file": "03_widget.png",
        "left_title": "ホーム画面で\n自然に継続",
        "left_sub": "思い出す負担を最小化",
        "right_title": "ウィジェットで\n習慣化を支える",
        "right_sub": "短いフレーズを毎日更新",
        "left_img": "home1",
        "right_img": "widget",
        "chip": "WIDGET",
    },
    {
        "file": "04_favorite.png",
        "left_title": "刺さった言葉を\n保存して再訪",
        "left_sub": "自分だけの名言アーカイブ",
        "right_title": "必要な時に\nすぐ読み返せる",
        "right_sub": "迷った時の判断軸になる",
        "left_img": "fav",
        "right_img": "home2",
    },
    {
        "file": "05_share.png",
        "left_title": "想いを美しく\nシェア",
        "left_sub": "画像としてそのまま共有",
        "right_title": "世界観を崩さない\nダークトーン",
        "right_sub": "ブランド一貫のビジュアル",
        "left_img": "share",
        "right_img": "home1",
    },
]


def cover(img: Image.Image, w: int, h: int) -> Image.Image:
    sw, sh = img.size
    s = max(w / sw, h / sh)
    nw, nh = int(sw * s), int(sh * s)
    img = img.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (nw - w) // 2
    y = (nh - h) // 2
    return img.crop((x, y, x + w, y + h))


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, img.size[0], img.size[1]), radius=radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def draw_bg(w: int, h: int) -> Image.Image:
    base = Image.new("RGB", (w, h), "#07090D")
    d = ImageDraw.Draw(base)
    for i in range(12):
        alpha = int(26 - i * 2)
        c = (20 + i * 4, 24 + i * 3, 35 + i * 2)
        y = int(h * (i / 12))
        d.rectangle((0, y, w, y + h // 12 + 2), fill=c)
    vignette = Image.new("L", (w, h), 0)
    vd = ImageDraw.Draw(vignette)
    vd.ellipse((-w * 0.2, -h * 0.3, w * 1.2, h * 1.05), fill=180)
    vd.rectangle((0, int(h * 0.85), w, h), fill=70)
    dark = Image.new("RGBA", (w, h), (0, 0, 0, 180))
    dark.putalpha(vignette)
    return Image.alpha_composite(base.convert("RGBA"), dark).convert("RGBA")


def compose_slide(size: tuple[int, int], cfg: dict, out: Path) -> None:
    w, h = size
    canvas = draw_bg(w, h)
    d = ImageDraw.Draw(canvas)

    pad = int(w * 0.055)
    gap = int(w * 0.028)
    card_w = (w - pad * 2 - gap) // 2
    card_h = int(h * 0.77)
    top = int(h * 0.135)
    r = int(w * 0.05)

    # shadow
    for idx in range(2):
        x = pad + idx * (card_w + gap)
        sh = Image.new("RGBA", (card_w, card_h), (0, 0, 0, 0))
        sd = ImageDraw.Draw(sh)
        sd.rounded_rectangle((0, 0, card_w, card_h), radius=r, fill=(0, 0, 0, 110))
        sh = sh.filter(ImageFilter.GaussianBlur(int(w * 0.012)))
        canvas.alpha_composite(sh, (x, top + int(h * 0.01)))

    # cards
    for idx, (title, sub, img_key) in enumerate(
        [
            (cfg["left_title"], cfg["left_sub"], cfg["left_img"]),
            (cfg["right_title"], cfg["right_sub"], cfg["right_img"]),
        ]
    ):
        x = pad + idx * (card_w + gap)
        card = Image.new("RGBA", (card_w, card_h), (238, 239, 242, 255))
        cd = ImageDraw.Draw(card)
        cd.rounded_rectangle((0, 0, card_w, card_h), radius=r, fill=(238, 239, 242, 255))

        ft = ImageFont.truetype(FONT_H, int(w * 0.048))
        fs = ImageFont.truetype(FONT_R, int(w * 0.025))
        cd.multiline_text((int(card_w * 0.08), int(card_h * 0.09)), title, fill=(34, 36, 40), font=ft, spacing=8)
        cd.multiline_text((int(card_w * 0.08), int(card_h * 0.245)), sub, fill=(92, 96, 103), font=fs, spacing=6)

        ph_w = int(card_w * 0.78)
        ph_h = int(card_h * 0.55)
        p = cover(Image.open(ASSETS[img_key]).convert("RGB"), ph_w, ph_h)
        p = ImageEnhance.Brightness(p).enhance(0.95)
        p = rounded(p, int(w * 0.03))

        # slight tilt for dynamic storefront look
        angle = -8 if idx == 0 else 7
        if img_key == "widget":
            angle = 0
        p = p.rotate(angle, expand=True, resample=Image.Resampling.BICUBIC)
        px = int(card_w * 0.11)
        py = int(card_h * 0.42)
        card.alpha_composite(p, (px, py))

        # chip
        if cfg.get("chip") and idx == 1:
            chip_w, chip_h = int(card_w * 0.36), int(card_h * 0.08)
            chip = Image.new("RGBA", (chip_w, chip_h), (255, 255, 255, 255))
            chd = ImageDraw.Draw(chip)
            chd.rounded_rectangle((0, 0, chip_w, chip_h), radius=chip_h // 2, fill=(250, 250, 252, 255))
            chf = ImageFont.truetype(FONT_B, int(w * 0.022))
            tw = chd.textlength(cfg["chip"], font=chf)
            chd.text(((chip_w - tw) // 2, int(chip_h * 0.26)), cfg["chip"], fill=(45, 49, 55), font=chf)
            card.alpha_composite(chip, (int(card_w * 0.52), int(card_h * 0.52)))

        canvas.alpha_composite(rounded(card, r), (x, top))

    # top branding
    fk = ImageFont.truetype(FONT_B, int(w * 0.023))
    fh = ImageFont.truetype(FONT_H, int(w * 0.032))
    d.text((pad, int(h * 0.055)), "MyWords", font=fh, fill=(246, 246, 248, 255))
    d.text((pad + int(w * 0.1), int(h * 0.062)), "毎日に、静かな推進力を", font=fk, fill=(180, 184, 190, 255))

    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out, "PNG", optimize=True)


def main() -> None:
    for label, size in (("6.5", (1284, 2778)), ("6.7", (1290, 2796))):
        for slide in SLIDES:
            compose_slide(size, slide, OUT / label / slide["file"])
    print(f"Generated promo screenshots in: {OUT}")


if __name__ == "__main__":
    main()
