from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parent
image = Image.open(root / "photos/06-bed-phone-v1.png").convert("RGB")
crop = image.crop((430, 880, 900, 1600)).resize((940, 1440), Image.Resampling.NEAREST)
draw = ImageDraw.Draw(crop)
draw.rectangle((0, 0, crop.width - 1, crop.height - 1), outline=(234, 163, 161), width=4)
crop.save(root / "photos/06-phone-source-crop.png")

cover = Image.open(root / "01-cover.png").convert("RGB")
cover.crop((210, 900, 900, 1160)).resize((1380, 520), Image.Resampling.NEAREST).save(root / "photos/01-title-crop.png")
