#!/usr/bin/env python3

import json
import re
import subprocess
import time
import urllib.parse

FILES = [
    "QuoteApp/Sources/Resources/quotes.json",
    "QuoteApp/Sources/Resources/quotes_full.json",
]

API = "https://www.wikidata.org/w/api.php"

AUTHOR_SEARCH_OVERRIDES = {
    "Princess Diana": "Diana, Princess of Wales",
    "Dalai Lama": "14th Dalai Lama",
    "Brene Brown": "Brené Brown",
    "Anais Nin": "Anaïs Nin",
    "Antoine de Saint-Exupéry": "Antoine de Saint-Exupéry",
    "C.S. Lewis": "C. S. Lewis",
    "Thích Nhất Hạnh": "Thích Nhất Hạnh",
    "Ruth Bader Ginsburg": "Ruth Bader Ginsburg",
    "José Martí": "José Martí",
    "Pope John XXIII": "Pope John XXIII",
}

AUTHOR_QID_OVERRIDES = {
    "Princess Diana": "Q9685",
    "Mother Teresa": "Q31119",
    "Fred Rogers": "Q313804",
    "Dalai Lama": "Q76517",
    "Brene Brown": "Q4966114",
    "bell hooks": "Q290191",
    "C.S. Lewis": "Q34660",
    "Thích Nhất Hạnh": "Q310913",
    "Marcus Aurelius": "Q8409",
    "Seneca": "Q18216",
    "Lao Tzu": "Q9333",
    "Rumi": "Q43347",
    "Elizabeth Gilbert": "Q231424",
}

DESCRIPTION_OVERRIDES = {
    "Princess Diana": "英国の元皇太子妃・人道活動家",
    "Mother Teresa": "カトリック修道女・宣教者慈善修道会の創設者",
    "Fred Rogers": "司会者・プロデューサー・子ども番組制作者",
    "Dalai Lama": "チベット仏教の精神的指導者・ノーベル平和賞受賞者",
    "Brene Brown": "アメリカの研究者・作家",
    "bell hooks": "アメリカの作家・思想家",
    "C.S. Lewis": "アイルランド生まれの作家・思想家",
    "Marcus Aurelius": "ローマ皇帝・ストア派哲学者",
    "Seneca": "古代ローマの哲学者・政治家・劇作家",
    "Lao Tzu": "古代中国の思想家・『老子』の著者とされる人物",
    "Rumi": "ペルシア語の詩人・神秘思想家",
    "Pope John XXIII": "第261代ローマ教皇",
    "Thích Nhất Hạnh": "ベトナムの禅僧・平和活動家",
    "Rumi": "13世紀のペルシア語詩人・神秘思想家",
    "Elizabeth Gilbert": "アメリカの作家",
    "Lao Tzu": "中国古代の思想家・『老子』の著者とされる人物",
    "Dana Reeve": "アメリカの俳優・歌手",
    "Anais Nin": "フランス生まれの作家",
    "Anaïs Nin": "フランス生まれの作家",
    "Gloria Steinem": "アメリカのフェミニスト活動家・ジャーナリスト",
    "Indra Nooyi": "インド出身の実業家・元ペプシコCEO",
    "George Santayana": "スペイン生まれの哲学者・随筆家",
    "Brad Henry": "アメリカの政治家",
    "Haim Ginott": "イスラエル生まれの臨床心理学者・教育家",
    "Viktor Frankl": "オーストリアの精神科医・哲学者・作家",
}

METADATA_OVERRIDES = {
    "Rumi": {
        "author_birth_year": 1207,
        "author_death_year": 1273,
        "author_fact": "1207年生まれ、1273年没。13世紀のペルシア語詩人・神秘思想家。",
    },
    "Thích Nhất Hạnh": {
        "author_birth_year": 1926,
        "author_death_year": 2022,
        "author_fact": "1926年生まれ、2022年没。ベトナムの禅僧・平和活動家。",
    },
    "Elizabeth Gilbert": {
        "author_birth_year": 1969,
        "author_death_year": None,
        "author_fact": "1969年生まれ。アメリカの作家。",
    },
    "Lao Tzu": {
        "author_birth_year": None,
        "author_death_year": None,
        "author_fact": "中国古代の思想家・『老子』の著者とされる人物。生没年は諸説あります。",
    },
    "Dana Reeve": {
        "author_fact": "1961年生まれ、2006年没。アメリカの俳優・歌手。",
    },
    "Anais Nin": {
        "author_fact": "1903年生まれ、1977年没。フランス生まれの作家。",
    },
    "Anaïs Nin": {
        "author_fact": "1903年生まれ、1977年没。フランス生まれの作家。",
    },
    "Gloria Steinem": {
        "author_fact": "1934年生まれ。アメリカのフェミニスト活動家・ジャーナリスト。",
    },
    "Indra Nooyi": {
        "author_fact": "1955年生まれ。インド出身の実業家・元ペプシコCEO。",
    },
    "George Santayana": {
        "author_fact": "1863年生まれ、1952年没。スペイン生まれの哲学者・随筆家。",
    },
    "Brad Henry": {
        "author_fact": "1963年生まれ。アメリカの政治家。",
    },
    "Haim Ginott": {
        "author_fact": "1922年生まれ、1973年没。イスラエル生まれの臨床心理学者・教育家。",
    },
    "Viktor Frankl": {
        "author_fact": "1905年生まれ、1997年没。オーストリアの精神科医・哲学者・作家。",
    },
}

BAD_DESCRIPTION_KEYWORDS = [
    "painting",
    "film",
    "book edition",
    "airport",
    "organization",
    "foundation",
    "television series",
    "rose cultivar",
]

HUMAN_QID = "Q5"


def curl_json(url: str):
    last_error = None
    for attempt in range(4):
        raw = subprocess.check_output(
            ["curl", "-L", "-s", "-A", "QuoteAppAuthorFacts/1.0", url],
            text=True,
        ).strip()
        if raw:
            try:
                return json.loads(raw)
            except json.JSONDecodeError as exc:
                last_error = exc
        time.sleep(0.35 * (attempt + 1))
    raise last_error or RuntimeError(f"Empty response from {url}")


def search_author(author):
    query = AUTHOR_SEARCH_OVERRIDES.get(author, author)
    url = (
        f"{API}?"
        + urllib.parse.urlencode(
            {
                "action": "wbsearchentities",
                "search": query,
                "language": "ja",
                "uselang": "ja",
                "type": "item",
                "limit": 5,
                "format": "json",
            }
        )
    )
    return curl_json(url).get("search", [])


def choose_candidate(author, candidates, candidate_entities):
    if author in AUTHOR_QID_OVERRIDES:
        for candidate in candidates:
            if candidate.get("id") == AUTHOR_QID_OVERRIDES[author]:
                return candidate
    if not candidates:
        return None

    exactish = []
    lowered = author.lower()
    for candidate in candidates:
        entity = candidate_entities.get(candidate.get("id"), {})
        if entity and not is_human(entity):
            continue
        label = (candidate.get("label") or "").lower()
        description = (candidate.get("description") or "").lower()
        if any(keyword in description for keyword in BAD_DESCRIPTION_KEYWORDS):
            continue
        if lowered in label or label in lowered or author in (candidate.get("label") or ""):
            exactish.append(candidate)

    if exactish:
        return exactish[0]

    for candidate in candidates:
        entity = candidate_entities.get(candidate.get("id"), {})
        if entity and not is_human(entity):
            continue
        description = (candidate.get("description") or "").lower()
        if any(keyword in description for keyword in BAD_DESCRIPTION_KEYWORDS):
            continue
        return candidate

    return candidates[0]


def parse_years(description):
    if not description:
        return None, None
    match = re.search(r"[(（](\d{1,4})(?:[–-](\d{1,4})?)?[)）]", description)
    if not match:
        return None, None
    birth = int(match.group(1)) if match.group(1) else None
    death = int(match.group(2)) if match.group(2) else None
    return birth, death


def get_entities(ids):
    entities = {}
    for start in range(0, len(ids), 50):
        chunk = ids[start:start + 50]
        url = (
            f"{API}?"
            + urllib.parse.urlencode(
                {
                    "action": "wbgetentities",
                    "ids": "|".join(chunk),
                    "props": "claims|descriptions",
                    "languages": "ja|en",
                    "format": "json",
                }
            )
        )
        entities.update(curl_json(url).get("entities", {}))
    return entities


def claim_ids(entity, prop):
    ids = []
    for claim in entity.get("claims", {}).get(prop, []):
        value = claim.get("mainsnak", {}).get("datavalue", {}).get("value", {})
        if isinstance(value, dict) and value.get("entity-type") == "item":
            ids.append(value.get("id"))
    return ids


def is_human(entity):
    return HUMAN_QID in claim_ids(entity, "P31")


def claim_year(entity, prop):
    for claim in entity.get("claims", {}).get(prop, []):
        value = claim.get("mainsnak", {}).get("datavalue", {}).get("value", {})
        time_value = value.get("time")
        if isinstance(time_value, str):
            match = re.match(r"^[+-](\d{1,11})-", time_value)
            if match:
                return int(match.group(1))
    return None


def entity_description(entity):
    descriptions = entity.get("descriptions", {})
    if "ja" in descriptions:
        return descriptions["ja"]["value"]
    if "en" in descriptions:
        return descriptions["en"]["value"]
    return None


def clean_description(author, description, fallback):
    if author in DESCRIPTION_OVERRIDES:
        return DESCRIPTION_OVERRIDES[author]
    if not description:
        return fallback
    text = re.sub(r"\s*[(（]\d{1,4}(?:[–-]\d{1,4})?[)）]\s*$", "", description).strip()
    text = re.sub(r"\s*[(（]\d{1,4}-[)）]\s*$", "", text).strip()
    if not re.search(r"[ぁ-んァ-ヶ一-龯]", text):
        return fallback
    return text


def build_author_fact(author, birth_year, death_year, description):
    if birth_year and death_year:
        return f"{birth_year}年生まれ、{death_year}年没。{description}。"
    if birth_year:
        return f"{birth_year}年生まれ。{description}。"
    return f"{description}。"


def main():
    with open(FILES[0]) as f:
        data = json.load(f)

    defaults = {}
    for quote in data:
        author = quote.get("author")
        if author and author != "Original":
            defaults.setdefault(author, quote.get("author_description") or "")

    metadata = {}
    unresolved = []
    selected_qids = {}

    search_results = {author: search_author(author) for author in defaults}
    candidate_ids = sorted({
        candidate["id"]
        for candidates in search_results.values()
        for candidate in candidates
    })
    candidate_entities = get_entities(candidate_ids)

    for author, fallback_description in defaults.items():
        candidate = choose_candidate(author, search_results[author], candidate_entities)
        if candidate is None:
            unresolved.append(author)
            continue
        selected_qids[author] = candidate.get("id")

    if unresolved:
        raise SystemExit(f"Unresolved authors: {', '.join(unresolved)}")

    entities = get_entities(sorted(set(selected_qids.values())))

    for author, fallback_description in defaults.items():
        entity = entities.get(selected_qids[author], {})
        raw_description = entity_description(entity) or fallback_description
        description = clean_description(author, raw_description, fallback_description)
        birth_year = claim_year(entity, "P569")
        death_year = claim_year(entity, "P570")
        if birth_year is None:
            birth_year, death_year = parse_years(raw_description)
        metadata[author] = {
            "author_birth_year": birth_year,
            "author_death_year": death_year,
            "author_description": description,
            "author_fact": build_author_fact(author, birth_year, death_year, description),
        }
        if author in METADATA_OVERRIDES:
            metadata[author].update(METADATA_OVERRIDES[author])

    for path in FILES:
        with open(path) as f:
            quotes = json.load(f)

        for quote in quotes:
            author = quote.get("author")
            if not author or author == "Original":
                quote["author_birth_year"] = None
                quote["author_death_year"] = None
                quote["author_fact"] = None
                continue

            meta = metadata[author]
            quote["author_birth_year"] = meta["author_birth_year"]
            quote["author_death_year"] = meta["author_death_year"]
            quote["author_description"] = meta["author_description"]
            quote["author_fact"] = meta["author_fact"]

        with open(path, "w") as f:
            json.dump(quotes, f, ensure_ascii=False, indent=2)
            f.write("\n")

    print(f"Updated authors: {len(metadata)}")


if __name__ == "__main__":
    main()
