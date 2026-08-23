from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parent.parent
PHOTOS = ROOT / "photos"
OUT = ROOT
SIZE = (1080, 1920)


def normalize_photo(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA").resize(SIZE, Image.Resampling.LANCZOS)
    # The generation prompts already requested the design scrim; these light passes
    # make the batch treatment consistent without touching the generated glyphs.
    black = Image.new("RGBA", SIZE, (0, 0, 0, 20))
    rose = Image.new("RGBA", SIZE, (234, 163, 161, 15))
    image = Image.alpha_composite(image, black)
    image = Image.alpha_composite(image, rose)
    return image


def find_coeffs(destination, source):
    matrix = []
    vector = []
    for (x, y), (u, v) in zip(destination, source):
        matrix.append([x, y, 1, 0, 0, 0, -u * x, -u * y])
        matrix.append([0, 0, 0, x, y, 1, -v * x, -v * y])
        vector.extend([u, v])
    return np.linalg.solve(np.asarray(matrix, dtype=float), np.asarray(vector, dtype=float))


def paste_screenshot(background: Image.Image, screenshot_path: Path) -> Image.Image:
    # Coordinates are the visible display surface on the generated 941x1672 base,
    # then scaled to the required 1080x1920 output.
    sx = SIZE[0] / 941.0
    sy = SIZE[1] / 1672.0
    base_quad = [(700, 1070), (925, 1150), (700, 1450), (535, 1360)]
    destination = [(x * sx, y * sy) for x, y in base_quad]

    screen = Image.open(screenshot_path).convert("RGBA")
    source = [(0, 0), (screen.width - 1, 0), (screen.width - 1, screen.height - 1), (0, screen.height - 1)]
    coeffs = find_coeffs(destination, source)
    warped = screen.transform(
        SIZE,
        Image.Transform.PERSPECTIVE,
        tuple(coeffs),
        resample=Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    )
    # Keep the generated hand in front of the real screen, as it is in the
    # photograph. The mask is restricted to the display quadrilateral and only
    # catches warm, skin-like pixels; the supplied UI artwork itself is not
    # recolored or redrawn.
    bg_rgb = np.asarray(background.convert("RGB"))
    red, green, blue = [bg_rgb[:, :, channel].astype(np.int16) for channel in range(3)]
    skin = (red > 42) & ((red - green) > 22) & ((green - blue) > 8)
    occlusion = Image.new("L", SIZE, 0)
    occlusion_draw = Image.new("L", SIZE, 0)
    ImageDraw.Draw(occlusion_draw).polygon(destination, fill=255)
    polygon_mask = np.asarray(occlusion_draw) > 0
    occlusion_pixels = skin & polygon_mask
    alpha = np.asarray(warped.getchannel("A")).copy()
    alpha[occlusion_pixels] = 0
    warped.putalpha(Image.fromarray(alpha.astype(np.uint8), mode="L"))
    return Image.alpha_composite(background, warped)


slides = [
    ("01-title-v1.png", "01-title.png"),
    ("02-dining-v1.png", "02-hanashikata-01-02.png"),
    ("03-living-v1.png", "03-hanashikata-03-04.png"),
    ("04-kitchen-v2.png", "04-hanashikata-05-06.png"),
    ("05-train-v1.png", "05-hanashikata-07-08.png"),
    ("06-bed-wfm-v1.png", "06-hanashikata-09-10.png"),
    ("07-quote-v2.png", "07-quote.png"),
]

for source_name, output_name in slides:
    background = normalize_photo(PHOTOS / source_name)
    if output_name == "06-hanashikata-09-10.png":
        final = paste_screenshot(
            background,
            ROOT.parent.parent.parent.parent / "スクショ/アプリスクショ/お気に入り理由メモ.png",
        )
    else:
        final = background
    final.convert("RGB").save(OUT / output_name, format="PNG", optimize=True)
