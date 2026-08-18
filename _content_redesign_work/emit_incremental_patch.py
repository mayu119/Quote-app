import json
import sys

old = json.load(open("QuoteApp/Sources/Resources/quotes.json"))
new = json.load(open("/private/tmp/quotes-v2-meta.json"))
new_by = {q["id"]: q for q in new}
keys = list(old[0].keys())
for q in old:
    n = new_by[q["id"]]
    changed = [i for i, key in enumerate(keys) if q[key] != n[key]]
    if not changed:
        continue
    start = changed[0]
    end = start
    while end + 1 < len(keys) and (end + 1) in changed:
        end += 1
    low = 0
    high = min(len(keys) - 1, end + 1)

    def field_line(obj, index):
        key = keys[index]
        value = json.dumps(obj[key], ensure_ascii=False)
        comma = "," if index < len(keys) - 1 else ""
        return '    "' + key + '": ' + value + comma

    print("# " + q["id"] + " " + keys[start] + ".." + keys[end])
    print("@@")
    for index in range(low, high + 1):
        if start <= index <= end:
            print("-" + field_line(q, index))
            print("+" + field_line(n, index))
        else:
            print(" " + field_line(q, index))
    break
else:
    print("# DONE")
