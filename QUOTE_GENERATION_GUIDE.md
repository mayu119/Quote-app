# 名言データ生成ガイド 📝

## 目標：200件の名言データ作成

現在10件 → **目標200件**（各カテゴリ40件ずつ）

---

## 🎯 ターゲット理解

**20-35歳の「変えたいけど行動できてない」男性**
- Alpha / Sigma Male 文化に共感
- 筋トレ・自己啓発・ビジネスに興味はあるが「始めてない」or「続いてない」
- 朝なんとなくスマホを開いてしまう
- 「今日こそやろう」と思うが結局やらない

**刺さる名言の特徴**:
- 短く、力強い
- 行動を促す（思考より行動）
- 男性的な表現（「お前」「俺」）
- ストイックさを称賛

---

## 📚 カテゴリ別の名言ソース

### 💪 自己鍛錬（self_discipline）- 40件

**テーマ**: 継続、忍耐、ストイックさ、身体と精神の鍛錬

**おすすめ人物**:
- David Goggins（元Navy SEAL、超人的な持久力）
- Jocko Willink（元Navy SEAL、Discipline Equalsフリーダム）
- Arnold Schwarzenegger（ボディビルダー）
- Kobe Bryant（マンバメンタリティ）
- Bruce Lee（武道哲学）
- Miyamoto Musashi（五輪書）

**名言例**:
```json
{
  "quote_ja": "苦しくなったら、\nそこからが本当のスタートだ。",
  "author": "David Goggins",
  "category": "self_discipline",
  "punchline": "苦しくなったら、そこからが本当のスタートだ。",
  "background_image": "bg_gym_03",
  "push_notification_hook": "これ読んでからジム行く気になった。マジで。"
}
```

---

### 🔥 覚醒・行動（awakening）- 40件

**テーマ**: すぐに行動、先延ばしをやめる、言い訳をしない

**おすすめ人物**:
- Nike（Just Do It）
- Gary Vaynerchuk（行動>思考）
- Andrew Tate（controversial だが行動派）
- Unknown（日本の諺など）
- Sun Tzu（孫子）

**名言例**:
```json
{
  "quote_ja": "言い訳を探す時間があるなら、\n解決策を探せ。",
  "author": "Gary Vaynerchuk",
  "category": "awakening",
  "punchline": "言い訳を探すな、解決策を探せ。",
  "background_image": "bg_fire_03",
  "push_notification_hook": "今すぐ読んだ方がいい。マジで後悔する前に。"
}
```

---

### 🧠 マインドセット（mindset）- 40件

**テーマ**: 失敗の捉え方、成長思考、ポジティブ思考、信念

**おすすめ人物**:
- Steve Jobs（Think Different）
- Elon Musk（不可能を可能に）
- Michael Jordan（失敗から学ぶ）
- Marcus Aurelius（ストア哲学）
- Seneca（ストア哲学）
- Naval Ravikant（現代の哲学者）
- Jordan Peterson（心理学・人生のルール）

**名言例**:
```json
{
  "quote_ja": "お前の限界は、\nお前の頭の中にしか存在しない。",
  "author": "Naval Ravikant",
  "category": "mindset",
  "punchline": "お前の限界は、頭の中にしかない。",
  "background_image": "bg_mountain_03",
  "push_notification_hook": "この名言、お前の人生変えるかもしれない。"
}
```

---

### ⚔️ 戦い・勝負（battle）- 40件

**テーマ**: 競争、勝利、ライバルを倒す、頂点を目指す

**おすすめ人物**:
- Muhammad Ali（チャンピオンマインド）
- Conor McGregor（UFC、自信と勝利）
- Mike Tyson（フィアレス）
- Alexander the Great（征服者）
- Napoleon Bonaparte（戦略家）
- Miyamoto Musashi（剣豪）

**名言例**:
```json
{
  "quote_ja": "チャンピオンは\nリングの中で作られるのではない。\nリングの外で作られる。",
  "author": "Muhammad Ali",
  "category": "battle",
  "punchline": "チャンピオンはリングの外で作られる。",
  "background_image": "bg_fight_03",
  "push_notification_hook": "勝者と敗者の差、今日の名言で分かる。"
}
```

---

### 🌅 朝・習慣（morning）- 40件

**テーマ**: 早起き、朝のルーティン、習慣の力、1日の始まり

**おすすめ人物**:
- Hal Elrod（The Miracle Morning）
- Robin Sharma（5AM Club）
- Tim Ferriss（モーニングルーティン）
- Benjamin Franklin（早起きの価値）
- 日本の諺（早起きは三文の徳）

**名言例**:
```json
{
  "quote_ja": "朝の30分が、\nお前の人生を変える。",
  "author": "Robin Sharma",
  "category": "morning",
  "punchline": "朝の30分が、人生を変える。",
  "background_image": "bg_sunrise_03",
  "push_notification_hook": "朝イチでこれ読んだら、今日は勝てる。"
}
```

---

## 🤖 AIツールでの生成方法

### 方法1: ChatGPT / Claude等を使う

**プロンプト例**:
```
以下の条件で、名言データを40件作成してください。

カテゴリ: 💪 自己鍛錬（self_discipline）
ターゲット: 20-35歳の「変えたいけど行動できてない」男性

名言のソース:
- David Goggins
- Jocko Willink
- Arnold Schwarzenegger
- Kobe Bryant
- Bruce Lee
- Miyamoto Musashi

JSONフォーマット:
{
  "id": "quote_011",
  "quote_ja": "日本語の名言（短く、力強く）",
  "quote_en": "英語原文（あれば）",
  "author": "偉人名",
  "author_description": "一行の説明",
  "category": "self_discipline",
  "punchline": "ウィジェット用の短縮版",
  "background_image": "bg_gym_01〜10をランダムに",
  "push_notification_hook": "釣り場理論準拠の通知文言"
}

通知文言の例:
- 「今日の名言、読んだ瞬間に鳥肌立った...」
- 「90%の男がスルーする。でもお前は違うと信じてる。」
- 「これ読んでからジム行く気になった。マジで。」
```

### 方法2: 段階的に生成して結合

1. **カテゴリ1（自己鍛錬）**: 40件生成 → `quotes_self_discipline.json`
2. **カテゴリ2（覚醒・行動）**: 40件生成 → `quotes_awakening.json`
3. **カテゴリ3（マインドセット）**: 40件生成 → `quotes_mindset.json`
4. **カテゴリ4（戦い・勝負）**: 40件生成 → `quotes_battle.json`
5. **カテゴリ5（朝・習慣）**: 40件生成 → `quotes_morning.json`
6. 全てを結合 → `quotes.json`（200件）

---

## 📝 名言作成チェックリスト

各名言が以下を満たしているか確認:

- [ ] **短い**: 3行以内（長くても5行）
- [ ] **力強い**: 弱々しい表現を避ける
- [ ] **具体的**: 抽象的すぎない
- [ ] **行動的**: 思考より行動を促す
- [ ] **男性的**: ターゲットに合った表現
- [ ] **通知文言**: 答えを完結させず、開かせる
- [ ] **背景画像**: カテゴリに応じた画像名
- [ ] **punchline**: ウィジェットで映える1-2行

---

## 🎨 背景画像の命名規則

| カテゴリ | 画像名パターン | 説明 |
|---|---|---|
| 💪 自己鍛錬 | `bg_gym_01〜10` | ジム、ダンベル、トレーニング |
| 🔥 覚醒・行動 | `bg_fire_01〜10` | 炎、エネルギッシュな背景 |
| 🧠 マインドセット | `bg_mountain_01〜10` | 山、高峰、達成感 |
| ⚔️ 戦い・勝負 | `bg_fight_01〜10` | 格闘技、戦場、競争 |
| 🌅 朝・習慣 | `bg_sunrise_01〜10` | 朝焼け、日の出、新しい始まり |

---

## 📊 進捗管理

| カテゴリ | 目標 | 現在 | 残り |
|---|:---:|:---:|:---:|
| 💪 自己鍛錬 | 40 | 2 | 38 |
| 🔥 覚醒・行動 | 40 | 2 | 38 |
| 🧠 マインドセット | 40 | 2 | 38 |
| ⚔️ 戦い・勝負 | 40 | 2 | 38 |
| 🌅 朝・習慣 | 40 | 2 | 38 |
| **合計** | **200** | **10** | **190** |

---

## 🚀 次のステップ

1. **AIツールで各カテゴリ40件ずつ生成**
2. **生成されたJSONを確認・調整**
3. **quotes.json に統合**
4. **アプリで動作確認**

---

## 💡 ヒント

### MVPとして30-50件でもOK
リリース判定条件では「200件以上」となっていますが、最初のMVPとして:
- **30-50件でもコア体験は成立**
- **1ヶ月間は被らない**
- **リリース後に追加アップデートで拡張可能**

### クオリティ > 数
- 200件の平凡な名言より、50件の刺さる名言の方が価値が高い
- ターゲットに刺さらない名言は逆効果

---

## 参考リンク

- [David Goggins Quotes](https://www.goalcast.com/david-goggins-quotes/)
- [Jocko Willink Quotes](https://www.goalcast.com/jocko-willink-quotes/)
- [Kobe Bryant Quotes](https://www.goalcast.com/kobe-bryant-quotes/)
- [Marcus Aurelius Meditations](https://www.goodreads.com/work/quotes/31010-ta-eis-heauton)
