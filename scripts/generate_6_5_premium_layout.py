#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path("/Users/hayashimasaki/Downloads/名言アプリ")
SRC = ROOT / "スクショ" / "6_5_raw"
OUT = ROOT / "スクショ" / "6_5_premium_export"

W, H = 1284, 2778

FONT_R = "/System/Library/Fonts/ヒラギノ角ゴシック W4.ttc"
FONT_B = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
FONT_H = "/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc"

SLIDES = [
    {
        "file": "premium_6_5_01.png",
        "title": "朝の一言で、\n行動の質が変わる",
        "sub": "迷いを削ぎ落とし、最初の一歩を速くする。",
        "phones": [
            {"img": "01_home2_6_5.png", "x": 140, "y": 420, "angle": 7},
        ],
    },
    {
        "file": "premium_6_5_02.png",
        "title": "今の自分に刺さる\n言葉を選べる",
        "sub": "カテゴリ導線で、必要なメッセージに最短で届く。",
        "phones": [
            {"img": "03_genre_6_5.png", "x": -170, "y": 600, "angle": -9, "scale": 0.66},
            {"img": "02_home3_6_5.png", "x": 500, "y": 1040, "angle": 6, "scale": 0.62},
        ],
    },
    {
        "file": "premium_6_5_03.png",
        "title": "背景を選んで、\n没入感を高める",
        "sub": "視覚トーンが整うと、言葉の刺さり方も変わる。",
        "phones": [
            {"img": "04_wallpaper_6_5.png", "x": 10, "y": 500, "angle": 0},
        ],
    },
    {
        "file": "premium_6_5_04.png",
        "title": "スワイプで\nSNSに共有",
        "sub": "共有はスワイプ操作。世界観のままシェアできる。",
        "phones": [
            {"img": "05_share_screen_6_5.png", "x": 170, "y": 470, "angle": 4},
        ],
    },
    {
        "file": "premium_6_5_05.png",
        "title": "広告ゼロ。\n無料で始める",
        "sub": "毎日1名言・お気に入り・シェアまで、すぐ体験できる。",
        "phones": [
            {"img": "01_home2_6_5.png", "x": -220, "y": 760, "angle": -10, "scale": 0.64},
            {"img": "05_share_screen_6_5.png", "x": 530, "y": 1060, "angle": 8, "scale": 0.62},
        ],
    },
]


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def draw_bg() -> Image.Image:
    bg = Image.new("RGBA", (W, H), "#0A0D16")
    d = ImageDraw.Draw(bg)
    top = (18, 28, 52)
    bottom = (8, 11, 20)
    for y in range(H):
        t = y / max(1, H - 1)
        c = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        d.line((0, y, W, y), fill=(*c, 255))

    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((-200, -280, 900, 680), fill=(200, 160, 90, 70))
    gd.ellipse((420, 260, 1500, 1240), fill=(110, 150, 240, 55))
    gd.ellipse((-260, 1650, 820, 2900), fill=(160, 120, 70, 45))
    glow = glow.filter(ImageFilter.GaussianBlur(110))
    return Image.alpha_composite(bg, glow)


def make_phone(screen: Image.Image) -> Image.Image:
    bezel = 24
    corner = 110

    screen = screen.convert("RGBA")
    smask = rounded_mask(screen.size, corner)
    screen.putalpha(smask)

    pw = screen.size[0] + bezel * 2
    ph = screen.size[1] + bezel * 2
    phone = Image.new("RGBA", (pw, ph), (12, 14, 20, 255))
    pd = ImageDraw.Draw(phone)
    pd.rounded_rectangle((0, 0, pw, ph), radius=corner + bezel, fill=(13, 15, 22, 255))

    phone.alpha_composite(screen, (bezel, bezel))

    notch_w = int(pw * 0.34)
    notch_h = int(ph * 0.028)
    nx = (pw - notch_w) // 2
    ny = bezel + 16
    pd.rounded_rectangle((nx, ny, nx + notch_w, ny + notch_h), radius=notch_h // 2, fill=(7, 8, 12, 255))

    return phone


def draw_header(img: Image.Image, title: str, sub: str) -> None:
    panel = Image.new("RGBA", (W, 760), (0, 0, 0, 0))
    pd = ImageDraw.Draw(panel)
    for y in range(760):
        t = y / 760.0
        a = int(245 * (1 - t) ** 1.22)
        pd.line((0, y, W, y), fill=(5, 6, 10, a))
    img.alpha_composite(panel, (0, 0))

    d = ImageDraw.Draw(img)
    f_brand = ImageFont.truetype(FONT_B, 33)
    f_title = ImageFont.truetype(FONT_H, 84)
    f_sub = ImageFont.truetype(FONT_R, 38)

    d.text((76, 112), "WAGEN  PREMIUM", fill=(244, 206, 138, 255), font=f_brand)
    d.multiline_text((76, 194), title, fill=(250, 252, 255, 255), font=f_title, spacing=10)
    d.text((76, 470), sub, fill=(224, 230, 240, 255), font=f_sub)


def apply_top_round(img: Image.Image, radius: int = 92) -> Image.Image:
    """Round only top corners to keep App Store-safe full frame size."""
    w, h = img.size
    mask = Image.new("L", (w, h), 255)
    d = ImageDraw.Draw(mask)

    # Clear top corners and repaint quarter-circles.
    d.rectangle((0, 0, radius, radius), fill=0)
    d.rectangle((w - radius, 0, w, radius), fill=0)
    d.pieslice((0, 0, radius * 2, radius * 2), 180, 270, fill=255)
    d.pieslice((w - radius * 2, 0, w, radius * 2), 270, 360, fill=255)

    bg = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    bg.paste(img, (0, 0), mask)
    return bg


def compose_slide(cfg: dict) -> None:
    canvas = draw_bg()

    # Device shadows + phones
    for p in cfg["phones"]:
        shot = Image.open(SRC / p["img"])
        phone = make_phone(shot)
        scale = float(p.get("scale", 1.0))
        if scale != 1.0:
            phone = phone.resize(
                (int(phone.size[0] * scale), int(phone.size[1] * scale)),
                Image.Resampling.LANCZOS,
            )

        shadow = Image.new("RGBA", phone.size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow)
        sd.rounded_rectangle((0, 0, shadow.size[0], shadow.size[1]), radius=130, fill=(0, 0, 0, 175))
        shadow = shadow.filter(ImageFilter.GaussianBlur(35))

        ang = p["angle"]
        phone_r = phone.rotate(ang, expand=True, resample=Image.Resampling.BICUBIC)
        shadow_r = shadow.rotate(ang, expand=True, resample=Image.Resampling.BICUBIC)

        canvas.alpha_composite(shadow_r, (p["x"] + 10, p["y"] + 28))
        canvas.alpha_composite(phone_r, (p["x"], p["y"]))

    draw_header(canvas, cfg["title"], cfg["sub"])

    canvas = apply_top_round(canvas, 92)

    OUT.mkdir(parents=True, exist_ok=True)
    out_path = OUT / cfg["file"]
    canvas.convert("RGB").save(out_path, "PNG", optimize=True)

    # Also place directly under スクショ for quick access
    direct = ROOT / "スクショ" / cfg["file"]
    canvas.convert("RGB").save(direct, "PNG", optimize=True)


def main() -> None:
    for cfg in SLIDES:
        compose_slide(cfg)
    print(f"Generated premium screenshots in: {OUT}")


if __name__ == "__main__":
    main()
