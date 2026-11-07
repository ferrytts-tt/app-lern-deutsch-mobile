import asyncio
import hashlib
import json
import os
import sys
import edge_tts

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

BASE_DIR = r"c:\Users\tahak\Downloads\app-lern-deutsch-mobile"
PHRASES_PATH = os.path.join(BASE_DIR, "assets", "data", "phrases.json")
MEDIA_DIR = os.path.join(BASE_DIR, "assets", "media")
AUDIO_DIR = os.path.join(MEDIA_DIR, "audio")
MANIFEST_PATH = os.path.join(MEDIA_DIR, "manifest.json")

LOT_METADATA = {
    41: {
        "title_de": "Am Bahnhof und im Zug",
        "title_fr": "À la gare et dans le train",
        "title_ar": "في محطة القطار وعلى متنه"
    },
    42: {
        "title_de": "Bahnsteig und Anschlüsse",
        "title_fr": "Sur le quai et correspondances",
        "title_ar": "على رصيف المحطة والتبديل بين القطارات"
    },
    43: {
        "title_de": "Unterwegs mit U-Bahn und Bus",
        "title_fr": "En déplacement en métro et bus",
        "title_ar": "في المترو والحافلة"
    },
    44: {
        "title_de": "Fahrkarten und Abflugvorbereitung",
        "title_fr": "Tickets urbains et départ pour l'aéroport",
        "title_ar": "التذاكر والتوجه إلى المطار"
    },
    45: {
        "title_de": "Check-in und Sicherheitskontrolle",
        "title_fr": "Enregistrement et contrôle de sécurité",
        "title_ar": "التسجيل والتفتيش الأمني في المطار"
    },
    46: {
        "title_de": "Gepäckausgabe und Taxi",
        "title_fr": "Récupération des bagages et taxi",
        "title_ar": "استلام الحقائب وسيارة الأجرة"
    },
    47: {
        "title_de": "Taxifahrt und Telefonanrufe",
        "title_fr": "Course en taxi et premiers coups de fil",
        "title_ar": "رحلة التاكسي والاتصال الهاتفي"
    },
    48: {
        "title_de": "Telefonate und Sprachnachrichten",
        "title_fr": "Conversations téléphoniques et messages vocaux",
        "title_ar": "مكالمات ورسائل صوتية"
    },
    49: {
        "title_de": "Nach dem Weg fragen",
        "title_fr": "Demander son chemin dans la rue",
        "title_ar": "السؤال عن الطريق في المدينة"
    },
    50: {
        "title_de": "Verloren, Hilfe und Notfälle",
        "title_fr": "Objets perdus, secours et urgences",
        "title_ar": "فقدان الأغراض وطلب النجدة والطوارئ"
    },
}

def get_mp3_duration_ms(data):
    pos = 0
    total_frames = 0
    samples_per_frame = 576
    sample_rate = 24000
    while pos < len(data) - 4:
        if data[pos] == 0xFF and (data[pos+1] & 0xE0) == 0xE0:
            b1, b2, b3 = data[pos+1], data[pos+2], data[pos+3]
            version_bits = (b1 >> 3) & 0x03
            bitrate_idx = (b2 >> 4) & 0x0F
            sr_idx = (b2 >> 2) & 0x03
            padding = (b2 >> 1) & 0x01
            
            if version_bits == 3:  # MPEG 1
                srs = [44100, 48000, 32000]
                rates = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0]
                samples_per_frame = 1152
                coeff = 144
            else:  # MPEG 2 or 2.5
                srs = [22050, 24000, 16000]
                rates = [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0]
                samples_per_frame = 576
                coeff = 72
                
            if sr_idx < len(srs) and bitrate_idx < len(rates) and rates[bitrate_idx] > 0:
                sr = srs[sr_idx]
                sample_rate = sr
                br = rates[bitrate_idx] * 1000
                frame_len = int((coeff * br // sr) + padding)
                total_frames += 1
                pos += frame_len
            else:
                pos += 1
        else:
            pos += 1
    if total_frames == 0 or sample_rate == 0:
        return 0
    return int(total_frames * (samples_per_frame / sample_rate) * 1000)

async def synthesize_line(text, voice, rate="+0%"):
    comm = edge_tts.Communicate(text, voice, rate=rate)
    data = bytearray()
    async for chunk in comm.stream():
        if chunk["type"] == "audio":
            data.extend(chunk["data"])
    return bytes(data)

async def generate_lot_dialogue(lot_id, phrases_subset, manifest):
    meta = LOT_METADATA.get(lot_id, {
        "title_de": f"Gespräch Lot {lot_id}",
        "title_fr": f"Dialogue du Lot {lot_id}",
        "title_ar": f"محادثة المجموعة {lot_id}"
    })
    
    print(f"\n==========================================")
    print(f"[DIALOGUE] Génération Lot {lot_id:02d} : {meta['title_de']}")
    print(f"==========================================")
    
    lignes = []
    # Créer les répliques en alternant Conrad et Katja
    for i, p in enumerate(phrases_subset):
        locuteur = "Conrad" if i % 2 == 0 else "Katja"
        lignes.append({
            "locuteur": locuteur,
            "de": p["de_parle"],
            "ar": p["ar"],
            "fr": p["fr"],
            "debut_ms": 0,
            "fin_ms": 0,
            "phrase_id": p["id"]
        })
        
    dialogue_data = {
        "lot_id": lot_id,
        "type": "dialogue",
        "title_de": meta["title_de"],
        "title_ar": meta["title_ar"],
        "title_fr": meta["title_fr"],
        "lignes": lignes
    }
    
    # 1. Génération audio vitesse normale (+0%)
    print(f"-> Audio normal (+0%)...")
    combined_audio = bytearray()
    current_ms = 0
    
    for line in dialogue_data["lignes"]:
        voice = "de-DE-ConradNeural" if line["locuteur"] == "Conrad" else "de-DE-KatjaNeural"
        audio_chunk = await synthesize_line(line["de"], voice, rate="+0%")
        chunk_ms = get_mp3_duration_ms(audio_chunk)
        line["debut_ms"] = current_ms
        current_ms += chunk_ms
        line["fin_ms"] = current_ms
        combined_audio.extend(audio_chunk)
        
    dur_s = round(current_ms / 1000.0, 1)
    size_bytes = len(combined_audio)
    checksum = hashlib.sha256(combined_audio).hexdigest()
    
    audio_file = f"lot_{lot_id:03d}_dialogue.mp3"
    audio_path = os.path.join(AUDIO_DIR, audio_file)
    with open(audio_path, 'wb') as f:
        f.write(combined_audio)
        
    # 2. Génération audio vitesse lente (-20%)
    print(f"-> Audio lent (-20%)...")
    combined_slow = bytearray()
    slow_ms = 0
    for line in dialogue_data["lignes"]:
        voice = "de-DE-ConradNeural" if line["locuteur"] == "Conrad" else "de-DE-KatjaNeural"
        audio_chunk = await synthesize_line(line["de"], voice, rate="-20%")
        chunk_ms = get_mp3_duration_ms(audio_chunk)
        slow_ms += chunk_ms
        combined_slow.extend(audio_chunk)
        
    slow_dur_s = round(slow_ms / 1000.0, 1)
    slow_size = len(combined_slow)
    slow_checksum = hashlib.sha256(combined_slow).hexdigest()
    
    slow_file = f"lot_{lot_id:03d}_dialogue_slow.mp3"
    slow_path = os.path.join(AUDIO_DIR, slow_file)
    with open(slow_path, 'wb') as f:
        f.write(combined_slow)
        
    # 3. Sauvegarder le JSON synchronisé
    json_file = f"lot_{lot_id:03d}_dialogue.json"
    json_path = os.path.join(MEDIA_DIR, json_file)
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(dialogue_data, f, indent=2, ensure_ascii=False)
        
    # 4. Mettre à jour manifest
    manifest["contents"] = [
        c for c in manifest["contents"]
        if not (c.get("lot_id") == lot_id and c.get("type") == "dialogue")
    ]
    manifest["contents"].append({
        "lot_id": lot_id,
        "type": "dialogue",
        "audio_file": audio_file,
        "audio_slow_file": slow_file,
        "content_json_file": json_file,
        "duration_seconds": int(round(dur_s)),
        "size_bytes": size_bytes,
        "checksum": checksum,
        "checksum_slow": slow_checksum,
        "version": 1,
        "statut_licence": "approuve",
        "source": "Voix natives de-DE-ConradNeural & de-DE-KatjaNeural",
        "created_at": "2026-11-07T12:00:00Z",
        "title_de": meta["title_de"],
        "title_ar": meta["title_ar"],
        "title_fr": meta["title_fr"]
    })
    print(f"[OK] Lot {lot_id:02d} : {dur_s}s (lent: {slow_dur_s}s), taille={size_bytes}b")

async def main():
    with open(PHRASES_PATH, 'r', encoding='utf-8') as f:
        all_phrases = json.load(f)
        
    with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
        manifest = json.load(f)
        
    os.makedirs(AUDIO_DIR, exist_ok=True)
    
    # Générer les dialogues pour les lots 41 à 50 (phrases index 400 à 500)
    for lot_id in range(41, 51):
        start = (lot_id - 1) * 10
        end = start + 10
        phrases_subset = all_phrases[start:end]
        if len(phrases_subset) != 10:
            print(f"Warning: Lot {lot_id} has {len(phrases_subset)} phrases, expected 10!")
        await generate_lot_dialogue(lot_id, phrases_subset, manifest)
        
        # Sauvegarder manifest au fur et à mesure
        with open(MANIFEST_PATH, 'w', encoding='utf-8') as f:
            json.dump(manifest, f, indent=2, ensure_ascii=False)
            
    print("\n>>> LOTS 41 À 50 GÉNÉRÉS AVEC SUCCÈS ! <<<")

if __name__ == "__main__":
    asyncio.run(main())
