"""確認用カルーセル。`export-tiktok-1080x1920/` の投稿用JPEGをそのまま束ねる。

スライドを直すたびに手で組み直すと中身がずれるので、書き出しから生成する。
埋め込みは実寸の半分（540x960）に落とす。原寸6枚をbase64にすると1MB超になり、
確認用としては重すぎるため。
"""
import base64
import html
import io
from pathlib import Path
from PIL import Image

HERE = Path(__file__).resolve().parent

TITLE = 'v5a — 既読のままの画面を、まだスワイプできない人へ'
SUB = '1080×1920 ／ 全6枚 ／ 枠=線画(gpt-image-2)＋オフホワイト明朝、カード=アプリ実物アセット'

CAPTIONS = [
    '01 表紙 — 横書きタイトル1行のみ。線画を上へ送り、下25%は空ける',
    '02 導入 — 手のひらの上でめくられる一枚（線画）',
    '03 実物カード — 実背景アセット＋縦書き。ここは画像生成なし',
    '04 もう少し読む — 開いた本と灯り（線画）／ meaning_preview はデータそのまま',
    '05 私の棚 — WeeklyShelfView の構造を枠の視覚言語で。punchline 3行',
    '06 締め — 300枚の言葉と、それを置く棚。',
]

NOTE = """<b>今回:</b> 表紙を縦書き3要素から<b>横書きタイトル1要素</b>へ（字送り 61px→72px）。
線画は <b>0.72H</b> より下に出さない＝TikTokのキャプション帯を避ける。<br>
<b>棚:</b> 実物カードの横並びは<b>アプリに無い画面</b>だったので、WeeklyShelfView の
punchline 行リストへ作り直し。構造だけ実画面から採り、色と書体は枠に合わせる。<br>
<b>切り分け:</b> 画像生成は枠の線画だけ。3枚目のカードは Backgrounds の実アセット。"""

CSS = """*{box-sizing:border-box}
body{margin:0;background:#1b1a18;color:#eae6de;font-family:-apple-system,"Hiragino Sans",sans-serif}
.wrap{max-width:560px;margin:0 auto;padding:18px 14px 44px}
h1{font-size:15.5px;font-weight:600;margin:0 0 4px}
.sub{font-size:11.5px;color:#98928a;margin:0 0 16px;line-height:1.6}
.stage{border-radius:12px;overflow:hidden;background:#000}
.stage img{width:100%;display:block}
.bar{display:flex;gap:4px;margin:9px 0 7px}
.bar i{flex:1;height:3px;border-radius:2px;background:#38342e;transition:background .2s}
.bar i.on{background:#c9a227}
.cap{font-size:12px;color:#aaa298;min-height:34px;line-height:1.5}
.nav{display:flex;gap:8px;margin-top:10px}
button{flex:1;padding:11px;border:1px solid #3b362f;background:#252320;color:#eae6de;
border-radius:8px;font-size:14px;cursor:pointer;font-family:inherit}
.grid{display:grid;grid-template-columns:repeat(6,1fr);gap:4px;margin-top:18px}
.grid img{width:100%;border-radius:3px;display:block;opacity:.4;cursor:pointer;border:1.5px solid transparent}
.grid img.on{opacity:1;border-color:#c9a227}
.note{margin-top:22px;padding:13px;border:1px solid #3b362f;border-radius:9px;
font-size:12px;line-height:1.75;color:#a29a90}
.note b{color:#c9a227}"""

JS = """const v=document.getElementById('v'),cap=document.getElementById('cap'),
bar=document.getElementById('bar'),grid=document.getElementById('grid');let i=0;
S.forEach((s,n)=>{const b=document.createElement('i');b.onclick=()=>set(n);bar.appendChild(b);
const g=document.createElement('img');g.src=s;g.onclick=()=>set(n);grid.appendChild(g);});
function set(n){i=(n+S.length)%S.length;v.src=S[i];cap.textContent=C[i];
[...bar.children].forEach((e,k)=>e.className=k<=i?'on':'');
[...grid.children].forEach((e,k)=>e.className=k===i?'on':'');}
function go(d){set(i+d)}
document.onkeydown=e=>{if(e.key==='ArrowRight')go(1);if(e.key==='ArrowLeft')go(-1)};
let x0=null;const st=v.parentElement;
st.ontouchstart=e=>x0=e.touches[0].clientX;
st.ontouchend=e=>{if(x0===null)return;const dx=e.changedTouches[0].clientX-x0;
if(Math.abs(dx)>40)go(dx<0?1:-1);x0=null};
set(0);"""


def data_uri(path, scale=0.5, quality=78):
    im = Image.open(path).convert('RGB')
    im = im.resize((int(im.width * scale), int(im.height * scale)), Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, 'JPEG', quality=quality)
    return 'data:image/jpeg;base64,' + base64.b64encode(buf.getvalue()).decode()


def build(src=HERE / 'export-tiktok-1080x1920', out=HERE / 'carousel.html'):
    files = sorted(src.glob('*.jpg'))
    assert len(files) == len(CAPTIONS), f'{len(files)}枚に対しキャプション{len(CAPTIONS)}件'
    srcs = ',\n'.join(f'"{data_uri(p)}"' for p in files)
    caps = ',\n'.join(f'"{html.escape(c)}"' for c in CAPTIONS)
    out.write_text(f"""<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{html.escape(TITLE)}</title>
<style>
{CSS}
</style>
<div class="wrap">
<h1>{html.escape(TITLE)}</h1>
<p class="sub">{html.escape(SUB)}</p>
<div class="stage"><img id="v"></div>
<div class="bar" id="bar"></div>
<div class="cap" id="cap"></div>
<div class="nav"><button onclick="go(-1)">‹ 前</button><button onclick="go(1)">次 ›</button></div>
<div class="grid" id="grid"></div>
<div class="note">{NOTE}</div>
</div>
<script>
const S=[
{srcs}],C=[
{caps}];
{JS}
</script>
""", encoding='utf-8')
    return out


if __name__ == '__main__':
    print('carousel ->', build())
