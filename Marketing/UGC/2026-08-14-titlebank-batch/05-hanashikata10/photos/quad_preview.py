from PIL import Image, ImageDraw

src = Image.open("06-bed-wfm-v1.png").convert("RGB")
draw = ImageDraw.Draw(src)
quad = [(700, 1070), (925, 1150), (700, 1450), (535, 1360)]
draw.line(quad + [quad[0]], fill=(234, 163, 161), width=6, joint="curve")
for index, (x, y) in enumerate(quad):
    draw.ellipse((x - 10, y - 10, x + 10, y + 10), fill=(234, 163, 161))
    draw.text((x + 12, y - 28), str(index + 1), fill=(234, 163, 161))
src.save("06-phone-quad-preview.png")
