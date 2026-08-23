"""表紙(1枚目)の横書き案。

現行は「英文小見出し + 縦書きタイトル + サブコピー1行」の3要素。
Mayu指摘(2026-08-21): タイトルは横書き、タイトル以外の文字は要らない。

縦書きは H*0.42 の箱に最長12字を詰めるため字送りが約61pxまで落ちる。
横書きにすると同じ面積で70px超が取れるので、要素を削るほど字が大きくなる。
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '_formats'))
import wfm_render as R  # noqa: E402

HERE = Path(__file__).resolve().parent
W, H = R.W, R.H
LINEART = HERE / 'lineart' / '01-cover.png'

TITLE = ['既読のままの画面を、', 'まだスワイプできない人へ']
EN = 'still cannot swipe away'
SUB = '通知が来るたび、違う名前だった。'


def fit_horizontal(lines, box_w, fs_max=96, fs_min=48, track_ratio=0.08):
    """最長行が箱に収まる最大の字送りを返す。"""
    d = ImageDraw.Draw(Image.new('RGB', (10, 10)))
    for fs in range(fs_max, fs_min - 1, -2):
        f = R.mincho(fs, 6)
        tr = fs * track_ratio
        widest = max(sum(d.textlength(c, font=f) for c in ln) + tr * (len(ln) - 1)
                     for ln in lines)
        if widest <= box_w:
            return fs, tr
    return fs_min, fs_min * track_ratio


def title_block(im, lines, cy, box_w=W * 0.84, fs_max=96, leading=1.52):
    """横書きタイトル。行は中央揃え、字間は明朝の見出しらしく少し開ける。"""
    d = ImageDraw.Draw(im)
    fs, tr = fit_horizontal(lines, box_w, fs_max=fs_max)
    f = R.mincho(fs, 6)
    lead = fs * leading
    y = cy - lead * (len(lines) - 1) / 2
    for ln in lines:
        R.tracked(d, W / 2, y, ln, f, R.INK, tr)
        y += lead
    return fs, cy + lead * (len(lines) - 1) / 2 + fs / 2


def base(dy=0):
    """線画を地にする。dy>0 で上へ送る。

    R.lineart() は下揃えで敷くため、この線画は机が y=0.73〜0.98H に来る。
    TikTokのキャプション/ユーザー名が乗る帯と重なるので、型3の勝ち構図
    （線画=上 / タイトル=中下 / 下25%は空ける）へ寄せる案では上へ送る。
    """
    im = R.lineart(LINEART) if LINEART.exists() else R.paper()
    if not dy:
        return im
    out = R.paper()
    out.paste(im.crop((0, dy, W, H)), (0, 0))
    return out


def variant_a():
    """タイトルだけ。指摘どおり文字を最小にした案。"""
    im = base()
    title_block(im, TITLE, H * 0.285)
    return im


def variant_b():
    """タイトル + 罫 + サブコピー1行（型3の表紙と同じ組み方）。"""
    im = base()
    fs, bottom = title_block(im, TITLE, H * 0.255)
    d = ImageDraw.Draw(im)
    R.hairline(d, bottom + fs * 0.62, 300)
    d.text((W / 2, bottom + fs * 1.30), SUB, font=R.mincho(40), fill=R.INK, anchor='mm')
    return im


def variant_c():
    """英文小見出しだけ残してサブコピーを落とした案。"""
    im = base()
    d = ImageDraw.Draw(im)
    R.en_sub(d, H * 0.105, EN, 28, 10)
    title_block(im, TITLE, H * 0.295)
    return im


ART_UP = 1090   # 机が 0.15〜0.42H に来る送り量


def variant_d():
    """線画を上へ / 横書きタイトルを中下へ。型3の勝ち構図と同じ配置。"""
    im = base(ART_UP)
    title_block(im, TITLE, H * 0.585, box_w=W * 0.88)
    return im


def variant_e():
    """D + 罫 + サブコピー1行。型3の表紙と要素まで揃えた案。"""
    im = base(ART_UP)
    fs, bottom = title_block(im, TITLE, H * 0.555, box_w=W * 0.88)
    d = ImageDraw.Draw(im)
    R.hairline(d, bottom + fs * 0.66, 300)
    d.text((W / 2, bottom + fs * 1.36), SUB, font=R.mincho(40), fill=R.INK, anchor='mm')
    return im


def sheet(items, path, cols=3, scale=0.30):
    tw, th = int(W * scale), int(H * scale)
    gap, pad, cap = 18, 18, 52
    rows = -(-len(items) // cols)
    sh = Image.new('RGB', (pad * 2 + cols * tw + (cols - 1) * gap,
                           pad * 2 + rows * (th + cap) + (rows - 1) * gap), (28, 28, 28))
    d = ImageDraw.Draw(sh)
    f = R.serif(28)
    for i, (label, im) in enumerate(items):
        x = pad + (i % cols) * (tw + gap)
        y = pad + (i // cols) * (th + cap + gap)
        sh.paste(im.resize((tw, th), Image.Resampling.LANCZOS), (x, y))
        d.text((x + tw / 2, y + th + cap / 2), label, font=f, fill=(232, 228, 222), anchor='mm')
    sh.save(path)
    return path


if __name__ == '__main__':
    out = HERE / 'cover-variants'
    out.mkdir(exist_ok=True)
    current = Image.open(HERE / 'slides' / '01-cover.png').convert('RGB')
    items = [
        ('current  vertical+EN+sub', current),
        ('A  title only', variant_a()),
        ('B  title+rule+sub', variant_b()),
        ('C  EN+title', variant_c()),
        ('D  art up / title only', variant_d()),
        ('E  art up / title+sub', variant_e()),
    ]
    for label, im in items[1:]:
        im.save(out / f'{label.split()[0]}.png')
    sheet(items, HERE / 'cover-variants.png', cols=6, scale=0.22)
    print('done ->', HERE / 'cover-variants.png')
