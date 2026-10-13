#!/usr/bin/env python3
"""Original GuMaster pixel environment. Integer raster primitives; no imported game art.
Run with Python 3; standard library only. World art is authored at one pixel per world unit.
"""
import json, math, random, struct, zlib
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/pixel/environment'
P = {'ink':'22392f','deep':'294731','shade':'3c613c','leaf':'548447','leaf2':'6c9c50','light':'91bb62','sun':'b8d880',
     'grass':'79a95a','grassdark':'709c52','grasslight':'85b461','wooddark':'4c4335','wood':'816444','woodlight':'ae8954',
     'soil':'baaa76','soildark':'a79769','soillight':'cdc18d','stone':'b2b9a2','stone2':'9da88f','stonehi':'c8ccb6',
     'mortar':'819078','red':'a74c3e','redhi':'d76b49','gold':'deb969','teal':'537c79','tealhi':'76a49b',
     'water':'578f9c','waterdeep':'477786','waterhi':'8dbdb6','foam':'b5d6bb'}
def rgba(c):
    if isinstance(c, tuple): return c
    c = P.get(c,c).lstrip('#')
    return tuple(int(c[i:i+2],16) for i in (0,2,4))+(255,)
class Pixel:
    def __init__(self,w,h,bg=None):
        self.w,self.h=w,h;self.data=bytearray(w*h*4)
        if bg:self.rect(0,0,w,h,bg)
    def px(self,x,y,c):
        x,y=int(x),int(y)
        if 0<=x<self.w and 0<=y<self.h:self.data[(y*self.w+x)*4:(y*self.w+x)*4+4]=bytes(rgba(c))
    def rect(self,x,y,w,h,c):
        for yy in range(int(y),int(y+h)):
            for xx in range(int(x),int(x+w)):self.px(xx,yy,c)
    def line(self,x0,y0,x1,y1,c,width=1):
        x0,y0,x1,y1=map(int,(x0,y0,x1,y1));dx=abs(x1-x0);sx=1 if x0<x1 else -1;dy=-abs(y1-y0);sy=1 if y0<y1 else -1;err=dx+dy
        while True:
            self.rect(x0-width//2,y0-width//2,width,width,c)
            if x0==x1 and y0==y1:break
            e=2*err
            if e>=dy:err+=dy;x0+=sx
            if e<=dx:err+=dx;y0+=sy
    def poly(self,points,c):
        for y in range(min(p[1] for p in points), max(p[1] for p in points)+1):
            xs=[]
            for n,a in enumerate(points):
                b=points[(n+1)%len(points)]
                if a[1]<=y<b[1] or b[1]<=y<a[1]:xs.append(a[0]+(y-a[1])*(b[0]-a[0])/(b[1]-a[1]))
            xs.sort()
            for n in range(0,len(xs)-1,2):self.rect(math.ceil(xs[n]),y,math.floor(xs[n+1])-math.ceil(xs[n])+1,1,c)
    def ellipse(self,cx,cy,rx,ry,c):
        for y in range(cy-ry,cy+ry+1):
            for x in range(cx-rx,cx+rx+1):
                if (x-cx)**2*ry*ry+(y-cy)**2*rx*rx<=rx*rx*ry*ry:self.px(x,y,c)
    def blit(self,other,x,y):
        for yy in range(other.h):
            for xx in range(other.w):
                o=(yy*other.w+xx)*4
                if other.data[o+3]:self.px(x+xx,y+yy,tuple(other.data[o:o+4]))
    def png(self,path):
        raw=b''.join(b'\0'+self.data[y*self.w*4:(y+1)*self.w*4] for y in range(self.h))
        def chunk(name,d):return struct.pack('>I',len(d))+name+d+struct.pack('>I',zlib.crc32(name+d)&0xffffffff)
        path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',self.w,self.h,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))
    def bounds(self):
        points=[(i//4%self.w,i//4//self.w) for i in range(0,len(self.data),4) if self.data[i+3]]
        if not points:return [0,0,0,0]
        x=min(p[0] for p in points);y=min(p[1] for p in points)
        return [x-48,y-88,max(p[0] for p in points)-x+1,max(p[1] for p in points)-y+1]
def grass(seed):
    r=random.Random(seed);im=Pixel(32,32,'grass')
    for _ in range(15):
        x,y=r.randrange(32),r.randrange(32);im.rect(x,y,r.choice((2,3,4)),1,r.choice(('grassdark','grasslight')))
    for _ in range(3):
        x,y=r.randrange(4,28),r.randrange(4,29)
        im.line(x,y,x-1,y-3,'leaf');im.line(x+1,y,x+2,y-4,'grasslight');im.px(x+3,y-2,'grassdark')
    return im
def road(mask,stone=False):
    r=random.Random(mask+200 if stone else mask+100);im=grass(mask+19)
    for y in range(32):
        for x in range(32):
            # Irregular two-pixel grass shoulders are encoded for the actual neighbor mask.
            edge=(mask&1 and y<2+(x//5%2)) or (mask&2 and x>29-(y//5%2)) or (mask&4 and y>29-(x//4%2)) or (mask&8 and x<2+(y//4%2))
            if not edge:im.px(x,y,'stone' if stone else 'soil')
    if stone:
        # Hand-cut stones, with staggered joints continuing across adjacent tiles.
        for y in (2,12,22):
            off=0 if y==12 else 8
            for x in range(-8+off,32,16):
                im.line(x,y,x+14,y,'stonehi');im.line(x+14,y+1,x+14,y+8,'mortar');im.line(x+1,y+8,x+13,y+8,'stone2');im.px(x+2,y+2,'stonehi')
        for _ in range(9):im.px(r.randrange(3,29),r.randrange(3,29),r.choice(('stone2','stonehi')))
    else:
        for _ in range(18):
            x,y=r.randrange(4,28),r.randrange(4,28);im.rect(x,y,r.choice((1,2,3)),1,r.choice(('soildark','soillight')))
        for _ in range(2):
            x,y=r.randrange(5,27),r.randrange(5,27);im.rect(x,y,3,2,'soildark');im.rect(x,y,2,1,'soillight')
    # Restore the outline of the requested road shoulders after detail placement.
    for y in range(32):
        for x in range(32):
            edge=(mask&1 and y<2+(x//5%2)) or (mask&2 and x>29-(y//5%2)) or (mask&4 and y>29-(x//4%2)) or (mask&8 and x<2+(y//4%2))
            if edge:im.px(x,y,'grassdark' if (x+y)%5==0 else 'grass')
    return im
def water(frame):
    im=grass(72);im.poly([(4,10),(8,5),(22,5),(27,10),(28,23),(22,27),(10,27),(4,21)],'soildark')
    im.poly([(6,10),(10,7),(22,7),(25,12),(25,22),(21,25),(11,25),(6,20)],'waterdeep')
    im.poly([(8,10),(13,8),(21,9),(24,13),(24,20),(20,24),(10,22),(8,18)],'water')
    for n in range(4):
        x=9+(n*7+frame*2)%12;y=11+n*3
        im.line(x,y,min(x+4,23),y,'waterhi');im.px(x-1,y+1,'waterdeep')
    im.rect(11,7,4,1,'foam');im.rect(6,17,1,3,'grasslight')
    return im
def flower_tile():
    im=grass(2)
    for x,y in [(6,10),(22,20),(12,26),(25,6)]:
        im.line(x,y,x,y+4,'shade');im.px(x-1,y+3,'leaf');im.rect(x-1,y-1,3,3,'d9b493');im.px(x,y,'gold')
    return im
def farm_tile():
    im=grass(8);im.rect(2,3,28,27,'wooddark');im.rect(3,4,26,24,'soildark')
    for y in (8,16,24):
        im.line(4,y+2,27,y+2,'soil')
        for x in (7,15,23):
            im.rect(x-2,y-2,5,3,'shade');im.rect(x-1,y-3,3,3,'leaf2');im.px(x,y-4,'light');im.px(x+2,y-1,'grasslight')
    return im
def tree(v):
    im=Pixel(96,96);r=random.Random(310+v)
    im.ellipse(49,88,23,4,'shade');im.poly([(42,88),(44,44),(52,41),(55,88),(60,89),(47,92),(35,90)],'ink')
    im.poly([(45,87),(46,48),(51,47),(53,88),(58,89),(46,90)],'wood');im.line(47,57,47,83,'woodlight');im.line(52,62,53,84,'wooddark')
    im.line(46,63,32,48,'wood',4);im.line(51,58,67,38,'wood',4)
    blobs=[(30,39,17,15),(65,38,18,16),(46,25,23,18),(23,53,17,13),(70,52,16,12),(47,46,27,22),(42,60,25,12)]
    if v==1:blobs=[(a,b-4 if i%2 else b,c-1,d+2) for i,(a,b,c,d) in enumerate(blobs)]
    if v==2:blobs=[(a+2,b,c-3,d-1) for a,b,c,d in blobs]
    for x,y,rx,ry in blobs:im.ellipse(x,y,rx,ry,'ink')
    for x,y,rx,ry in blobs:im.ellipse(x,y-1,rx-2,ry-2,'shade')
    for n,(x,y,rx,ry) in enumerate(blobs):
        im.ellipse(x-3,y-4,rx-4,ry-5,'leaf2' if n%3 else 'leaf')
        im.ellipse(x-7,y-7,max(3,rx-9),max(2,ry-9),'light')
        for _ in range(8):
            xx=x+r.randrange(-rx+4,rx-3);yy=y+r.randrange(-ry+4,ry-3)
            if yy<y+3:im.rect(xx,yy,r.choice((2,3,4)),1,'leaf' if yy>y-4 else 'grasslight')
        im.rect(x-rx+5,y-4,3,2,'sun')
    if v==3:
        for x,y in ((28,38),(61,52),(44,23),(74,44)):im.rect(x,y,3,2,'red');im.px(x,y-1,'redhi')
    if v==4:
        for x,y in ((28,38),(61,52),(44,23),(74,44)):im.rect(x,y,3,2,'gold');im.px(x,y-1,'sun')
    for x,y in ((32,87),(62,90),(56,85)):
        im.line(x,y,x-2,y-3,'leaf');im.line(x+1,y,x+2,y-4,'leaf2')
    return im
def rock(v):
    im=Pixel(96,96);im.ellipse(48,88,17,3,'shade')
    points=[(30,85),(32,72),(41,65),(58,66),(66,77),(64,88),(47,91)]
    if v==1:points=[(30,85),(31,76),(40,73),(51,66),(65,71),(69,85),(58,91),(42,90)]
    if v==2:points=[(35,86),(35,69),(43,61),(57,63),(64,76),(62,88),(47,91)]
    im.poly(points,'ink');im.poly([(33,84),(35,74),(42,68),(56,69),(63,77),(61,85),(47,88)],'stone2')
    im.poly([(35,73),(44,66),(56,68),(60,72),(48,79),(36,80)],'stonehi');im.poly([(49,80),(62,74),(65,81),(61,88),(47,88)],'mortar')
    im.line(43,71,50,73,'stone');im.line(50,73,47,76,'mortar');im.line(37,83,45,85,'stonehi');im.rect(32,85,7,2,'leaf');im.rect(39,88,5,1,'leaf2')
    return im
def house_segment(side,segment):
    im=Pixel(96,96);start=32;end=63
    im.rect(start,48,32,41,'ink');im.rect(start+1,52,30,32,'soillight');im.rect(start+1,79,30,7,'soil')
    for y in (55,64,73):
        im.line(start+1,y,start+30,y,'soildark');im.line(start+((y*5)%23),y,start+((y*5)%23),y+7,'soil')
    im.rect(start+1,48,30,6,'wooddark');im.rect(start+1,53,30,2,'woodlight');im.rect(start+1,85,30,4,'wooddark')
    if segment==1:
        im.rect(start+8,61,16,25,'wooddark');im.rect(start+9,62,14,23,'wood');im.rect(start+14,62,2,23,'woodlight');im.px(start+20,76,'gold');im.rect(start+7,85,18,3,'stone2');im.rect(start+5,88,22,2,'stonehi')
        # Tiny hanging wooden nameplate with hand-painted decorative glyphs.
        im.rect(start+6,55,20,5,'wooddark');im.rect(start+7,56,18,3,'gold');im.rect(start+11,56,1,3,'wood');im.rect(start+18,56,2,3,'wood')
    else:
        im.rect(start+6,62,20,14,'wooddark');im.rect(start+8,64,16,10,'teal');im.rect(start+8,64,7,4,'tealhi');im.line(start+16,63,start+16,75,'woodlight');im.line(start+7,69,start+25,69,'woodlight')
        im.rect(start+5,76,22,2,'wood');im.rect(start+7,79,3,4,'red')
    # All three sections join without a visible seam; eaves form native32px roofs.
    for y in range(21,49):
        im.rect(start,y,32,1,'red' if side==0 else 'teal')
        if y%5==0:im.rect(start,y,32,1,'wooddark')
        elif y%5==1:im.rect(start,y,32,1,'redhi' if side==0 else 'tealhi')
        for x in range(start+((y//5)%2)*4,start+32,8):im.px(x,y,'wooddark')
    im.rect(start,19,32,2,'wooddark');im.rect(start,20,32,1,'gold');im.rect(start,48,32,3,'wooddark');im.rect(start,48,32,1,'woodlight')
    if segment==0:
        for y in range(19,50):im.rect(start,y,2,1,'ink')
        im.rect(start-3,48,5,3,'wooddark');im.rect(start,52,2,35,'wood')
    if segment==2:
        for y in range(19,50):im.rect(end-1,y,2,1,'ink')
        im.rect(end-1,48,5,3,'wooddark');im.rect(end-1,52,2,35,'wood')
    return im
def pillar(v):
    im=Pixel(96,96);im.rect(37,86,23,4,'ink');im.rect(39,82,19,5,'stone2');im.rect(40,43,16,40,'ink');im.rect(42,45,12,37,'stone2');im.rect(42,45,5,37,'stonehi');im.rect(53,46,1,35,'mortar')
    im.rect(35,38,27,7,'ink');im.rect(37,38,23,4,'stonehi');im.rect(37,42,23,2,'stone2');im.rect(38,48,21,3,'stone');im.rect(43,72,9,1,'mortar')
    im.rect(47,57,4,10,'teal');im.rect(48,58,2,7,'tealhi');im.rect(44,66,3,3,'gold');im.rect(49,61,4,2,'gold')
    im.rect(39,84,12,1,'stonehi');im.rect(35,89,12,2,'leaf')
    return im
def monolith():
    im=Pixel(96,96);im.ellipse(49,88,21,4,'shade');im.poly([(32,87),(35,29),(48,18),(61,29),(64,87),(48,92)],'ink');im.poly([(36,85),(38,32),(48,23),(58,33),(60,86),(48,89)],'mortar');im.poly([(38,33),(48,23),(49,89),(36,85)],'stone2');im.line(40,38,39,73,'stonehi');im.line(57,35,58,78,'shade')
    im.ellipse(49,50,8,8,'wooddark');im.ellipse(48,49,6,6,'gold');im.ellipse(51,47,5,5,'mortar');im.rect(48,64,2,7,'tealhi');im.rect(44,66,10,2,'gold');im.rect(47,77,3,3,'stonehi');im.rect(34,86,9,2,'leaf')
    return im
def lantern(frame):
    im=Pixel(96,96);im.ellipse(47,88,11,3,'shade');im.rect(42,83,11,6,'wooddark');im.rect(44,83,7,4,'woodlight');im.rect(46,43,4,40,'wooddark');im.rect(46,44,1,37,'woodlight');im.line(45,44,50,39,'wooddark',2);im.line(49,39,64,39,'wooddark',2);im.rect(63,39,1,9,'gold')
    im.rect(57,47,15,3,'wooddark');im.poly([(57,50),(72,50),(75,55),(74,64),(70,68),(59,68),(55,63),(55,54)],'ink');im.poly([(58,51),(70,51),(72,55),(71,63),(69,66),(60,66),(57,62),(57,55)],'red');im.rect(60,52,8,13,'redhi');im.rect(63,52,2,13,'gold');im.rect(61+(frame%2),56,3,4,'f2d38a');im.px(62+frame%3,55,'fff1b2');im.rect(58,67,13,2,'wooddark');im.rect(64,69,1,6,'gold');im.rect(62,74,5,2,'red')
    return im
def altar(frame):
    im=Pixel(96,96);im.ellipse(48,87,23,4,'shade');im.rect(28,83,40,6,'ink');im.rect(30,83,36,4,'stonehi');im.rect(32,75,32,8,'wooddark');im.rect(34,75,28,7,'wood');im.rect(27,71,42,5,'ink');im.rect(28,71,40,3,'gold');im.rect(35,59,5,12,'wooddark');im.rect(36,59,3,11,'stonehi');im.rect(57,59,5,12,'wooddark');im.rect(58,59,3,11,'stonehi')
    for x in (38,59):im.poly([(x-2,58),(x,53-frame%2),(x+2,58),(x+1,60),(x-1,60)],'redhi');im.px(x,57,'gold')
    im.rect(44,63,10,8,'ink');im.rect(45,64,8,6,'teal');im.rect(46,66,6,2,'gold');im.rect(47,59,1,5,'wooddark');im.rect(51,58,1,6,'wooddark')
    return im
def well():
    im=Pixel(96,96);im.ellipse(48,86,18,5,'shade');im.rect(32,60,3,25,'wooddark');im.rect(34,62,1,22,'woodlight');im.rect(62,60,3,25,'wooddark');im.line(30,61,67,61,'wooddark',4);im.line(31,59,65,59,'woodlight');im.rect(46,61,1,9,'gold');im.rect(43,68,7,7,'wooddark');im.rect(44,69,5,5,'wood');im.ellipse(48,81,17,8,'ink');im.ellipse(48,79,15,6,'stonehi');im.ellipse(48,78,10,4,'waterdeep');im.line(42,78,52,78,'water');im.rect(33,81,30,8,'stone2');im.line(33,83,63,83,'mortar');im.line(34,87,62,87,'mortar');im.rect(41,81,1,3,'mortar');im.rect(53,84,1,4,'mortar');im.rect(34,81,7,1,'stonehi')
    return im
def hut(v):
    im=Pixel(96,96);im.ellipse(48,88,20,4,'shade')
    im.rect(31,54,35,35,'ink');im.rect(33,56,31,29,'soillight');im.rect(33,80,31,5,'soil')
    for y in (60,68,76):im.line(33,y,63,y,'soildark')
    im.rect(34,58,3,27,'wood');im.rect(61,58,3,27,'wooddark');im.rect(32,85,33,3,'wooddark')
    im.rect(41,64,15,22,'wooddark');im.rect(42,65,13,19,'wood');im.rect(43,65,3,19,'woodlight');im.px(53,77,'gold');im.rect(39,86,19,3,'stonehi')
    im.rect(37,57,24,5,'wooddark');im.rect(38,58,22,3,'gold');im.rect(43,58,2,3,'wood');im.rect(53,58,2,3,'wood')
    # Raised ridge and stepped flared eaves: roof overhang has no ground collider.
    im.poly([(27,52),(32,36),(41,29),(57,29),(66,36),(71,52),(76,56),(22,56)],'ink')
    im.poly([(29,51),(34,37),(41,32),(57,32),(64,38),(68,51),(73,54),(25,54)],'red' if v==0 else 'teal')
    for y in (37,42,47,52):
        left=34-(y-37)//3;right=64+(y-37)//3
        im.line(left,y,right,y,'wooddark');im.line(left+1,y+1,right-1,y+1,'redhi' if v==0 else 'tealhi')
        for x in range(left+2,right,8):im.px(x,y+2,'wooddark')
    im.rect(40,29,19,3,'wooddark');im.rect(40,29,19,1,'gold');im.rect(25,54,48,2,'woodlight');im.rect(23,56,52,2,'wooddark')
    if v==0:
        im.rect(34,70,6,8,'ink');im.rect(35,71,4,6,'teal');im.rect(35,71,2,2,'tealhi');im.rect(37,71,1,6,'woodlight')
        im.rect(58,70,5,8,'ink');im.rect(59,71,3,6,'teal')
    else:
        # Rolled shop shade and basket distinguish the second village building.
        im.rect(38,63,22,2,'redhi');im.rect(60,78,4,6,'wood');im.rect(59,76,6,3,'woodlight');im.px(62,75,'gold')
    return im
def crates():
    im=Pixel(96,96)
    for x,y in ((33,71),(49,76)):
        im.rect(x,y,16,15,'ink');im.rect(x+1,y+1,14,13,'wood');im.rect(x+2,y+2,12,2,'woodlight');im.line(x+2,y+4,x+13,y+12,'wooddark',2);im.line(x+2,y+12,x+13,y+4,'woodlight');im.rect(x+1,y+13,14,1,'wooddark')
    im.rect(37,68,7,3,'soillight');im.rect(57,72,6,4,'gold')
    return im
def fence():
    im=Pixel(96,96)
    for x in (35,59):im.rect(x,64,4,24,'wooddark');im.rect(x,65,1,22,'woodlight');im.rect(x-1,62,6,3,'wood')
    im.rect(35,69,28,4,'wooddark');im.rect(36,69,26,1,'woodlight');im.rect(35,79,28,3,'wood');im.rect(36,79,26,1,'woodlight');return im

def main():
    OUT.mkdir(parents=True,exist_ok=True);terrain=Pixel(256,192);tiles=[grass(v+9) for v in range(8)]+[road(m) for m in range(16)]+[road(m,True) for m in range(16)]+[water(f) for f in range(6)]+[flower_tile(),farm_tile()]
    for n,t in enumerate(tiles):terrain.blit(t,n%8*32,n//8*32)
    terrain.png(OUT/'terrain.png')
    frames=[]
    def add(name,im):frames.append((name,im))
    for v in range(5):add('tree_'+str(v),tree(v))
    for v in range(4):add('rock_'+str(v),rock(v))
    for side in range(2):
        for seg in range(3):add('house_'+str(side)+'_'+str(seg),house_segment(side,seg))
    for v in range(2):add('pillar_'+str(v),pillar(v))
    add('monolith',monolith())
    for f in range(4):add('lantern_'+str(f),lantern(f))
    for f in range(4):add('altar_'+str(f),altar(f))
    add('well',well());add('crates',crates());add('fence',fence());add('hut_0',hut(0));add('hut_1',hut(1))
    atlas=Pixel(768,384);manifest_frames=[]
    for n,(name,im) in enumerate(frames):
        x,y=n%8*96,n//8*96;atlas.blit(im,x,y);manifest_frames.append({'name':name,'index':n,'region':[x,y,96,96],'bounds':im.bounds()})
    atlas.png(OUT/'props.png')
    manifest={'version':1,'pixel_scale':1,'tile_size':32,'terrain':{'path':'res://assets/pixel/environment/terrain.png','columns':8,'tile_count':48,'groups':{'grass':list(range(8)),'dirt':list(range(8,24)),'stone':list(range(24,40)),'water':list(range(40,46)),'flowers':[46],'farm':[47]}},'props':{'path':'res://assets/pixel/environment/props.png','frame_size':[96,96],'columns':8,'pivot':[48,88],'frames':manifest_frames},'source':'Original code-authored pixel art; no graphics copied from reference games.','generator':'tools/generate_pixel_environment.py'}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    # Contact sheet enlarged by integer replication, useful for art review and reproducibility.
    preview=Pixel(768*2,384*2,'grass')
    for y in range(atlas.h):
        for x in range(atlas.w):
            n=(y*atlas.w+x)*4
            if atlas.data[n+3]:preview.rect(x*2,y*2,2,2,tuple(atlas.data[n:n+4]))
    preview.png(OUT/'props_preview.png')
    print(f'Created {len(tiles)} terrain tiles and {len(frames)} pixel prop frames.')
if __name__=='__main__':main()
