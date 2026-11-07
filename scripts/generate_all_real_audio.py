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

async def process_dialogue():
    json_path = r"c:\Users\tahak\Downloads\app-lern-deutsch-mobile\assets\media\lot_001_dialogue.json"
    with open(json_path, 'r', encoding='utf-8') as f:
        doc = json.load(f)

    print("--- Génération Dialogue Normal ---")
    combined_audio = bytearray()
    current_ms = 0

    for ligne in doc["lignes"]:
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

    dialogue_mp3_path = r"c:\Users\tahak\Downloads\app-lern-deutsch-mobile\assets\media\audio\lot_001_dialogue.mp3"
    with open(dialogue_mp3_path, 'wb') as f:
        f.write(combined_audio)
    
    dialogue_dur_s = round(current_ms / 1000.0, 1)
    dialogue_size = len(combined_audio)
    dialogue_hash = hashlib.sha256(combined_audio).hexdigest()
    print(f"-> Dialogue généré : {dialogue_dur_s}s, {dialogue_size} octets, hash={dialogue_hash}")

    # Sauvegarder dialogue JSON mis à jour avec timestamps réels
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(doc, f, indent=2, ensure_ascii=False)

    print("\n--- Génération Dialogue Lent (-20%) ---")
    combined_slow = bytearray()
    slow_ms = 0
    for ligne in doc["lignes"]:
        locuteur = ligne["locuteur"]
        text = ligne["de"]
        voice = "de-DE-ConradNeural" if locuteur == "Conrad" else "de-DE-KatjaNeural"
        audio_chunk = await synthesize_line(text, voice, rate="-20%")
        chunk_ms = get_mp3_duration_ms(audio_chunk)
        slow_ms += chunk_ms
        combined_slow.extend(audio_chunk)

    slow_mp3_path = r"c:\Users\tahak\Downloads\app-lern-deutsch-mobile\assets\media\audio\lot_001_dialogue_slow.mp3"
    with open(slow_mp3_path, 'wb') as f:
        f.write(combined_slow)

    slow_dur_s = round(slow_ms / 1000.0, 1)
    slow_size = len(combined_slow)
    slow_hash = hashlib.sha256(combined_slow).hexdigest()
    print(f"-> Dialogue lent généré : {slow_dur_s}s, {slow_size} octets, hash={slow_hash}")

    return {
        "dialogue_dur_s": int(round(dialogue_dur_s)),
        "dialogue_size": dialogue_size,
        "dialogue_hash": dialogue_hash,
        "slow_hash": slow_hash,
    }

async def process_chanson():
    json_path = r"c:\Users\tahak\Downloads\app-lern-deutsch-mobile\assets\media\lot_001_chanson.json"
    with open(json_path, 'r', encoding='utf-8') as f:
        doc = json.load(f)

    print("\n--- Génération Chanson ---")
    combined_audio = bytearray()
    current_ms = 0

    for ligne in doc["lignes"]:
        text = ligne["de"]
        # Alterner Katja et Conrad ou voix mélodieuse
        voice = "de-DE-KatjaNeural"
        print(f"[Chant] {text}")
        audio_chunk = await synthesize_line(text, voice, rate="+5%")
        chunk_ms = get_mp3_duration_ms(audio_chunk)
        
        ligne["debut_ms"] = current_ms
        current_ms += chunk_ms
        ligne["fin_ms"] = current_ms
        combined_audio.extend(audio_chunk)

    chanson_mp3_path = r"c:\Users\tahak\Downloads\app-lern-deutsch-mobile\assets\media\audio\lot_001_chanson.mp3"
    with open(chanson_mp3_path, 'wb') as f:
        f.write(combined_audio)
    
    chanson_dur_s = round(current_ms / 1000.0, 1)
    chanson_size = len(combined_audio)
    chanson_hash = hashlib.sha256(combined_audio).hexdigest()
    print(f"-> Chanson générée : {chanson_dur_s}s, {chanson_size} octets, hash={chanson_hash}")

    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(doc, f, indent=2, ensure_ascii=False)

    return {
        "chanson_dur_s": int(round(chanson_dur_s)),
        "chanson_size": chanson_size,
        "chanson_hash": chanson_hash,
    }

async def update_manifest(d_info, c_info):
    manifest_path = r"c:\Users\tahak\Downloads\app-lern-deutsch-mobile\assets\media\manifest.json"
    with open(manifest_path, 'r', encoding='utf-8') as f:
        manifest = json.load(f)

    for item in manifest["contents"]:
        if item["type"] == "dialogue":
            item["duree_secondes"] = d_info["dialogue_dur_s"]
            item["taille_octets"] = d_info["dialogue_size"]
            item["checksum"] = d_info["dialogue_hash"]
            item["checksum_slow"] = d_info["slow_hash"]
            item["source"] = "Voix natives de-DE-ConradNeural & de-DE-KatjaNeural"
        elif item["type"] == "chanson":
            item["duree_secondes"] = c_info["chanson_dur_s"]
            item["taille_octets"] = c_info["chanson_size"]
            item["checksum"] = c_info["chanson_hash"]
            item["source"] = "Refrain chanté voix native de-DE-KatjaNeural"

    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    print("\nmanifest.json mis à jour avec succès !")

async def main():
    d_info = await process_dialogue()
    c_info = await process_chanson()
    await update_manifest(d_info, c_info)
    print("\nToutes les voix réelles natives allemandes ont été générées avec succès !")

if __name__ == "__main__":
    asyncio.run(main())
