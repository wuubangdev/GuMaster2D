"""Lossless encoding of entire native framebuffers, plus RGB roundtrip checks."""
from pathlib import Path
from PIL import Image
import json
import sys

root = Path(__file__).resolve().parents[1]
prefix = sys.argv[1] if len(sys.argv)>1 else 'concept31'
report = {}
for weapon, duration in {'sword':18, 'spear':20, 'unarmed':13}.items():
    paths = sorted((root/'artifacts'/f'{prefix}_combat'/weapon).glob('frame*.png'))
    assert len(paths) == 48
    frames = [Image.open(path).convert('RGB') for path in paths]
    assert all(frame.size == (1280,800) for frame in frames)
    output = root/'artifacts'/f'{prefix}_combat_{weapon}.webp'
    frames[0].save(output,save_all=True,append_images=frames[1:],duration=duration,loop=0,lossless=True,method=6)
    decoded = 0
    with Image.open(output) as clip:
        for i in range(clip.n_frames):
            clip.seek(i)
            pixels = clip.convert('RGB').tobytes()
            assert clip.info['duration'] % duration == 0
            for _ in range(clip.info['duration']//duration):
                assert pixels == frames[decoded].tobytes()
                decoded += 1
    assert decoded == 48
    report[weapon]={'native_frames':48,'rgb_mismatches':0,'frame_duration_ms':duration,'dimensions':[1280,800]}
    print(f'{weapon}: 48 frames, lossless RGB verified')
(root/'artifacts'/f'{prefix}_combat_clip_validation.json').write_text(json.dumps(report,indent=2))
