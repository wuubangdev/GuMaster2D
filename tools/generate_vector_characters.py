"""Author original curved SVG cutout pieces for the illustrated 2D character rig.

Python standard library only. Shapes are editable Bezier artwork, not traced or
filtered pixel sprites. Godot imports each small part at eight texels per unit;
the rig poses those pieces continuously without baking animation frames.
"""
from pathlib import Path
import json
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/vector/characters'
INK = '#2b2521'
PALETTES = {
    'jade': ('#657a61', '#9caa83', '#c5c8a1', '#3f5144'),
    'crimson': ('#8e615c', '#b79178', '#d9c3a0', '#573e3b'),
    'ivory': ('#bdb394', '#d9cbaa', '#eee0bd', '#777b68'),
}
RECTS = {'head': [-20,-24,40,44], 'torso': [-18,-13,36,30],
         'sleeve': [-6,-3,12,19], 'boot': [-6,-8,12,12],
         'hat': [-22,-29,44,32],
         'hand': [-4,-4,8,8], 'tail': [-10,-3,20,31],
         'weapon': [-10,-44,20,54]}

def path(d, fill, stroke=INK, width=.85, extra=''):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round" {extra}/>'

def ellipse(x,y,rx,ry,fill,stroke='none',width=.7):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>'

def head(body,hair,direction,closed=False):
    side=direction in (2,6)
    back=direction in (3,4,5)
    quarter=direction in (1,3,5,7)
    flip=direction in (1,2,3)
    feminine=body=='female'
    eye='#426b82' if feminine else '#567a76'
    p=[]
    if hair=='topknot':
        p += [path('M-4 -13 C-8 -20 -3 -23 2 -21 C9 -19 8 -12 4 -10Z','#304659'),
              path('M-4 -17 Q0 -21 4 -18','none','#668a9e',1.3),
              path('M-5 -12 Q0 -14 6 -12 L6 -10 Q0 -11 -5 -10Z','#d5b46d')]
    else:
        p += [path('M-7 -10 Q-13 -15 -10 -19 Q-3 -23 0 -15Z','#354c62'),
              path('M-11 -14 Q-7 -17 -3 -15','none','#7c9eb0',1.2)]
    if back:
        p += [path('M-12 -7 C-13 -17 9 -20 12 -8 L11 5 Q7 14 0 13 Q-10 13 -12 5Z','#304559'),
              path('M-10 -8 Q-5 -15 4 -14 Q11 -12 10 -5 Q4 -9 -3 -7 Q-8 -3 -10 -8Z','#49667d','none'),
              path('M-8 -9 Q-3 -13 3 -12','none','#8aacba',1.1),
              path('M8 -3 Q7 7 2 11 Q-3 12 -7 8','none','#1d3042',1.1),
              path('M-5 -4 Q-6 4 -3 7 M2 -4 Q0 3 1 6','none','#56778b',.65)]
        if quarter:
            p += [ellipse(10,3,2,3,'#edb28f',INK),path('M11 2 Q10 1 10 4','none','#ba806c',.6)]
    else:
        if side:
            # Separate profile anatomy; its eye stays inside the silhouette.
            p += [path('M-11 -5 C-12 -15 2 -18 7 -11 Q10 -8 9 -3 L10 .2 Q13 2 10 3.5 L9.5 7 Q9 11 4 12 Q-4 12 -9 6Z','#efbc99'),
                  path('M-4 -8 Q3 -13 6 -7 L7 5 Q5 10 1 9 Q-4 6 -4 -8Z','#ffdab3','none')]
        else:
            p += [path('M-12 -5 C-13 -18 12 -18 12 -5 L11 5 Q9 12 0 13 Q-9 12 -11 5Z','#efbd9a'),
                  path('M-9 -6 Q-3 -12 2 -7 L4 7 Q0 12 -5 8 Q-9 5 -9 -6Z','#ffe0b9','none'),
                  path('M9 -3 Q12 3 8 8 Q4 12 0 11','none','#d4967f',1.4),
                  ellipse(-12,2,2,3,'#efb596',INK),ellipse(12,2,2,3,'#efb596',INK)]
        eyes=[(5.6,1.5,2.15,2.85)] if side else ([(-6,1.7,1.85,3.15),(4.5,1.8,2.85,3.65)] if quarter else [(-5,2,3.3,4.0),(5,2,3.3,4.0)])
        for x,y,rx,ry in eyes:
            if closed:
                p += [path(f'M{x-rx} {y-.2} Q{x} {y+1.5} {x+rx} {y-.2}','none',INK,.8)]
                continue
            p += [ellipse(x,y,rx+.25,ry+.25,'#fff9e9'),ellipse(x+.35,y+.25,rx*.66,ry*.87,eye),
                  ellipse(x+.6,y+.45,rx*.39,ry*.70,'#243949'),ellipse(x-.1,y-.85,rx*.23,ry*.25,'#fffdf3'),
                  ellipse(x+.8,y+1.45,rx*.11,ry*.12,'#b9e1d5'),
                  path(f'M{x-rx-.15} {y-ry+.5} Q{x} {y-ry-.7} {x+rx} {y-ry+.5}','none',INK,.8)]
            if feminine:
                p += [path(f'M{x-rx-.15} {y-ry+.5} l-.8 -.9','none',INK,.65)]
        if side:
            p += [path('M9.7 4.5 Q8.6 4.8 9.2 5.1','none','#c58d77',.5),
                  path('M6.8 8.1 Q8 8.7 9 8.1','none','#a66168',.65),ellipse(4.1,6.2,1.7,.65,'#e7a090')]
        else:
            p += [path('M2 4 Q1 6 3 6' if quarter else 'M1 4 Q-1 6 2 6','none','#c58d77',.55),
                  path('M0 9 Q3 10 5 8.8' if quarter else 'M-2 9 Q1 10 4 8.8','none','#a66168',.8),
                  ellipse(-8,6,1.5 if quarter else 2.3,.9,'#ed9e97'),ellipse(8,6,1.6,.8,'#e7a090')]
        # Connected locks are curved masses with a few broad shine planes.
        if side:
            p += [path('M-12 -3 C-15 -13 -5 -19 3 -16 Q10 -14 10 -7 Q7 -10 5 -11 Q3 -7 -1 -5 L-2 -9 Q-5 -4 -6 0 L-7 6 Q-12 3 -12 -3Z','#30475d'),
                  path('M-11 -9 Q-6 -16 1 -14 Q-5 -12 -7 -6 L-9 -3Z','#57788e','none'),
                  path('M-10 -10 Q-5 -14 0 -13','none','#8db0bd',.85),
                  path('M4 -14 Q8 -12 8 -10','none','#64869b',1.0),
                  ellipse(-6.8,3,2.0,2.7,'#efb596',INK,.7),
                  path('M-7.5 2.3 Q-5.8 1.9 -6.2 4','none','#ba806c',.6)]
        else:
            p += [path('M-12 -4 C-15 -15 -3 -21 8 -14 Q15 -10 12 0 L8 -3 Q10 -9 6 -11 Q5 -5 0 -2 Q1 -7 -2 -9 Q-4 -3 -7 -1 L-8 5 Q-13 2 -12 -4Z','#30475d'),
                  path('M-10 -10 Q-4 -17 4 -13 Q-3 -12 -5 -7 L-8 -4Z','#57788e','none'),
                  path('M-9 -11 Q-4 -14 0 -13','none','#8db0bd',1.0),
                  path('M7 -13 Q12 -9 11 -5','none','#64869b',1.3)]
    return '<g transform="scale(-1 1)">'+''.join(p)+'</g>' if flip else ''.join(p)

def torso(body,outfit,direction):
    base,light,high,shadow=PALETTES[outfit]
    side=direction in (2,6); back=direction in (3,4,5)
    width=9 if side else (10 if body=='female' else 11)
    p=[path(f'M{-width} -9 Q-4 -14 0 -13 Q5 -14 {width} -9 L{width-1} 0 Q{width+1} 7 {width+3} 13 Q3 17 -1 12 Q-5 17 {-width-3} 13 L{-width+1} 0Z',base),
       path(f'M{-width+2} -7 Q-4 -10 -2 -8 L-3 10 Q-6 14 {-width} 12 L{-width+2} 1Z',light,'none'),
       path(f'M{width-2} -7 Q{width+1} -4 {width-1} 2 L{width+2} 12 Q5 15 3 12 L4 -7Z',shadow,'none'),
       path(f'M{-width+1} 12 Q-5 15 -1 12 Q4 15 {width+2} 12 L{width+3} 14 Q4 18 -1 14 Q-6 18 {-width-3} 14Z',shadow,'none',extra='opacity=".52"')]
    if back:
        p += [path('M-5 -8 Q0 -6 5 -8','none',high,.85),
              path('M0 -5 C-5 -1 -3 3 0 4 C4 1 4 -3 0 -5Z','none','#dabd81',.8),
              path('M-5 6 Q-4 10 -5 12 M5 6 Q4 10 6 13','none',light,.9),
              path('M-6 1 Q0 3 6 1','none',shadow,.55),
              path('M-4 -2 Q0 0 4 -2','none',high,.45)]
    elif side:
        p += [path('M-3 -11 L3 -8 L6 -10 L4 -11 L2 -10 L-1 -12Z','#faf0d2'),
              path('M3 -8 Q5 -5 5 -1 L3 1 L1 -8Z','#d1b674','none'),
              path('M4 -1 Q2 5 3 12','none',high,.8),
              path('M-4 10 Q-2 7 1 10','none','#d5c28d',.7),
              path('M-2 -8 Q1 -5 3 -2','none','#fff0cd',.6)]
    else:
        p += [path('M-7 -10 L0 -2 L7 -10 L4 -12 L0 -6 L-4 -12Z','#faf0d2'),
              path('M-6 -9 L3 -1 L0 2 L-8 -6Z','#d1b674','none'),
              path('M2 -2 L-2 12','none',high,.9),
              path('M-8 9 Q-5 6 -2 9 M4 10 Q6 6 10 10','none','#d5c28d',.7),
              path('M-3 -7 L1 -3 M-6 -6 L-3 -3','none','#fff0cd',.55)]
    p += [path(f'M{-width} 0 Q0 2 {width} 0 L{width} 3 Q0 5 {-width} 3Z','#293f4a'),
          path('M-2 .7 L2 .7 L2 3.7 L-2 3.7Z','#e2c07f',INK,.55),
          path('M-10 1 Q-7 2 -4 1 M4 1 Q7 2 10 1','none','#c8aa70',.45),
          path(f'M{width-2} 2 Q{width+4} 8 {width} 13 L{width-2} 10 Q{width+1} 6 {width-3} 4Z','#e5c27b',INK,.5),
          path(f'M{-width} 13 Q-4 16 -1 12 Q4 16 {width+2} 13','none','#eed6a4',.85)]
    if not back:
        p += [ellipse(-5.7,5.2,2.5,2.8,'#8a9a79',INK,.6),
              ellipse(-5.7,5.2,1.55,1.8,'none','#d8c994',.55),
              path('M-6.8 7.4 Q-7.7 9.2 -6.3 10.5 M-5.4 7.8 Q-4.8 9.3 -5.5 10.6','none','#d8c994',.55),
              path('M-8.8 4.1 Q-7.6 3.6 -6.7 4','none','#e6d7a9',.45)]
    return '<g transform="scale(-1 1)">'+''.join(p)+'</g>' if direction in (1,2,3) else ''.join(p)

def sleeve(outfit):
    base,light,high,shadow=PALETTES[outfit]
    return ''.join([path('M-3 0 Q0 -2 3 0 Q5 4 3 10 L2 12 L-3 12 Q-5 6 -3 0Z',base),
                    path('M-2 1 Q0 0 1 1 L0 10 L-3 10Z',light,'none'),
                    path('M-3 10 Q0 11 3 10 L3 12 Q0 14 -3 12Z','#dbbf82'),
                    path('M-2 2 L-2 7','none',high,.65)])

def boot(direction, style='cloth'):
    back=direction in (3,4,5)
    side=direction in (2,6)
    silhouette=('M-2 -7 Q0 -9 2 -7 L2 -2 Q6 -1 5 2 Q3 4 -4 2 Q-5 0 -2 -2Z' if side else
                'M-3 -7 Q0 -9 3 -7 L3 1 Q3 3 0 3 Q-4 3 -4 1 L-3 -2Z' if back else
                'M-3 -7 Q0 -9 3 -7 L3 -1 Q6 1 4 3 L-4 3 Q-6 0 -3 -2Z')
    if style == 'leather':
        pieces=''.join([path(silhouette,'#514638'),
                        path('M-2 -6 Q0 -7 1 -6 L1 0 L-3 0Z','#846d50','none'),
                        path('M-3 2 Q0 3 4 2','none','#c8a76b',1.05),
                        path('M-2 -4 L2 -4','none','#d2b979',1.0 if not back else .65),
                        path('M-2 -1 L2 -1','none','#332e27',.6)])
    else:
        pieces=''.join([path(silhouette,'#324b5d'),
                        path('M-2 -6 Q0 -7 1 -6 L1 0 L-3 0Z','#607b8d','none'),
                        path('M-3 2 Q0 3 4 2','none','#c3b493',.9),
                        path('M-2 -4 L2 -4','none','#b79d6b',.85 if not back else .55)])
    if direction==2:
        pieces='<g transform="scale(-1 1)">'+pieces+'</g>'
    elif direction in (1,3,5,7):
        pieces=f'<g transform="rotate({-7 if direction in (1,3) else 7})">'+pieces+'</g>'
    return pieces

def hat(style, direction):
    """Top-down hat layers, authored separately so hair/face remain swappable."""
    back=direction in (3,4,5)
    side=direction in (2,6)
    flip=direction in (1,2,3)
    if style == 'bamboo':
        brim='M-17 -7 Q-15 -12 0 -12 Q15 -12 17 -7 Q15 -2 0 -1 Q-15 -2 -17 -7Z'
        crown='M-1 -21 Q1 -23 3 -21 L9 -9 Q5 -6 0 -6 Q-5 -6 -9 -9Z'
        parts=[path(brim,'#81714d',INK,.8),
               path('M-15 -8 Q-8 -11 0 -10 Q9 -11 15 -8 Q8 -5 0 -5 Q-9 -5 -15 -8Z','#c4ac79','none'),
               path(crown,'#aa9467',INK,.75),
               path('M-1 -20 Q2 -21 5 -16 L0 -14Z','#d0ba86','none'),
               path('M-8 -9 Q0 -7 8 -9','none','#6c6046',.7),
               path('M-11 -6 Q0 -3 11 -6','none','#e0c995',.65)]
        if side:
            parts += [path('M7 -8 Q12 -6 15 -8','none','#4d493a',.7)]
        if back:
            parts += [path('M-8 -10 Q0 -8 8 -10','none','#ded0a7',.6)]
    else:
        brim='M-12 -10 Q-8 -14 0 -14 Q8 -14 12 -10 L10 -6 Q0 -4 -10 -6Z'
        parts=[path(brim,'#343d39',INK,.9),
               path('M-10 -10 Q-5 -13 0 -12 Q6 -13 10 -10 L8 -8 Q0 -6 -8 -8Z','#566455','none'),
               path('M-7 -12 Q-5 -21 0 -23 Q5 -21 7 -12 Q4 -10 0 -10 Q-4 -10 -7 -12Z','#46534a',INK,.8),
               path('M-3 -19 Q0 -22 3 -19','none','#9d9874',.8),
               path('M-2 -15 Q0 -17 2 -15 L1 -12 L-1 -12Z','#c8ad72',INK,.45)]
        if not back:
            parts += [path('M-10 -8 Q0 -5 10 -8','none','#bba674',.55)]
        else:
            parts += [path('M-6 -8 Q0 -7 6 -8','none','#85856a',.55)]
    body=''.join(parts)
    if flip:
        body='<g transform="scale(-1 1)">'+body+'</g>'
    return body

def tail(hair,direction):
    if hair=='topknot':
        return path('M-2 0 Q-5 9 -1 12 Q1 6 1 0Z','#354d61')+path('M1 0 Q4 7 7 9 Q5 4 3 0Z','#c4a66f')
    flip=direction in (1,2,3)
    p=path('M-3 0 Q-8 5 -6 13 Q-4 18 -6 23 Q3 21 4 14 Q6 8 2 1Z','#30475b')+path('M-3 3 Q-6 10 -3 17 Q1 13 1 6Z','#57778e','none')+path('M-4 5 Q-4 11 -2 13','none','#87aaba',.8)
    return '<g transform="scale(-1 1)">'+p+'</g>' if flip else p

def weapon(kind):
    if kind=='sword':
        return ''.join([path('M-1 -7 L-2 -29 L0 -38 L2 -29 L1 -7Z','#d9eee9',INK,.8),
                        path('M0 -35 L0 -9','none','#ffffff',.75),
                        path('M0 -8 L2 -29','none','#7fb2bc',.65),
                        path('M-5 -7 Q0 -10 5 -7 L5 -5 Q0 -7 -5 -5Z','#e8c77e'),
                        path('M-1 -5 L1 -5 L1 3 L-1 3Z','#63888a'),
                        path('M-1 -2 L1 -2 M-1 0 L1 0','none','#dcca93',.5),ellipse(0,4,1.8,1.4,'#ddbd76',INK)])
    return ''.join([path('M-1 9 L-1 -25 L1 -25 L1 9Z','#a77f51'),
                    path('M0 -24 L0 8','none','#e1c693',.65),
                    path('M0 -42 L4 -30 L1 -24 L-1 -24 L-4 -30Z','#dceeee'),
                    path('M0 -38 L0 -27','none','#ffffff',.8),
                    path('M-2 -24 Q-8 -23 -4 -18 Q-2 -20 1 -20 Q7 -19 6 -14 Q11 -22 2 -24Z','#d97985',INK,.65)])

def mix_color(a,b,weight):
    aa=[int(a[i:i+2],16) for i in (1,3,5)]
    bb=[int(b[i:i+2],16) for i in (1,3,5)]
    return '#'+''.join(f'{round(x+(y-x)*weight):02x}' for x,y in zip(aa,bb))

def material_finish(key,kind,body):
    # Keep every authored contour/eye/limb. Only paints change; the imported
    # alpha silhouette is checked against the original 0.15 asset library.
    definitions=[]
    def linear(name,stops,start,end):
        definitions.append(f'<linearGradient id="{name}" gradientUnits="userSpaceOnUse" x1="{start[0]}" y1="{start[1]}" x2="{end[0]}" y2="{end[1]}">'+''.join(f'<stop offset="{offset}%" stop-color="{color}"/>' for offset,color in stops)+'</linearGradient>')
    def paint(color,name):
        nonlocal body
        body=body.replace('fill="'+color+'"','fill="url(#'+name+')"')
    linear('skin',[(0,'#edc8a0'),(36,'#e7b891'),(68,'#d4a17e'),(100,'#b77f69')],(-8,-10),(8,14))
    linear('skin_light',[(0,'#f4d5ae'),(55,'#f0c89e'),(100,'#dcb08b')],(-6,-8),(5,12))
    for color in ('#efbd9a','#efbc99','#f7cba5'):paint(color,'skin')
    for color in ('#ffe0b9','#ffdab3'):paint(color,'skin_light')
    linear('hair',[(0,'#686050'),(26,'#514a3f'),(61,'#39362f'),(100,'#24231f')],(-7,-19),(5,18))
    linear('hair_light',[(0,'#91836a'),(45,'#746b59'),(100,'#4e4a40')],(-9,-15),(4,14))
    for color in ('#30475d','#304559','#304659','#354c62','#30475b','#354d61'):paint(color,'hair')
    for color in ('#57788e','#49667d','#57778e'):paint(color,'hair_light')
    linear('iris',[(0,'#6b7462'),(52,'#6b7462'),(52,'#454e43'),(100,'#454e43')],(0,-2),(0,6))
    for color in ('#426b82','#567a76'):paint(color,'iris')
    for outfit,(base,light,high,shadow) in PALETTES.items():
        if outfit not in key:continue
        linear('cloth',[(0,mix_color(base,light,.43)),(24,mix_color(base,light,.26)),(56,base),(82,mix_color(base,shadow,.35)),(100,mix_color(base,shadow,.72))],(-8,-12),(8,15))
        linear('cloth_light',[(0,mix_color(light,high,.18)),(46,light),(76,mix_color(light,base,.26)),(100,mix_color(light,base,.45))],(-9,-12),(3,15))
        paint(base,'cloth');paint(light,'cloth_light')
    linear('leather',[(0,'#797c69'),(38,'#797c69'),(38,'#51594e'),(78,'#51594e'),(78,'#303a34'),(100,'#303a34')],(-2,-8),(3,3))
    paint('#324b5d','leather')
    linear('metal',[(0,'#777e6e'),(35,'#777e6e'),(35,'#dfd9ba'),(65,'#dfd9ba'),(65,'#aaaf96'),(100,'#aaaf96')],(-2,0),(2,0))
    for color in ('#d9eee9','#dceeee'):paint(color,'metal')
    linear('bronze',[(0,'#d2bc8b'),(50,'#d2bc8b'),(50,'#a58c61'),(100,'#a58c61')],(-5,-10),(5,12))
    for color in ('#e8c77e','#d5b46d','#dbbf82','#e2c07f','#ddbd76','#d1b674'):paint(color,'bronze')
    linear('sash',[(0,'#b6a379'),(65,'#b6a379'),(65,'#7f795e'),(100,'#7f795e')],(4,2),(10,14))
    paint('#e5c27b','sash')
    # Broad material masses carry the silhouette at gameplay scale. Reduce
    # decorative highlights so embroidery no longer reads as bright wires.
    for old,new in [('#eed6a4','#aa9c78'),('#8db0bd','#999174'),('#8aacba','#999174'),('#fff9e9','#e9e0c5'),('#fffdf3','#eee7cf'),('#b9e1d5','#b6b795'),('#243949','#282a24'),('#293f4a','#353b30'),('#1d3042','#282d27'),('#d97985','#a16e59'),('#ffffff','#e4dec6'),('#ed9e97','#b39a80'),('#56778b','#66695a'),('#668a9e','#777762'),('#7c9eb0','#85846c'),('#64869b','#787b65'),('#87aaba','#8e9276'),('#e7a090','#b79d82')]:
        body=body.replace(old,new)
    def detail(fragment):
        nonlocal body
        if body.startswith('<g transform='):
            body=body[:-4]+fragment+'</g>'
        else:
            body+=fragment
    # Fold accents follow the existing view transform and opaque cloth.
    if kind=='torso':
        outfit=next(name for name in PALETTES if name in key)
        base,light,high,shadow=PALETTES[outfit]
        body=body.replace('#d5c28d',mix_color(base,high,.25))
        detail(path('M-5 4 Q-6 7 -5 11 L-3.5 6Z',shadow,'none',extra='opacity=".45"')+
               path('M3 -6 Q2 -3 4 -1 L4.8 -2 Q3.7 -4 3 -6Z',shadow,'none',extra='opacity=".40"')+
               path('M-4.7 5 Q-5.2 8 -4.8 10 M3.8 5 Q2.6 8 3.2 11','none',mix_color(base,high,.42),.55)+
               path('M-8.5 8 Q-7 8.8 -5.8 8 M5.8 9 Q7.2 8.2 8.6 8','none',mix_color(base,shadow,.45),.55)+
               path('M-6 3.7 Q0 5.2 6 3.7','none',shadow,.65)+
               path('M-8 11 Q-7 9.5 -6.2 9.8 L-7.2 12Z',mix_color(base,shadow,.48),'none',extra='opacity=".34"')+
               path('M7 6 Q8.5 5.6 9.2 7 L8 7.7Z',mix_color(base,high,.52),'none',extra='opacity=".38"')+
               path('M-4 -5 Q-2 -2 -1 0 M-6 -4 L-4 -2','none','#fff0cd',.65)+
               path('M-10 13 Q-7 14.5 -5 13.3 M4 14 Q7 15 10 13','none',mix_color(base,high,.30),.5))
    if kind=='sleeve':
        outfit=next(name for name in PALETTES if name in key)
        detail(path('M1.5 3 Q.3 5 1.3 7 M-2.6 8 L-.5 9','none',mix_color(PALETTES[outfit][0],PALETTES[outfit][2],.40),.28))
    if kind=='hand':
        detail(path('M-1.8 .7 Q-.7 1.5 .1 .6 M.9 -1.3 Q1.8 -.5 1.5 .7','none','#bb8879',.35))
    # Short tapered ink flicks live inside the opaque masses, never the eyes.
    # They mirror with the authored view and remain stationary on the cloth.
    def flick(x,y,dx,dy,width=.33):
        length=(dx*dx+dy*dy)**.5
        nx=-dy/length*width;ny=dx/length*width
        return path(f'M{x} {y} Q{x+dx*.35+nx} {y+dy*.35+ny} {x+dx} {y+dy} Q{x+dx*.5-nx*.6} {y+dy*.5-ny*.6} {x} {y}Z',INK,'none')
    marks=[]
    if kind=='head':
        marks=[(-10,-8,2.7,-2.0,.30),(-9,-5,2.8,-2.0,.35),(-6,-12,2.4,-1.6,.28)]
    elif kind=='torso':
        marks=[(5.4,5,-2.1,1.6,.32),(5.8,7.3,-2.3,1.6,.36),(6.2,9.5,-2.0,1.4,.30),(-5.8,5.1,1.7,-1.1,.24)]
    elif kind=='sleeve':
        marks=[(2.5,4,-1.4,1.1,.25),(2.5,6,-1.6,1.0,.27)]
    elif kind=='boot':
        marks=[(-1.3,-4,1.7,.8,.23),(-1.3,-2.6,1.7,.8,.20)]
    elif kind=='tail' and 'ponytail' in key:
        marks=[(-3.5,9,2.3,1.0,.26),(-2.8,13,2.3,.8,.24)]
    elif kind=='weapon':
        marks=[(-.6,-29,1.1,1.0,.15),(-.6,-26,1.1,1.0,.15)]
    detail(''.join(flick(*mark) for mark in marks))
    return '<defs>'+''.join(definitions)+'</defs>'+body

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    records={}
    def emit(key,kind,body):
        x,y,w,h=RECTS[kind]
        body=material_finish(key,kind,body)
        source=f'<svg xmlns="http://www.w3.org/2000/svg" width="{w*8}" height="{h*8}" viewBox="{x} {y} {w} {h}">{body}</svg>'
        ET.fromstring(source)
        (OUT/(key+'.svg')).write_text(source,encoding='utf-8')
        records[key]={'path':'res://assets/vector/characters/'+key+'.svg','rect':RECTS[kind]}
    for d in range(8):
        emit(f'boot_{d}','boot',boot(d,'cloth'))
        emit(f'boot_leather_{d}','boot',boot(d,'leather'))
        for style in ('bamboo','sect'):
            emit(f'hat_{style}_{d}','hat',hat(style,d))
        for body in ('male','female'):
            for hair in ('topknot','ponytail'):
                emit(f'head_{body}_{hair}_{d}','head',head(body,hair,d))
                if d in (0,1,2,6,7):
                    emit(f'head_{body}_{hair}_{d}_closed','head',head(body,hair,d,closed=True))
            for outfit in PALETTES:
                emit(f'torso_{body}_{outfit}_{d}','torso',torso(body,outfit,d))
        for hair in ('topknot','ponytail'):
            emit(f'tail_{hair}_{d}','tail',tail(hair,d))
    for outfit in PALETTES:
        emit(f'sleeve_{outfit}','sleeve',sleeve(outfit))
    for body in ('male','female'):
        emit('hand_'+body,'hand',ellipse(0,0,2.5,2.8,'#f7cba5',INK,.7)+path('M-1 -1 Q1 -2 1.5 0','none','#ffe9c8',.65))
    for kind in ('sword','spear'):
        emit('weapon_'+kind,'weapon',weapon(kind))
    manifest={'revision':'ink20-character','style':'Warm storybook ink; layered eight-way character equipment and stationary hatching','source':'Original Bezier SVG cutout art; no external raster inputs','units_per_figure':60,'import_texels_per_unit':8,'directions':8,'cosmetic_combinations':216,'parts':records}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    (OUT/'README.md').write_text('# Illustrated character pieces\n\nOriginal editable SVG layers generated by `tools/generate_vector_characters.py`. Eight compass views, two body/face types, two hairstyles, three outfits, two boot styles, three hat options and sword/spear. Godot imports at eight texels per design unit and uses linear filtering. Live joint poses and weapon transforms are continuous; SVG textures are never upscaled old pixel artwork.\n',encoding='utf-8')
    print(f'VECTOR_CHARACTER_SOURCE_OK {len(records)} original SVG pieces; 8 views; 216 looks; 8x source resolution')

if __name__=='__main__':
    main()
