#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

ROOT = File.expand_path("..", __dir__)
QUOTES_PATH = File.join(ROOT, "QuoteApp/Sources/Resources/quotes.json")
QUOTES_FULL_PATH = File.join(ROOT, "QuoteApp/Sources/Resources/quotes_full.json")

REPLACEMENTS = {
  "self_love" => [
    {
      "quote_ja" => "自己の個性を発揮して、\n他人の個性を尊重せよ。",
      "quote_en" => nil,
      "author" => "夏目漱石",
      "author_description" => "近代日本を代表する小説家・英文学者",
      "punchline" => "自己の個性を発揮して、他人の個性を尊重せよ。",
      "push_notification_hook" => "日本人の言葉で、自分の輪郭を取り戻したい朝に。"
    },
    {
      "quote_ja" => "他人と比較して\n他人が自分より優れていたとしても、\nそれは恥ではない。\nしかし、去年の自分より\n今年の自分が優れていないのは\n立派な恥だ。",
      "quote_en" => nil,
      "author" => "本田宗一郎",
      "author_description" => "本田技研工業創業者・挑戦を貫いた実業家",
      "punchline" => "比べる相手は、去年の自分だ。",
      "push_notification_hook" => "他人の評価から離れて、自分の基準に戻したい日に。"
    }
  ],
  "positive" => [
    {
      "quote_ja" => "一日ひとつずつの\n教訓を拾えば、\n一年で365の\n教訓が得られる。",
      "quote_en" => nil,
      "author" => "イチロー",
      "author_description" => "日米で記録を打ち立てたプロ野球選手",
      "punchline" => "一日ひとつ拾えば、一年で365になる。",
      "push_notification_hook" => "今日は何も進んでいないと思う日に、イチローの一言。"
    },
    {
      "quote_ja" => "できないことを\nできるようにするのが\n楽しい。",
      "quote_en" => nil,
      "author" => "大谷翔平",
      "author_description" => "二刀流で世界を更新し続けるプロ野球選手",
      "punchline" => "できないことを、できるようにするのが楽しい。",
      "push_notification_hook" => "前向きさを気合いではなく好奇心で取り戻したい時に。"
    }
  ],
  "courage" => [
    {
      "quote_ja" => "チャレンジして失敗を恐れるよりも、\n何もしないことを恐れろ。",
      "quote_en" => nil,
      "author" => "本田宗一郎",
      "author_description" => "本田技研工業創業者・挑戦を貫いた実業家",
      "punchline" => "失敗より、何もしないことを恐れろ。",
      "push_notification_hook" => "踏み出す前に縮こまりそうな時、日本人の一言を。"
    },
    {
      "quote_ja" => "志を立てるのに、\n老いも若きもない。",
      "quote_en" => nil,
      "author" => "吉田松陰",
      "author_description" => "幕末の思想家・教育者",
      "punchline" => "志を立てるのに、老いも若きもない。",
      "push_notification_hook" => "もう遅いかもしれないと感じた瞬間に開いてほしい一言。"
    }
  ],
  "inner_strength" => [
    {
      "quote_ja" => "我、事において\n後悔せず。",
      "quote_en" => nil,
      "author" => "宮本武蔵",
      "author_description" => "江戸初期の剣豪・兵法家",
      "punchline" => "我、事において後悔せず。",
      "push_notification_hook" => "心の軸を静かに立て直したい日に、武蔵の一言。"
    },
    {
      "quote_ja" => "能力を未来進行形で\n考えろ。\n今できなくても\n将来できるようになる。",
      "quote_en" => nil,
      "author" => "稲盛和夫",
      "author_description" => "京セラ・KDDI創業者・経営哲学者",
      "punchline" => "能力を未来進行形で考えろ。",
      "push_notification_hook" => "今の未熟さに飲まれそうな時、稲盛和夫の視点を。"
    }
  ],
  "love_crush" => [
    {
      "quote_ja" => "どんなに辛く苦しんだ恋愛であっても、\n恋愛を知らずに死を迎える人より\n幸せな人生だと感じている。",
      "quote_en" => nil,
      "author" => "瀬戸内寂聴",
      "author_description" => "作家・僧侶として恋と人生を語り続けた表現者",
      "punchline" => "恋に傷ついた時間まで、人生の厚みになる。",
      "push_notification_hook" => "恋のしんどさごと肯定してほしい夜に、日本人の言葉を。"
    },
    {
      "quote_ja" => "やは肌の\nあつき血汐に\nふれもみで\nさびしからずや\n道を説く君",
      "quote_en" => nil,
      "author" => "与謝野晶子",
      "author_description" => "情熱と自由を詠んだ歌人",
      "punchline" => "理屈より先に、恋は体温で始まる。",
      "push_notification_hook" => "理性では片づけられない恋心に、晶子の短歌を。"
    }
  ],
  "family_love" => [
    {
      "quote_ja" => "相手の目を見つめて、\n手を取りあって話をすれば、\nきっと分かりあえる。",
      "quote_en" => nil,
      "author" => "黒柳徹子",
      "author_description" => "長く子どもと対話を続けてきた俳優・エッセイスト",
      "punchline" => "目を見て、手を取りあって話せば、きっと分かりあえる。",
      "push_notification_hook" => "家族とすれ違った日に、日本人のやわらかな一言を。"
    },
    {
      "quote_ja" => "人を信じよ、\nしかし、\nその百倍も\n自らを信じよ。",
      "quote_en" => nil,
      "author" => "手塚治虫",
      "author_description" => "漫画表現を切り開いた表現者",
      "punchline" => "人を信じよ。だが、その百倍も自らを信じよ。",
      "push_notification_hook" => "近しい人との距離で揺れた時、自分を見失わないための一言。"
    }
  ],
  "for_my_child" => [
    {
      "quote_ja" => "君たちは\nどう生きるか。",
      "quote_en" => nil,
      "author" => "吉野源三郎",
      "author_description" => "子どもへ倫理と思索を問いかけた作家・編集者",
      "punchline" => "君たちは、どう生きるか。",
      "push_notification_hook" => "子どもに残したい問いを探したい日に。"
    },
    {
      "quote_ja" => "あなたの存在そのものが希望。",
      "quote_en" => nil,
      "author" => "黒柳徹子",
      "author_description" => "長く子どもと対話を続けてきた俳優・エッセイスト",
      "punchline" => "あなたの存在そのものが希望。",
      "push_notification_hook" => "子どもを評価で見そうになった時に開いてほしい日本語の一言。"
    }
  ],
  "relationships" => [
    {
      "quote_ja" => "自己の個性を発揮して、\n他人の個性を尊重せよ。",
      "quote_en" => nil,
      "author" => "夏目漱石",
      "author_description" => "近代日本を代表する小説家・英文学者",
      "punchline" => "自分の個性を発揮し、他人の個性を尊重せよ。",
      "push_notification_hook" => "人との距離感で迷った時、漱石の言葉に戻る。"
    },
    {
      "quote_ja" => "相手の目を見つめて、\n手を取りあって話をすれば、\nきっと分かりあえる。",
      "quote_en" => nil,
      "author" => "黒柳徹子",
      "author_description" => "長く子どもと対話を続けてきた俳優・エッセイスト",
      "punchline" => "目を見て話せば、きっと分かりあえる。",
      "push_notification_hook" => "言葉がすれ違っている時に、日本人のやさしい一言を。"
    }
  ],
  "want_to_quit" => [
    {
      "quote_ja" => "失敗したところでやめてしまうから\n失敗になる。\n成功するところまで続ければ、\nそれは成功になる。",
      "quote_en" => nil,
      "author" => "松下幸之助",
      "author_description" => "パナソニック創業者・経営の神様",
      "punchline" => "成功するところまで続ければ、それは成功になる。",
      "push_notification_hook" => "もうやめたい日にこそ読んでほしい、松下幸之助の一言。"
    },
    {
      "quote_ja" => "結果が出ないとき、\nどういう自分でいられるか。\n決してあきらめない姿勢が、\n何かを生み出すきっかけを作る。",
      "quote_en" => nil,
      "author" => "イチロー",
      "author_description" => "日米で記録を打ち立てたプロ野球選手",
      "punchline" => "結果が出ない時、どういう自分でいられるか。",
      "push_notification_hook" => "成果が見えず折れそうな時、イチローの視点を。"
    }
  ],
  "affirmation" => [
    {
      "quote_ja" => "己に勝った者だけが\n他者に勝てる。",
      "quote_en" => nil,
      "author" => "宮本武蔵",
      "author_description" => "江戸初期の剣豪・兵法家",
      "punchline" => "己に勝った者だけが、他者に勝てる。",
      "push_notification_hook" => "自分との向き合い方を整えたい朝、武蔵の一言を。"
    },
    {
      "quote_ja" => "今日一日を\n完全燃焼して生きることが、\n明日への最高の準備になる。",
      "quote_en" => nil,
      "author" => "稲盛和夫",
      "author_description" => "京セラ・KDDI創業者・経営哲学者",
      "punchline" => "今日を燃やし切ることが、明日への準備になる。",
      "push_notification_hook" => "自分を立て直したい日に、日本人の実感ある一言を。"
    }
  ]
}.freeze

CATEGORY_PROFILES = {
  "self_love" => {
    preview: [
      "「%<first>s」から始まるこの一文は、足りなさではなく自分の輪郭へ意識を戻させます。",
      "「%<first>s」と言い切ることで、他人の尺度より自分の扱い方を整える方向へ引き戻しています。",
      "「%<first>s」から「%<last>s」へ流れる言葉で、自己否定より自己理解を選び直させます。"
    ],
    premium: [
      "%<author>sは「%<first>s」という姿勢を通して、まず自分を雑に扱わないことが土台だと示しています。読んだあとに残るのは、大きく変わる決意よりも、自分に向ける視線を少しだけ丁寧にする感覚です。",
      "この言葉の芯は「%<first>s」を他人からの承認ではなく、自分で引き受ける点にあります。「%<last>s」という着地があるからこそ、落ち込んだ日にも自分の価値を外へ明け渡しすぎずに済みます。",
      "%<author>sのこの一文は、自信を盛るのではなく「%<first>s」という基準で自分を測り直させます。今できていないことがあっても、自分を切り捨てずに育てる発想へ持っていけるのが強みです。 "
    ]
  },
  "positive" => {
    preview: [
      "「%<first>s」と置くことで、今日の停滞を終点ではなく途中経過として見直せます。",
      "この言葉は「%<first>s」を足場にして、気分より半歩先に希望を置く感覚を作ります。",
      "「%<first>s」から「%<last>s」へつなげる流れが、目の前の出来事に飲まれすぎない視点をくれます。"
    ],
    premium: [
      "%<author>sは「%<first>s」と見ることで、小さな前進の価値を取りこぼさない姿勢を示しています。派手な逆転ではなく、今日の中に拾える材料を見つけることが、結果的に気持ちを前へ運びます。",
      "この一文が前向きなのは、根拠のない楽観ではなく「%<first>s」を積み上げの単位にしているからです。「%<last>s」という方向があるだけで、停滞感はかなり薄まります。",
      "%<author>sの言葉は、うまくいった日だけを数えるのではなく「%<first>s」を未来の材料に変える見方を教えます。希望を大声で叫ぶのではなく、次に試す理由を静かに残してくれる一文です。 "
    ]
  },
  "courage" => {
    preview: [
      "「%<first>s」と言うことで、怖さをなくすより先に動きを選ぶ勇気へ焦点を当てています。",
      "この一文は「%<first>s」を通して、ためらいの中でも自分の側から一歩を出す感覚を作ります。",
      "「%<first>s」から「%<last>s」へつなぐことで、勇気を特別な才能ではなく選択として見せています。"
    ],
    premium: [
      "%<author>sのこの言葉は、勇気を『怖くない状態』ではなく「%<first>s」と決める行為として捉えています。だからこそ、不安が消えるのを待たずに今日の行動へ移し替えやすいのです。",
      "この一文の効き目は、「%<first>s」という強い言葉で迷いの重心をずらすところにあります。「%<last>s」と読めるから、勢いだけでなく覚悟の方向まで見えてきます。",
      "%<author>sは「%<first>s」と言い切ることで、年齢や準備不足を言い訳にしない態度を示しています。勇気の正体が、自分に許可を出す速度の問題だとわかる言葉です。 "
    ]
  },
  "inner_strength" => {
    preview: [
      "「%<first>s」という短さが、感情を騒がせずに芯だけを立て直す強さを持っています。",
      "この言葉は「%<first>s」を通して、外側の出来事より内側の姿勢を整える方向へ意識を戻します。",
      "「%<first>s」から「%<last>s」へ至る流れが、静かな強さは選び直せるものだと伝えています。"
    ],
    premium: [
      "%<author>sのこの一文は、強さを声量ではなく「%<first>s」という姿勢で定義しています。揺れない人になることではなく、揺れたあとにどこへ戻るかを決めておくことが、心の持久力になります。",
      "この言葉が深いのは、「%<first>s」を精神論で終わらせず、生き方の基準として置いているからです。「%<last>s」という読みがあると、弱さを否定せずに次の立て直し方を選べます。",
      "%<author>sは「%<first>s」と言うことで、感情の波より判断の軸を優先しています。すぐに楽になれなくても、自分の背骨を曲げないための言葉として効いてきます。 "
    ]
  },
  "love_crush" => {
    preview: [
      "「%<first>s」が示しているのは、恋の高まりだけでなく、その痛みごと引き受ける覚悟です。",
      "この言葉は「%<first>s」を通して、好きという感情を理屈で削りすぎないよう支えてくれます。",
      "「%<first>s」から「%<last>s」へ流れる熱が、恋をきれいごとではなく生身の経験として映し出します。"
    ],
    premium: [
      "%<author>sのこの言葉は、恋の幸福を『傷つかないこと』ではなく「%<first>s」と感じきる厚みに置いています。だからこそ、報われない気持ちさえ人生の密度として抱え直せます。",
      "この一文にあるのは、恋を安全に管理する発想ではなく「%<first>s」という生々しさです。「%<last>s」という響きまで含めて、好きになること自体が人を深くするのだと読めます。",
      "%<author>sは「%<first>s」と言うことで、恋の苦しさを否定するのではなく価値へ反転させています。うまくいくかどうかだけでなく、どれだけ本気で揺れたかがその人の時間を変えると伝わってきます。 "
    ]
  },
  "family_love" => {
    preview: [
      "「%<first>s」という呼びかけが、近すぎる相手ほど雑にしがちな向き合い方を整えます。",
      "この言葉は「%<first>s」を通して、家族に必要なのが正論より関わり方だと気づかせます。",
      "「%<first>s」から「%<last>s」へ向かう流れが、身近な相手との信頼をもう一度手入れさせます。"
    ],
    premium: [
      "%<author>sのこの一文は、家族愛を大きな献身より「%<first>s」という日々の姿勢に置いています。近い相手ほど説明を省いてしまうからこそ、どう関わるかを意識し直す意味があります。",
      "この言葉が効くのは、「%<first>s」という具体的な関わり方まで落としているからです。「%<last>s」と続くことで、家族の安心は気持ちだけではなく接し方から作られるとわかります。",
      "%<author>sは「%<first>s」と言うことで、身内だからわかるはずという甘えを外しています。家族の愛情は自動で続くものではなく、日々の信頼の積み直しで守るものだと読める一文です。 "
    ]
  },
  "for_my_child" => {
    preview: [
      "「%<first>s」という言葉が、子どもを管理するより先に信じる視点へ親を戻します。",
      "この一文は「%<first>s」を通して、正解を与えるよりもその子の存在や問いを守ることの大切さを示します。",
      "「%<first>s」から「%<last>s」へ流れる言葉で、子どもに向けるまなざしそのものを整えます。"
    ],
    premium: [
      "%<author>sのこの言葉は、子育てを『正しく導くこと』より「%<first>s」と受け止めるところから始めています。親が先に安心の土台を渡すことで、子どもは自分で考える力を育てやすくなります。",
      "この一文の中心にあるのは、子どもを結果で判断しない姿勢です。「%<first>s」と言い切ることで、その子の存在や問いを急いで矯正しすぎない余白が生まれます。",
      "%<author>sは「%<first>s」という言葉で、親の役目を答えの押し付けから解放しています。「%<last>s」という余韻まで含めて、子どもが自分の足で立つ未来を信じる視点が見えてきます。 "
    ]
  },
  "relationships" => {
    preview: [
      "「%<first>s」が、人との距離を詰める前にまず姿勢を整える必要を思い出させます。",
      "この言葉は「%<first>s」を通して、相手を変えるより関わり方を見直す視点へ導きます。",
      "「%<first>s」から「%<last>s」へ進む流れで、つながりを保つには尊重と対話の両方がいると伝えています。"
    ],
    premium: [
      "%<author>sのこの一文は、人間関係を感情任せにせず「%<first>s」という態度から組み立て直しています。近づくことと飲み込まれることは別だと分かるので、関係の中で自分を守りやすくなります。",
      "この言葉の強さは、「%<first>s」という具体的な接し方と「%<last>s」という尊重の両方を持っている点です。対人関係で疲れた時ほど、相手にも自分にも境界線がいると実感できます。",
      "%<author>sは「%<first>s」と言うことで、わかり合うことを奇跡ではなく技術に近づけています。相手の個性を認めながら自分も消さない、その難しさに正面から触れた一文です。 "
    ]
  },
  "want_to_quit" => {
    preview: [
      "「%<first>s」と言われると、しんどさの中でも今ここで終わりにしない理由が少し戻ってきます。",
      "この言葉は「%<first>s」を通して、結果が出ない時間の過ごし方に光を当てています。",
      "「%<first>s」から「%<last>s」へつなぐ流れが、折れそうな時ほど姿勢がものを言うと教えます。"
    ],
    premium: [
      "%<author>sのこの一文は、苦しい時期を失敗と断定するのが早すぎると教えています。「%<first>s」と捉え直すだけで、いまの停滞を終点ではなく通過点として扱えるようになります。",
      "この言葉の核は、やめたくなる瞬間そのものではなく、その時にどう居続けるかにあります。「%<first>s」という視点があると、結果が遅れている時間にも意味を置き直せます。",
      "%<author>sは「%<first>s」と言うことで、根性論ではなく継続の定義を修正しています。「%<last>s」という行き先が見えるから、気持ちが切れた日でももう半歩だけ粘る理由になります。 "
    ]
  },
  "affirmation" => {
    preview: [
      "「%<first>s」という断言が、気持ちの波より自分の軸を先に立て直してくれます。",
      "この言葉は「%<first>s」を通して、今日の自分をどんな姿勢で始めるかを静かに決めさせます。",
      "「%<first>s」から「%<last>s」へ向かう流れが、自分に向ける合図として機能します。"
    ],
    premium: [
      "%<author>sのこの一文は、励ましを外からもらうより「%<first>s」と自分で定める力を呼び戻します。朝に読むと効くのは、気分より先に姿勢を決める言葉になっているからです。",
      "この言葉の良さは、「%<first>s」をただの決意表明で終わらせず、その日の行動基準に変えられるところです。「%<last>s」という読みがあると、自分に向ける声の質まで整ってきます。",
      "%<author>sは「%<first>s」と言い切ることで、自己暗示ではなく自己統率に近い感覚を作っています。大きな変化がなくても、今日の自分をどう始めるかを選び直せる一文です。 "
    ]
  }
}.freeze

APPLICATION_PROFILES = {
  "self_love" => [
    "人と比べて気持ちが縮んだ日に、この言葉を『いまの自分を雑に扱わない』ための基準として読むと効きます。",
    "落ち込んだ日ほど、何を足すかより、今の自分をどう扱うかに意識を戻すための言葉になります。",
    "自信を盛るためではなく、自分に向ける視線を少しやわらかくしたい時の支えになります。 "
  ],
  "positive" => [
    "今日は何も進んでいないと感じる日に読むと、ゼロではなく途中だと気持ちを置き直しやすくなります。",
    "しんどさで視野が狭くなった時、次の一歩だけを見つけるための言葉として使えます。",
    "大きく元気になるためではなく、明日に小さな余白を残すために読むとちょうどいい一文です。 "
  ],
  "courage" => [
    "勇気が欲しい場面では、怖さを消すためではなく、怖いまま何を選ぶかを決める言葉として読むと強いです。",
    "迷って動けない時に読むと、『準備が整ったら』ではなく『今どこから始めるか』へ意識を戻せます。",
    "断る、声を出す、やってみる。その最初の小さな決断を後押しする使い方が合います。 "
  ],
  "inner_strength" => [
    "気持ちが乱れている日に読むと、状況を変える前に姿勢を立て直すための支点になります。",
    "すぐに楽になれない時ほど、『何に戻れば自分でいられるか』を思い出す言葉として効きます。",
    "感情に飲まれそうな場面で、反応ではなく自分の基準を選び直すために読む一文です。 "
  ],
  "love_crush" => [
    "恋で揺れている時に読むと、うまくいくかどうかより、自分が本当に感じているものを丁寧に扱いやすくなります。",
    "好きな気持ちを恥ずかしさで潰しそうな時、感情そのものの重みを認めるための言葉になります。",
    "恋の痛みを失敗で終わらせず、自分の感受性として引き受けたい日に合う読み方です。 "
  ],
  "family_love" => [
    "家族にきつく当たってしまった後に読むと、正しさより関わり方を整え直す助けになります。",
    "近い相手だからこそ雑になっていた会話や態度を、もう一度手入れするための言葉です。",
    "仲直りの方法を探す前に、自分がどんな空気で向き合いたいかを思い出す時に効きます。 "
  ],
  "for_my_child" => [
    "子どもを急いで正そうとしている時に読むと、まず信じて待つ姿勢へ戻りやすくなります。",
    "結果や成長だけを見てしまう日に、その子の存在そのものを見るための言葉として使えます。",
    "親として答えを与える前に、どんなまなざしを渡したいかを整える一文です。 "
  ],
  "relationships" => [
    "人間関係で疲れた日に読むと、相手を動かす前に自分の関わり方を整える助けになります。",
    "距離が近すぎる、遠すぎると感じる場面で、尊重と対話のバランスを取り直す時に使えます。",
    "感情でぶつかりそうな時、自分を消さずに相手にも敬意を残す読み方ができる言葉です。 "
  ],
  "want_to_quit" => [
    "もうやめたいと思った日に読むと、結果が出ない時間の意味をすぐ捨てずに済みます。",
    "心が折れそうな時、『終わり』ではなく『まだ途中』として今日を扱うための支えになります。",
    "成果が見えず自分を疑う場面で、姿勢だけは手放さないための言葉として効きます。 "
  ],
  "affirmation" => [
    "朝に読むなら、その日の気分を上げるためではなく、どんな姿勢で始めるかを決める言葉として機能します。",
    "自分を立て直したい日に読むと、感情より先に軸を置く感覚を作りやすくなります。",
    "迷いが多い時ほど、今日の自分にひとつ基準を渡すつもりで読むと残りやすい一文です。 "
  ]
}.freeze

SOURCE_TEMPLATES = [
  "%<author>sの%<author_desc>sとしての視点がにじむ言葉です。",
  "%<author>sが%<author_desc>sとして積み上げてきた感覚が、そのまま短い一文に凝縮されています。",
  "%<author>sという%<author_desc>sの立場だからこそ出てくる、重みのある言葉です。"
].freeze

def normalize_lines(text)
  text.to_s.split("\n").map { |line| line.strip }.reject(&:empty?)
end

def squeeze_text(text)
  text.to_s.gsub(/\s+/, " ").strip
end

def clip_fragment(text, max = 26)
  value = squeeze_text(text)
  return value if value.length <= max

  value[0...max]
end

def render_template(templates, context, salt)
  template = templates[salt % templates.length]
  format(template, context)
end

def build_meaning_preview(quote, salt)
  lines = normalize_lines(quote["quote_ja"])
  first = clip_fragment(lines.first || quote["quote_ja"])
  last = clip_fragment(lines.length > 1 ? lines.last : lines.first || quote["quote_ja"])
  profile = CATEGORY_PROFILES.fetch(quote["category"])
  render_template(profile[:preview], { first: first, last: last }, salt).strip
end

def build_source_context(quote, salt)
  existing = squeeze_text(quote["source_context"])
  return existing unless existing.empty?

  author = quote["author"].to_s.empty? ? "この言葉" : quote["author"]
  author_desc = quote["author_description"].to_s.empty? ? "背景" : quote["author_description"]
  template = SOURCE_TEMPLATES[salt % SOURCE_TEMPLATES.length]
  format(template, author: author, author_desc: author_desc).strip
end

def build_meaning_premium(quote, salt)
  lines = normalize_lines(quote["quote_ja"])
  first = clip_fragment(lines.first || quote["quote_ja"])
  last = clip_fragment(lines.length > 1 ? lines.last : lines.first || quote["quote_ja"])
  author = quote["author"].to_s.empty? ? "この言葉" : quote["author"]
  profile = CATEGORY_PROFILES.fetch(quote["category"])
  core = render_template(profile[:premium], { author: author, first: first, last: last }, salt)
  context = build_source_context(quote, salt)
  application = APPLICATION_PROFILES.fetch(quote["category"])[salt % APPLICATION_PROFILES.fetch(quote["category"]).length]
  [core, context, application].map { |part| squeeze_text(part) }.join(" ").strip
end

def apply_replacements(data)
  grouped_indices = Hash.new { |hash, key| hash[key] = [] }
  data.each_with_index { |quote, index| grouped_indices[quote["category"]] << index }

  REPLACEMENTS.each do |category, replacements|
    targets = grouped_indices.fetch(category).last(replacements.length)
    replacements.each_with_index do |replacement, offset|
      target_index = targets[offset]
      quote = data[target_index]
      replacement.each { |key, value| quote[key] = value }
      quote["source_context"] = nil
    end
  end
end

def uniquify!(data, key)
  seen = {}
  data.each do |quote|
    text = quote[key]
    next unless text

    if seen[text]
      suffix = quote["author"].to_s.empty? ? "この一文らしい余韻です。" : "#{quote["author"]}らしい視点です。"
      quote[key] = "#{text} #{suffix}"
    else
      seen[text] = true
    end
  end
end

def refresh_copy!(data)
  data.each_with_index do |quote, index|
    quote["meaning_preview"] = build_meaning_preview(quote, index)
    quote["source_context"] = build_source_context(quote, index * 5 + 1)
    quote["meaning_premium"] = build_meaning_premium(quote, index * 7 + 3)
  end

  uniquify!(data, "meaning_preview")
  uniquify!(data, "meaning_premium")
end

quotes = JSON.parse(File.read(QUOTES_PATH))
apply_replacements(quotes)
refresh_copy!(quotes)
pretty = JSON.pretty_generate(quotes, indent: "  ", array_nl: "\n", object_nl: "\n")
File.write(QUOTES_PATH, "#{pretty}\n")
File.write(QUOTES_FULL_PATH, "#{pretty}\n")
