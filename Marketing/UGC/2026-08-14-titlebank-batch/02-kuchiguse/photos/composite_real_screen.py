from pathlib import Path
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / "photos" / "06-blank-phone-generated-v1.png"
SCREEN = ROOT.parent.parent.parent.parent / "スクショ" / "アプリスクショ" / "ホーム画面.png"
OUT = ROOT / "06-nemuru-no-mo-yotei.png"
PREVIEW = ROOT / "photos" / "06-composited-preview.png"
QUOTE_BASE = ROOT / "photos" / "07-quote-generated-v1.png"
QUOTE_OUT = ROOT / "07-quote.png"
MINCHO = "/System/Library/Fonts/ヒラギノ明朝 ProN.ttc"
ROSE = (234, 163, 161, 255)  # #EAA3A1
AUTHOR = "Ralph Waldo Emerson（ラルフ・ワルド・エマーソン）"


def homography(src_points, dst_points):
    rows = []
    for (x, y), (u, v) in zip(src_points, dst_points):
        rows.append([-x, -y, -1, 0, 0, 0, u * x, u * y, u])
        rows.append([0, 0, 0, -x, -y, -1, v * x, v * y, v])
    _, _, vt = np.linalg.svd(np.asarray(rows, dtype=float))
    matrix = vt[-1].reshape(3, 3)
    return matrix / matrix[2, 2]


def add_quote_author():
    """Re-export only the closing slide with its caption-style author line."""
    quote = Image.open(QUOTE_BASE).convert("RGBA").resize((1080, 1920), Image.Resampling.LANCZOS)
    draw = ImageDraw.Draw(quote)
    author_font = ImageFont.truetype(MINCHO, 26, index=0)
    draw.text((540, 1020), AUTHOR, font=author_font, fill=ROSE, anchor="mm")
    quote.convert("RGB").save(QUOTE_OUT, format="PNG", optimize=True)
    print(f"saved {QUOTE_OUT}")


def main():
    if sys.argv[1:] == ["--quote-author"]:
        add_quote_author()
        return

    base = Image.open(BASE).convert("RGB").resize((1080, 1920), Image.Resampling.LANCZOS).convert("RGBA")
    screenshot = Image.open(SCREEN).convert("RGBA")

    # Inner glass corners on the generated 941x1672 source, scaled to the final 1080x1920 canvas.
    sx, sy = 1080 / 941, 1920 / 1672
    screen_corners_raw = [(646, 123), (799, 139), (750, 481), (610, 455)]
    dst = [(x * sx, y * sy) for x, y in screen_corners_raw]
    sw, sh = screenshot.size
    src = [(0, 0), (sw - 1, 0), (sw - 1, sh - 1), (0, sh - 1)]

    inverse = np.linalg.inv(homography(src, dst))
    inverse /= inverse[2, 2]
    coefficients = (
        float(inverse[0, 0]), float(inverse[0, 1]), float(inverse[0, 2]),
        float(inverse[1, 0]), float(inverse[1, 1]), float(inverse[1, 2]),
        float(inverse[2, 0]), float(inverse[2, 1]),
    )

    warped = screenshot.transform(
        base.size,
        Image.Transform.PERSPECTIVE,
        coefficients,
        resample=Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    )
    mask_source = Image.new("L", screenshot.size, 255)
    mask = mask_source.transform(
        base.size,
        Image.Transform.PERSPECTIVE,
        coefficients,
        resample=Image.Resampling.BICUBIC,
        fillcolor=0,
    )
    warped.putalpha(mask)
    base.alpha_composite(warped)

    final = base.convert("RGB")
    final.save(OUT, format="PNG", optimize=True)
    final.save(PREVIEW, format="PNG", optimize=True)
    print(f"saved {OUT}")
    print(f"screen corners final: {[(round(x, 1), round(y, 1)) for x, y in dst]}")


if __name__ == "__main__":
    main()
