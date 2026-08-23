from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance

ROOT = Path('/Users/mac2-mayu/Quote-app/Marketing/UGC/2026-08-13-kodomo-sodatte-wakatta')
SRC = ROOT / 'generated/background-imagegen-source.png'
OUT = ROOT / 'slides'
PREVIEW = ROOT / 'preview/contact-sheet.jpg'
W, H = 1080, 1920

MINCHO = '/System/Library/Fonts/ヒラギノ明朝 ProN.ttc'
GOTHIC = '/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc'
GOTHIC_BOLD = '/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc'
CHARCOAL = (73, 61, 54, 255)
MUTED = (101, 87, 77, 255)
ACCENT = (157, 103, 89, 255)
PAPER = (255, 250, 242, 255)


def f(kind, size):
    if kind == 'title':
        return ImageFont.truetype(MINCHO, size, index=2)
    if kind == 'mincho':
        return ImageFont.truetype(MINCHO, size, index=0)
    if kind == 'bold':
        return ImageFont.truetype(GOTHIC_BOLD, size)
    return ImageFont.truetype(GOTHIC, size)


def background():
    im = Image.open(SRC).convert('RGB').resize((W, H), Image.Resampling.LANCZOS)
    im = ImageEnhance.Color(im).enhance(0.90)
    # Slightly deepen the perimeter while keeping the center light for text.
    shade = Image.new('L', (W, H), 0)
    sd = ImageDraw.Draw(shade)
    sd.rectangle((0, 0, W, H), fill=18)
    shade = shade.filter(ImageFilter.GaussianBlur(180))
    dark = Image.new('RGBA', (W, H), (60, 45, 37, 255))
    dark.putalpha(shade)
    im = im.convert('RGBA')
    im.alpha_composite(dark)
    return im


def text_width(draw, text, font, tracking=0):
    return draw.textlength(text, font=font) + max(0, len(text)-1) * tracking


def draw_tracked(draw, xy, text, font, fill, tracking=0, anchor=None):
    x, y = xy
    if anchor == 'mm':
        x -= text_width(draw, text, font, tracking) / 2
    for ch in text:
        draw.text((x, y), ch, font=font, fill=fill)
        x += draw.textlength(ch, font=font) + tracking


def wrap_lines(draw, text, font, max_width):
    lines, current = [], ''
    for ch in text:
        candidate = current + ch
        if current and draw.textlength(candidate, font=font) > max_width:
            lines.append(current)
            current = ch
        else:
            current = candidate
    if current:
        lines.append(current)
    return lines


def add_veil(im, box=(62, 250, 1018, 1700), alpha=42):
    veil = Image.new('RGBA', (W, H), (255, 250, 242, 0))
    vd = ImageDraw.Draw(veil)
    vd.rounded_rectangle(box, radius=46, fill=(255, 250, 242, alpha))
    im.alpha_composite(veil.filter(ImageFilter.GaussianBlur(1)))


def add_header(draw, number=None):
    if number:
        draw_tracked(draw, (92, 112), number, f('mincho', 48), ACCENT, 6)
        draw.line((92, 190, 228, 190), fill=ACCENT, width=2)
        draw.text((92, 204), '子供が育ってわかったこと', font=f('body', 25), fill=MUTED)


def add_body_slide(idx, title, body):
    im = background()
    add_veil(im, alpha=30)
    d = ImageDraw.Draw(im)
    add_header(d, f'{idx:02d}')
    title_font = f('title', 72)
    title_lines = wrap_lines(d, title, title_font, 870)
    y = 390
    for line in title_lines:
        d.text((92, y), line, font=title_font, fill=CHARCOAL)
        y += 104
    d.line((92, y + 18, 300, y + 18), fill=ACCENT, width=3)
    body_font = f('body', 41)
    body_lines = []
    for paragraph in body:
        body_lines.extend(wrap_lines(d, paragraph, body_font, 875))
        body_lines.append('')
    if body_lines and body_lines[-1] == '':
        body_lines.pop()
    y = 1130 if len(body_lines) <= 6 else 1010
    for line in body_lines:
        if line == '':
            y += 28
        else:
            d.text((92, y), line, font=body_font, fill=MUTED)
            y += 70
    d.text((92, 1790), 'Words For Me', font=f('mincho', 28), fill=ACCENT)
    out = OUT / f'{idx+1:02d}.png'
    im.convert('RGB').save(out, 'PNG', optimize=True)
    return out


def cover():
    im = background()
    add_veil(im, box=(62, 480, 1018, 1480), alpha=44)
    d = ImageDraw.Draw(im)
    d.text((92, 565), 'Words For Me', font=f('mincho', 34), fill=ACCENT)
    d.line((92, 650, 294, 650), fill=ACCENT, width=3)
    title_font = f('title', 94)
    lines = ['子供が育って', 'わかったこと', '7選']
    y = 790
    for line in lines:
        draw_tracked(d, ('center' if False else W/2, y), line, title_font, CHARCOAL, 7, anchor='mm')
        y += 142
    d.text((92, 1425), '母親の話から始まって、', font=f('body', 38), fill=MUTED)
    d.text((92, 1495), '最後は自分の人生の話になる。', font=f('body', 38), fill=MUTED)
    out = OUT / '01.png'
    im.convert('RGB').save(out, 'PNG', optimize=True)
    return out


def wfm_slide():
    im = background()
    add_veil(im, alpha=38)
    d = ImageDraw.Draw(im)
    add_header(d, '06')
    title_font = f('title', 72)
    y = 390
    for line in ['子供に言いたい言葉を、', 'まず自分のために残していい。']:
        d.text((92, y), line, font=title_font, fill=CHARCOAL)
        y += 104
    d.line((92, y + 18, 300, y + 18), fill=ACCENT, width=3)
    body_font = f('body', 39)
    body = ['ある夜、Words For Meを開いて、', '出てきた言葉を保存した。', '', 'メモには、こう書いた。']
    y = 1040
    for line in body:
        if line:
            d.text((92, y), line, font=body_font, fill=MUTED)
        y += 68 if line else 28
    quote_box = (92, 1370, 988, 1610)
    d.rounded_rectangle(quote_box, radius=26, fill=(255, 250, 242, 178), outline=(157,103,89,170), width=2)
    quote_font = f('mincho', 38)
    d.text((130, 1435), 'この言葉を子供に渡したいと思った。', font=quote_font, fill=CHARCOAL)
    d.text((130, 1505), 'でも今日は、私が読むために残す。', font=quote_font, fill=CHARCOAL)
    d.text((92, 1790), 'Words For Me', font=f('mincho', 28), fill=ACCENT)
    out = OUT / '07.png'
    im.convert('RGB').save(out, 'PNG', optimize=True)
    return out


def close():
    im = background()
    add_veil(im, box=(62, 610, 1018, 1390), alpha=46)
    d = ImageDraw.Draw(im)
    d.text((92, 700), '今日の言葉', font=f('mincho', 34), fill=ACCENT)
    d.line((92, 780, 270, 780), fill=ACCENT, width=3)
    quote_font = f('title', 58)
    lines = ['人生は、固まった', '完成品ではなく、', 'なっていく途中にあるもの。']
    y = 870
    for line in lines:
        draw_tracked(d, (W/2, y), line, quote_font, CHARCOAL, 3, anchor='mm')
        y += 104
    draw_tracked(d, (W/2, 1245), '— アナイス・ニン', f('body', 34), ACCENT, 3, anchor='mm')
    d.text((92, 1790), 'Words For Me', font=f('mincho', 28), fill=ACCENT)
    out = OUT / '09.png'
    im.convert('RGB').save(out, 'PNG', optimize=True)
    return out


def make_contact():
    imgs = [Image.open(OUT / f'{i:02d}.png').resize((216, 384), Image.Resampling.LANCZOS) for i in range(1, 10)]
    sheet = Image.new('RGB', (216*3, 384*3), (237, 229, 220))
    for i, im in enumerate(imgs):
        sheet.paste(im, ((i%3)*216, (i//3)*384))
    sheet.save(PREVIEW, quality=92)


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    cover()
    slides = [
        ('子供の予定を確認しない朝が、最初は少し落ち着かなかった。', ['学校の時間割も、部活の予定も、帰宅時間もない。', '自由になったはずなのに、朝、何をすればいいのか分からない日があった。']),
        ('夕飯を待つ相手がいなくても、夕飯は自分のために作っていい。', ['家族の好みに合わせることが、いつの間にか当たり前になっていた。', '自分が食べたいものを、自分の分だけ作る日があってもよかった。']),
        ('子供の機嫌は、私の母親としての点数ではなかった。', ['元気なら安心して、落ち込んでいれば自分を責めていた。', 'でも、子供の人生は子供のものだった。']),
        ('部屋が静かなのは、寂しいだけではなかった。', ['音のない時間に、昔は聞こえなかった自分の考えが聞こえた。', '何を食べたいか。どこへ行きたいか。何をもうやめたいか。']),
        ('子供から相談が来ても、すぐ答えなくていい。', ['先回りして解決することより、話を最後まで聞くことの方が大事な日がある。', '親でいることと、全部を引き受けることは同じではなかった。']),
    ]
    for idx, (title, body) in enumerate(slides, start=1):
        add_body_slide(idx, title, body)
    wfm_slide()
    add_body_slide(7, '母親ではない時間も、私の人生の一部だった。', ['子供が育ったから、私の役目がなくなったわけではない。', 'これから何に時間を使うかを、私が選び直せるようになった。'])
    close()
    make_contact()
    print('created', len(list(OUT.glob('*.png'))), 'slides')
