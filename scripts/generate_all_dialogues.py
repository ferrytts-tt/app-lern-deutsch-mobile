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
    1: {"title_de": "Zufälliges Treffen im Regen", "title_fr": "Rencontre fortuite sous la pluie", "title_ar": "لقاء بالصدفة تحت المطر"},
    2: {"title_de": "Stress im Büro", "title_fr": "Coup de chaud au bureau", "title_ar": "ضغط في العمل"},
    3: {"title_de": "Kinoabend mit Freunden", "title_fr": "Soirée ciné entre amis", "title_ar": "سهرة سينما مع الأصدقاء"},
    4: {"title_de": "Gefühlschaos vor dem Auftritt", "title_fr": "Tourbillon d'émotions avant le direct", "title_ar": "مشاعر متضاربة قبل العرض"},
    5: {"title_de": "Im gemütlichen Café", "title_fr": "Au café du coin", "title_ar": "في المقهى اللطيف"},
    6: {"title_de": "Auf dem Bürgeramt", "title_fr": "Au bureau des formalités", "title_ar": "في مكتب الإدارة والمواعيد"},
    7: {"title_de": "Krank im Bett", "title_fr": "Coup de froid au lit", "title_ar": "مريض في الفراش"},
    8: {"title_de": "Schlechte Verbindung", "title_fr": "Mauvaise réception au téléphone", "title_ar": "اتصال هاتفي مشوش"},
    9: {"title_de": "Chaos am Hauptbahnhof", "title_fr": "Pagaille à la gare centrale", "title_ar": "فوضى في محطة القطار"},
    10: {"title_de": "Diskussion über das Wochenende", "title_fr": "Débat animé sur le week-end", "title_ar": "نقاش حول عطلة الأسبوع"},
    11: {"title_de": "Unter vier Augen", "title_fr": "Entre quatre yeux", "title_ar": "حديث على انفراد"},
    12: {"title_de": "Wichtige Aussprache", "title_fr": "Explication franche", "title_ar": "توضيح هام بين صديقين"},
    13: {"title_de": "Hausarbeit und Einkäufe", "title_fr": "Ménage et corvées à la maison", "title_ar": "أشغال البيت والتبضع"},
    14: {"title_de": "Finanzen am Monatsende", "title_fr": "Fin de mois difficile", "title_ar": "نهاية الشهر والميزانية"},
    15: {"title_de": "Fit bleiben nach der Arbeit", "title_fr": "Garder la forme après le boulot", "title_ar": "اللياقة البدنية بعد العمل"},
    16: {"title_de": "Aufgebrachte Reaktionen", "title_fr": "Coups de gueule du quotidien", "title_ar": "انفعالات يومية"},
    17: {"title_de": "Bürokratie im Unternehmen", "title_fr": "Formalités administratives au bureau", "title_ar": "إجراءات إدارية في العمل"},
    18: {"title_de": "Ein harter Arbeitstag", "title_fr": "Une rude journée de travail", "title_ar": "يوم عمل شاق"},
    19: {"title_de": "Der tägliche Rhythmus", "title_fr": "Le rythme de tous les jours", "title_ar": "روتين الحياة اليومية"},
    20: {"title_de": "Kaffee und Kuchen geht auf mich", "title_fr": "C'est ma tournée !", "title_ar": "حسابك علي اليوم"},
    21: {"title_de": "Zwischen den Stühlen", "title_fr": "Un cœur qui balance", "title_ar": "تردد وحيرة في الاختيار"},
    22: {"title_de": "Ein gewagter Plan", "title_fr": "Un plan qui laisse perplexe", "title_ar": "خطة غامضة ومفاجئة"},
    23: {"title_de": "Redensarten im Alltag", "title_fr": "Expressions courantes et sagesses", "title_ar": "أمثال وتعبيرات شعبية"},
    24: {"title_de": "Grenzen setzen", "title_fr": "Mettre les points sur les i", "title_ar": "وضع حد للأمور"},
    25: {"title_de": "Bildhafte Sprache im Gespräch", "title_fr": "Images et métaphores allemandes", "title_ar": "تعابير تصويرية معبرة"},
    26: {"title_de": "Nerven und Bammel", "title_fr": "Peur bleue et nerfs à vif", "title_ar": "توتر وقلق يومي"},
    27: {"title_de": "Meinungen und Daumen drücken", "title_fr": "Points de vue et encouragements", "title_ar": "آراء متبادلة وتمنيات التوفيق"},
    28: {"title_de": "Übung macht den Meister", "title_fr": "C'est en forgeant qu'on devient forgeron", "title_ar": "التدريب يصنع الأستاذ"},
    29: {"title_de": "Kluge Ratschläge im Leben", "title_fr": "Sagesses et conseils avisés", "title_ar": "حكم ونصائح حكيمة"},
    30: {"title_de": "Ende gut, alles gut!", "title_fr": "Tout est bien qui finit bien !", "title_ar": "نهاية سعيدة والحمد لله"},
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
            
            if version_bits == 3: # MPEG 1
                srs = [44100, 48000, 32000]
                rates = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0]
                samples_per_frame = 1152
                coeff = 144
            else: # MPEG 2 or 2.5
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
    print(f"[DIALOGUE] Generation Lot {lot_id:02d} : {meta['title_de']}")
    print(f"==========================================")
    
    lignes = []
    # Créer les répliques en alternant Conrad et Katja
    for i, p in enumerate(phrases_subset):
        locuteur = "Conrad" if i % 2 == 0 else "Katja"
        lignes.append({
            "locuteur": locuteur,
            "de": p["de"],
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
        "created_at": "2026-11-02T12:00:00Z",
        "title_de": meta["title_de"],
        "title_ar": meta["title_ar"],
        "title_fr": meta["title_fr"]
    })
    print(f"[OK] Lot {lot_id:02d} OK : {dur_s}s (lent: {slow_dur_s}s), taille={size_bytes}b")

async def main():
    with open(PHRASES_PATH, 'r', encoding='utf-8') as f:
        all_phrases = json.load(f)
        
    with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
        manifest = json.load(f)
        
    os.makedirs(AUDIO_DIR, exist_ok=True)
    
    # Générer les dialogues pour les lots 4 à 30
    for lot_id in range(4, 31):
        start = (lot_id - 1) * 10
        end = start + 10
        phrases_subset = all_phrases[start:end]
        await generate_lot_dialogue(lot_id, phrases_subset, manifest)
        
        # Sauvegarder manifest au fur et à mesure
        with open(MANIFEST_PATH, 'w', encoding='utf-8') as f:
            json.dump(manifest, f, indent=2, ensure_ascii=False)
            
    print("\n>>> ALL 30 DIALOGUES GENERATED SUCCESSFULLY! <<<")

if __name__ == "__main__":
    asyncio.run(main())
