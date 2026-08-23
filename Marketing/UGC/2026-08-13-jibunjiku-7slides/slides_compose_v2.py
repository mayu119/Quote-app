# Words For Me UGC v2 compositor — design-spec.md 準拠
# 写真(文字なし)に、ヒラギノ明朝W6/角ゴW3で統一タイポグラフィを合成する。
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance, ImageChops

BATCH = "/Users/mac2-mayu/Quote-app/Marketing/UGC/2026-08-13-jibunjiku-7slides"
W, H = 1080, 1920
MARGIN_X = 84
CREAM = (255, 248, 242, 255)      # #FFF8F2
CHARCOAL = (47, 39, 48, 255)      # #2F2730
ROSE = (234, 163, 161, 255)       # #EAA3A1
PANEL = (248, 243, 239)           # #F8F3EF

MINCHO = "/System/Library/Fonts/ヒラギノ明朝 ProN.ttc"   # index0=W3, index2=W6
GOTHIC_W3 = "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc"

def font(kind, size):
    if kind == "title": return ImageFont.truetype(MINCHO, size, index=2)
    if kind == "num":   return ImageFont.truetype(MINCHO, size, index=0)
    return ImageFont.truetype(GOTHIC_W3, size)

def grade(img):
    img = ImageEnhance.Color(img.convert("RGB")).enhance(0.88)
    rose = Image.new("RGB", img.size, (234, 163, 161))
    return Image.blend(img, rose, 0.055).convert("RGBA")

def v_gradient(width, height, alpha_top, alpha_bottom):
    col = np.linspace(alpha_top, alpha_bottom, height).astype(np.uint8)
    a = np.tile(col[:, None], (1, width))
    g = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    g.putalpha(Image.fromarray(a, "L"))
    return g

def apply_scrims(base, top=True, bottom=True):
    base = Image.alpha_composite(base, Image.new("RGBA", (W, H), (0, 0, 0, 20)))
    if top:
        base.alpha_composite(v_gradient(W, 420, 90, 0), (0, 0))
    if bottom:
        base.alpha_composite(v_gradient(W, 640, 0, 128), (0, H - 640))
    return base

def text_len(draw, s, f, tracking=0):
    return draw.textlength(s, font=f) + max(0, len(s) - 1) * tracking

def fit_size(draw, s, kind, size, max_w, tracking=0):
    while size > 24 and text_len(draw, s, font(kind, size), tracking) > max_w:
        size -= 2
    return size

def draw_tracked(layer, xy, s, f, fill, tracking=0):
    d = ImageDraw.Draw(layer)
    x, y = xy
    for ch in s:
        d.text((x, y), ch, font=f, fill=fill)
        x += d.textlength(ch, font=f) + tracking

def soft_text(base, items, shadow=True):
    """items: list of (x_or_'center', y, text, kind, size, fill, tracking)"""
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    meas = ImageDraw.Draw(layer)
    resolved = []
    for x, y, s, kind, size, fill, tr in items:
        size = fit_size(meas, s, kind, size, W - 2 * MARGIN_X, tr)
        f = font(kind, size)
        if x == "center":
            x = (W - text_len(meas, s, f, tr)) / 2
        resolved.append((x, y, s, f, fill, tr))
    if shadow:
        sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        for x, y, s, f, fill, tr in resolved:
            draw_tracked(sh, (x, y + 3), s, f, (0, 0, 0, 110), tr)
        base.alpha_composite(sh.filter(ImageFilter.GaussianBlur(5)))
    for x, y, s, f, fill, tr in resolved:
        draw_tracked(layer, (x, y), s, f, fill, tr)
    base.alpha_composite(layer)
    return base

def habit_slide(photo, out, num, title_lines, body_lines):
    base = apply_scrims(grade(Image.open(photo).resize((W, H), Image.Resampling.LANCZOS)))
    items = [(MARGIN_X, 148, num, "num", 44, ROSE, 6)]
    y = 225
    for ln in title_lines:
        items.append((MARGIN_X, y, ln, "title", 76, CREAM, 5))
        y += int(76 * 1.42)
    n = len(body_lines)
    adv = int(38 * 1.7)
    y = H - 130 - n * adv
    for ln in body_lines:
        items.append((MARGIN_X, y, ln, "body", 38, CREAM, 1))
        y += adv
    soft_text(base, items).convert("RGB").save(out, "PNG", optimize=True)
    print("saved", out)

def cover_slide(photo, out, title_lines, note):
    base = grade(Image.open(photo).resize((W, H), Image.Resampling.LANCZOS))
    base = apply_scrims(base, top=False, bottom=True)
    base.alpha_composite(v_gradient(W, 900, 0, 70), (0, 700))
    items = []
    y = 1080
    for ln in title_lines:
        items.append(("center", y, ln, "title", 88, CREAM, 6))
        y += int(88 * 1.45)
    items.append(("center", 1730, note, "body", 34, CREAM, 2))
    soft_text(base, items).convert("RGB").save(out, "PNG", optimize=True)
    print("saved", out)

def recap_slide(photo, out, heading, rows):
    base = grade(Image.open(photo).resize((W, H), Image.Resampling.LANCZOS))
    panel = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(panel).rounded_rectangle((72, 260, 1008, 1730), radius=40,
                                            fill=PANEL + (217,))
    base.alpha_composite(panel.filter(ImageFilter.GaussianBlur(1)))
    items = [("center", 330, heading, "title", 64, CHARCOAL, 10)]
    y = 520
    for num, txt in rows:
        items.append((132, y, num, "num", 54, ROSE, 4))
        items.append((246, y + 12, txt, "body", 38, CHARCOAL, 0))
        y += 240
    layer_items = []
    meas = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    for x, yy, s, kind, size, fill, tr in items:
        max_w = 1008 - 40 - (x if x != "center" else 72)
        size = fit_size(meas, s, kind, size, max_w if x != "center" else W - 260, tr)
        layer_items.append((x, yy, s, kind, size, fill, tr))
    soft_text(base, layer_items, shadow=False).convert("RGB").save(out, "PNG", optimize=True)
    print("saved", out)

def wfm_slide(photo, screenshot, out, num, title_lines, body_lines):
    base = grade(Image.open(photo).resize((W, H), Image.Resampling.LANCZOS))
    base = apply_scrims(base)
    # 実スクショを画面領域へ透視変換で合成（UI無改変）
    screen = Image.open(screenshot).convert("RGBA")
    sw, sh = screen.size
    quad = [(615, 730), (860, 740), (820, 1285), (550, 1268)]
    src = [(0, 0), (sw, 0), (sw, sh), (0, sh)]
    a, b = [], []
    for (x, y), (u, v) in zip(quad, src):
        a += [[x, y, 1, 0, 0, 0, -u * x, -u * y], [0, 0, 0, x, y, 1, -v * x, -v * y]]
        b += [u, v]
    coeffs = np.linalg.solve(np.asarray(a, float), np.asarray(b, float)).tolist()
    warped = screen.transform((W, H), Image.Transform.PERSPECTIVE, coeffs,
                              resample=Image.Resampling.BICUBIC, fillcolor=(0, 0, 0, 0))
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).polygon(quad, fill=255)
    warped.putalpha(ImageChops.multiply(warped.getchannel("A"), mask))
    base.alpha_composite(warped)
    items = [(MARGIN_X, 148, num, "num", 44, ROSE, 6)]
    y = 225
    for ln in title_lines:
        items.append((MARGIN_X, y, ln, "title", 76, CREAM, 5))
        y += int(76 * 1.42)
    n = len(body_lines)
    adv = int(38 * 1.7)
    y = H - 130 - n * adv
    for ln in body_lines:
        items.append((MARGIN_X, y, ln, "body", 38, CREAM, 1))
        y += adv
    soft_text(base, items).convert("RGB").save(out, "PNG", optimize=True)
    print("saved", out)

P = f"{BATCH}/photos"
cover_slide(f"{P}/p01-cover.png", f"{BATCH}/01-cover.png",
            ["自分軸がある人が", "毎日やってること", "5選"], "※全部できてる日の方が少ない")
habit_slide(f"{P}/p02-coffee.png", f"{BATCH}/02-habit1.png", "01",
            ["朝いちのスマホで、", "SNSを開かない"],
            ["起きて30秒で他人の朝を見ると、", "その日の基準が人になる。通知は朝ごはんの", "後って決めただけで、朝がだいぶ静かになった。"])
habit_slide(f"{P}/p03-planner.png", f"{BATCH}/03-habit2.png", "02",
            ["人の予定より先に、", "自分の予定を入れる"],
            ["先に空白を自分の用事で埋める。", "散歩でもカフェでもいい。先約は私、にする。"])
habit_slide(f"{P}/p04-nightdesk.png", f"{BATCH}/04-habit3.png", "03",
            ["違和感を、その日の", "うちにメモに残す"],
            ["なんかモヤっとした、だけでいい。", "あとで読み返すと、自分が我慢しやすい", "場面が見えてくる。"])
habit_slide(f"{P}/p05-nighttable.png", f"{BATCH}/05-habit4.png", "04",
            ["即答できない誘いは、", "一晩置いて返事する"],
            ["その場で返すと、だいたい相手に合わせてる。", "一晩置いて、行きたいかどうかだけで決める。"])
wfm_slide(f"{P}/p06-bedphone.png", "/Users/mac2-mayu/Quote-app/スクショ/アプリスクショ/ホーム画面.png",
          f"{BATCH}/06-habit5-wfm.png", "05",
          ["夜、SNSの代わりに", "言葉を一枚だけ読む"],
          ["スクロールで終わる夜をやめたくて、", "寝る前は一枚だけ読んで閉じることにしてる。", "私はWords For Meってアプリでやってる。"])
recap_slide(f"{P}/p07-recap.png", f"{BATCH}/07-recap.png", "まとめ",
            [("01", "朝いちのスマホで、SNSを開かない"),
             ("02", "人の予定より先に、自分の予定を入れる"),
             ("03", "違和感を、その日のうちにメモに残す"),
             ("04", "即答できない誘いは、一晩置いて返事する"),
             ("05", "夜、SNSの代わりに言葉を一枚だけ読む")])
