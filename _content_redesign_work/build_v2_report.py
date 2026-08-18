import glob
import json
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "_content_redesign_work"))
from validate_content import FEMALE_AUTHORS, JAPANESE_AUTHORS

final = json.loads((ROOT / "QuoteApp/Sources/Resources/quotes.json").read_text())
old_by = {}
for path in glob.glob(str(ROOT / "_content_redesign_work/bank_*.json")):
    for row in json.loads(Path(path).read_text()):
        old_by[row["id"]] = row

changed = [(old_by[q["id"]], q) for q in final if q["id"] in old_by and old_by[q["id"]] != q]
assert len(changed) == 61, len(changed)

protected = {"Rupi Kaur", "Nayyirah Waheed", "Mary Oliver", "茨木のり子", "俵万智", "谷川俊太郎"}
invalid_context = {"women_quote_470", "women_quote_497"}

def cell(value):
    return str(value or "—").replace("|", "／").replace("\n", "<br>")

def reason(old, new):
    if old["author"] in protected:
        return "B-2-7 保護期間中の詩・短歌本文を不採用"
    if new["id"] in invalid_context:
        return "B-2-9 family_love内の反戦詩・文脈不適合"
    return "B-2-8 quote_ja重複の解消"

out = [
    "## 9. v2修正パス（2026-08-18）",
    "",
    "監査で判明した本文重複、保護期間中の詩・短歌本文、文脈不適合を対象に、該当枠だけを修正した。差し替えは61件（重複解消41件、B-2-7の保護対象18件、B-2-9の文脈不適合2件）。affirmation 30件と各カテゴリのOriginal 6件は維持し、追加枠はすべて出典検証済みの実在名言で埋めた。",
    "",
    "### 9.1 修正一覧（旧→新）",
    "",
    "| category | id | 旧著者 | 旧 quote_ja | 新著者 | 新 quote_ja | 理由 |",
    "|---|---|---|---|---|---|---|",
]
for old, new in changed:
    out.append("| " + " | ".join([
        cell(new["category"]), cell(new["id"]), cell(old["author"]), cell(old["quote_ja"]),
        cell(new["author"]), cell(new["quote_ja"]), reason(old, new)
    ]) + " |")

out += [
    "",
    "### 9.2 差し替え理由区分",
    "",
    "| 区分 | 件数 | 対応 |",
    "|---|---:|---|",
    "| B-2-8 本文重複 | 41 | 同一本文をカテゴリ間で使い回さず、PDまたは出典を一点特定できる実在名言へ交換 |",
    "| B-2-7 保護期間中の詩・短歌本文 | 18 | Rupi Kaur 4、Nayyirah Waheed 1、Mary Oliver 5、茨木のり子 4、俵万智 3、谷川俊太郎 1を全件除去 |",
    "| B-2-9 文脈不適合 | 2 | 与謝野晶子「君死にたまふことなかれ」をfamily_love／for_my_childから除去 |",
    "",
    "### 9.3 更新後のカテゴリ別集計",
    "",
    "| category | total | real | Original | 女性著者 | 女性比率 | 日本人著者 |",
    "|---|---:|---:|---:|---:|---:|---|",
]
for category in sorted({q["category"] for q in final}):
    rows = [q for q in final if q["category"] == category]
    real = [q for q in rows if q["author"] != "Original"]
    female = [q for q in real if q["author"] in FEMALE_AUTHORS]
    japanese = sorted({q["author"] for q in real if q["author"] in JAPANESE_AUTHORS})
    ratio = f"{len(female) / len(real) * 100:.1f}%" if real else "—"
    out.append("| " + " | ".join([
        category, str(len(rows)), str(len(real)), str(len(rows) - len(real)),
        str(len(female)), ratio, ", ".join(japanese) or "—"
    ]) + " |")

out += [
    "",
    "非affirmationは実在216件／Original54件。女性著者は171/216（79.2%）。全9非affirmationカテゴリに日本人著者を1件以上残し、Original上限6件を超えるカテゴリはない。",
    "",
    "### 9.4 強化した機械検証と再実行結果",
    "",
    " _content_redesign_work/validate_content.py に、全300件の quote_ja を Counter で集計し、重複グループと重複行をFAILにする検査を追加した。あわせて、新規著者を女性著者・日本人著者の集計へ追加した。",
    "",
    "実行コマンド: python3 _content_redesign_work/validate_content.py",
    "",
    "~~~text",
    "PASS",
    "total=300 categories=10 each=30 fields=16 ids_unique=300 quote_ja_unique=300 json=valid",
    "non_affirmation_real=216 non_affirmation_original=54",
    "female_real=171/216 (79.2%)",
    "japanese_author_each_category=PASS",
    "background_values=existing_only NG_terms=none",
    "~~~",
    "",
    "### 9.5 存命・近年著者の散文引用（Mayuのリスク判断用）",
    "",
    "v2で追加したPD詩歌以外に、存命または死後70年未満の著者の短い散文・日記・講演・エッセイを残している。詩・短歌本文はこの区分に含めず、著作名・章／日付・一次寄りの参照先を source_context と source_index.md に記載した。最終的な公開可否は、配信地域の著作権運用と引用許容範囲をMayuが判断するためのリスク一覧である。",
    "",
    "#### A. 存命著者（散文・講演・日記の短文）",
]
living = defaultdict(list)
recent = defaultdict(list)
for q in final:
    if q["author"] == "Original" or q["category"] == "affirmation":
        continue
    death = q["author_death_year"]
    if death is None:
        living[q["author"]].append(q)
    elif death >= 1956:
        recent[q["author"]].append(q)
for author in sorted(living):
    entries = "; ".join(f'{q["id"]}（{q["category"]}）' for q in living[author])
    out.append(f"- **{author}**: {entries}")
out += ["", "#### B. 死後70年未満の著者（近年著作・散文）"]
for author in sorted(recent):
    entries = "; ".join(f'{q["id"]}（{q["category"]}）' for q in recent[author])
    out.append(f"- **{author}**: {entries}")
out += [
    "",
    "A区分は新規追加のBrene Brown（TED Talk）を含む。B区分はAnne Frankの日記、Audre Lorde・bell hooks・Toni Morrison等の散文／エッセイ／小説本文、Maya Angelou・Joan Didion等の著作からの短文を含む。これらはB-2-7の「詩・短歌本体」には該当しないが、PD詩歌より著作権リスクが高いため、ストア公開前に採用／差し替えを判断する。",
    "",
]
Path("/private/tmp/v2_report_section.md").write_text("\n".join(out) + "\n")
print(f"wrote lines={len(out)} changed={len(changed)} living={len(living)} recent={len(recent)}")
