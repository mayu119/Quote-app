#!/usr/bin/env python3
"""Bundled quote data の回帰を防ぐ軽量バリデータ。"""

import json
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1] / "QuoteApp"
FILES = [
    ROOT / "Sources/Resources/quotes.json",
    ROOT / "Sources/Resources/quotes_full.json",
]
REMOVED_IDS = {
    "women_quote_044", "women_quote_087", "women_quote_184",
    "women_quote_049", "women_quote_098", "women_quote_178",
    "women_quote_108", "women_quote_109", "women_quote_121",
    "women_quote_122", "women_quote_123", "women_quote_127",
    "women_quote_134", "women_quote_136", "women_quote_137",
    "women_quote_140", "women_quote_141", "women_quote_159",
    "women_quote_170", "women_quote_173", "women_quote_175",
    "women_quote_181", "women_quote_185", "women_quote_186",
    "women_quote_187", "women_quote_188",
}
EXPECTED_KANA = {"women_quote_183": "ヴィクトール・フランクル"}


def normalized(value: str) -> str:
    return "".join(value.split()).casefold()


def validate(quotes: list[dict], path: Path) -> list[str]:
    errors: list[str] = []
    ids = [quote["id"] for quote in quotes]
    duplicate_ids = [item for item, count in Counter(ids).items() if count > 1]
    if duplicate_ids:
        errors.append(f"{path.name}: duplicate IDs: {duplicate_ids}")

    for quote_id in REMOVED_IDS:
        if quote_id in ids:
            errors.append(f"{path.name}: removed quote remains: {quote_id}")

    for quote_id, kana in EXPECTED_KANA.items():
        quote = next((item for item in quotes if item["id"] == quote_id), None)
        if quote is None or quote.get("author_kana") != kana:
            errors.append(f"{path.name}: kana mismatch: {quote_id}")

    english = [
        (item.get("category"), normalized(item["quote_en"]))
        for item in quotes if item.get("quote_en")
    ]
    duplicates = [item for item, count in Counter(english).items() if count > 1]
    if duplicates:
        errors.append(f"{path.name}: duplicate English quotes: {duplicates}")

    category_counts = Counter(item["category"] for item in quotes)
    invalid_categories = {category: count for category, count in category_counts.items() if count != 30}
    if invalid_categories:
        errors.append(f"{path.name}: category counts must be 30: {invalid_categories}")

    if len(quotes) != 300:
        errors.append(f"{path.name}: total quote count must be 300: {len(quotes)}")

    original_count = sum(item.get("author") == "Original" for item in quotes)
    if original_count < 60:
        errors.append(f"{path.name}: Original count is below 60: {original_count}")
    return errors


def main() -> int:
    datasets = []
    errors = []
    for path in FILES:
        try:
            quotes = json.loads(path.read_text())
            if not isinstance(quotes, list):
                raise ValueError("root must be an array")
            datasets.append(quotes)
            errors.extend(validate(quotes, path))
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            errors.append(f"{path}: {exc}")

    if len(datasets) == 2 and datasets[0] != datasets[1]:
        errors.append("quotes.json and quotes_full.json differ")

    if errors:
        print("Quote data validation failed:", *errors, sep="\\n- ")
        return 1
    print(f"Quote data validation passed: {len(datasets[0])} quotes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
