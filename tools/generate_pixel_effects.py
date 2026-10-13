"""Author original, hard-edged pixel spell animations; no runtime rasterization.

Every cell has an integer pivot, binary alpha and transparent margins. Shapes
are oriented into eight authored directions before packing, so the game never
rotates an image through fractional pixels. Rebuild with Python and Pillow.
"""
from pathlib import Path
import json
import math
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/pixel/effects'
CELL, FRAMES, COLUMNS = 96, 8, 16
JADE = ['#183e45', '#287c80', '#58beb2', '#a9efd3', '#f3fff0']
ICE = ['#254b71', '#458baa', '#78ced8', '#c4f3f4', '#ffffff']
GOLD = ['#62472b', '#a07d45', '#d9bb73', '#f6dea0', '#fff7ce']
BLUE = ['#254858', '#527c96', '#8fbacc', '#d3e8ee', '#ffffff']
CLIPS = {
    'moon_blade': 8, 'moon_impact': 1,
    'ice_shard': 8, 'ice_impact': 1,
    'shield_cast': 1, 'shield_loop': 1,
    'dash_wake': 8, 'dash_feather': 8,
    'cast_spark': 1, 'hit_spark': 1,
    'dust': 1, 'seal': 1, 'reward': 1,
}


class Canvas:
    def __init__(self, angle=0):
        self.image = Image.new('RGBA', (CELL, CELL))
        self.draw = ImageDraw.Draw(self.image)
        self.angle = angle

    def point(self, x, y):
        co, si = math.cos(self.angle), math.sin(self.angle)
        return round(48 + x * co - y * si), round(48 + x * si + y * co)

    def polygon(self, points, color, outline=None):
        points = [self.point(x, y) for x, y in points]
        self.draw.polygon(points, fill=color)
        if outline:
            self.draw.line(points + [points[0]], fill=outline, width=1)

    def line(self, points, color, width=1):
        self.draw.line([self.point(x, y) for x, y in points], fill=color, width=width)

    def spark(self, x, y, radius, palette):
        r = max(1, round(radius))
        self.polygon([(x-r,y),(x-1,y-1),(x,y-r),(x+1,y-1),
                      (x+r,y),(x+1,y+1),(x,y+r),(x-1,y+1)], palette[2])
        if r > 2:
            self.line([(x-r+2,y),(x+r-2,y)], palette[4])
            self.line([(x,y-r+2),(x,y+r-2)], palette[4])


def crescent(c, radius, color, thickness, ox=0, oy=0):
    outer = [(ox+math.cos(a)*radius, oy+math.sin(a)*radius)
             for a in [math.radians(-105+i*10) for i in range(22)]]
    inner = [(ox-3+math.cos(a)*(radius-thickness), oy+math.sin(a)*(radius-thickness))
             for a in [math.radians(105-i*10) for i in range(22)]]
    c.polygon(outer+inner, color)


def crystal(c, x, y, length, width, angle, palette=ICE):
    co, si = math.cos(angle), math.sin(angle)
    def p(a, b):
        return x+a*co-b*si, y+a*si+b*co
    c.polygon([p(-length*.5,0),p(-length*.2,-width),p(length*.5,0),
               p(-length*.2,width)], palette[0])
    c.polygon([p(-length*.4,0),p(-length*.17,-max(1,width-1)),
               p(length*.4,0),p(-length*.17,max(1,width-1))], palette[2])
    c.polygon([p(-length*.3,0),p(-length*.12,-max(1,width-2)),p(length*.4,0)], palette[4])
    c.line([p(-length*.2,0),p(length*.32,0)], palette[3])


def shield_outline(c, rx, ry, palette, frame, solid=False):
    points = [(0,-ry),(.7*rx,-ry*.7),(rx,-ry*.15),(.8*rx,ry*.6),
              (0,ry),(-.8*rx,ry*.6),(-rx,-ry*.15),(-.7*rx,-ry*.7)]
    c.line(points+[points[0]], palette[0], 3)
    c.line(points+[points[0]], palette[2], 1)
    c.line(points[:4], palette[4], 1)
    # Faceted corners make the shield read as a shell at native size.
    for sign in (-1,1):
        c.polygon([(sign*rx,-ry*.15),(sign*rx*.7,-ry*.7),
                   (sign*rx*.5,-ry*.62),(sign*rx*.8,-ry*.1)],palette[2])
        c.line([(sign*rx*.7,-ry*.7),(sign*rx,-ry*.15)],palette[4])
        c.polygon([(sign*rx*.8,ry*.6),(sign*rx*.68,ry*.52),
                   (sign*rx*.86,ry*.12),(sign*rx,ry*.05)],palette[1])
    for i in range(4):
        a = (i*math.tau/4)+frame*.025
        x, y = math.cos(a)*(rx+4), math.sin(a)*(ry+4)
        c.polygon([(x,y-2),(x+2,y),(x,y+2),(x-2,y)], palette[3])
    if solid:
        c.polygon([(-5,-3),(0,-7),(5,-3),(4,3),(0,7),(-4,3)], palette[0])
        c.line([(-4,-3),(0,-6),(4,-3),(3,3),(0,6),(-3,3),(-4,-3)], palette[3])
        c.line([(0,-3),(0,3)], palette[4])


def cell(kind, frame, direction):
    c = Canvas(direction*math.tau/8)
    p = frame/(FRAMES-1)
    if kind == 'moon_blade':
        radius = (16,18,20,21,20,19,18,16)[frame]
        crescent(c, radius+2, JADE[0], 9)
        crescent(c, radius+1, JADE[1], 8)
        crescent(c, radius, JADE[2], 7)
        crescent(c, radius-1, JADE[3], 4)
        crescent(c, radius-2, JADE[4], 1)
        for i in range(3):
            x = -16-i*7+(frame%3)
            c.line([(x-4,-7+i*7),(x,-7+i*7)], JADE[1+i])
        c.spark(-12+(frame%3)*3,-13,2+(frame%2),JADE)
    elif kind == 'ice_shard':
        crystal(c, 2,0,32+(frame%3)*2,6,0)
        crystal(c,-17,-8,10,3,.1)
        crystal(c,-21,7,9,2,-.2)
        c.line([(-34+(frame%2)*3,0),(-20,0)],ICE[2])
        c.spark(-8,11-(frame%3)*2,3,ICE)
    elif kind in ('moon_impact','ice_impact','hit_spark','reward'):
        palette = {'moon_impact':JADE,'ice_impact':ICE,'hit_spark':GOLD,'reward':GOLD}[kind]
        radius = (8,15,23,28,30,30,27,23)[frame]
        if kind == 'ice_impact':
            for i in range(7):
                a = i*math.tau/7+.1
                length = (8,14,21,25,24,19,12,7)[frame]
                crystal(c,math.cos(a)*radius*.62,math.sin(a)*radius*.62,
                        length,4 if frame<5 else 3,a)
        else:
            for i in range(8):
                a = i*math.tau/8
                inner = radius*(.25 if frame<4 else .55)
                outer = radius*(1 if i%2==0 else .65)
                co,si=math.cos(a),math.sin(a)
                c.polygon([(co*inner-si*4,si*inner+co*4),(co*outer,si*outer),
                           (co*inner+si*4,si*inner-co*4)],palette[2])
                if frame<4:
                    c.line([(co*inner*.6,si*inner*.6),(co*outer*.78,si*outer*.78)],palette[4],2)
        for i in range(5):
            a=i*math.tau/5+.3
            x,y=math.cos(a)*(radius+4),math.sin(a)*(radius+4)
            c.spark(x,y,3 if frame<5 else 1,palette)
        if frame<4:
            c.spark(0,0,(5,7,8,4)[frame],palette)
    elif kind in ('shield_cast','shield_loop'):
        radius = (10,16,21,25,26,25,24,23)[frame] if kind=='shield_cast' else 23
        shield_outline(c,radius,radius*1.18,GOLD,frame,kind=='shield_cast' and frame<4)
        if kind=='shield_cast':
            for i in range(5):
                a=i*math.tau/5
                c.spark(math.cos(a)*(radius+8),math.sin(a)*(radius+8),2+(frame%2),GOLD)
        else:
            c.line([(-16,-17),(-11,-21)],GOLD[3+(frame%2)])
    elif kind=='dash_wake':
        for i in range(5):
            y=(i-2)*7
            length=(24,32,36,39,35,29,21,13)[frame]-abs(i-2)*3
            start=-length+((i+frame)%3)
            c.polygon([(start,y),(start+7,y-1),(length*.45,y-1),
                       (length*.65,y),(length*.45,y+1),(start+7,y+1)],BLUE[1])
            c.line([(start+7,y),(length*.55,y)],BLUE[3 if i%2 else 4])
        for sign in (-1,1):
            c.line([(-21,sign*18),(-9,sign*13),(0,sign*5)],BLUE[2])
            c.line([(-21,sign*18),(-8,sign*16)],BLUE[4])
    elif kind=='dash_feather':
        curve=[(-12,7),(-7,5),(-1,2),(4,-2),(8,-7),(10,-10)]
        c.line(curve,BLUE[0],3)
        c.line(curve,BLUE[4])
        for i in range(5):
            x=-9+i*4
            y=round(5-i*2.5)
            c.line([(x,y),(x-2,y-4+(frame%2))],BLUE[2])
            c.line([(x,y),(x+5,y)],BLUE[3])
    elif kind=='cast_spark':
        c.spark(0,0,(3,4,6,8,7,5,4,2)[frame],JADE)
        c.spark(-8,5,2,JADE)
        c.spark(7,-6,1+(frame%2),JADE)
    elif kind=='dust':
        palette=['#635644','#9e9167','#c8be94','#e5d6ac']
        for i in range(5):
            x=(i-2)*(3+frame)
            y=-2-round(math.sin(i*1.4)*3)-frame//3
            r=max(1,(4 if frame<4 else 3)-(i%2))
            c.polygon([(x-r,y),(x-r,y-2),(x-r+2,y-r),(x+r-1,y-r),
                       (x+r,y-1),(x+r,y+1),(x-r+2,y+1)],palette[i%3])
            c.line([(x-r+2,y-r),(x+r-2,y-r)],palette[3])
    elif kind=='seal':
        radius=19+(frame%3)
        points=[(math.cos(i*math.tau/8)*radius,math.sin(i*math.tau/8)*radius*.55) for i in range(8)]
        c.line(points+[points[0]],GOLD[2],2)
        inner=[(x*.76,y*.76) for x,y in points]
        c.line(inner+[inner[0]],GOLD[4])
        for i in range(4):
            a=i*math.tau/4+frame*.09
            c.spark(math.cos(a)*27,math.sin(a)*15,3,GOLD)
    return c.image


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    cells=sum(directions*FRAMES for directions in CLIPS.values())
    atlas=Image.new('RGBA',(COLUMNS*CELL,math.ceil(cells/COLUMNS)*CELL))
    manifest={'revision':'pixel12','original':True,'generator':'tools/generate_pixel_effects.py',
              'path':'res://assets/pixel/effects/spells.png','cell_size':[CELL,CELL],
              'pivot':[48,48],'columns':COLUMNS,'frames':cells,'clips':{}}
    index=0
    for kind,directions in CLIPS.items():
        records=[]
        for direction in range(directions):
            frames=[]
            for frame in range(FRAMES):
                image=cell(kind,frame,direction)
                bounds=image.getbbox()
                assert bounds and min(bounds[:2])>0 and max(bounds[2:])<CELL,(kind,frame,direction,bounds)
                assert set(image.getchannel('A').tobytes()) <= {0,255}
                atlas.alpha_composite(image,((index%COLUMNS)*CELL,(index//COLUMNS)*CELL))
                frames.append(index)
                index+=1
            records.append(frames)
        manifest['clips'][kind]={'frames':FRAMES,'directions':directions,'indices':records}
    atlas.save(OUT/'spells.png',optimize=True)
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    sheet=Image.new('RGBA',(FRAMES*CELL,len(CLIPS)*CELL),'#142629')
    for row,kind in enumerate(CLIPS):
        for frame in range(FRAMES):
            sheet.alpha_composite(cell(kind,frame,0),(frame*CELL,row*CELL))
    sheet.save(OUT/'showcase.png',optimize=True)
    (OUT/'README.md').write_text('# Original pixel spell art — 0.12\n\n'
        '13 clips, 328 frames. 96×96 cell, pivot48,48; binary alpha and transparent padding. '
        'Moon blade, ice shard and crane wakes/feathers have eight baked directions. '
        'Run tools/generate_pixel_effects.py with Pillow to regenerate. Gameplay events own timing; '
        'GuPixelEffectsArt shares one nearest-filtered atlas and draws integer positions.\n',encoding='utf-8')
    print(f'PIXEL_EFFECTS_OK {index} frames; 13 clips; binary alpha; padded integer cells')


if __name__=='__main__':
    main()
