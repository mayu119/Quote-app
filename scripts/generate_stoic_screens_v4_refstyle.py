#!/usr/bin/env python3
from __future__ import annotations

import unicodedata
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

ROOT = Path("/Users/hayashimasaki/Downloads/名言アプリ")
SRC = ROOT / "スクショ"
OUT = SRC / "審査用_Stoic_20260227_refstyle"

FONT_REG = "/System/Library/Fonts/ヒラギノ角ゴシック W4.ttc"
FONT_BOLD = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
FONT_HEAVY = "/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc"


def nf(s: str) -> str:
    return unicodedata.normalize("NFKC", s)


def pick(name: str) -> Path:
    target = nf(name)
    for p in SRC.iterdir():
        if p.is_file() and target in nf(p.name):
            return p
    raise FileNotFoundError(name)


ASSETS = {
    "home": pick("ホーム画面.PNG"),
    "home2": pick("ホーム画面２"),
    "share": pick("シェア画面"),
    "favorite": pick("お気に入り"),
    "widget": pick("ウィ"),
}


SLIDES = [
    {
        "file": "01_home.png",
        "screen": "home",
        "kicker": "毎日の思考を整える",
        "title": "朝の迷いを\n1つの言葉で整える",
        "sub": "起動した瞬間に、今日の軸を取り戻す。",
        "cta": "Stoicで、今日を静かに始める",
    },
    {
        "file": "02_widget.png",
        "screen": "widget",
        "kicker": "自然に続く仕組み",
        "title": "ホーム画面で\n習慣化を支える",
        "sub": "思い出す負担を減らし、継続に集中できる。",
        "cta": "ウィジェットで、習慣を無理なく継続",
    },
    {
        "file": "03_favorites.png",
        "screen": "favorite",
        "kicker": "必要な時に再訪",
        "title": "刺さった言葉を\n保存して積み上げる",
        "sub": "迷う瞬間に、すぐ読み返せる自分のアーカイブ。",
        "cta": "大切な言葉を、あなたの資産にする",
    },
    {
        "file": "04_share.png",
        "screen": "share",
        "kicker": "言葉を美しく共有",
        "title": "カードでそのまま\nSNSにシェア",
        "sub": "世界観を保ったまま、想いを届けられる。",
        "cta": "共有まで、1タップで完結する",
    },
    {
        "file": "05_daily.png",
        "screen": "home2",
        "kicker": "1日1メッセージ",
        "title": "短い言葉で\n行動へ切り替える",
        "sub": "考え込みすぎる前に、次の一歩を促す。",
        "cta": "Stoicで、行動のスイッチを入れる",
    },
]


def cover(img: Image.Image, w: int, h: int) -> Image.Image:
    sw, sh = img.size
    scale = max(w / sw, h / sh)
    nw, nh = int(sw * scale), int(sh * scale)
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (nw - w) // 2
    y = (nh - h) // 2
    return resized.crop((x, y, x + w, y + h))


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, img.size[0], img.size[1]), radius=radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def fit_font(text: str, font_path: str, max_size: int, min_size: int, max_w: int, max_h: int, spacing: int = 0) -> ImageFont.FreeTypeFont:
    probe = Image.new("RGB", (8, 8), "black")
    d = ImageDraw.Draw(probe)
    for s in range(max_size, min_size - 1, -1):
        f = ImageFont.truetype(font_path, s)
        box = d.multiline_textbbox((0, 0), text, font=f, spacing=spacing)
        if (box[2] - box[0]) <= max_w and (box[3] - box[1]) <= max_h:
            return f
    return ImageFont.truetype(font_path, min_size)


def gradient_bg(w: int, h: int) -> Image.Image:
    top = (2, 13, 35)
    mid = (3, 21, 56)
    bot = (2, 12, 35)
    img = Image.new("RGB", (w, h), top)
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(1, h - 1)
        if t < 0.56:
            u = t / 0.56
            r = int(top[0] * (1 - u) + mid[0] * u)
            g = int(top[1] * (1 - u) + mid[1] * u)
            b = int(top[2] * (1 - u) + mid[2] * u)
        else:
            u = (t - 0.56) / 0.44
            r = int(mid[0] * (1 - u) + bot[0] * u)
            g = int(mid[1] * (1 - u) + bot[1] * u)
            b = int(mid[2] * (1 - u) + bot[2] * u)
        d.line((0, y, w, y), fill=(r, g, b))
    # subtle horizontal bands for depth
    d.rectangle((0, int(h * 0.36), w, int(h * 0.55)), fill=(2, 16, 44))
    d.rectangle((0, int(h * 0.55), w, int(h * 0.72)), fill=(3, 22, 58))
    return img.convert("RGBA")


def make_phone(screen: Image.Image, w: int, h: int) -> Image.Image:
    bezel = int(w * 0.022)
    body = Image.new("RGBA", (w, h), (7, 8, 10, 255))
    d = ImageDraw.Draw(body)
    # glowing cyan outer frame like the reference
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius=int(w * 0.10), outline=(64, 162, 255, 255), width=max(3, int(w * 0.008)), fill=(7, 8, 10, 255))

    sw = w - bezel * 2
    sh = h - bezel * 2
    sc = cover(screen.convert("RGB"), sw, sh)
    sc = rounded(sc, int(w * 0.08))
    body.alpha_composite(sc, (bezel, bezel))
    return body


def draw_slide(size: tuple[int, int], cfg: dict, out_path: Path) -> None:
    w, h = size
    canvas = gradient_bg(w, h)
    d = ImageDraw.Draw(canvas)
    pad = int(w * 0.075)

    # Copy block (top)
    d.text((pad, int(h * 0.05)), "Stoic", font=ImageFont.truetype(FONT_BOLD, int(w * 0.034)), fill=(140, 202, 255, 255))
    kicker_font = fit_font(cfg["kicker"], FONT_BOLD, int(w * 0.05), int(w * 0.032), int(w * 0.84), int(h * 0.05))
    d.text((pad, int(h * 0.095)), cfg["kicker"], font=kicker_font, fill=(106, 192, 255, 255))

    title_font = fit_font(cfg["title"], FONT_HEAVY, int(w * 0.094), int(w * 0.060), int(w * 0.84), int(h * 0.13), spacing=int(w * 0.008))
    d.multiline_text((pad, int(h * 0.135)), cfg["title"], font=title_font, fill=(236, 243, 255, 255), spacing=int(w * 0.008))

    sub_font = fit_font(cfg["sub"], FONT_REG, int(w * 0.040), int(w * 0.028), int(w * 0.84), int(h * 0.06), spacing=4)
    d.multiline_text((pad, int(h * 0.255)), cfg["sub"], font=sub_font, fill=(156, 190, 236, 255), spacing=4)

    # Center phone mock
    phone_w = int(w * 0.78)
    phone_h = int(h * 0.58)
    phone = make_phone(Image.open(ASSETS[cfg["screen"]]).convert("RGB"), phone_w, phone_h)
    px = int((w - phone_w) / 2)
    py = int(h * 0.305)

    # soft glow behind phone
    glow = Image.new("RGBA", (int(phone_w * 1.05), int(phone_h * 0.88)), (70, 150, 255, 95))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=40))
    gx = px - int((glow.width - phone_w) / 2)
    gy = py + int(phone_h * 0.10)
    canvas.alpha_composite(glow, (gx, gy))
    canvas.alpha_composite(phone, (px, py))

    # CTA pill (bottom)
    cta_w = int(w * 0.86)
    cta_h = int(h * 0.066)
    cta = Image.new("RGBA", (cta_w, cta_h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(cta)
    for x in range(cta_w):
        t = x / max(1, cta_w - 1)
        r = int(72 * (1 - t) + 96 * t)
        g = int(174 * (1 - t) + 122 * t)
        b = int(246 * (1 - t) + 240 * t)
        cd.line((x, 0, x, cta_h), fill=(r, g, b, 255))
    cta = rounded(cta, cta_h // 2)
    cx = int((w - cta_w) / 2)
    cy = int(h * 0.90)
    canvas.alpha_composite(cta, (cx, cy))

    cta_font = fit_font(cfg["cta"], FONT_BOLD, int(w * 0.042), int(w * 0.028), int(cta_w * 0.86), int(cta_h * 0.70))
    tw = d.textlength(cfg["cta"], font=cta_font)
    d.text((cx + int((cta_w - tw) / 2), cy + int(cta_h * 0.24)), cfg["cta"], font=cta_font, fill=(242, 248, 255, 255))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out_path, "PNG", optimize=True)


def main() -> None:
    targets = [("6.5", (1284, 2778)), ("6.7", (1290, 2796))]
    for label, size in targets:
        for slide in SLIDES:
            draw_slide(size, slide, OUT / label / slide["file"])
    print(f"Generated: {OUT}")


if __name__ == "__main__":
    main()
