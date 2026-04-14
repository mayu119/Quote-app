#!/usr/bin/env python3

import json
import re

FILES = [
    "QuoteApp/Sources/Resources/quotes.json",
    "QuoteApp/Sources/Resources/quotes_full.json",
]

AUTHOR_FIXES = {
    "Helen Keller": {
        "author_birth_year": 1880,
        "author_death_year": 1968,
        "author_description": "アメリカの作家・教育家・社会福祉活動家",
        "author_fact": "1880年生まれ、1968年没。アメリカの作家・教育家・社会福祉活動家。",
    },
    "Kahlil Gibran": {
        "author_birth_year": 1883,
        "author_death_year": 1931,
        "author_description": "レバノン生まれの詩人・作家・画家",
        "author_fact": "1883年生まれ、1931年没。レバノン生まれの詩人・作家・画家。",
    },
    "Amelia Earhart": {
        "author_birth_year": 1897,
        "author_death_year": 1937,
        "author_description": "アメリカの飛行士",
        "author_fact": "1897年生まれ、1937年没。アメリカの飛行士。",
    },
    "Desmond Tutu": {
        "author_birth_year": 1931,
        "author_death_year": 2021,
        "author_description": "南アフリカの聖職者・人権活動家",
        "author_fact": "1931年生まれ、2021年没。南アフリカの聖職者・人権活動家。",
    },
    "Barbara Bush": {
        "author_birth_year": 1925,
        "author_death_year": 2018,
        "author_description": "アメリカの元ファーストレディ",
        "author_fact": "1925年生まれ、2018年没。アメリカの元ファーストレディ。",
    },
    "Joyce Brothers": {
        "author_birth_year": 1927,
        "author_death_year": 2013,
        "author_description": "アメリカの心理学者・作家",
        "author_fact": "1927年生まれ、2013年没。アメリカの心理学者・作家。",
    },
    "Steve Jobs": {
        "author_birth_year": 1955,
        "author_death_year": 2011,
        "author_description": "アメリカの実業家・Apple共同創業者",
        "author_fact": "1955年生まれ、2011年没。アメリカの実業家・Apple共同創業者。",
    },
    "Erich Fromm": {
        "author_birth_year": 1900,
        "author_death_year": 1980,
        "author_description": "ドイツ出身の社会心理学者・思想家",
        "author_fact": "1900年生まれ、1980年没。ドイツ出身の社会心理学者・思想家。",
    },
    "Henry David Thoreau": {
        "author_birth_year": 1817,
        "author_death_year": 1862,
        "author_description": "アメリカの思想家・作家",
        "author_fact": "1817年生まれ、1862年没。アメリカの思想家・作家。",
    },
    "Michael J. Fox": {
        "author_birth_year": 1961,
        "author_death_year": None,
        "author_description": "カナダ系アメリカ人の俳優・活動家",
        "author_fact": "1961年生まれ。カナダ系アメリカ人の俳優・活動家。",
    },
    "Madeleine Albright": {
        "author_birth_year": 1937,
        "author_death_year": 2022,
        "author_description": "アメリカの外交官・政治家",
        "author_fact": "1937年生まれ、2022年没。アメリカの外交官・政治家。",
    },
    "Coretta Scott King": {
        "author_birth_year": 1927,
        "author_death_year": 2006,
        "author_description": "アメリカの活動家・公民権運動指導者",
        "author_fact": "1927年生まれ、2006年没。アメリカの活動家・公民権運動指導者。",
    },
    "Rainer Maria Rilke": {
        "author_birth_year": 1875,
        "author_death_year": 1926,
        "author_description": "オーストリアの詩人",
        "author_fact": "1875年生まれ、1926年没。オーストリアの詩人。",
    },
}


def normalize(text):
    return re.sub(r"\s+", " ", (text or "").replace("\n", " ")).strip()


def lines(text):
    return [line.strip(" 。") for line in (text or "").split("\n") if line.strip()]


def lead(text):
    return lines(text)[0] if lines(text) else ""


def quoted(text):
    return f"「{lead(text)}」"


def has(text, *words):
    return any(word in text for word in words)


def style_index(entry):
    return sum(ord(ch) for ch in entry["id"]) % 4


def open_sentence(entry, clause):
    q = quoted(entry["quote_ja"])
    idx = style_index(entry)
    if idx == 0:
        return f"{q} は、{clause}。"
    if idx == 1:
        return f"この一文が刺さるのは、{clause}。"
    if idx == 2:
        return f"{q} という言い方で、{clause}。"
    return f"ここで言い切っているのは、{clause}。"


def source_kind(text):
    text = normalize(text)
    if not text:
        return "generic"
    if "日記" in text:
        return "diary"
    if has(text, "演説", "スピーチ", "講演"):
        return "speech"
    if "インタビュー" in text:
        return "interview"
    if has(text, "刊『", "著作", "書簡", "一節", "思想", "日々のことば"):
        return "book"
    return "generic"


def source_anchor(text):
    text = normalize(text)
    if not text:
        return ""

    year = re.search(r"([0-9]{4}年)", text)
    title = re.search(r"『([^』]+)』", text)

    if "日記" in text:
        return f"{year.group(1)}の日記" if year else "日記"
    if "民主党全国大会" in text:
        return "民主党全国大会のスピーチ"
    if "国連演説" in text:
        return "国連演説"
    if has(text, "演説", "スピーチ", "講演"):
        for token in ["演説", "スピーチ", "講演"]:
            if token in text:
                return f"{year.group(1)}の{token}" if year else token
    if "インタビュー" in text:
        return f"{year.group(1)}のインタビュー" if year else "インタビュー"
    if title:
        return f"『{title.group(1)}』"
    if "書簡" in text:
        return "書簡"
    return text.rstrip("。")


def background_sentence(entry, clause):
    source = entry.get("source_context", "")
    anchor = source_anchor(source)
    kind = source_kind(source)
    source_text = normalize(source)

    if kind == "diary":
        return f"{anchor}に残った言葉だけに、{clause}。"
    if kind == "speech":
        return f"{anchor}で人に向かって放たれた言葉だから、{clause}。"
    if kind == "interview":
        return f"{anchor}で語られた背景を踏まえると、{clause}。"
    if kind == "book":
        return f"{anchor}の文脈で読むと、{clause}。"
    if has(source_text, "人生観", "人生哲学"):
        return f"本人の人生観として残った言葉だけに、{clause}。"
    if has(source_text, "自己受容", "自己肯定感", "内面"):
        return f"自己受容の文脈で残った言葉だけに、{clause}。"
    if "リーダーシップ" in source_text:
        return f"リーダーシップの文脈で残った言葉だけに、{clause}。"
    if has(source_text, "前向きさ", "象徴する"):
        return f"その人の生き方を象徴する言葉だけに、{clause}。"
    if has(source_text, "広く引用", "代表的", "有名"):
        return f"繰り返し引用されてきた言葉だけに、{clause}。"
    if anchor and len(anchor) <= 18:
        return f"{anchor}という背景を踏まえると、{clause}。"
    return f"この言葉の背景を踏まえると、{clause}。"


def self_love(entry):
    text = normalize(entry["quote_ja"])

    if has(text, "生き延びることではない", "力強く生きる"):
        s1 = open_sentence(entry, "無事にやり過ごすだけの人生では足りない、と自分の存在の熱量を上げるよう迫っている点です")
        s2 = background_sentence(entry, "きれいな自己啓発ではなく、ただ耐える側に自分を固定しないための決意として響きます")
    elif has(text, "居場所", "受け入れる"):
        s1 = open_sentence(entry, "好かれるための仮面より先に、自分で自分を迎え入れる感覚が居場所の土台になると示している点です")
        s2 = background_sentence(entry, "外から認められる前に内側で追放をやめる、その順序を入れ替える洞察として読むと深く入ります")
    elif has(text, "何者かになろう", "見せかけ", "自分自身"):
        s1 = open_sentence(entry, "評価される役を演じ続けるほど悩みは増えるので、演出より素の輪郭を選べと言っている点です")
        s2 = background_sentence(entry, "自己肯定感を足し算で作るのでなく、不要な背伸びを引き算して取り戻す発想として効きます")
    elif has(text, "舞い上がりたい", "這うことに同意"):
        s1 = open_sentence(entry, "自分の中に上へ行きたい衝動があるなら、低い自己評価に従うなとかなり強く線を引いている点です")
        s2 = background_sentence(entry, "境遇に合わせて望みを縮めるより、望みの大きさに自分を合わせ直せという励ましとして残ります")
    elif has(text, "視点", "表現しない"):
        s1 = open_sentence(entry, "自分だけの見方を黙らせることが、そのまま自己信頼の目減りにつながると見抜いている点です")
        s2 = background_sentence(entry, "認められるかどうかより、まず自分の視点を外に出すこと自体が自尊心を守る行為だと読めます")
    elif has(text, "歴史に記憶"):
        s1 = open_sentence(entry, "自分の価値は肩書きではなく、日々どう生きたかの積み重ねで決まると静かに言い切っている点です")
        s2 = background_sentence(entry, "他人の評価表より、自分の時間の使い方に責任を持つことが自尊心の芯になると読み取れます")
    elif has(text, "感謝", "朝", "目覚め"):
        s1 = open_sentence(entry, "自分を立て直す入口を、大きな変化ではなく、今あるものを受け取る習慣に置いている点です")
        s2 = background_sentence(entry, "足りなさに意識を奪われた朝より、持っているものを数え直した朝のほうが自分への扱いが変わります")
    elif has(text, "物語", "始まり"):
        s1 = open_sentence(entry, "今の停滞を完成形だと決めつけず、物語はまだ書き換わる途中だと思い出させる点です")
        s2 = background_sentence(entry, "行き詰まりを結末と見なさないだけで、自分への見切りの早さを止められると教えています")
    elif has(text, "想像力は", "知識よりも重要"):
        s1 = open_sentence(entry, "自分を前へ進めるのは、今ある知識の量より、まだ無い未来を思い描く力だと示している点です")
        s2 = background_sentence(entry, "知っている範囲だけで生きると自分は小さく固まるので、想像力を自己信頼の源として読むと効きます")
    elif has(text, "想像力", "夢", "可能性"):
        s1 = open_sentence(entry, "現実が先に限界を決めるのではなく、可能性を想像できなくなった瞬間に人は縮むと示している点です")
        s2 = background_sentence(entry, "自分を信じる力は根拠の量より、まだ見えていない未来を手放さない想像力から立ち上がると読めます")
    elif has(text, "自分を愛する"):
        s1 = open_sentence(entry, "自己愛を甘やかしではなく、人生を生きる前提条件として置いている点です")
        s2 = background_sentence(entry, "自分への敵意を抱えたまま前に進むのは難しいので、まず内側の扱い方を変えろという教えとして効きます")
    elif has(text, "内なる声", "羅針盤"):
        s1 = open_sentence(entry, "情報や正解が多いほど、自分の内側の声を聞き分ける力が価値を持つと示している点です")
        s2 = background_sentence(entry, "他人の基準で迷子になる前に、自分の感覚へ戻る回路を持てという読み方ができます")
    elif has(text, "今日ここ", "この瞬間"):
        s1 = open_sentence(entry, "生きている実感は遠い理想ではなく、いまここを丁寧に受け取ることで戻ってくると教えています")
        s2 = background_sentence(entry, "未来の不足ばかり見て自分を責めるより、今日ここに在る自分を一度肯定する感覚として使えます")
    elif has(text, "他人になるな"):
        s1 = open_sentence(entry, "自己表現の核心を、上手に適応することより自分を偽らないことに置いている点です")
        s2 = background_sentence(entry, "自分を消してまで好かれるより、輪郭を保ったまま立つほうが長い目では救いになると響きます")
    elif has(text, "慈悲", "失敗"):
        s1 = open_sentence(entry, "失敗した時ほど厳しさではなく、自分への慈悲が必要になると真正面から言っている点です")
        s2 = background_sentence(entry, "立て直しは反省だけでは進まず、もう一度自分を味方に戻すところから始まると教えています")
    elif has(text, "比べ", "去年の自分"):
        s1 = open_sentence(entry, "他人との優劣ではなく、昨日までの自分を更新できているかで自尊心を測れと軸を置き直している点です")
        s2 = background_sentence(entry, "比較で削れる心を止めるには、勝敗より成長の差分に視線を戻すほうが健全だと読めます")
    else:
        s1 = open_sentence(entry, "自分を雑に扱ったまま前向きになろうとする無理を止めている点です")
        s2 = background_sentence(entry, "派手な自信より先に、自分への扱いを整えることが回復の入口になると受け取れます")
    return f"{s1} {s2}"


def positive(entry):
    text = normalize(entry["quote_ja"])

    if has(text, "新しい一日", "明日"):
        s1 = open_sentence(entry, "昨日の失敗や気分を、そのまま今日の運命にしなくていいと視界を切り替えてくれる点です")
        s2 = background_sentence(entry, "希望を奇跡待ちではなく、朝ごとに見方を更新する技術として使えるのがこの言葉の強さです")
    elif has(text, "可能性そのもの"):
        s1 = open_sentence(entry, "現在地の説明で自分を閉じず、まだ起きていない可能性まで含めて自分を見ろと促している点です")
        s2 = background_sentence(entry, "落ち込んだ日は現状が自分の全てに見えますが、この言葉はそこをかなり強引に引き剥がしてくれます")
    elif has(text, "愛を選ぶ", "恐れを選ぶ"):
        s1 = open_sentence(entry, "出来事そのものより、その場で愛と恐れのどちらから反応するかが人生の質を分けると見抜いている点です")
        s2 = background_sentence(entry, "前向きさを気分の明るさではなく、選び方の問題に引き戻すところに実用性があります")
    elif has(text, "苦しみに満ちている", "乗り越える力"):
        s1 = open_sentence(entry, "世界の痛みを否定せず、その中に耐える力も同時に存在すると二つを並べて見せている点です")
        s2 = background_sentence(entry, "楽観ではなく、つらさだけを真実にしない視点の持ち方として読むと腑に落ちます")
    elif has(text, "祝うべき喜び"):
        s1 = open_sentence(entry, "苦しい最中でも喜びを見つけることは現実逃避ではなく、心を枯らさないための技術だと教えています")
        s2 = background_sentence(entry, "しんどい時期ほど全部を暗く塗りつぶしがちなので、この一文は小さな光を見落とさない訓練になります")
    elif has(text, "宇宙は変化", "思考が形づくる"):
        s1 = open_sentence(entry, "変化し続ける世界で、自分の現実を固めてしまうのは受け取り方のほうだと突いている点です")
        s2 = background_sentence(entry, "状況を一気に変えられない日でも、意味づけを変えるだけで呼吸は少し楽になると読めます")
    elif has(text, "まだ起きていない", "癒えてきた傷"):
        s1 = open_sentence(entry, "実際の傷より、まだ起きていない未来への想像で消耗している自分に気づかせる点です")
        s2 = background_sentence(entry, "過去に越えた痛みを思い出すことで、未来への過剰な恐れを少しほどける言葉になっています")
    elif has(text, "不安から逃れた", "手放した"):
        s1 = open_sentence(entry, "不安を外から来る敵ではなく、自分の解釈の中で膨らんでいたものとして見直させる点です")
        s2 = background_sentence(entry, "現実を変えずに少し楽になる道があると示すので、気持ちの出口を作りやすい一文です")
    elif has(text, "小さなこと", "誠実"):
        s1 = open_sentence(entry, "前向きさの正体を大きな転機ではなく、小さなことに誠実でいる反復へ落としている点です")
        s2 = background_sentence(entry, "人生を変えるのは気合いより習慣だと腹落ちさせる、かなり地に足のついた言葉です")
    elif has(text, "傷は", "知恵に変え"):
        s1 = open_sentence(entry, "傷を消すことではなく、傷から取り出せる知恵を増やすことに回復の焦点を置いている点です")
        s2 = background_sentence(entry, "つらい経験を無駄にしない見方を持てるだけで、過去への感じ方はかなり変わります")
    elif has(text, "終わり", "始まり"):
        s1 = open_sentence(entry, "終わったと感じる場所が、そのまま次の入口になりうると結論を急がせない点です")
        s2 = background_sentence(entry, "うまくいかなかった出来事を即失敗認定しない、その余白を作るための言葉として使えます")
    elif has(text, "幸せは", "行動から生まれる"):
        s1 = open_sentence(entry, "幸せを運や気分の産物ではなく、日々の行動が生む結果として捉え直している点です")
        s2 = background_sentence(entry, "待つ姿勢から動く姿勢へ重心を移すだけで、前向きさがかなり現実的なものになります")
    elif has(text, "いちばん良い日"):
        s1 = open_sentence(entry, "今日を仮の一日として流さず、今この日を最良の候補として扱えと言っている点です")
        s2 = background_sentence(entry, "毎日を通過点にしすぎる癖を止めて、今日の密度を上げるための見方として響きます")
    elif has(text, "太陽", "影"):
        s1 = open_sentence(entry, "問題が消えるかどうかより、どこへ顔を向けるかで見える景色は変わると教えています")
        s2 = background_sentence(entry, "暗さに全部の視界を渡さないための姿勢として読むと、意外なくらい実践的です")
    elif has(text, "読書", "礎"):
        s1 = open_sentence(entry, "一日の質は朝に何を入れるかでかなり決まる、と考え方の土台作りに触れている点です")
        s2 = background_sentence(entry, "気分任せで一日を始めるより、最初に思考の軸を入れるほうがぶれにくいと読めます")
    elif has(text, "明日を恐れない"):
        s1 = open_sentence(entry, "今日をちゃんと生きることが、未来への過度な恐れを薄める一番現実的な方法だと示している点です")
        s2 = background_sentence(entry, "先の不安に飲まれる時ほど、今日への愛着を取り戻せという向きの言葉として効きます")
    elif has(text, "瞑想", "錨"):
        s1 = open_sentence(entry, "心を整える時間を贅沢品ではなく、荒れる一日を支える錨として位置づけている点です")
        s2 = background_sentence(entry, "外の出来事が多い日ほど、先に内側を落ち着かせるほうが結局は強いと読めます")
    elif has(text, "一日ひとつ", "365"):
        s1 = open_sentence(entry, "成長を劇的な変化ではなく、毎日ひとつ拾う学びの累積として捉えている点です")
        s2 = background_sentence(entry, "大きく変われない自分を責めるより、小さく拾い続けるほうが一年後の差になると響きます")
    elif has(text, "できないこと", "楽しい"):
        s1 = open_sentence(entry, "前向きさを結果の快感より、できないことができるようになる途中の面白さに置いている点です")
        s2 = background_sentence(entry, "伸びる人は完成ではなく成長そのものを楽しめる、この視点の強さがよく出ています")
    else:
        s1 = open_sentence(entry, "気持ちを無理に明るくするのでなく、見方を一段ずらすことで立ち直りの余白を作っている点です")
        s2 = background_sentence(entry, "前向きさを根性論にしないところが、この言葉の使いやすさにつながっています")
    return f"{s1} {s2}"


def courage(entry):
    text = normalize(entry["quote_ja"])

    if has(text, "勇気がなければ", "美徳"):
        s1 = open_sentence(entry, "勇気を一つの長所ではなく、他の美徳を持続させる土台として見ている点です")
        s2 = background_sentence(entry, "やさしさも誠実さも、怖い場面で引っ込めてしまえば続かないので、勇気が根っこになると分かります")
    elif has(text, "声に出す", "自分の頭で考え"):
        s1 = open_sentence(entry, "本当に勇敢なのは派手な挑戦より、自分の考えを自分の声で外に出すことだと定義し直している点です")
        s2 = background_sentence(entry, "黙って波風を避けるより、立場を引き受けて言葉にするほうが人生を動かすと響きます")
    elif has(text, "できないと思うこと", "やってみなさい"):
        s1 = open_sentence(entry, "自信がついてから動くのでなく、無理だと思うことへ先に手を伸ばせと背中を押している点です")
        s2 = background_sentence(entry, "怖さの消失を待つ限り前へ出られない、その堂々巡りを切るための言葉として効きます")
    elif has(text, "立ち上がれる", "誰かのため"):
        s1 = open_sentence(entry, "他人のために戦う勇気も、まず自分を守る勇気が育っていないと続かないと見抜いている点です")
        s2 = background_sentence(entry, "自己犠牲を美化せず、自分の足場を作った人だけが他者の支えになれると読めます")
    elif has(text, "恐れはどんどん小さくなる"):
        s1 = open_sentence(entry, "恐れをなくす方法を、待つことではなく、自分の力を実際に使うことに置いている点です")
        s2 = background_sentence(entry, "勇気は感情の準備より行動の後に育つ、その順番を体感で教えてくれる一文です")
    elif has(text, "行動すると決める", "第一のルール", "行動を起こす"):
        s1 = open_sentence(entry, "難所は継続より最初の決断にある、と勇気の本丸を『決める瞬間』へ絞っている点です")
        s2 = background_sentence(entry, "迷い続ける時間がいちばん力を削るので、まず決めること自体が突破口になると分かります")
    elif has(text, "情熱", "羅針盤"):
        s1 = open_sentence(entry, "勇気を根性ではなく、自分が何に引かれているかを知ることから始めている点です")
        s2 = background_sentence(entry, "怖さを消すより、進みたい方向を明確にしたほうが足が前に出るという示唆があります")
    elif has(text, "太陽", "今日輝け"):
        s1 = open_sentence(entry, "誰かの許可を待たず、今日は自分が光る側に回れと強めに促している点です")
        s2 = background_sentence(entry, "勇気を特別な舞台の話にせず、その日の姿勢として扱っているのがこの言葉の良さです")
    elif has(text, "限界は心が作り出した"):
        s1 = open_sentence(entry, "目の前の壁より先に、心の中で引いている限界線のほうを疑えと言っている点です")
        s2 = background_sentence(entry, "能力の不足より先に自己定義が行動を止める、その構造を見抜く言葉として読めます")
    elif has(text, "嵐の後の虹", "苦しい時ほど"):
        s1 = open_sentence(entry, "苦しい時期を単なる消耗ではなく、自分の芯が見える時間として捉え直している点です")
        s2 = background_sentence(entry, "つらさの只中でも意味を見失わないための言葉として、かなり救いがあります")
    elif has(text, "倒れることは恥ずかしくない"):
        s1 = open_sentence(entry, "恥ずかしいのは失敗ではなく、倒れた瞬間に自分を終わらせることだと価値基準をひっくり返している点です")
        s2 = background_sentence(entry, "勇気を『転ばない人』ではなく『転んでも閉じない人』の側に置き直してくれます")
    elif has(text, "暗い夜", "星"):
        s1 = open_sentence(entry, "最悪の状況そのものが、見えなかったものを見せる時間にもなりうると教えている点です")
        s2 = background_sentence(entry, "暗さをただの不運で終わらせず、見る目を育てる局面として読めるのがこの言葉の強さです")
    elif has(text, "望む変化", "あなた自身がなれ"):
        s1 = open_sentence(entry, "理想の世界を願うだけでなく、自分がその変化の最初の一人になれと迫っている点です")
        s2 = background_sentence(entry, "外側への不満を言い続けるより、自分の在り方から変えるほうがずっと勇気がいると響きます")
    elif has(text, "教育", "武器"):
        s1 = open_sentence(entry, "勇気を一時の気合いではなく、長い時間で世界を書き換える力に置いている点です")
        s2 = background_sentence(entry, "感情的に戦うより、学びを武器にするほうが深く社会を変えるという視点が残ります")
    elif has(text, "逆境が人間を作る"):
        s1 = open_sentence(entry, "楽な環境では見えない輪郭が、逆境の中でこそ削り出されると捉えている点です")
        s2 = background_sentence(entry, "苦労を美化するのでなく、困難が人を鍛える側面を直視した言葉として読めます")
    elif has(text, "光を見つける目"):
        s1 = open_sentence(entry, "勇気の本質を、暗闇がないことではなく、暗闇の中でも光を探す目に置いている点です")
        s2 = background_sentence(entry, "状況そのものより視線の向け方を鍛えるほうが、長く使える強さになると示しています")
    elif has(text, "静寂", "思考"):
        s1 = open_sentence(entry, "大きな決断を支えるのは騒がしさではなく、一人で深く考え抜く静けさだと示している点です")
        s2 = background_sentence(entry, "勇気ある行動の前に、静かに腹を決める時間が必要だと読める言葉です")
    elif has(text, "何もしないことを恐れろ", "チャレンジ"):
        s1 = open_sentence(entry, "失敗の痛みより、挑戦しないまま固まることのほうを恐れろと方向づけている点です")
        s2 = background_sentence(entry, "恥を避ける人生より、試して傷つく人生のほうが前に進むと腹落ちさせてくれます")
    elif has(text, "志を立てる"):
        s1 = open_sentence(entry, "始める資格を年齢で区切らず、志を持つこと自体に遅すぎる瞬間はないと切っている点です")
        s2 = background_sentence(entry, "もう遅いという言い訳を断ち切る、かなり直接的な勇気の言葉になっています")
    else:
        s1 = open_sentence(entry, "怖さがある場面でも、自分の立ち位置を選び直す力こそ勇気だと教えている点です")
        s2 = background_sentence(entry, "感情が整うのを待たず、まず一歩の選び方を変えるために使える言葉です")
    return f"{s1} {s2}"


def inner_strength(entry):
    text = normalize(entry["quote_ja"])

    if has(text, "弱さも恐れも絶望も消えて"):
        s1 = open_sentence(entry, "強さを生まれつきの資質ではなく、弱さや恐れを通ったあとに立ち上がる力として描いている点です")
        s2 = background_sentence(entry, "痛みを知らない人の強さではなく、傷を越えた人だけが持つ重さとして読むと一気に切実になります")
    elif has(text, "高くあろう"):
        s1 = open_sentence(entry, "相手の粗さに自分の品位まで引きずられないことを、本当の強さとして定義している点です")
        s2 = background_sentence(entry, "怒りに怒りで返さないのは受け身ではなく、自分の軸を守るためのかなり攻めた判断だと分かります")
    elif has(text, "翼がある"):
        s1 = open_sentence(entry, "壊れた現実を認めたうえで、想像力まで差し出すなと言い切っている点が鋭いです")
        s2 = background_sentence(entry, "きれいな標語ではなく、自分の可能性だけは折らなかった執念として響くから強い言葉になります")
    elif has(text, "決定が下される", "いるべき"):
        s1 = open_sentence(entry, "強さを我慢の能力ではなく、決定の席から降りないことに置いている点です")
        s2 = background_sentence(entry, "文句を言う側にとどまるより、決める側へ回る覚悟のほうがずっと重いと教えています")
    elif has(text, "責任を持ちなさい", "満たせるのは、あなただけ"):
        s1 = open_sentence(entry, "人生の主語を他人や環境に預けたままにするな、とかなり厳しく引き戻している点です")
        s2 = background_sentence(entry, "誰かに整えてもらう期待を手放し、自分の選び方を自分で引き受けるところに強さが宿ると読めます")
    elif has(text, "組織を良くしたい", "自分自身を育て"):
        s1 = open_sentence(entry, "外側を動かしたいなら、まず自分の器と判断力を鍛えろと順序を示している点です")
        s2 = background_sentence(entry, "強い人とは他人を動かす人ではなく、先に自分を育て続けられる人だと受け取れます")
    elif has(text, "善い人とは何か", "自分がそうなればいい"):
        s1 = open_sentence(entry, "人格を論じる快感に浸る前に、自分の行動をその基準へ合わせろと言っている点です")
        s2 = background_sentence(entry, "理想を語ることと体現することの差を突かれるので、かなり耳が痛いぶん効く言葉です")
    elif has(text, "静まったとき", "宇宙の声"):
        s1 = open_sentence(entry, "強さを大声や勢いではなく、静けさの中で自分を保てる力として描いている点です")
        s2 = background_sentence(entry, "外が騒がしいほど反応を急がず、内側を整えた人のほうが最後に崩れにくいと読めます")
    elif has(text, "逆境で輝く"):
        s1 = open_sentence(entry, "逆境は人を潰すだけでなく、本来の光り方を露わにする場面でもあると示している点です")
        s2 = background_sentence(entry, "苦しい時に自分の価値まで否定しない、その姿勢を支える言葉として使えます")
    elif has(text, "敗北から立ち上がる"):
        s1 = open_sentence(entry, "無傷でいることより、敗北のあとで戻ってこられることのほうに本当の強さを見る点です")
        s2 = background_sentence(entry, "勝ち続ける人より、負けたあとに立ち直る人に厚みが出るという読みができます")
    elif has(text, "感謝は", "十分なものに変える"):
        s1 = open_sentence(entry, "足りないものに心を奪われた状態から、自分を立て直す力として感謝を置いている点です")
        s2 = background_sentence(entry, "感謝は優しさの話だけでなく、欠乏感に飲まれないための精神的な筋力として読めます")
    elif has(text, "大きな冒険", "夢見る人生"):
        s1 = open_sentence(entry, "安全にまとまることより、自分が本当に望む人生を引き受けるほうが強さだと言っている点です")
        s2 = background_sentence(entry, "本音に沿って生きるほうが怖いからこそ、この言葉は背中を押すというより覚悟を迫ってきます")
    elif has(text, "千里の道も一歩"):
        s1 = open_sentence(entry, "巨大な目標も最初の一歩を切り出した瞬間にしか現実へ変わらない、と強さを細かく分解している点です")
        s2 = background_sentence(entry, "圧倒される時ほど遠さではなく最初の一歩だけを見る、その発想が自分を救います")
    elif has(text, "死を思えば", "生の価値"):
        s1 = open_sentence(entry, "死を意識することで今の時間の重みが増す、と強さを有限性の自覚から引き出している点です")
        s2 = background_sentence(entry, "永遠に続くと思うと人は鈍るので、終わりを知ることが逆に生を濃くすると読めます")
    elif has(text, "困難な時こそ", "本当の姿"):
        s1 = open_sentence(entry, "平時の余裕では見えない本性が、困難の中でむしろはっきり出ると見ている点です")
        s2 = background_sentence(entry, "逆境は評価を落とす場面でなく、自分の芯が露わになる場面だと受け取れます")
    elif has(text, "沈黙の中にこそ", "知恵"):
        s1 = open_sentence(entry, "強さと知恵の源を、反応の速さではなく、沈黙の中で考え抜く深さに置いている点です")
        s2 = background_sentence(entry, "言い返す前に黙る強さを持てる人ほど、最後にぶれにくいという示唆があります")
    elif has(text, "信頼すること", "成功の秘密"):
        s1 = open_sentence(entry, "最初に必要なのは条件の充実ではなく、自分を信じる感覚だと端的に言っている点です")
        s2 = background_sentence(entry, "外の承認が来る前に自分で自分を信じる、その先行投資が強さの核になると読めます")
    elif has(text, "後悔せず"):
        s1 = open_sentence(entry, "結果の良し悪しより、自分で選んだことを引き受ける腹の据わり方に強さを見る点です")
        s2 = background_sentence(entry, "迷い続けるより、決めたあとに振り返らない姿勢のほうが人を前へ進めると響きます")
    elif has(text, "未来進行形"):
        s1 = open_sentence(entry, "能力を現在の点数で固定せず、育っていく前提で見ろと未来側に軸を置いている点です")
        s2 = background_sentence(entry, "今できない自分を即断罪しないことで、人は意外なほど強く粘れるようになります")
    else:
        s1 = open_sentence(entry, "目先の弱気に飲まれず、もっと長い時間軸で自分を扱えと言っている点です")
        s2 = background_sentence(entry, "励ましよりむしろ『どう立つか』を問う言葉として読むほうが強く刺さります")
    return f"{s1} {s2}"


def love_crush(entry):
    text = normalize(entry["quote_ja"])

    if has(text, "大切に抱きしめて"):
        s1 = open_sentence(entry, "愛を当たり前のものとして消費せず、出会えたこと自体を丁寧に扱えと促している点です")
        s2 = background_sentence(entry, "恋は失った時に価値に気づきやすいので、あるうちに抱きしめる姿勢を求める言葉として響きます")
    elif has(text, "与えたい心", "求める心"):
        s1 = open_sentence(entry, "愛を受け取りたい欲求だけでなく、同じ熱量で差し出したい衝動まで含めて恋だと語っている点です")
        s2 = background_sentence(entry, "愛される側に偏ると関係は細るので、与える側の自分も育てろという示唆があります")
    elif has(text, "所有しない"):
        s1 = open_sentence(entry, "愛と所有を切り離し、相手を握らなくても成立する関係だけが本物だと線を引いている点です")
        s2 = background_sentence(entry, "失う不安が強い時ほど執着は愛に見えるので、その誤認を断つ言葉としてかなり効きます")
    elif has(text, "安心していられる"):
        s1 = open_sentence(entry, "恋の本音を劇的な情熱ではなく、安心していられる相手を求める静かな欲求として言っている点です")
        s2 = background_sentence(entry, "ときめきより安心を欲している自分に気づいた時、この言葉はかなり現実味を帯びます")
    elif has(text, "ひとりでいられる力"):
        s1 = open_sentence(entry, "ひとりで立てないままでは、愛は支え合いでなく依存に傾くと見抜いている点です")
        s2 = background_sentence(entry, "相手に埋めてもらう恋より、自分を保ったまま近づく恋のほうが深いと読めます")
    elif has(text, "余白を残しなさい"):
        s1 = open_sentence(entry, "一緒にいるほど余白を失わないことが、関係を長く呼吸させると教えている点です")
        s2 = background_sentence(entry, "密着が愛の証拠に見える時ほど、この余白という発想はかなり示唆的です")
    elif has(text, "無防備"):
        s1 = open_sentence(entry, "愛することの怖さを未熟さではなく、心を開いた時に当然生まれるリスクとして扱っている点です")
        s2 = background_sentence(entry, "傷つかない恋を求めるほど閉じていく、その矛盾をやさしく突く言葉になっています")
    elif has(text, "成熟した愛", "必要だから愛している"):
        s1 = open_sentence(entry, "依存と成熟の違いを、相手を必要とする順番の違いで鮮やかに切り分けている点です")
        s2 = background_sentence(entry, "欠乏を埋める恋か、愛した結果として必要になる恋かを見分ける物差しとして使えます")
    elif has(text, "虐待", "同じ場所"):
        s1 = open_sentence(entry, "苦しくても愛だと思い込みたくなる関係に対して、愛と暴力は両立しないと断言している点です")
        s2 = background_sentence(entry, "恋の名の下に自分を傷つける関係を正当化しない、その境界線を守る言葉として必要です")
    elif has(text, "最も難しい仕事"):
        s1 = open_sentence(entry, "愛を自然に起こる感情ではなく、最も難しい課題として捉えている点です")
        s2 = background_sentence(entry, "好きだからうまくいくのでなく、難しさを引き受ける覚悟が要ると読めるのが深いところです")
    elif has(text, "自然には死なない", "枯れていく"):
        s1 = open_sentence(entry, "愛が終わる時は突然ではなく、満たし方を知らないまま少しずつ痩せていくと見ている点です")
        s2 = background_sentence(entry, "関係は放置で保てるものではない、その地味で重い真実を突く言葉として響きます")
    elif has(text, "もう一度だけ", "またもう一度"):
        s1 = open_sentence(entry, "一度傷ついたあとでも、閉じ切らずにもう一度信じてみる勇気を勧めている点です")
        s2 = background_sentence(entry, "恋で傷ついた人に必要なのは防御の完成より、少しずつ開き直す力だと教えています")
    elif has(text, "感謝は批判を消す"):
        s1 = open_sentence(entry, "関係を蝕む批判の連鎖を、感謝という視点の転換で断てると示している点です")
        s2 = background_sentence(entry, "相手の欠点ばかり見始めた時ほど、この一文は関係の空気を立て直すヒントになります")
    elif has(text, "愛されているという確信"):
        s1 = open_sentence(entry, "人が自分を十分に差し出すには、まず安全に受け止められる感覚が必要だと見抜いている点です")
        s2 = background_sentence(entry, "関係の中で縮こまる人ほど、安心が先にないと愛は深まらないと分かります")
    elif has(text, "困難な時にこそ"):
        s1 = open_sentence(entry, "愛の深さは楽しい時より、困難の中でどこまで残るかで測られると教えています")
        s2 = background_sentence(entry, "順風でのやさしさではなく、きつい時の態度こそ関係の本音だと読むと鋭いです")
    elif has(text, "冒険", "旅"):
        s1 = open_sentence(entry, "愛を安定した状態ではなく、先が読めない冒険として引き受けろと言っている点です")
        s2 = background_sentence(entry, "予定通りにいかないからこそ恋は深く、同時に怖いのだと受け取れます")
    elif has(text, "薬はない", "もっと愛する"):
        s1 = open_sentence(entry, "愛の不足を癒やす方法は、冷めることではなく、むしろもう一段深く愛することだと逆向きに示しています")
        s2 = background_sentence(entry, "恋を守るのは距離でなく、もう少し差し出す勇気かもしれないと考えさせる言葉です")
    elif has(text, "自由でいられる"):
        s1 = open_sentence(entry, "本当に愛するなら、近くに置くことだけでなく相手の自由まで愛せるはずだと問うている点です")
        s2 = background_sentence(entry, "好きだから縛りたくなる気持ちを超えられるかが、成熟した愛の境目だと読めます")
    elif has(text, "恋愛を知らずに死を迎える"):
        s1 = open_sentence(entry, "苦しい恋であっても、誰かを本気で愛した経験そのものに人生の厚みが宿ると語っている点です")
        s2 = background_sentence(entry, "傷が残っていても、愛した時間まで否定しなくていいと思わせてくれる一文です")
    elif has(text, "やは肌"):
        s1 = open_sentence(entry, "理屈を説く言葉より、体温を持った恋の切実さのほうが人を動かすと歌っている点です")
        s2 = background_sentence(entry, "正しさだけでは埋まらない孤独を、身体感覚のある恋として突きつけてくる言葉です")
    else:
        s1 = open_sentence(entry, "恋の高揚だけでなく、その関係をどう持つかまで問うている点です")
        s2 = background_sentence(entry, "ただ愛されたい気持ちの先へ進み、自分を残したまま愛する方法を考えさせてくれます")
    return f"{s1} {s2}"


def family_love(entry):
    text = normalize(entry["quote_ja"])

    if has(text, "世界でいちばん大切"):
        s1 = open_sentence(entry, "家族を数ある大事なものの一つではなく、人生の中心に置いている点が率直です")
        s2 = background_sentence(entry, "忙しさの中で優先順位が崩れやすいからこそ、何を最後まで守りたいかを思い出させてくれます")
    elif has(text, "家の中で", "家に帰って"):
        s1 = open_sentence(entry, "優しさを遠くの誰かより、いちばん近い家の中で発揮できるかを問うている点です")
        s2 = background_sentence(entry, "近い相手ほど雑になる現実を知ったうえで、それでも家の中から整えろという言葉として深いです")
    elif has(text, "娘たち", "母であること"):
        s1 = open_sentence(entry, "社会の肩書きや成果より、家族に向ける役割の重さを先に置いている点です")
        s2 = background_sentence(entry, "外でどれだけ評価されても、最後に残る誇りは身近な人との関わり方だと響きます")
    elif has(text, "抱きしめ", "そばにいる"):
        s1 = open_sentence(entry, "家族の価値を立派な理念でなく、抱きしめることやそばにいることの手触りまで下ろしている点です")
        s2 = background_sentence(entry, "安心は大きな言葉より、離れずにいる態度から生まれると読むと効きます")
    elif has(text, "過去と未来をつなぐ橋"):
        s1 = open_sentence(entry, "家族を一時の関係ではなく、時間をまたいで人を支える橋として見ている点です")
        s2 = background_sentence(entry, "自分だけで完結して生きていないことを思い出す時、この比喩はかなり強く残ります")
    elif has(text, "自然が生んだ最高傑作"):
        s1 = open_sentence(entry, "家族を制度としてでなく、人が持ちうる最も豊かな営みの一つとして捉えている点です")
        s2 = background_sentence(entry, "完璧ではない家族でも、その不器用さごと価値があると思い直せる言葉です")
    elif has(text, "贈り物"):
        s1 = open_sentence(entry, "家族を自分で選んだ成果ではなく、与えられた関係として受け止める視点を持たせる点です")
        s2 = background_sentence(entry, "厄介さも含めて、それでも贈り物だと見る時に接し方が変わると読めます")
    elif has(text, "羅針盤"):
        s1 = open_sentence(entry, "迷った時に進む方向を教えてくれるものとして、家族を人生の羅針盤にたとえている点です")
        s2 = background_sentence(entry, "成果や流行でぶれやすい時ほど、自分を元の向きに戻してくれる場所として響きます")
    elif has(text, "人間社会の最初", "単位"):
        s1 = open_sentence(entry, "家族を個人的な感情の場ではなく、社会の一番最初の土台として見ている点です")
        s2 = background_sentence(entry, "公共の前に家庭のあり方がある、その順番を思い出させる言葉として読めます")
    elif has(text, "家族の愛によって支えられている", "幸せは家族の幸せ"):
        s1 = open_sentence(entry, "自分一人の達成より、家族の幸福の中に人生の大きな支えがあると語っている点です")
        s2 = background_sentence(entry, "頑張る理由が見えなくなった時ほど、誰と生きているかへ戻るヒントになります")
    elif has(text, "相手の目を見つめて", "分かりあえる"):
        s1 = open_sentence(entry, "家族のすれ違いを解く鍵を、まず向き合う姿勢そのものに置いている点です")
        s2 = background_sentence(entry, "正しさをぶつける前に、目を見て手を取る距離感が関係をほどくと教えてくれます")
    elif has(text, "人を信じよ", "自らを信じよ"):
        s1 = open_sentence(entry, "家族や他者を信じることと、自分の軸を持つことを両立させろと言っている点です")
        s2 = background_sentence(entry, "近い関係の中で飲み込まれすぎないためにも、自分への信頼が要ると読み取れます")
    else:
        s1 = open_sentence(entry, "家族を『あるのが当然』なものではなく、日々守り直す関係として見直させる点です")
        s2 = background_sentence(entry, "安心の土台は気持ちだけで続かないので、接し方まで整えてこそ家族になると響きます")
    return f"{s1} {s2}"


def for_my_child(entry):
    text = normalize(entry["quote_ja"])

    if has(text, "お手本", "育てたように", "柔らかいセメント"):
        s1 = open_sentence(entry, "子どもは言葉より先に、大人のふるまいそのものを吸い込んで育つと教えている点です")
        s2 = background_sentence(entry, "正しいことを言う前に、焦り方や謝り方まで見られている前提で読むとかなり重みが出ます")
    elif has(text, "愛され", "抱きしめ", "存在そのものが希望"):
        s1 = open_sentence(entry, "子どもに最初に必要なのは評価より、ここにいていいと感じられる安全だと示している点です")
        s2 = background_sentence(entry, "できるかどうかの前に、愛されている実感を渡せるかが土台になると読めます")
    elif has(text, "言葉にして", "受け止めやすく"):
        s1 = open_sentence(entry, "子どもの感情を消すのでなく、言葉にして一緒に扱える形へ変えることの大切さを伝えている点です")
        s2 = background_sentence(entry, "泣きや怒りを『早く静める対象』ではなく、『まず分かってもらう必要のあるもの』として見る視点が残ります")
    elif has(text, "自分でできる", "可能性", "世界を変える力"):
        s1 = open_sentence(entry, "助けることと、子どもの手応えを奪うことは別だとかなり厳しく線を引いている点です")
        s2 = background_sentence(entry, "先回りの優しさより、自分でできた感覚を守るほうがその子の芯を育てると読めます")
    elif has(text, "あなたのものではない", "考えそのもの"):
        s1 = open_sentence(entry, "愛していても、子どもの人生や頭の中まで所有してはいけないと伝えている点です")
        s2 = background_sentence(entry, "親の役割を支配ではなく伴走として読むと、『口を出しすぎる怖さ』まで見えてきます")
    elif has(text, "どう扱うか", "社会の本質"):
        s1 = open_sentence(entry, "社会の成熟度は、子どもたちをどれだけ大切に扱えているかで露わになると示している点です")
        s2 = background_sentence(entry, "子どもへの接し方は家庭の問題に留まらず、その社会の品位そのものを映すと読めます")
    elif has(text, "芸術家"):
        s1 = open_sentence(entry, "子どもの価値を完成度ではなく、生まれつき持っている創造性そのものに見ている点です")
        s2 = background_sentence(entry, "育てるとは型にはめることではなく、その子の自由な感性を失わせないことだと受け取れます")
    elif has(text, "世界の希望"):
        s1 = open_sentence(entry, "子どもを未来の候補ではなく、すでに希望そのものとして見ている点がまっすぐです")
        s2 = background_sentence(entry, "だからこそ大人は目先の都合で削るのでなく、その希望が育つ環境を守る役目を負うと読めます")
    elif has(text, "希望であり", "約束"):
        s1 = open_sentence(entry, "子どもの存在を、まだ来ていない未来への約束として受け止めている点です")
        s2 = background_sentence(entry, "今見えている未熟さより、この先に開いていく可能性へ賭けるまなざしが大事だと響きます")
    elif has(text, "希望"):
        s1 = open_sentence(entry, "子どもを未完成な存在ではなく、社会や未来の希望そのものとして見ている点です")
        s2 = background_sentence(entry, "大人の都合で形を整える前に、その子が持つ芽をどう守るかが問われていると読めます")
    elif has(text, "どう見るか"):
        s1 = open_sentence(entry, "子どもは大人の目線を通して自分を知っていく、と関わる側の責任を明確にしている点です")
        s2 = background_sentence(entry, "評価の言葉以上に、どんな眼差しで見たかがその子の自己像を作ると響きます")
    elif has(text, "どう生きるか"):
        s1 = open_sentence(entry, "子どもへの問いでありながら、先に大人自身の生き方を問うている点が深いです")
        s2 = background_sentence(entry, "育てるとは答えを与えることではなく、一緒に生き方を考え続けることだと受け取れます")
    else:
        s1 = open_sentence(entry, "子どもを能力や期待の器ではなく、まず一人の存在として尊重しろという点です")
        s2 = background_sentence(entry, "何かを求める前に『生きてそこにいること自体が希望』だと受け取る姿勢が安心の土台になります")
    return f"{s1} {s2}"


def relationships(entry):
    text = normalize(entry["quote_ja"])

    if has(text, "裁いて", "闇は闇では", "敵を友"):
        s1 = open_sentence(entry, "正しさで相手を打ち負かすより、関係を壊し切らない態度のほうがずっと難しいと教えている点です")
        s2 = background_sentence(entry, "怒り返すほうが楽な場面で別の返し方を選べるかが、人間関係の質を分けると読めます")
    elif has(text, "孤立", "つながり", "友を得る"):
        s1 = open_sentence(entry, "人は一人で完全には癒えず、回復も信頼も関係の中で育つと見ている点です")
        s2 = background_sentence(entry, "孤立して整える発想より、安心して弱さを置ける相手を持つほうが人は深く立ち直れます")
    elif has(text, "コミュニティの偉大さ", "思いやりある行動"):
        s1 = open_sentence(entry, "共同体の価値は理念の立派さより、そこで交わされる思いやりの行動量で決まると示している点です")
        s2 = background_sentence(entry, "人間関係の質はきれいな言葉より、日々どれだけ相手に手を伸ばせたかで測られると読めます")
    elif has(text, "向き合い続ける", "見つめ合う", "ありのままに見てもらう"):
        s1 = open_sentence(entry, "近い関係の本質を密着そのものではなく、相手とどう向き合い続けるかに置いている点です")
        s2 = background_sentence(entry, "関係を決めるのは言葉の量より、並んで立てるかどうかだと読むとかなり深く刺さります")
    elif has(text, "友人", "世界を連れてくる"):
        s1 = open_sentence(entry, "よい友人は慰め役というより、自分の中にまだ無かった世界を連れてくる存在だと見ている点です")
        s2 = background_sentence(entry, "安心だけでなく、自分を広げてくれる相手こそ大事な関係だと読み直せます")
    elif has(text, "人生にどんな変化", "他の女性を助けない", "思いやりある行動"):
        s1 = open_sentence(entry, "関係を受け取るものではなく、自分からどう差し出すかで作るものだと示している点です")
        s2 = background_sentence(entry, "助けられるのを待つより、先に助ける側へ回る人が信頼を厚くしていくと読めます")
    elif has(text, "心のこもった言葉"):
        s1 = open_sentence(entry, "人を大きく変えるのは派手な正論より、心が通った一言のほうだと見抜いている点です")
        s2 = background_sentence(entry, "関係の修復に必要なのは正しさより温度かもしれない、と立ち止まらせる言葉です")
    elif has(text, "どんな気持ちにさせたか"):
        s1 = open_sentence(entry, "人は内容そのものより、一緒にいた時の感情の記憶を長く持つと教えている点です")
        s2 = background_sentence(entry, "関係の質は伝えた情報より残した体温で決まる、その視点に切り替わります")
    elif has(text, "不可能なことなどない"):
        s1 = open_sentence(entry, "愛がある時、人は自分の限界を少し超えて動けると信じている点がまっすぐです")
        s2 = background_sentence(entry, "誰かのためなら踏ん張れる感覚を肯定するので、関係が人を強くする側面が見えてきます")
    elif has(text, "幸せは遠くに", "今ここ"):
        s1 = open_sentence(entry, "関係の幸福を大きな完成形ではなく、今ここで感じ直せるものとして捉えている点です")
        s2 = background_sentence(entry, "遠くの理想を追いかけすぎず、すでにあるつながりに気づくための言葉として使えます")
    elif has(text, "感謝は空腹感を消す"):
        s1 = open_sentence(entry, "足りないものばかり数えると関係は痩せるので、感謝がその飢えを和らげると示している点です")
        s2 = background_sentence(entry, "満たされなさを責め合いに変える前に、あるものへ目を向ける視点として効きます")
    elif has(text, "自らの光", "朝だ"):
        s1 = open_sentence(entry, "誰かに照らされるのを待つのでなく、自分が関係の中で光る側に回れと促している点です")
        s2 = background_sentence(entry, "受け身の期待を越え、自分が空気を変える一人になれると読むと力が出ます")
    elif has(text, "愛嬌", "柔らかい武器"):
        s1 = open_sentence(entry, "人を動かす力は強さや圧ではなく、柔らかさの中にも宿ると見抜いている点です")
        s2 = background_sentence(entry, "関係をこじらせない賢さとしての愛嬌を評価しているので、かなり日本的な含みがあります")
    elif has(text, "出逢い", "根底から変える"):
        s1 = open_sentence(entry, "たった一つの出会いが、その後の人生の地盤そのものを変えることがあると語っている点です")
        s2 = background_sentence(entry, "人間関係を偶然で流さず、誰と出会うかを人生の大事な出来事として扱う視点が残ります")
    else:
        s1 = open_sentence(entry, "欲しい関係を待つだけでなく、自分がどう関わるかを先に問う言葉になっています")
        s2 = background_sentence(entry, "受け身で愛情を測るより、自分から差し出す敬意や柔らかさが関係を変えると読めます")
    return f"{s1} {s2}"


def want_to_quit(entry):
    text = normalize(entry["quote_ja"])

    if has(text, "何もかも", "強くいる"):
        s1 = open_sentence(entry, "全部が崩れて見える日でも、自分まで崩し切らなくていいと支えている点です")
        s2 = background_sentence(entry, "ここで言う強さは平気さではなく、しんどい日を渡り切る姿勢そのものだと読めます")
    elif has(text, "自分を小さくしない"):
        s1 = open_sentence(entry, "出来事を支配できなくても、それで自分の価値まで縮める必要はないと切り分けている点です")
        s2 = background_sentence(entry, "失敗した出来事と、価値のない自分を同一視しないための言葉としてかなり効きます")
    elif has(text, "なっていく途中"):
        s1 = open_sentence(entry, "今の不完全さを欠陥ではなく、まだ途中にいる証拠として見直している点です")
        s2 = background_sentence(entry, "完成していないことを失敗扱いしない、その余白が続ける力を作ってくれます")
    elif has(text, "動き始める"):
        s1 = open_sentence(entry, "行き詰まりの出口を、正解探しより先に『とにかく動くこと』へ置いている点です")
        s2 = background_sentence(entry, "諦めるか固まるかの二択から降りて、動きながら道を見つけろという現実的な助言になります")
    elif has(text, "喜びはちゃんと見つけられる"):
        s1 = open_sentence(entry, "苦しい時期でも喜びまで全部失ったわけではない、と感情の全滅を止めている点です")
        s2 = background_sentence(entry, "暗さが全面を覆って見える日に、小さな喜びの存在を認めるだけでもかなり違います")
    elif has(text, "生きることそのものが"):
        s1 = open_sentence(entry, "ただ生き延びること自体が、ある日には十分すぎる勇気になると認めている点です")
        s2 = background_sentence(entry, "立て直せない日まで自分を責めなくていい、その最低限を肯定してくれるので救いがあります")
    elif has(text, "言葉にしていい", "扱いやすくなる"):
        s1 = open_sentence(entry, "感情を押し込めるより、言葉にして扱える大きさへ変えるほうが回復につながると示している点です")
        s2 = background_sentence(entry, "しんどさは隠すほど増幅しやすいので、言葉にすること自体が立ち直りの一歩になります")
    elif has(text, "痛み", "殻", "割れて"):
        s1 = open_sentence(entry, "痛みをただの損失でなく、理解の殻が割れていく過程として捉えている点です")
        s2 = background_sentence(entry, "苦しみを無意味だと感じる時ほど、この見方は心を少し前へ押してくれます")
    elif has(text, "ドアが閉まれば"):
        s1 = open_sentence(entry, "終わった扉に意識を貼りつけたままだと、新しく開いている可能性を見逃すと教えています")
        s2 = background_sentence(entry, "失ったものばかり見て動けなくなる時に、視線を少しずらすだけで道が変わると分かります")
    elif has(text, "障害物", "迂回路"):
        s1 = open_sentence(entry, "障害を前進の終わりではなく、進み方を変える合図として捉え直している点です")
        s2 = background_sentence(entry, "まっすぐ行けないから終わりではなく、別ルートが見えてくるという読みが支えになります")
    elif has(text, "時間", "最も不平等"):
        s1 = open_sentence(entry, "諦めたくなる時ほど、何に時間を使っているかが未来を分けると突いている点です")
        s2 = background_sentence(entry, "気力がない日でも、時間の使い方を少し戻すだけで立て直しのきっかけになります")
    elif has(text, "半分は成功"):
        s1 = open_sentence(entry, "最初の突破口は条件の改善より、自分に賭ける感覚を取り戻すことだと示している点です")
        s2 = background_sentence(entry, "うまくいく保証がなくても、信じる側に回るだけで人の動きはかなり変わります")
    elif has(text, "意味の追求"):
        s1 = open_sentence(entry, "幸福の気分より、自分が何のために生きるのかという意味のほうが人を持たせると見ている点です")
        s2 = background_sentence(entry, "しんどさを根性で越えるのでなく、続ける理由を取り戻す方向へ導いてくれます")
    elif has(text, "可能性を信じる力", "最大の武器"):
        s1 = open_sentence(entry, "武器になるのは現状の能力より、自分の可能性を見切らない姿勢だと語っている点です")
        s2 = background_sentence(entry, "諦める時に先に折れるのは能力でなく自己評価なので、そこを守る言葉として使えます")
    elif has(text, "傷が深ければ深いほど"):
        s1 = open_sentence(entry, "深い傷はそのまま深い回復の土台にもなりうる、と痛みの反転可能性を示している点です")
        s2 = background_sentence(entry, "つらい経験を傷だけで終わらせず、強さに変わる余地を残すので救われます")
    elif has(text, "毎日同じこと", "違う結果"):
        s1 = open_sentence(entry, "変わりたいのに同じやり方にしがみつく矛盾を容赦なく指摘している点です")
        s2 = background_sentence(entry, "詰んだ感じの裏には、まだ変えていないやり方があると気づかせてくれます")
    elif has(text, "ビジョン", "理解しなくても"):
        s1 = open_sentence(entry, "周囲の理解が追いつかなくても、自分の見ている方向に忠実であれと励ましている点です")
        s2 = background_sentence(entry, "孤独を理由にやめそうな時、自分のビジョンまで疑わなくていいと支えてくれます")
    elif has(text, "困難と戦う", "諦めない姿"):
        s1 = open_sentence(entry, "美しいのは結果より、困難の中で諦めずに向き合っている姿だと見ている点です")
        s2 = background_sentence(entry, "報われていない途中の自分にも価値があると思わせてくれる言葉です")
    elif has(text, "成功するところまで続ければ"):
        s1 = open_sentence(entry, "失敗は出来事そのものではなく、途中でやめた時に確定するものだと再定義している点です")
        s2 = background_sentence(entry, "今つらいのは失敗したからでなく、まだ途中だからだと思えた時に少し楽になります")
    elif has(text, "結果が出ないとき", "どういう自分でいられるか"):
        s1 = open_sentence(entry, "成果が出ない時期にどんな自分でいられるかこそ、本当の実力だと見ている点です")
        s2 = background_sentence(entry, "うまくいっていない時の姿勢が次のきっかけを作る、その遅い因果を信じさせる言葉です")
    else:
        s1 = open_sentence(entry, "結果が見えない時間を『失敗で確定したもの』として扱う早さを止めている点です")
        s2 = background_sentence(entry, "途中で閉じなければまだ途中だ、という見方が続ける力を支えてくれます")
    return f"{s1} {s2}"


def rewrite(entry):
    category = entry["category"]
    if entry["author"] == "Original":
        return entry.get("meaning_premium")
    if category == "self_love":
        return self_love(entry)
    if category == "positive":
        return positive(entry)
    if category == "courage":
        return courage(entry)
    if category == "inner_strength":
        return inner_strength(entry)
    if category == "love_crush":
        return love_crush(entry)
    if category == "family_love":
        return family_love(entry)
    if category == "for_my_child":
        return for_my_child(entry)
    if category == "relationships":
        return relationships(entry)
    if category == "want_to_quit":
        return want_to_quit(entry)
    return entry.get("meaning_premium")


def main():
    for path in FILES:
        with open(path) as f:
            data = json.load(f)

        for entry in data:
            if entry.get("author") in AUTHOR_FIXES:
                entry.update(AUTHOR_FIXES[entry["author"]])
            if entry.get("author") != "Original":
                entry["meaning_premium"] = rewrite(entry)

        with open(path, "w") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")

    print("rewritten")


if __name__ == "__main__":
    main()
