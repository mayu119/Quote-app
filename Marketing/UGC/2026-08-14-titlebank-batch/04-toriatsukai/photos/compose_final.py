from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parent.parent
PHOTOS = ROOT / "photos"
OUT = ROOT
SIZE = (1080, 1920)


def homography(src, dst):
    """Return H mapping four source points to four destination points."""
    rows = []
    vals = []
    for (x, y), (u, v) in zip(src, dst):
        rows.append([x, y, 1, 0, 0, 0, -u * x, -u * y])
        vals.append(u)
        rows.append([0, 0, 0, x, y, 1, -v * x, -v * y])
        vals.append(v)
    coeff = np.linalg.solve(np.asarray(rows, dtype=float), np.asarray(vals, dtype=float))
    return np.array(
        [[coeff[0], coeff[1], coeff[2]], [coeff[3], coeff[4], coeff[5]], [coeff[6], coeff[7], 1.0]],
        dtype=float,
    )


def inverse_perspective_coefficients(src_size, dst_quad):
    sw, sh = src_size
    src_quad = [(0, 0), (sw - 1, 0), (sw - 1, sh - 1), (0, sh - 1)]
    h = homography(src_quad, dst_quad)
    inv = np.linalg.inv(h)
    inv /= inv[2, 2]
    return tuple(
        float(v)
        for v in (inv[0, 0], inv[0, 1], inv[0, 2], inv[1, 0], inv[1, 1], inv[1, 2], inv[2, 0], inv[2, 1])
    )


def upscale(path):
    return Image.open(path).convert("RGB").resize(SIZE, Image.Resampling.LANCZOS)


selected = {
    "01-cover.png": "01-cover-v1.png",
    "02-reply.png": "02-item01-v1.png",
    "03-warm-drink.png": "03-item02-v1.png",
    "04-one-thing.png": "04-item03-v1.png",
    "05-close-screen.png": "05-item04-v2.png",
    "06-one-quote.png": "06-item05-v1.png",
    "07-closing-quote.png": "07-closing-v1.png",
}


for final_name, source_name in selected.items():
    base = upscale(PHOTOS / source_name)

    if final_name == "06-one-quote.png":
        # Inner glass area of the generated phone in the 941x1672 source image.
        source_quad = [(651, 190), (837, 204), (793, 623), (588, 609)]
        sx = SIZE[0] / 941.0
        sy = SIZE[1] / 1672.0
        target_quad = [(round(x * sx, 3), round(y * sy, 3)) for x, y in source_quad]

        screenshot = Image.open(Path("/Users/mac2-mayu/Quote-app/スクショ/アプリスクショ/カテゴリ.png")).convert("RGB")
        coeffs = inverse_perspective_coefficients(screenshot.size, target_quad)
        warped = screenshot.transform(SIZE, Image.Transform.PERSPECTIVE, coeffs, Image.Resampling.BICUBIC)
        mask = Image.new("L", SIZE, 0)
        ImageDraw.Draw(mask).polygon(target_quad, fill=255)
        base.paste(warped, (0, 0), mask)

    base.save(OUT / final_name, format="PNG", optimize=True)


print(f"wrote {len(selected)} final PNGs to {OUT}")
