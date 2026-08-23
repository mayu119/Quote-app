from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parent.parent
PHOTOS = ROOT / "photos"
W, H = 1080, 1920


def perspective_coefficients(src_points, dst_points):
    """Return Pillow PERSPECTIVE coefficients mapping destination -> source."""
    rows = []
    rhs = []
    for (xd, yd), (xs, ys) in zip(dst_points, src_points):
        rows.append([xd, yd, 1, 0, 0, 0, -xs * xd, -xs * yd])
        rhs.append(xs)
        rows.append([0, 0, 0, xd, yd, 1, -ys * xd, -ys * yd])
        rhs.append(ys)
    coeffs = np.linalg.solve(np.asarray(rows, dtype=float), np.asarray(rhs, dtype=float))
    return tuple(float(v) for v in coeffs)


def resize_final(source: Path, target: Path):
    image = Image.open(source).convert("RGB")
    image = image.resize((W, H), Image.Resampling.LANCZOS)
    image.save(target, format="PNG", optimize=True)


def compose_real_screen(source: Path, screenshot: Path, target: Path):
    base = Image.open(source).convert("RGB").resize((W, H), Image.Resampling.LANCZOS)
    screen = Image.open(screenshot).convert("RGB")

    # Inner display corners measured on the generated gen3 frame at its native 941x1672.
    # Order: top-left, top-right, bottom-right, bottom-left.
    native_dest = [(658, 705), (838, 720), (806, 1147), (628, 1132)]
    sx, sy = W / 941.0, H / 1672.0
    dest = [(x * sx, y * sy) for x, y in native_dest]
    src = [(0, 0), (screen.width - 1, 0), (screen.width - 1, screen.height - 1), (0, screen.height - 1)]

    coeffs = perspective_coefficients(src, dest)
    warped = screen.transform((W, H), Image.Transform.PERSPECTIVE, coeffs, Image.Resampling.BICUBIC)

    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).polygon(dest, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(radius=0.55))

    composed = Image.composite(warped, base, mask)
    composed.save(target, format="PNG", optimize=True)


finals = [
    ("01-title.png", "01-cover-gen1.png"),
    ("02-line-stamp.png", "02-item1-gen1.png"),
    ("03-short-reply.png", "03-item2-gen1.png"),
    ("04-replay-talk.png", "04-item3-gen1.png"),
    ("05-work-mistake.png", "05-item4-gen1.png"),
    ("07-release-quote.png", "07-closing-gen1.png"),
]

for target_name, source_name in finals:
    resize_final(PHOTOS / source_name, ROOT / target_name)

compose_real_screen(
    PHOTOS / "06-item5-blank-gen3.png",
    Path("/Users/mac2-mayu/Quote-app/スクショ/アプリスクショ/お気に入り.png"),
    ROOT / "06-words-before-sleep.png",
)
