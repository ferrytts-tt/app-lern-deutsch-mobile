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

async def generate_lot_2_dialogue():
    base_dir = r"c:\Users\tahak\Downloads\app-lern-deutsch-mobile"
    json_path = os.path.join(base_dir, "assets", "media", "lot_002_dialogue.json")
    audio_dir = os.path.join(base_dir, "assets", "media", "audio")
    os.makedirs(audio_dir, exist_ok=True)

    dialogue_data = {
        "lot_id": 2,
        "type": "dialogue",
        "title_de": "Stress im Büro",
        "title_ar": "ضغط في العمل",
        "title_fr": "Coup de chaud au bureau",
        "lignes": [
            {
                "locuteur": "Conrad",
                "de": "Katja! Hast du mal kurz Zeit?",
                "ar": "كاتيا! هل عندك وقت قصير؟",
                "fr": "Katja ! T'as deux minutes ?",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_015"
            },
            {
                "locuteur": "Katja",
                "de": "Eigentlich nicht, ich hab heute echt viel um die Ohren.",
                "ar": "في الحقيقة لا، عندي اليوم أشغال كثيرة جداً.",
                "fr": "Pas vraiment, j'en ai par-dessus la tête aujourd'hui.",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_011"
            },
            {
                "locuteur": "Conrad",
                "de": "Pass auf: Können wir den Termin schieben?",
                "ar": "اسمعي: هل نؤجل الموعد؟",
                "fr": "Écoute : on peut décaler le rendez-vous ?",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_012"
            },
            {
                "locuteur": "Katja",
                "de": "Gute Idee! Der Chef hat heute voll schlechte Laune.",
                "ar": "فكرة ممتازة! مزاج المدير سيئ جداً اليوم.",
                "fr": "Bonne idée ! Le patron est d'une humeur massacrante aujourd'hui.",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_017"
            },
            {
                "locuteur": "Conrad",
                "de": "Stimmt. Und gestern warst du auch nicht da?",
                "ar": "صحيح. وبالأمس لم تكوني هنا أيضاً؟",
                "fr": "C'est vrai. Et hier tu n'étais pas là non plus ?",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": None
            },
            {
                "locuteur": "Katja",
                "de": "Genau, ich hab mich krankgemeldet.",
                "ar": "بالضبط، بلّغت عن مرضي.",
                "fr": "Exact, je me suis mise en arrêt maladie.",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_016"
            },
            {
                "locuteur": "Conrad",
                "de": "Verstehe. Und das Projekt? Das schaff ich bis morgen nicht.",
                "ar": "أفهمك. وماذا عن المشروع؟ لن أنجز هذا قبل الغد.",
                "fr": "Je comprends. Et le projet ? J'y arriverai jamais d'ici demain.",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_014"
            },
            {
                "locuteur": "Katja",
                "de": "Ich helfe dir dabei, das habe ich dir doch versprochen!",
                "ar": "سأساعدك في ذلك، لقد وعدتك بذلك!",
                "fr": "Je vais t'aider pour ça, je te l'avais promis !",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": None
            },
            {
                "locuteur": "Conrad",
                "de": "Ach, hab ich total vergessen, sorry!",
                "ar": "أوه، نسيت تماماً، آسف!",
                "fr": "Ah, j'ai complètement zappé, désolé !",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_018"
            },
            {
                "locuteur": "Katja",
                "de": "Kein Problem, das klären wir später.",
                "ar": "لا مشكلة، نتكلم عن هذا ونحسمه لاحقاً.",
                "fr": "Pas de problème, on règle ça plus tard.",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_019"
            },
            {
                "locuteur": "Conrad",
                "de": "Danke dir, du hast mir echt den Tag gerettet!",
                "ar": "شكراً لكِ، أنقذتِ يومي بالفعل!",
                "fr": "Merci à toi, tu m'as vraiment sauvé la mise !",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_020"
            },
            {
                "locuteur": "Katja",
                "de": "Gern geschehen! Ich mach gleich Feierabend.",
                "ar": "على الرحب والسعة! سأنهي دوامي بعد قليل.",
                "fr": "De rien ! Je débauche bientôt.",
                "debut_ms": 0,
                "fin_ms": 0,
                "phrase_id": "phrase_013"
            }
        ]
    }

    print("=== Génération du Dialogue Lot 2 (Vitesse Normale) ===")
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

    dialogue_mp3_path = os.path.join(audio_dir, "lot_002_dialogue.mp3")
    with open(dialogue_mp3_path, 'wb') as f:
        f.write(combined_audio)
    
    dialogue_dur_s = round(current_ms / 1000.0, 1)
    dialogue_size = len(combined_audio)
    dialogue_hash = hashlib.sha256(combined_audio).hexdigest()
    print(f"-> Dialogue Lot 2 Normal généré : {dialogue_dur_s}s, {dialogue_size} octets, hash={dialogue_hash}")

    # Sauvegarder dialogue JSON avec timestamps exacts
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(dialogue_data, f, indent=2, ensure_ascii=False)
    print(f"-> JSON sauvegardé : {json_path}")

    print("\n=== Génération du Dialogue Lot 2 (Vitesse Lente -20%) ===")
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

    slow_mp3_path = os.path.join(audio_dir, "lot_002_dialogue_slow.mp3")
    with open(slow_mp3_path, 'wb') as f:
        f.write(combined_slow)

    slow_dur_s = round(slow_ms / 1000.0, 1)
    slow_size = len(combined_slow)
    slow_hash = hashlib.sha256(combined_slow).hexdigest()
    print(f"-> Dialogue Lot 2 Lent généré : {slow_dur_s}s, {slow_size} octets, hash={slow_hash}")

    # Mettre à jour manifest.json
    manifest_path = os.path.join(base_dir, "assets", "media", "manifest.json")
    with open(manifest_path, 'r', encoding='utf-8') as f:
        manifest = json.load(f)

    # Vérifier si lot 2 dialogue existe déjà
    manifest["contents"] = [c for c in manifest["contents"] if not (c.get("lot_id") == 2 and c.get("type") == "dialogue")]

    manifest["contents"].append({
        "lot_id": 2,
        "type": "dialogue",
        "audio_file": "lot_002_dialogue.mp3",
        "audio_slow_file": "lot_002_dialogue_slow.mp3",
        "content_json_file": "lot_002_dialogue.json",
        "duration_seconds": int(round(dialogue_dur_s)),
        "size_bytes": dialogue_size,
        "checksum": dialogue_hash,
        "checksum_slow": slow_hash,
        "version": 1,
        "statut_licence": "approuve",
        "source": "Voix natives de-DE-ConradNeural & de-DE-KatjaNeural",
        "created_at": "2026-11-01T15:15:00Z",
        "title_de": "Stress im Büro",
        "title_ar": "ضغط في العمل",
        "title_fr": "Coup de chaud au bureau"
    })

    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    print("-> manifest.json mis à jour avec le dialogue du Lot 2 !")

if __name__ == "__main__":
    asyncio.run(generate_lot_2_dialogue())
