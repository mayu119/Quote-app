import glob
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "_content_redesign_work"))
from v2_replacement_patch import NEW_AUTHORS

target_path = Path("/private/tmp/quotes-v2.json")
out_path = Path("/private/tmp/quotes-v2-meta.json")
data = json.loads(target_path.read_text())

bank_meta = {}
for path in glob.glob(str(ROOT / "_content_redesign_work/bank_*.json")):
    for row in json.loads(Path(path).read_text()):
        if row["author"] != "Original":
            values = (
                row["author_kana"], row["author_description"],
                row["author_birth_year"], row["author_death_year"], row["author_fact"],
            )
            bank_meta.setdefault(row["author"], values)

changed_ids = set()
old_by = {}
for path in glob.glob(str(ROOT / "_content_redesign_work/bank_*.json")):
    for row in json.loads(Path(path).read_text()):
        old_by[row["id"]] = row

for row in data:
    old = old_by.get(row["id"])
    if not old or old == row:
        continue
    changed_ids.add(row["id"])
    if row["author"] in NEW_AUTHORS:
        values = NEW_AUTHORS[row["author"]]
        row["author_kana"], row["author_description"], row["author_birth_year"], row["author_death_year"], row["author_fact"] = values
    elif row["author"] in bank_meta:
        row["author_kana"], row["author_description"], row["author_birth_year"], row["author_death_year"], row["author_fact"] = bank_meta[row["author"]]
    else:
        raise ValueError(f"missing author metadata: {row['author']}")

out_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
print(f"wrote {out_path} changed_metadata={len(changed_ids)}")
