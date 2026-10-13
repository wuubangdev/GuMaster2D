#!/usr/bin/env python3
"""Check authored atlas margins, opaque pixel clusters and cosmetic identities."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets/pixel/characters"
data = json.loads((ASSETS / "manifest.json").read_text(encoding="utf-8"))
failures = []
hashes = set()
frames = 0
anchors = 0
locomotion_clips = 0
expected_clips = {"idle": 4, "walk": 8, "run": 8, "attack": 8, "defend": 4,
                  "cast": 6, "channel": 6, "dash": 4, "hit": 4, "death": 6, "respawn": 6}
if data.get("cell_size") != [80, 80] or data.get("pivot") != [40, 68]:
    failures.append("Cell/pivot contract changed")
if len(data.get("appearances", {})) != 36:
    failures.append("Cosmetic identity count changed")
for identity, entry in data["appearances"].items():
    path = ASSETS / Path(entry["path"]).name
    hashes.add(hashlib.sha256(path.read_bytes()).hexdigest())
    atlas = Image.open(path).convert("RGBA")
    values = atlas.getchannel("A").getcolors(3)
    if values is None or {v for _, v in values} != {0, 255}:
        failures.append(identity + ": nonbinary alpha")
    if set(entry["frames"]) != set(expected_clips):
        failures.append(identity + ": semantic clip contract changed")
    for clip, directions in entry["frames"].items():
        if len(directions) != 8:
            failures.append(f"{identity}/{clip}: expected eight views")
        for direction, ids in enumerate(directions):
            if len(ids) != expected_clips.get(clip, -1):
                failures.append(f"{identity}/{clip}/{direction}: frame count changed")
            poses = set()
            for frame, index in enumerate(ids):
                x, y = index % entry["columns"] * 80, index // entry["columns"] * 80
                cell = atlas.crop((x, y, x + 80, y + 80))
                bounds = cell.getbbox()
                if bounds is None or bounds[0] < 1 or bounds[1] < 1 or bounds[2] > 79 or bounds[3] > 79:
                    failures.append(f"{identity}/{clip}/{direction}/{frame}: clipped {bounds}")
                for side in ("L", "R"):
                    point = entry["hands"][clip][direction][frame][side]
                    if len(point) != 2 or not all(isinstance(n, int) and 0 <= n < 80 for n in point):
                        failures.append(f"{identity}/{clip}/{direction}/{frame}/{side}: invalid anchor")
                    elif cell.getpixel(tuple(point))[3] != 255:
                        failures.append(f"{identity}/{clip}/{direction}/{frame}/{side}: anchor misses drawn hand")
                    anchors += 1
                poses.add(hashlib.sha256(cell.tobytes()).hexdigest())
                frames += 1
            if clip in ("walk", "run"):
                locomotion_clips += 1
                if len(poses) < 6:
                    failures.append(f"{identity}/{clip}/{direction}: fewer than six distinct gait poses")
    # Both eyes and highlights must survive the hair layer on the front pose.
    index = entry["frames"]["idle"][0][0]
    x, y = index % entry["columns"] * 80, index // entry["columns"] * 80
    cell = atlas.crop((x, y, x + 80, y + 80))
    for eye_x in (36, 42):
        eye = cell.crop((eye_x, 33, eye_x + 3, 36))
        colors = {color for _, color in eye.getcolors(9)}
        if (25, 40, 55, 255) not in colors or (255, 248, 218, 255) not in colors:
            failures.append(identity + ": front eye/catchlight hidden by fringe")
    atlas.close()
if len(hashes) != 36:
    failures.append(f"Distinct cosmetic atlases: {len(hashes)}/36")
for failure in failures[:40]:
    print(failure)
print(f"Hand attachments: {anchors}; distinct locomotion clips: {locomotion_clips}; visible front eyes: 36 identities.")
print(f"Pixel atlas authoring: {36} identities; {frames} frame bounds; binary alpha; {len(failures)} failures.")
raise SystemExit(1 if failures else 0)
