"""Encode only native directional-motion frames; no generated/interpolated images."""
from pathlib import Path
import hashlib
import json
from PIL import Image, _webp

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'artifacts'
record = json.loads((ART / 'ink19_turn_capture.json').read_text())
paths = sorted((ART / 'directional_motion').glob('frame*.png'))
assert record['revision'] == 'ink19'
assert record['frames'] == len(paths) == 240 and record['sample_rate'] == 60
size = (1280, 800)
encoder = _webp.WebPAnimEncoder(size, 0xFF000000, 0, False, 9, 17, False, False)
for i, path in enumerate(paths):
    with Image.open(path) as source:
        assert source.size == size
        encoder.add(source.convert('RGBA').getim(), round(i * 1000 / 60), True, 60, 100, 0)
encoder.add(None, 4000, True, 60, 100, 0)
webp = ART / 'ink19_turn_motion.webp'
webp.write_bytes(encoder.assemble('', '', ''))
palette_source = Image.new('RGB', (1280, 800 * 6))
for i in range(6):
    with Image.open(paths[i * 30]) as source:
        palette_source.paste(source.convert('RGB'), (0, i * 800))
palette = palette_source.quantize(colors=256)
frames = []
for path in paths[::2]:
    with Image.open(path) as source:
        frames.append(source.convert('RGB').quantize(palette=palette, dither=Image.Dither.NONE))
durations = [(round((i + 1) * 100 / 30) - round(i * 100 / 30)) * 10 for i in range(len(frames))]
gif = ART / 'ink19_turn_motion.gif'
frames[0].save(gif, save_all=True, append_images=frames[1:], duration=durations, loop=0, optimize=True, disposal=1)
with Image.open(webp) as encoded:
    assert encoded.n_frames == 240
    for index in (0, 239):
        encoded.seek(index)
        with Image.open(paths[index]) as source:
            assert encoded.convert('RGB').tobytes() == source.convert('RGB').tobytes()
report = {'revision': 'ink19', 'native_frames': 240, 'native_sample_rate': 60,
          'duration_ms': 4000, 'webp_lossless': True, 'gif_selected_frames': 120,
          'files': {p.name: {'bytes': p.stat().st_size, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in (webp, gif)}}
(ART / 'ink19_turn_preview_encode.json').write_text(json.dumps(report, indent=2))
print('TURN_PREVIEW_OK 240 native60Hz frames; lossless WebP; 30Hz GIF; 4000ms')
