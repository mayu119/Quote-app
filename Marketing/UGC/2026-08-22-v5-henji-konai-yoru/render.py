"""v5a-daily-draw デッキ生成（改訂版）

視覚言語を2層に分ける。
  - 枠(表紙・導入・解説・締め): 現行 v3-lineart の生成りオフホワイト＋墨色明朝
    ＋ gpt-image-2 で生成した一本線イラスト（`lineart/`）。現行フォーマットと同じ作り方。
  - カード(名言・棚): アプリ実物のカード。ここは画像生成を使わず、
    `Assets.xcassets/Backgrounds` の実アセットと `quotes_full.json` の実データのみ。

線画は `wfm_render.lineart()` で PAPER/INK の2値へ正規化してから敷くので、
生成物の地色ブレが枠スライドの色と食い違わない。
出力は 1080x1920（現行バッチの export と同じ）。
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / '_formats'))
import wfm_render as R  # noqa: E402

HERE = Path(__file__).resolve().parent
W, H = R.W, R.H


LINEART = HERE / 'lineart'


def base(art=None, dy=0):
    """線画があればそれを地にする。無ければ無地。"""
    p = LINEART / art if art else None
    return R.lineart(p, dy=dy) if p and p.exists() else R.paper()


SAFE_BOTTOM = 0.72   # これより下に線画を出さない（TikTokのキャプション帯）


def art_lift(art, top=None, bottom=SAFE_BOTTOM):
    """線画の送り量。top 指定ならインク上端を、無指定なら下端を基準にする。

    この線画群は下揃えのままだと 0.65〜0.95H に来て、TikTokの
    キャプション／ユーザー名が乗る下25%と重なる。
    """
    lo, hi = R.ink_bounds(R.lineart(LINEART / art))
    dy = lo - H * top if top is not None else hi - H * bottom
    return max(0, int(dy))


def cover(title_lines, art=None):
    """表紙。タイトルは横書き、文字はタイトルだけ。

    型3の勝ち構図に合わせ、線画=上／タイトル=中下／下25%は空ける
    （2026-08-21 Mayu判断: 横書き・タイトル以外の文字は置かない）。
    """
    im = base(art, dy=art_lift(art, top=0.12) if art else 0)
    R.h_title(im, title_lines, H * 0.585, box_w=W * 0.88)
    return im


def round_corners(im, r):
    im = im.convert('RGBA')
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.width - 1, im.height - 1), radius=r, fill=255)
    im.putalpha(mask)
    return im


def note(label, body, en=None, accent=False, art=None):
    """オフホワイトの本文スライド。"""
    im = base(art, dy=art_lift(art) if art else 0)
    d = ImageDraw.Draw(im)
    if label:
        R.tracked(d, W / 2, H * 0.175, label, R.mincho(30), R.RULE, 14)
        R.hairline(d, H * 0.200, 80)
    f = R.mincho(52, 6 if accent else 3)
    lines = R.wrap(d, body, f, W * 0.76)
    R.stack(d, H * 0.42, lines, f, R.INK, 96)
    # 線画は下1/3に来るので、英文小見出しは表紙と同じく天に置く。
    if en:
        R.en_sub(d, H * 0.085, en, 27, 9)
    return im


def shelf_sub(ids):
    """棚の説明行。`WeeklyShelfView.swift:17` と同じ文。"""
    cats = {R.BY_ID[i]['category'] for i in ids}
    assert len(cats) == 1, f'棚の説明行は単一カテゴリー前提。混在: {cats}'
    return f'今週は「{CATEGORY_JA[cats.pop()]}」の言葉を{len(ids)}枚集めました。'


def shelf(ids, heading='私の棚', en='what stayed this week'):
    """今週の棚。**構造は実画面、視覚言語は枠スライドと同じ**。

    旧版は実物カードを4枚並べていたが、アプリにそんな画面は無い
    （`WeeklyShelfView.swift:20-26` は punchline の行リスト）。
    かといって iOS の角ゴ＋角丸パネル＋ダークで描くと、この1枚だけ
    生成りオフホワイト＋明朝のデッキから浮く。行リストという構造だけ
    実画面から採り、色と書体は枠に合わせる。
    """
    im = R.paper()
    d = ImageDraw.Draw(im)
    R.tracked(d, W / 2, H * 0.175, heading, R.mincho(34, 6), R.INK, 16)
    R.hairline(d, H * 0.200, 90)

    f_row = R.mincho(48)
    lead = f_row.size * 1.44
    gap = H * 0.052

    # 説明行は1行に収める。折ると「3枚集めま／した。」のように語中で割れる。
    sub = shelf_sub(ids)
    for size in range(36, 25, -1):
        f_sub = R.mincho(size)
        if d.textlength(sub, font=f_sub) <= W * 0.86:
            break
    rows = [R.wrap(d, R.BY_ID[q]['punchline'], f_row, W * 0.74) for q in ids]
    y = H * 0.275

    d.text((W / 2, y), sub, font=f_sub, fill=R.RULE, anchor='mm')
    y += f_sub.size * 1.6
    for i, r in enumerate(rows):
        y += gap
        if i:
            R.hairline(d, y - gap / 2, 60)
        for ln in r:
            d.text((W / 2, y), ln, font=f_row, fill=R.INK, anchor='mm')
            y += lead
    assert y <= H * SAFE_BOTTOM, f'棚が下の帯へ届いている: {y / H:.2f}H'
    R.en_sub(d, H * 0.085, en, 27, 9)
    return im


def shelf_app_ui(ids, heading='私の棚'):
    """棚をアプリのUI言語（ダーク＋角ゴ＋角丸パネル）で描いた版。

    実画面には忠実だが、デッキの中で1枚だけ別世界になる。比較用に残す。
    """
    im = Image.new('RGB', (W, H), R.APP_PAGE)
    d = ImageDraw.Draw(im)
    pad = R.pt(R.SPACE['l'])
    inner = R.pt(R.SPACE['m'])
    gap = R.pt(R.SPACE['l'])
    radius = R.pt(R.RADIUS['m'])

    f_head = R.mincho(int(R.pt(34)), 6)          # .system(size:34, weight:.bold, design:.serif)
    f_sub = R.gothic(int(R.pt(17)), 3)           # .body

    sub_lines = R.wrap(d, shelf_sub(ids), f_sub, W - pad * 2)
    head_h = f_head.size * 1.3 + gap + len(sub_lines) * f_sub.size * 1.6

    # 実画面はスクロールできるがスライドはできない。行が下の帯（TikTokの
    # キャプション）へ届くなら .title3 から一段ずつ落として収める。
    top, bottom = H * 0.09, H * SAFE_BOTTOM
    for size_pt in range(20, 14, -1):
        f_row = R.gothic(int(R.pt(size_pt)), 5)  # .title3.weight(.medium)
        lead_row = f_row.size * 1.52
        rows = [(ln, len(ln) * lead_row + inner * 2) for ln in
                (R.wrap(d, R.BY_ID[q]['punchline'], f_row, W - pad * 2 - inner * 2) for q in ids)]
        total = head_h + gap + sum(h for _, h in rows) + gap * (len(rows) - 1)
        if top + total <= bottom:
            break
    y = top

    d.text((pad, y), heading, font=f_head, fill=R.APP_TEXT, anchor='la')
    y += f_head.size * 1.3 + gap
    for ln in sub_lines:
        d.text((pad, y), ln, font=f_sub, fill=R.APP_SUB, anchor='la')
        y += f_sub.size * 1.6
    y += gap

    for lines, h in rows:
        d.rounded_rectangle((pad, y, W - pad, y + h), radius=radius, fill=R.APP_SHEET)
        ty = y + inner
        for ln in lines:
            d.text((pad + inner, ty + lead_row / 2), ln, font=f_row, fill=R.APP_TEXT, anchor='lm')
            ty += lead_row
        y += h + gap
    return im


def closing(tagline='300枚の言葉と、それを置く棚。'):
    im = R.paper()
    d = ImageDraw.Draw(im)
    ic = Image.open(R.ICON).convert('RGB').resize((240, 240), Image.Resampling.LANCZOS)
    im.paste(round_corners(ic, 54), (int(W / 2 - 120), int(H * 0.38)), round_corners(ic, 54))
    R.tracked(d, W / 2, H * 0.53, 'Words For Me', R.serif(58), R.INK, 5)
    d.text((W / 2, H * 0.575), tagline, font=R.mincho(36), fill=R.RULE, anchor='mm')
    return im


# ---------------------------------------------------------------- デッキ定義

QUOTE_ID = 'women_original_212'
# 棚は説明行と同じカテゴリーで揃える。women_original_217 は `relationships` なので外した
# （「好きな人ができた時」の言葉として数えると実データと食い違う）。
SHELF_IDS = ['women_quote_009', 'women_quote_041']

# Quote.swift の displayTitleJa（棚の説明行に出す中カテゴリー名）
CATEGORY_JA = {
    'self_love': '自己肯定', 'positive': 'ポジティブ', 'courage': '勇気が出ない時',
    'inner_strength': '強い自分になる', 'love_crush': '好きな人ができた時',
    'family_love': '家族愛', 'for_my_child': '大切なあなたへ', 'relationships': '対人関係',
    'want_to_quit': 'もう辞めてしまいたい時', 'affirmation': 'アファメーション',
}

TITLE_LINES = ['既読のままの画面を、', 'まだスワイプできない人へ']


def build(out=HERE / 'slides', title_lines=TITLE_LINES):
    out.mkdir(parents=True, exist_ok=True)
    for f in out.glob('*.png'):
        f.unlink()
    q = R.BY_ID[QUOTE_ID]

    # 本文は観察可能な動作・具体物・数字で書く（状態語・心理語を置かない）。
    deck = [
        ('01-cover.png', cover(title_lines, art='01-cover.png')),
        ('02-intro.png', note(None, '相手の名前を見に行く代わりに、\n一枚めくった。',
                              en='opened this instead', art='02-intro.png')),
        ('03-card.png', R.real_card(QUOTE_ID)),
        ('04-meaning.png', note('もう少し読む', q['meaning_preview'],
                                en='what this one is for', art='04-meaning.png')),
        ('05-shelf.png', shelf(SHELF_IDS + [QUOTE_ID])),
        ('06-closing.png', closing()),
    ]
    for name, im in deck:
        im.save(out / name)
        print('  ', name)
    return out


def export(src=HERE / 'slides', out=HERE / 'export-tiktok-1080x1920', quality=92):
    """投稿用 1080x1920 JPEG。TikTokは UPLOAD 運用なので寸法をここで固定する。"""
    out.mkdir(parents=True, exist_ok=True)
    for f in out.glob('*.jpg'):
        f.unlink()
    for p in sorted(src.glob('*.png')):
        im = Image.open(p).convert('RGB')
        assert im.size == (W, H), f'{p.name} is {im.size}, expected {(W, H)}'
        im.save(out / f'{p.stem}.jpg', quality=quality, subsampling=0)
    return out


def contact_sheet(src=HERE / 'slides', path=HERE / 'contact-sheet.png', cols=3, scale=0.24):
    files = sorted(src.glob('*.png'))
    tw, th = int(W * scale), int(H * scale)
    gap, pad = 12, 12
    rows = -(-len(files) // cols)
    sh = Image.new('RGB', (pad * 2 + cols * tw + (cols - 1) * gap,
                           pad * 2 + rows * th + (rows - 1) * gap), (24, 24, 24))
    for i, p in enumerate(files):
        sh.paste(Image.open(p).convert('RGB').resize((tw, th), Image.Resampling.LANCZOS),
                 (pad + (i % cols) * (tw + gap), pad + (i // cols) * (th + gap)))
    sh.save(path)
    return path


if __name__ == '__main__':
    import carousel
    print('rendering v5a (real assets, 1080x1920) ...')
    o = build()
    print('export   ->', export())
    print('sheet    ->', contact_sheet())
    print('carousel ->', carousel.build())
    print('done ->', o)
