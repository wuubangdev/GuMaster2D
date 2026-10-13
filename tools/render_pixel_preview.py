"""Encode native Godot pixel-review frames. Keeps their full native resolution."""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
record = json.loads((ROOT/'artifacts/pixel_motion_capture.json').read_text())
paths = sorted((ROOT/'artifacts/pixel_motion').glob('frame_*.png'))
assert len(paths) == record['frames'] == 96
images = []
for path in paths:
    with Image.open(path) as source:
        assert source.size == (1280,800)
        images.append(source.convert('RGB'))
palette_source = Image.new('RGB',(1280,800*6))
for index,frame in enumerate((0,20,40,50,72,88)):
    palette_source.paste(images[frame],(0,index*800))
palette = palette_source.quantize(colors=224)
indexed = [frame.quantize(palette=palette,dither=Image.Dither.NONE) for frame in images]
destination = ROOT/'artifacts/pixel_gameplay_motion.gif'
durations = [(round((i+1)*100/24)-round(i*100/24))*10 for i in range(len(images))]
indexed[0].save(destination,save_all=True,append_images=indexed[1:],duration=durations,loop=0,optimize=True,disposal=1)
print(json.dumps({'gif':str(destination),'frames':len(images),'sample_rate':24,'native_size':[1280,800],'bytes':destination.stat().st_size}))
