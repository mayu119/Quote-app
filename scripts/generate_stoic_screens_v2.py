#!/usr/bin/env python3
from __future__ import annotations

import unicodedata
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

ROOT = Path("/Users/hayashimasaki/Downloads/名言アプリ")
SRC = ROOT / "スクショ"
OUT = SRC / "審査用_Stoic_20260227"

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
        "layout": "hero_right",
        "accent": (78, 102, 145, 255),
        "kicker": "DAILY RESET",
        "title": "毎日を、\nひとつ整える",
        "sub": "続けることに、無理はいらない。",
        "main": "home",
        "secondary": "home2",
        "angle": -10,
    },
    {
        "file": "02_focus.png",
        "layout": "split_cards",
        "accent": (204, 198, 186, 255),
        "kicker": "FOCUS",
        "title": "考え込まず、\n次の一歩へ",
        "sub": "短い言葉が、行動に切り替える。",
        "main": "home2",
        "secondary": "home",
        "angle": 8,
    },
    {
        "file": "03_widget.png",
        "layout": "spotlight",
        "accent": (171, 145, 98, 255),
        "kicker": "WIDGET",
        "title": "ホーム画面で\n自然に継続",
        "sub": "思い出す負担を減らし、習慣を守る。",
        "main": "widget",
        "secondary": "home",
        "angle": -4,
    },
    {
        "file": "04_favorite.png",
        "layout": "archive_grid",
        "accent": (109, 132, 143, 255),
        "kicker": "FAVORITES",
        "title": "刺さった言葉を\n保存して再訪",
        "sub": "必要な時に、すぐ読み返せる。",
        "main": "favorite",
        "secondary": "home2",
        "angle": -9,
    },
    {
        "file": "05_share.png",
        "layout": "share_stage",
        "accent": (142, 126, 102, 255),
        "kicker": "SHARE",
        "title": "想いを、\n美しく届ける",
        "sub": "画像でそのまま、静かに共有。",
        "main": "share",
        "secondary": "home",
        "angle": 9,
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


def make_background(w: int, h: int, source_key: str) -> Image.Image:
    bg = cover(Image.open(ASSETS[source_key]).convert("RGB"), w, h)
    bg = bg.filter(ImageFilter.GaussianBlur(radius=18))
    bg = ImageEnhance.Brightness(bg).enhance(0.35)
    bg = ImageEnhance.Contrast(bg).enhance(1.15)

    # Dark cinematic tint
    tint = Image.new("RGBA", (w, h), (8, 10, 14, 180))
    bg = Image.alpha_composite(bg.convert("RGBA"), tint)

    grad = Image.new("L", (1, h))
    for y in range(h):
        alpha = int(220 - (140 * y / h))
        grad.putpixel((0, y), max(70, min(255, alpha)))
    grad = grad.resize((w, h))
    top = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    top.putalpha(grad)
    return Image.alpha_composite(bg, top)


def dark_gradient(w: int, h: int, top=(7, 9, 13), bottom=(6, 7, 10)) -> Image.Image:
    img = Image.new("RGB", (w, h), top)
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(1, h - 1)
        r = int(top[0] * (1 - t) + bottom[0] * t)
        g = int(top[1] * (1 - t) + bottom[1] * t)
        b = int(top[2] * (1 - t) + bottom[2] * t)
        d.line((0, y, w, y), fill=(r, g, b))
    return img.convert("RGBA")


def draw_branding(draw: ImageDraw.ImageDraw, w: int, h: int, cfg: dict, x: int, y: int) -> None:
    f_brand = ImageFont.truetype(FONT_BOLD, int(w * 0.034))
    f_kicker = ImageFont.truetype(FONT_BOLD, int(w * 0.022))
    f_title = ImageFont.truetype(FONT_HEAVY, int(w * 0.072))
    f_sub = ImageFont.truetype(FONT_REG, int(w * 0.033))
    draw.text((x, y), "Stoic", font=f_brand, fill=(245, 246, 250, 255))
    draw.text((x, y + int(h * 0.045)), cfg["kicker"], font=f_kicker, fill=(186, 192, 204, 255))
    draw.multiline_text((x, y + int(h * 0.08)), cfg["title"], font=f_title, fill=(250, 250, 252, 255), spacing=int(w * 0.012))
    draw.text((x, y + int(h * 0.20)), cfg["sub"], font=f_sub, fill=(184, 188, 196, 255))


def draw_center_block(draw: ImageDraw.ImageDraw, w: int, h: int, cfg: dict, y: int) -> None:
    f_kicker = ImageFont.truetype(FONT_BOLD, int(w * 0.022))
    f_title = ImageFont.truetype(FONT_HEAVY, int(w * 0.068))
    f_sub = ImageFont.truetype(FONT_REG, int(w * 0.031))

    def centered_text(ty: int, text: str, font: ImageFont.FreeTypeFont, fill):
        box = draw.multiline_textbbox((0, 0), text, font=font, spacing=int(w * 0.011), align="center")
        tw = box[2] - box[0]
        draw.multiline_text(((w - tw) // 2, ty), text, font=font, fill=fill, spacing=int(w * 0.011), align="center")

    centered_text(y, "Stoic", ImageFont.truetype(FONT_BOLD, int(w * 0.034)), (245, 246, 250, 255))
    centered_text(y + int(h * 0.045), cfg["kicker"], f_kicker, (186, 192, 204, 255))
    centered_text(y + int(h * 0.08), cfg["title"], f_title, (250, 250, 252, 255))
    centered_text(y + int(h * 0.195), cfg["sub"], f_sub, (184, 188, 196, 255))


def make_phone_mock(screen: Image.Image, w: int, h: int) -> Image.Image:
    bezel = int(w * 0.03)
    body = Image.new("RGBA", (w, h), (9, 9, 11, 255))
    d = ImageDraw.Draw(body)
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius=int(w * 0.12), fill=(10, 10, 12, 255))

    screen_area = (bezel, bezel, w - bezel, h - bezel)
    sw = screen_area[2] - screen_area[0]
    sh = screen_area[3] - screen_area[1]
    inside = cover(screen.convert("RGB"), sw, sh)
    inside = rounded(inside, int(w * 0.09))
    body.alpha_composite(inside, (screen_area[0], screen_area[1]))

    # simple dynamic island
    notch_w = int(w * 0.24)
    notch_h = int(h * 0.035)
    notch_x = (w - notch_w) // 2
    notch_y = int(h * 0.04)
    d.rounded_rectangle((notch_x, notch_y, notch_x + notch_w, notch_y + notch_h), radius=notch_h // 2, fill=(0, 0, 0, 255))
    return body


def layout_hero_right(size: tuple[int, int], cfg: dict) -> Image.Image:
    w, h = size
    canvas = make_background(w, h, cfg["main"])
    d = ImageDraw.Draw(canvas)
    draw_branding(d, w, h, cfg, int(w * 0.08), int(h * 0.06))

    accent = Image.new("RGBA", (int(w * 0.62), int(h * 0.006)), cfg["accent"])
    accent = accent.filter(ImageFilter.GaussianBlur(radius=3))
    canvas.alpha_composite(accent, (int(w * 0.28), int(h * 0.51)))

    phone_w = int(w * 0.63)
    phone_h = int(phone_w * 2.08)
    phone = make_phone_mock(Image.open(ASSETS[cfg["main"]]).convert("RGB"), phone_w, phone_h)
    phone = phone.rotate(cfg["angle"], expand=True, resample=Image.Resampling.BICUBIC)
    canvas.alpha_composite(phone, (int(w * 0.43), int(h * 0.33)))

    mini = cover(Image.open(ASSETS[cfg["secondary"]]).convert("RGB"), int(w * 0.30), int(h * 0.12))
    mini = rounded(mini, int(w * 0.02))
    canvas.alpha_composite(mini, (int(w * 0.08), int(h * 0.64)))
    return canvas


def layout_split_cards(size: tuple[int, int], cfg: dict) -> Image.Image:
    w, h = size
    canvas = dark_gradient(w, h)
    d = ImageDraw.Draw(canvas)
    d.text((int(w * 0.08), int(h * 0.06)), "Stoic", font=ImageFont.truetype(FONT_BOLD, int(w * 0.033)), fill=(238, 240, 244, 255))

    gap = int(w * 0.032)
    x0 = int(w * 0.06)
    card_w = int((w - x0 * 2 - gap) / 2)
    card_h = int(h * 0.78)
    y = int(h * 0.14)
    titles = [cfg["title"], "タップするだけの\nシンプル設計"]
    subs = [cfg["sub"], "必要な機能にすぐ届く"]
    imgs = [cfg["main"], cfg["secondary"]]
    angles = [-9, 8]

    for i in range(2):
        x = x0 + i * (card_w + gap)
        card = Image.new("RGBA", (card_w, card_h), (228, 230, 234, 255))
        cd = ImageDraw.Draw(card)
        cd.rounded_rectangle((0, 0, card_w, card_h), radius=int(w * 0.045), fill=(228, 230, 234, 255))
        cd.multiline_text((int(card_w * 0.08), int(card_h * 0.12)), titles[i], font=ImageFont.truetype(FONT_HEAVY, int(w * 0.052)), fill=(43, 46, 52, 255), spacing=8)
        cd.text((int(card_w * 0.08), int(card_h * 0.30)), subs[i], font=ImageFont.truetype(FONT_REG, int(w * 0.026)), fill=(106, 110, 118, 255))
        shot = make_phone_mock(Image.open(ASSETS[imgs[i]]).convert("RGB"), int(card_w * 0.82), int(card_w * 1.68))
        shot = shot.rotate(angles[i], expand=True, resample=Image.Resampling.BICUBIC)
        card.alpha_composite(shot, (int(card_w * 0.10), int(card_h * 0.52)))
        canvas.alpha_composite(rounded(card, int(w * 0.045)), (x, y))
    return canvas


def layout_spotlight(size: tuple[int, int], cfg: dict) -> Image.Image:
    w, h = size
    canvas = make_background(w, h, cfg["main"])
    d = ImageDraw.Draw(canvas)
    draw_center_block(d, w, h, cfg, int(h * 0.05))

    halo = Image.new("RGBA", (int(w * 0.72), int(h * 0.38)), cfg["accent"])
    halo = halo.filter(ImageFilter.GaussianBlur(radius=50))
    canvas.alpha_composite(halo, (int(w * 0.14), int(h * 0.38)))

    phone_w = int(w * 0.56)
    phone_h = int(phone_w * 2.05)
    phone = make_phone_mock(Image.open(ASSETS[cfg["main"]]).convert("RGB"), phone_w, phone_h)
    canvas.alpha_composite(phone, (int((w - phone_w) / 2), int(h * 0.34)))

    chip = Image.new("RGBA", (int(w * 0.28), int(h * 0.07)), (245, 246, 248, 245))
    cd = ImageDraw.Draw(chip)
    cd.rounded_rectangle((0, 0, chip.width, chip.height), radius=int(chip.height * 0.45), fill=(245, 246, 248, 245))
    cd.text((int(chip.width * 0.22), int(chip.height * 0.30)), "WIDGET", font=ImageFont.truetype(FONT_BOLD, int(w * 0.025)), fill=(39, 42, 47, 255))
    canvas.alpha_composite(chip, (int(w * 0.61), int(h * 0.52)))
    return canvas


def layout_archive_grid(size: tuple[int, int], cfg: dict) -> Image.Image:
    w, h = size
    canvas = make_background(w, h, cfg["main"])
    d = ImageDraw.Draw(canvas)
    draw_branding(d, w, h, cfg, int(w * 0.08), int(h * 0.06))

    left_phone = make_phone_mock(Image.open(ASSETS[cfg["main"]]).convert("RGB"), int(w * 0.46), int(h * 0.69))
    left_phone = left_phone.rotate(-8, expand=True, resample=Image.Resampling.BICUBIC)
    canvas.alpha_composite(left_phone, (int(w * -0.01), int(h * 0.39)))

    panel = Image.new("RGBA", (int(w * 0.45), int(h * 0.17)), (20, 24, 31, 210))
    pd = ImageDraw.Draw(panel)
    pd.rounded_rectangle((0, 0, panel.width, panel.height), radius=int(w * 0.03), fill=(20, 24, 31, 210))
    pd.text((int(panel.width * 0.08), int(panel.height * 0.20)), "再訪しやすい\n保存一覧", font=ImageFont.truetype(FONT_BOLD, int(w * 0.038)), fill=(236, 238, 243, 255), spacing=8)
    pd.text((int(panel.width * 0.08), int(panel.height * 0.66)), "必要な言葉にすぐ戻れる", font=ImageFont.truetype(FONT_REG, int(w * 0.023)), fill=(164, 170, 182, 255))
    canvas.alpha_composite(panel, (int(w * 0.49), int(h * 0.45)))

    thumb1 = rounded(cover(Image.open(ASSETS[cfg["secondary"]]).convert("RGB"), int(w * 0.21), int(h * 0.14)), int(w * 0.022))
    thumb2 = rounded(cover(Image.open(ASSETS["home"]).convert("RGB"), int(w * 0.21), int(h * 0.14)), int(w * 0.022))
    canvas.alpha_composite(thumb1, (int(w * 0.49), int(h * 0.67)))
    canvas.alpha_composite(thumb2, (int(w * 0.73), int(h * 0.67)))
    return canvas


def layout_share_stage(size: tuple[int, int], cfg: dict) -> Image.Image:
    w, h = size
    canvas = dark_gradient(w, h, top=(6, 8, 11), bottom=(8, 10, 14))
    d = ImageDraw.Draw(canvas)
    draw_branding(d, w, h, cfg, int(w * 0.08), int(h * 0.06))

    beam = Image.new("RGBA", (int(w * 0.9), int(h * 0.18)), cfg["accent"])
    beam = beam.filter(ImageFilter.GaussianBlur(radius=28)).rotate(-20, expand=True, resample=Image.Resampling.BICUBIC)
    canvas.alpha_composite(beam, (int(w * 0.20), int(h * 0.48)))

    main_phone = make_phone_mock(Image.open(ASSETS[cfg["main"]]).convert("RGB"), int(w * 0.60), int(h * 0.78))
    main_phone = main_phone.rotate(8, expand=True, resample=Image.Resampling.BICUBIC)
    canvas.alpha_composite(main_phone, (int(w * 0.40), int(h * 0.31)))

    strip = rounded(cover(Image.open(ASSETS[cfg["secondary"]]).convert("RGB"), int(w * 0.32), int(h * 0.11)), int(w * 0.02))
    canvas.alpha_composite(strip, (int(w * 0.08), int(h * 0.66)))
    return canvas


def render_slide(size: tuple[int, int], cfg: dict, out_path: Path) -> None:
    layout = cfg["layout"]
    if layout == "hero_right":
        canvas = layout_hero_right(size, cfg)
    elif layout == "split_cards":
        canvas = layout_split_cards(size, cfg)
    elif layout == "spotlight":
        canvas = layout_spotlight(size, cfg)
    elif layout == "archive_grid":
        canvas = layout_archive_grid(size, cfg)
    elif layout == "share_stage":
        canvas = layout_share_stage(size, cfg)
    else:
        canvas = layout_hero_right(size, cfg)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out_path, "PNG", optimize=True)


def main() -> None:
    targets = [("6.5", (1284, 2778)), ("6.7", (1290, 2796))]
    for label, size in targets:
        for cfg in SLIDES:
            render_slide(size, cfg, OUT / label / cfg["file"])
    print(f"Generated: {OUT}")


if __name__ == "__main__":
    main()
