#!/usr/bin/env python3
"""Bake the original Gu 2D pixel cast; integer drawing only, no external artwork.

Run with Python + Pillow. Every frame has an 80x80 cell and a ground pivot at
(40,68). Eight compass views and all eleven semantic clips are drawn in place.
Outfit, hair, body and weapon are independently authored before compositing.
The atlas is final game artwork, not a scaled 3D render or a preview mockup.
"""
from __future__ import annotations

import argparse
import itertools
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/pixel/characters"
CELL = 80
PIVOT = (40, 68)
COLUMNS = 16
DIRECTIONS = ["down", "down_left", "left", "up_left", "up", "up_right", "right", "down_right"]
VECTORS = [(0, 1), (-.707, .707), (-1, 0), (-.707, -.707), (0, -1), (.707, -.707), (1, 0), (.707, .707)]
CLIPS = {"idle": (4, True), "walk": (8, True), "run": (8, True), "attack": (8, False),
         "defend": (4, True), "cast": (6, False), "channel": (6, True), "dash": (4, False),
         "hit": (4, False), "death": (6, False), "respawn": (6, False)}
INK = "#192c36"
SKIN = ["#aa6c59", "#d58f72", "#f0b98e", "#ffe0b5"]
HAIR = ["#172333", "#28394f", "#405873", "#67849a"]
GOLD = ["#8c663b", "#d6a85b", "#ffe5a0"]
BOOTS = ["#202c3e", "#3d4f63", "#7e8b96"]
OUTFITS = {
    "jade": ["#173e42", "#226365", "#348c82", "#63b9a3", "#a4ddbf"],
    "crimson": ["#512c45", "#8a374d", "#c15160", "#eb8882", "#ffd2b0"],
    "ivory": ["#485674", "#778cac", "#abbecb", "#e2e1d2", "#fff4da"],
}


def ip(p):
    return (round(p[0]), round(p[1]))


def add(p, q):
    return (p[0] + q[0], p[1] + q[1])


def mul(p, n):
    return (p[0] * n, p[1] * n)


def poly(d, points, color, outline=INK):
    points = [ip(p) for p in points]
    d.polygon(points, fill=color)
    if outline:
        d.line(points + [points[0]], fill=outline, width=1)


def rod(d, a, b, color, width=1):
    d.line([ip(a), ip(b)], fill=color, width=width)


def pixel(d, p, color):
    d.point(ip(p), fill=color)


def sleeve(d, shoulder, hand, colors, near=True):
    delta = (hand[0] - shoulder[0], hand[1] - shoulder[1])
    length = math.hypot(*delta) or 1
    perpendicular = (-delta[1] / length, delta[0] / length)
    # A folded elbow breaks the former straight tubes into two readable volumes.
    elbow = add(add(shoulder, mul(delta, .53)), mul(perpendicular, 1.0 if near else -1.0))
    poly(d, [add(shoulder, mul(perpendicular, 3)), add(elbow, mul(perpendicular, 3)),
             add(hand, mul(perpendicular, 2)), add(hand, mul(perpendicular, -2)),
             add(elbow, mul(perpendicular, -3)), add(shoulder, mul(perpendicular, -3))], colors[2 if near else 1])
    rod(d, add(shoulder, (-1, 0)), add(elbow, (-1, 0)), colors[3 if near else 2], 2)
    rod(d, add(elbow, mul(perpendicular, -2)), add(hand, mul(perpendicular, -2)), colors[0], 1)
    pixel(d, add(elbow, mul(perpendicular, 1)), colors[4 if near else 3])
    cuff = add(hand, mul(delta, -.12))
    rod(d, add(cuff, mul(perpendicular, -2)), add(cuff, mul(perpendicular, 2)), INK, 3)
    rod(d, add(cuff, mul(perpendicular, -2)), add(cuff, mul(perpendicular, 2)), GOLD[1], 1)
    h = ip(hand)
    poly(d, [(h[0]-2,h[1]-1),(h[0]+1,h[1]-2),(h[0]+2,h[1]),(h[0]+2,h[1]+2),(h[0]-1,h[1]+2)], SKIN[2])
    rod(d, (h[0]-1,h[1]), (h[0]+1,h[1]), SKIN[3])
    pixel(d, (h[0]+1,h[1]+2), SKIN[0])


def weapon(d, hand, other, kind, angle, attack, phase):
    if kind == "unarmed":
        # Impact sparks belong to the world effect, so the fist silhouette is
        # clean in portraits and paused animation inspection.
        return
    # Orthographic top-down foreshortening keeps the ground-plane reach shorter
    # vertically than horizontally, including weapons aimed towards the camera.
    axis = (math.cos(angle), math.sin(angle)*.70)
    perpendicular = (-axis[1], axis[0])
    if kind == "sword":
        start = add(hand, mul(axis, -3))
        blade_base = add(hand, mul(axis, 3))
        tip = add(hand, mul(axis, 23))
        rod(d, start, blade_base, INK, 4)
        rod(d, start, hand, "#687e80", 2)
        poly(d, [add(blade_base, mul(perpendicular, 2)), add(tip, mul(axis,-3)), tip,
                 add(blade_base, mul(perpendicular,-2))], "#a9c8d0")
        rod(d, add(blade_base,mul(perpendicular,-1)), add(tip, mul(axis,-3)), "#688398", 1)
        rod(d, blade_base, add(tip, mul(axis,-2)), "#f5ffec", 1)
        rod(d, add(blade_base,mul(perpendicular,-4)), add(blade_base,mul(perpendicular,4)), INK, 3)
        rod(d, add(blade_base,mul(perpendicular,-3)), add(blade_base,mul(perpendicular,3)), GOLD[1], 1)
        pixel(d, start, GOLD[2])
        if attack and phase in (2,3,4):
            for n in range(4):
                a = angle - .35 - n*.14
                p = add(hand, (math.cos(a)*20,math.sin(a)*14))
                rod(d, p, add(p, (math.cos(a-.3)*3, math.sin(a-.3)*2)), "#e5e8d0")
    else:
        rear = add(hand, mul(axis, -18))
        # Fully extended east/west thrusts keep a 2px transparent atlas margin.
        point = add(hand, mul(axis, 22))
        rod(d, rear, point, INK, 3)
        rod(d, rear, point, "#a88059", 1)
        base = add(point,mul(axis,-7))
        poly(d, [add(base,mul(perpendicular,3)), point, add(base,mul(perpendicular,-3)), add(base,mul(axis,-2))], "#a9c8d0")
        rod(d, base, point, "#f5ffec")
        rod(d,add(base,mul(perpendicular,-1)),add(point,mul(axis,-2)),"#688398",1)
        knot = add(base,mul(axis,-2))
        rod(d, add(knot,mul(perpendicular,-3)), add(knot,mul(perpendicular,3)), "#ba5360", 2)
        rod(d, add(knot,mul(perpendicular,2)), add(knot,add(mul(perpendicular,5),mul(axis,-4))), "#ed9383", 1)
        for grip in [hand,other]:
            g = ip(grip)
            d.rectangle((g[0]-1,g[1]-1,g[0]+1,g[1]+1), fill=SKIN[2])


def head(d, center, direction, hair, body, blink=False):
    """Draw a compact rounded skull, then hair, then visible facial landmarks.

    Eyes are deliberately below the lowest fringe step. The face contains no
    isolated antialias pixels: cheek, eye and temple clusters read at native 1x.
    """
    cx,cy = ip(center)
    fx,fy = VECTORS[direction]
    back = fy < -.2
    side = abs(fx) > .9
    threequarter = abs(fx) > .2 and not side
    sx = -1 if fx < 0 else 1
    width = 6 if side else 8
    outline=[(cx-width+3,cy-8),(cx+width-3,cy-8),(cx+width-1,cy-6),
             (cx+width,cy-3),(cx+width,cy+3),(cx+width-2,cy+6),
             (cx+3,cy+8),(cx-3,cy+8),(cx-width+1,cy+5),(cx-width,cy+1),
             (cx-width,cy-3),(cx-width+1,cy-6)]
    poly(d,outline,HAIR[1] if back else SKIN[2])
    if back:
        # Curved stepped shine crosses the crown; narrower vertical strands give
        # a rounded occipital mass, rather than the old uniform rectangle.
        poly(d,[(cx-5,cy-6),(cx+1,cy-7),(cx+5,cy-4),(cx+3,cy-1),
                (cx-3,cy),(cx-6,cy-2)],HAIR[2],None)
        rod(d,(cx-4,cy-5),(cx,cy-6),HAIR[3],1)
        poly(d,[(cx+4,cy-3),(cx+6,cy-1),(cx+5,cy+5),(cx+2,cy+7),
                (cx-3,cy+6),(cx-4,cy+3),(cx+1,cy+4)],HAIR[0],None)
        rod(d,(cx-6,cy+1),(cx-4,cy+5),HAIR[2],1)
        pixel(d,(cx-3,cy+3),HAIR[3])
        rod(d,(cx-2,cy),(cx-1,cy+3),HAIR[2],1)
        if threequarter:
            # Only an ear and a jaw edge are visible from rear three-quarter.
            ex=cx+sx*7
            rod(d,(ex,cy+2),(ex,cy+4),SKIN[1],2)
            pixel(d,(ex,cy+2),SKIN[3])
        rod(d,(cx-2,cy+7),(cx+2,cy+7),HAIR[0],1)
    else:
        # Warm light is a connected plane on the camera-left forehead/cheek.
        poly(d,[(cx-5,cy-3),(cx-2,cy-5),(cx+1,cy-4),(cx+1,cy+4),
                (cx-3,cy+6),(cx-5,cy+3)],SKIN[3],None)
        poly(d,[(cx+5,cy-3),(cx+7,cy-1),(cx+6,cy+4),(cx+3,cy+6),
                (cx+2,cy+7),(cx+1,cy+5),(cx+4,cy+3)],SKIN[1],None)
        # Ears sit outside the temple, separated from the hair contour.
        if not side:
            for sign in [-1,1]:
                ex=cx+sign*8
                rod(d,(ex,cy+1),(ex,cy+3),SKIN[1],1)
                pixel(d,(ex,cy+1),SKIN[3] if sign<0 else SKIN[2])
        if side:
            face_edge=cx+sx*6
            near=cx+sx*3
            a,b=sorted((near,face_edge))
            poly(d,[(a,cy-3),(b,cy-3),(face_edge,cy),
                    (face_edge+sx*2,cy+2),(face_edge,cy+3),
                    (face_edge,cy+5),(cx+sx*2,cy+7),(cx-sx,cy+5)],SKIN[2],None)
            rod(d,(face_edge,cy-1),(face_edge,cy+2),SKIN[3],1)
            pixel(d,(face_edge+sx,cy+2),SKIN[3])
            pixel(d,(face_edge,cy+5),SKIN[0])
            pixel(d,(cx+sx*3,cy+6),SKIN[3])
            rod(d,(cx-sx,cy+1),(cx-sx,cy+3),SKIN[1],2)
            pixel(d,(cx-sx,cy+1),SKIN[3])
        else:
            face_shift=2*sx if threequarter else 0
            pixel(d,(cx+face_shift,cy+4),SKIN[1])
            pixel(d,(cx+face_shift-sx,cy+3),SKIN[3])
            mouth_x=cx+face_shift
            rod(d,(mouth_x-1,cy+6),(mouth_x+1,cy+6),"#a35e59",1)
            pixel(d,(mouth_x-1,cy+5),"#ffc6a1")
            if body == "female":
                rod(d,(cx-5+face_shift,cy+4),(cx-4+face_shift,cy+4),"#e39686",1)
                pixel(d,(cx+5,cy+4),"#e39686")
        # Hairline is authored around the visible eye space, never across it.
        if side:
            poly(d,[(cx-4,cy-7),(cx+3,cy-7),(cx+5,cy-4),
                    (cx+sx*4,cy-1),(cx+sx*2,cy),(cx+sx,cy-2),
                    (cx-sx*2,cy),(cx-sx*3,cy+4),(cx-sx*5,cy+4),
                    (cx-6,cy-2)],HAIR[1],None)
        else:
            poly(d,[(cx-6,cy-6),(cx-3,cy-8),(cx+3,cy-8),(cx+6,cy-5),
                    (cx+7,cy-2),(cx+5,cy),(cx+4,cy-2),(cx+2,cy-1),
                    (cx,cy-3),(cx-2,cy-1),(cx-3,cy-3),(cx-5,cy-1),
                    (cx-7,cy+1),(cx-7,cy-3)],HAIR[1],None)
        poly(d,[(cx-5,cy-5),(cx-3,cy-7),(cx+1,cy-7),(cx+4,cy-5),
                (cx+2,cy-4),(cx-2,cy-4)],HAIR[2],None)
        rod(d,(cx-3,cy-6),(cx,cy-6),HAIR[3],1)
        pixel(d,(cx+3,cy-5),HAIR[3])
        rod(d,(cx-7 if not side else cx-sx*5,cy-1),
            (cx-7 if not side else cx-sx*5,cy+3),HAIR[0],1)
        # Face comes last. These highlights are intentionally carried through
        # every front/three-quarter/profile look and every animation frame.
        def eye(ex, far=False):
            if blink:
                rod(d,(ex-1,cy+2),(ex+1,cy+2),HAIR[0],1)
                return
            if far:
                d.rectangle((ex,cy+1,ex+1,cy+3),fill="#192837")
                pixel(d,(ex,cy+1),"#fff8da")
            else:
                d.rectangle((ex-1,cy+1,ex+1,cy+3),fill="#192837")
                rod(d,(ex-1,cy),(ex+1,cy),HAIR[0],1)
                pixel(d,(ex-1,cy+1),"#fff8da")
                pixel(d,(ex,cy+3),"#587b88")
            if body == "female":
                pixel(d,(ex+(1 if ex>cx else -1)*2,cy+1),HAIR[0])
        if side:
            eye(cx+sx*4)
        elif threequarter:
            eye(cx-sx,True)
            eye(cx+sx*4)
        else:
            eye(cx-3)
            eye(cx+3)
    if hair == "topknot":
        # Gold pin and rounded bun create two distinct material clusters.
        poly(d,[(cx-3,cy-9),(cx-3,cy-11),(cx-1,cy-12),
                (cx+2,cy-12),(cx+4,cy-10),(cx+3,cy-8),(cx-2,cy-8)],HAIR[1])
        rod(d,(cx-1,cy-11),(cx+2,cy-11),HAIR[2],1)
        pixel(d,(cx,cy-11),HAIR[3])
        rod(d,(cx-4,cy-8),(cx+5,cy-8),GOLD[0],2)
        rod(d,(cx-3,cy-8),(cx+5,cy-8),GOLD[2],1)
        pixel(d,(cx+6,cy-8),GOLD[1])
    else:
        tie=(cx-sx*6,cy-3)
        d.rectangle((tie[0]-1,tie[1]-1,tie[0]+1,tie[1]+1),fill=GOLD[1])
        pixel(d,tie,GOLD[2])
    if body == "female":
        f=(cx-sx*6,cy-4)
        for delta in [(-1,0),(1,0),(0,-1),(0,1)]:
            pixel(d,add(f,delta),"#f3aea1")
        pixel(d,f,GOLD[2])


def fallen(d, appearance, frame, direction):
    colors=OUTFITS[appearance["outfit"]]
    left=direction in (1,2,3)
    cx=27 if not left else 53
    cy=61
    poly(d, [(cx-6,cy-5),(cx+5,cy-5),(cx+7,cy-2),(cx+6,cy+4),(cx-5,cy+5),(cx-7,cy+1)],HAIR[1])
    d.rectangle((cx-3,cy-1,cx+3,cy+3),fill=SKIN[2])
    rod(d,(cx-2,cy),(cx,cy),HAIR[0])
    rod(d,(cx+2,cy),(cx+3,cy),HAIR[0])
    start=cx+5 if not left else cx-5
    end=cx+28 if not left else cx-28
    lo,hi=sorted((start,end))
    poly(d,[(lo,55),(hi-3,56),(hi+1,61),(hi,66),(lo,67),(lo-3,63)],colors[2])
    rod(d,(lo+2,58),(hi-3,58),colors[3],2)
    rod(d,(lo+4,63),(hi-1,63),colors[1],2)
    rod(d,(hi-7,56),(hi-7,66),GOLD[1],1)
    rod(d,(end,60),(end+(5 if not left else -5),60),BOOTS[1],4)
    rod(d,(end,65),(end+(5 if not left else -5),65),BOOTS[0],4)
    hand=(lo+9,66)
    d.rectangle((hand[0]-2,hand[1]-1,hand[0]+2,hand[1]+1),fill=SKIN[2])
    if appearance["weapon"] == "sword":
        rod(d,(32,71),(54,73),INK,3)
        rod(d,(32,71),(54,73),"#c8d5d1",1)
        rod(d,(35,69),(34,73),GOLD[1],1)
    elif appearance["weapon"] == "spear":
        rod(d,(14,72),(65,72),INK,2)
        rod(d,(14,72),(59,72),"#a88059",1)
        poly(d,[(59,70),(67,72),(59,74)],"#c8d5d1")
    return {"R":list(hand),"L":[hand[0]-6,hand[1]-4]}


def cloth(d, center, width, colors, direction, bob, sway, body):
    """Layered cross-collar tunic, belt and split overskirt with placed folds."""
    cx=round(center[0])
    top=41+bob
    back=direction in (3,4,5)
    side=direction in (2,6)
    hem=round(sway)
    shoulder=width+1
    waist=width-2
    # Main body has shaped shoulders and a narrow waist; the knees no longer
    # read as part of an unbroken triangular dress silhouette.
    poly(d,[(cx-width+2,top),(cx+width-2,top),(cx+shoulder,top+3),
            (cx+width,top+8),(cx+waist,top+12),(cx+width+1+hem,top+18),
            (cx+width+hem,top+21),(cx+2+hem,top+21),(cx,top+17),
            (cx-2+hem,top+21),(cx-width+hem,top+21),
            (cx-width-1+hem,top+18),(cx-waist,top+12),
            (cx-width,top+8),(cx-shoulder,top+3)],colors[2])
    # Connected lit and shaded planes establish cloth volume without speckles.
    poly(d,[(cx-width+2,top+3),(cx-2,top+2),(cx-1,top+11),
            (cx-3+hem,top+20),(cx-width+2+hem,top+19),
            (cx-width+4,top+12)],colors[3],None)
    poly(d,[(cx+2,top+4),(cx+width-1,top+4),(cx+waist-1,top+12),
            (cx+width-1+hem,top+19),(cx+3+hem,top+20)],colors[1],None)
    # Shoulder seams are small lit clusters, not broad bright UI-like borders.
    rod(d,(cx-width+3,top+2),(cx-width+1,top+5),colors[4],1)
    rod(d,(cx+width-3,top+2),(cx+width-1,top+4),colors[3],1)
    if back:
        rod(d,(cx-3,top+2),(cx+3,top+2),colors[0],1)
        rod(d,(cx-2,top+3),(cx+2,top+3),GOLD[1],1)
        # Back crest is a diamond leaf sewn into the darker waist plane.
        poly(d,[(cx,top+5),(cx+2,top+7),(cx,top+10),(cx-2,top+7)],colors[4],None)
        rod(d,(cx,top+6),(cx,top+9),GOLD[1],1)
        rod(d,(cx-4,top+8),(cx-3,top+11),colors[0],1)
    elif side:
        sign=-1 if direction==2 else 1
        rod(d,(cx-sign,top+1),(cx+sign*3,top+7),"#f6dfb2",2)
        rod(d,(cx+sign*3,top+7),(cx+sign,top+11),GOLD[0],1)
        rod(d,(cx-sign*3,top+7),(cx-sign*2,top+10),colors[0],1)
    else:
        # Two narrow ivory strips form a true crossed collar; the old broad
        # pale chest wedge is gone so the weapon and face lead the silhouette.
        rod(d,(cx-3,top+1),(cx+2,top+7),"#f6dfb2",2)
        rod(d,(cx+3,top+1),(cx-2,top+8),"#e0c193",2)
        rod(d,(cx+3,top+2),(cx-3,top+9),GOLD[0],1)
        pixel(d,(cx-2,top+2),"#fff3d1")
        rod(d,(cx-4,top+8),(cx-4,top+10),colors[0],1)
        # Diagonal embroidery on the lit lapel uses a 2px connected cluster.
        pixel(d,(cx-5,top+7),colors[4])
        pixel(d,(cx-4,top+8),colors[4])
    # Split skirt panels, with offset hems and a dark central negative space.
    rod(d,(cx-1,top+13),(cx-2+hem,top+20),colors[0],2)
    rod(d,(cx+1,top+13),(cx+2+hem,top+20),colors[4],1)
    rod(d,(cx-5,top+14),(cx-6+hem,top+18),colors[4],1)
    rod(d,(cx+4,top+14),(cx+6+hem,top+18),colors[0],1)
    rod(d,(cx-width+1+hem,top+20),(cx-3+hem,top+20),GOLD[1],1)
    rod(d,(cx+3+hem,top+20),(cx+width-1+hem,top+20),GOLD[1],1)
    pixel(d,(cx-width+2+hem,top+19),GOLD[2])
    pixel(d,(cx+width-2+hem,top+19),GOLD[2])
    # A dark leather sash and small buckle make the torso proportions legible.
    rod(d,(cx-waist,top+11),(cx+waist,top+11),"#263345",3)
    rod(d,(cx-waist+1,top+10),(cx+waist-1,top+10),"#76644d",1)
    buckle_x=cx+(-2 if back else 1)
    d.rectangle((buckle_x-1,top+10,buckle_x+1,top+12),fill=GOLD[0])
    pixel(d,(buckle_x,top+10),GOLD[2])
    pixel(d,(buckle_x+1,top+11),GOLD[1])
    tassel_x=cx+(-4 if back else 4)
    rod(d,(tassel_x,top+12),(tassel_x+1+hem,top+16),GOLD[1],1)
    pixel(d,(tassel_x+1+hem,top+17),GOLD[2])
    if body=="female":
        # Smaller waist plus a crimson ribbon gives a body-specific outfit
        # silhouette without changing the gameplay root or cosmetic interface.
        rod(d,(cx-4,top+11),(cx+4,top+11),"#976157",1)
        pixel(d,(cx-4,top+12),"#efa38c")


def boot(d, foot, knee, facing, near=True, lifted=0):
    colors=BOOTS if near else ["#1b2635","#2c3b50","#62728a"]
    rod(d,knee,foot,INK,5)
    rod(d,add(knee,(-1,0)),add(foot,(-1,0)),colors[1],3)
    x,y=ip(foot)
    fx,fy=facing
    toe=ip((fx*2,fy*.65))
    # Boot shaft, welt and toe are separately shaded. Raised soles stay visibly
    # higher than the planted boot through the locomotion swing segment.
    poly(d,[(x-2,y-4),(x+1,y-4),(x+2,y-1),
            (x+3+toe[0],y+toe[1]),(x+3+toe[0],y+2+toe[1]),
            (x-2+toe[0],y+2+toe[1]),(x-3,y)],colors[0])
    rod(d,(x-1,y-3),(x+1,y-3),colors[2],1)
    rod(d,(x-1,y),(x+1+toe[0],y+toe[1]),colors[1],1)
    rod(d,(x-1+toe[0],y+1+toe[1]),(x+2+toe[0],y+1+toe[1]),"#ac936e",1)
    if lifted:
        pixel(d,(x+1+toe[0],y+toe[1]),colors[2])


def draw_character(appearance, action, direction, frame):
    image=Image.new("RGBA",(CELL,CELL),(0,0,0,0))
    d=ImageDraw.Draw(image)
    if action == "death" and frame>=3:
        return image,fallen(d,appearance,frame,direction)
    colors=OUTFITS[appearance["outfit"]]
    fx,fy=VECTORS[direction]
    forward=(fx,fy*.65)
    perp=(-fy,fx*.42)
    count=CLIPS[action][0]
    phase=frame/max(1,count-1)
    moving=action in ("walk","run")
    gait=math.sin(frame/count*math.tau) if moving else 0
    # Artist-authored displacement samples are intentionally asymmetric: contact
    # is brisk, the cloth and hair settle one sample after the body changes.
    bob=0
    lean=0
    shift=(0,0)
    twist=0
    if action=="idle":
        bob=[0,0,-1,0][frame]
    elif moving:
        bob=([0,0,-1,0,0,0,-1,0] if action=="walk" else [1,0,-1,0,1,0,-1,0])[frame]
        lean=1 if action=="walk" else 3
    elif action=="attack":
        bob=[0,1,2,-1,0,1,0,0][frame]
        push=[0,-1,-2,2,2,1,0,0][frame]
        shift=mul(forward,push)
        twist=[0,-1,-2,1,2,1,0,0][frame]
    elif action=="defend":
        bob=2+(1 if frame==2 else 0)
        lean=-1
    elif action in ("cast","channel"):
        bob=([1,1,0,-1,0,0][frame] if action=="cast" else [0,-1,-1,0,0,0][frame])
    elif action=="dash":
        bob=[3,1,0,1][frame]
        lean=[3,6,5,1][frame]
        shift=mul(forward,[0,2,3,0][frame])
    elif action=="hit":
        shift=mul(forward,[-3,-4,-2,0][frame])
        bob=[0,2,1,0][frame]
        lean=-2
    elif action=="death":
        bob=[0,4,9][frame]
        lean=frame*2
    elif action=="respawn":
        bob=[7,6,3,0,-1,0][frame]
        lean=[-2,-2,-1,0,0,0][frame]
    center=add((40,0),shift)
    chest=add((center[0],45+bob),mul((fx,fy*.30),lean))
    cloth_center=(chest[0],0)
    width=8 if appearance["body"]=="male" else 7
    if abs(fx)>.9:
        width-=2
    shoulders={"L":add(chest,mul(perp,-6.0)),"R":add(chest,mul(perp,6.0))}
    arm_swing=gait*(3 if action=="run" else 2)
    hands={"L":add(shoulders["L"],(-fx*arm_swing,8+arm_swing)),
           "R":add(shoulders["R"],(fx*arm_swing,8-arm_swing))}
    angle=-2.04 if hands["R"][0]<chest[0] else -1.10
    if appearance["weapon"]=="unarmed" and action=="idle":
        hands["L"]=add(chest,(-perp[0]*6+fx*2,3-perp[1]*6))
        hands["R"]=add(chest,(perp[0]*6+fx*4,2+perp[1]*6))
    if appearance["weapon"]=="spear":
        angle=-1.05 if fx>=0 else -2.09
        hands["R"]=add(chest,(4 if fx>=0 else -4,8))
        hands["L"]=add(hands["R"],(math.cos(angle)*8,math.sin(angle)*.70*8))
    if action=="idle":
        # Four quiet breathing keys: wrists lift before the chest settles, and
        # release after it. Foot landmarks remain planted through the loop.
        breath=[0,-1,-1,1][frame]
        hands={side:add(point,(0,breath)) for side,point in hands.items()}
        if frame==1:
            width+=1
    if action=="attack":
        aim_angle=math.atan2(fy*.65,fx)
        if appearance["weapon"]=="sword":
            swing=[-1.1,-1.8,-1.9,-.25,.70,1.0,.45,-1.1][frame]
            angle=aim_angle+swing
            reach=[3,4,5,11,11,8,5,3][frame]
            hands["R"]=add(chest,(math.cos(angle)*reach,math.sin(angle)*.70*reach+3))
            hands["L"]=add(chest,add(mul(perp,-5),mul(forward,-2)))
            hands["L"]=add(hands["L"],(0,5))
        elif appearance["weapon"]=="spear":
            angle=aim_angle
            reach=[0,-4,-3,11,12,9,4,0][frame]
            hands["R"]=add(chest,add(mul(forward,reach),(0,5)))
            axis=(math.cos(angle),math.sin(angle)*.70)
            hands["L"]=add(hands["R"],mul(axis,8))
        else:
            angle=aim_angle
            reach=[2,-2,-3,14,13,6,3,2][frame]
            hands["R"]=add(chest,add(mul(forward,reach),(0,1)))
            hands["L"]=add(chest,add(mul(perp,-5),mul(forward,3)))
    elif action=="defend":
        # Compact low guard: wrists protect the chest while the planted feet
        # widen, instead of the former erect idle body with moved hands.
        hands["R"]=add(chest,add(mul(forward,5),mul(perp,4)))
        hands["L"]=add(chest,add(mul(forward,4),mul(perp,-4)))
        if appearance["weapon"]=="sword":
            angle=math.atan2(fy*.35,fx)-1.05
        elif appearance["weapon"]=="spear":
            angle=math.atan2(fy*.35,fx)-.22
            hands["L"]=add(hands["R"],(math.cos(angle)*8,math.sin(angle)*.70*8))
        hands={side:add(point,(0,[0,-1,0,1][frame])) for side,point in hands.items()}
    elif action in ("cast","channel"):
        lift=([0,4,10,13,7,1][frame] if action=="cast" else 9+[0,1,2,1,0,-1][frame])
        # The casting hand reaches in the aim direction and above the shoulder;
        # the weapon hand trails low, preserving the face and spell silhouette.
        hands["L"]=add(chest,add(mul(perp,-7),mul(forward,4)))
        hands["L"]=add(hands["L"],(0,3-lift))
        hands["R"]=add(chest,add(mul(perp,7),mul(forward,-2)))
        hands["R"]=add(hands["R"],(0,7))
        angle=-2.1 if hands["R"][0]<chest[0] else -1.0
        if appearance["weapon"]=="spear":
            # Grip the staff low while the free hand channels. It intentionally
            # leaves the normal two-hand stance for this semantic action.
            angle=-2.7 if fx<0 else -.45
    elif action=="dash":
        hands["L"]=add(chest,add(mul(forward,-7),mul(perp,-3)))
        hands["R"]=add(chest,add(mul(forward,-7),mul(perp,3)))
        hands["L"]=add(hands["L"],(0,4))
        hands["R"]=add(hands["R"],(0,4))
        angle=math.atan2(-fy*.6,-fx)
    elif action=="hit":
        hands["L"]=add(chest,(-6,1))
        hands["R"]=add(chest,(6,-1))
    hair_sway=round(math.sin(frame/count*math.tau-.7)*2) if moving else twist
    cloth_sway=round(math.sin(frame/count*math.tau-.8)*(2 if action=="run" else 1)) if moving else -twist
    if action=="dash":
        hair_sway=-round(fx*3)
        cloth_sway=-round(fx*3)
    # Ponytail is behind the body, but its taper and highlight survive the larger
    # shaded head. The delayed swing makes the hairstyle visibly independent.
    if appearance["hair"]=="ponytail":
        base=(round(chest[0]-fx*5),31+bob)
        swing=hair_sway-round(fx*lean)
        poly(d,[add(base,(-3,-1)),add(base,(2,-1)),add(base,(3+swing,8)),
                add(base,(1+swing,17)),add(base,(-1+swing,20)),
                add(base,(-4+swing,16)),add(base,(-5,7))],HAIR[1])
        rod(d,add(base,(-1,3)),add(base,(swing-1,14)),HAIR[2],2)
        pixel(d,add(base,(swing-1,15)),HAIR[3])
    # Painter's depth order puts the far boot behind the near one. Each gait
    # has a planted stance half and an independently lifted recovery half.
    near="R" if fx>=0 else "L"
    far="L" if near=="R" else "R"
    feet={}
    for side,sign in [("L",-1),("R",1)]:
        reach=0
        lift=0
        if moving:
            leg_frame=(frame+(4 if side=="R" else 0))%8
            reach=[3,1,-1,-3,-3,-1,1,3][leg_frame]*(1.5 if action=="run" else 1)
            lift=([0,0,0,0,1,2,2,1] if action=="walk" else [0,0,0,0,2,4,4,2])[leg_frame]
        elif action=="attack":
            reach=sign*[0,1,1,3,3,2,1,0][frame]
        elif action=="defend":
            reach=sign*2
        elif action=="dash":
            reach=sign*[1,5,4,1][frame]
            lift=2 if side=="R" and frame in (1,2) else 0
        foot=add((40,65),add(mul(perp,sign*(4 if action=="defend" else 3.5)),mul(forward,reach)))
        foot=add(foot,(0,-lift))
        knee=add((40,58+bob),mul(perp,sign*3))
        feet[side]=(foot,knee,lift)
    for side in [far,near]:
        foot,knee,lift=feet[side]
        boot(d,foot,knee,(fx,fy),side==near,lift)
    sleeve(d,shoulders[far],hands[far],colors,False)
    # Exposed neck is a small warm cluster, rather than a pale triangular chest.
    d.rectangle((round(chest[0])-2,39+bob,round(chest[0])+2,43+bob),fill=SKIN[1])
    cloth(d,cloth_center,width,colors,direction,bob,cloth_sway,appearance["body"])
    sleeve(d,shoulders[near],hands[near],colors,True)
    head_center=(chest[0]+round(fx*(1 if moving else 0)),32+bob-round(lean*.18))
    head(d,head_center,direction,appearance["hair"],appearance["body"])
    weapon(d,hands["R"],hands["L"],appearance["weapon"],angle,action=="attack",frame)
    if action in ("cast","channel") and frame>0:
        orb=add(hands["L"],(0,-4))
        ox,oy=ip(orb)
        poly(d,[(ox,oy-3),(ox+3,oy),(ox,oy+3),(ox-3,oy)],"#30a99d",None)
        rod(d,(ox-1,oy-1),(ox+1,oy+1),"#d1ffe0",2)
        pixel(d,orb,"#fff1b3")
        for n in range(3):
            a=frame*1.05+n*math.tau/3
            pixel(d,add(orb,(math.cos(a)*6,math.sin(a)*5)),"#ffe0a1")
    if action=="respawn" and frame<4:
        for x,y in [(32,26),(48,36),(29,49),(52,56)]:
            y-=frame*3
            rod(d,(x,y-2),(x,y+2),GOLD[2],1)
            rod(d,(x-1,y),(x+1,y),"#fff0ca",1)
    return image,{side:list(ip(point)) for side,point in hands.items()}


def bake():
    OUT.mkdir(parents=True,exist_ok=True)
    total=sum(v[0]*8 for v in CLIPS.values())
    manifest={"format":"GuPixelCharacter/1","source":"tools/generate_pixel_characters.py",
              "cell_size":[CELL,CELL],"pivot":list(PIVOT),"native_height":48,
              "directions":DIRECTIONS,"clips":{k:{"frames":v[0],"loop":v[1]} for k,v in CLIPS.items()},
              "appearances":{}}
    for body,outfit,hair,kind in itertools.product(["male","female"],OUTFITS,["topknot","ponytail"],["sword","spear","unarmed"]):
        appearance={"body":body,"outfit":outfit,"hair":hair,"weapon":kind}
        key="_".join([body,outfit,hair,kind])
        atlas=Image.new("RGBA",(COLUMNS*CELL,math.ceil(total/COLUMNS)*CELL),(0,0,0,0))
        data={"path":"res://assets/pixel/characters/"+key+".png","columns":COLUMNS,"frames":{},"hands":{}}
        index=0
        for action,(count,_) in CLIPS.items():
            data["frames"][action]=[]
            data["hands"][action]=[]
            for direction in range(8):
                ids=[]
                anchors=[]
                for frame in range(count):
                    sprite,hands=draw_character(appearance,action,direction,frame)
                    bounds=sprite.getbbox()
                    assert bounds and min(bounds[:2])>=1 and max(bounds[2:])<=79, (key,action,direction,frame,bounds)
                    atlas.paste(sprite,((index%COLUMNS)*CELL,(index//COLUMNS)*CELL))
                    ids.append(index)
                    anchors.append(hands)
                    index+=1
                data["frames"][action].append(ids)
                data["hands"][action].append(anchors)
        atlas.save(OUT/(key+".png"),optimize=True)
        manifest["appearances"][key]=data
        print(key,flush=True)
    (OUT/"manifest.json").write_text(json.dumps(manifest,separators=(",",":")),encoding="utf-8")
    showcase(manifest)
    print(f"Baked {len(manifest['appearances'])} identities, {total} frames each, 80x80 RGBA.")


def showcase(manifest):
    # This contact sheet uses exact atlas frame crops, enlarged with NEAREST.
    bg=Image.new("RGB",(1280,1120),"#283b45")
    d=ImageDraw.Draw(bg)
    font=ImageFont.load_default(size=18)
    d.text((32,18),"GU MASTER / ORIGINAL 2D PIXEL CAST",font=font,fill="#f6dc9c")
    d.text((32,49),"8 compass views | 11 motion states | 36 modular identities",font=font,fill="#abc4bf")
    def cell(key,action,direction,frame,x,y,scale=2):
        info=manifest["appearances"][key]
        index=info["frames"][action][direction][frame]
        with Image.open(OUT/Path(info["path"]).name) as atlas:
            crop=atlas.crop(((index%16)*80,(index//16)*80,(index%16+1)*80,(index//16+1)*80))
            bg.paste(crop.resize((80*scale,80*scale),Image.Resampling.NEAREST),(x,y),crop.resize((80*scale,80*scale),Image.Resampling.NEAREST))
    for n,name in enumerate(DIRECTIONS):
        d.text((22+n*156,90),name,font=font,fill="#9ab6b7")
        cell("male_jade_topknot_sword","idle",n,0,n*156,106)
    d.line((20,280,1250,280),fill="#49616a",width=1)
    d.text((32,295),"Wardrobe / body + cloth + hair + weapon",font=font,fill="#f6dc9c")
    cases=["male_jade_topknot_sword","female_jade_ponytail_sword","male_crimson_topknot_spear",
           "female_crimson_ponytail_spear","male_ivory_topknot_unarmed","female_ivory_ponytail_unarmed"]
    for n,key in enumerate(cases):
        cell(key,"idle",7 if n%2==0 else 1,0,40+n*196,322)
        d.text((44+n*196,486),key.split("_")[0]+" / "+key.split("_")[1],font=font,fill="#abc4bf")
    d.line((20,530,1250,530),fill="#49616a",width=1)
    d.text((32,545),"Movement and combat / actual baked game frames",font=font,fill="#f6dc9c")
    cases2=[("walk",2),("run",2),("attack",3),("defend",0),("cast",3),("channel",2)]
    for n,(action,frame) in enumerate(cases2):
        cell("male_jade_topknot_sword",action,7,frame,40+n*196,578)
        d.text((75+n*196,750),action,font=font,fill="#abc4bf")
    d.line((20,795,1250,795),fill="#49616a",width=1)
    cases3=[("male_crimson_topknot_sword","attack",4),("male_jade_topknot_spear","attack",4),
            ("female_ivory_ponytail_unarmed","attack",3),("female_crimson_ponytail_sword","hit",0),
            ("male_jade_topknot_sword","death",5),("female_jade_ponytail_sword","respawn",2)]
    labels=["sword slash","spear thrust","unarmed strike","impact","fallen","respawn"]
    for n,(key,action,frame) in enumerate(cases3):
        cell(key,action,6,frame,40+n*196,820)
        d.text((50+n*196,994),labels[n],font=font,fill="#abc4bf")
    d.text((32,1070),"Native pixels, transparent frames, fixed foot pivot. No 3D renderer or antialiasing.",font=font,fill="#738f98")
    bg.save(OUT/"showcase.png")


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--showcase-only",action="store_true")
    args=parser.parse_args()
    if args.showcase_only:
        showcase(json.loads((OUT/"manifest.json").read_text(encoding="utf-8")))
    else:
        bake()
