from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path('/Users/mac2-mayu/Quote-app/Marketing/UGC/2026-08-13-kodomo-sodatte-wakatta')
OUT = ROOT / 'slides-solid-gray'
PREVIEW = ROOT / 'preview/solid-gray-contact-sheet.jpg'
W, H = 1080, 1920
BG = (108, 108, 108)  # flat neutral gray
WHITE = (255, 255, 255)

MINCHO = '/System/Library/Fonts/ヒラギノ明朝 ProN.ttc'
GOTHIC = '/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc'


def font(kind, size):
    if kind == 'title':
        return ImageFont.truetype(MINCHO, size, index=2)
    if kind == 'body-mincho':
        return ImageFont.truetype(MINCHO, size, index=0)
    return ImageFont.truetype(GOTHIC, size)


def width(draw, text, f):
    return draw.textlength(text, font=f)


def wrap(draw, text, f, max_width):
    lines, current = [], ''
    for ch in text:
        candidate = current + ch
        if current and width(draw, candidate, f) > max_width:
            lines.append(current)
            current = ch
        else:
            current = candidate
    if current:
        lines.append(current)
    return lines


def fit(draw, text, kind, start, max_width, minimum=28):
    size = start
    while size > minimum and width(draw, text, font(kind, size)) > max_width:
        size -= 2
    return font(kind, size), size


def canvas():
    return Image.new('RGB', (W, H), BG)


def centered(draw, text, y, f, fill=WHITE):
    draw.text((W / 2, y), text, font=f, fill=fill, anchor='ma')


def centered_lines(draw, lines, y, f, gap):
    for line in lines:
        centered(draw, line, y, f)
        y += gap
    return y


def cover():
    im = canvas(); d = ImageDraw.Draw(im)
    title_f = font('title', 94)
    y = 675
    y = centered_lines(d, ['子供が育って', 'わかったこと', '7選'], y, title_f, 142)
    out = OUT / '01.png'; im.save(out, 'PNG', optimize=True); return out


def content_slide(num, title, paragraphs, out_name):
    im = canvas(); d = ImageDraw.Draw(im)
    num_f = font('body-mincho', 48)
    centered(d, f'{num:02d}', 420, num_f)
    title_f, title_size = fit(d, title, 'title', 78, 900, 54)
    title_lines = wrap(d, title, title_f, 900)
    y = 565
    y = centered_lines(d, title_lines, y, title_f, int(title_size * 1.35))
    body_f, body_size = fit(d, '子供が育ってわかったこと', 'body-mincho', 43, 900, 32)
    body_lines = []
    for p in paragraphs:
        body_lines.extend(wrap(d, p, body_f, 900))
        body_lines.append('')
    if body_lines and body_lines[-1] == '':
        body_lines.pop()
    total = sum((int(body_size * 1.8) if line else int(body_size * 0.9)) for line in body_lines)
    y = max(970, 1030 - total // 2)
    for line in body_lines:
        if line:
            centered(d, line, y, body_f)
            y += int(body_size * 1.8)
        else:
            y += int(body_size * 0.9)
    out = OUT / out_name; im.save(out, 'PNG', optimize=True); return out


def quote_slide():
    im = canvas(); d = ImageDraw.Draw(im)
    centered(d, '今日の言葉', 565, font('body-mincho', 42))
    qf = font('title', 66)
    lines = ['人生は、固まった', '完成品ではなく、', 'なっていく途中にあるもの。']
    centered_lines(d, lines, 780, qf, 112)
    centered(d, '— アナイス・ニン', 1190, font('body-mincho', 36))
    out = OUT / '09.png'; im.save(out, 'PNG', optimize=True); return out


def contact_sheet():
    ims = [Image.open(OUT / f'{i:02d}.png').resize((216, 384), Image.Resampling.LANCZOS) for i in range(1,10)]
    sheet = Image.new('RGB', (648, 1152), (90,90,90))
    for i, im in enumerate(ims):
        sheet.paste(im, ((i%3)*216, (i//3)*384))
    sheet.save(PREVIEW, quality=95)


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    (ROOT / 'preview').mkdir(parents=True, exist_ok=True)
    cover()
    content_slide(1, '子供の予定を確認しない朝が、最初は少し落ち着かなかった。', ['学校の時間割も、部活の予定も、帰宅時間もない。', '自由になったはずなのに、朝、何をすればいいのか分からない日があった。'], '02.png')
    content_slide(2, '夕飯を待つ相手がいなくても、夕飯は自分のために作っていい。', ['家族の好みに合わせることが、いつの間にか当たり前になっていた。', '自分が食べたいものを、自分の分だけ作る日があってもよかった。'], '03.png')
    content_slide(3, '子供の機嫌は、私の母親としての点数ではなかった。', ['元気なら安心して、落ち込んでいれば自分を責めていた。', 'でも、子供の人生は子供のものだった。'], '04.png')
    content_slide(4, '部屋が静かなのは、寂しいだけではなかった。', ['音のない時間に、昔は聞こえなかった自分の考えが聞こえた。', '何を食べたいか。どこへ行きたいか。何をもうやめたいか。'], '05.png')
    content_slide(5, '子供から相談が来ても、すぐ答えなくていい。', ['先回りして解決することより、話を最後まで聞くことの方が大事な日がある。', '親でいることと、全部を引き受けることは同じではなかった。'], '06.png')
    content_slide(6, '子供に言いたい言葉を、まず自分のために残していい。', ['ある夜、Words For Meを開いて、出てきた言葉を保存した。', 'メモには、こう書いた。', 'この言葉を子供に渡したいと思った。でも今日は、私が読むために残す。'], '07.png')
    content_slide(7, '母親ではない時間も、私の人生の一部だった。', ['子供が育ったから、私の役目がなくなったわけではない。', 'これから何に時間を使うかを、私が選び直せるようになった。'], '08.png')
    quote_slide()
    contact_sheet()
    print('created', len(list(OUT.glob('*.png'))), 'solid-gray slides')
