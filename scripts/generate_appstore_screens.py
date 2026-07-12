#!/usr/bin/env python3
from __future__ import annotations

import shutil
import unicodedata
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

ROOT = Path("/Users/hayashimasaki/Downloads/名言アプリ")
SRC_DIR = ROOT / "スクショ"
APP_SRC_DIR = SRC_DIR / "アプリスクショ"
OUT_BASE = ROOT / "screenshots" / "final"
FASTLANE_SCREENSHOTS = ROOT / "QuoteApp" / "fastlane" / "screenshots" / "ja"

FONT_REG = "/System/Library/Fonts/ヒラギノ角ゴシック W4.ttc"
FONT_BOLD = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
FONT_HEAVY = "/System/Library/Fonts/ヒラギノ角ゴシック W7.ttc"


def normalize(value: str) -> str:
    return unicodedata.normalize("NFKC", value).lower()


def find_source(*keywords: str) -> Path:
    files = [p for base in (APP_SRC_DIR, SRC_DIR) for p in base.iterdir() if p.is_file()]
    for keyword in keywords:
        key = normalize(keyword)
        for path in files:
            if key in normalize(path.name):
                return path
    raise FileNotFoundError(f"source not found: {keywords}")


SOURCES = {
    "home": find_source("ホーム画面"),
    "favorites": find_source("favorites", "お気に入り"),
    "memo": find_source("memo", "お気に入り理由メモ"),
    "widget": find_source("widget", "ウィジェット"),
    "share": find_source("共有", "share"),
}


SLIDES = [
    {
        "file": "01-save.jpg",
        "kicker": "SAVE",
        "headline": "響いた言葉を、\nその日の自分に残す",
        "sub": "読むだけで終わらせず、心に残った一節をすぐ保存。",
        "source": "home",
        "accent": "#D96E83",
        "badge": "左スワイプで保存",
    },
    {
        "file": "02-calendar.jpg",
        "kicker": "CALENDAR",
        "headline": "保存した言葉を、\n日付ごとに見返せる",
        "sub": "どんな日に、どんな言葉が支えになったか振り返れます。",
        "source": "favorites",
        "accent": "#A86DE0",
        "calendar": True,
    },
    {
        "file": "03-note.jpg",
        "kicker": "REFLECT",
        "headline": "自分の言葉として、\nメモに残す",
        "sub": "なぜ響いたのかを書き添えて、自己理解の記録に。",
        "source": "memo",
        "accent": "#E08A61",
        "badge": "保存 + メモ",
    },
    {
        "file": "04-widget.jpg",
        "kicker": "WIDGET",
        "headline": "毎日ひとつ、\n自然に続く",
        "sub": "通知とウィジェットで、言葉に触れる習慣をつくれます。",
        "source": "widget",
        "accent": "#69A9A4",
        "badge": "ホーム画面対応",
    },
    {
        "file": "05-share.jpg",
        "kicker": "SHARE",
        "headline": "大切な一言を、\n美しくシェア",
        "sub": "背景つきの画像として、SNSやメッセージで共有できます。",
        "source": "share",
        "accent": "#9B7FD3",
        "badge": "画像で共有",
    },
]


def cover_resize(img: Image.Image, width: int, height: int) -> Image.Image:
    sw, sh = img.size
    scale = max(width / sw, height / sh)
    resized = img.resize((int(sw * scale), int(sh * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - width) // 2
    top = (resized.height - height) // 2
    return resized.crop((left, top, left + width, top + height))


def fit_resize(img: Image.Image, width: int, height: int) -> Image.Image:
    img.thumbnail((width, height), Image.Resampling.LANCZOS)
    return img


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def rounded(img: Image.Image, radius: int) -> Image.Image:
    out = img.convert("RGBA")
    out.putalpha(rounded_mask(out.size, radius))
    return out


def draw_background(width: int, height: int, accent: str) -> Image.Image:
    base = Image.new("RGB", (width, height), "#FBF5F2")
    draw = ImageDraw.Draw(base)
    for y in range(height):
        t = y / height
        r = int(251 * (1 - t) + 241 * t)
        g = int(245 * (1 - t) + 234 * t)
        b = int(242 * (1 - t) + 246 * t)
        draw.line((0, y, width, y), fill=(r, g, b))

    glow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    rgb = tuple(int(accent[i : i + 2], 16) for i in (1, 3, 5))
    gd.ellipse((-width // 4, height // 7, width // 2, height // 2), fill=(*rgb, 34))
    gd.ellipse((width // 2, -height // 6, width + width // 4, height // 3), fill=(*rgb, 28))
    glow = glow.filter(ImageFilter.GaussianBlur(width // 10))
    return Image.alpha_composite(base.convert("RGBA"), glow)


def add_phone(canvas: Image.Image, source: Path, box: tuple[int, int, int, int], rotate: float = 0) -> None:
    x, y, width, height = box
    screen = cover_resize(Image.open(source).convert("RGB"), width, height)
    screen = ImageEnhance.Contrast(screen).enhance(1.03)
    screen = rounded(screen, max(28, width // 13))

    phone = Image.new("RGBA", (width + 28, height + 28), (0, 0, 0, 0))
    pd = ImageDraw.Draw(phone)
    pd.rounded_rectangle((0, 0, phone.width, phone.height), radius=width // 11, fill=(34, 31, 33, 255))
    phone.alpha_composite(screen, (14, 14))

    if rotate:
        phone = phone.rotate(rotate, expand=True, resample=Image.Resampling.BICUBIC)

    shadow = Image.new("RGBA", phone.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((0, 0, phone.width, phone.height), radius=width // 10, fill=(56, 28, 40, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(width // 12))
    canvas.alpha_composite(shadow, (x - 16, y + 30))
    canvas.alpha_composite(phone, (x, y))


def draw_calendar_card(canvas: Image.Image, x: int, y: int, width: int, height: int, accent: str) -> None:
    card = Image.new("RGBA", (width, height), (255, 255, 255, 225))
    draw = ImageDraw.Draw(card)
    radius = width // 13
    draw.rounded_rectangle((0, 0, width, height), radius=radius, fill=(255, 255, 255, 235))
    draw.rounded_rectangle((0, 0, width, height), radius=radius, outline=(255, 255, 255, 255), width=2)

    ink = (76, 55, 62)
    muted = (132, 111, 119)
    rgb = tuple(int(accent[i : i + 2], 16) for i in (1, 3, 5))
    f_month = ImageFont.truetype(FONT_HEAVY, width // 13)
    f_day = ImageFont.truetype(FONT_BOLD, width // 24)
    f_body = ImageFont.truetype(FONT_REG, width // 26)
    f_quote = ImageFont.truetype(FONT_BOLD, width // 23)

    draw.text((width * 0.09, height * 0.08), "April 2026", font=f_month, fill=ink)
    weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    cell_w = width * 0.82 / 7
    start_x = width * 0.09
    grid_y = height * 0.23
    for i, label in enumerate(weekdays):
        draw.text((start_x + cell_w * i + cell_w * 0.28, grid_y), label, font=f_day, fill=muted)

    day = 1
    marked = {3, 8, 12, 18, 22}
    selected = 18
    for row in range(5):
        for col in range(7):
            cx = start_x + cell_w * col + cell_w * 0.5
            cy = grid_y + 54 + row * (height * 0.105)
            if day <= 30:
                if day == selected:
                    draw.ellipse((cx - 23, cy - 23, cx + 23, cy + 23), fill=(*rgb, 235))
                    fill = (255, 255, 255)
                else:
                    fill = ink
                draw.text((cx - 9, cy - 14), str(day), font=f_day, fill=fill)
                if day in marked and day != selected:
                    draw.ellipse((cx - 4, cy + 20, cx + 4, cy + 28), fill=(*rgb, 210))
                day += 1

    note_y = int(height * 0.78)
    draw.rounded_rectangle((width * 0.08, note_y, width * 0.92, height * 0.93), radius=22, fill=(*rgb, 28))
    draw.text((width * 0.12, note_y + 20), "4月18日に残した言葉", font=f_body, fill=muted)
    draw.text((width * 0.12, note_y + 58), "私の歩幅で進んでいい。", font=f_quote, fill=ink)

    shadow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((0, 0, width, height), radius=radius, fill=(90, 45, 64, 46))
    shadow = shadow.filter(ImageFilter.GaussianBlur(width // 13))
    canvas.alpha_composite(shadow, (x, y + 26))
    canvas.alpha_composite(card, (x, y))


def render_slide(size: tuple[int, int], cfg: dict, out: Path) -> None:
    width, height = size
    accent = cfg["accent"]
    canvas = draw_background(width, height, accent)
    draw = ImageDraw.Draw(canvas)

    pad_x = int(width * 0.072)
    kicker_y = int(height * 0.07)
    headline_y = int(height * 0.115)
    sub_y = int(height * 0.265)

    f_kicker = ImageFont.truetype(FONT_BOLD, int(width * 0.032))
    f_headline = ImageFont.truetype(FONT_HEAVY, int(width * 0.062))
    f_sub = ImageFont.truetype(FONT_REG, int(width * 0.030))
    f_badge = ImageFont.truetype(FONT_BOLD, int(width * 0.026))

    ink = (63, 46, 54, 255)
    muted = (112, 93, 102, 255)
    rgb = tuple(int(accent[i : i + 2], 16) for i in (1, 3, 5))

    draw.text((pad_x, kicker_y), cfg["kicker"], font=f_kicker, fill=(*rgb, 255))
    draw.multiline_text(
        (pad_x, headline_y),
        cfg["headline"],
        font=f_headline,
        fill=ink,
        spacing=int(width * 0.012),
    )
    draw.text((pad_x, sub_y), cfg["sub"], font=f_sub, fill=muted)

    if cfg.get("badge"):
        badge_text = cfg["badge"]
        text_w = draw.textlength(badge_text, font=f_badge)
        bx, by = pad_x, int(height * 0.325)
        bw, bh = int(text_w + width * 0.08), int(width * 0.07)
        draw.rounded_rectangle((bx, by, bx + bw, by + bh), radius=bh // 2, fill=(*rgb, 235))
        draw.text((bx + width * 0.04, by + bh * 0.25), badge_text, font=f_badge, fill=(255, 255, 255, 255))

    if cfg.get("calendar"):
        draw_calendar_card(
            canvas,
            int(width * 0.10),
            int(height * 0.43),
            int(width * 0.80),
            int(height * 0.42),
            accent,
        )
        add_phone(
            canvas,
            SOURCES[cfg["source"]],
            (int(width * 0.66), int(height * 0.52), int(width * 0.23), int(height * 0.29)),
            rotate=5,
        )
    else:
        phone_w = int(width * 0.52)
        phone_h = int(height * 0.58)
        add_phone(
            canvas,
            SOURCES[cfg["source"]],
            (int(width * 0.24), int(height * 0.38), phone_w, phone_h),
            rotate=-3 if cfg["file"] in {"01-save.jpg", "03-note.jpg"} else 2,
        )

    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out, "JPEG", quality=94, optimize=True)


def sync_to_fastlane() -> None:
    if FASTLANE_SCREENSHOTS.exists():
        shutil.rmtree(FASTLANE_SCREENSHOTS)
    FASTLANE_SCREENSHOTS.mkdir(parents=True, exist_ok=True)

    slide_files = {slide["file"] for slide in SLIDES}
    for device_dir in OUT_BASE.iterdir():
        if not device_dir.is_dir():
            continue
        for screenshot in sorted(device_dir.glob("*.jpg")):
            if screenshot.name not in slide_files:
                continue
            target = FASTLANE_SCREENSHOTS / f"{device_dir.name}-{screenshot.name}"
            shutil.copy2(screenshot, target)


def main() -> None:
    sizes = {
        "iphone_6.5_inch_1242x2688": (1242, 2688),
        "iphone_6.7_inch_1284x2778": (1284, 2778),
        "iphone_6.7_inch_1290x2796": (1290, 2796),
    }
    for label, size in sizes.items():
        out_dir = OUT_BASE / label
        if out_dir.exists():
            shutil.rmtree(out_dir)
        for slide in SLIDES:
            render_slide(size, slide, out_dir / slide["file"])
    sync_to_fastlane()
    print(f"Generated screenshots in: {OUT_BASE}")
    print(f"Synced fastlane screenshots to: {FASTLANE_SCREENSHOTS}")


if __name__ == "__main__":
    main()
