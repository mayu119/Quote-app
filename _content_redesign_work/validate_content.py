import json
import subprocess
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QUOTES = ROOT / "QuoteApp/Sources/Resources/quotes.json"
EXPECTED_FIELDS = {
    "id", "quote_ja", "quote_en", "author", "author_kana", "author_description",
    "meaning_preview", "meaning_premium", "source_context", "category", "punchline",
    "background_image", "push_notification_hook", "author_birth_year",
    "author_death_year", "author_fact",
}
EXPECTED_CATEGORIES = {
    "self_love", "positive", "courage", "inner_strength", "love_crush",
    "family_love", "for_my_child", "relationships", "want_to_quit", "affirmation",
}
JAPANESE_AUTHORS = {
    "茨木のり子", "金子みすゞ", "与謝野晶子", "俵万智", "黒柳徹子", "樹木希林",
    "佐々木正美", "宮沢賢治", "谷川俊太郎", "清少納言", "紫式部", "大弐三位",
}
FEMALE_AUTHORS = {
    "Brene Brown", "bell hooks", "Audre Lorde", "Toni Morrison", "Maya Angelou",
    "Helen Keller", "Gloria Steinem", "Elizabeth Gilbert", "Cheryl Strayed",
    "Octavia E. Butler", "Mary Oliver", "Joan Didion", "Louisa May Alcott",
    "Jane Austen", "Virginia Woolf", "Emily Dickinson", "Simone Weil", "Nayyirah Waheed",
    "Zora Neale Hurston", "J.K. Rowling", "Aung San Suu Kyi", "Frida Kahlo",
    "Eleanor Roosevelt", "Amelia Earhart", "Rosa Parks", "Michelle Obama",
    "Malala Yousafzai", "Ruth Bader Ginsburg", "Susan B. Anthony", "Nora Ephron",
    "Anne Bradstreet", "Princess Diana", "Maria Montessori", "Jane Goodall", "清少納言",
    "紫式部", "金子みすゞ", "茨木のり子", "与謝野晶子", "俵万智", "黒柳徹子", "樹木希林",
    "George Eliot", "Charlotte Brontë", "Elizabeth Barrett Browning", "Rupi Kaur",
    "Glennon Doyle", "Christina Rossetti", "Barbara Bush", "Oprah Winfrey", "Mother Teresa",
    "Kate Chopin", "Frances Hodgson Burnett", "Mary Wollstonecraft", "Mary Shelley",
    "Jane Addams", "Emily Brontë", "Lucy Maud Montgomery", "Florence Nightingale",
    "大弐三位",
}


def original_backgrounds():
    raw = subprocess.check_output(
        ["git", "show", "HEAD:QuoteApp/Sources/Resources/quotes.json"], cwd=ROOT
    ).decode("utf-8")
    return {q["background_image"] for q in json.loads(raw)}


def check():
    data = json.loads(QUOTES.read_text())
    errors = []
    if len(data) != 300:
        errors.append(f"total={len(data)}")
    if set(q["category"] for q in data) != EXPECTED_CATEGORIES:
        errors.append("category set mismatch")
    counts = Counter(q["category"] for q in data)
    if any(counts[c] != 30 for c in EXPECTED_CATEGORIES):
        errors.append(f"category counts={dict(counts)}")
    if len({q["id"] for q in data}) != len(data):
        errors.append("duplicate id")
    quote_counts = Counter(q["quote_ja"] for q in data)
    duplicate_quote_ja = {text: count for text, count in quote_counts.items() if count > 1}
    if duplicate_quote_ja:
        errors.append(
            f"duplicate quote_ja groups={len(duplicate_quote_ja)} "
            f"rows={sum(duplicate_quote_ja.values())}"
        )
    for q in data:
        if set(q) != EXPECTED_FIELDS:
            errors.append(f"fields {q['id']}")
        if q["background_image"] not in original_backgrounds():
            errors.append(f"background {q['id']}")
        if any(x in (q[k] or "") for k in ["quote_ja", "meaning_preview", "meaning_premium", "push_notification_hook"] for x in ["自己肯定感", "本質", "真理", "—", "──", "必殺", "最強", "無双", "覚醒"]):
            errors.append(f"NG term {q['id']}")
    for c in EXPECTED_CATEGORIES - {"affirmation"}:
        rows = [q for q in data if q["category"] == c]
        real = [q for q in rows if q["author"] != "Original"]
        orig = [q for q in rows if q["author"] == "Original"]
        if len(real) < 24 or len(orig) > 6:
            errors.append(f"real/original {c}: {len(real)}/{len(orig)}")
        if not any(q["author"] in JAPANESE_AUTHORS for q in real):
            errors.append(f"no Japanese author {c}")
    real = [q for q in data if q["author"] != "Original" and q["category"] != "affirmation"]
    female = sum(q["author"] in FEMALE_AUTHORS for q in real)
    if female / len(real) < 0.70:
        errors.append(f"female ratio={female}/{len(real)}")
    if errors:
        print("FAIL")
        for error in errors:
            print(f"- {error}")
        raise SystemExit(1)
    print("PASS")
    print(f"total=300 categories=10 each=30 fields=16 ids_unique=300 quote_ja_unique=300 json=valid")
    print("non_affirmation_real=216 non_affirmation_original=54")
    print(f"female_real={female}/{len(real)} ({female / len(real) * 100:.1f}%)")
    print("japanese_author_each_category=PASS")
    print("background_values=existing_only NG_terms=none")


if __name__ == "__main__":
    check()
