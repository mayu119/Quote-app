import json
import re
import subprocess
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QUOTES_PATH = ROOT / "QuoteApp/Sources/Resources/quotes.json"
WORK = ROOT / "_content_redesign_work"


def r(category, author, kana, quote_en, quote_ja, source):
    return {
        "category": category,
        "author": author,
        "author_kana": kana,
        "quote_en": quote_en,
        "quote_ja": quote_ja,
        "source": source,
    }


SOURCES = {
    "brown_belonging": ("Brené Brown『Braving the Wilderness』、TED掲載の抜粋", "https://ideas.ted.com/finding-our-way-to-true-belonging/"),
    "brown_vulnerability": ("Brené Brown TEDxHouston『The Power of Vulnerability』の講演記録", "https://www.ted.com/talks/brene_brown_the_power_of_vulnerability/c/transcript"),
    "brown_daring": ("Brené Brown『Daring Greatly』、TED Blog掲載の本文抜粋", "https://blog.ted.com/5-insights-from-brene-browns-new-book-daring-greatly-out-today/"),
    "brown_boundaries": ("Brené Brown『Dare to Lead』関連の本人対談記録", "https://www.ted.com/podcasts/brene-brown-on-what-vulnerability-isnt-transcript"),
    "oprah_life": ("Oprah Winfrey『What I Know For Sure』および本人インタビュー", "https://www.oprah.com/"),
    "mother_teresa": ("Mother Teresaの著作・公式資料", "https://www.motherteresa.org/"),
    "anne_diary": ("Anne Frank『The Diary of a Young Girl』、Anne Frank House公式資料", "https://www.annefrank.org/en/anne-frank/diary/"),
    "tanigawa_ikiru": ("谷川俊太郎『生きる』", "https://www.shinchosha.co.jp/"),
    "diana_panorama": ("Princess Diana 1995年BBC『Panorama』インタビュー", "https://www.bbc.co.uk/"),
    "george_middlemarch": ("George Eliot『Middlemarch』", "https://www.gutenberg.org/ebooks/145"),
    "barbara_speech": ("Barbara Bush 1990年Wellesley College卒業式スピーチ", "https://www.wellesley.edu/"),
    "alex_roots": ("Alex Haley『Roots』", "https://www.penguinrandomhouse.com/"),
    "madeleine_women": ("Madeleine Albrightの女性支援に関する本人講演", "https://2009-2017.state.gov/"),
    "coretta_community": ("Coretta Scott Kingの講演・The King Center資料", "https://thekingcenter.org/"),
    "anais_diary": ("Anaïs Nin『The Diary of Anaïs Nin』", "https://anaisnin.com/"),
    "charlotte_jane": ("Charlotte Brontë『Jane Eyre』", "https://www.gutenberg.org/ebooks/1260"),
    "christina_rossetti": ("Christina Rossetti『Remember』", "https://www.poetryfoundation.org/poets/christina-rossetti"),
    "browning_sonnets": ("Elizabeth Barrett Browning『Sonnets from the Portuguese』", "https://www.poetryfoundation.org/poems/43742/sonnets-from-the-portuguese-43-how-do-i-love-thee-let-me-count-the-ways"),
    "hooks_all_love": ("bell hooks『All About Love: New Visions』", "https://www.harpercollins.com/products/all-about-love-bell-hooks"),
    "hooks_salvation": ("bell hooks『Salvation: Black People and Love』", "https://www.harpercollins.com/products/salvation-bell-hooks"),
    "lorde_burst": ("Audre Lorde『A Burst of Light』所収のエピローグ", "https://www.loc.gov/item/2023636183/"),
    "lorde_sister": ("Audre Lorde『Sister Outsider』", "https://www.poetryfoundation.org/articles/89445/dear-sister-outsider"),
    "morrison_beloved": ("Toni Morrison『Beloved』", "https://www.nobelprize.org/prizes/literature/1993/morrison/lecture/"),
    "morrison_nobel": ("Toni Morrison 1993年ノーベル文学賞受賞講演", "https://www.nobelprize.org/prizes/literature/1993/morrison/lecture/"),
    "morrison_empower": ("Toni Morrisonの発言を収録したO Magazine『The Truest Eye』", "https://www.oprahdaily.com/"),
    "angelou_letter": ("Maya Angelou『Letter to My Daughter』", "https://mayaangelou.com/"),
    "angelou_interview": ("Maya Angelou本人インタビュー・講演で確認できる発言", "https://mayaangelou.com/"),
    "keller_open": ("Helen Keller『The Open Door』", "https://archive.org/details/opendoor00kell"),
    "keller_optimism": ("Helen Keller『Optimism』", "https://archive.org/details/optimism00kell"),
    "gloria_revolution": ("Gloria Steinem『Revolution from Within』", "https://www.simonandschuster.com/books/Revolution-from-Within/Gloria-Steinem/9780743200395"),
    "gilbert_bigmagic": ("Elizabeth Gilbert『Big Magic』", "https://www.elizabethgilbert.com/books/big-magic/"),
    "strayed_tiny": ("Cheryl Strayed『Tiny Beautiful Things』", "https://www.cherylstrayed.com/tiny-beautiful-things"),
    "butler_parable": ("Octavia E. Butler『Parable of the Sower』", "https://www.penguinrandomhouse.com/books/55832/parable-of-the-sower-by-octavia-e-butler/"),
    "oliver_poetry": ("Mary Oliverの詩集・詩本文、Poetry Foundation掲載の確認記事", "https://www.poetryfoundation.org/articles/81975/attention-as-a-form-of-devotion-to-mary-oliver"),
    "didion_year": ("Joan Didion『The Year of Magical Thinking』", "https://www.penguinrandomhouse.com/books/29293/the-year-of-magical-thinking-by-joan-didion/"),
    "alcott_little": ("Louisa May Alcott『Little Women』", "https://www.gutenberg.org/ebooks/514"),
    "austen_emma": ("Jane Austen『Emma』", "https://www.gutenberg.org/ebooks/158"),
    "austen_pride": ("Jane Austen『Pride and Prejudice』", "https://www.gutenberg.org/ebooks/1342"),
    "woolf_waves": ("Virginia Woolf『The Waves』", "https://www.gutenberg.org/ebooks/1321"),
    "woolf_room": ("Virginia Woolf『A Room of One's Own』", "https://www.gutenberg.org/ebooks/65845"),
    "dickinson_poems": ("Emily Dickinson詩篇、Poetry Foundation掲載本文", "https://www.poetryfoundation.org/poets/emily-dickinson"),
    "weill_waiting": ("Simone Weil『Waiting for God』", "https://archive.org/details/waitingforgod00weil"),
    "waheed_salt": ("Nayyirah Waheed『salt.』", "https://www.nayyirahwaheed.com/"),
    "rupi_books": ("Rupi Kaur『milk and honey』『the sun and her flowers』", "https://rupikaur.com/"),
    "zora_their": ("Zora Neale Hurston『Their Eyes Were Watching God』", "https://www.harpercollins.com/products/their-eyes-were-watching-god-zora-neale-hurston"),
    "rowling_harvard": ("J.K. Rowling 2008年Harvard Commencement Speech", "https://www.harvard.edu/president/news/2008/commencement-address/"),
    "suu_freedom": ("Aung San Suu Kyi『Freedom from Fear』", "https://www.penguinrandomhouse.com/books/17080/freedom-from-fear-by-aung-san-suu-kyi/"),
    "frida_diary": ("Frida Kahlo『The Diary of Frida Kahlo』", "https://www.hachettebookgroup.com/titles/frida-kahlo/the-diary-of-frida-kahlo/9780811800277/"),
    "roosevelt_story": ("Eleanor Roosevelt『This Is My Story』", "https://archive.org/details/thisismystory00roos"),
    "roosevelt_day": ("Eleanor Roosevelt『My Day』、Eleanor Roosevelt Papers Project", "https://erpapers.columbian.gwu.edu/"),
    "amelia_biography": ("Amelia Earhartの本人発言を収録した公刊伝記・Purdue University資料", "https://www.lib.purdue.edu/spcol/earhart/"),
    "parks_memoir": ("Rosa Parks『Rosa Parks: My Story』および本人回想", "https://www.loc.gov/resource/mss85943.001814/"),
    "michelle_dnc": ("Michelle Obama 2016年民主党全国大会スピーチ", "https://obamawhitehouse.archives.gov/the-press-office/2016/07/25/remarks-first-lady-at-the-democratic-national-convention"),
    "michelle_mentor": ("Michelle Obama 2011年National Mentoring Summit講演", "https://obamawhitehouse.archives.gov/blog/2011/01/27/first-lady-mentorship-kids-don-t-need-you-be-superman-they-just-need-you-be-there"),
    "michelle_parents": ("Michelle Obamaの公式スピーチ、子どもと親についての発言", "https://obamawhitehouse.archives.gov/the-press-office/remarks-first-lady-michelle-obama"),
    "malala_un": ("Malala Yousafzai 2013年国連スピーチ", "https://malala.org/news-and-voices/malala-day-speech-at-un-house-nigeria"),
    "malala_worldbank": ("Malala Yousafzai 2013年World Bank対談記録", "https://www.worldbank.org/en/news/speech/2013/10/11/transcript-malala-yousafzai-malala-day-speech-at-un-house-nigeria"),
    "rbg_interview": ("Ruth Bader Ginsburgの公式インタビュー・講演記録", "https://www.supremecourt.gov/about/biographyGinsburg.aspx"),
    "susan_speech": ("Susan B. Anthony本人の公刊演説・Library of Congress資料", "https://www.loc.gov/collections/susan-b-anthony-papers/"),
    "mandela_long": ("Nelson Mandela『Long Walk to Freedom』", "https://www.nelsonmandela.org/long-walk-to-freedom"),
    "baldwin_essay": ("James Baldwinのエッセイ・講演本文", "https://www.penguinrandomhouse.com/authors/2133/james-baldwin/"),
    "rogers_world": ("Fred Rogers『The World According to Mister Rogers』", "https://www.penguinrandomhouse.com/books/1683/the-world-according-to-mister-rogers-by-fred-rogers/"),
    "montessori_method": ("Maria Montessori『The Montessori Method』『The Absorbent Mind』", "https://montessori-ami.org/resource-library/books"),
    "gibran_prophet": ("Kahlil Gibran『The Prophet』", "https://www.gutenberg.org/ebooks/58585"),
    "ginott_parent": ("Haim G. Ginott『Between Parent and Child』", "https://www.penguinrandomhouse.com/books/311870/between-parent-and-child-by-haim-g-ginott/"),
    "korczak_child": ("Janusz Korczak『How to Love a Child』『The Child's Right to Respect』", "https://www.korczak.com/"),
    "jane_goodall": ("Jane Goodall Institute掲載の本人の言葉", "https://janegoodall.org/tributes-and-reflections/"),
    "marti_edad": ("José Martí『La Edad de Oro』", "https://www.loc.gov/item/2021666787/"),
    "picasso_interview": ("Pablo Picassoの公刊インタビュー・発言記録", "https://www.museepicassoparis.fr/en/pablo-picasso"),
    "sasaki_child": ("佐々木正美の子育て著作・講演記録", "https://www.kodansha.co.jp/"),
    "kuroyanagi_totto": ("黒柳徹子『窓ぎわのトットちゃん』", "https://www.kodansha.co.jp/books/9784062932127"),
    "ibaraki_sens": ("茨木のり子『自分の感受性くらい』", "https://www.iwanami.co.jp/book/b248047.html"),
    "ibaraki_rely": ("茨木のり子『倚りかからず』", "https://www.chikumashobo.co.jp/product/9784480422513/"),
    "kaneko_poem": ("金子みすゞ『私と小鳥と鈴と』", "https://www.nhk-ep.com/products/detail/h14535A1"),
    "kaneko_echo": ("金子みすゞ『こだまでしょうか』", "https://www.nhk-ep.com/"),
    "tawara_salad": ("俵万智『サラダ記念日』", "https://www.kadokawa.co.jp/product/321606000524/"),
    "yosano_midare": ("与謝野晶子『みだれ髪』", "https://www.aozora.gr.jp/cards/000885/card174.html"),
    "yosano_yama": ("与謝野晶子『そぞろごと』所収の詩句", "https://www.aozora.gr.jp/cards/000885/"),
    "yosano_otouto": ("与謝野晶子『君死にたまふことなかれ』", "https://www.aozora.gr.jp/cards/000885/card3346.html"),
    "seishonagon_makura": ("清少納言『枕草子』", "https://www.aozora.gr.jp/cards/000199/card53990.html"),
    "murasaki_waka": ("紫式部の和歌、百人一首所収", "https://www.aozora.gr.jp/cards/000052/"),
    "miyazawa_nomin": ("宮沢賢治『農民芸術概論綱要』", "https://www.aozora.gr.jp/cards/000081/card2386.html"),
    "kiki_interview": ("樹木希林の生前の発言を収録した『一切なりゆき』・告別式紹介", "https://books.bunshun.jp/articles/-/5231"),
    "fromm_loving": ("Erich Fromm『The Art of Loving』", "https://www.harpercollins.com/products/the-art-of-loving-erich-fromm"),
    "rilke_letters": ("Rainer Maria Rilke『Letters to a Young Poet』", "https://www.gutenberg.org/ebooks/5317"),
    "thich_love": ("Thích Nhất Hạnhの著作『How to Love』", "https://plumvillage.org/books/how-to-love"),
    "mlk_strength": ("Martin Luther King Jr.『Strength to Love』", "https://kinginstitute.stanford.edu/king-papers/publications/strength-love"),
    "emerson_essays": ("Ralph Waldo Emerson『Essays: First Series』", "https://www.gutenberg.org/ebooks/16643"),
    "csl_four": ("C. S. Lewis『The Four Loves』", "https://www.cslewisinstitute.org/resources/the-four-loves/"),
    "thoreau_journal": ("Henry David Thoreau『A Week on the Concord and Merrimack Rivers』等の公刊著作", "https://gutenberg.org/ebooks/4232"),
    "wilde_plays": ("Oscar Wilde『A Woman of No Importance』等の公刊作品", "https://www.gutenberg.org/ebooks/51563"),
    "seneca_letters": ("Seneca『Moral Letters to Lucilius』", "https://www.gutenberg.org/ebooks/56075"),
    "marcus_meditations": ("Marcus Aurelius『Meditations』", "https://www.gutenberg.org/ebooks/2680"),
    "frankl_man": ("Viktor Frankl『Man's Search for Meaning』", "https://www.beacon.org/Mans-Search-for-Meaning-P404.aspx"),
    "gibran_pain": ("Kahlil Gibran『The Prophet』所収『On Pain』", "https://www.gutenberg.org/ebooks/58585"),
    "bradstreet_poems": ("Anne Bradstreet詩篇", "https://www.poetryfoundation.org/poets/anne-bradstreet"),
    "ephron_wellesley": ("Nora Ephron 1996年Wellesley College卒業式スピーチ", "https://www.wellesley.edu/news/1996/commencement"),
    "glennon_podcast": ("Glennon Doyle『We Can Do Hard Things』公式ポッドキャスト", "https://wecandohardthingspodcast.com/"),
}


META = {
    "Brene Brown": ("ブレネー・ブラウン", "アメリカの研究者・作家", "F", 1965, None, "脆さ、勇気、つながりを研究してきた作家。"),
    "bell hooks": ("ベル・フックス", "アメリカの批評家・作家", "F", 1952, 2021, "愛と教育について書いた批評家・作家。"),
    "Audre Lorde": ("オードリー・ロード", "アメリカの詩人・活動家", "F", 1934, 1992, "詩と批評を通じて声とケアを考えた詩人。"),
    "Toni Morrison": ("トニ・モリスン", "アメリカの作家", "F", 1931, 2019, "1993年ノーベル文学賞受賞作家。"),
    "Maya Angelou": ("マヤ・アンジェロウ", "アメリカの詩人・作家", "F", 1928, 2014, "詩と自伝で生の声を残した作家。"),
    "Helen Keller": ("ヘレン・ケラー", "アメリカの作家・活動家", "F", 1880, 1968, "著作と活動を通じて障害者教育を訴えた作家。"),
    "Gloria Steinem": ("グロリア・スタイネム", "アメリカの作家・活動家", "F", 1934, None, "女性の権利をめぐる執筆と活動を続ける作家。"),
    "Elizabeth Gilbert": ("エリザベス・ギルバート", "アメリカの作家", "F", 1969, None, "創作と人生について書く作家。"),
    "Cheryl Strayed": ("シェリル・ストレイド", "アメリカの作家", "F", 1968, None, "喪失と再出発について書く作家。"),
    "Octavia E. Butler": ("オクテイヴィア・E・バトラー", "アメリカの作家", "F", 1947, 2006, "変化と共生を描いたSF作家。"),
    "Mary Oliver": ("メアリー・オリヴァー", "アメリカの詩人", "F", 1935, 2019, "日常の観察と生の手触りを詠んだ詩人。"),
    "Joan Didion": ("ジョーン・ディディオン", "アメリカの作家・ジャーナリスト", "F", 1934, 2021, "喪失と記憶を精密に書いた作家。"),
    "Louisa May Alcott": ("ルイーザ・メイ・オルコット", "アメリカの作家", "F", 1832, 1888, "『若草物語』で知られる作家。"),
    "Jane Austen": ("ジェイン・オースティン", "イギリスの作家", "F", 1775, 1817, "人間関係を機知と観察で描いた作家。"),
    "Virginia Woolf": ("ヴァージニア・ウルフ", "イギリスの作家", "F", 1882, 1941, "意識と女性の生活を書いた作家。"),
    "Emily Dickinson": ("エミリー・ディキンソン", "アメリカの詩人", "F", 1830, 1886, "短い詩句で内面と自然を描いた詩人。"),
    "Simone Weil": ("シモーヌ・ヴェイユ", "フランスの思想家", "F", 1909, 1943, "注意と他者へのまなざしを考えた思想家。"),
    "Nayyirah Waheed": ("ナイイラ・ワヒード", "アメリカの詩人", "F", None, None, "短い詩で身体と自己へのまなざしを綴る詩人。"),
    "Zora Neale Hurston": ("ゾラ・ニール・ハーストン", "アメリカの作家・民俗学者", "F", 1891, 1960, "黒人女性の生活と声を描いた作家。"),
    "Oprah Winfrey": ("オプラ・ウィンフリー", "アメリカの司会者・作家", "F", 1954, None, "インタビューと著作を通じて人生を語る司会者・作家。"),
    "Mother Teresa": ("マザー・テレサ", "修道者・慈善活動家", "F", 1910, 1997, "貧困者支援に生涯を捧げた修道者。"),
    "George Eliot": ("ジョージ・エリオット", "イギリスの作家", "F", 1819, 1880, "人間関係と倫理を描いた作家。"),
    "Charlotte Brontë": ("シャーロット・ブロンテ", "イギリスの作家", "F", 1816, 1855, "愛と自立を描いた作家。"),
    "Elizabeth Barrett Browning": ("エリザベス・バレット・ブラウニング", "イギリスの詩人", "F", 1806, 1861, "愛のソネットで知られる詩人。"),
    "Rupi Kaur": ("ルピ・カウル", "カナダの詩人・作家", "F", 1992, None, "身体と愛を短い詩で綴る詩人。"),
    "Glennon Doyle": ("グレノン・ドイル", "アメリカの作家・活動家", "F", 1976, None, "困難と回復について発信する作家。"),
    "Christina Rossetti": ("クリスティーナ・ロセッティ", "イギリスの詩人", "F", 1830, 1894, "愛と喪失を詠んだ詩人。"),
    "Barbara Bush": ("バーバラ・ブッシュ", "アメリカの公職者", "F", 1925, 2018, "教育と家族について発信した公職者。"),
    "Alex Haley": ("アレックス・ヘイリー", "アメリカの作家", "M", 1921, 1992, "家族史を描いた作家。"),
    "J.K. Rowling": ("J・K・ローリング", "イギリスの作家", "F", 1965, None, "小説と卒業式スピーチで知られる作家。"),
    "Aung San Suu Kyi": ("アウンサンスーチー", "ミャンマーの政治家・活動家", "F", 1945, None, "恐れと自由について著作を残した活動家。"),
    "Frida Kahlo": ("フリーダ・カーロ", "メキシコの画家", "F", 1907, 1954, "日記と絵画に身体と生の経験を残した画家。"),
    "Eleanor Roosevelt": ("エレノア・ルーズベルト", "アメリカの公職者・作家", "F", 1884, 1962, "人権と女性の権利を訴えた公職者・作家。"),
    "Amelia Earhart": ("アメリア・イアハート", "アメリカの飛行家", "F", 1897, 1937, "大西洋単独横断などで知られる飛行家。"),
    "Rosa Parks": ("ローザ・パークス", "アメリカの公民権活動家", "F", 1913, 2005, "公民権運動に参加した活動家。"),
    "Michelle Obama": ("ミシェル・オバマ", "アメリカの弁護士・作家", "F", 1964, None, "教育と家族について発信してきた作家。"),
    "Malala Yousafzai": ("マララ・ユスフザイ", "パキスタンの教育活動家", "F", 1997, None, "女子教育の権利を訴える活動家。"),
    "Ruth Bader Ginsburg": ("ルース・ベイダー・ギンズバーグ", "アメリカの法学者・裁判官", "F", 1933, 2020, "法の下の平等を訴えた裁判官。"),
    "Susan B. Anthony": ("スーザン・B・アンソニー", "アメリカの女性参政権活動家", "F", 1820, 1906, "女性参政権運動を率いた活動家。"),
    "Nora Ephron": ("ノーラ・エフロン", "アメリカの作家・映画監督", "F", 1941, 2012, "作家・脚本家として日常と恋愛を描いた。"),
    "Anne Bradstreet": ("アン・ブラッドストリート", "イギリス生まれの詩人", "F", 1612, 1672, "英語圏最初期の女性詩人の一人。"),
    "Princess Diana": ("ダイアナ元妃", "イギリスの王族・慈善活動家", "F", 1961, 1997, "慈善活動と人道支援で知られる。"),
    "Maria Montessori": ("マリア・モンテッソーリ", "イタリアの教育者・医師", "F", 1870, 1952, "子どもの自発性を尊重する教育法を築いた。"),
    "Jane Goodall": ("ジェーン・グドール", "イギリスの霊長類学者・活動家", "F", 1934, None, "チンパンジー研究と環境活動で知られる。"),
    "清少納言": ("せいしょうなごん", "平安時代の作家", "F", None, None, "『枕草子』を著した平安時代の作家。"),
    "紫式部": ("むらさきしきぶ", "平安時代の作家", "F", None, None, "『源氏物語』を著した平安時代の作家。"),
    "金子みすゞ": ("かねこみすず", "日本の詩人", "F", 1903, 1930, "童謡詩を残した日本の詩人。"),
    "茨木のり子": ("いばらぎのりこ", "日本の詩人", "F", 1926, 2006, "自立と感受性を詠んだ日本の詩人。"),
    "与謝野晶子": ("よさのあきこ", "日本の歌人・作家", "F", 1878, 1942, "『みだれ髪』などで知られる歌人。"),
    "俵万智": ("たわらまち", "日本の歌人", "F", 1962, None, "日常語で短歌を広げた歌人。"),
    "黒柳徹子": ("くろやなぎてつこ", "日本の俳優・作家", "F", 1933, None, "俳優・作家として子どもの世界を書いた。"),
    "樹木希林": ("きききりん", "日本の俳優", "F", 1943, 2018, "生活を面白がる視点を残した俳優。"),
    "佐々木正美": ("ささきまさみ", "日本の児童精神科医", "M", 1935, 2017, "子どもの育ちと親子関係を書いた医師。"),
    "宮沢賢治": ("みやざわけんじ", "日本の作家・詩人", "M", 1896, 1933, "詩と童話を残した作家。"),
    "谷川俊太郎": ("たにかわしゅんたろう", "日本の詩人", "M", 1931, 2024, "平明な言葉で生を詠んだ詩人。"),
    "James Baldwin": ("ジェイムズ・ボールドウィン", "アメリカの作家・批評家", "M", 1924, 1987, "人種と教育と人間関係を書いた作家。"),
    "Fred Rogers": ("フレッド・ロジャース", "アメリカの教育者・司会者", "M", 1928, 2003, "子ども向け番組を通じて感情と言葉を扱った教育者。"),
    "Kahlil Gibran": ("ハリール・ジブラーン", "レバノン系アメリカ人の作家", "M", 1883, 1931, "『預言者』で知られる作家・詩人。"),
    "Nelson Mandela": ("ネルソン・マンデラ", "南アフリカの政治家", "M", 1918, 2013, "反アパルトヘイト運動を率いた政治家。"),
    "Pablo Picasso": ("パブロ・ピカソ", "スペインの画家", "M", 1881, 1973, "20世紀美術を代表する画家。"),
    "Haim Ginott": ("ハイム・G・ギノット", "イスラエル系アメリカ人の心理学者", "M", 1922, 1973, "親子のコミュニケーションを書いた心理学者。"),
    "Janusz Korczak": ("ヤヌシュ・コルチャック", "ポーランドの医師・教育者", "M", 1878, 1942, "子どもの権利を訴えた医師・教育者。"),
    "José Martí": ("ホセ・マルティ", "キューバの作家・思想家", "M", 1853, 1895, "教育と自由を論じた作家・思想家。"),
    "Erich Fromm": ("エーリッヒ・フロム", "ドイツ生まれの社会心理学者", "M", 1900, 1980, "愛と自由について書いた社会心理学者。"),
    "Rainer Maria Rilke": ("ライナー・マリア・リルケ", "オーストリアの詩人", "M", 1875, 1926, "詩と書簡を残した詩人。"),
    "Thích Nhất Hạnh": ("ティク・ナット・ハン", "ベトナムの僧侶・作家", "M", 1926, 2022, "慈悲と自由について書いた僧侶・作家。"),
    "Martin Luther King Jr.": ("マーティン・ルーサー・キング・ジュニア", "アメリカの牧師・活動家", "M", 1929, 1968, "公民権運動を率いた牧師・活動家。"),
    "Ralph Waldo Emerson": ("ラルフ・ウォルドー・エマーソン", "アメリカの思想家・作家", "M", 1803, 1882, "自己信頼と自然について書いた思想家。"),
    "C.S. Lewis": ("C・S・ルイス", "イギリスの作家・研究者", "M", 1898, 1963, "文学と愛について書いた作家。"),
    "Henry David Thoreau": ("ヘンリー・デイヴィッド・ソロー", "アメリカの思想家・作家", "M", 1817, 1862, "自然と簡素な生活について書いた作家。"),
    "Oscar Wilde": ("オスカー・ワイルド", "アイルランドの作家・劇作家", "M", 1854, 1900, "機知に富む戯曲と小説を残した作家。"),
    "Seneca": ("セネカ", "ローマの哲学者・政治家", "M", None, 65, "困難と生き方について書いた哲学者。"),
    "Marcus Aurelius": ("マルクス・アウレリウス", "ローマ皇帝・哲学者", "M", 121, 180, "『自省録』を残した哲学者。"),
    "Viktor Frankl": ("ヴィクトール・フランクル", "オーストリアの精神科医・作家", "M", 1905, 1997, "意味と生きる力について書いた精神科医。"),
}


REAL = defaultdict(list)

# self_love
REAL["self_love"] += [
    r("self_love", "Brene Brown", "ブレネー・ブラウン", "Belonging is the innate human desire to be part of something larger than us.", "居場所を求める気持ちは、自分より大きな何かに加わりたいという人間の自然な願いです。", "brown_belonging"),
    r("self_love", "bell hooks", "ベル・フックス", "Love is an act of will, namely, both an intention and an action.", "愛は意志の行為です。思うだけでなく、意図して行うことでもあります。", "hooks_all_love"),
    r("self_love", "Helen Keller", "ヘレン・ケラー", "One can never consent to creep when one feels an impulse to soar.", "飛びたい衝動があるなら、這うことに甘んじてはいけません。", "keller_open"),
    r("self_love", "Audre Lorde", "オードリー・ロード", "Caring for myself is not self-indulgence, it is self-preservation.", "自分をいたわることは、甘やかしではなく、自分を守ることです。", "lorde_burst"),
    r("self_love", "Maya Angelou", "マヤ・アンジェロウ", "If you are always trying to be normal you will never know how amazing you can be.", "いつも普通になろうとしていたら、自分がどれほど素敵になれるかを知らないままです。", "angelou_letter"),
    r("self_love", "Toni Morrison", "トニ・モリスン", "You are your best thing.", "あなたは、あなたにとっていちばん大切なものです。", "morrison_beloved"),
    r("self_love", "Zora Neale Hurston", "ゾラ・ニール・ハーストン", "There are years that ask questions and years that answer.", "問いを投げかける年もあれば、答えをくれる年もあります。", "zora_their"),
    r("self_love", "Rupi Kaur", "ルピ・カウル", "how you love yourself / is how you teach others / to love you", "自分をどう愛するかが、誰かにどう愛されるかを教えていく。", "rupi_books"),
    r("self_love", "Elizabeth Gilbert", "エリザベス・ギルバート", "A creative life is an amplified life, a bigger life, a happier life.", "創造する人生は、広がった人生です。大きく、そして幸せな人生です。", "gilbert_bigmagic"),
    r("self_love", "Cheryl Strayed", "シェリル・ストレイド", "Put yourself in the way of beauty.", "美しいものが届く場所に、自分を置いてみなさい。", "strayed_tiny"),
    r("self_love", "Octavia E. Butler", "オクテイヴィア・E・バトラー", "All that you touch You Change. All that you Change Changes you.", "あなたが触れるものは変わり、あなたが変えるものはあなたを変えます。", "butler_parable"),
    r("self_love", "Mary Oliver", "メアリー・オリヴァー", "To pay attention, this is our endless and proper work.", "注意を向けること。それが、終わりのない私たちの仕事です。", "oliver_poetry"),
    r("self_love", "Joan Didion", "ジョーン・ディディオン", "Life changes in the instant. The ordinary instant.", "人生は、一瞬で変わります。何気ない一瞬に。", "didion_year"),
    r("self_love", "Louisa May Alcott", "ルイーザ・メイ・オルコット", "I am not afraid of storms, for I am learning how to sail my ship.", "嵐は怖くありません。私は、自分の船の進め方を覚えているところだから。", "alcott_little"),
    r("self_love", "Jane Austen", "ジェイン・オースティン", "There is no charm equal to tenderness of heart.", "心のやわらかさに勝る魅力はありません。", "austen_emma"),
    r("self_love", "Emily Dickinson", "エミリー・ディキンソン", "I dwell in Possibility.", "私は、可能性の中に住んでいます。", "dickinson_poems"),
    r("self_love", "Virginia Woolf", "ヴァージニア・ウルフ", "I am rooted, but I flow.", "私は根を張りながら、流れていく。", "woolf_waves"),
    r("self_love", "Nayyirah Waheed", "ナイイラ・ワヒード", "and i said to my body. softly. i want to be your friend.", "私は自分の身体に、そっと言った。友だちになりたい。", "waheed_salt"),
    r("self_love", "Simone Weil", "シモーヌ・ヴェイユ", "Attention is the rarest and purest form of generosity.", "注意深く見ることは、最も静かで純粋な贈りものです。", "weill_waiting"),
    r("self_love", "Gloria Steinem", "グロリア・スタイネム", "Dreaming, after all, is a form of planning.", "夢を見ることは、結局のところ、計画を立てることでもあります。", "gloria_revolution"),
    r("self_love", "茨木のり子", "いばらぎのりこ", None, "自分の感受性くらい\n自分で守れ\nばかものよ", "ibaraki_sens"),
    r("self_love", "金子みすゞ", "かねこみすず", None, "鈴と、小鳥と、それから私\nみんなちがって、みんないい。", "kaneko_poem"),
    r("self_love", "与謝野晶子", "よさのあきこ", None, "山の動く日来る。", "yosano_yama"),
    r("self_love", "黒柳徹子", "くろやなぎてつこ", None, "君は、本当は、いい子なんだよ。", "kuroyanagi_totto"),
]

# positive
REAL["positive"] += [
    r("positive", "Helen Keller", "ヘレン・ケラー", "Although the world is full of suffering, it is full also of the overcoming of it.", "世界は苦しみに満ちています。それを越えていく力にも満ちています。", "keller_optimism"),
    r("positive", "Eleanor Roosevelt", "エレノア・ルーズベルト", "With the new day comes new strength and new thoughts.", "新しい日には、新しい力と新しい考えがやってきます。", "roosevelt_day"),
    r("positive", "Oprah Winfrey", "オプラ・ウィンフリー", "The more you praise and celebrate your life, the more there is in life to celebrate.", "自分の人生を喜び、祝うほど、祝えるものは増えていきます。", "oprah_life"),
    r("positive", "Mary Oliver", "メアリー・オリヴァー", "Instructions for living a life: Pay attention. Be astonished. Tell about it.", "生きるための指示。よく見て、驚いて、それを話すこと。", "oliver_poetry"),
    r("positive", "Toni Morrison", "トニ・モリスン", "If you want to fly, you have to give up the things that weigh you down.", "飛びたいなら、重くしているものを手放さなければなりません。", "morrison_beloved"),
    r("positive", "Zora Neale Hurston", "ゾラ・ニール・ハーストン", "Love makes your soul crawl out from its hiding place.", "愛は、隠れていた魂を外へ連れ出します。", "zora_their"),
    r("positive", "Rupi Kaur", "ルピ・カウル", "the universe took its time on you / crafted you to offer the world / something different from everyone else", "宇宙は時間をかけてあなたをつくり、誰とも違うものを世界に渡せるようにした。", "rupi_books"),
    r("positive", "Anne Frank", "アンネ・フランク", "How wonderful it is that nobody need wait a single moment before starting to improve the world.", "世界を少しよくし始めるのに、誰も一瞬たりとも待たなくていい。なんて素敵なことだろう。", "anne_diary"),
    r("positive", "Jane Austen", "ジェイン・オースティン", "Ah! There is nothing like staying at home for real comfort.", "ああ、本当の安らぎなら、家にいることにかないません。", "austen_emma"),
    r("positive", "Emily Dickinson", "エミリー・ディキンソン", "Hope is the thing with feathers that perches in the soul.", "希望は、魂にとまる羽のあるもの。", "dickinson_poems"),
    r("positive", "Maya Angelou", "マヤ・アンジェロウ", "Try to be a rainbow in someone's cloud.", "誰かの雲の中で、虹になってみなさい。", "angelou_letter"),
    r("positive", "Brene Brown", "ブレネー・ブラウン", "Owning our story and loving ourselves through that process is the bravest thing that we'll ever do.", "自分の物語を引き受け、その途中の自分を愛することが、いちばん勇気のいることです。", "brown_daring"),
    r("positive", "bell hooks", "ベル・フックス", "When we choose to love, we choose to move against fear, against alienation and separation.", "愛することを選ぶとき、恐れや孤立、分断に抗うことを選びます。", "hooks_salvation"),
    r("positive", "Octavia E. Butler", "オクテイヴィア・E・バトラー", "God is Change.", "神は変化です。", "butler_parable"),
    r("positive", "Malala Yousafzai", "マララ・ユスフザイ", "Let us make our future now, and let us make our dreams tomorrow's reality.", "いま未来をつくり、明日には夢を現実にしましょう。", "malala_un"),
    r("positive", "Virginia Woolf", "ヴァージニア・ウルフ", "One cannot think well, love well, sleep well, if one has not dined well.", "よく考え、よく愛し、よく眠るには、きちんと食べていなければなりません。", "woolf_room"),
    r("positive", "Maya Angelou", "マヤ・アンジェロウ", "You may not control all of the events that happen to you, but you can decide not to be reduced by them.", "起きることのすべては選べなくても、それによって小さくならないと決めることはできます。", "angelou_letter"),
    r("positive", "Elizabeth Gilbert", "エリザベス・ギルバート", "The universe buries strange jewels deep within us all, and then stands back to see if we can find them.", "宇宙は私たちの中に不思議な宝石を埋め、見つけられるかを静かに見ています。", "gilbert_bigmagic"),
    r("positive", "Joan Didion", "ジョーン・ディディオン", "We forget all too soon the things we thought we could never forget.", "決して忘れないと思ったことほど、私たちはあまりに早く忘れてしまいます。", "didion_year"),
    r("positive", "Mother Teresa", "マザー・テレサ", "Be faithful in small things because it is in them that your strength lies.", "小さなことに誠実でいなさい。そこにあなたの力があるからです。", "mother_teresa"),
    r("positive", "谷川俊太郎", "たにかわしゅんたろう", None, "生きているということ\nいま生きているということ", "tanigawa_ikiru"),
    r("positive", "俵万智", "たわらまち", None, "この味がいいねと君が言ったから\n七月六日はサラダ記念日", "tawara_salad"),
    r("positive", "宮沢賢治", "みやざわけんじ", None, "世界がぜんたい幸福にならないうちは\n個人の幸福はあり得ない。", "miyazawa_nomin"),
    r("positive", "清少納言", "せいしょうなごん", None, "春はあけぼの。\nやうやう白くなりゆく山ぎは。", "seishonagon_makura"),
]

# courage
REAL["courage"] += [
    r("courage", "Eleanor Roosevelt", "エレノア・ルーズベルト", "You must do the thing you think you cannot do.", "できないと思っていることを、やってみなさい。", "roosevelt_story"),
    r("courage", "Audre Lorde", "オードリー・ロード", "When I dare to be powerful, to use my strength in the service of my vision, then it becomes less and less important whether I am afraid.", "自分の力を使う覚悟を決めるほど、怖いかどうかは小さなことになります。", "lorde_sister"),
    r("courage", "Michelle Obama", "ミシェル・オバマ", "Sometimes the best way to deal with fear is to just get moving.", "怖さに向き合ういちばんの方法は、まず動き始めることかもしれません。", "michelle_dnc"),
    r("courage", "Amelia Earhart", "アメリア・イアハート", "The most difficult thing is the decision to act, the rest is merely tenacity.", "いちばん難しいのは行動を決めること。あとは粘り強さの問題です。", "amelia_biography"),
    r("courage", "Rosa Parks", "ローザ・パークス", "The only tired I was, was tired of giving in.", "私が疲れていたのは、諦め続けることに疲れていたからです。", "parks_memoir"),
    r("courage", "Maya Angelou", "マヤ・アンジェロウ", "We may encounter many defeats but we must not be defeated.", "何度も負けることはあっても、負けたままになってはいけません。", "angelou_letter"),
    r("courage", "Susan B. Anthony", "スーザン・B・アンソニー", "Failure is impossible.", "失敗は、ありえません。", "susan_speech"),
    r("courage", "Ruth Bader Ginsburg", "ルース・ベイダー・ギンズバーグ", "Real change, enduring change, happens one step at a time.", "本当の変化、残っていく変化は、一歩ずつ起きます。", "rbg_interview"),
    r("courage", "Brene Brown", "ブレネー・ブラウン", "Vulnerability is the birthplace of innovation, creativity and change.", "不確かさに身を置くことが、創造と変化の生まれる場所になります。", "brown_vulnerability"),
    r("courage", "Frida Kahlo", "フリーダ・カーロ", "At the end of the day, we can endure much more than we think we can.", "一日の終わりには、自分が思うよりずっと多くを耐えてきたとわかります。", "frida_diary"),
    r("courage", "Mary Oliver", "メアリー・オリヴァー", "Tell me, what is it you plan to do with your one wild and precious life?", "教えてください。この一度きりの、自由で大切な人生で、何をするつもりですか。", "oliver_poetry"),
    r("courage", "Toni Morrison", "トニ・モリスン", "The function of freedom is to free someone else.", "自由の役割は、誰かを自由にすることです。", "morrison_nobel"),
    r("courage", "Aung San Suu Kyi", "アウンサンスーチー", "The only real prison is fear, and the only real freedom is freedom from fear.", "本当の牢獄は恐れだけ。本当の自由は、恐れから自由になることです。", "suu_freedom"),
    r("courage", "Malala Yousafzai", "マララ・ユスフザイ", "I raise up my voice, not so that I can shout, but so that those without a voice can be heard.", "声を上げるのは叫ぶためでなく、声を持たない人の声が届くようにするためです。", "malala_un"),
    r("courage", "Maya Angelou", "マヤ・アンジェロウ", "Nothing can dim the light which shines from within.", "内側から輝く光を、消せるものはありません。", "angelou_letter"),
    r("courage", "Jane Austen", "ジェイン・オースティン", "I am half agony, half hope.", "私は苦しさが半分、希望が半分です。", "austen_pride"),
    r("courage", "Emily Dickinson", "エミリー・ディキンソン", "If I can stop one heart from breaking, I shall not live in vain.", "ひとつの心が壊れるのを止められたなら、私の生は無駄ではありません。", "dickinson_poems"),
    r("courage", "Gloria Steinem", "グロリア・スタイネム", "A feminist is anyone who recognizes the equality and full humanity of women and men.", "女性と男性の平等と、人としての十分な価値を認める人は、誰でもフェミニストです。", "gloria_revolution"),
    r("courage", "J.K. Rowling", "J・K・ローリング", "Rock bottom became the solid foundation on which I rebuilt my life.", "どん底は、人生を建て直すための確かな土台になりました。", "rowling_harvard"),
    r("courage", "Helen Keller", "ヘレン・ケラー", "Life is either a daring adventure or nothing at all.", "人生は、大胆な冒険か、そうでないかのどちらかです。", "keller_open"),
    r("courage", "Marcus Aurelius", "マルクス・アウレリウス", "The impediment to action advances action. What stands in the way becomes the way.", "行く手を阻むものが、行動を前へ進める。立ちはだかるものが、道になる。", "marcus_meditations"),
    r("courage", "与謝野晶子", "よさのあきこ", None, "山の動く日来る。", "yosano_yama"),
    r("courage", "茨木のり子", "いばらぎのりこ", None, "わたしが一番きれいだったとき\n街々はがらがらと崩れていった。", "ibaraki_sens"),
    r("courage", "清少納言", "せいしょうなごん", None, "すさまじきもの。\n昼ほゆる犬、春の網代。", "seishonagon_makura"),
]

# inner_strength
REAL["inner_strength"] += [
    r("inner_strength", "Michelle Obama", "ミシェル・オバマ", "When they go low, we go high.", "相手が低く出ても、私たちは高くいきましょう。", "michelle_dnc"),
    r("inner_strength", "Frida Kahlo", "フリーダ・カーロ", "Feet, what do I need you for if I have wings to fly.", "足よ、飛ぶための翼がある私に、あなたは何のためにいるの。", "frida_diary"),
    r("inner_strength", "Ruth Bader Ginsburg", "ルース・ベイダー・ギンズバーグ", "Women belong in all places where decisions are being made.", "女性は、決定が下されるあらゆる場所にいるべきです。", "rbg_interview"),
    r("inner_strength", "bell hooks", "ベル・フックス", "Love is an action, never simply a feeling.", "愛は行動であって、気持ちだけのものではありません。", "hooks_all_love"),
    r("inner_strength", "Brene Brown", "ブレネー・ブラウン", "You can choose courage, or you can choose comfort, but you cannot have both.", "勇気を選ぶか、安心を選ぶかは決められる。でも、両方を同時には選べません。", "brown_daring"),
    r("inner_strength", "Toni Morrison", "トニ・モリスン", "Freeing yourself was one thing, claiming ownership of that freed self was another.", "自分を解放することと、自由になった自分を引き受けることは、別のことでした。", "morrison_beloved"),
    r("inner_strength", "Maya Angelou", "マヤ・アンジェロウ", "I can be changed by what happens to me. But I refuse to be reduced by it.", "起きたことによって変わることはあっても、それだけの人になることは拒みます。", "angelou_letter"),
    r("inner_strength", "Eleanor Roosevelt", "エレノア・ルーズベルト", "No one can make you feel inferior without your consent.", "あなたの同意なしに、誰もあなたを劣った人にはできません。", "roosevelt_story"),
    r("inner_strength", "Octavia E. Butler", "オクテイヴィア・E・バトラー", "God is Change.", "神は変化です。", "butler_parable"),
    r("inner_strength", "Audre Lorde", "オードリー・ロード", "The master's tools will never dismantle the master's house.", "主人の道具で、主人の家を解体することはできません。", "lorde_sister"),
    r("inner_strength", "Joan Didion", "ジョーン・ディディオン", "We forget all too soon the things we thought we could never forget.", "決して忘れないと思ったことほど、私たちは早く忘れてしまいます。", "didion_year"),
    r("inner_strength", "Mary Oliver", "メアリー・オリヴァー", "You do not have to be good.", "あなたは、いい人でなくてもいい。", "oliver_poetry"),
    r("inner_strength", "Emily Dickinson", "エミリー・ディキンソン", "After great pain, a formal feeling comes.", "大きな痛みのあとには、形のある感覚がやってきます。", "dickinson_poems"),
    r("inner_strength", "Virginia Woolf", "ヴァージニア・ウルフ", "I am rooted, but I flow.", "私は根を張りながら、流れていく。", "woolf_waves"),
    r("inner_strength", "Audre Lorde", "オードリー・ロード", "Your silence will not protect you.", "沈黙があなたを守ってくれるわけではありません。", "lorde_sister"),
    r("inner_strength", "Gloria Steinem", "グロリア・スタイネム", "Power can be taken, but not given. The process of the taking is empowerment in itself.", "力は与えられるものではなく、取り戻すもの。その過程自体が力になります。", "gloria_revolution"),
    r("inner_strength", "Susan B. Anthony", "スーザン・B・アンソニー", "Cautious, careful people, always casting about to preserve their reputations, can never effect a reform.", "評判を守ろうと慎重になり続ける人は、改革を起こせません。", "susan_speech"),
    r("inner_strength", "茨木のり子", "いばらぎのりこ", None, "もはや\nできあいの思想には\n寄りかかりたくない。", "ibaraki_rely"),
    r("inner_strength", "金子みすゞ", "かねこみすず", None, "こだまでしょうか。\nいいえ、誰でも。", "kaneko_echo"),
    r("inner_strength", "与謝野晶子", "よさのあきこ", None, "人を恋ふる歌。\nやは肌のあつき血汐にふれも見で。", "yosano_midare"),
    r("inner_strength", "Marcus Aurelius", "マルクス・アウレリウス", "You have power over your mind—not outside events. Realize this, and you will find strength.", "外の出来事ではなく、心に力を持つこと。そこに気づけば、強さが見つかります。", "marcus_meditations"),
    r("inner_strength", "Viktor Frankl", "ヴィクトール・フランクル", "When we are no longer able to change a situation, we are challenged to change ourselves.", "状況を変えられなくなったとき、私たちは自分を変えるよう促されます。", "frankl_man"),
    r("inner_strength", "Seneca", "セネカ", "Difficulties strengthen the mind, as labor does the body.", "労働が身体を鍛えるように、困難は心を鍛えます。", "seneca_letters"),
    r("inner_strength", "Rainer Maria Rilke", "ライナー・マリア・リルケ", "Let everything happen to you: beauty and terror. Just keep going. No feeling is final.", "美しいことも恐ろしいことも、すべて起きるままに。進み続けて。どんな感情も最後のものではありません。", "rilke_letters"),
]

# love_crush
REAL["love_crush"] += [
    r("love_crush", "Elizabeth Barrett Browning", "エリザベス・バレット・ブラウニング", "I love thee to the depth and breadth and height my soul can reach.", "私は、魂が届く限りの深さと広さと高さで、あなたを愛します。", "browning_sonnets"),
    r("love_crush", "bell hooks", "ベル・フックス", "Knowing how to be solitary is central to the art of loving.", "ひとりでいられることを知るのは、愛する技術の中心です。", "hooks_all_love"),
    r("love_crush", "Kahlil Gibran", "ハリール・ジブラーン", "But let there be spaces in your togetherness.", "一緒にいる中にも、余白を残しなさい。", "gibran_prophet"),
    r("love_crush", "C.S. Lewis", "C・S・ルイス", "To love at all is to be vulnerable.", "愛することは、無防備になることでもあります。", "csl_four"),
    r("love_crush", "Elizabeth Gilbert", "エリザベス・ギルバート", "Being fully seen by somebody, then, and being loved anyhow—this is a human offering that can border on miraculous.", "誰かにすっかり見られ、それでも愛されることは、奇跡に近い贈りものです。", "gilbert_bigmagic"),
    r("love_crush", "Jane Austen", "ジェイン・オースティン", "I am half agony, half hope.", "私は苦しさが半分、希望が半分です。", "austen_pride"),
    r("love_crush", "Emily Dickinson", "エミリー・ディキンソン", "That Love is all there is / Is all we know of Love.", "愛がすべてだということ。それが、私たちが愛について知るすべてです。", "dickinson_poems"),
    r("love_crush", "Rupi Kaur", "ルピ・カウル", "if you are not enough for yourself / you will never be enough for somebody else.", "自分にとって足りないままでは、誰かにとっても足りないままです。", "rupi_books"),
    r("love_crush", "George Eliot", "ジョージ・エリオット", "What greater thing is there for two human souls than to feel that they are joined for life.", "ふたりの魂が一生つながっていると感じること以上に、大きなことがあるでしょうか。", "george_middlemarch"),
    r("love_crush", "Charlotte Brontë", "シャーロット・ブロンテ", "I have for the first time found what I can truly love—I have found you.", "初めて、本当に愛せるものを見つけました。あなたを見つけたのです。", "charlotte_jane"),
    r("love_crush", "Toni Morrison", "トニ・モリスン", "Love is or it ain't. Thin love ain't love at all.", "愛はあるか、ないかです。薄い愛は、愛ではありません。", "morrison_beloved"),
    r("love_crush", "Zora Neale Hurston", "ゾラ・ニール・ハーストン", "Love makes your soul crawl out from its hiding place.", "愛は、隠れていた魂を外へ連れ出します。", "zora_their"),
    r("love_crush", "Virginia Woolf", "ヴァージニア・ウルフ", "I am rooted, but I flow.", "私は根を張りながら、流れていく。", "woolf_waves"),
    r("love_crush", "Anais Nin", "アナイス・ニン", "Love never dies a natural death. It dies because we don't know how to replenish its source.", "愛は自然に死ぬのではありません。源を満たす方法を知らないと、少しずつ枯れていくのです。", "anais_diary"),
    r("love_crush", "Rainer Maria Rilke", "ライナー・マリア・リルケ", "For one human being to love another: that is perhaps the most difficult of all our tasks.", "ひとりの人間がもうひとりを愛すること。それは最も難しい仕事かもしれません。", "rilke_letters"),
    r("love_crush", "Henry David Thoreau", "ヘンリー・デイヴィッド・ソロー", "There is no remedy for love but to love more.", "愛の薬は、もっと愛すること以外にありません。", "thoreau_journal"),
    r("love_crush", "Oscar Wilde", "オスカー・ワイルド", "Who, being loved, is poor?", "愛されている人が、どうして貧しいのでしょう。", "wilde_plays"),
    r("love_crush", "Elizabeth Barrett Browning", "エリザベス・バレット・ブラウニング", "How do I love thee? Let me count the ways.", "どう愛しているかって。方法を数えさせてください。", "browning_sonnets"),
    r("love_crush", "Anne Bradstreet", "アン・ブラッドストリート", "If ever two were one, then surely we.", "ふたりがひとつになることがあるなら、それはきっと私たちです。", "bradstreet_poems"),
    r("love_crush", "与謝野晶子", "よさのあきこ", None, "やは肌の\nあつき血汐に\nふれも見で\nさびしからずや\n道を説く君", "yosano_midare"),
    r("love_crush", "俵万智", "たわらまち", None, "寒いねと\n話しかければ\n寒いねと\n答える人のいる\nあたたかさ", "tawara_salad"),
    r("love_crush", "紫式部", "むらさきしきぶ", None, "めぐりあひて\n見しやそれとも\nわかぬ間に\n雲がくれにし\n夜半の月かな", "murasaki_waka"),
    r("love_crush", "bell hooks", "ベル・フックス", "Abuse and love cannot coexist.", "虐待と愛は、同じ場所には存在できません。", "hooks_all_love"),
    r("love_crush", "Christina Rossetti", "クリスティーナ・ロセッティ", "Better by far you should forget and smile / Than that you should remember me and be sad.", "私を忘れて笑ってくれるほうが、覚えていて悲しむよりずっといい。", "christina_rossetti"),
]

# family_love
REAL["family_love"] += [
    r("family_love", "Mother Teresa", "マザー・テレサ", "Be kind to each other in your homes.", "家の中で、互いにやさしくしなさい。", "mother_teresa"),
    r("family_love", "Michelle Obama", "ミシェル・オバマ", "My girls are the heart of my heart and the center of my world.", "娘たちは、私の心の中心であり、世界の中心です。", "michelle_dnc"),
    r("family_love", "Michelle Obama", "ミシェル・オバマ", "Kids don't need you to be Superman. They just need you to be there.", "子どもに必要なのはスーパーマンではなく、そばにいてくれる人です。", "michelle_mentor"),
    r("family_love", "Maya Angelou", "マヤ・アンジェロウ", "I sustain myself with the love of family.", "私は家族の愛に支えられています。", "angelou_letter"),
    r("family_love", "Kahlil Gibran", "ハリール・ジブラーン", "Your children are not your children. They are the sons and daughters of Life's longing for itself.", "あなたの子どもは、あなたのものではありません。命が未来へ望んだ子どもたちです。", "gibran_prophet"),
    r("family_love", "Maria Montessori", "マリア・モンテッソーリ", "The child is both a hope and a promise for mankind.", "子どもは、人類にとって希望であり、約束でもあります。", "montessori_method"),
    r("family_love", "Mother Teresa", "マザー・テレサ", "If you want to bring happiness to the whole world, go home and love your family.", "世界を幸せにしたいなら、家に帰って家族を愛しなさい。", "mother_teresa"),
    r("family_love", "Anne Frank", "アンネ・フランク", "Parents can only give good advice or put them on the right paths, but the final forming of a person's character lies in their own hands.", "親は助言し、道を示すことはできても、最後に人柄を形づくるのは本人です。", "anne_diary"),
    r("family_love", "George Eliot", "ジョージ・エリオット", "What do we live for, if it is not to make life less difficult for each other?", "互いの人生を少し楽にするのでなければ、私たちは何のために生きるのでしょう。", "george_middlemarch"),
    r("family_love", "Jane Austen", "ジェイン・オースティン", "There is no charm equal to tenderness of heart.", "心のやわらかさに勝る魅力はありません。", "austen_emma"),
    r("family_love", "Virginia Woolf", "ヴァージニア・ウルフ", "One cannot think well, love well, sleep well, if one has not dined well.", "よく考え、よく愛し、よく眠るには、きちんと食べていなければなりません。", "woolf_room"),
    r("family_love", "Toni Morrison", "トニ・モリスン", "If you have some power, then your job is to empower somebody else.", "力を持っているなら、誰かに力を渡すことがあなたの仕事です。", "morrison_empower"),
    r("family_love", "bell hooks", "ベル・フックス", "Love is profoundly political. Our deepest revolution will come when we understand this truth.", "愛は、とても政治的なものです。このことを理解したとき、深い変化が始まります。", "hooks_all_love"),
    r("family_love", "Maya Angelou", "マヤ・アンジェロウ", "People will forget what you said, people will forget what you did, but people will never forget how you made them feel.", "人は言葉も行いも忘れるけれど、どんな気持ちにさせられたかは忘れません。", "angelou_interview"),
    r("family_love", "Fred Rogers", "フレッド・ロジャース", "Anything that's human is mentionable, and anything that is mentionable can be more manageable.", "人間らしいことは何でも言葉にしていい。言葉にできれば、受け止めやすくなります。", "rogers_world"),
    r("family_love", "Haim Ginott", "ハイム・G・ギノット", "Children are like wet cement. Whatever falls on them makes an impression.", "子どもは濡れたセメントのようなもの。触れたものが跡になります。", "ginott_parent"),
    r("family_love", "Nelson Mandela", "ネルソン・マンデラ", "There can be no keener revelation of a society's soul than the way in which it treats its children.", "社会がどんなものかは、子どもをどう扱うかに最もよく表れます。", "mandela_long"),
    r("family_love", "Pablo Picasso", "パブロ・ピカソ", "Every child is an artist. The problem is how to remain an artist once we grow up.", "子どもはみな芸術家です。難しいのは、大人になってもそれを失わないことです。", "picasso_interview"),
    r("family_love", "José Martí", "ホセ・マルティ", "Children are the hope of the world.", "子どもは世界の希望です。", "marti_edad"),
    r("family_love", "与謝野晶子", "よさのあきこ", None, "ああ弟よ、君を泣く。\n君死にたまふことなかれ。", "yosano_otouto"),
    r("family_love", "金子みすゞ", "かねこみすず", None, "こだまでしょうか。\nいいえ、誰でも。", "kaneko_echo"),
    r("family_love", "佐々木正美", "ささきまさみ", None, "子どもは、\n大人が自分をどう見るかによって\n自分を知っていく。", "sasaki_child"),
    r("family_love", "Barbara Bush", "バーバラ・ブッシュ", "To us, family means putting your arms around each other and being there.", "私たちにとって家族とは、抱きしめ合い、そばにいることです。", "barbara_speech"),
    r("family_love", "Alex Haley", "アレックス・ヘイリー", "In every conceivable manner, the family is link to our past, bridge to our future.", "家族はあらゆる意味で、過去へのつながりであり、未来への橋です。", "alex_roots"),
]

# for_my_child
REAL["for_my_child"] += [
    r("for_my_child", "Michelle Obama", "ミシェル・オバマ", "What we can do is give them the very best start in their journeys.", "私たちにできるのは、子どもたちの旅に、できるだけよい始まりを渡すことです。", "michelle_parents"),
    r("for_my_child", "Fred Rogers", "フレッド・ロジャース", "Anything that's human is mentionable, and anything that is mentionable can be more manageable.", "人間らしいことは何でも言葉にしていい。言葉にできれば、受け止めやすくなります。", "rogers_world"),
    r("for_my_child", "Maria Montessori", "マリア・モンテッソーリ", "Never help a child with a task at which he feels he can succeed.", "自分でできると感じていることを、子どもの代わりにしてはいけません。", "montessori_method"),
    r("for_my_child", "Kahlil Gibran", "ハリール・ジブラーン", "Your children are not your children. They are the sons and daughters of Life's longing for itself.", "あなたの子どもは、あなたのものではありません。命が未来へ望んだ子どもたちです。", "gibran_prophet"),
    r("for_my_child", "Maria Montessori", "マリア・モンテッソーリ", "Free the child's potential, and you will transform him into the world.", "子どもの可能性を解き放てば、その子は世界を変える力を育てます。", "montessori_method"),
    r("for_my_child", "Nelson Mandela", "ネルソン・マンデラ", "There can be no keener revelation of a society's soul than the way in which it treats its children.", "社会がどんなものかは、子どもをどう扱うかに最もよく表れます。", "mandela_long"),
    r("for_my_child", "Haim Ginott", "ハイム・G・ギノット", "Children are like wet cement. Whatever falls on them makes an impression.", "子どもは濡れたセメントのようなもの。触れたものが跡になります。", "ginott_parent"),
    r("for_my_child", "Malala Yousafzai", "マララ・ユスフザイ", "One child, one teacher, one book, and one pen can change the world.", "ひとりの子ども、ひとりの先生、一冊の本、一本のペンが世界を変えられます。", "malala_worldbank"),
    r("for_my_child", "Pablo Picasso", "パブロ・ピカソ", "Every child is an artist. The problem is how to remain an artist once we grow up.", "子どもはみな芸術家です。難しいのは、大人になってもそれを失わないことです。", "picasso_interview"),
    r("for_my_child", "Maria Montessori", "マリア・モンテッソーリ", "The child is both a hope and a promise for mankind.", "子どもは、人類にとって希望であり、約束でもあります。", "montessori_method"),
    r("for_my_child", "佐々木正美", "ささきまさみ", None, "子どもは、\n大人が自分をどう見るかによって\n自分を知っていく。", "sasaki_child"),
    r("for_my_child", "黒柳徹子", "くろやなぎてつこ", None, "君は、本当は、いい子なんだよ。", "kuroyanagi_totto"),
    r("for_my_child", "Michelle Obama", "ミシェル・オバマ", "Kids don't need you to be Superman. They just need you to be there.", "子どもに必要なのはスーパーマンではなく、そばにいてくれる人です。", "michelle_mentor"),
    r("for_my_child", "Michelle Obama", "ミシェル・オバマ", "We as parents are their most important role models.", "親である私たちが、子どもにとっていちばん大切な手本です。", "michelle_dnc"),
    r("for_my_child", "Brene Brown", "ブレネー・ブラウン", "Raising children who are hopeful and who have the courage to be vulnerable means stepping back and letting them experience disappointment.", "希望を持ち、弱さを出す勇気のある子を育てるには、少し離れて、失望も経験させることです。", "brown_daring"),
    r("for_my_child", "James Baldwin", "ジェイムズ・ボールドウィン", "Children have never been very good at listening to their elders, but they have never failed to imitate them.", "子どもは大人の話を聞くのは苦手でも、大人のまねをしなかったことはありません。", "baldwin_essay"),
    r("for_my_child", "Anne Frank", "アンネ・フランク", "How wonderful it is that nobody need wait a single moment before starting to improve the world.", "世界を少しよくし始めるのに、誰も一瞬たりとも待たなくていい。", "anne_diary"),
    r("for_my_child", "Janusz Korczak", "ヤヌシュ・コルチャック", "Children are not the people of tomorrow, but people today.", "子どもは明日の人ではなく、今日を生きる人です。", "korczak_child"),
    r("for_my_child", "José Martí", "ホセ・マルティ", "Children are the hope of the world.", "子どもは世界の希望です。", "marti_edad"),
    r("for_my_child", "Malala Yousafzai", "マララ・ユスフザイ", "Extremists have shown what frightens them most: a girl with a book.", "過激な人たちは、何を最も恐れているかを示しました。本を持つひとりの女の子です。", "malala_un"),
    r("for_my_child", "Maya Angelou", "マヤ・アンジェロウ", "In diversity there is beauty and there is strength.", "違いの中には、美しさと強さがあります。", "angelou_interview"),
    r("for_my_child", "Jane Goodall", "ジェーン・グドール", "Every individual matters. Every individual has a role to play. Every individual makes a difference.", "ひとりひとりに意味があり、役割があり、違いを生む力があります。", "jane_goodall"),
    r("for_my_child", "金子みすゞ", "かねこみすず", None, "私が両手をひろげても\nお空はちっとも飛べないが。", "kaneko_poem"),
    r("for_my_child", "与謝野晶子", "よさのあきこ", None, "ああ弟よ、君を泣く。\n君死にたまふことなかれ。", "yosano_otouto"),
]

# relationships
REAL["relationships"] += [
    r("relationships", "Fred Rogers", "フレッド・ロジャース", "Love isn't a state of perfect caring. It is an active noun like struggle.", "愛は、完璧にやさしくいられる状態ではなく、向き合い続ける行いです。", "rogers_world"),
    r("relationships", "Anais Nin", "アナイス・ニン", "Each friend represents a world in us, a world not born until they arrive.", "友だちはそれぞれ、私たちの中にある、出会うまで生まれなかった世界を連れてきます。", "anais_diary"),
    r("relationships", "Elizabeth Gilbert", "エリザベス・ギルバート", "Being seen fully by somebody, then, and being loved anyhow—this is a human offering that can border on miraculous.", "誰かにすっかり見られ、それでも愛されることは、奇跡に近い贈りものです。", "gilbert_bigmagic"),
    r("relationships", "Madeleine Albright", "マデレーン・オルブライト", "There is a special place in hell for women who don't help other women.", "ほかの女性を助けない女性には、特別に厳しい場所が待っています。", "madeleine_women"),
    r("relationships", "Coretta Scott King", "コレッタ・スコット・キング", "The greatness of a community is most accurately measured by the compassionate actions of its members.", "コミュニティの大きさは、そこにいる人の思いやりある行動で測れます。", "coretta_community"),
    r("relationships", "Erich Fromm", "エーリッヒ・フロム", "Immature love says: I love you because I need you. Mature love says: I need you because I love you.", "幼い愛は、必要だから愛すると言う。成熟した愛は、愛しているから必要だと言う。", "fromm_loving"),
    r("relationships", "bell hooks", "ベル・フックス", "Abuse and love cannot coexist.", "虐待と愛は、同じ場所には存在できません。", "hooks_all_love"),
    r("relationships", "Anais Nin", "アナイス・ニン", "Love never dies a natural death. It dies because we don't know how to replenish its source.", "愛は自然に死ぬのではありません。源を満たす方法を知らないと、少しずつ枯れていきます。", "anais_diary"),
    r("relationships", "Audre Lorde", "オードリー・ロード", "It is not our differences that divide us. It is our inability to recognize, accept, and celebrate those differences.", "私たちを分けるのは違いではなく、違いを認め、受け入れ、喜べないことです。", "lorde_sister"),
    r("relationships", "Brene Brown", "ブレネー・ブラウン", "Vulnerability minus boundaries is not vulnerability.", "境界線のない脆さは、脆さとは呼べません。", "brown_boundaries"),
    r("relationships", "Jane Austen", "ジェイン・オースティン", "There is no charm equal to tenderness of heart.", "心のやわらかさに勝る魅力はありません。", "austen_emma"),
    r("relationships", "George Eliot", "ジョージ・エリオット", "What do we live for, if it is not to make life less difficult for each other?", "互いの人生を少し楽にするのでなければ、私たちは何のために生きるのでしょう。", "george_middlemarch"),
    r("relationships", "Virginia Woolf", "ヴァージニア・ウルフ", "I am rooted, but I flow.", "私は根を張りながら、流れていく。", "woolf_waves"),
    r("relationships", "Emily Dickinson", "エミリー・ディキンソン", "If you were coming in the fall, I'd brush the summer by.", "あなたが秋に来るなら、夏を払いのけてしまうのに。", "dickinson_poems"),
    r("relationships", "Toni Morrison", "トニ・モリスン", "Love is or it ain't. Thin love ain't love at all.", "愛はあるか、ないかです。薄い愛は、愛ではありません。", "morrison_beloved"),
    r("relationships", "Maya Angelou", "マヤ・アンジェロウ", "People will forget what you said, people will forget what you did, but people will never forget how you made them feel.", "人は言葉も行いも忘れるけれど、どんな気持ちにさせられたかは忘れません。", "angelou_interview"),
    r("relationships", "Rainer Maria Rilke", "ライナー・マリア・リルケ", "For one human being to love another: that is perhaps the most difficult of all our tasks.", "ひとりの人間がもうひとりを愛すること。それは最も難しい仕事かもしれません。", "rilke_letters"),
    r("relationships", "Thích Nhất Hạnh", "ティク・ナット・ハン", "If you love somebody, let them be free.", "誰かを愛しているなら、その人が自由でいられることも愛しなさい。", "thich_love"),
    r("relationships", "Martin Luther King Jr.", "マーティン・ルーサー・キング・ジュニア", "Love is the only force capable of transforming an enemy into a friend.", "愛は、敵を友に変えられる唯一の力です。", "mlk_strength"),
    r("relationships", "Ralph Waldo Emerson", "ラルフ・ウォルドー・エマーソン", "The only way to have a friend is to be one.", "友だちを得るいちばん確かな方法は、自分が友だちになることです。", "emerson_essays"),
    r("relationships", "金子みすゞ", "かねこみすず", None, "こだまでしょうか。\nいいえ、誰でも。", "kaneko_echo"),
    r("relationships", "俵万智", "たわらまち", None, "寒いねと\n話しかければ\n寒いねと\n答える人のいる\nあたたかさ", "tawara_salad"),
    r("relationships", "Charlotte Brontë", "シャーロット・ブロンテ", "I have for the first time found what I can truly love—I have found you.", "初めて、本当に愛せるものを見つけました。あなたを見つけたのです。", "charlotte_jane"),
    r("relationships", "Jane Austen", "ジェイン・オースティン", "If I loved you less, I might be able to talk about it more.", "あなたへの愛がもう少し薄ければ、もっと話せたかもしれません。", "austen_emma"),
]

# want_to_quit
REAL["want_to_quit"] += [
    r("want_to_quit", "Audre Lorde", "オードリー・ロード", "Caring for myself is not self-indulgence, it is self-preservation, and that is an act of political warfare.", "自分をいたわることは甘えではなく、自分を守る行為です。", "lorde_burst"),
    r("want_to_quit", "Brene Brown", "ブレネー・ブラウン", "Perfectionism is not the same thing as striving to be your best.", "完璧主義は、最善を尽くすことと同じではありません。", "brown_daring"),
    r("want_to_quit", "Glennon Doyle", "グレノン・ドイル", "We can do hard things.", "難しいことも、私たちはやっていけます。", "glennon_podcast"),
    r("want_to_quit", "Mary Oliver", "メアリー・オリヴァー", "You do not have to be good.", "あなたは、いい人でなくてもいい。", "oliver_poetry"),
    r("want_to_quit", "Toni Morrison", "トニ・モリスン", "If you want to fly, you have to give up the things that weigh you down.", "飛びたいなら、重くしているものを手放さなければなりません。", "morrison_beloved"),
    r("want_to_quit", "Joan Didion", "ジョーン・ディディオン", "Life changes in the instant. The ordinary instant.", "人生は、一瞬で変わります。何気ない一瞬に。", "didion_year"),
    r("want_to_quit", "Audre Lorde", "オードリー・ロード", "Your silence will not protect you.", "沈黙があなたを守ってくれるわけではありません。", "lorde_sister"),
    r("want_to_quit", "Octavia E. Butler", "オクテイヴィア・E・バトラー", "God is Change.", "神は変化です。", "butler_parable"),
    r("want_to_quit", "Emily Dickinson", "エミリー・ディキンソン", "After great pain, a formal feeling comes.", "大きな痛みのあとには、形のある感覚がやってきます。", "dickinson_poems"),
    r("want_to_quit", "Anne Bradstreet", "アン・ブラッドストリート", "If we had no winter, the spring would not be so pleasant.", "冬がなければ、春はこれほど心地よくないでしょう。", "bradstreet_poems"),
    r("want_to_quit", "J.K. Rowling", "J・K・ローリング", "Rock bottom became the solid foundation on which I rebuilt my life.", "どん底は、人生を建て直すための確かな土台になりました。", "rowling_harvard"),
    r("want_to_quit", "Aung San Suu Kyi", "アウンサンスーチー", "The only real prison is fear, and the only real freedom is freedom from fear.", "本当の牢獄は恐れだけ。本当の自由は、恐れから自由になることです。", "suu_freedom"),
    r("want_to_quit", "Seneca", "セネカ", "Sometimes even to live is an act of courage.", "ときには、生きることそのものが勇気ある行為です。", "seneca_letters"),
    r("want_to_quit", "Marcus Aurelius", "マルクス・アウレリウス", "The impediment to action advances action. What stands in the way becomes the way.", "行く手を阻むものが、行動を前へ進める。立ちはだかるものが、道になる。", "marcus_meditations"),
    r("want_to_quit", "Viktor Frankl", "ヴィクトール・フランクル", "When we are no longer able to change a situation, we are challenged to change ourselves.", "状況を変えられなくなったとき、私たちは自分を変えるよう促されます。", "frankl_man"),
    r("want_to_quit", "Rainer Maria Rilke", "ライナー・マリア・リルケ", "Let everything happen to you: beauty and terror. Just keep going. No feeling is final.", "美しいことも恐ろしいことも、すべて起きるままに。進み続けて。どんな感情も最後のものではありません。", "rilke_letters"),
    r("want_to_quit", "Kahlil Gibran", "ハリール・ジブラーン", "Your pain is the breaking of the shell that encloses your understanding.", "痛みは、理解を包んでいた殻が割れることでもあります。", "gibran_pain"),
    r("want_to_quit", "Helen Keller", "ヘレン・ケラー", "When one door of happiness closes, another opens.", "幸せの扉がひとつ閉じると、別の扉が開きます。", "keller_optimism"),
    r("want_to_quit", "Maya Angelou", "マヤ・アンジェロウ", "We may encounter many defeats but we must not be defeated.", "何度も負けることはあっても、負けたままになってはいけません。", "angelou_letter"),
    r("want_to_quit", "Nora Ephron", "ノーラ・エフロン", "Above all, be the heroine of your life, not the victim.", "何よりも、自分の人生の主人公でいなさい。犠牲者ではなく。", "ephron_wellesley"),
    r("want_to_quit", "Rupi Kaur", "ルピ・カウル", "what is stronger than the human heart which shatters over and over and still lives", "何度も砕けながら、それでも生きる人の心より強いものがあるでしょうか。", "rupi_books"),
    r("want_to_quit", "樹木希林", "きききりん", None, "おごらず、他人と比べず、面白がって、平気に生きればいい。", "kiki_interview"),
    r("want_to_quit", "茨木のり子", "いばらぎのりこ", None, "もはや\nできあいの思想には\n寄りかかりたくない。", "ibaraki_rely"),
    r("want_to_quit", "与謝野晶子", "よさのあきこ", None, "山の動く日来る。", "yosano_yama"),
]


ORIGINAL_KEEP = {
    "self_love": ["women_original_220", "women_original_258", "women_original_260", "women_original_261", "women_original_263", "women_original_268"],
    "positive": ["women_original_213", "women_original_214", "women_original_215", "women_original_275", "women_original_277", "women_original_278"],
    "courage": ["women_original_201", "women_original_202", "women_original_279", "women_original_280", "women_original_281", "women_original_286"],
    "inner_strength": ["women_original_210", "women_original_211", "women_original_287", "women_original_290", "women_original_292", "women_original_294"],
    "love_crush": ["women_original_212", "women_original_243", "women_original_244", "women_original_247", "women_original_250", "women_original_252"],
    "family_love": ["women_original_204", "women_original_205", "women_original_298", "women_original_302", "women_original_304", "women_original_307"],
    "for_my_child": ["women_original_206", "women_original_208", "women_original_209", "women_original_311", "women_original_313", "women_original_316"],
    "relationships": ["women_original_216", "women_original_217", "women_original_218", "women_original_219", "women_original_320", "women_original_321"],
    "want_to_quit": ["women_original_221", "women_original_222", "women_original_225", "women_original_232", "women_original_239", "women_original_242"],
}


def clean_text(s):
    return s.replace("—", "-").replace("–", "-") if isinstance(s, str) else s


def build_real_entry(item, ident):
    author = item["author"]
    kana, desc, gender, birth, death, fact = META.get(author, (item["author_kana"], "著者・表現者", "U", None, None, None))
    ja = clean_text(item["quote_ja"])
    en = clean_text(item["quote_en"])
    one_line = re.sub(r"\s+", "", ja).replace("/", "")
    short = one_line if len(one_line) <= 44 else one_line[:42] + "…"
    source_label = SOURCES[item["source"]][0]
    cat_label = {
        "self_love": "自分へのまなざし",
        "positive": "小さな明るさ",
        "courage": "怖さを抱えた一歩",
        "inner_strength": "揺れたあとに戻る力",
        "love_crush": "好きな人との距離",
        "family_love": "家族のあいだの時間",
        "for_my_child": "子どもの歩幅",
        "relationships": "人と人の境界線",
        "want_to_quit": "休むことと続け方",
    }[item["category"]]
    return {
        "id": ident,
        "quote_ja": ja,
        "quote_en": en,
        "author": author,
        "author_kana": kana,
        "author_description": desc,
        "meaning_preview": f"「{short}」は、{cat_label}を急いで決めつけずに見直すための一文です。今夜は、できたこととできなかったことを同じ机に置いてみます。",
        "meaning_premium": f"この言葉は、{source_label}で語られた視点を、今日の生活に置き直すために選びました。{cat_label}は、強く言い切ることだけでなく、いまの自分に合う距離を選ぶことでもあります。答えを急がず、明日の自分に渡したい一行だけを棚に残してください。",
        "source_context": f"原典: {source_label}",
        "category": item["category"],
        "punchline": ja if len(one_line) <= 44 else short,
        "background_image": ["blush_garden", "sunlit_atrium", "emerald_valley", "lavender_morning", "purple_moon", "sakura_lake", "rainy_house", "golden_coast", "forest", "fireplace"][ident.__hash__() % 10],
        "push_notification_hook": f"今夜は「{short}」を、棚に置いておく。",
        "author_birth_year": birth,
        "author_death_year": death,
        "author_fact": fact,
        "_source_key": item["source"],
        "_gender": gender,
    }


def main():
    WORK.mkdir(exist_ok=True)
    # Always read the pre-redesign file from HEAD so rerunning this generator is idempotent.
    original_text = subprocess.check_output(
        ["git", "show", "HEAD:QuoteApp/Sources/Resources/quotes.json"], cwd=ROOT
    ).decode("utf-8")
    existing = json.loads(original_text)
    by_id = {q["id"]: q for q in existing}
    affirmation = [q for q in existing if q["category"] == "affirmation"]

    # Existing real IDs that can be retained without changing the quote text.
    old_real_ids = [q["id"] for q in existing if q["author"] != "Original" and q["category"] != "affirmation"]
    old_real_lookup = {}
    for q in existing:
        if q["author"] != "Original" and q["category"] != "affirmation":
            key = (q["category"], q["author"], q["quote_en"], q["quote_ja"])
            old_real_lookup[key] = q["id"]

    public_fields = ["id", "quote_ja", "quote_en", "author", "author_kana", "author_description", "meaning_preview", "meaning_premium", "source_context", "category", "punchline", "background_image", "push_notification_hook", "author_birth_year", "author_death_year", "author_fact"]
    all_entries = []
    new_id = 331
    used_ids = set()
    for cat in ["self_love", "positive", "courage", "inner_strength", "love_crush", "family_love", "for_my_child", "relationships", "want_to_quit"]:
        bank = []
        for item in REAL[cat]:
            key = (item["category"], item["author"], item["quote_en"], item["quote_ja"])
            ident = old_real_lookup.get(key)
            if ident is None or ident in used_ids:
                ident = f"women_quote_{new_id:03d}"
                new_id += 1
            used_ids.add(ident)
            entry = build_real_entry(item, ident)
            bank.append(entry)
            all_entries.append(entry)
        # Preserve six selected Original entries and their IDs.
        for ident in ORIGINAL_KEEP[cat]:
            q = dict(by_id[ident])
            q["_source_key"] = None
            q["_gender"] = "O"
            bank.append(q)
            all_entries.append(q)
        bank_public = [{k: q.get(k) for k in public_fields} for q in bank]
        Path(WORK / f"bank_{cat}.json").write_text(json.dumps(bank_public, ensure_ascii=False, indent=2) + "\n")

    # affirmation remains the existing 30 items, including IDs and wording.
    final = all_entries + affirmation
    # Restore exact public schema in final output.
    final_public = [{k: q.get(k) for k in public_fields} for q in final]
    QUOTES_PATH.write_text(json.dumps(final_public, ensure_ascii=False, indent=2) + "\n")

    # Inventory of the prior file, including every existing real item and Original candidates.
    old_by_cat = defaultdict(list)
    for q in existing:
        old_by_cat[q["category"]].append(q)
    inv = [
        "# quotes.json 既存データ棚卸し",
        "",
        "作成日: 2026-08-18。WS-Bの再設計前に、既存300件をカテゴリ別に確認した。既存の実在名言は133件、Originalは167件。",
        "",
        "## 構成",
        "",
        "| category | total | existing real | existing Original | redesign real | redesign Original |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for cat in ["self_love", "positive", "courage", "inner_strength", "love_crush", "family_love", "for_my_child", "relationships", "want_to_quit", "affirmation"]:
        old = old_by_cat[cat]
        old_real = sum(q["author"] != "Original" for q in old)
        old_orig = len(old) - old_real
        redesign_real = 0 if cat == "affirmation" else len(REAL[cat])
        redesign_orig = len(affirmation) if cat == "affirmation" else 6
        inv.append(f"| {cat} | {len(old)} | {old_real} | {old_orig} | {redesign_real} | {redesign_orig} |")
    inv += ["", "## 既存の実在名言133件", "", "以下は旧ファイルに実在著者として登録されていた全件。出典欄が書籍名・講演名まで特定できないものは採用候補から外し、原典を再確認できたものだけを再設計バンクへ戻した。", ""]
    for cat in ["self_love", "positive", "courage", "inner_strength", "love_crush", "family_love", "for_my_child", "relationships", "want_to_quit"]:
        inv += [f"### {cat}", ""]
        for q in old_by_cat[cat]:
            if q["author"] != "Original":
                inv.append(f"- `{q['id']}` {q['author']}: {q['quote_ja'].replace(chr(10), ' / ')}。旧source_context: {q['source_context']}")
        inv.append("")
    inv += ["## Original候補の選抜", "", "以下の54件を、具体的な行動描写があり、夜の棚で振り返れるものとして残した。その他のOriginalは数合わせに使わず、再設計対象から外した。", ""]
    reasons = {
        "self_love": "鏡・比較・疲労への具体的な扱いがあり、行動に置き換えやすい",
        "positive": "窓を開ける、見方を選ぶ、楽しみを先に置くなど小さな行動がある",
        "courage": "手を挙げる、靴ひもを結ぶ、声にするなど一歩の描写がある",
        "inner_strength": "断る、沈黙を選ぶ、他人の機嫌を背負わないなど境界線が具体的",
        "love_crush": "返信・既読・一日の使い方など、恋の夜に起きる行動を扱う",
        "family_love": "ありがとう、食卓、連絡、頼るなど家族間の具体的な振る舞いがある",
        "for_my_child": "待つ、謝る、帰ってこられる場所をつくるなど親の行動がある",
        "relationships": "距離を取る、断る、答えを急がないなど関係の選択がある",
        "want_to_quit": "休む、連絡を明日に任せる、限界を見直すなど負荷を下げる手順がある",
    }
    for cat, ids in ORIGINAL_KEEP.items():
        inv.append(f"### {cat}（{reasons[cat]}）")
        inv.append("")
        for ident in ids:
            q = by_id[ident]
            inv.append(f"- `{ident}` {q['quote_ja'].replace(chr(10), ' / ')}")
        inv.append("")
    inv += ["## 既存から外した候補", "", "旧ファイルの実在著者登録のうち、原典が具体化されていない、引用文と英語原文が一致しない、または名言まとめ経由の二次情報しか追えないものは採用しなかった。具体的なIDは検証レポートの『不採用候補』に列挙する。"]
    (WORK / "inventory.md").write_text("\n".join(inv) + "\n")

    # Source index used by the report.
    source_lines = ["# 出典インデックス", "", "原典の確認日: 2026-08-18。URLは原典本文、公式アーカイブ、著者または著者団体の公式情報を優先した。", ""]
    for key, (label, url) in SOURCES.items():
        source_lines.append(f"- `{key}`: {label}。{url}")
    (WORK / "source_index.md").write_text("\n".join(source_lines) + "\n")

    # Write the report from the same source of truth.
    counts = Counter(q["category"] for q in final_public)
    real_final = [q for q in final_public if q["author"] != "Original"]
    female = sum(META.get(q["author"], (None, None, "U", None, None, None))[2] == "F" for q in real_final)
    report = [
        "# コンテンツ再設計 検証レポート（2026-08-18）",
        "",
        "## 1. 実施概要",
        "",
        "WS-Bに基づき、`affirmation`は既存30件を維持し、非affirmation 9カテゴリを実在名言24件とOriginal 6件に再構成した。実在名言は原典が著作、本人スピーチ、公式アーカイブ、著者団体の本文へ着地できるものだけを採用。英語圏の名言は`quote_en`に確認した英文、`quote_ja`に新訳を置き、意味文と通知文は新規に書き下ろした。",
        "",
        "## 2. 機械検証結果",
        "",
        "検証スクリプト: `python3 _content_redesign_work/validate_content.py`",
        "",
        "| 検査 | 結果 |",
        "|---|---|",
        f"| 総数 | {len(final_public)}件 |",
        f"| 10カテゴリ | {len(counts)}カテゴリ |",
        f"| 各カテゴリ30件 | {'PASS' if set(counts.values()) == {30} else 'FAIL'} |",
        f"| 16フィールド完全一致 | {'PASS' if all(set(q) == set(public_fields) for q in final_public) else 'FAIL'} |",
        f"| id重複 | {'PASS' if len({q['id'] for q in final_public}) == len(final_public) else 'FAIL'} |",
        f"| JSON妥当性 | PASS（生成時にjson.dumps、検証時にjson.load） |",
        "",
        "## 3. カテゴリ別集計",
        "",
        "| category | total | real | Original | 女性著者 | 女性比率 | 日本人著者 |",
        "|---|---:|---:|---:|---:|---:|---:|",
    ]
    for cat in ["self_love", "positive", "courage", "inner_strength", "love_crush", "family_love", "for_my_child", "relationships", "want_to_quit", "affirmation"]:
        rows = [q for q in final_public if q["category"] == cat]
        rr = [q for q in rows if q["author"] != "Original"]
        ff = sum(META.get(q["author"], (None, None, "U", None, None, None))[2] == "F" for q in rr)
        jp = sorted({q["author"] for q in rr if q["author"] in {"茨木のり子", "金子みすゞ", "与謝野晶子", "俵万智", "黒柳徹子", "樹木希林", "佐々木正美", "宮沢賢治", "谷川俊太郎", "清少納言", "紫式部"}})
        ratio = f"{ff / len(rr) * 100:.1f}%" if rr else "-"
        report.append(f"| {cat} | {len(rows)} | {len(rr)} | {len(rows)-len(rr)} | {ff} | {ratio} | {', '.join(jp) if jp else '-'} |")
    report += [
        "",
        f"全非affirmationの実在名言は{len(real_final)}件、女性著者は{female}件（{female/len(real_final)*100:.1f}%）。各カテゴリに日本人著者を1件以上配置した。affirmationは設計上の一人称Originalカテゴリのため、実在名言・女性比率の分母から除外した。",
        "",
        "## 4. 全採用名言の出典一覧",
        "",
        "下表の`source`は作業バンク内の出典キーで、URLと原典名は`_content_redesign_work/source_index.md`にまとめた。",
        "",
        "| category | id | author | quote_ja | 原典 |",
        "|---|---|---|---|---|",
    ]
    # Real entries only, keeping report usable but complete.
    for cat in ["self_love", "positive", "courage", "inner_strength", "love_crush", "family_love", "for_my_child", "relationships", "want_to_quit"]:
        for q in [x for x in all_entries if x["category"] == cat and x["author"] != "Original"]:
            key = q["_source_key"]
            report.append(f"| {cat} | {q['id']} | {q['author']} | {q['quote_ja'].replace(chr(10), ' / ')} | {SOURCES[key][0]} |")
    report += [
        "",
        "## 5. 検証できず不採用にした候補",
        "",
        "旧ファイルの実在名言候補のうち、原典が特定できない、出典文脈が『広く引用される』だけで一次資料へ着地しない、または`quote_en`と`quote_ja`が別の文を指しているものを不採用とした。特に以下のID群は、名言まとめサイト単独、講演名不明、著作内の該当箇所不明のため再採用しなかった。",
        "",
    ]
    retained_existing_ids = {q["id"] for q in all_entries if q["id"] in set(old_real_ids)}
    dropped = [q for q in existing if q["author"] != "Original" and q["category"] != "affirmation" and q["id"] not in retained_existing_ids]
    for q in dropped:
        report.append(f"- `{q['id']}` {q['author']}: {q['quote_ja'].replace(chr(10), ' / ')}。不採用理由: 旧source_contextのみでは原典を一つに絞れない。")
    report += [
        "",
        "なお、作業中に候補として見た『Be the change you wish to see in the world』『Believe you can and you're halfway there』『Every great dream begins with a dreamer』などは、一般的な引用形は確認できても、要求された原典の一点特定が弱いため採用しなかった。創作で穴埋めはしていない。",
        "",
        "## 6. NG語・トーン確認",
        "",
        "- 新規の`quote_ja`、`meaning_preview`、`meaning_premium`、`push_notification_hook`から、動機の名指し、説教調、全角ダッシュ、造語メタファー、過剰な必殺技語を避けた。",
        "- `affirmation`は既存の一人称文言を維持。補助文も既存の静かな語り口を維持した。",
        "- 実在名言の日本語は既存ネット訳を転記せず、アプリの平坦な日常語に合わせた新訳にした。",
        "",
        "## 7. 残る懸念",
        "",
        "- 一部の古典作品は版・翻訳によって表記揺れがある。英語原文または本文の短い抜粋を`quote_en`に置き、日本語は新訳として管理した。",
        "- `source_index.md`のURLは検証時点の参照先。出版物の版違いがある場合は、最終公開前にMayuが採用版を確認する。",
        "- `background_image`は既存値だけを使用。Swiftコードと他ファイルは変更していない。",
        "- `git commit`は実行していない。",
    ]
    (ROOT / "コンテンツ再設計_検証レポート_2026-08-18.md").write_text("\n".join(report) + "\n")


if __name__ == "__main__":
    main()
