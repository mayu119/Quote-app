#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

FILES = [
  "QuoteApp/Sources/Resources/quotes.json",
  "QuoteApp/Sources/Resources/quotes_full.json"
].freeze

AFFIRMATIONS = {
  "women_quote_019" => {
    "quote_ja" => "私はそのままで、\n雑に扱われていい存在じゃない。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "自己肯定感が落ちた日に、自分の価値を相手の反応で決め直さないための一文です。",
    "meaning_premium" => "この言葉が守っているのは、自信満々でいることではなく、自分を粗末に扱う流れを止めることです。返信が遅い、比べて落ち込む、優先順位を下げられる。そんな日に『私は雑に扱われていい存在じゃない』と先に決めておくと、選ぶ言葉も距離の取り方も変わります。",
    "source_context" => "アプリオリジナル",
    "punchline" => "私は、雑に扱われていい存在じゃない。",
    "push_notification_hook" => "自分の価値を外に明け渡しそうな日に。"
  },
  "women_quote_020" => {
    "quote_ja" => "私は今日、\n自分を後回しにしすぎない。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "頑張るほど自分を最後に回してしまう日に、優先順位を静かに戻す言葉です。",
    "meaning_premium" => "後回しにしないとは、わがままになることではありません。空腹や疲れを無視しない、嫌なことにすぐ頷かない、少し休む時間を取る。そういう小さな扱いの積み重ねが、自分への信頼を取り戻していきます。",
    "source_context" => "アプリオリジナル",
    "punchline" => "今日は、自分を後回しにしすぎない。",
    "push_notification_hook" => "人に合わせすぎている日に、自分を戻す一言。"
  },
  "women_quote_021" => {
    "quote_ja" => "私は自分の気持ちを、\n先に否定しない。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "悲しい、寂しい、嫌だったという感情に、まず居場所をつくるための言葉です。",
    "meaning_premium" => "感情を信じるとは、感情のまま暴れることではありません。『こんなことで傷つく私は弱い』と切り捨てず、まず感じたことを認めることです。気持ちを否定しないだけで、必要な距離や本当に欲しい言葉が見えやすくなります。",
    "source_context" => "アプリオリジナル",
    "punchline" => "私は、自分の気持ちを先に否定しない。",
    "push_notification_hook" => "感情を飲み込んでしまいそうな日に。"
  },
  "women_quote_022" => {
    "quote_ja" => "私は誰かに選ばれる前に、\nまず自分を選ぶ。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "相手からの好意や評価がないと不安になる日に、軸を自分へ戻す一文です。",
    "meaning_premium" => "選ばれることばかり考えていると、無理をしてでも残ろうとしてしまいます。この言葉は、先に自分の本音と条件を引き受けるためのものです。『私は何を我慢しすぎているか』を見直すきっかけとして読むと、恋愛でも仕事でも効きます。",
    "source_context" => "アプリオリジナル",
    "punchline" => "誰かより先に、まず自分を選ぶ。",
    "push_notification_hook" => "相手軸に傾いている日に、自分を選び直す。"
  },
  "women_quote_023" => {
    "quote_ja" => "私は小さな一歩でも、\nちゃんと前に進んでいる。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "派手な成果がない日に、自分の前進をゼロ扱いしないための言葉です。",
    "meaning_premium" => "前に進んでいる感覚は、大きな変化がないと消えやすいものです。でも、起き上がった、連絡を返した、五分だけ手をつけた。その一歩まで無かったことにしない人のほうが、長く進めます。今日は小さいままでいい、と許可を出すための一文です。",
    "source_context" => "アプリオリジナル",
    "punchline" => "小さな一歩でも、私は前に進んでいる。",
    "push_notification_hook" => "何もできていない気がする日に。"
  },
  "women_quote_024" => {
    "quote_ja" => "私は恋をしても、\n自分の心を置き去りにしない。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "好きな相手に意識が向きすぎて、自分の違和感を見失いそうな日に読む言葉です。",
    "meaning_premium" => "恋の中では、相手の機嫌や温度に敏感になるほど、自分の本音が置き去りになりがちです。この一文は、好きでいることと我慢し続けることを分けるためにあります。好きな気持ちは持ったまま、自分の心まで差し出しすぎない。その線を思い出すための言葉です。",
    "source_context" => "アプリオリジナル",
    "punchline" => "恋をしても、自分の心を置き去りにしない。",
    "push_notification_hook" => "恋の中で自分を見失いそうな夜に。"
  },
  "women_quote_025" => {
    "quote_ja" => "私は疲れた日は、\n休むことを自分に許す。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "休むたびに怠けた気がしてしまう人へ向けた、回復のための言葉です。",
    "meaning_premium" => "休むことに罪悪感があると、身体が止まっても心が休まりません。この言葉は、倒れないための休みを堂々と取るためにあります。頑張る力をなくさないためにも、今日は休んでいいと自分に言えることが、次の前進を支えます。",
    "source_context" => "アプリオリジナル",
    "punchline" => "疲れた日は、休むことを許していい。",
    "push_notification_hook" => "頑張り続けて息切れしている日に。"
  },
  "women_quote_026" => {
    "quote_ja" => "私は人と比べなくても、\n私の魅力を失わない。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "誰かの華やかさを見て、自分のよさまで薄く感じてしまう日に効く一文です。",
    "meaning_premium" => "比べてしまうこと自体は止められなくても、比べた瞬間に自分の価値まで消さなくていい。この言葉は、そのための踏みとどまりです。私は私の輪郭で魅力を持っている、と言い直せると、焦りではなく自分の歩幅で整え直せます。",
    "source_context" => "アプリオリジナル",
    "punchline" => "比べても、私の魅力は消えない。",
    "push_notification_hook" => "他人の輝きに飲まれそうな日に。"
  },
  "women_quote_027" => {
    "quote_ja" => "私はやさしさと強さを、\nどちらも持っていていい。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "やさしくいるほど損をしている気がする日に、しなやかな強さを思い出すための言葉です。",
    "meaning_premium" => "やさしい人は弱い、強い人は冷たい。そんな二択で苦しくなる時があります。この一文は、その思い込みをほどくためにあります。断る時も守る時も、やさしさを失わずに強くいていい。自分のあり方を狭めないための確認として使えます。",
    "source_context" => "アプリオリジナル",
    "punchline" => "やさしさと強さを、どちらも持っていていい。",
    "push_notification_hook" => "やさしいままで強くいたい日に。"
  },
  "women_quote_028" => {
    "quote_ja" => "私は明日を、\n少しだけ楽しみにして眠っていい。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "一日がしんどかった夜に、明日への扉を完全には閉じないための言葉です。",
    "meaning_premium" => "希望は、大きく持てる日ばかりではありません。この言葉は、明日が全部よくなると信じるためではなく、ほんの少しだけ期待を残して眠るためにあります。次の日の自分に、重さではなく余白を渡すための一文です。",
    "source_context" => "アプリオリジナル",
    "punchline" => "明日を、少しだけ楽しみにして眠っていい。",
    "push_notification_hook" => "今日が重かった夜、明日に余白を残すために。"
  },
  "women_quote_191" => {
    "quote_ja" => "私は境界線を引いても、\n冷たい人にはならない。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "断ることや距離を取ることに罪悪感がある人へ向けた、境界線の言葉です。",
    "meaning_premium" => "境界線を引くと、相手を突き放したように感じることがあります。でも、本当に守りたい関係ほど、無理のない距離が必要です。冷たくなったのではなく、自分を守る線を引いているだけだと認めると、関係の持ち方がずっと健やかになります。",
    "source_context" => "アプリオリジナル",
    "punchline" => "境界線を引いても、私は冷たくならない。",
    "push_notification_hook" => "断ることに罪悪感がある日に。"
  },
  "women_quote_192" => {
    "quote_ja" => "今日はうまくできなくても、\n私の価値は減らない。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "失敗や空回りを、そのまま自己否定へつなげないための言葉です。",
    "meaning_premium" => "うまくできなかった日ほど、人は結果で自分を裁きやすくなります。この一文は、出来不出来と存在の価値を切り分けるためのものです。反省はしていい。でも、自分まで減点しすぎない。その姿勢が、明日の立て直しを楽にします。",
    "source_context" => "アプリオリジナル",
    "punchline" => "うまくできなくても、私の価値は減らない。",
    "push_notification_hook" => "失敗を全部自分のせいにしてしまう日に。"
  },
  "women_quote_193" => {
    "quote_ja" => "私は私のペースで、\n整っていけばいい。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "人のスピードに合わせるほど苦しくなる時、自分の歩幅を取り戻す言葉です。",
    "meaning_premium" => "成長も回復も、きれいな一直線では進みません。それなのに周りの早さを見ると、自分だけ遅い気がしてしまいます。この言葉は、急いで整えようとして崩れるより、自分のペースで戻っていけばいいと許すためのものです。",
    "source_context" => "アプリオリジナル",
    "punchline" => "私は、私のペースで整っていけばいい。",
    "push_notification_hook" => "周りと比べて焦っている日に。"
  },
  "women_quote_194" => {
    "quote_ja" => "断ることは、\n私を守るためのやさしさでもある。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "NO を言えずに抱え込みやすい人へ向けた、実用的な自己対話です。",
    "meaning_premium" => "断ると嫌われる、期待を裏切る。そう感じるほど、無理な引き受けが増えていきます。この一文は、断ることを攻撃ではなく自己保全として捉え直すためのものです。守れていない自分を責めるのではなく、次はどこで線を引くかを考える材料になります。",
    "source_context" => "アプリオリジナル",
    "punchline" => "断ることも、自分を守るやさしさ。",
    "push_notification_hook" => "本当は無理なのに引き受けそうな日に。"
  },
  "women_quote_195" => {
    "quote_ja" => "泣いたあとでも、\n私はまた立て直せる。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "感情が崩れた日を、そのまま終わり扱いしないための一文です。",
    "meaning_premium" => "泣いた自分をみっともないと感じる時ほど、回復は遠のきます。この言葉は、崩れたことと、もう戻れないことは別だと教えるためにあります。泣いたあとに水を飲む、眠る、誰かに頼る。そういう小さな立て直しも、ちゃんと再出発です。",
    "source_context" => "アプリオリジナル",
    "punchline" => "泣いたあとでも、また立て直せる。",
    "push_notification_hook" => "感情があふれた日の夜に。"
  },
  "women_quote_196" => {
    "quote_ja" => "私は誰かの期待より、\n自分の本音を大切にする。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "周囲の期待に応えようとするほど、自分の声が小さくなっている日に効く言葉です。",
    "meaning_premium" => "期待に応える力は長所ですが、それだけで生きると本音が痩せていきます。この一文は、自分勝手になるためではなく、自分の人生の責任を他人の期待で埋めないためのものです。今日は何が本当は嫌で、何を望んでいるのかを聞き直す入口になります。",
    "source_context" => "アプリオリジナル",
    "punchline" => "期待より先に、自分の本音を大切にする。",
    "push_notification_hook" => "人の期待でいっぱいになっている日に。"
  },
  "women_quote_197" => {
    "quote_ja" => "一歩しか進めない日でも、\n私は止まっていない。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "前進の量ばかり気にして、自分を厳しく追い立ててしまう日に読む言葉です。",
    "meaning_premium" => "進みが遅い日は、止まっている気分になりがちです。でも、昨日より一歩でも動いたなら、それは前進です。この一文は、完璧な速度を求めて何もできなくなるより、不完全でも続けるほうを選ぶためにあります。",
    "source_context" => "アプリオリジナル",
    "punchline" => "一歩でも進めたなら、私は止まっていない。",
    "push_notification_hook" => "焦りで自分を責めている日に。"
  },
  "women_quote_198" => {
    "quote_ja" => "私は愛されるために、\n無理に演じなくていい。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "嫌われないために明るく振る舞いすぎて、あとで苦しくなる人へ向けた言葉です。",
    "meaning_premium" => "愛されたいと思うほど、人は都合のいい役を引き受けやすくなります。この言葉は、好かれるために自分を削り続けないための確認です。演じることを少しやめると、残る関係は少なくても、ずっと深くなります。",
    "source_context" => "アプリオリジナル",
    "punchline" => "愛されるために、無理に演じなくていい。",
    "push_notification_hook" => "いい人を演じ続けて疲れた日に。"
  },
  "women_quote_199" => {
    "quote_ja" => "私は私の人生を、\n私の手で引き受けていく。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "誰かの判断待ちになっている時、自分の人生の主語を戻すための一文です。",
    "meaning_premium" => "環境や相手のせいにしたくなる日ほど、自分の手に残っているものまで見えなくなります。この言葉は、全部をコントロールするためではなく、いま自分が選べるものを取り戻すためにあります。小さくても自分で選ぶ感覚が戻ると、人生への手応えも戻ります。",
    "source_context" => "アプリオリジナル",
    "punchline" => "私は、自分の人生を自分で引き受けていく。",
    "push_notification_hook" => "人生の主語を取り戻したい日に。"
  },
  "women_quote_200" => {
    "quote_ja" => "今日の私を大切にすることが、\n明日の私を助ける。",
    "quote_en" => nil,
    "author" => "Original",
    "author_kana" => "オリジナル",
    "author_description" => "アプリオリジナルのアファメーション",
    "meaning_preview" => "先の不安ばかり大きくなる時に、今日できるケアへ視点を戻す言葉です。",
    "meaning_premium" => "明日のために頑張ることは大事ですが、今日の自分を置き去りにすると長くは続きません。この一文は、未来をよくする最短距離が、今日の自分を丁寧に扱うことだと思い出させます。睡眠、食事、言葉の選び方まで、いまの扱いが明日の土台になります。",
    "source_context" => "アプリオリジナル",
    "punchline" => "今日の私を大切にすることが、明日の私を助ける。",
    "push_notification_hook" => "未来が不安で、今日を雑にしそうな日に。"
  }
}.freeze

UPDATES = {
  "women_quote_041" => {
    "quote_ja" => "愛は互いを所有しない。\n愛は、愛だけで満ち足りる。",
    "quote_en" => "Love possesses not nor would it be possessed; for love is sufficient unto love.",
    "author" => "Kahlil Gibran",
    "author_kana" => "カリール・ジブラン",
    "author_description" => "詩人・思想家",
    "meaning_preview" => "好きだから近づきたい気持ちと、持ちすぎる苦しさを切り分けてくれる一文です。",
    "meaning_premium" => "恋が苦しくなる時は、愛そのものより『この人を失いたくない』という握りしめる気持ちが強くなっていることがあります。この言葉は、愛を所有や支配と混ぜないためのものです。大切に思うことと、相手を自分の安心の道具にしないこと。その境目を静かに思い出させてくれます。",
    "source_context" => "1923年刊『The Prophet（預言者）』「On Marriage」で語られる一節。",
    "punchline" => "愛は、相手を持つことではなく、愛すること。",
    "push_notification_hook" => "好きな気持ちが苦しさに変わりかけた夜に。"
  },
  "women_quote_084" => {
    "author_kana" => "クロヤナギ・テツコ"
  },
  "women_quote_085" => {
    "author_kana" => "テヅカ・オサム"
  },
  "women_quote_098" => {
    "author_kana" => "ヨシノ・ゲンザブロウ",
    "source_context" => "1937年刊『君たちはどう生きるか』の題名にもなった問い。"
  },
  "women_quote_112" => {
    "author" => "黒柳徹子",
    "author_kana" => "クロヤナギ・テツコ",
    "author_description" => "俳優・司会者・ユニセフ親善大使",
    "source_context" => "黒柳徹子が長年の取材や対話を通して繰り返し伝えてきた、比較に飲まれないための実感ある言葉。"
  },
  "women_quote_113" => {
    "author_kana" => "ホンダ・ソウイチロウ"
  },
  "women_quote_124" => {
    "author_kana" => "イチロー"
  },
  "women_quote_125" => {
    "author_kana" => "オオタニ・ショウヘイ"
  },
  "women_quote_138" => {
    "author_kana" => "ホンダ・ソウイチロウ"
  },
  "women_quote_139" => {
    "author_kana" => "ヨシダ・ショウイン"
  },
  "women_quote_151" => {
    "author_kana" => "ミヤモト・ムサシ",
    "source_context" => "1645年に遺した『独行道』で知られる、宮本武蔵の厳しい自己鍛錬の言葉。"
  },
  "women_quote_152" => {
    "author_kana" => "イナモリ・カズオ",
    "source_context" => "稲盛和夫オフィシャルサイトでも紹介される『能力を未来進行形でとらえる』という考え方。"
  },
  "women_quote_165" => {
    "author_kana" => "セトウチ・ジャクチョウ"
  },
  "women_quote_166" => {
    "author_kana" => "ヨサノ・アキコ",
    "source_context" => "1901年刊『みだれ髪』に収められた、与謝野晶子の代表的な恋の短歌。"
  },
  "women_quote_177" => {
    "quote_ja" => "愛嬌というのはね、\n自分より強いものを倒す\n柔らかい武器だよ。",
    "quote_en" => nil,
    "author" => "夏目漱石",
    "author_kana" => "ナツメ・ソウセキ",
    "author_description" => "近代日本を代表する小説家・英文学者",
    "meaning_preview" => "人間関係を押し切る強さだけで考えず、やわらかさの力を思い出させる言葉です。",
    "meaning_premium" => "この言葉が面白いのは、愛嬌を単なる感じの良さではなく、人を動かす力として捉えているところです。正しさだけでは届かない場面でも、やわらかさや余白が関係をほどくことがある。張り詰めて人と向き合いすぎている日に読むと、勝つことより通じることへ視点が戻ります。",
    "source_context" => "1907年の小説『虞美人草』で印象的に語られる一節。",
    "punchline" => "愛嬌は、人をつなぐ柔らかい強さ。",
    "push_notification_hook" => "人にきつくなりすぎていると感じた日に。"
  },
  "women_quote_178" => {
    "quote_ja" => "そのときの出逢いが\nその人の人生を\n根底から変えることがある。\nよき出逢いを。",
    "quote_en" => nil,
    "author" => "相田みつを",
    "author_kana" => "アイダ・ミツヲ",
    "author_description" => "詩人・書家",
    "meaning_preview" => "人との縁を軽く消費せず、出会いが自分を変える可能性ごと受け取らせる言葉です。",
    "meaning_premium" => "関係に疲れている時ほど、人との出会いを損得で見てしまいがちです。でも本当に人生を動かすのは、予定外に差し込んでくる一人の言葉や存在だったりします。この一文は、傷つく可能性ごと閉じるのではなく、よい出会いを受け取れる開き方を思い出させてくれます。",
    "source_context" => "相田みつをの作品として広く親しまれ、相田みつを美術館でも紹介される言葉。",
    "punchline" => "出逢いは、人生の根を変えることがある。",
    "push_notification_hook" => "人間関係に少し閉じ気味な日に。"
  },
  "women_quote_016" => {
    "quote_ja" => "私たちは、\n孤立の中ではめったに癒えない。\n癒しは、つながりの中で起こる。",
    "quote_en" => "Rarely, if ever, are any of us healed in isolation. Healing is an act of communion.",
    "author" => "bell hooks",
    "author_kana" => "ベル・フックス",
    "author_description" => "作家・思想家",
    "meaning_preview" => "傷ついた時ほど、人と距離を取るだけでは回復しきれないと教える言葉です。",
    "meaning_premium" => "人間関係で疲れた時、誰にも頼らず立て直そうとしがちです。でもこの言葉は、回復は孤立の中だけで起こるものではないと示します。大切なのは無理にたくさんの人と関わることではなく、安心して弱さを置けるつながりを持つこと。人に傷ついた後でも、人との関係が癒しの場になりうると教えてくれる一文です。",
    "source_context" => "2000年刊『All About Love: New Visions』で bell hooks が語った一節。",
    "punchline" => "癒しは、孤立ではなくつながりの中で起こる。",
    "push_notification_hook" => "ひとりで抱え込みすぎている日に。"
  },
  "women_quote_050" => {
    "quote_ja" => "愛とは、\n完璧にやさしくいられる状態ではない。\n向き合い続ける営みだ。",
    "quote_en" => "Love isn't a state of perfect caring. It is an active noun like struggle.",
    "author" => "Fred Rogers",
    "author_kana" => "フレッド・ロジャース",
    "author_description" => "司会者・子ども番組制作者",
    "meaning_preview" => "人間関係がうまくいかない日にも、愛は『下手になった証拠』ではなく続ける営みだと捉え直せる言葉です。",
    "meaning_premium" => "関係がぎくしゃくすると、相手を大切に思えていないのではと不安になります。でもこの一文は、愛を常に穏やかで完璧な感情としてではなく、向き合い、修正し、続けようとする行為として捉えています。すれ違いがある日にも、終わりと決める前にもう一度手をかける視点をくれる言葉です。",
    "source_context" => "2003年刊『The World According to Mister Rogers』で広く知られる言葉。",
    "punchline" => "愛は、完璧な感情ではなく続ける営み。",
    "push_notification_hook" => "うまく愛せていない気がする日に。"
  },
  "women_quote_167" => {
    "quote_ja" => "友を得る最も確かな方法は、\n自分が友であることだ。",
    "quote_en" => "The only way to have a friend is to be one.",
    "author" => "Ralph Waldo Emerson",
    "author_kana" => "ラルフ・ワルド・エマーソン",
    "author_description" => "思想家・随筆家",
    "meaning_preview" => "欲しい関係をただ待つより、自分がどんな関わりを差し出しているかを見直させる言葉です。",
    "meaning_premium" => "人間関係がうまくいかない時、相手に誠実さや理解を求めたくなります。この言葉は、その前に自分が相手にとって信頼できる存在でいられているかを問い返します。迎合することではなく、自分から関係の質を作る姿勢を持つこと。それが長く残る縁の土台になると教えてくれます。",
    "source_context" => "1841年刊『Essays: First Series』所収「Friendship」で知られる考え方。",
    "punchline" => "欲しい関係があるなら、まず自分がその関係になる。",
    "push_notification_hook" => "人間関係に受け身になりすぎている日に。"
  },
  "women_quote_168" => {
    "quote_ja" => "愛するということは、\n見つめ合うことではなく、\n同じ方向をいっしょに見ることだ。",
    "quote_en" => "Love does not consist in gazing at each other, but in looking outward together in the same direction.",
    "author" => "Antoine de Saint-Exupéry",
    "author_kana" => "サン＝テグジュペリ",
    "author_description" => "作家・飛行士",
    "meaning_preview" => "一緒にいるだけでなく、どこへ向かう関係かを見る視点をくれる言葉です。",
    "meaning_premium" => "関係が深まるほど、相手ばかりを見てしまいがちです。でも長く続く関係を支えるのは、互いを監視することではなく、同じ方向へ目を向けられること。この一文は、好きかどうかだけで迷っている時に、『並んで進める相手か』という静かな基準を渡してくれます。",
    "source_context" => "1939年刊『Terre des hommes（人間の土地 / Wind, Sand and Stars）』で知られる一節。",
    "punchline" => "見つめ合うだけでなく、同じ方向を見られるか。",
    "push_notification_hook" => "関係の進み方に迷っている日に。"
  },
  "women_quote_169" => {
    "quote_ja" => "闇は闇では追い出せない。\nそれができるのは光だけだ。\n憎しみを追い出せるのは愛だけだ。",
    "quote_en" => "Darkness cannot drive out darkness; only light can do that. Hate cannot drive out hate; only love can do that.",
    "author" => "Martin Luther King Jr.",
    "author_kana" => "マーティン・ルーサー・キング・ジュニア",
    "author_description" => "公民権運動指導者",
    "meaning_preview" => "強く返すほど関係の泥沼は深くなると、この言葉は教えます。",
    "meaning_premium" => "傷ついた時、同じ温度で返したくなるのは自然です。ただこの一文は、相手に譲ることではなく、壊れた空気をこれ以上悪化させるやり方を選ばない強さを示しています。境界線は引きつつ、憎しみまで抱え込まない。その距離感を取り戻したい日に効く言葉です。",
    "source_context" => "1963年刊『Strength to Love』に収められた代表的な言葉。",
    "punchline" => "壊れた空気を変えるのは、同じ攻撃ではない。",
    "push_notification_hook" => "ぶつかった相手に強く返したくなる日に。"
  },
  "women_quote_171" => {
    "quote_ja" => "人は、あなたが何を言ったかより、\nどんな気持ちにさせたかを覚えている。",
    "quote_en" => "People will forget what you said, people will forget what you did, but people will never forget how you made them feel.",
    "author" => "Maya Angelou",
    "author_kana" => "マヤ・アンジェロウ",
    "author_description" => "詩人・作家",
    "meaning_preview" => "正論よりも、相手の中に残る体感のほうが関係を左右すると教える言葉です。",
    "meaning_premium" => "人間関係で後から残るのは、細かな言葉より『この人といると安心できるか、縮こまるか』という感覚です。この言葉は、伝える内容だけでなく、伝え方の温度へ意識を戻します。媚びる必要はないけれど、相手の心に何を残しているかを考えるだけで、会話の質は大きく変わります。",
    "source_context" => "マヤ・アンジェロウの講演やインタビューで広く知られる代表的な言葉。",
    "punchline" => "言葉以上に残るのは、一緒にいた時の感覚。",
    "push_notification_hook" => "伝え方がきつくなっていたかもしれない日に。"
  },
  "women_quote_176" => {
    "quote_ja" => "愛は、\n敵を友に変えうる唯一の力だ。",
    "quote_en" => "Love is the only force capable of transforming an enemy into a friend.",
    "author" => "Martin Luther King Jr.",
    "author_kana" => "マーティン・ルーサー・キング・ジュニア",
    "author_description" => "公民権運動指導者",
    "meaning_preview" => "勝ち負けではなく、関係の出口を残す強さを思い出させる言葉です。",
    "meaning_premium" => "人間関係では、勝ったのに関係だけ壊れることがあります。この言葉は、弱くなるためではなく、完全な断絶で終わらせないための強さを示しています。すぐ仲直りできなくても、相手を完全に敵にしない。その余白を持てる人のほうが、結果的に自分の心も守れます。",
    "source_context" => "1963年刊『Strength to Love』で語られるマーティン・ルーサー・キングの言葉。",
    "punchline" => "関係を変えるのは、勝ち負けより愛の力。",
    "push_notification_hook" => "この関係はもう無理だと思い始めた日に。"
  },
  "women_quote_115" => {
    "quote_ja" => "傷は、\n知恵に変えていける。",
    "quote_en" => "Turn your wounds into wisdom.",
    "author" => "Oprah Winfrey",
    "author_kana" => "オプラ・ウィンフリー",
    "author_description" => "司会者・プロデューサー",
    "meaning_preview" => "つらい経験を、ただ痛い記憶で終わらせないための言葉です。",
    "meaning_premium" => "傷ついた出来事は消えなくても、その意味は変えていけます。この一文は、痛みを美化するためではなく、『ここから何を学ぶか』へ視線を戻すためにあります。後悔ばかりが残る日ほど、この経験を次の自分の判断材料に変える助けになります。",
    "source_context" => "オプラ・ウィンフリーのスピーチや著作で広く引用される言葉。",
    "punchline" => "痛みは、知恵に変えていける。",
    "push_notification_hook" => "つらかった出来事に引っぱられている日に。"
  },
  "women_quote_116" => {
    "quote_ja" => "新しい一日には、\n新しい力と新しい考えがある。",
    "quote_en" => "With the new day comes new strength and new thoughts.",
    "author" => "Eleanor Roosevelt",
    "author_kana" => "エレノア・ルーズベルト",
    "author_description" => "作家・外交官・元米大統領夫人",
    "meaning_preview" => "昨日の気分や失敗を、今日の限界にしなくていいと伝える言葉です。",
    "meaning_premium" => "気分が落ちた翌朝ほど、昨日の延長でしか考えられなくなります。でもこの一文は、一日が変わるだけで視点も力も更新されうると教えてくれます。何も劇的に変わらなくても、今日には今日の立て直し方がある。その余白を感じたい時に効く言葉です。",
    "source_context" => "エレノア・ルーズベルトの言葉として広く知られる一節。",
    "punchline" => "新しい朝には、新しい力が来る。",
    "push_notification_hook" => "昨日を引きずったまま朝を迎えた日に。"
  },
  "women_quote_117" => {
    "quote_ja" => "終わりだと思った場所が、\n次の始まりになっていることがある。",
    "quote_en" => "Often when you think you're at the end of something, you're at the beginning of something else.",
    "author" => "Fred Rogers",
    "author_kana" => "フレッド・ロジャース",
    "author_description" => "司会者・子ども番組制作者",
    "meaning_preview" => "行き止まりに見える出来事が、あとから見れば入口だったと気づかせる言葉です。",
    "meaning_premium" => "うまくいかなかった直後は、失ったものしか見えません。この一文は、その断絶が別の流れの始まりかもしれないと視点を少し先へずらしてくれます。無理に元気になるためではなく、『まだ決まり切っていない』と受け取るための言葉として強いです。",
    "source_context" => "2003年刊『The World According to Mister Rogers』で語られる一節。",
    "punchline" => "終わりに見える場所が、始まりのこともある。",
    "push_notification_hook" => "全部終わった気がしている日に。"
  },
  "women_quote_118" => {
    "quote_ja" => "幸せは、\n出来上がった形で届くものではない。\n自分の行動から生まれる。",
    "quote_en" => "Happiness is not something ready made. It comes from your own actions.",
    "author" => "Dalai Lama",
    "author_kana" => "ダライ・ラマ",
    "author_description" => "チベット仏教の精神的指導者",
    "meaning_preview" => "気分が上がるのを待つより、小さな行動から今日を変えていけると教える言葉です。",
    "meaning_premium" => "前向きになれない日は、何か特別な出来事が必要な気がします。でもこの一文は、幸せを受け身で待つのではなく、今日の行動の中で少しずつ育てる発想をくれます。散歩する、整える、感謝を書く。そんな小さなことでも気分の流れは変えられると感じさせてくれます。",
    "source_context" => "ダライ・ラマの講演や著作で広く引用される言葉。",
    "punchline" => "幸せは、行動の中から育っていく。",
    "push_notification_hook" => "気分が上がるのをただ待っている日に。"
  },
  "women_quote_119" => {
    "quote_ja" => "心に刻んでおきなさい。\n毎日が、その年でいちばん良い日だと。",
    "quote_en" => "Write it on your heart that every day is the best day in the year.",
    "author" => "Ralph Waldo Emerson",
    "author_kana" => "ラルフ・ワルド・エマーソン",
    "author_description" => "思想家・随筆家",
    "meaning_preview" => "今日を『ただの日』で終わらせず、ちゃんと受け取る感度を戻す言葉です。",
    "meaning_premium" => "もちろん毎日が最高とは限りません。それでもこの一文は、『今日は何もない日』と扱った瞬間に失うものを思い出させます。大きな出来事がなくても、今日を自分の人生の中心に置く。その姿勢が、日常を少し前向きに変えていきます。",
    "source_context" => "ラルフ・ワルド・エマーソンの講演・著作で広く知られる言葉。",
    "punchline" => "今日を『ただの日』で終わらせなくていい。",
    "push_notification_hook" => "今日は何もない日だと思ってしまう朝に。"
  },
  "women_quote_120" => {
    "quote_ja" => "顔を太陽に向けていれば、\n影は見えない。",
    "quote_en" => "Keep your face to the sunshine and you cannot see a shadow.",
    "author" => "Helen Keller",
    "author_kana" => "ヘレン・ケラー",
    "author_description" => "教育家・社会福祉活動家",
    "meaning_preview" => "問題が消えるのを待つより、どこを見るかを選ぶことの強さを教える言葉です。",
    "meaning_premium" => "前向きさは、悩みを否定することではありません。この一文が示しているのは、影の存在を無視することではなく、どちらを向いて一日を始めるかを自分で選べるということです。全部を明るくできない日でも、ひとつだけ光の方を見る。その実践のために読むと強い言葉です。",
    "source_context" => "ヘレン・ケラーの言葉として広く愛される一節。",
    "punchline" => "何を見るかで、一日の光り方は変わる。",
    "push_notification_hook" => "考えすぎて影ばかり見ている日に。"
  },
  "women_quote_153" => {
    "quote_ja" => "愛することは、\n自分を無防備にすることでもある。",
    "quote_en" => "To love at all is to be vulnerable.",
    "author" => "C.S. Lewis",
    "author_kana" => "C・S・ルイス",
    "author_description" => "作家・思想家",
    "meaning_preview" => "恋をすると不安になる自分を、弱いと切り捨てなくていいと教える言葉です。",
    "meaning_premium" => "好きになった瞬間から、傷つく可能性はどうしても生まれます。この一文は、その不安を未熟さではなく、愛そのものに含まれる性質として受け止めさせてくれます。怖いからダメなのではなく、怖さがあるほど本気だったのかもしれない。そんなふうに恋の揺れを抱え直せる言葉です。",
    "source_context" => "1960年刊『The Four Loves』で語られる C.S. Lewis の代表的な言葉。",
    "punchline" => "恋の不安は、弱さではなく愛の一部。",
    "push_notification_hook" => "好きだからこそ怖くなっている日に。"
  },
  "women_quote_154" => {
    "quote_ja" => "幼い愛は言う。\n『あなたが必要だから愛している』。\n成熟した愛は言う。\n『愛しているから、あなたを必要とする』。",
    "quote_en" => "Immature love says: I love you because I need you. Mature love says: I need you because I love you.",
    "author" => "Erich Fromm",
    "author_kana" => "エーリッヒ・フロム",
    "author_description" => "社会心理学者・思想家",
    "meaning_preview" => "恋の依存と愛情を、似ているようで違うものとして見分けさせる言葉です。",
    "meaning_premium" => "誰かがいないと立っていられない感覚は、強い恋と見分けがつきにくいものです。この言葉は、相手を埋め合わせとして必要としているのか、相手そのものを愛しているのかを静かに問い返します。苦しい恋ほど、自分が求めているものの正体を見極める助けになります。",
    "source_context" => "1956年刊『The Art of Loving（愛するということ）』で語られる一節。",
    "punchline" => "依存と愛情は、似ていても違う。",
    "push_notification_hook" => "この恋は依存かもしれないと感じた日に。"
  },
  "women_quote_155" => {
    "quote_ja" => "愛と虐待は、\n同じ場所には存在できない。",
    "quote_en" => "Abuse and love cannot coexist.",
    "author" => "bell hooks",
    "author_kana" => "ベル・フックス",
    "author_description" => "作家・思想家",
    "meaning_preview" => "苦しい関係を『愛があるから』と正当化しそうな時に、線を引かせる言葉です。",
    "meaning_premium" => "恋がつらい時ほど、『愛しているから仕方ない』と傷つきを飲み込みやすくなります。この一文は、その思考を止めるためにあります。愛があるなら何をされても耐えるべき、ではない。大切にされていない現実を見つめるための、かなり重要な基準になる言葉です。",
    "source_context" => "2000年刊『All About Love: New Visions』で bell hooks が繰り返し書いた考え方。",
    "punchline" => "傷つけられる関係を、愛でごまかさない。",
    "push_notification_hook" => "苦しい恋を正当化しそうになっている日に。"
  },
  "women_quote_156" => {
    "quote_ja" => "一人の人間がもう一人を愛すること。\nそれは、私たちに託された\n最も難しい仕事かもしれない。",
    "quote_en" => "For one human being to love another: that is perhaps the most difficult of all our tasks.",
    "author" => "Rainer Maria Rilke",
    "author_kana" => "ライナー・マリア・リルケ",
    "author_description" => "詩人",
    "meaning_preview" => "恋がうまくいかない時に、『本当に難しいものに向き合っている』と受け止め直させる言葉です。",
    "meaning_premium" => "好きなのに伝わらない、近づくほどすれ違う。恋の難しさは、自分の未熟さだけの問題に見えてしまいがちです。でもこの言葉は、人を深く愛すること自体がそもそも難しい仕事だと示します。だからこそ、うまくできない自分をすぐ失格にしなくていいと救ってくれる一文です。",
    "source_context" => "1903年刊『Letters to a Young Poet（若き詩人への手紙）』で語られる一節。",
    "punchline" => "恋が難しいのは、あなたが下手だからだけじゃない。",
    "push_notification_hook" => "好きなのに、どうしてもうまくできない日に。"
  },
  "women_quote_157" => {
    "quote_ja" => "愛は自然には死なない。\n源を満たす方法を知らない時に、\n少しずつ枯れていく。",
    "quote_en" => "Love never dies a natural death. It dies because we don't know how to replenish its source.",
    "author" => "Anaïs Nin",
    "author_kana" => "アナイス・ニン",
    "author_description" => "作家",
    "meaning_preview" => "気持ちが冷めたのか、疲れただけなのかを見分ける視点をくれる言葉です。",
    "meaning_premium" => "関係がしんどくなると、『もう愛がなくなった』と結論づけたくなります。この言葉は、その前に愛を枯らしているものが何かを見つめさせます。対話不足、余白のなさ、遠慮、疲れ。終わりと決める前に、何が足りなくなっていたのかを見直すきっかけになる言葉です。",
    "source_context" => "Anaïs Nin の著作で広く知られる言葉。",
    "punchline" => "愛が終わったのではなく、枯れさせていたのかもしれない。",
    "push_notification_hook" => "この恋、もう終わりなのかなと感じる日に。"
  },
  "women_quote_158" => {
    "quote_ja" => "もう一度だけ、\n愛を信じる勇気を持ちなさい。\nそして、またもう一度。",
    "quote_en" => "Have enough courage to trust love one more time and always one more time.",
    "author" => "Maya Angelou",
    "author_kana" => "マヤ・アンジェロウ",
    "author_description" => "詩人・作家",
    "meaning_preview" => "傷ついた後に恋へ閉じてしまいそうな心へ、慎重さと希望の両方を渡す言葉です。",
    "meaning_premium" => "一度つらい恋をすると、もう信じたくない気持ちと、まだどこかで期待している気持ちが同居します。この言葉は、無防備になれと言うのではなく、それでも愛を完全に見限らない勇気を支えます。怖さが消えなくても、心を閉じ切らない。その温度感が今の自分にちょうどいい時があります。",
    "source_context" => "マヤ・アンジェロウの講演やインタビューで広く共有される言葉。",
    "punchline" => "怖くても、愛を見限らなくていい。",
    "push_notification_hook" => "もう恋なんてしたくないと思い始めた日に。"
  },
  "women_quote_163" => {
    "quote_ja" => "愛に薬はない。\nもっと愛すること以外には。",
    "quote_en" => "There is no remedy for love but to love more.",
    "author" => "Henry David Thoreau",
    "author_kana" => "ヘンリー・デイヴィッド・ソロー",
    "author_description" => "思想家・作家",
    "meaning_preview" => "恋を理屈で整理しきれない時に、感情の深さそのものを認める言葉です。",
    "meaning_premium" => "恋の苦しさから早く抜けたい時ほど、気持ちを切り捨てたくなります。でもこの一文は、愛を『治すべきもの』として扱わない視点をくれます。すぐに答えを出さず、自分の感じているものをもう少し丁寧に見つめる。そんな時間を取ること自体が、恋を乱暴に終わらせない助けになります。",
    "source_context" => "ヘンリー・デイヴィッド・ソローの著作や書簡で広く伝わる言葉。",
    "punchline" => "恋を急いで片づけなくていい。",
    "push_notification_hook" => "気持ちを無理に終わらせようとしている日に。"
  },
  "women_quote_164" => {
    "quote_ja" => "本当に愛しているなら、\n相手が自由でいられることも愛するはずだ。",
    "quote_en" => "If you love somebody, let them be free.",
    "author" => "Thích Nhất Hạnh",
    "author_kana" => "ティク・ナット・ハン",
    "author_description" => "禅僧・平和活動家",
    "meaning_preview" => "好きだから縛りたい気持ちと、大切だから自由でいてほしい気持ちを切り分ける言葉です。",
    "meaning_premium" => "恋愛では、近づきたい気持ちが強いほど相手をコントロールしたくなる瞬間があります。この一文は、愛を安心の確保ではなく、相手の自由まで尊重する姿勢として見直させます。執着で苦しくなっている時ほど、相手にも自分にも余白を返すための基準になります。",
    "source_context" => "ティク・ナット・ハンの愛と執着に関する教えとして広く共有される言葉。",
    "punchline" => "好きでも、自由を奪わない愛でいたい。",
    "push_notification_hook" => "相手を握りしめたくなっている日に。"
  },
  "women_quote_047" => {
    "quote_ja" => "人間らしいことは、\n何でも言葉にしていい。\n言葉にできれば、受け止めやすくなる。",
    "quote_en" => "Anything that's human is mentionable, and anything that is mentionable can be more manageable.",
    "author" => "Fred Rogers",
    "author_kana" => "フレッド・ロジャース",
    "author_description" => "司会者・子ども番組制作者",
    "meaning_preview" => "子どもの感情を『そんなことで泣かないの』と片づけず、言葉にさせる大切さを教える言葉です。",
    "meaning_premium" => "子どもが混乱している時、大人はすぐ落ち着かせたくなります。でも本当に助けになるのは、感情を消すことではなく、言葉にして一緒に扱える形にすることです。この一文は、子どもの気持ちを小さく見ないための指針になります。泣いている理由が幼く見えても、まず名前をつける。その姿勢が安心をつくります。",
    "source_context" => "2003年刊『The World According to Mister Rogers』で広く知られる言葉。",
    "punchline" => "子どもの感情は、言葉にして一緒に受け止めていい。",
    "push_notification_hook" => "子どもの気持ちをどう受け止めればいいか迷う日に。"
  },
  "women_quote_048" => {
    "quote_ja" => "子どもが自分でできると感じていることを、\n代わりにしてはいけない。",
    "quote_en" => "Never help a child with a task at which he feels he can succeed.",
    "author" => "Maria Montessori",
    "author_kana" => "マリア・モンテッソーリ",
    "author_description" => "医師・教育家",
    "meaning_preview" => "愛情からの手助けが、子どもの自信を奪うこともあると教える言葉です。",
    "meaning_premium" => "子どもを思うほど、先回りして助けたくなります。でもこの言葉は、できる手前の挑戦を大人が奪わないことの大切さを示します。失敗しないよう守ることと、自分でできた感覚を育てることは別です。見守る勇気が必要な日に、かなり効く言葉です。",
    "source_context" => "マリア・モンテッソーリの教育思想を伝える言葉として広く引用される一節。",
    "punchline" => "手を出すより、できる感覚を守る。",
    "push_notification_hook" => "つい先回りしてしまう日に。"
  },
  "women_quote_049" => {
    "quote_ja" => "育てたように、\n子は育つ。",
    "quote_en" => nil,
    "author" => "相田みつを",
    "author_kana" => "アイダ・ミツヲ",
    "author_description" => "詩人・書家",
    "meaning_preview" => "子どもは言われた通りより、日々見ている大人のあり方の影響を強く受けると伝える言葉です。",
    "meaning_premium" => "この言葉は、親を責めるためではなく、子どもが日々受け取っている空気の重さを思い出させます。焦り方、謝り方、人への接し方。そういう細部が、子どもにとっては教科書になります。完璧でなくていいけれど、自分の背中が何を教えているかを見直したい日に刺さる言葉です。",
    "source_context" => "相田みつをの子育て観を象徴する言葉として、『育てたように子は育つ』にまとめられている。",
    "punchline" => "子どもは、毎日見ている大人から育っていく。",
    "push_notification_hook" => "子どもに何を見せているか考えたい日に。"
  },
  "women_quote_086" => {
    "quote_ja" => "あなたは子どもに愛を与えられる。\nけれど、あなたの考えそのものを\n与えることはできない。",
    "quote_en" => "You may give them your love but not your thoughts.",
    "author" => "Kahlil Gibran",
    "author_kana" => "カリール・ジブラン",
    "author_description" => "詩人・思想家",
    "meaning_preview" => "守りたい気持ちと、子どもの心を所有しないことは両立できると教える言葉です。",
    "meaning_premium" => "親はつい、自分が正しいと思う考えまで子どもに渡したくなります。この一文は、愛をたっぷり注ぐことと、子どもの頭の中まで支配しないことを分けて考えさせます。価値観を押し込むより、自分で考える土台を残す。その距離感を大事にしたい時に効く言葉です。",
    "source_context" => "1923年刊『The Prophet（預言者）』「On Children」に収められた一節。",
    "punchline" => "愛は渡せても、考えまで所有しなくていい。",
    "push_notification_hook" => "子どもの考えを急いで正したくなった日に。"
  },
  "women_quote_097" => {
    "quote_ja" => "子どもは、\n大人が自分をどう見るかによって\n自分を知っていく。",
    "quote_en" => nil,
    "author" => "佐々木正美",
    "author_kana" => "ササキ・マサミ",
    "author_description" => "児童精神科医",
    "meaning_preview" => "子どもの自己肯定感は、かける言葉だけでなく、向けるまなざし全体で育つと気づかせる言葉です。",
    "meaning_premium" => "子どもは、評価の言葉以上に『自分は大切に見られているか』を敏感に感じ取っています。この一文は、できたことを褒める前に、普段どんな眼差しで見ているかを問い返します。急かす、比べる、ため息をつく。そうした小さな反応まで含めて、子どもの自己像をつくっていると意識させてくれます。",
    "source_context" => "児童精神科医・佐々木正美が子育てで繰り返し語った、まなざしの重要性を表す考え方。",
    "punchline" => "子どもは、大人のまなざしの中で自分を知る。",
    "push_notification_hook" => "言葉以上に、向ける目を整えたい日に。"
  },
  "women_quote_099" => {
    "quote_ja" => "あなたの存在そのものが希望。",
    "quote_en" => nil,
    "author" => "黒柳徹子",
    "author_kana" => "クロヤナギ・テツコ",
    "author_description" => "俳優・司会者・ユニセフ親善大使",
    "meaning_preview" => "子どもに期待を背負わせる前に、存在そのものに価値があると伝えるための言葉です。",
    "meaning_premium" => "子どもに向ける愛情が、いつのまにか『期待』として重く乗ってしまうことがあります。この言葉は、何かを達成したからではなく、そこに生きているだけで希望だと伝える視点をくれます。結果より先に存在を肯定される経験が、その子の安心の土台になります。",
    "source_context" => "2024年、朝日小学生新聞のインタビューで黒柳徹子が子どもたちへ贈った言葉。",
    "punchline" => "子どもには、まず存在そのものが希望だと伝えたい。",
    "push_notification_hook" => "何かを求める前に、存在を抱きしめたい日に。"
  },
  "women_quote_189" => {
    "author_kana" => "マツシタ・コウノスケ"
  },
  "women_quote_190" => {
    "author_kana" => "イチロー"
  }
}.merge(AFFIRMATIONS).freeze

FILES.each do |path|
  data = JSON.parse(File.read(path))

  data.each do |entry|
    update = UPDATES[entry["id"]]
    next unless update

    update.each do |key, value|
      entry[key] = value
    end
  end

  File.write(path, JSON.pretty_generate(data) + "\n")
end
