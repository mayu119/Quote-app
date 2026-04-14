#!/usr/bin/env python3
from __future__ import annotations

import unicodedata
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

ROOT = Path("/Users/hayashimasaki/Downloads/名言アプリ")
SRC = ROOT / "スクショ"
OUT = SRC / "審査用_Stoic_20260227_polished"

FONT_REG = "/System/Library/Fonts/ヒラギノ角ゴシック W4.ttc"
FONT_BOLD = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
FONT_HEAVY = "/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc"

TOKENS = {
    "bg_top": (11, 9, 8),
    "bg_mid": (24, 18, 14),
    "bg_bot": (9, 8, 7),
    "brand": (214, 185, 128),
    "kicker": (182, 148, 92),
    "title": (245, 236, 223),
    "sub": (186, 168, 139),
    "panel": (18, 14, 12, 232),
    "cta_l": (186, 146, 88),
    "cta_r": (122, 93, 58),
    "cta_text": (250, 243, 230),
}


def nf(s: str) -> str:
    return unicodedata.normalize("NFKC", s)


def pick(name: str) -> Path:
    key = nf(name)
    for p in SRC.iterdir():
        if p.is_file() and key in nf(p.name):
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
    out = img.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (nw - w) // 2
    y = (nh - h) // 2
    return out.crop((x, y, x + w, y + h))


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, img.size[0], img.size[1]), radius=radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def fit_font(text: str, path: str, max_size: int, min_size: int, max_w: int, max_h: int, spacing: int = 0) -> ImageFont.FreeTypeFont:
    probe = Image.new("RGB", (16, 16), "black")
    d = ImageDraw.Draw(probe)
    for s in range(max_size, min_size - 1, -1):
        f = ImageFont.truetype(path, s)
        box = d.multiline_textbbox((0, 0), text, font=f, spacing=spacing)
        if (box[2] - box[0]) <= max_w and (box[3] - box[1]) <= max_h:
            return f
    return ImageFont.truetype(path, min_size)


def gradient_background(w: int, h: int) -> Image.Image:
    img = Image.new("RGB", (w, h), TOKENS["bg_top"])
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(1, h - 1)
        if t < 0.52:
            u = t / 0.52
            a, b = TOKENS["bg_top"], TOKENS["bg_mid"]
        else:
            u = (t - 0.52) / 0.48
            a, b = TOKENS["bg_mid"], TOKENS["bg_bot"]
        col = tuple(int(a[i] * (1 - u) + b[i] * u) for i in range(3))
        d.line((0, y, w, y), fill=col)
    # controlled depth bands
    d.rectangle((0, int(h * 0.34), w, int(h * 0.55)), fill=(16, 12, 10))
    d.rectangle((0, int(h * 0.55), w, int(h * 0.73)), fill=(22, 17, 13))
    return img.convert("RGBA")


def make_screen_card(screen: Image.Image, w: int, h: int) -> Image.Image:
    sc = cover(screen.convert("RGB"), w, h)
    sc = ImageEnhance.Brightness(sc).enhance(0.98)
    sc = ImageEnhance.Contrast(sc).enhance(1.04)
    return rounded(sc, int(w * 0.06))


def draw_cta(canvas: Image.Image, draw: ImageDraw.ImageDraw, w: int, h: int, text: str) -> None:
    cta_w = int(w * 0.86)
    cta_h = int(h * 0.066)
    cta = Image.new("RGBA", (cta_w, cta_h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(cta)
    for x in range(cta_w):
        t = x / max(1, cta_w - 1)
        r = int(TOKENS["cta_l"][0] * (1 - t) + TOKENS["cta_r"][0] * t)
        g = int(TOKENS["cta_l"][1] * (1 - t) + TOKENS["cta_r"][1] * t)
        b = int(TOKENS["cta_l"][2] * (1 - t) + TOKENS["cta_r"][2] * t)
        cd.line((x, 0, x, cta_h), fill=(r, g, b, 255))
    cta = rounded(cta, cta_h // 2)
    cx = (w - cta_w) // 2
    cy = int(h * 0.90)

    shadow = Image.new("RGBA", (cta_w, cta_h), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((0, 0, cta_w, cta_h), radius=cta_h // 2, fill=(28, 20, 14, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=8))
    canvas.alpha_composite(shadow, (cx, cy + int(h * 0.006)))
    canvas.alpha_composite(cta, (cx, cy))

    tf = fit_font(text, FONT_BOLD, int(w * 0.039), int(w * 0.028), int(cta_w * 0.86), int(cta_h * 0.66))
    tw = draw.textlength(text, font=tf)
    draw.text((cx + int((cta_w - tw) / 2), cy + int(cta_h * 0.24)), text, font=tf, fill=TOKENS["cta_text"])


def draw_slide(size: tuple[int, int], cfg: dict, out_path: Path) -> None:
    w, h = size
    canvas = gradient_background(w, h)
    d = ImageDraw.Draw(canvas)
    mx = int(w * 0.075)

    # Header block with stricter rhythm
    y0 = int(h * 0.050)
    d.text((mx, y0), "Stoic", font=ImageFont.truetype(FONT_BOLD, int(w * 0.034)), fill=TOKENS["brand"])
    kf = fit_font(cfg["kicker"], FONT_BOLD, int(w * 0.050), int(w * 0.032), int(w * 0.84), int(h * 0.05))
    d.text((mx, y0 + int(h * 0.048)), cfg["kicker"], font=kf, fill=TOKENS["kicker"])

    tf = fit_font(cfg["title"], FONT_HEAVY, int(w * 0.088), int(w * 0.058), int(w * 0.84), int(h * 0.12), spacing=int(w * 0.008))
    d.multiline_text((mx, y0 + int(h * 0.088)), cfg["title"], font=tf, fill=TOKENS["title"], spacing=int(w * 0.008))

    sf = fit_font(cfg["sub"], FONT_REG, int(w * 0.039), int(w * 0.028), int(w * 0.84), int(h * 0.052), spacing=4)
    d.multiline_text((mx, y0 + int(h * 0.205)), cfg["sub"], font=sf, fill=TOKENS["sub"], spacing=4)

    # Main screenshot card (no device frame)
    shot_w = int(w * 0.78)
    shot_h = int(h * 0.50)
    shot_x = int((w - shot_w) / 2)
    shot_y = int(h * 0.335)
    shot = make_screen_card(Image.open(ASSETS[cfg["screen"]]).convert("RGB"), shot_w, shot_h)

    shot_shadow = Image.new("RGBA", (shot_w, shot_h), (0, 0, 0, 0))
    ImageDraw.Draw(shot_shadow).rounded_rectangle((0, 0, shot_w, shot_h), radius=int(w * 0.06), fill=(0, 0, 0, 160))
    shot_shadow = shot_shadow.filter(ImageFilter.GaussianBlur(radius=16))
    canvas.alpha_composite(shot_shadow, (shot_x, shot_y + int(h * 0.012)))
    canvas.alpha_composite(shot, (shot_x, shot_y))

    draw_cta(canvas, d, w, h, cfg["cta"])

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
