import av
import hashlib
import json
import os
import shutil

src_mp3 = r"C:\Users\tahak\.gemini\antigravity\brain\b555cf82-3f5a-4c44-9ede-fd23278d6eb9\.user_uploaded\uploaded_media_1793546253145.mp3"
dest_mp3 = r"c:\Users\tahak\Downloads\app-lern-deutsch-mobile\assets\media\audio\lot_001_chanson.mp3"

# Copy file
shutil.copy2(src_mp3, dest_mp3)
file_size = os.path.getsize(dest_mp3)

# Hash
with open(dest_mp3, "rb") as f:
    mp3_bytes = f.read()
file_hash = hashlib.sha256(mp3_bytes).hexdigest()

# Duration
container = av.open(dest_mp3)
duration_s = float(container.duration / av.time_base)
container.close()

print(f"Fichier copié : {dest_mp3}")
print(f"Taille : {file_size} octets")
print(f"Durée : {duration_s:.2f} secondes (arrondi: {int(round(duration_s))}s)")
print(f"SHA-256 : {file_hash}")
