import urllib.request
import json

song_id = "427dddbb-acfe-4126-87ee-4abbe1fe48b6"

test_urls = [
    f"https://audiopipe.suno.ai/?item_id={song_id}",
    f"https://cdn1.suno.ai/{song_id}.mp3",
    f"https://cdn2.suno.ai/{song_id}.mp3",
    f"https://studio-api.prod.suno.com/api/clip/{song_id}/mp3",
    f"https://studio-api-prod.suno.com/api/clip/{song_id}/download",
]

for u in test_urls:
    try:
        req = urllib.request.Request(u, headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Referer": "https://suno.com/",
        })
        with urllib.request.urlopen(req) as res:
            print("SUCCESS:", u, "->", res.getcode(), res.getheader("Content-Type"))
    except Exception as e:
        print("FAIL:", u, "->", e)
