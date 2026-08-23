# Words For Me UGC v2 compositor — design-spec.md 準拠
# 写真(文字なし)に、ヒラギノ明朝W6/角ゴW3で統一タイポグラフィを合成する。
# バッチ: 2026-08-12-kirawarekowai-8slides (嫌われるのが怖い人の特徴5選・8枚構成)
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance, ImageChops

BATCH = "/Users/mac2-mayu/Quote-app/Marketing/UGC/2026-08-12-kirawarekowai-8slides"
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

def recap_slide(photo, out, heading_lines, rows):
    base = grade(Image.open(photo).resize((W, H), Image.Resampling.LANCZOS))
    panel = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(panel).rounded_rectangle((72, 260, 1008, 1730), radius=40,
                                            fill=PANEL + (217,))
    base.alpha_composite(panel.filter(ImageFilter.GaussianBlur(1)))
    items = []
    y = 330
    for ln in heading_lines:
        items.append(("center", y, ln, "title", 64, CHARCOAL, 10))
        y += int(64 * 1.35)
    y += 40
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

def wfm_slide(photo, screenshot, out, num, title_lines, body_lines, quad):
    base = grade(Image.open(photo).resize((W, H), Image.Resampling.LANCZOS))
    base = apply_scrims(base)
    # 実スクショを画面領域へ透視変換で合成（UI無改変）
    screen = Image.open(screenshot).convert("RGBA")
    sw, sh = screen.size
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

def quote_slide(photo, out, quote_lines, brand_line):
    """免罪名言の締めスライド。design-spec準拠(写真+統一スクリム、クリーム白+ローズ2色)。"""
    base = grade(Image.open(photo).resize((W, H), Image.Resampling.LANCZOS))
    base = apply_scrims(base, top=True, bottom=True)
    # 中央の文字帯だけを柔らかくぼかした単一の暗幕で沈める(帯の継ぎ目が出ないようGaussianBlurで滑らかに)
    veil = Image.new("L", (W, H), 0)
    ImageDraw.Draw(veil).rectangle((0, 620, W, 1500), fill=100)
    veil = veil.filter(ImageFilter.GaussianBlur(220))
    dark = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    dark.putalpha(veil)
    base.alpha_composite(dark)
    items = []
    y = 800
    for ln in quote_lines:
        items.append(("center", y, ln, "title", 72, CREAM, 6))
        y += int(72 * 1.55)
    y += 56
    items.append(("center", y, brand_line, "body", 32, ROSE, 6))
    soft_text(base, items).convert("RGB").save(out, "PNG", optimize=True)
    print("saved", out)

P = f"{BATCH}/photos"
F = f"{BATCH}/final"

cover_slide(f"{P}/p01-cover.png", f"{F}/01.png",
            ["嫌われるのが怖い人の", "特徴5選"], "※ぜんぶ私のことだった")

habit_slide(f"{P}/p02-daytexting.png", f"{F}/02.png", "01",
            ["送る前にLINEを3回", "読み直して、結局", "スタンプだけ送る"],
            ["変なこと言ってないよね、の確認が", "終わらない。打った文は、だいたい消してる。"])

habit_slide(f"{P}/p03-eveningwalk.png", f"{F}/03.png", "02",
            ["「全然いいよ」って言ったあと、", "ひとりで反省会してる"],
            ["言った瞬間はいいの。", "帰り道でずっと再生してる。"])

# p04-bedphone.png(再生成版・画面が下方)のスマホ画面領域(白マスク検出→1080x1920換算、3%内側にインセット)
WFM_QUAD = [(450.5, 1030.7), (593.7, 1025.9), (595.7, 1406.6), (449.4, 1403.0)]
wfm_slide(f"{P}/p04-bedphone.png",
          "/Users/mac2-mayu/Quote-app/スクショ/アプリスクショ/ホーム画面.png",
          f"{F}/04.png", "03",
          ["寝る前に、昼間の", "会話を思い出してる"],
          ["あの一言余計だったかな、って。", "最近はここで言葉をひとつだけ読んで、", "考えるのをやめてる。"],
          WFM_QUAD)

habit_slide(f"{P}/p05-sofa.png", f"{F}/05.png", "04",
            ["誘いを断るとき、", "理由をふたつ以上つけちゃう"],
            ["「行けない」だけだと感じ悪い気がして。", "気づいたら長文になってる。"])

habit_slide(f"{P}/p06-cafe.png", f"{F}/06.png", "05",
            ["本当はちがうと思っても", "「たしかに」って言っちゃう"],
            ["合わせた方がラクだから。", "でも家に帰ると、ちょっと疲れてる。"])

recap_slide(f"{P}/p07-recap.png", f"{F}/07.png",
            ["嫌われるのが怖い人の", "特徴5選"],
            [("01", "送る前にLINEを3回読み直して、結局スタンプだけ送る"),
             ("02", "「全然いいよ」って言ったあと、ひとりで反省会してる"),
             ("03", "寝る前に、昼間の会話を思い出してる"),
             ("04", "誘いを断るとき、理由をふたつ以上つけちゃう"),
             ("05", "本当はちがうと思っても「たしかに」って言っちゃう")])

quote_slide(f"{P}/p08-quote.png", f"{F}/08.png",
            ["嫌われない工夫より、", "自分に嘘をつかない工夫を。"],
            "Words For Me")
