from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
OUT = ROOT / "delivery-fuan" / "slides"
ICON = ROOT.parents[2] / "QuoteApp/Sources/Assets.xcassets/AppIcon.appiconset/Icon-1024.png"

W, H = 1080, 1350
S = 3
PAPER = (246, 242, 235)
INK = (63, 60, 56)
RULE = (116, 109, 101)

JP_FONT = next(Path("/System/Library/Fonts").glob("*明朝*"))
EN_FONT = Path("/System/Library/Fonts/Supplemental/Baskerville.ttc")


def px(value):
    return int(round(value * S))


def font(path, size):
    return ImageFont.truetype(str(path), px(size))


def canvas():
    return Image.new("RGB", (px(W), px(H)), PAPER)


def tracked_width(draw, text, face, tracking):
    if not text:
        return 0
    return sum(draw.textlength(ch, font=face) for ch in text) + px(tracking) * (len(text) - 1)


def tracked_text(draw, text, y, face, tracking=0, fill=INK):
    width = tracked_width(draw, text, face, tracking)
    x = (px(W) - width) / 2
    for ch in text:
        draw.text((x, px(y)), ch, font=face, fill=fill, anchor="la")
        x += draw.textlength(ch, font=face) + px(tracking)


def centered_lines(draw, lines, y, face, gap=16, tracking=1.0, fill=INK):
    line_height = face.size / S
    for index, text in enumerate(lines):
        tracked_text(draw, text, y + index * (line_height + gap), face, tracking, fill)


def line(draw, points, fill=RULE, width=2):
    draw.line([(px(x), px(y)) for x, y in points], fill=fill, width=px(width), joint="curve")


def cubic(draw, points, fill=RULE, width=2, steps=48):
    p0, p1, p2, p3 = points
    samples = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        samples.append(
            (
                u**3 * p0[0] + 3 * u**2 * t * p1[0] + 3 * u * t**2 * p2[0] + t**3 * p3[0],
                u**3 * p0[1] + 3 * u**2 * t * p1[1] + 3 * u * t**2 * p2[1] + t**3 * p3[1],
            )
        )
    line(draw, samples, fill, width)


def ellipse(draw, box, width=2):
    draw.ellipse(tuple(px(v) for v in box), outline=RULE, width=px(width))


def rounded(draw, box, radius=16, width=2):
    draw.rounded_rectangle(tuple(px(v) for v in box), radius=px(radius), outline=RULE, width=px(width))


def save(img, filename):
    OUT.mkdir(parents=True, exist_ok=True)
    img.resize((W, H), Image.Resampling.LANCZOS).save(OUT / filename, format="PNG", optimize=True)


def draw_wave_anchor(draw):
    cubic(draw, [(270, 235), (360, 210), (425, 258), (515, 230)], width=2)
    cubic(draw, [(515, 230), (610, 202), (690, 255), (810, 225)], width=2)
    ellipse(draw, (519, 266, 561, 308), width=2)
    line(draw, [(540, 308), (540, 418)], width=2)
    line(draw, [(501, 336), (579, 336)], width=2)
    cubic(draw, [(540, 418), (500, 426), (461, 407), (445, 365)], width=2)
    cubic(draw, [(540, 418), (580, 426), (619, 407), (635, 365)], width=2)
    line(draw, [(445, 365), (431, 388)], width=2)
    line(draw, [(445, 365), (469, 372)], width=2)
    line(draw, [(635, 365), (611, 372)], width=2)
    line(draw, [(635, 365), (649, 388)], width=2)


def draw_bubble(draw, short=False):
    left, top, right, bottom = (350, 720, 730, 940) if not short else (365, 730, 715, 925)
    rounded(draw, (left, top, right, bottom), radius=32, width=2)
    line(draw, [(left + 75, bottom), (left + 52, bottom + 55), (left + 132, bottom)], width=2)
    if short:
        line(draw, [(430, 805), (650, 805)], width=2)
        line(draw, [(430, 850), (585, 850)], width=2)


def draw_clearing_cloud(draw):
    # A single cloud whose thinning right edge suggests the mood clearing.
    cubic(draw, [(336, 878), (315, 824), (358, 781), (414, 795)], width=2)
    cubic(draw, [(414, 795), (430, 712), (548, 709), (573, 798)], width=2)
    cubic(draw, [(573, 798), (638, 763), (720, 812), (701, 882)], width=2)
    cubic(draw, [(701, 882), (691, 925), (627, 932), (575, 920)], width=2)
    line(draw, [(575, 920), (402, 920)], width=2)
    cubic(draw, [(402, 920), (354, 919), (328, 906), (336, 878)], width=2)
    cubic(draw, [(688, 742), (724, 702), (771, 683), (817, 682)], width=2)
    line(draw, [(779, 755), (836, 725)], width=2)


def draw_calendar_arrow(draw):
    rounded(draw, (345, 725, 735, 975), radius=14, width=2)
    line(draw, [(345, 800), (735, 800)], width=2)
    line(draw, [(435, 688), (435, 765)], width=2)
    line(draw, [(645, 688), (645, 765)], width=2)
    line(draw, [(438, 886), (600, 886)], width=2)
    line(draw, [(600, 886), (565, 852)], width=2)
    line(draw, [(600, 886), (565, 920)], width=2)


def draw_closed_book(draw):
    rounded(draw, (335, 765, 745, 950), radius=10, width=2)
    line(draw, [(380, 765), (380, 950)], width=2)
    line(draw, [(402, 805), (678, 805)], width=2)
    cubic(draw, [(745, 807), (716, 825), (716, 892), (745, 910)], width=2)


def draw_equal_circles(draw):
    ellipse(draw, (330, 755, 520, 945), width=2)
    ellipse(draw, (560, 755, 750, 945), width=2)
    line(draw, [(405, 990), (675, 990)], width=1)


def draw_magnifier(draw):
    ellipse(draw, (385, 710, 650, 975), width=2)
    line(draw, [(620, 945), (735, 1060)], width=3)
    cubic(draw, [(432, 820), (447, 763), (501, 746), (548, 760)], width=1)


def render_cover():
    img = canvas()
    draw = ImageDraw.Draw(img)
    draw_wave_anchor(draw)
    centered_lines(draw, ["不安にさせない男性の", "行動"], 500, font(JP_FONT, 48), gap=17, tracking=1.7)
    tracked_text(draw, "7", 670, font(JP_FONT, 122), tracking=0)
    # Keep the title phrase intact in reading order while emphasizing the list count.
    draw.text((px(637), px(770)), "選", font=font(JP_FONT, 46), fill=INK, anchor="mm")
    line(draw, [(255, 885), (825, 885)], width=1)
    tracked_text(draw, "特別なことは、何もしてない。", 955, font(JP_FONT, 29), tracking=1.1)
    save(img, "01-cover.png")


ITEMS = [
    ("02-item01.png", ["1. 既読を、わざと", "遅らせない。"], "no delayed reads on purpose", lambda d: draw_bubble(d, False)),
    ("03-item02.png", ["2. 忙しい日でも、", "一言だけ送る。"], "one line even on busy days", lambda d: draw_bubble(d, True)),
    ("04-item03.png", ["3. 不機嫌を、黙って", "引きずらない。"], "doesn't carry a bad mood", draw_clearing_cloud),
    ("05-item04.png", ["4. 会えない理由を、", "先に伝える。"], "explains before she asks", draw_calendar_arrow),
    ("06-item05.png", ["5. 過去の話を、", "蒸し返さない。"], "doesn't reopen old fights", draw_closed_book),
    ("07-item06.png", ["6. 比べる言葉を、", "使わない。"], "never compares her to anyone", draw_equal_circles),
    ("08-item07.png", ["7. 「大丈夫」を、", "簡単に信じない。"], "doesn't take \"I'm fine\" lightly", draw_magnifier),
]


def render_item(filename, title_lines, english, motif):
    img = canvas()
    draw = ImageDraw.Draw(img)
    centered_lines(draw, title_lines, 255, font(JP_FONT, 47), gap=18, tracking=1.2)
    line(draw, [(395, 490), (685, 490)], width=1)
    tracked_text(draw, english, 525, font(EN_FONT, 26), tracking=1.4)
    motif(draw)
    save(img, filename)


def render_closing():
    img = canvas()
    icon = Image.open(ICON).convert("RGBA")
    icon = icon.resize((px(156), px(156)), Image.Resampling.LANCZOS)
    x = (px(W) - icon.width) // 2
    y = px(505)
    img.paste(icon.convert("RGB"), (x, y))
    draw = ImageDraw.Draw(img)
    tracked_text(draw, "Words For Me — 名言アプリ", 720, font(JP_FONT, 30), tracking=0.7)
    save(img, "09-closing.png")


def main():
    render_cover()
    for item in ITEMS:
        render_item(*item)
    render_closing()


if __name__ == "__main__":
    main()
