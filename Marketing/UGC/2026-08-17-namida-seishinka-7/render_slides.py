from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
OUT = ROOT / "slides"
ICON = ROOT.parents[2] / "QuoteApp/Sources/Assets.xcassets/AppIcon.appiconset/Icon-1024.png"

W, H = 1080, 1350
S = 3
PAPER = (246, 242, 235)
INK = (63, 60, 56)
RULE = (116, 109, 101)

SERIF_JP = "/System/Library/Fonts/Supplemental/AppleMyungjo.ttf"
JP_FALLBACK = "/System/Library/Fonts/Hiragino Sans GB.ttc"
SERIF_EN = "/System/Library/Fonts/Supplemental/Baskerville.ttc"


def fnt(path, size):
    return ImageFont.truetype(path, int(size * S))


def jp_font(text, size):
    # AppleMyungjo provides the required Mincho-like rhythm. Hiragino is used
    # only for punctuation characters that AppleMyungjo renders incompletely.
    if any(ch in text for ch in "々・ー医変当残気涙状"):
        return fnt(JP_FALLBACK, size)
    return fnt(SERIF_JP, size)


def xy(v):
    return int(round(v * S))


def centered(draw, text, y, font, fill=INK, spacing=12):
    box = draw.multiline_textbbox(
        (0, 0),
        text,
        font=font,
        anchor="la",
        spacing=xy(spacing),
        align="center",
    )
    x = (xy(W) - (box[2] - box[0])) // 2
    draw.multiline_text(
        (x, xy(y)),
        text,
        font=font,
        fill=fill,
        anchor="la",
        spacing=xy(spacing),
        align="center",
    )


def line(draw, points, fill=RULE, width=2):
    draw.line([(xy(x), xy(y)) for x, y in points], fill=fill, width=xy(width), joint="curve")


def curve(draw, points, fill=RULE, width=2, steps=30):
    # Quadratic Bezier for the restrained hand-drawn single-line motifs.
    p0, p1, p2 = points
    samples = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        samples.append((
            u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0],
            u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1],
        ))
    line(draw, samples, fill=fill, width=width)


def base():
    return Image.new("RGB", (xy(W), xy(H)), PAPER)


def save(img, name):
    OUT.mkdir(parents=True, exist_ok=True)
    img.resize((W, H), Image.Resampling.LANCZOS).save(OUT / name, format="PNG", optimize=True)


def draw_open_book(draw, cx=540, top=230, scale=1.0):
    def p(x, y):
        return cx + x * scale, top + y * scale

    # One open book, no fill and no shadow.
    curve(draw, [p(-5, 65), p(-95, 10), p(-190, 18)], width=2)
    curve(draw, [p(5, 65), p(95, 10), p(190, 18)], width=2)
    curve(draw, [p(-190, 18), p(-175, 118), p(-5, 98)], width=2)
    curve(draw, [p(190, 18), p(175, 118), p(5, 98)], width=2)
    line(draw, [p(0, 65), p(0, 98)], width=2)
    curve(draw, [p(-175, 118), p(-95, 126), p(0, 98)], width=2)
    curve(draw, [p(175, 118), p(95, 126), p(0, 98)], width=2)
    curve(draw, [p(-166, 108), p(-88, 116), p(-3, 92)], width=1)
    curve(draw, [p(166, 108), p(88, 116), p(3, 92)], width=1)
    # Outer cover edges make the open-book silhouette unmistakable.
    line(draw, [p(-190, 18), p(-215, 128), p(-8, 110)], width=1)
    line(draw, [p(190, 18), p(215, 128), p(8, 110)], width=1)
    curve(draw, [p(-215, 128), p(-102, 145), p(0, 110)], width=1)
    curve(draw, [p(215, 128), p(102, 145), p(0, 110)], width=1)
    # A single falling tear above the book.
    x, y = p(0, -55)
    curve(draw, [(x, y - 22 * scale), (x - 18 * scale, y + 4 * scale), (x, y + 26 * scale)], width=2)
    curve(draw, [(x, y - 22 * scale), (x + 18 * scale, y + 4 * scale), (x, y + 26 * scale)], width=2)
    curve(draw, [(x, y + 26 * scale), (x - 1 * scale, y + 31 * scale), (x, y + 34 * scale)], width=2)


def draw_quote_marks(draw, cx, y, upside_down=False):
    # Small serif quote marks are used as the card's line-art motif.
    mark = "”" if upside_down else "“"
    centered(draw, mark, y, fnt(SERIF_EN, 45), fill=RULE)


def fit_quote_font(draw, text, max_width, preferred, minimum=25):
    size = preferred
    while size > minimum:
        font = jp_font(text, size)
        box = draw.multiline_textbbox((0, 0), text, font=font, spacing=xy(12), align="center")
        if box[2] - box[0] <= xy(max_width):
            return font
        size -= 1
    return jp_font(text, minimum)


def draw_quote_card(draw, quote, author, top=245, bottom=1010):
    left, right = 120, 960
    draw.rounded_rectangle(
        (xy(left), xy(top), xy(right), xy(bottom)),
        radius=xy(10),
        outline=RULE,
        width=xy(2),
    )
    draw_quote_marks(draw, 540, top - 43)
    draw_quote_marks(draw, 540, bottom - 37, upside_down=True)

    lines = quote.split("\n")
    preferred = {2: 42, 3: 38, 4: 33}.get(len(lines), 31)
    quote_font = fit_quote_font(draw, quote, 700, preferred)
    box = draw.multiline_textbbox(
        (0, 0), quote, font=quote_font, spacing=xy(16), align="center"
    )
    quote_h = box[3] - box[1]
    author_font = jp_font(author, 28)
    author_box = draw.textbbox((0, 0), "— " + author, font=author_font)
    author_h = author_box[3] - author_box[1]
    group_h = quote_h + xy(48) + author_h
    group_top = (xy(top) + xy(bottom) - group_h) // 2 - xy(4)
    centered(draw, quote, group_top / S, quote_font, spacing=16)
    author_y = (group_top + quote_h + xy(36)) / S
    centered(draw, "— " + author, author_y, author_font, spacing=8)


def render_cover():
    img = base()
    d = ImageDraw.Draw(img)
    draw_open_book(d, top=205, scale=0.78)
    centered(d, "涙が出てくる", 485, jp_font("涙が出てくる", 49), spacing=10)
    centered(d, "精神科医の言葉", 555, jp_font("精神科医の言葉", 49), spacing=10)
    centered(d, "7選", 650, jp_font("7選", 116), spacing=8)
    line(d, [(235, 842), (845, 842)], fill=RULE, width=1)
    centered(d, "最後の1つだけ、", 935, jp_font("最後の1つだけ、", 28), spacing=8)
    centered(d, "今夜のあなたの番。", 978, jp_font("今夜のあなたの番。", 28), spacing=8)
    save(img, "01-cover.png")


QUOTES = [
    (
        "人生を耐えがたいものにするのは\n状況ではなく、意味と目的の欠如だ。",
        "ヴィクトール・フランクル",
    ),
    (
        "子どもはまだ柔らかいセメントのようなもの。\n落ちたものは何でも跡を残す。",
        "ハイム・ギノット",
    ),
    (
        "子どもは、\n大人が自分をどう見るかによって\n自分を知っていく。",
        "佐々木正美",
    ),
    (
        "幼い愛は言う。\n『あなたが必要だから愛している』。\n成熟した愛は言う。\n『愛しているから、あなたを必要とする』。",
        "エーリッヒ・フロム",
    ),
    (
        "人生を振り返ると、\nいちばん大きな幸せは家族の幸せだとわかる。",
        "ジョイス・ブラザーズ",
    ),
    (
        "本当の居場所は、\n自分を受け入れるところから始まる。",
        "ブレネー・ブラウン",
    ),
]


def render_quote(index, quote, author):
    img = base()
    d = ImageDraw.Draw(img)
    centered(d, "今日の言葉", 130, jp_font("今日の言葉", 28), spacing=8)
    top = 235 if len(quote.split("\n")) <= 3 else 175
    bottom = 1050 if len(quote.split("\n")) <= 3 else 1105
    draw_quote_card(d, quote, author, top=top, bottom=bottom)
    save(img, f"{index:02d}-quote{index - 1}.png")


def draw_face_down_card(draw):
    # Two offset blank cards make the hidden content legible without adding text.
    draw.rounded_rectangle(
        (xy(342), xy(526), xy(760), xy(816)),
        radius=xy(12),
        outline=RULE,
        width=xy(2),
    )
    draw.rounded_rectangle(
        (xy(320), xy(500), xy(738), xy(790)),
        radius=xy(12),
        outline=RULE,
        width=xy(2),
    )
    # A single restrained corner line suggests a face-down card, without text.
    line(draw, [(320, 500), (352, 532)], width=2)


def render_withheld():
    img = base()
    d = ImageDraw.Draw(img)
    centered(d, "7. 最後の1つだけ、\nまだ誰にも見せていません。", 130, jp_font("7. 最後の1つだけ、\nまだ誰にも見せていません。", 35), spacing=13)
    line(d, [(390, 276), (690, 276)], fill=RULE, width=1)
    centered(d, "the seventh is yours", 304, fnt(SERIF_EN, 27), fill=INK, spacing=3)
    draw_face_down_card(d)
    centered(d, "6人の言葉は、もう決まってる。", 955, jp_font("6人の言葉は、もう決まってる。", 26), spacing=8)
    centered(d, "7つ目だけは、今夜引く人によって変わる。", 995, jp_font("7つ目だけは、今夜引く人によって変わる。", 26), spacing=8)
    save(img, "08-withheld.png")


def render_closing():
    img = base()
    d = ImageDraw.Draw(img)
    icon = Image.open(ICON).convert("RGB")
    icon.thumbnail((xy(146), xy(146)), Image.Resampling.LANCZOS)
    x = (xy(W) - icon.width) // 2
    y = xy(535)
    img.paste(icon, (x, y))
    centered(d, "気になった夜は、Words for Meで一枚だけ引いてる。", 760, jp_font("気になった夜は、Words for Meで一枚だけ引いてる。", 22), spacing=6)
    save(img, "09-closing.png")


def main():
    render_cover()
    for index, (quote, author) in enumerate(QUOTES, start=2):
        render_quote(index, quote, author)
    render_withheld()
    render_closing()


if __name__ == "__main__":
    main()
