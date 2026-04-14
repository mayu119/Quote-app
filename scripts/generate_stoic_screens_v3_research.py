#!/usr/bin/env python3
from __future__ import annotations

import math
import unicodedata
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

ROOT = Path("/Users/hayashimasaki/Downloads/名言アプリ")
SRC = ROOT / "スクショ"
OUT = SRC / "審査用_Stoic_20260227_research"

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
        "layout": "hero",
        "kicker": "CORE VALUE",
        "title": "毎朝、軸が戻る",
        "sub": "1日1つの名言で、思考を整える。",
        "main": "home",
        "secondary": "home2",
    },
    {
        "file": "02_action.png",
        "layout": "left_copy_right_device",
        "kicker": "ACTION",
        "title": "迷ったら、\n次の一歩へ",
        "sub": "短い言葉で、行動に切り替える。",
        "main": "home2",
        "secondary": "home",
    },
    {
        "file": "03_widget.png",
        "layout": "light_card",
        "kicker": "WIDGET",
        "title": "ホーム画面で\n自然に続く",
        "sub": "思い出す負担を減らし、習慣化を支える。",
        "main": "widget",
        "secondary": "home",
    },
    {
        "file": "04_favorites.png",
        "layout": "library",
        "kicker": "FAVORITES",
        "title": "刺さった言葉を\n保存して再訪",
        "sub": "必要な瞬間に、すぐ読み返せる。",
        "main": "favorite",
        "secondary": "home2",
    },
    {
        "file": "05_share.png",
        "layout": "share_stage",
        "kicker": "SHARE",
        "title": "美しいカードで\n言葉を共有",
        "sub": "Instagram / Xへ、そのまま届ける。",
        "main": "share",
        "secondary": "home",
    },
]


def cover(img: Image.Image, w: int, h: int) -> Image.Image:
    sw, sh = img.size
    s = max(w / sw, h / sh)
    nw, nh = int(sw * s), int(sh * s)
    r = img.resize((nw, nh), Image.Resampling.LANCZOS)
    x = (nw - w) // 2
    y = (nh - h) // 2
    return r.crop((x, y, x + w, y + h))


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, img.size[0], img.size[1]), radius=radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def shadow_box(size: tuple[int, int], radius: int, alpha: int) -> Image.Image:
    box = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(box)
    d.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=(0, 0, 0, alpha))
    return box.filter(ImageFilter.GaussianBlur(radius=max(2, radius // 4)))


def fit_font(text: str, font_path: str, max_size: int, min_size: int, max_w: int, max_h: int, spacing: int = 0) -> ImageFont.FreeTypeFont:
    probe = Image.new("RGB", (16, 16), "black")
    draw = ImageDraw.Draw(probe)
    for size in range(max_size, min_size - 1, -1):
        font = ImageFont.truetype(font_path, size)
        box = draw.multiline_textbbox((0, 0), text, font=font, spacing=spacing)
        if (box[2] - box[0]) <= max_w and (box[3] - box[1]) <= max_h:
            return font
    return ImageFont.truetype(font_path, min_size)


def draw_copy(draw: ImageDraw.ImageDraw, w: int, h: int, cfg: dict, x: int, y: int, bw: int) -> None:
    f_brand = ImageFont.truetype(FONT_BOLD, int(w * 0.034))
    f_kicker = ImageFont.truetype(FONT_BOLD, int(w * 0.022))
    f_title = fit_font(cfg["title"], FONT_HEAVY, int(w * 0.09), int(w * 0.055), bw, int(h * 0.12), spacing=int(w * 0.01))
    f_sub = fit_font(cfg["sub"], FONT_REG, int(w * 0.038), int(w * 0.026), bw, int(h * 0.06), spacing=4)

    draw.text((x, y), "Stoic", font=f_brand, fill=(245, 246, 250, 255))
    draw.text((x, y + int(h * 0.045)), cfg["kicker"], font=f_kicker, fill=(184, 190, 200, 255))
    draw.multiline_text((x, y + int(h * 0.08)), cfg["title"], font=f_title, fill=(252, 252, 255, 255), spacing=int(w * 0.01))
    draw.multiline_text((x, y + int(h * 0.18)), cfg["sub"], font=f_sub, fill=(190, 195, 203, 255), spacing=4)


def make_phone(screen: Image.Image, w: int, h: int) -> Image.Image:
    bezel = int(w * 0.028)
    body = Image.new("RGBA", (w, h), (10, 10, 12, 255))
    d = ImageDraw.Draw(body)
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius=int(w * 0.11), fill=(10, 10, 12, 255))

    sw = w - bezel * 2
    sh = h - bezel * 2
    inside = cover(screen.convert("RGB"), sw, sh)
    inside = rounded(inside, int(w * 0.085))
    body.alpha_composite(inside, (bezel, bezel))

    notch_w = int(w * 0.24)
    notch_h = int(h * 0.033)
    nx = (w - notch_w) // 2
    ny = int(h * 0.04)
    d.rounded_rectangle((nx, ny, nx + notch_w, ny + notch_h), radius=notch_h // 2, fill=(0, 0, 0, 255))
    return body


def textured_bg(w: int, h: int, key: str, tint=(8, 10, 14, 180)) -> Image.Image:
    bg = cover(Image.open(ASSETS[key]).convert("RGB"), w, h)
    bg = bg.filter(ImageFilter.GaussianBlur(radius=20))
    bg = ImageEnhance.Brightness(bg).enhance(0.34)
    bg = ImageEnhance.Contrast(bg).enhance(1.18)
    tint_layer = Image.new("RGBA", (w, h), tint)
    mix = Image.alpha_composite(bg.convert("RGBA"), tint_layer)
    grad = Image.new("L", (1, h))
    for y in range(h):
        a = int(220 - (145 * y / h))
        grad.putpixel((0, y), max(70, min(255, a)))
    grad = grad.resize((w, h))
    top = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    top.putalpha(grad)
    return Image.alpha_composite(mix, top)


def layout_hero(size: tuple[int, int], cfg: dict) -> Image.Image:
    w, h = size
    canvas = textured_bg(w, h, cfg["main"])
    d = ImageDraw.Draw(canvas)
    draw_copy(d, w, h, cfg, int(w * 0.08), int(h * 0.06), int(w * 0.52))

    bar = Image.new("RGBA", (int(w * 0.24), int(h * 0.006)), (82, 104, 146, 255))
    bar = bar.filter(ImageFilter.GaussianBlur(radius=4))
    canvas.alpha_composite(bar, (int(w * 0.29), int(h * 0.53)))

    phone = make_phone(Image.open(ASSETS[cfg["main"]]).convert("RGB"), int(w * 0.63), int(w * 0.63 * 2.07))
    phone = phone.rotate(-10, expand=True, resample=Image.Resampling.BICUBIC)
    canvas.alpha_composite(phone, (int(w * 0.43), int(h * 0.34)))

    mini = rounded(cover(Image.open(ASSETS[cfg["secondary"]]).convert("RGB"), int(w * 0.30), int(h * 0.12)), int(w * 0.02))
    canvas.alpha_composite(mini, (int(w * 0.08), int(h * 0.66)))
    return canvas


def layout_left_copy_right_device(size: tuple[int, int], cfg: dict) -> Image.Image:
    w, h = size
    canvas = Image.new("RGBA", (w, h), (6, 8, 12, 255))
    d = ImageDraw.Draw(canvas)

    # Clear top safe area for copy readability
    d.rectangle((0, 0, w, int(h * 0.34)), fill=(6, 8, 12, 255))
    draw_copy(d, w, h, cfg, int(w * 0.08), int(h * 0.06), int(w * 0.50))

    # Two high-contrast white cards for "breathing room"
    gap = int(w * 0.03)
    x0 = int(w * 0.06)
    cw = int((w - x0 * 2 - gap) / 2)
    ch = int(h * 0.64)
    y = int(h * 0.30)
    for i in range(2):
        x = x0 + i * (cw + gap)
        card = Image.new("RGBA", (cw, ch), (229, 231, 235, 255))
        card = rounded(card, int(w * 0.042))
        canvas.alpha_composite(shadow_box((cw, ch), int(w * 0.042), 120), (x, y + int(h * 0.01)))
        canvas.alpha_composite(card, (x, y))

    titles = [cfg["title"], "タップだけの\nシンプル設計"]
    subs = [cfg["sub"], "必要な機能にすぐ届く"]
    imgs = [cfg["main"], cfg["secondary"]]
    for i in range(2):
        x = x0 + i * (cw + gap)
        cd = ImageDraw.Draw(canvas)
        tf = fit_font(titles[i], FONT_HEAVY, int(w * 0.053), int(w * 0.040), int(cw * 0.84), int(ch * 0.12), spacing=6)
        sf = fit_font(subs[i], FONT_REG, int(w * 0.025), int(w * 0.020), int(cw * 0.84), int(ch * 0.05))
        cd.multiline_text((x + int(cw * 0.08), y + int(ch * 0.10)), titles[i], font=tf, fill=(45, 48, 54, 255), spacing=6)
        cd.text((x + int(cw * 0.08), y + int(ch * 0.28)), subs[i], font=sf, fill=(106, 111, 119, 255))
        ph = make_phone(Image.open(ASSETS[imgs[i]]).convert("RGB"), int(cw * 0.82), int(cw * 0.82 * 2.02))
        ang = -9 if i == 0 else 8
        ph = ph.rotate(ang, expand=True, resample=Image.Resampling.BICUBIC)
        canvas.alpha_composite(ph, (x + int(cw * 0.10), y + int(ch * 0.54)))
    return canvas


def layout_light_card(size: tuple[int, int], cfg: dict) -> Image.Image:
    w, h = size
    canvas = textured_bg(w, h, cfg["secondary"], tint=(8, 10, 14, 190))
    d = ImageDraw.Draw(canvas)

    # Centered copy for quick scanning
    center_y = int(h * 0.06)
    f_brand = ImageFont.truetype(FONT_BOLD, int(w * 0.034))
    f_kicker = ImageFont.truetype(FONT_BOLD, int(w * 0.022))
    f_title = fit_font(cfg["title"], FONT_HEAVY, int(w * 0.085), int(w * 0.058), int(w * 0.66), int(h * 0.11), spacing=8)
    f_sub = fit_font(cfg["sub"], FONT_REG, int(w * 0.032), int(w * 0.025), int(w * 0.78), int(h * 0.05))
    d.text((int(w * 0.08), center_y), "Stoic", font=f_brand, fill=(245, 246, 250, 255))
    d.text((int(w * 0.08), center_y + int(h * 0.045)), cfg["kicker"], font=f_kicker, fill=(184, 190, 200, 255))
    d.multiline_text((int(w * 0.08), center_y + int(h * 0.08)), cfg["title"], font=f_title, fill=(252, 252, 255, 255), spacing=8)
    d.text((int(w * 0.08), center_y + int(h * 0.19)), cfg["sub"], font=f_sub, fill=(190, 195, 203, 255))

    # One light "window" with widget as hero object
    card_w = int(w * 0.70)
    card_h = int(h * 0.48)
    card_x = int((w - card_w) / 2)
    card_y = int(h * 0.35)
    light = Image.new("RGBA", (card_w, card_h), (233, 235, 239, 255))
    light = rounded(light, int(w * 0.04))
    canvas.alpha_composite(shadow_box((card_w, card_h), int(w * 0.04), 120), (card_x, card_y + int(h * 0.01)))
    canvas.alpha_composite(light, (card_x, card_y))

    widget = cover(Image.open(ASSETS[cfg["main"]]).convert("RGB"), int(card_w * 0.82), int(card_h * 0.42))
    widget = rounded(widget, int(w * 0.02))
    wx = card_x + int(card_w * 0.09)
    wy = card_y + int(card_h * 0.16)
    canvas.alpha_composite(widget, (wx, wy))

    chip = Image.new("RGBA", (int(card_w * 0.34), int(card_h * 0.12)), (247, 248, 251, 250))
    chip = rounded(chip, chip.height // 2)
    cd = ImageDraw.Draw(chip)
    cd.text((int(chip.width * 0.26), int(chip.height * 0.28)), "WIDGET", font=ImageFont.truetype(FONT_BOLD, int(w * 0.023)), fill=(48, 51, 57, 255))
    canvas.alpha_composite(chip, (card_x + int(card_w * 0.57), card_y + int(card_h * 0.44)))
    return canvas


def layout_library(size: tuple[int, int], cfg: dict) -> Image.Image:
    w, h = size
    canvas = textured_bg(w, h, cfg["main"])
    d = ImageDraw.Draw(canvas)
    draw_copy(d, w, h, cfg, int(w * 0.08), int(h * 0.06), int(w * 0.54))

    main_phone = make_phone(Image.open(ASSETS[cfg["main"]]).convert("RGB"), int(w * 0.48), int(h * 0.70))
    main_phone = main_phone.rotate(-7, expand=True, resample=Image.Resampling.BICUBIC)
    canvas.alpha_composite(main_phone, (int(w * -0.01), int(h * 0.40)))

    panel_w = int(w * 0.44)
    panel_h = int(h * 0.17)
    panel = Image.new("RGBA", (panel_w, panel_h), (19, 24, 33, 220))
    panel = rounded(panel, int(w * 0.024))
    pd = ImageDraw.Draw(panel)
    p_title = fit_font("再訪しやすい\n保存一覧", FONT_BOLD, int(w * 0.040), int(w * 0.030), int(panel_w * 0.80), int(panel_h * 0.52), spacing=6)
    p_sub = fit_font("必要な言葉にすぐ戻れる", FONT_REG, int(w * 0.022), int(w * 0.018), int(panel_w * 0.80), int(panel_h * 0.16))
    pd.multiline_text((int(panel_w * 0.09), int(panel_h * 0.18)), "再訪しやすい\n保存一覧", font=p_title, fill=(240, 242, 248, 255), spacing=6)
    pd.text((int(panel_w * 0.09), int(panel_h * 0.68)), "必要な言葉にすぐ戻れる", font=p_sub, fill=(164, 170, 184, 255))
    canvas.alpha_composite(panel, (int(w * 0.49), int(h * 0.46)))

    t1 = rounded(cover(Image.open(ASSETS[cfg["secondary"]]).convert("RGB"), int(w * 0.20), int(h * 0.14)), int(w * 0.020))
    t2 = rounded(cover(Image.open(ASSETS["home"]).convert("RGB"), int(w * 0.20), int(h * 0.14)), int(w * 0.020))
    canvas.alpha_composite(t1, (int(w * 0.49), int(h * 0.68)))
    canvas.alpha_composite(t2, (int(w * 0.72), int(h * 0.68)))
    return canvas


def layout_share_stage(size: tuple[int, int], cfg: dict) -> Image.Image:
    w, h = size
    canvas = textured_bg(w, h, cfg["main"], tint=(9, 11, 15, 170))
    d = ImageDraw.Draw(canvas)
    draw_copy(d, w, h, cfg, int(w * 0.08), int(h * 0.06), int(w * 0.52))

    beam = Image.new("RGBA", (int(w * 0.88), int(h * 0.16)), (148, 132, 105, 215))
    beam = beam.filter(ImageFilter.GaussianBlur(radius=24)).rotate(-18, expand=True, resample=Image.Resampling.BICUBIC)
    canvas.alpha_composite(beam, (int(w * 0.20), int(h * 0.52)))

    phone = make_phone(Image.open(ASSETS[cfg["main"]]).convert("RGB"), int(w * 0.60), int(h * 0.78))
    phone = phone.rotate(8, expand=True, resample=Image.Resampling.BICUBIC)
    canvas.alpha_composite(phone, (int(w * 0.40), int(h * 0.32)))

    # Action chips to visualize sharing flow
    for i, label in enumerate(["保存", "Instagram", "X"]):
        chip = Image.new("RGBA", (int(w * 0.22), int(h * 0.058)), (240, 242, 247, 245))
        chip = rounded(chip, chip.height // 2)
        cd = ImageDraw.Draw(chip)
        tf = fit_font(label, FONT_BOLD, int(w * 0.023), int(w * 0.019), int(chip.width * 0.75), int(chip.height * 0.6))
        tx = int((chip.width - cd.textlength(label, font=tf)) / 2)
        cd.text((tx, int(chip.height * 0.27)), label, font=tf, fill=(37, 41, 49, 255))
        canvas.alpha_composite(chip, (int(w * 0.07) + i * int(w * 0.24), int(h * 0.70)))

    mini = rounded(cover(Image.open(ASSETS[cfg["secondary"]]).convert("RGB"), int(w * 0.30), int(h * 0.11)), int(w * 0.018))
    canvas.alpha_composite(mini, (int(w * 0.08), int(h * 0.63)))
    return canvas


def render_slide(size: tuple[int, int], cfg: dict) -> Image.Image:
    layout = cfg["layout"]
    if layout == "hero":
        return layout_hero(size, cfg)
    if layout == "left_copy_right_device":
        return layout_left_copy_right_device(size, cfg)
    if layout == "light_card":
        return layout_light_card(size, cfg)
    if layout == "library":
        return layout_library(size, cfg)
    if layout == "share_stage":
        return layout_share_stage(size, cfg)
    return layout_hero(size, cfg)


def main() -> None:
    targets = [("6.5", (1284, 2778)), ("6.7", (1290, 2796))]
    for label, size in targets:
        for cfg in SLIDES:
            img = render_slide(size, cfg)
            out = OUT / label / cfg["file"]
            out.parent.mkdir(parents=True, exist_ok=True)
            img.convert("RGB").save(out, "PNG", optimize=True)
    print(f"Generated: {OUT}")


if __name__ == "__main__":
    main()
