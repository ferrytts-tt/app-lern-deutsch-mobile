import json

with open('assets/data/phrases.json', 'r', encoding='utf-8') as f:
    phrases = json.load(f)

for lot in range(4, 31):
    start = (lot - 1) * 10
    end = start + 10
    print(f"=== LOT {lot} ===")
    for p in phrases[start:end]:
        print(f"  {p['id']}: [{p['de']}] - {p['fr']}")
