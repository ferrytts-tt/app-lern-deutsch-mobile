import os
import wave
import struct

# Let's inspect the downloaded m4a
m4a_path = r"assets\media\audio\lot_001_chanson_suno.m4a"
size = os.path.getsize(m4a_path)
print("m4a size:", size)

# Look at tags or atoms in m4a
with open(m4a_path, "rb") as f:
    header = f.read(64)
    print("Header bytes:", header[:16])
