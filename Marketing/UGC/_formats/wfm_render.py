"""WFM UGC 共通レンダラー

2つの視覚言語を持つ。
  1. frame  — 現行 v3-lineart の生成りオフホワイト＋墨色明朝（エンタメ層／伸びる側の言語）
  2. card   — アプリ実物の名言カード（実背景写真＋縦書き HiraMinProN-W6＋金の罫）

card は画像生成をせず `Assets.xcassets/Backgrounds` の実アセットと
`quotes_full.json` の `background_image` をそのまま使う。
縦書きの挙動は `QuoteApp/Sources/Utilities/VerticalTextView.swift` に合わせている。
"""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path('/Users/mac2-mayu/Quote-app')
W, H = 1080, 1920

# --- v3-lineart のオフホワイト言語（既存バッチと同一値） ---
PAPER = (246, 242, 235)
INK = (63, 60, 56)
RULE = (133, 126, 116)

# --- 実物カード側 ---
GOLD = (217, 166, 51)          # ImageGenerator.swift accentGold (0.85,0.65,0.2)
CARD_TEXT = (255, 255, 255)

# --- アプリ実画面のトークン（Assets.xcassets/Colors の dark 値）---
# WeeklyShelfView は preferredColorScheme(.dark) なので dark を採る。
APP_PAGE = (30, 26, 29)        # PageBase       0.118,0.102,0.114
APP_SHEET = (43, 37, 40)       # SheetBase      0.169,0.145,0.157
APP_TEXT = (246, 238, 241)     # TextPrimary    0.965,0.933,0.945
APP_SUB = (194, 182, 190)      # TextSub        0.761,0.714,0.745
APP_ROSE = (246, 174, 171)     # AccentRose     0.965,0.682,0.671

# DesignSystem.swift の Space / Radius を pt で保持し、PT で px に直す。
PT = W / 393                   # iPhoneの論理幅393pt を 1080px に写す
SPACE = {'xxs': 4, 'xs': 8, 's': 12, 'm': 16, 'l': 24, 'xl': 32}
RADIUS = {'s': 12, 'm': 18, 'l': 26, 'xl': 34}

MINCHO_W3 = '/System/Library/Fonts/ヒラギノ明朝 ProN.ttc'   # index 0
MINCHO_W6_INDEX = 2                                        # HiraMinProN-W6
GOTHIC = '/System/Library/Fonts/ヒラギノ角ゴシック W{}.ttc'  # SwiftUI既定の和文（.body 等）
SERIF_EN = '/System/Library/Fonts/Times New Roman.ttf'

BG_DIR = ROOT / 'QuoteApp/Sources/Assets.xcassets/Backgrounds'
ICON = ROOT / 'QuoteApp/Sources/Assets.xcassets/AppIcon.appiconset/Icon-1024.png'

_q = json.load(open(ROOT / 'QuoteApp/Sources/Resources/quotes_full.json'))
QUOTES = _q['quotes'] if isinstance(_q, dict) else _q
BY_ID = {q['id']: q for q in QUOTES}


def mincho(size, weight=3):
    return ImageFont.truetype(MINCHO_W3, size, index=0 if weight == 3 else MINCHO_W6_INDEX)


def gothic(size, weight=3):
    """SwiftUI の .body / .title3 等（design未指定）に対応する和文。"""
    return ImageFont.truetype(GOTHIC.format(weight), size)


def serif(size):
    return ImageFont.truetype(SERIF_EN, size)


def pt(v):
    """DesignSystem.swift の pt 値を px に直す。"""
    return v * PT


# ---------------------------------------------------------------- 実背景アセット

def background(name):
    """background_image 名から実アセットPNGを読む。無ければ近い既定へ落とす。"""
    for cand in (name, 'purple_moon', 'blush_garden'):
        p = BG_DIR / f'{cand}.imageset' / f'{cand}.png'
        if p.exists():
            return Image.open(p).convert('RGB')
        hits = list((BG_DIR / f'{cand}.imageset').glob('*.png')) if (BG_DIR / f'{cand}.imageset').exists() else []
        if hits:
            return Image.open(hits[0]).convert('RGB')
    raise FileNotFoundError(name)


def cover_fill(im, w, h):
    """アスペクト比を保って中央クロップ。"""
    r = max(w / im.width, h / im.height)
    im = im.resize((max(1, int(im.width * r)), max(1, int(im.height * r))), Image.Resampling.LANCZOS)
    x, y = (im.width - w) // 2, (im.height - h) // 2
    return im.crop((x, y, x + w, y + h))


def dark_gradient(im, top=0.30, mid=0.60, bot=0.90):
    """ImageGenerator.swift の drawDarkGradient と同じ 0.3 → 0.6 → 0.9。"""
    w, h = im.size
    ov = Image.new('L', (1, h))
    px = ov.load()
    for y in range(h):
        t = y / max(1, h - 1)
        a = top + (mid - top) * (t / 0.5) if t < 0.5 else mid + (bot - mid) * ((t - 0.5) / 0.5)
        px[0, y] = int(a * 255)
    ov = ov.resize((w, h))
    return Image.composite(Image.new('RGB', (w, h), (0, 0, 0)), im, ov)


# ---------------------------------------------------------------- 縦書き

ROTATE = set('ー-~〜()「」『』（）＜＞[]')
PUNCT = set('。、.,')
SMALL = set('ぁぃぅぇぉっゃゅょァィゥェォッャュョ')


def columns(text, max_rows):
    """\\n があればそれを列とみなす。無ければ読点優先＋列長を均して割る。"""
    if '\n' in text:
        return [l for l in text.split('\n') if l.strip()]
    n = len(text)
    if n <= max_rows:
        return [text]
    ncols = -(-n // max_rows)                      # 必要な最小列数
    target = -(-n // ncols)                        # 均した1列あたり
    cols, cur = [], ''
    for ch in text:
        cur += ch
        # 読点はその列の締めに使えるなら優先して折る
        soft = ch in '、。' and len(cur) >= target - 3
        if (soft or len(cur) >= target) and len(cols) < ncols - 1:
            cols.append(cur)
            cur = ''
    if cur:
        cols.append(cur)
    return cols


def clean_columns(text, max_rows):
    """句読点でだけ列を折る。語の途中で切れる解は返さない（収まらなければ None）。"""
    if '\n' in text:
        cols = [l for l in text.split('\n') if l.strip()]
        return cols if max(len(c) for c in cols) <= max_rows else None
    chunks, cur = [], ''
    for ch in text:
        cur += ch
        if ch in '、。！？':
            chunks.append(cur)
            cur = ''
    if cur:
        chunks.append(cur)
    if not chunks or max(len(c) for c in chunks) > max_rows:
        return None
    cols, cur = [], ''
    for c in chunks:
        if cur and len(cur) + len(c) > max_rows:
            cols.append(cur)
            cur = c
        else:
            cur += c
    if cur:
        cols.append(cur)
    return cols


def fit_vertical(text, box_h, box_w, fs_max=96, fs_min=44):
    """箱に収まる最大の字送りと列構成を返す。句読点で折れる解を優先する。"""
    def fits(fs, cols):
        spacing = fs * 0.42
        return len(cols) * fs + (len(cols) - 1) * spacing <= box_w

    best = {}
    for key, build in (('clean', clean_columns), ('balanced', columns)):
        for fs in range(fs_max, fs_min - 1, -2):
            max_rows = int(box_h // (fs * 1.1))
            if max_rows < 4:
                continue
            cols = build(text, max_rows)
            if not cols or max(len(c) for c in cols) > max_rows:
                continue
            if fits(fs, cols):
                best[key] = (fs, cols, fs * 0.42)
                break
    # 句読点で折れる解を優先する。ただしそのために字が大きく痩せるなら均等割りを採る。
    c, b = best.get('clean'), best.get('balanced')
    if c and (not b or b[0] <= c[0] * 1.3):
        return c
    if b:
        return b
    fs = fs_min
    return fs, columns(text, int(box_h // (fs * 1.1))), fs * 0.42


def draw_vertical(base, cols, fs, x_right, y_top, spacing, fill=CARD_TEXT, weight=6, shadow=True):
    """VerticalTextView と同じ規則で縦書きを描く。列は右から左。"""
    f = mincho(fs, weight)
    cell = fs * 1.1
    layer = Image.new('RGBA', base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x = x_right
    for col in cols:                      # cols[0] が最も右
        y = y_top
        for ch in col:
            dx = dy = 0
            if ch in PUNCT:
                dx, dy = fs * 0.60, -fs * 0.60
            elif ch in SMALL:
                dx, dy = fs * 0.15, -fs * 0.15
            if ch in ROTATE:
                t = Image.new('RGBA', (int(fs * 1.6), int(fs * 1.6)), (0, 0, 0, 0))
                ImageDraw.Draw(t).text((t.width / 2, t.height / 2), ch, font=f,
                                       fill=fill + (255,), anchor='mm')
                t = t.rotate(-90, resample=Image.BICUBIC)
                layer.alpha_composite(t, (int(x - t.width / 2 + dx), int(y + cell / 2 - t.height / 2 + dy)))
            else:
                d.text((x + dx, y + cell / 2 + dy), ch, font=f, fill=fill + (255,), anchor='mm')
            y += cell
        x -= (fs + spacing)
    if shadow:
        sh = layer.filter(ImageFilter.GaussianBlur(9))
        dark = Image.new('RGBA', base.size, (0, 0, 0, 0))
        dark.putalpha(sh.getchannel('A').point(lambda v: int(v * 0.55)))
        base.alpha_composite(dark, (0, 4))
    base.alpha_composite(layer)
    return x


# ---------------------------------------------------------------- 実物カード

def real_card(quote_id, size=(W, H), fs=86, author=True):
    """アプリのメイン画面と同じ見た目のカードを実アセットから作る。"""
    q = BY_ID[quote_id]
    w, h = size
    im = cover_fill(background(q.get('background_image') or 'purple_moon'), w, h)
    im = im.filter(ImageFilter.GaussianBlur(max(1, w / 260)))
    im = dark_gradient(im).convert('RGBA')

    box_h, box_w = h * 0.62, w * 0.72
    fs, cols, spacing = fit_vertical(q['quote_ja'], box_h, box_w, fs_max=fs)
    total_w = len(cols) * fs + (len(cols) - 1) * spacing
    x_right = w / 2 + total_w / 2 - fs / 2
    longest = max(len(c) for c in cols)
    y_top = h * 0.20 + (box_h - longest * fs * 1.1) / 2
    draw_vertical(im, cols, fs, x_right, y_top, spacing)

    if author:
        name = q.get('author_kana') or q.get('author') or ''
        if name and name not in ('オリジナル', 'Original'):
            afs = max(20, int(fs * 0.32))
            ax = w * 0.155
            ay = h * 0.70
            d = ImageDraw.Draw(im)
            # 実物カードと同じく、金の縦罫は著者名の左側
            gx = ax - afs * 1.15
            d.line((gx, ay + afs * 0.4, gx, ay + afs * 1.1 * len(name)),
                   fill=GOLD + (255,), width=max(3, int(w / 260)))
            draw_vertical(im, [name], afs, ax, ay, 0, fill=(242, 240, 237), weight=3, shadow=True)
    return im.convert('RGB')


# ---------------------------------------------------------------- オフホワイト枠

def paper():
    return Image.new('RGB', (W, H), PAPER)


def lineart(path, strength=1.0, dy=0):
    """生成した一本線イラストを紙の2値パレットへ正規化して背景にする。

    生成物の地色・線色は毎回わずかにブレるので、明度だけを取り出して
    PAPER と INK の間に写像し直す。これで枠スライドと完全に同じ色になる。

    dy>0 で絵を上へ送る。既定の下揃えだと絵が下端まで届き、TikTokの
    キャプション／ユーザー名が乗る下25%と重なる。
    """
    art = Image.open(path).convert('L')
    # 生成物は 2:3 などで返るため、幅に合わせて縮尺し**下揃え**で置く。
    # 横クロップすると線画の端（机の脚など）が切れる。上部は元から余白なので
    # 足りない分を紙色で埋め、はみ出す分だけ上から捨てる。
    scaled_h = round(art.height * W / art.width)
    art = art.resize((W, scaled_h), Image.Resampling.LANCZOS)
    canvas = Image.new('L', (W, H), 255)
    if scaled_h <= H:
        canvas.paste(art, (0, H - scaled_h))
    else:
        canvas.paste(art.crop((0, scaled_h - H, W, scaled_h)), (0, 0))
    # 地のわずかな濁りを飛ばし、線だけを残す
    canvas = canvas.point(lambda v: 255 if v > 232 else max(0, int((v - 40) * 255 / 192)))
    out = Image.new('RGB', (W, H), PAPER)
    ink = Image.new('RGB', (W, H), INK)
    alpha = canvas.point(lambda v: int((255 - v) * strength))
    im = Image.composite(ink, out, alpha)
    if dy:
        shifted = paper()
        shifted.paste(im.crop((0, dy, W, H)), (0, 0))
        im = shifted
    return im


def ink_bounds(im, threshold=200):
    """線画の実インクが縦方向のどこにあるかを返す（0..H）。送り量の算出用。"""
    g = im.convert('L')
    rows = [y for y in range(H) if min(g.crop((0, y, W, y + 1)).getdata()) < threshold]
    return (rows[0], rows[-1]) if rows else (0, 0)


def wrap(d, text, font, max_w):
    NO_HEAD = '、。」』ーぁぃぅぇぉっゃゅょ'
    out = []
    for para in text.split('\n'):
        cur = ''
        for ch in para.strip():
            if d.textlength(cur + ch, font=font) > max_w and cur and ch not in NO_HEAD:
                out.append(cur)
                cur = ch
            else:
                cur += ch
        if cur:
            out.append(cur)
    return out


def stack(d, cy, lines, font, fill, leading):
    y = cy - leading * (len(lines) - 1) / 2
    for ln in lines:
        d.text((W // 2, y), ln, font=font, fill=fill, anchor='mm')
        y += leading


def tracked(d, cx, y, text, font, fill, tracking=14):
    ws = [d.textlength(c, font=font) for c in text]
    x = cx - (sum(ws) + tracking * (len(text) - 1)) / 2
    for c, wd in zip(text, ws):
        d.text((x, y), c, font=font, fill=fill, anchor='lm')
        x += wd + tracking


def fit_horizontal(lines, box_w, fs_max=96, fs_min=48, track_ratio=0.08):
    """最長行が箱に収まる最大の字送りと字間を返す（横書きタイトル用）。"""
    d = ImageDraw.Draw(Image.new('RGB', (10, 10)))
    for fs in range(fs_max, fs_min - 1, -2):
        f = mincho(fs, 6)
        tr = fs * track_ratio
        widest = max(sum(d.textlength(c, font=f) for c in ln) + tr * (len(ln) - 1)
                     for ln in lines)
        if widest <= box_w:
            return fs, tr
    return fs_min, fs_min * track_ratio


def h_title(im, lines, cy, box_w=None, fs_max=96, leading=1.52, fill=INK):
    """横書きタイトル。行は中央揃え、字間は明朝の見出しらしく少し開ける。

    同じ面積なら縦書きより字が大きく取れる（22字の見出しで 61px → 72px）。
    描画後のブロック下端 y を返すので、罫やサブコピーはそこから積む。
    """
    d = ImageDraw.Draw(im)
    fs, tr = fit_horizontal(lines, box_w or W * 0.88, fs_max=fs_max)
    f = mincho(fs, 6)
    lead = fs * leading
    y = cy - lead * (len(lines) - 1) / 2
    for ln in lines:
        tracked(d, W / 2, y, ln, f, fill, tr)
        y += lead
    return fs, cy + lead * (len(lines) - 1) / 2 + fs / 2


def en_sub(d, y, text, size=30, tracking=9):
    tracked(d, W // 2, y, text.upper(), serif(size), RULE, tracking)


def hairline(d, y, half=90):
    d.line((W // 2 - half, y, W // 2 + half, y), fill=RULE, width=2)
