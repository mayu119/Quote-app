from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
OUT = ROOT / "delivery-iwanai" / "slides"

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


def cubic(draw, points, fill=RULE, width=2, steps=64):
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
    line(draw, samples, fill=fill, width=width)


def ellipse(draw, box, width=2):
    draw.ellipse(tuple(px(v) for v in box), outline=RULE, width=px(width))


def rounded(draw, box, radius=10, width=2):
    draw.rounded_rectangle(tuple(px(v) for v in box), radius=px(radius), outline=RULE, width=px(width))


def save(img, filename):
    OUT.mkdir(parents=True, exist_ok=True)
    img.resize((W, H), Image.Resampling.LANCZOS).save(OUT / filename, format="PNG", optimize=True)


# Every motif is a single restrained, unfilled line drawing using the same stroke.
def draw_untying_thread(draw):
    cubic(draw, [(292, 305), (360, 264), (424, 292), (468, 330)], width=2)
    cubic(draw, [(468, 330), (502, 360), (532, 350), (540, 321)], width=2)
    cubic(draw, [(540, 321), (548, 350), (578, 360), (612, 330)], width=2)
    cubic(draw, [(612, 330), (656, 292), (720, 264), (788, 305)], width=2)
    cubic(draw, [(468, 330), (420, 391), (515, 413), (540, 321)], width=2)
    cubic(draw, [(612, 330), (660, 391), (565, 413), (540, 321)], width=2)
    cubic(draw, [(292, 305), (246, 335), (216, 349), (178, 354)], width=2)
    cubic(draw, [(788, 305), (834, 335), (864, 349), (902, 354)], width=2)


def draw_shrinking_wave(draw):
    # A voice waveform that visibly loses amplitude toward the right.
    points = [
        (245, 870), (285, 870), (315, 755), (350, 985), (390, 785), (430, 948),
        (470, 815), (510, 925), (550, 835), (590, 906), (630, 850), (670, 892),
        (710, 860), (748, 881), (785, 866), (835, 872),
    ]
    line(draw, points, width=2)


def draw_heavy_eyelids(draw):
    cubic(draw, [(305, 820), (370, 752), (470, 752), (520, 820)], width=2)
    cubic(draw, [(560, 820), (610, 752), (710, 752), (775, 820)], width=2)
    cubic(draw, [(320, 855), (385, 900), (455, 900), (505, 855)], width=2)
    cubic(draw, [(575, 855), (625, 900), (695, 900), (760, 855)], width=2)
    line(draw, [(345, 765), (326, 724)], width=2)
    line(draw, [(424, 742), (421, 695)], width=2)
    line(draw, [(655, 742), (659, 695)], width=2)
    line(draw, [(735, 765), (754, 724)], width=2)


def draw_bookshelf_one_book(draw):
    # Shelf and one book only: no phone, app icon, badge, card, or extra label.
    line(draw, [(315, 955), (765, 955)], width=2)
    line(draw, [(345, 745), (345, 955)], width=2)
    line(draw, [(735, 745), (735, 955)], width=2)
    line(draw, [(345, 775), (735, 775)], width=2)
    rounded(draw, (485, 795, 595, 955), radius=4, width=2)
    line(draw, [(510, 795), (510, 955)], width=2)
    line(draw, [(528, 830), (572, 830)], width=1)


def draw_unequal_circles(draw):
    ellipse(draw, (300, 770, 500, 970), width=2)
    ellipse(draw, (565, 700, 825, 960), width=2)


def draw_hesitating_hand(draw):
    # An open hand just before it is extended, drawn without face or fill.
    cubic(draw, [(285, 928), (360, 901), (410, 886), (470, 866)], width=2)
    cubic(draw, [(470, 866), (520, 838), (580, 815), (646, 802)], width=2)
    cubic(draw, [(646, 802), (681, 795), (689, 819), (658, 836)], width=2)
    cubic(draw, [(658, 836), (632, 849), (606, 861), (578, 871)], width=2)
    cubic(draw, [(578, 871), (650, 867), (713, 869), (772, 883)], width=2)
    cubic(draw, [(772, 883), (808, 892), (807, 921), (770, 927)], width=2)
    cubic(draw, [(770, 927), (710, 937), (647, 947), (586, 965)], width=2)
    cubic(draw, [(586, 965), (526, 982), (475, 1011), (432, 1040)], width=2)
    line(draw, [(432, 1040), (295, 1040)], width=2)
    cubic(draw, [(295, 1040), (321, 1007), (320, 967), (285, 928)], width=2)


def render_cover():
    img = canvas()
    draw = ImageDraw.Draw(img)
    draw_untying_thread(draw)
    centered_lines(draw, ["自分を責める女性が", "言わない言葉"], 490, font(JP_FONT, 48), gap=17, tracking=1.7)
    tracked_text(draw, "5", 675, font(JP_FONT, 120), tracking=0)
    draw.text((px(637), px(774)), "選", font=font(JP_FONT, 46), fill=INK, anchor="mm")
    line(draw, [(255, 885), (825, 885)], width=1)
    tracked_text(draw, "言わなくなったら、", 948, font(JP_FONT, 29), tracking=1.1)
    tracked_text(draw, "少し息がしやすくなった。", 1000, font(JP_FONT, 29), tracking=1.1)
    save(img, "01-cover.png")


ITEMS = [
    (
        "02-item01.png",
        ["1. 「私なんて」と、", "口癖のように言うこと。"],
        'calling herself "nothing"',
        draw_shrinking_wave,
    ),
    (
        "03-item02.png",
        ["2. 頑張れなかった日を、", "「甘え」と呼ぶこと。"],
        "calling a hard day laziness",
        draw_heavy_eyelids,
    ),
    (
        "04-item03.png",
        ["3. 流して終わる保存を、", "Words for Meに変えること。"],
        "not just saved, kept",
        draw_bookshelf_one_book,
    ),
    (
        "05-item04.png",
        ["4. 人と比べて、「自分はダメ」と", "決めつけること。"],
        "deciding she's the worst",
        draw_unequal_circles,
    ),
    (
        "06-item05.png",
        ["5. 誰かに謝る前に、", "自分を先に責めること。"],
        "blaming herself first",
        draw_hesitating_hand,
    ),
]


def render_item(filename, title_lines, english, motif):
    # This exact template is used for all five items, including 04-item03.png.
    img = canvas()
    draw = ImageDraw.Draw(img)
    centered_lines(draw, title_lines, 255, font(JP_FONT, 45), gap=18, tracking=1.0)
    line(draw, [(395, 490), (685, 490)], width=1)
    tracked_text(draw, english, 525, font(EN_FONT, 26), tracking=1.4)
    motif(draw)
    save(img, filename)


def render_closing():
    img = canvas()
    draw = ImageDraw.Draw(img)
    tracked_text(draw, "今日の言葉", 158, font(JP_FONT, 27), tracking=2.0)
    line(draw, [(435, 215), (645, 215)], width=1)
    rounded(draw, (135, 292, 945, 1055), radius=8, width=2)
    centered_lines(
        draw,
        ["自分を裁かずに見つめることは、", "人間の高い知性のかたちだ。"],
        545,
        font(JP_FONT, 39),
        gap=25,
        tracking=1.1,
    )
    tracked_text(draw, "— ジッドゥ・クリシュナムルティ", 755, font(JP_FONT, 27), tracking=0.6)
    save(img, "07-closing.png")


def main():
    render_cover()
    for item in ITEMS:
        render_item(*item)
    render_closing()


if __name__ == "__main__":
    main()
