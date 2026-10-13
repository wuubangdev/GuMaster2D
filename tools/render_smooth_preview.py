"""Encode actual native motion frames with bounded memory, without resampling art.

The bundled Pillow WebP encoder streams all 60Hz frames losslessly. The GIF
review selects every second native frame at 30Hz and uses one shared palette.
Neither export is an engine performance benchmark.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image, _webp

ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / 'artifacts'
record = json.loads((ARTIFACTS / 'ink19_motion_capture.json').read_text())
paths = sorted((ARTIFACTS / 'smooth_motion').glob('frame*.png'))
assert record['revision'] == 'ink19'
assert record['renderer'] == 'GuIllustratedCharacterView'
assert record['frames'] == len(paths) == 600 and record['sample_rate'] == 60
assert record['accepted_slots'] == [1, 2, 3, 4]
assert record['authority_unchanged_by_preview']
size = (1280, 800)

# Use the same native encoder arguments as the installed Pillow _save_all,
# streaming one image at a time instead of retaining 600 RGBA frame buffers.
encoder = _webp.WebPAnimEncoder(size, 0xFF000000, 0, False, 9, 17, False, False)
for index, path in enumerate(paths):
    with Image.open(path) as source:
        assert source.size == size
        frame = source.convert('RGBA')
        encoder.add(frame.getim(), round(index * 1000 / 60), True, 60, 100, 0)
    if (index + 1) % 150 == 0:
        print(f'WEBP_NATIVE_FRAME {index + 1}/600', flush=True)
encoder.add(None, 10000, True, 60, 100, 0)
webp = ARTIFACTS / 'ink19_motion.webp'
webp.write_bytes(encoder.assemble('', '', ''))

palette_source = Image.new('RGB', (1280, 800 * 8))
for index in range(8):
    with Image.open(paths[index * len(paths) // 8]) as source:
        palette_source.paste(source.convert('RGB'), (0, index * 800))
palette = palette_source.quantize(colors=256)
frames = []
for path in paths[::2]:
    with Image.open(path) as source:
        frames.append(source.convert('RGB').quantize(palette=palette, dither=Image.Dither.NONE))
durations = [(round((i + 1) * 100 / 30) - round(i * 100 / 30)) * 10 for i in range(len(frames))]
gif = ARTIFACTS / 'ink19_motion.gif'
frames[0].save(gif, save_all=True, append_images=frames[1:], duration=durations, loop=0, optimize=True, disposal=1)
assert sum(durations) == 10000
with Image.open(webp) as encoded:
    assert encoded.size == size and encoded.is_animated
    encoded.seek(0)
    with Image.open(paths[0]) as source:
        assert encoded.convert('RGB').tobytes() == source.convert('RGB').tobytes()
    encoded.seek(encoded.n_frames - 1)
    with Image.open(paths[-1]) as source:
        assert encoded.convert('RGB').tobytes() == source.convert('RGB').tobytes()
    encoded_frames = encoded.n_frames
report = {
    'revision': 'ink19', 'native_frames': len(paths), 'native_sample_rate': 60,
    'size': list(size), 'duration_ms': 10000, 'webp_lossless': True,
    'webp_encoded_frames': encoded_frames, 'gif_selected_frames': len(frames),
    'gif_sample_rate': 30, 'source': 'Full native Godot framebuffer; no generated or interpolated image frames',
    'files': {p.name: {'bytes': p.stat().st_size, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in (webp, gif)},
}
(ARTIFACTS / 'ink19_preview_encode.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report))
print('SMOOTH_PREVIEW_OK 600 native60Hz frames; lossless WebP; 30Hz GIF; 10000ms', flush=True)
