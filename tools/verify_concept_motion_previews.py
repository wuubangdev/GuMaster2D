"""Compare every lossless preview frame with its complete native framebuffer."""
from pathlib import Path
from PIL import Image
import json
import sys

root = Path(__file__).resolve().parents[1]
prefix = sys.argv[1] if len(sys.argv) > 1 else "concept30"
report = {}
for kind, expected in {"motion": 48, "turn": 48, "gameplay": 64, "vertical": 96}.items():
    paths = sorted((root / "artifacts" / f"{prefix}_{kind}").glob("frame*.png"))
    assert len(paths) == expected
    decoded = 0
    mismatches = 0
    with Image.open(root / "artifacts" / f"{prefix}_{kind}.webp") as clip:
        for frame in range(clip.n_frames):
            clip.seek(frame)
            assert clip.size == (1280, 800)
            pixels = clip.convert("RGB").tobytes()
            duration = clip.info["duration"]
            assert duration % 42 == 0
            for repeated in range(duration // 42):
                with Image.open(paths[decoded]) as native:
                    mismatches += pixels != native.convert("RGB").tobytes()
                decoded += 1
    assert decoded == expected and mismatches == 0
    report[kind] = {"native_frames": decoded, "rgb_mismatches": mismatches, "dimensions": [1280, 800]}
output = root / "artifacts" / f"{prefix}_clip_validation.json"
output.write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps(report))
