import asyncio
import json
import os
import edge_tts

VOICES = {
    'male': 'de-DE-ConradNeural',
    'female': 'de-DE-KatjaNeural',
}

DEST_DIRS = [
    'assets/audio',
    'web/audio',
    'build/web/audio',
]

async def generate_phrase(p, sem):
    async with sem:
        phrase_id = p.get('id')
        text = (p.get('de_parle') or p.get('de') or p.get('de_standard') or '').strip()
        if not phrase_id or not text:
            return

        for gender, voice in VOICES.items():
            # Check if all destination files exist
            all_exist = True
            for dest in DEST_DIRS:
                target_path = os.path.join(dest, gender, f'{phrase_id}.mp3')
                if not os.path.exists(target_path) or os.path.getsize(target_path) < 100:
                    all_exist = False
                    break
            
            if all_exist:
                continue

            try:
                comm = edge_tts.Communicate(text, voice, rate="+0%")
                data = bytearray()
                async for chunk in comm.stream():
                    if chunk["type"] == "audio":
                        data.extend(chunk["data"])

                if len(data) > 0:
                    for dest in DEST_DIRS:
                        folder = os.path.join(dest, gender)
                        os.makedirs(folder, exist_ok=True)
                        target_path = os.path.join(folder, f'{phrase_id}.mp3')
                        with open(target_path, 'wb') as f:
                            f.write(data)
                    print(f"[{gender}] {phrase_id}: {text[:30]} ({len(data)} bytes)")
            except Exception as e:
                print(f"Error {phrase_id} ({gender}): {e}")

async def main():
    phrases_path = os.path.join('assets', 'data', 'phrases.json')
    with open(phrases_path, 'r', encoding='utf-8') as f:
        phrases = json.load(f)

    # Filter for phrases starting from 301
    missing_phrases = []
    for p in phrases:
        pid = p.get('id', '')
        if pid.startswith('phrase_'):
            try:
                num = int(pid.replace('phrase_', ''))
                if num > 300:
                    missing_phrases.append(p)
            except ValueError:
                pass

    print(f"Found {len(missing_phrases)} phrases to check and generate (301-500)...")
    sem = asyncio.Semaphore(8) # 8 concurrent requests for fast, reliable generation
    tasks = [generate_phrase(p, sem) for p in missing_phrases]
    await asyncio.gather(*tasks)
    print("All phrases audio generated successfully!")

if __name__ == '__main__':
    asyncio.run(main())
