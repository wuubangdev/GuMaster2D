"""Encode full native Godot frames; no mockup, cropping or synthetic motion."""
from pathlib import Path
import json
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]

def encode(folder, metadata_name, destination):
    record=json.loads((ROOT/'artifacts'/metadata_name).read_text())
    paths=sorted((ROOT/'artifacts'/folder).glob('frame*.png'))
    assert len(paths)==record['frames']
    assert record['renderer']=='GuIllustratedCharacterView'
    frames=[]
    for path in paths:
        with Image.open(path) as source:
            assert source.size==(1280,800)
            frames.append(source.convert('RGB'))
    palette_source=Image.new('RGB',(1280,800*6))
    for index in range(6):
        palette_source.paste(frames[min(len(frames)-1,index*len(frames)//6+8)],(0,index*800))
    palette=palette_source.quantize(colors=256)
    indexed=[frame.quantize(palette=palette,dither=Image.Dither.NONE) for frame in frames]
    rate=record['sample_rate']
    durations=[(round((i+1)*100/rate)-round(i*100/rate))*10 for i in range(len(frames))]
    output=ROOT/'artifacts'/destination
    indexed[0].save(output,save_all=True,append_images=indexed[1:],duration=durations,loop=0,optimize=True,disposal=1)
    print(json.dumps({'gif':destination,'frames':len(frames),'sample_rate':rate,'size':[1280,800],'bytes':output.stat().st_size}))

encode('pixel_motion','pixel_motion_capture.json','pixel_gameplay_motion.gif')
encode('vector_studio_motion','ink19_studio_motion_capture.json','ink19_studio_motion.gif')
print('GAMEPLAY_AND_STUDIO_PREVIEWS_OK native ink19 frames')
