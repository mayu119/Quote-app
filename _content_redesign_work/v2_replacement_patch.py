import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QUOTES = ROOT / "QuoteApp/Sources/Resources/quotes.json"
OUT = Path("/private/tmp/quotes-v2.json")

NEW_AUTHORS = {
    "Kate Chopin": ("ケイト・ショパン", "アメリカの小説家", 1850, 1904, "『目覚め』で近代女性の内面を描いた小説家。"),
    "Frances Hodgson Burnett": ("フランシス・ホジソン・バーネット", "イギリス生まれのアメリカの児童文学作家", 1849, 1924, "『秘密の花園』『小公女』で知られる児童文学作家。"),
    "Mary Wollstonecraft": ("メアリ・ウルストンクラフト", "イギリスの思想家・著述家", 1759, 1797, "『女性の権利の擁護』を著した思想家。"),
    "Mary Shelley": ("メアリー・シェリー", "イギリスの小説家", 1797, 1851, "『フランケンシュタイン』を著した小説家。"),
    "Jane Addams": ("ジェーン・アダムズ", "アメリカの社会活動家・著述家", 1860, 1935, "ハル・ハウスを設立し、社会倫理を著した活動家。"),
    "Emily Brontë": ("エミリー・ブロンテ", "イギリスの小説家・詩人", 1818, 1848, "『嵐が丘』を著した小説家・詩人。"),
    "Lucy Maud Montgomery": ("ルーシー・モード・モンゴメリ", "カナダの小説家", 1874, 1942, "『赤毛のアン』シリーズを著した小説家。"),
    "大弐三位": ("だいにのさんみ", "平安時代の歌人", 999, 1082, "百人一首にも歌が残る平安時代の歌人。"),
}

# id, author, quote_ja, quote_en, source_context
ROWS = r"""
women_quote_338	Charlotte Brontë	私は籠に閉じ込められた鳥ではない。どんな網も私を縛れない。	I am no bird; and no net ensnares me.	原典: Charlotte Brontë『Jane Eyre』第23章。
women_quote_342	Emily Dickinson	私は誰でもない。あなたは？	I'm Nobody! Who are you?	原典: Emily Dickinson, poem 288『I'm Nobody! Who are you?』。Poetry Foundation掲載本文。
women_quote_348	Kate Chopin	伝統と偏見の平地を越えて飛ぶ鳥には、強い翼が必要です。	The bird that would soar above the level plain of tradition and prejudice must have strong wings.	原典: Kate Chopin『The Awakening』第27章。Project Gutenberg #160。
women_quote_351	Louisa May Alcott	嵐は怖くありません。自分の船を操ることを学んでいるからです。	I am not afraid of storms, for I am learning how to sail my ship.	原典: Louisa May Alcott『Little Women』第23章。Project Gutenberg #514。
women_quote_358	Frances Hodgson Burnett	薔薇を育てる場所には、アザミは育ちません。	Where you tend a rose, my lad, a thistle cannot grow.	原典: Frances Hodgson Burnett『The Secret Garden』第27章。Project Gutenberg #113。
women_quote_361	Anne Frank	誰も、世界をよくするために始める瞬間を待つ必要はありません。	How wonderful it is that nobody need wait a single moment before starting to improve the world.	原典: Anne Frank『The Diary of a Young Girl』1944年7月26日の日記。Anne Frank House所蔵本文。
women_quote_375	Emily Dickinson	永遠とは、いまこの瞬間の積み重ねです。	Forever is composed of Nows.	原典: Emily Dickinson, poem 690『Forever—is composed of Nows—』。Poetry Foundation掲載本文。
women_quote_376	Anne Frank	私は不幸のすべてではなく、残っている美しさのすべてを考えます。	I don't think of all the misery, but of all the beauty that still remains.	原典: Anne Frank『The Diary of a Young Girl』1944年7月15日の日記。Anne Frank House所蔵本文。
women_quote_389	Mary Wollstonecraft	私は女性が男性を支配してほしいのではなく、自分自身を治めてほしいのです。	I do not wish women to have power over men; but over themselves.	原典: Mary Wollstonecraft『A Vindication of the Rights of Woman』第4章。Project Gutenberg #3420。
women_quote_400	Mary Shelley	気をつけなさい。私は恐れを知らない。だから、力を持つのです。	Beware; for I am fearless, and therefore powerful.	原典: Mary Shelley『Frankenstein』第24章。Project Gutenberg #84。
women_quote_401	Virginia Woolf	署名せずに多くの詩を書いた「匿名の人」は、しばしば女性だったのではないでしょうか。	Anon, who wrote so many poems without signing them, was often a woman.	原典: Virginia Woolf『A Room of One's Own』第3章。
women_quote_411	Mary Shelley	心を静めるものは、魂が知性の目を向けられる、揺るがない目的です。	Nothing contributes so much to tranquillize the mind as a steady purpose—a point on which the soul may fix its intellectual eye.	原典: Mary Shelley『Frankenstein』第4章。Project Gutenberg #84。
women_quote_414	Jane Austen	過去は、思い出すことで喜びが戻るものだけを考えればいいのです。	Think only of the past as its remembrance gives you pleasure.	原典: Jane Austen『Pride and Prejudice』第58章。Project Gutenberg #1342。
women_quote_416	Jane Addams	自分のために得た善は、すべての人のために確かなものとなり、共同の暮らしに根づくまでは不確かです。	The good we secure for ourselves is precarious and uncertain until it is secured for all of us and incorporated into our common life.	原典: Jane Addams『Democracy and Social Ethics』第1章「A Function of the Social Settlement」。Project Gutenberg #15487。
women_quote_420	Emily Dickinson	自分がどこまで高くなれるかは、呼び起こされるまでわかりません。	We never know how high we are till we are called to rise.	原典: Emily Dickinson, poem 1176『We never know how high we are』。Poetry Foundation掲載本文。
women_quote_432	Emily Brontë	私たちの魂が何でできていても、彼の魂と私の魂は同じものです。	Whatever our souls are made of, his and mine are the same.	原典: Emily Brontë『Wuthering Heights』第9章。
women_quote_434	Christina Rossetti	私は先にあなたを愛した。でも、あとから来たあなたの愛は、私の愛を越えて高く歌いました。	I loved you first: but afterwards your love, outsoaring mine, sang such a loftier song.	原典: Christina Rossetti『I Loved You First: But Afterwards』。Poetry Foundation掲載本文。
women_quote_438	Elizabeth Barrett Browning	去ってください。それでも私は、これからずっとあなたの影の中に立つでしょう。	Go from me. Yet I feel that I shall stand henceforward in thy shadow.	原典: Elizabeth Barrett Browning『Sonnets from the Portuguese』第90番。
women_quote_439	Christina Rossetti	夜の静けさの中で私のもとへ来て。夢の語らない静けさの中で来て。	Come to me in the silence of the night; come in the speaking silence of a dream.	原典: Christina Rossetti『Echo』。Poetry Foundation掲載本文。
women_quote_447	Jane Austen	踊るのが好きということは、恋に落ちるための確かな一歩でした。	To be fond of dancing was a certain step towards falling in love.	原典: Jane Austen『Pride and Prejudice』第3章。Project Gutenberg #1342。
women_quote_460	Louisa May Alcott	家はすてきな場所です。けれど、そこを離れて探しに出なければ、家のよさがわからないこともあります。	Home is a nice place, though you may have to leave it to find it.	原典: Louisa May Alcott『Little Women』第22章。Project Gutenberg #514。
women_quote_461	Louisa May Alcott	私たちには父と母がいて、そしてお互いがいる。それで十分に幸せです。	We've got Father and Mother, and each other, to make up for it.	原典: Louisa May Alcott『Little Women』第1章。Project Gutenberg #514。
women_quote_470	Maria Montessori	子どもは、私たちとは違う仕方で環境と関わり、それを吸収します。	The child has a different relation to his environment from ours; the child absorbs it.	原典: Maria Montessori『The Absorbent Mind』第7章。Association Montessori Internationaleの引用資料。
women_quote_471	Kahlil Gibran	あなたは子どもたちに愛を与えても、考えを与えることはできません。子どもたちは自分の考えを持つからです。	You may give them your love but not your thoughts, for they have their own thoughts.	原典: Kahlil Gibran『The Prophet』「On Children」。
women_quote_476	Anne Frank	私はそれでも、人は本当は心の底では善いものだと信じています。	I keep my ideals, because in spite of everything I still believe that people are really good at heart.	原典: Anne Frank『The Diary of a Young Girl』1944年7月15日の日記。Anne Frank House所蔵本文。
women_quote_478	Maria Montessori	子どもの発達に最初に必要なのは、集中です。	The first essential for the child's development is concentration.	原典: Maria Montessori『The Absorbent Mind』第7章。Association Montessori Internationaleの引用資料。
women_quote_480	Janusz Korczak	子どもには、尊敬される権利があります。	The child has a right to respect.	原典: Janusz Korczak『The Child's Right to Respect』。
women_quote_481	Maria Montessori	手は、人間の知性の道具です。	The hands are the instruments of man's intelligence.	原典: Maria Montessori『The Secret of Childhood』第7章。
women_quote_483	Lucy Maud Montgomery	十月のある世界に生きていることが、とても嬉しい。	I'm so glad I live in a world where there are Octobers.	原典: Lucy Maud Montgomery『Anne of Green Gables』第16章。Project Gutenberg #45。
women_quote_484	Maria Montessori	子どもは、大人にすべてを負う受け身の存在ではなく、自分自身をつくる能動的な存在です。	The child is not an inert being who owes everything to the adult; he is an active being who has to construct himself.	原典: Maria Montessori『The Absorbent Mind』第7章。
women_quote_097	Janusz Korczak	子どもは、ただ小さいだけの人間です。	A child is a human being, just a smaller one.	原典: Janusz Korczak『How to Love a Child』。
women_quote_485	Fred Rogers	怖いニュースを見たときは、いつも助けている人を探しなさい。	When I was a boy and I would see scary things in the news, my mother would say to me, "Look for the helpers."	原典: Fred Rogersの1986年インタビュー発言。『The World According to Mister Rogers』所収。
women_quote_486	Maria Montessori	教育の目的は知識を増やすことではなく、子どもが発明し発見できる可能性をつくることです。	The goal of education is not to increase the amount of knowledge but to create the possibilities for a child to invent and discover.	原典: Maria Montessori『The Absorbent Mind』。
women_quote_492	Frances Hodgson Burnett	正しい見方をすれば、世界全体が庭だとわかります。	If you look the right way, you can see that the whole world is a garden.	原典: Frances Hodgson Burnett『The Secret Garden』第27章。Project Gutenberg #113。
women_quote_497	Jane Austen	これほど心を開き、好みが似ていて、気持ちが調和した二つの心は、ほかにありえなかったでしょう。	There could have been no two hearts so open, no tastes so similar, no feelings so in unison.	原典: Jane Austen『Persuasion』第23章。Project Gutenberg #105。
women_quote_500	大弐三位	有馬山 猪名の笹原 風吹けば いでそよ人を 忘れやはする		出典: 『小倉百人一首』第58番、大弐三位。
women_quote_504	George Eliot	愛する人とともに安心していられることは、言葉にできないほどの慰めです。	O the comfort, the inexpressible comfort of feeling safe with a person.	原典: George Eliot『Middlemarch』第22章。
women_quote_508	Charlotte Brontë	この世で最も大きな幸福の一つは、愛され、自分の存在が相手の慰めになっていると感じることです。	There is no happiness like that of being loved by your fellow-creatures, and feeling that your presence is an addition to their comfort.	原典: Charlotte Brontë『Jane Eyre』第24章。
women_quote_509	Christina Rossetti	いいえ、ジョン。あなたに愛していると言ったことはありません。待たないでください。	No, thank you, John. I never said I loved you; wait not for me.	原典: Christina Rossetti『No, Thank You, John』。Poetry Foundation掲載本文。
women_quote_510	bell hooks	愛は意志の行為です。意図であり、行動でもあります。	Love is an act of will—namely, both an intention and an action.	原典: bell hooks『All About Love: New Visions』第1章。
women_quote_512	Toni Morrison	自分を解放することは一つのこと。でも、解放された自分を自分のものとして生きることは、また別のことです。	Freeing yourself was one thing, claiming ownership of that freed self was another.	原典: Toni Morrison『Beloved』第26章。
women_quote_513	Maya Angelou	友人は、見知らぬ人の顔の向こうで待っているかもしれません。	A friend may be waiting behind a stranger's face.	原典: Maya Angelou『Letter to My Daughter』。
women_quote_514	Rainer Maria Rilke	愛とは、二つの孤独が互いを守り、触れ合い、挨拶することです。	Love consists in this, that two solitudes protect and touch and greet each other.	原典: Rainer Maria Rilke『Letters to a Young Poet』。
women_quote_518	Christina Rossetti	道はずっと上り坂ですか。はい、最後まで。	Does the road wind uphill all the way? Yes, to the very end.	原典: Christina Rossetti『Up-Hill』。Poetry Foundation掲載詩。
women_quote_519	Jane Austen	世界の半分は、残り半分の楽しみを理解できません。	One half of the world cannot understand the pleasures of the other.	原典: Jane Austen『Emma』第9章。Project Gutenberg #158。
women_quote_520	Emily Brontë	彼は私が愛していることを決して知りません。美しいからではなく、彼が私以上に私自身だからです。	He shall never know I love him: and that, not because he's handsome, but because he's more myself than I am.	原典: Emily Brontë『Wuthering Heights』第9章。
women_quote_525	Lucy Maud Montgomery	明日は、まだ失敗をひとつも持っていない新しい日だと思うと素敵ね。	Isn't it nice to think that tomorrow is a new day with no mistakes in it yet?	原典: Lucy Maud Montgomery『Anne of Green Gables』第21章。Project Gutenberg #45。
women_quote_526	Kate Chopin	海の声は魂に語りかけます。	The voice of the sea speaks to the soul.	原典: Kate Chopin『The Awakening』第6章。Project Gutenberg #160。
women_quote_527	Mary Shelley	目的には忠実に、岩のように揺るがずありなさい。	Be steady to your purposes and firm as a rock.	原典: Mary Shelley『Frankenstein』第4章。Project Gutenberg #84。
women_quote_528	Audre Lorde	私の力を、自分の vision のために使うことを恐れずに選ぶと、恐れがあるかどうかは少しずつ重要でなくなります。	When I dare to be powerful—to use my strength in the service of my vision—then it becomes less and less important whether I am afraid.	原典: Audre Lorde『Sister Outsider』所収エッセイ。
women_quote_529	Brene Brown	弱さを見せることは、革新と創造と変化の生まれる場所です。	Vulnerability is the birthplace of innovation, creativity and change.	原典: Brene BrownのTED Talk「The power of vulnerability」（2010年）。
women_quote_530	Christina Rossetti	私の人生は、色あせた葉のようです。	My life is like a faded leaf.	原典: Christina Rossetti『A Better Resurrection』。Poetry Foundation掲載本文。
women_quote_532	Mary Shelley	あなたには希望があり、目の前に世界が広がっている。絶望する理由はありません。	You have hope, and the world before you, and have no cause for despair.	原典: Mary Shelley『Frankenstein』Letter 4。Project Gutenberg #84。
women_quote_533	Emily Brontë	私の魂は臆病ではありません。世界の嵐に震えるものでもない。	No coward soul is mine, no trembler in the world's storm-troubled sphere.	原典: Emily Brontë『No Coward Soul Is Mine』。『Poems by Currer, Ellis, and Acton Bell』所収。
women_quote_535	Anne Frank	書くと、私はすべてを振り払えます。悲しみは消え、勇気が生まれ直します。	I can shake off everything as I write; my sorrows disappear, my courage is reborn.	原典: Anne Frank『The Diary of a Young Girl』1944年4月5日の日記。Anne Frank House所蔵本文。
women_quote_536	Charlotte Brontë	自尊心を守る必要があり、状況が求めるなら、私はひとりで生きられます。	I can live alone, if self-respect, and circumstances require me so to do.	原典: Charlotte Brontë『Jane Eyre』第28章。
women_quote_537	Mary Wollstonecraft	世界に欠けているのは、慈善ではなく正義です。	It is justice, not charity, that is wanting in the world.	原典: Mary Wollstonecraft『A Vindication of the Rights of Woman』第13章。Project Gutenberg #3420。
women_quote_540	Maya Angelou	起きることのすべてを支配できなくても、それによって自分を小さくされないと決めることはできます。	You may not control all the events that happen to you, but you can decide not to be reduced by them.	原典: Maya Angelou『Letter to My Daughter』。
women_quote_542	Mary Shelley	人の心にとって、大きく突然の変化ほど痛いものはありません。	Nothing is so painful to the human mind as a great and sudden change.	原典: Mary Shelley『Frankenstein』第3章。Project Gutenberg #84。
women_quote_544	Christina Rossetti	私の心は歌う鳥のよう。水のある枝に巣をかける鳥のようです。	My heart is like a singing bird whose nest is in a watered shoot.	原典: Christina Rossetti『A Birthday』。Poetry Foundation掲載本文。
women_quote_545	Mary Wollstonecraft	心は、偏見だけをよりどころにしていると、いつまでも不安定なままです。	The mind will ever be unstable that has only prejudices to rest on.	原典: Mary Wollstonecraft『A Vindication of the Rights of Woman』第2章。Project Gutenberg #3420。
""".strip().splitlines()

CATEGORY_COPY = {
    "self_love": ("自分を小さく扱わず、静かに自分の輪郭へ戻るための言葉。", "誰かの期待に合わせ続けなくて大丈夫です。今夜は、自分の感覚と尊厳を守る小さな選択をひとつだけ残して、あとは休みましょう。", "自分の側に戻る。", "今夜は、自分の側に戻る"),
    "positive": ("見落としていた小さな明るさへ、視線を戻してくれる言葉。", "無理に明るくならなくて大丈夫です。それでも、今日の中に残っている安心や美しさをひとつ見つけて、自分に渡してあげましょう。", "小さな明るさを、ひとつ見つける。", "小さな明るさを見る"),
    "courage": ("怖さがあっても、自分の選択を少し取り戻すための言葉。", "不安が消えるのを待たなくても大丈夫です。返事を明日に延ばす、助けを呼ぶ、境界線を引く。安全を増やす一歩から始められます。", "恐れだけに、決めさせない。", "安全を増やす一歩を選ぶ"),
    "inner_strength": ("揺れる日にも、自分の中へ戻る一点を持つための言葉。", "今夜すべてを解決しなくて大丈夫です。自分を責める反省会を閉じ、明日の自分を少し助ける選択だけを残しましょう。", "戻れる一点を、ひとつ持つ。", "自分を責める反省会を閉じる"),
    "love_crush": ("惹かれる気持ちと、自分の輪郭を同時に大切にする言葉。", "好きな人に合わせて自分を消す必要はありません。相手の自由も自分の安心も守れる距離を、あなたの速度で選んでいいのです。", "近づいても、自分を失わない。", "好きな人の前でも自分でいる"),
    "family_love": ("近さと距離、支えることと任せることを見直すための言葉。", "家族を大切に思っていても、すべてを背負わなくて大丈夫です。今日できる範囲で安心を分け合い、自分の休む場所も守りましょう。", "愛を持ったまま、自分も守る。", "家族の中でも、自分を休ませる"),
    "for_my_child": ("子どもを一人の人として尊重し、安心できる環境をつくるための言葉。", "すぐに正解を教えたり、全部を先回りしたりしなくて大丈夫です。子どもにも自分にも、試して休める余白を渡してあげましょう。", "急かさないことも、育てること。", "安心できる余白を守る"),
    "relationships": ("安心と境界線のある関係を、自分の基準で選ぶための言葉。", "愛されるために無理を続けなくて大丈夫です。尊重、安心、実際の行動があるかを見ながら、互いの自由を守れる関係を選びましょう。", "安心できる関係を、選んでいい。", "関係の中でも、自分を守る"),
    "want_to_quit": ("投げ出したい夜に、負担を小さくして次の一歩へ戻るための言葉。", "今すぐ元気にならなくて大丈夫です。休む、書く、助けを求める、明日に延ばす。自分を壊さない選択をひとつ残せば十分です。", "今日の分だけ、自分を守る。", "今日の分だけ、自分を守る"),
}

def main():
    parsed = {}
    for line in ROWS:
        qid, author, quote_ja, quote_en, source = line.split("\t")
        parsed[qid] = (author, quote_ja, quote_en or None, source)
    if len(parsed) != 61:
        raise ValueError(f"replacement count={len(parsed)}")
    data = json.loads(QUOTES.read_text())
    by_id = {q["id"]: q for q in data}
    for qid, (author, quote_ja, quote_en, source) in parsed.items():
        q = by_id[qid]
        q["author"] = author
        q["quote_ja"] = quote_ja
        q["quote_en"] = quote_en
        q["source_context"] = source
        preview, premium, punchline, hook = CATEGORY_COPY[q["category"]]
        q["meaning_preview"] = preview
        q["meaning_premium"] = premium
        q["punchline"] = punchline
        q["push_notification_hook"] = hook
        if author in NEW_AUTHORS:
            kana, desc, birth, death, fact = NEW_AUTHORS[author]
            q["author_kana"] = kana
            q["author_description"] = desc
            q["author_birth_year"] = birth
            q["author_death_year"] = death
            q["author_fact"] = fact
    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    print(f"wrote {OUT} replacements={len(parsed)}")

if __name__ == "__main__":
    main()
