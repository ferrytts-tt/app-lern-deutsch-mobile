import json
import hashlib
import os

base_dir = r"c:\Users\tahak\Downloads\app-lern-deutsch-mobile"
mp3_path = os.path.join(base_dir, "assets", "media", "audio", "lot_001_chanson.mp3")
json_path = os.path.join(base_dir, "assets", "media", "lot_001_chanson.json")
manifest_path = os.path.join(base_dir, "assets", "media", "manifest.json")

# 1. Update lot_001_chanson.json
chanson_data = {
    "lot_id": 1,
    "type": "chanson",
    "title_de": "Mach's gut, bis bald (Suno)",
    "title_ar": "مع السلامة، إلى اللقاء (أغنية سونو)",
    "title_fr": "Prends soin de toi, à bientôt (Suno)",
    "lignes": [
        {
            "locuteur": "Chant",
            "de": "Mensch, lange nicht gesehen!",
            "ar": "يا رجل، من زمان ما شفتك!",
            "fr": "Ça fait un bail qu'on s'est pas vus !",
            "debut_ms": 0,
            "fin_ms": 2500,
            "phrase_id": "phrase_002"
        },
        {
            "locuteur": "Chant",
            "de": "Schön, dich mal wieder zu sehen!",
            "ar": "حلو أشوفك مرة ثانية!",
            "fr": "Ça fait plaisir de te revoir !",
            "debut_ms": 2500,
            "fin_ms": 5100,
            "phrase_id": "phrase_006"
        },
        {
            "locuteur": "Chant",
            "de": "Na, wie läuft's?",
            "ar": "كيف الأحوال؟",
            "fr": "Alors, comment ça roule ?",
            "debut_ms": 5100,
            "fin_ms": 6300,
            "phrase_id": "phrase_001"
        },
        {
            "locuteur": "Chant",
            "de": "Was gibt's Neues?",
            "ar": "شو الجديد؟",
            "fr": "Quoi de neuf ?",
            "debut_ms": 6300,
            "fin_ms": 7400,
            "phrase_id": "phrase_003"
        },
        {
            "locuteur": "Chant",
            "de": "Na, wie war's am Wochenende?",
            "ar": "كيف كانت عطلة نهاية الأسبوع؟",
            "fr": "Alors, c'était comment ton week-end ?",
            "debut_ms": 7400,
            "fin_ms": 9800,
            "phrase_id": "phrase_005"
        },
        {
            "locuteur": "Chant",
            "de": "Das Wetter ist heute echt mies,",
            "ar": "الجو اليوم سيئ جداً،",
            "fr": "Le temps est vraiment pourri aujourd'hui,",
            "debut_ms": 9800,
            "fin_ms": 12200,
            "phrase_id": "phrase_007"
        },
        {
            "locuteur": "Chant",
            "de": "Es schüttet wie aus Eimern!",
            "ar": "المطر ينهمر بغزارة!",
            "fr": "Il pleut des cordes !",
            "debut_ms": 12200,
            "fin_ms": 14900,
            "phrase_id": "phrase_008"
        },
        {
            "locuteur": "Chant",
            "de": "Hast du mal die Uhrzeit?",
            "ar": "تعرف كم الساعة؟",
            "fr": "T'aurais l'heure s'il te plaît ?",
            "debut_ms": 14900,
            "fin_ms": 16800,
            "phrase_id": "phrase_009"
        },
        {
            "locuteur": "Chant",
            "de": "Ich muss los –",
            "ar": "لازم أمشي الآن –",
            "fr": "Faut que j'y aille –",
            "debut_ms": 16800,
            "fin_ms": 18400,
            "phrase_id": "phrase_004"
        },
        {
            "locuteur": "Chant",
            "de": "Mach's gut, bis bald!",
            "ar": "مع السلامة، اعتنِ بنفسك، إلى اللقاء قريباً!",
            "fr": "Prends soin de toi, à bientôt !",
            "debut_ms": 18400,
            "fin_ms": 20800,
            "phrase_id": "phrase_010"
        },
        {
            "locuteur": "Chant",
            "de": "Mach's gut, bis bald! (Outro)",
            "ar": "مع السلامة، إلى اللقاء قريباً!",
            "fr": "Prends soin de toi, à bientôt !",
            "debut_ms": 20800,
            "fin_ms": 27450,
            "phrase_id": "phrase_010"
        }
    ]
}

with open(json_path, "w", encoding="utf-8") as f:
    json.dump(chanson_data, f, indent=2, ensure_ascii=False)
print("-> lot_001_chanson.json mis à jour !")

# 2. Compute MP3 hash and size
with open(mp3_path, "rb") as f:
    mp3_bytes = f.read()

mp3_size = len(mp3_bytes)
mp3_hash = hashlib.sha256(mp3_bytes).hexdigest()

# 3. Update manifest.json
with open(manifest_path, "r", encoding="utf-8") as f:
    manifest = json.load(f)

for item in manifest["contents"]:
    if item["lot_id"] == 1 and item["type"] == "chanson":
        item["audio_file"] = "lot_001_chanson.mp3"
        item["content_json_file"] = "lot_001_chanson.json"
        item["duration_seconds"] = 27
        item["size_bytes"] = mp3_size
        item["checksum"] = mp3_hash
        item["statut_licence"] = "approuve"
        item["source"] = "Suno AI v6 - Production originale par ferrytts"
        item["title_de"] = "Mach's gut, bis bald (Suno)"
        item["title_ar"] = "مع السلامة، إلى اللقاء (أغنية سونو)"
        item["title_fr"] = "Prends soin de toi, à bientôt (Suno)"
        break

with open(manifest_path, "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2, ensure_ascii=False)
print("-> manifest.json mis à jour avec le MP3 Suno officiel !")
