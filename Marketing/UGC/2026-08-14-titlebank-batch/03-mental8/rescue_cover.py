from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
FINAL = ROOT / "01-cover.png"
BACKGROUND = ROOT / "photos/01-cover-pil-rescue-bg-v1.png"
FONT_PATH = "/System/Library/Fonts/ヒラギノ明朝 ProN.ttc"
CREAM = (255, 248, 242)


def main():
    image = Image.open(BACKGROUND).convert("RGB").resize((1080, 1920), Image.Resampling.LANCZOS)
    width, height = image.size

    # The new photo already has a naturally dark central floor area. Use only
    # the shared subtle full-frame veil so no panel edge or hard band appears.
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 20))
    image = Image.alpha_composite(image.convert("RGBA"), overlay).convert("RGB")

    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype(FONT_PATH, 78, index=2)

    def draw_centered_tracking(text, center_y, tracking=4):
        widths = [draw.textlength(char, font=font) for char in text]
        total = sum(widths) + tracking * (len(text) - 1)
        x = (width - total) / 2
        for char, char_width in zip(text, widths):
            draw.text((round(x), center_y), char, font=font, fill=CREAM, anchor="ma")
            x += char_width + tracking

    draw_centered_tracking("ウソみたいにメンタル", 875)
    draw_centered_tracking("安定する考え方８選", 980)
    image.save(FINAL, format="PNG", optimize=True)


if __name__ == "__main__":
    main()
