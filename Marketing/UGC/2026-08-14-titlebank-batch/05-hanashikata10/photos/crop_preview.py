from PIL import Image, ImageDraw

src = Image.open("06-bed-wfm-v1.png")
crop = src.crop((500, 980, 941, 1672))
crop = crop.resize((762, 1180), Image.Resampling.LANCZOS)
draw = ImageDraw.Draw(crop)
for x in range(0, crop.width, 100):
    draw.line((x, 0, x, crop.height), fill=(234, 163, 161), width=1)
    draw.text((x + 4, 4), str(500 + x // 2), fill=(234, 163, 161))
for y in range(0, crop.height, 100):
    draw.line((0, y, crop.width, y), fill=(234, 163, 161), width=1)
    draw.text((4, y + 4), str(980 + y // 2), fill=(234, 163, 161))
crop.save("06-phone-crop.png")
