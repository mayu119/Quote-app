from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageFilter
import numpy as np

BASE = "/Users/mac2-mayu/.codex/generated_images/019fe5c8-d768-79c3-8740-9f487055bf0c/exec-b69a98aa-f425-41e2-9a10-a4340d6d1179.png"
SCREEN = "/Users/mac2-mayu/Quote-app/スクショ/アプリスクショ/ホーム画面.png"
OUT = "/Users/mac2-mayu/Quote-app/Marketing/UGC/2026-08-13-jibunjiku-7slides/06-habit5-wfm.png"

W, H = 1080, 1920

def perspective_coeffs(dst, src):
    a = []
    b = []
    for (x, y), (u, v) in zip(dst, src):
        a.append([x, y, 1, 0, 0, 0, -u*x, -u*y])
        b.append(u)
        a.append([0, 0, 0, x, y, 1, -v*x, -v*y])
        b.append(v)
    return np.linalg.solve(np.asarray(a, dtype=float), np.asarray(b, dtype=float)).tolist()

base = Image.open(BASE).convert("RGB").resize((W, H), Image.Resampling.LANCZOS)

# A restrained, soft scrim keeps the typography legible while preserving the photo.
scrim = Image.new("RGBA", (W, H), (0, 0, 0, 0))
scrim_draw = ImageDraw.Draw(scrim)
scrim_draw.rectangle((0, 0, W, H), fill=(0, 0, 0, 38))
panel = Image.new("L", (W, H), 0)
panel_draw = ImageDraw.Draw(panel)
panel_draw.rounded_rectangle((35, 225, 780, 1695), radius=42, fill=110)
panel = panel.filter(ImageFilter.GaussianBlur(38))
panel_rgba = Image.new("RGBA", (W, H), (0, 0, 0, 0))
panel_rgba.putalpha(panel)
base = Image.alpha_composite(base.convert("RGBA"), scrim)
base = Image.alpha_composite(base, panel_rgba)

# Put the literal supplied app screenshot into the phone display.
screen = Image.open(SCREEN).convert("RGBA")
sw, sh = screen.size
screen_corners = [(0, 0), (sw, 0), (sw, sh), (0, sh)]
# Display quadrilateral in the 1080x1920 canvas, matching the generated phone perspective.
phone_quad = [(615, 730), (860, 740), (820, 1285), (550, 1268)]
coeffs = perspective_coeffs(phone_quad, screen_corners)
warped = screen.transform((W, H), Image.Transform.PERSPECTIVE, coeffs,
                           resample=Image.Resampling.BICUBIC,
                           fillcolor=(0, 0, 0, 0))
mask = Image.new("L", (W, H), 0)
ImageDraw.Draw(mask).polygon(phone_quad, fill=255)
warped.putalpha(ImageChops.multiply(warped.getchannel("A"), mask))
base = Image.alpha_composite(base, warped)

font_path = "/System/Library/Fonts/Hiragino Sans GB.ttc"
font_main = ImageFont.truetype(font_path, 78)
font_body = ImageFont.truetype(font_path, 42)
font_small = ImageFont.truetype(font_path, 42)
draw = ImageDraw.Draw(base)
ink = (250, 248, 242, 255)

def draw_lines(lines, xy, font, spacing):
    x, y = xy
    for line in lines:
        draw.text((x + 2, y + 3), line, font=font, fill=(0, 0, 0, 120))
        draw.text((x, y), line, font=font, fill=ink)
        bbox = draw.textbbox((x, y), line, font=font)
        y += (bbox[3] - bbox[1]) + spacing

draw_lines(["05"], (78, 88), font_small, 0)
draw_lines(["夜、SNSの代わりに", "言葉を一枚だけ読む"], (82, 370), font_main, 18)
draw_lines([
    "スクロールで終わる夜を",
    "やめたくて、寝る前は一枚だけ",
    "読んで閉じることにしてる。",
    "私はWords For Meってアプリで",
    "やってる。",
], (82, 1255), font_body, 16)

base.convert("RGB").save(OUT, format="PNG", optimize=True)
print(f"IMAGE_SAVED: {OUT}")
