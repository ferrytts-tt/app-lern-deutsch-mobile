import av
import hashlib
import json
import os

m4a_path = r"assets\media\audio\lot_001_chanson_suno.m4a"
mp3_path = r"assets\media\audio\lot_001_chanson.mp3"

print("1. Conversion de m4a vers MP3 128kbps via PyAV...")
input_container = av.open(m4a_path)
input_stream = input_container.streams.audio[0]

output_container = av.open(mp3_path, mode='w', format='mp3')
output_stream = output_container.add_stream('mp3', rate=44100)
output_stream.bit_rate = 128000
output_stream.layout = 'stereo'

for frame in input_container.decode(input_stream):
    frame.pts = None
    for packet in output_stream.encode(frame):
        output_container.mux(packet)

for packet in output_stream.encode(None):
    output_container.mux(packet)

input_container.close()
output_container.close()

mp3_size = os.path.getsize(mp3_path)
print(f"-> MP3 généré : {mp3_size} octets")

# Calculer durée exacte
container = av.open(mp3_path)
duration_s = float(container.duration / av.time_base)
container.close()
print(f"-> Durée exacte : {duration_s:.2f} secondes ({int(round(duration_s))}s)")

# SHA-256
with open(mp3_path, "rb") as f:
    mp3_bytes = f.read()
sha256_hash = hashlib.sha256(mp3_bytes).hexdigest()
print(f"-> Checksum SHA-256 : {sha256_hash}")
