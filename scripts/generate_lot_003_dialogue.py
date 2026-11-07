import asyncio
import hashlib
import json
import os
import edge_tts

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

async def generate_lot_3_dialogue():
    base_dir = r"c:\Users\tahak\Downloads\app-lern-deutsch-mobile"
    json_path = os.path.join(base_dir, "assets", "media", "lot_003_dialogue.json")
    audio_dir = os.path.join(base_dir, "assets", "media", "audio")
    os.makedirs(audio_dir, exist_ok=True)

    dialogue_data = {
        "lot_id": 3,
        "type": "dialogue",
        "title_de": "Kinoabend mit Freunden",
        "title_ar": "سهرة سينما مع الأصدقاء",
        "title_fr": "Soirée ciné entre amis",
        "lignes": [
            {
                "locuteur": "Conrad",
                "de": "Katja! Hast du Bock auf Kino?",
                "ar": "كاتيا! عندك رغبة نروح السينما؟",
                "fr": "Katja ! Ça te dit un ciné ?",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_021"
            },
            {
                "locuteur": "Katja",
                "de": "Eigentlich nicht so, ich bleib heut lieber daheim.",
                "ar": "في الحقيقة ليس كثيراً، أفضّل أن أبقى في البيت اليوم.",
                "fr": "Pas vraiment, je préfère rester chez moi aujourd'hui.",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_027"
            },
            {
                "locuteur": "Conrad",
                "de": "Das meinst du jetzt nicht ernst, oder? Der Film ist genial!",
                "ar": "ما تقصدين هذا فعلاً، صح؟ الفيلم رائع جداً!",
                "fr": "Tu déconnes là, j'espère ? Le film est génial !",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_026"
            },
            {
                "locuteur": "Katja",
                "de": "Na gut... aber die Kinokarten sind ganz schön teuer.",
                "ar": "حسناً... لكن تذاكر السينما باهظة الثمن.",
                "fr": "Bon d'accord... mais les places de ciné sont super chères.",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": None
            },
            {
                "locuteur": "Conrad",
                "de": "Keine Sorge, geht auf mich!",
                "ar": "لا تقلقي، عليّ الحساب!",
                "fr": "T'inquiète, c'est pour moi !",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_029"
            },
            {
                "locuteur": "Katja",
                "de": "Echt? Danke! Tust du mir mal 'nen Gefallen und reservierst Plätze?",
                "ar": "حقاً؟ شكراً! تعمل لي معروفاً وتحجز مقاعد؟",
                "fr": "Vraiment ? Merci ! Tu peux me rendre un service et réserver des places ?",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_028"
            },
            {
                "locuteur": "Conrad",
                "de": "Klar, schon erledigt! Kommst du mit zum Eingang?",
                "ar": "بالتأكيد، تم بالفعل! هل تأتين معي إلى المدخل؟",
                "fr": "Bien sûr, c'est fait ! Tu viens avec moi vers l'entrée ?",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_025"
            },
            {
                "locuteur": "Katja",
                "de": "Ja, sofort! Aber ich bin ein bisschen spät dran.",
                "ar": "نعم، فوراً! لكني متأخرة قليلاً.",
                "fr": "Oui, tout de suite ! Mais je suis un peu à la bourre.",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_023"
            },
            {
                "locuteur": "Conrad",
                "de": "Kein Problem, nimm dir Zeit, ich warte hier.",
                "ar": "لا مشكلة، خذي وقتك، سأنتظر هنا.",
                "fr": "Pas de souci, prends ton temps, j'attends ici.",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": None
            },
            {
                "locuteur": "Katja",
                "de": "Ich sehe dich schon da vorne! Bin gleich da!",
                "ar": "أراك هناك في الأمام! أنا قادمة بعد قليل!",
                "fr": "Je te vois là-bas devant ! J'arrive tout de suite !",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_022"
            },
            {
                "locuteur": "Conrad",
                "de": "Was für ein toller Film! Das war ein mega Abend!",
                "ar": "يا له من فيلم رائع! كانت أمسية رائعة جداً!",
                "fr": "Quel film incroyable ! C'était une soirée trop géniale !",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_024"
            },
            {
                "locuteur": "Katja",
                "de": "Fand ich auch! Wir telefonieren später, ja?",
                "ar": "رأيي من رأيك! نتكلم بالهاتف لاحقاً، اتفقنا؟",
                "fr": "Carrément ! On s'appelle plus tard, ça marche ?",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_030"
            },
            {
                "locuteur": "Conrad",
                "de": "Abgemacht! Schlaf gut, Katja!",
                "ar": "اتفقنا! نوماً هنيئاً يا كاتيا!",
                "fr": "Ça marche ! Dors bien, Katja !",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": None
            }
        ]
    }

    print("=== Génération du Dialogue Lot 3 (Vitesse Normale) ===")
    combined_audio = bytearray()
    current_ms = 0

    for ligne in dialogue_data["lignes"]:
        locuteur = ligne["locuteur"]
        text = ligne["de"]
        voice = "de-DE-ConradNeural" if locuteur == "Conrad" else "de-DE-KatjaNeural"
        print(f"[{locuteur}] {text}")
        audio_chunk = await synthesize_line(text, voice, rate="+0%")
        chunk_ms = get_mp3_duration_ms(audio_chunk)
        
        ligne["debut_ms"] = current_ms
        current_ms += chunk_ms
        ligne["fin_ms"] = current_ms
        combined_audio.extend(audio_chunk)

    dialogue_mp3_path = os.path.join(audio_dir, "lot_003_dialogue.mp3")
    with open(dialogue_mp3_path, 'wb') as f:
        f.write(combined_audio)
    
    dialogue_dur_s = round(current_ms / 1000.0, 1)
    dialogue_size = len(combined_audio)
    dialogue_hash = hashlib.sha256(combined_audio).hexdigest()
    print(f"-> Dialogue Lot 3 Normal généré : {dialogue_dur_s}s, {dialogue_size} octets, hash={dialogue_hash}")

    # Sauvegarder dialogue JSON avec timestamps exacts
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(dialogue_data, f, indent=2, ensure_ascii=False)
    print(f"-> JSON sauvegardé : {json_path}")

    print("\n=== Génération du Dialogue Lot 3 (Vitesse Lente -20%) ===")
    combined_slow = bytearray()
    slow_ms = 0
    for ligne in dialogue_data["lignes"]:
        locuteur = ligne["locuteur"]
        text = ligne["de"]
        voice = "de-DE-ConradNeural" if locuteur == "Conrad" else "de-DE-KatjaNeural"
        audio_chunk = await synthesize_line(text, voice, rate="-20%")
        chunk_ms = get_mp3_duration_ms(audio_chunk)
        slow_ms += chunk_ms
        combined_slow.extend(audio_chunk)

    slow_mp3_path = os.path.join(audio_dir, "lot_003_dialogue_slow.mp3")
    with open(slow_mp3_path, 'wb') as f:
        f.write(combined_slow)

    slow_dur_s = round(slow_ms / 1000.0, 1)
    slow_size = len(combined_slow)
    slow_hash = hashlib.sha256(combined_slow).hexdigest()
    print(f"-> Dialogue Lot 3 Lent généré : {slow_dur_s}s, {slow_size} octets, hash={slow_hash}")

    # Mettre à jour manifest.json
    manifest_path = os.path.join(base_dir, "assets", "media", "manifest.json")
    with open(manifest_path, 'r', encoding='utf-8') as f:
        manifest = json.load(f)

    # Nettoyer entrée existante éventuelle
    manifest["contents"] = [c for c in manifest["contents"] if not (c.get("lot_id") == 3 and c.get("type") == "dialogue")]

    manifest["contents"].append({
        "lot_id": 3,
        "type": "dialogue",
        "audio_file": "lot_003_dialogue.mp3",
        "audio_slow_file": "lot_003_dialogue_slow.mp3",
        "content_json_file": "lot_003_dialogue.json",
        "duration_seconds": int(round(dialogue_dur_s)),
        "size_bytes": dialogue_size,
        "checksum": dialogue_hash,
        "checksum_slow": slow_hash,
        "version": 1,
        "statut_licence": "approuve",
        "source": "Voix natives de-DE-ConradNeural & de-DE-KatjaNeural",
        "created_at": "2026-11-01T22:50:00Z",
        "title_de": "Kinoabend mit Freunden",
        "title_ar": "سهرة سينما مع الأصدقاء",
        "title_fr": "Soirée ciné entre amis"
    })

    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    print("-> manifest.json mis à jour avec le dialogue du Lot 3 !")

if __name__ == "__main__":
    asyncio.run(generate_lot_3_dialogue())
