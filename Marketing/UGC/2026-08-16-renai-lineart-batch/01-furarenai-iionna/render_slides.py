from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parent
BASES = ROOT / "workbases"
OUT = ROOT / "slides"
W, H = 1080, 1350
S = 2
INK = (63, 60, 56, 255)
PAPER = (246, 242, 235, 255)
SERIF_JP = "/System/Library/Fonts/Supplemental/AppleMyungjo.ttf"
JP_FALLBACK = "/System/Library/Fonts/Hiragino Sans GB.ttc"
SERIF_EN = "/System/Library/Fonts/Supplemental/Baskerville.ttc"
# AppleMyungjo has a beautiful Mincho-like rhythm but lacks these CJK glyphs.
# Use a Japanese CJK fallback for any line containing one of them, preventing .notdef boxes.
JP_MISSING = set("・ー会寝拠揺残緒証込飲")


def font(path, size):
    return ImageFont.truetype(path, int(size * S))


def centered(draw, text, y, fnt, fill=INK, spacing=12):
    if any(ch in JP_MISSING for ch in text):
        fnt = font(JP_FALLBACK, fnt.size / S)
    box = draw.multiline_textbbox((0, 0), text, font=fnt, anchor="la", spacing=int(spacing * S), align="center")
    x = (W * S - (box[2] - box[0])) // 2
    draw.multiline_text((x, int(y * S)), text, font=fnt, fill=fill, anchor="la", spacing=int(spacing * S), align="center")


def line(draw, xy, fill=INK, width=1):
    draw.line(tuple(int(v * S) for v in xy), fill=fill, width=max(1, int(width * S)))


def prepare(name):
    if name == "12-closing":
        return Image.new("RGBA", (W * S, H * S), PAPER)
    src = Image.open(BASES / f"{name}.png").convert("RGBA")
    return ImageOps.fit(src, (W * S, H * S), method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))


def render_cover():
    name = "01-cover"
    img = prepare(name)
    d = ImageDraw.Draw(img)
    centered(d, "フラれないいい女の", 525, font(SERIF_JP, 48))
    centered(d, "思考法", 602, font(SERIF_JP, 48))
    centered(d, "10", 682, font(SERIF_JP, 128))
    d.text((650 * S, 754 * S), "選", font=font(SERIF_JP, 52), fill=INK, anchor="ma")
    line(d, (220, 885, 860, 885), fill=(116, 109, 101, 220), width=1)
    centered(d, "全部できてなくても大丈夫。", 975, font(SERIF_JP, 28))
    centered(d, "私は3つからでした。", 1022, font(SERIF_JP, 28))
    img.resize((W, H), Image.Resampling.LANCZOS).convert("RGB").save(OUT / "01-cover.png", optimize=True)


ITEMS = [
    ("02-item01", "1. 返信の速さで、\n愛を測らない。", "speed is not love"),
    ("03-item02", "2. 会えない日を、\n不安の材料にしない。", "absence is not a sign"),
    ("04-item03", "3. 重いかな、で\n言葉を飲み込まない。", "say it anyway"),
    ("05-item04", "4. 揺れた夜は、SNSを閉じて\n言葉を一枚だけ。", "one line a night"),
    ("06-item05", "5. 彼の機嫌まで、\n引き受けない。", "his mood is his job"),
    ("07-item06", "6. 元彼と、今の彼を\n比べない。", "he is not your ex"),
    ("08-item07", "7. 選ばれるのを待つ側に、\n回らない。", "you are choosing too"),
    ("09-item08", "8. 予定を空けて、\n待たない。", "keep your own plans"),
    ("10-item09", "9. 愛されてる証拠集めを、\nやめる。", "stop collecting proof"),
    ("11-item10", "10. ひとりの夜を、罰みたいに\n過ごさない。", "a night alone is not a punishment"),
]


def render_item(name, title, english):
    img = prepare(name)
    d = ImageDraw.Draw(img)
    title_size = 43 if name == "05-item04" else 48
    title_y = 325 if name == "05-item04" else 345
    centered(d, title, title_y, font(SERIF_JP, title_size), spacing=13)
    rule_y = 505 if name == "05-item04" else 525
    line(d, (395, rule_y, 685, rule_y), fill=(116, 109, 101, 220), width=1)
    centered(d, english, rule_y + 32, font(SERIF_EN, 28), spacing=3)

    if name == "05-item04":
        # The card is a required part of this slide's device composition.
        d.rounded_rectangle((205 * S, 665 * S, 875 * S, 950 * S), radius=2 * S, outline=(116, 109, 101, 220), width=1 * S)
        centered(d, "ひとりでいられる力は、", 725, font(SERIF_JP, 37))
        centered(d, "愛する力の中心にある。", 785, font(SERIF_JP, 37))
        centered(d, "— ベル・フックス", 848, font(SERIF_JP, 29))
        centered(d, "寝る前はWords for Meで一枚だけ引いてる。", 1038, font(SERIF_JP, 21))
        centered(d, "今日はこれだった。", 1074, font(SERIF_JP, 21))

    img.resize((W, H), Image.Resampling.LANCZOS).convert("RGB").save(OUT / f"{name}.png", optimize=True)


def render_closing():
    name = "12-closing"
    img = prepare(name)
    d = ImageDraw.Draw(img)
    centered(d, "今日の言葉", 430, font(SERIF_JP, 28))
    d.rectangle((205 * S, 505 * S, 875 * S, 865 * S), outline=(116, 109, 101, 220), width=1 * S)
    centered(d, "一緒にいることの中にも、", 615, font(SERIF_JP, 40))
    centered(d, "ちゃんと余白を残しなさい。", 680, font(SERIF_JP, 40))
    centered(d, "— カリール・ジブラン", 750, font(SERIF_JP, 30))
    d.text((108 * S, 1210 * S), "Words For Me", font=font(SERIF_EN, 18), fill=(63, 60, 56, 92), anchor="la")
    img.resize((W, H), Image.Resampling.LANCZOS).convert("RGB").save(OUT / "12-closing.png", optimize=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    render_cover()
    for name, title, english in ITEMS:
        render_item(name, title, english)
    render_closing()


if __name__ == "__main__":
    main()
