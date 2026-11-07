import urllib.request
import re

html_path = r"C:\Users\tahak\.gemini\antigravity\brain\b555cf82-3f5a-4c44-9ede-fd23278d6eb9\.system_generated\steps\4812\content.md"
with open(html_path, "r", encoding="utf-8") as f:
    html = f.read()

scripts = re.findall(r'src="(/_next/static/immutable/chunks/[^"]+)"', html)
print("Found scripts:", len(scripts))

for s in scripts:
    url = "https://suno.com" + s
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"})
        with urllib.request.urlopen(req) as res:
            content = res.read().decode("utf-8", errors="ignore")
            if "m4a-opus" in content or "d2lwuy8qc234o3" in content:
                print(f"Match in {s}!")
                idx = content.find("m4a-opus")
                print(content[max(0, idx - 100):min(len(content), idx + 200)])
    except Exception as e:
        pass
