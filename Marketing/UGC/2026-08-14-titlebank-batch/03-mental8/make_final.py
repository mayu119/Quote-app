from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import numpy as np


ROOT = Path(__file__).resolve().parent
PHOTOS = ROOT / "photos"
SCREENSHOT = Path("/Users/mac2-mayu/Quote-app/スクショ/アプリスクショ/深く知る.png")
OUT_SIZE = (1080, 1920)
MINCHO = "/System/Library/Fonts/ヒラギノ明朝 ProN.ttc"
AUTHOR = "Seneca（セネカ）"
AUTHOR_FONT = ImageFont.truetype(MINCHO, 32, index=0)
AUTHOR_COLOR = (234, 163, 161, 255)
AUTHOR_TOP = 1075


SOURCES = {
    "01-cover.png": "01-cover-v3.png",
    "02-replies.png": "02-replies-v1.png",
    "03-one-task.png": "03-one-task-v1.png",
    "04-light-off.png": "04-light-off-v1.png",
    "05-rewrite.png": "05-rewrite-v1.png",
    "06-bedtime.png": "06-bed-phone-v1.png",
    "07-tomorrow-notes.png": "07-night-desk-v1.png",
    "08-quote.png": "08-quote-v2.png",
}


def homography_coefficients(src_points, dst_points):
    """Return Pillow's inverse perspective coefficients: destination -> source."""
    rows = []
    values = []
    for (x, y), (u, v) in zip(dst_points, src_points):
        rows.append([x, y, 1, 0, 0, 0, -u * x, -u * y])
        values.append(u)
        rows.append([0, 0, 0, x, y, 1, -v * x, -v * y])
        values.append(v)
    solution = np.linalg.solve(np.asarray(rows, dtype=float), np.asarray(values, dtype=float))
    return tuple(float(value) for value in solution)


def add_rose_cast(image):
    # The design spec calls for a barely visible dusty-rose cast across the photo.
    veil = Image.new("RGBA", image.size, (234, 163, 161, 15))
    return Image.alpha_composite(image.convert("RGBA"), veil)


def composite_home_screen(background):
    """Place the immutable home screenshot only inside the generated phone screen."""
    screenshot = Image.open(SCREENSHOT).convert("RGBA")
    sw, sh = screenshot.size
    bw, bh = background.size

    # Corners are measured on the 941x1672 generated source. They trace the
    # inner black screen, leaving the generated bezel, hand, and warm reflections.
    screen_quad = [
        (506.0, 991.0),   # top-left
        (694.0, 960.0),   # top-right
        (817.0, 1417.0),  # bottom-right
        (613.0, 1458.0),  # bottom-left
    ]
    source_rect = [(0.0, 0.0), (sw - 1.0, 0.0), (sw - 1.0, sh - 1.0), (0.0, sh - 1.0)]
    coeffs = homography_coefficients(source_rect, screen_quad)

    warped = screenshot.transform(
        background.size,
        Image.Transform.PERSPECTIVE,
        coeffs,
        resample=Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    )

    # Preserve the rounded corners of the physical screen while keeping the
    # supplied screenshot itself unchanged inside the mask.
    source_mask = Image.new("L", screenshot.size, 0)
    mask_draw = ImageDraw.Draw(source_mask)
    radius = int(min(sw, sh) * 0.035)
    mask_draw.rounded_rectangle((0, 0, sw - 1, sh - 1), radius=radius, fill=255)
    warped_mask = source_mask.transform(
        background.size,
        Image.Transform.PERSPECTIVE,
        coeffs,
        resample=Image.Resampling.BICUBIC,
        fillcolor=0,
    )
    warped.putalpha(warped_mask)
    return Image.alpha_composite(background.convert("RGBA"), warped)


def add_author_caption(image):
    draw = ImageDraw.Draw(image)
    draw.text(
        (OUT_SIZE[0] // 2, AUTHOR_TOP),
        AUTHOR,
        font=AUTHOR_FONT,
        fill=AUTHOR_COLOR,
        anchor="mt",
    )
    return image


def render_slide(output_name, source_name):
    source = Image.open(PHOTOS / source_name).convert("RGBA")
    # Generate at the tool's native 941x1672, apply the shared photo cast,
    # then resize once to the required final canvas.
    source = add_rose_cast(source)
    if output_name == "06-bedtime.png":
        source = composite_home_screen(source)
    final = source.resize(OUT_SIZE, Image.Resampling.LANCZOS)
    if output_name == "08-quote.png":
        final = add_author_caption(final)
    final.save(ROOT / output_name, format="PNG", optimize=True)


def main():
    for output_name, source_name in SOURCES.items():
        render_slide(output_name, source_name)


if __name__ == "__main__":
    main()
