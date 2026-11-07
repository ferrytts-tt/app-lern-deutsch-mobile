import av
import hashlib
import json
import os
import shutil

src_mp3 = r"C:\Users\tahak\.gemini\antigravity\brain\b555cf82-3f5a-4c44-9ede-fd23278d6eb9\.user_uploaded\uploaded_media_1793548744141.mp3"
base_dir = r"c:\Users\tahak\Downloads\app-lern-deutsch-mobile"
dest_mp3 = os.path.join(base_dir, "assets", "media", "audio", "lot_002_chanson.mp3")
json_path = os.path.join(base_dir, "assets", "media", "lot_002_chanson.json")
manifest_path = os.path.join(base_dir, "assets", "media", "manifest.json")

# 1. Copier le fichier MP3
shutil.copy2(src_mp3, dest_mp3)
file_size = os.path.getsize(dest_mp3)

# 2. SHA-256
with open(dest_mp3, "rb") as f:
    mp3_bytes = f.read()
file_hash = hashlib.sha256(mp3_bytes).hexdigest()

# 3. Durée exacte
container = av.open(dest_mp3)
duration_s = float(container.duration / av.time_base)
container.close()

print(f"Fichier copié : {dest_mp3}")
print(f"Taille : {file_size} octets")
print(f"Durée : {duration_s:.2f} secondes (arrondi: {int(round(duration_s))}s)")
print(f"SHA-256 : {file_hash}")

# 4. Transcription synchronisée
chanson_data = {
    "lot_id": 2,
    "type": "chanson",
    "title_de": "Feierabend-Groove (Suno)",
    "title_ar": "لحن نهاية الدوام (أغنية سونو)",
    "title_fr": "Le groove de la débauche (Suno)",
    "lignes": [
        {
            "locuteur": "Chant",
            "de": "Ich hab heute echt viel um die Ohren,",
            "ar": "عندي اليوم أشغال كثيرة جداً،",
            "fr": "J'en ai par-dessus la tête aujourd'hui,",
            "debut_ms": 0,
            "fin_ms": 2800,
            "phrase_id": "phrase_011"
        },
        {
            "locuteur": "Chant",
            "de": "Der Chef hat voll schlechte Laune.",
            "ar": "مزاج المدير سيئ جداً اليوم.",
            "fr": "Le patron est d'une humeur massacrante aujourd'hui.",
            "debut_ms": 2800,
            "fin_ms": 5200,
            "phrase_id": "phrase_017"
        },
        {
            "locuteur": "Chant",
            "de": "Das schaff ich bis morgen nicht –",
            "ar": "لن أنجز هذا قبل الغد –",
            "fr": "J'y arriverai jamais d'ici demain –",
            "debut_ms": 5200,
            "fin_ms": 7400,
            "phrase_id": "phrase_014"
        },
        {
            "locuteur": "Chant",
            "de": "Hab ich total vergessen, sorry!",
            "ar": "نسيت تماماً، آسف!",
            "fr": "J'ai complètement zappé, désolé !",
            "debut_ms": 7400,
            "fin_ms": 9900,
            "phrase_id": "phrase_018"
        },
        {
            "locuteur": "Chant",
            "de": "Ich hab mich krankgemeldet!",
            "ar": "بلّغت عن مرضي!",
            "fr": "Je me suis mis en arrêt maladie !",
            "debut_ms": 9900,
            "fin_ms": 12400,
            "phrase_id": "phrase_016"
        },
        {
            "locuteur": "Chant",
            "de": "Hast du mal kurz Zeit?",
            "ar": "هل عندك وقت قصير؟",
            "fr": "T'as deux minutes ?",
            "debut_ms": 12400,
            "fin_ms": 14400,
            "phrase_id": "phrase_015"
        },
        {
            "locuteur": "Chant",
            "de": "Können wir den Termin schieben?",
            "ar": "هل نؤجل الموعد؟",
            "fr": "On peut décaler le rendez-vous ?",
            "debut_ms": 14400,
            "fin_ms": 16800,
            "phrase_id": "phrase_012"
        },
        {
            "locuteur": "Chant",
            "de": "Das klären wir später,",
            "ar": "نتكلم عن هذا ونحسمه لاحقاً،",
            "fr": "On règle ça plus tard,",
            "debut_ms": 16800,
            "fin_ms": 18800,
            "phrase_id": "phrase_019"
        },
        {
            "locuteur": "Chant",
            "de": "Ich mach gleich Feierabend!",
            "ar": "سأنهي دوامي بعد قليل!",
            "fr": "Je débauche bientôt !",
            "debut_ms": 18800,
            "fin_ms": 21500,
            "phrase_id": "phrase_013"
        },
        {
            "locuteur": "Chant",
            "de": "Danke dir, du hast mir echt den Tag gerettet!",
            "ar": "شكراً لك، أنقذتَ يومي بالفعل!",
            "fr": "Merci à toi, tu m'as vraiment sauvé la mise !",
            "debut_ms": 21500,
            "fin_ms": 26000,
            "phrase_id": "phrase_020"
        }
    ]
}

with open(json_path, "w", encoding="utf-8") as f:
    json.dump(chanson_data, f, indent=2, ensure_ascii=False)
print(f"-> {json_path} créé avec succès !")

# 5. Mettre à jour manifest.json
with open(manifest_path, "r", encoding="utf-8") as f:
    manifest = json.load(f)

# Retirer toute ancienne chanson pour le lot 2
manifest["contents"] = [c for c in manifest["contents"] if not (c.get("lot_id") == 2 and c.get("type") == "chanson")]

manifest["contents"].append({
    "lot_id": 2,
    "type": "chanson",
    "audio_file": "lot_002_chanson.mp3",
    "content_json_file": "lot_002_chanson.json",
    "duration_seconds": int(round(duration_s)),
    "size_bytes": file_size,
    "checksum": file_hash,
    "version": 1,
    "statut_licence": "approuve",
    "source": "Suno AI - Production originale avec les 10 phrases du Lot 2",
    "created_at": "2026-11-01T16:55:00Z",
    "title_de": "Feierabend-Groove (Suno)",
    "title_ar": "لحن نهاية الدوام (أغنية سونو)",
    "title_fr": "Le groove de la débauche (Suno)"
})

with open(manifest_path, "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2, ensure_ascii=False)
print("-> manifest.json mis à jour avec la chanson du Lot 2 !")
