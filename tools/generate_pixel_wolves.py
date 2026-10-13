"""Original integer-pixel wolf sprites. Rebuild with Python + Pillow; no external art."""
from pathlib import Path
import math
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/pixel/creatures'
ACTIONS = ['idle', 'walk', 'windup', 'strike', 'hit', 'death']
OUTLINE = '#26362f'
DARK = '#505d51'
COAT = '#8b9273'
LIGHT = '#bec59b'
CREAM = '#e8dfb3'


def wolf(action, direction, frame):
    im = Image.new('RGBA', (64, 64))
    d = ImageDraw.Draw(im)
    front = direction in (0, 1, 7)
    back = direction in (3, 4, 5)
    profile = direction in (2, 6)
    flip = direction in (1, 2, 3)
    bob = (0, -1, 0, -1)[frame] if action == 'walk' else 0
    crouch = frame // 2 if action == 'windup' else 0
    lean = (0, 2, 5, 1)[frame] if action == 'strike' else 0
    ox, oy = lean, bob + crouch
    gait = (0, 2, 0, -2)[frame] if action == 'walk' else 0
    tail = (0, 1, 0, -1)[frame] if action == 'idle' else 0

    def poly(points, fill, outline=None):
        pp = [(x + ox, y + oy) for x, y in points]
        d.polygon(pp, fill=fill)
        if outline:
            d.line(pp + [pp[0]], fill=outline, width=1)

    def rect(box, fill):
        x, y, w, h = box
        d.rectangle((x + ox, y + oy, x + w - 1 + ox, y + h - 1 + oy), fill=fill)

    if profile:
        poly([(13,36),(8,32+tail),(5,28+tail),(7,27+tail),(12,31),(17,32),(20,35)], DARK, OUTLINE)
        for x, g in [(21,-gait),(40,gait)]:
            poly([(x,41),(x+5,42),(x+3+g,50),(x+6+g,51),(x+6+g,53),(x-1+g,53),(x-1,47)], DARK, OUTLINE)
        poly([(13,36),(20,30),(29,29),(40,31),(47,36),(43,44),(32,46),(18,44)], COAT, OUTLINE)
        poly([(15,36),(24,32),(35,32),(41,35),(32,38),(22,37)], LIGHT)
        poly([(23,41),(33,43),(39,41),(37,45),(26,46)], DARK)
        for x, g in [(18,gait),(37,-gait)]:
            poly([(x,40),(x+5,41),(x+4+g,48),(x+6+g,50),(x+6+g,52),(x-1+g,52),(x-1,47)], COAT, OUTLINE)
            rect((x+g,50,5,1),LIGHT)
        poly([(35,29),(38,22),(43,27),(47,24),(48,32),(53,33),(55,36),(50,40),(42,40),(38,35)], COAT, OUTLINE)
        poly([(38,24),(41,28),(38,29)], '#b79783')
        poly([(44,27),(47,26),(47,30)], '#b79783')
        poly([(43,34),(48,34),(52,35),(51,38),(45,38)], CREAM)
        rect((46,31,3,2), OUTLINE)
        rect((47,31,1,1), '#efbf63')
        rect((53,34,2,2), OUTLINE)
        rect((42,39,3,1), DARK)
    else:
        diagonal = 3 if direction in (1,3,5,7) else 0
        poly([(31,41),(28+tail,31),(29+tail,25),(32+tail,24),(34,31),(35,42)], DARK, OUTLINE)
        for x, g in [(23,-gait),(35,gait)]:
            poly([(x,39),(x+5,39),(x+4+g,49),(x+6+g,51),(x+6+g,52),(x-1+g,52),(x-1,47)], DARK, OUTLINE)
        poly([(23,32),(28,29),(37,30),(42,35),(41,44),(36,48),(26,47),(22,42)], COAT, OUTLINE)
        poly([(27,32),(34,31),(38,35),(36,42),(29,43),(26,39)], LIGHT)
        poly([(23,37),(25,40),(24,44),(26,47),(22,45),(21,40)], DARK)
        if front:
            for x, g in [(24,gait),(35,-gait)]:
                poly([(x,41),(x+4,41),(x+4+g,50),(x+6+g,52),(x+6+g,53),(x-1+g,53),(x-1,49)], COAT, OUTLINE)
                rect((x+g,51,5,1),LIGHT)
            poly([(23+diagonal,30),(23+diagonal,23),(28+diagonal,27),(35+diagonal,27),(40+diagonal,23),(40+diagonal,32),(38+diagonal,37),(33+diagonal,40),(27+diagonal,38)], COAT, OUTLINE)
            poly([(25+diagonal,26),(27+diagonal,29),(25+diagonal,31)], '#b79783')
            poly([(36+diagonal,29),(38+diagonal,26),(38+diagonal,31)], '#b79783')
            poly([(28+diagonal,33),(34+diagonal,33),(36+diagonal,36),(32+diagonal,39),(28+diagonal,37)], CREAM)
            rect((26+diagonal,31,3,2),OUTLINE)
            rect((35+diagonal,31,3,2),OUTLINE)
            rect((27+diagonal,31,1,1),'#efbf63')
            rect((35+diagonal,31,1,1),'#efbf63')
            rect((31+diagonal,35,3,2),OUTLINE)
        else:
            poly([(23+diagonal,29),(24+diagonal,22),(28+diagonal,25),(34+diagonal,25),(39+diagonal,21),(40+diagonal,30),(36+diagonal,35),(26+diagonal,35)], COAT, OUTLINE)
            poly([(27+diagonal,26),(34+diagonal,26),(36+diagonal,29),(34+diagonal,31),(27+diagonal,31)], LIGHT)
            poly([(26+diagonal,34),(29+diagonal,36),(27+diagonal,38),(31+diagonal,37),(34+diagonal,38),(36+diagonal,34)], DARK)
    # Fur highlights use small connected clusters, not a noisy per-pixel filter.
    rect((29,34,2,1),CREAM)
    rect((26,37,2,1),LIGHT)
    if action == 'windup':
        rect((44 if profile else 29,33,3,1),'#f1a259')
    if flip:
        im = im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if action == 'hit' and frame % 2 == 0:
        pixels = im.load()
        for y in range(64):
            for x in range(64):
                r,g,b,a = pixels[x,y]
                if a: pixels[x,y] = (min(255,r+45),min(255,g+35),min(255,b+20),255)
    if action == 'death':
        # Four authored collapse states keep the ground pivot fixed.
        collapsed = Image.new('RGBA',(64,64))
        cropped = im.crop((4,20,60,54))
        target_height = (34,25,17,11)[frame]
        cropped = cropped.resize((56,target_height), Image.Resampling.NEAREST)
        collapsed.alpha_composite(cropped,(4,53-target_height))
        im = collapsed
    return im


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    atlas = Image.new('RGBA',(2048,384))
    for row,action in enumerate(ACTIONS):
        for direction in range(8):
            for frame in range(4):
                atlas.alpha_composite(wolf(action,direction,frame),((direction*4+frame)*64,row*64))
    atlas.save(OUT/'forest_wolf.png', optimize=True)
    manifest = {'revision':'pixel11','original':True,'generator':'tools/generate_pixel_wolves.py','texture':'res://assets/pixel/creatures/forest_wolf.png','frame_size':[64,64],'pivot':[32,52],'frames_per_action':4,'actions':ACTIONS,'directions':['down','down_left','left','up_left','up','up_right','right','down_right']}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    sheet = Image.new('RGBA',(64*8,64*6),'#aec482')
    for row,action in enumerate(ACTIONS):
        for direction in range(8):
            sheet.alpha_composite(wolf(action,direction,2),(direction*64,row*64))
    sheet.resize((1024,768),Image.Resampling.NEAREST).save(OUT/'wolf_showcase.png')
    print('PIXEL_WOLVES_OK 192 frames, 8 directions, 6 actions')


if __name__=='__main__': main()
