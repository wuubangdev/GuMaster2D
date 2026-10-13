"""Author editable vector cloth assets, registered to each approved view.

These are new SVG drawings of concealed cloth, not edited concept bitmaps.
Visible collar, belt ornament and robe paint remain on the isolated UV layer.
"""
from pathlib import Path
import math
import re


def hull(points):
    points = sorted(set(tuple(p) for p in points))
    def cross(a, b, c):
        return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
    lo, hi = [], []
    for line, seq in ((lo, points), (hi, reversed(points))):
        for p in seq:
            while len(line)>1 and cross(line[-2], line[-1], p)<=0:
                line.pop()
            line.append(p)
    return [list(p) for p in lo[:-1]+hi[:-1]]


def stitch_x(seam, y):
    seam = seam[:4]
    if y<=seam[0][1]:
        return seam[0][0]
    for a, b in zip(seam, seam[1:]):
        if y<=b[1]:
            return a[0]+(b[0]-a[0])*(y-a[1])/(b[1]-a[1])
    return seam[-1][0]


def clean_coat(view):
    """The body side ends at its stitch, not at the old resting sleeve edge."""
    coat = view['parts']['torso']['polygon']
    seams = sorted(view['sleeve_seams'].values(), key=lambda p: p[0][0])
    low, high = [], []
    ys = sorted(set([p[1] for p in coat]+[p[1] for s in seams for p in s[:4]]+
                    [view['ground'][1]-92, view['ground'][1]-83]))
    for y in ys:
        xs = []
        for a, b in zip(coat, coat[1:]+coat[:1]):
            if min(a[1], b[1])<=y<=max(a[1], b[1]):
                if a[1]==b[1]:
                    xs.extend((a[0], b[0]))
                else:
                    xs.append(a[0]+(b[0]-a[0])*(y-a[1])/(b[1]-a[1]))
        if not xs:
            continue
        left, right = min(xs), max(xs)
        for i, seam in enumerate(seams):
            start, end = seam[0][1], seam[3][1]
            # Blend back into the independently moving skirt below the waist.
            if start<=y<end+18:
                w = 1 if y<=end else (end+18-y)/18
                at = stitch_x(seam, y)
                if i==0: left=max(left, left+(at-left)*w)
                else: right=min(right, right+(at-right)*w)
        if right-left<.01:
            if not low or low[-1]!=[left, y]: low.append([round(left, 3), y])
            continue
        low.append([round(left, 3), y]); high.append([round(right, 3), y])
    result = low+list(reversed(high))
    return [p for i, p in enumerate(result) if p!=result[i-1]]


def svg(path, bounds, content):
    x, y, w, h = bounds
    path.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{math.ceil(w*4)}" '
                    f'height="{math.ceil(h*4)}" viewBox="{x} {y} {w} {h}">'
                    f'{content}</svg>\n', encoding='utf-8')


def author(view_key, view, output):
    folder = output/'parts'/view_key
    folder.mkdir(parents=True, exist_ok=True)
    cx, gy = view['ground']; scale=view['scale']
    # The old +/-90 rectangle also captured ponytail/ear ink in profile.
    # Keep the complete INNER stitch, but trace a close outer garment edge.
    for key, seam in list(view['sleeve_seams'].items()):
        outline=view['parts'][key]['polygon']; shoulder=view['parts'][key]['joints'][0]
        sign=-1 if shoulder[0]<cx else 1
        outer=[]
        for y in [seam[0][1]-2]+[p[1] for p in seam[:4]]+[seam[3][1]+2]:
            xs=[]
            for a,b in zip(outline,outline[1:]+outline[:1]):
                if a[1]!=b[1] and min(a[1],b[1])<=y<=max(a[1],b[1]):
                    xs.append(a[0]+(b[0]-a[0])*(y-a[1])/(b[1]-a[1]))
            edge=(min(xs) if sign<0 else max(xs)) if xs else shoulder[0]+sign*9
            outer.append([round(edge+sign*4,3),y])
        view['sleeve_seams'][key]=seam[:4]+list(reversed(outer))
    coat = clean_coat(view)
    view['body_core'] = coat
    # UV overlay only: it must never carry pixels outside the clean body.
    view['torso_keep'] = coat
    native = [[(x-cx)*scale, (y-gy)*scale] for x, y in coat]
    xmin=min(p[0] for p in native); ymin=min(p[1] for p in native)
    xmax=max(p[0] for p in native); ymax=max(p[1] for p in native)
    bounds=[xmin-.4, ymin-.4, xmax-xmin+.8, ymax-ymin+.8]
    points=' '.join(f'{x:.4f},{y:.4f}' for x, y in native)
    belt=[(p-gy)*scale for p in view['waist']]
    # Broad wash and sparse folds stay readable at 48/64 world pixels.
    defs=f'<defs><clipPath id="cloth"><polygon points="{points}"/></clipPath><linearGradient id="wash"><stop stop-color="#596451"/><stop offset=".48" stop-color="#717962"/><stop offset="1" stop-color="#555f4d"/></linearGradient><linearGradient id="belt" x2="0" y2="1"><stop stop-color="#736046"/><stop offset="1" stop-color="#463c2f"/></linearGradient></defs>'
    content=defs+f'<g clip-path="url(#cloth)"><polygon points="{points}" fill="url(#wash)"/>'
    content+=f'<path d="M {xmin+1:.3f} {ymin+2:.3f} Q 0 {belt[0]-2:.3f} {xmax-1:.3f} {belt[0]-1:.3f} L {xmax-2:.3f} {ymax-1:.3f} Q 1 {belt[1]+3:.3f} {xmin+1:.3f} {ymin+2:.3f}" fill="#a1a383" opacity=".10"/>'
    for side in (-1,1):
        x=side*(xmax-xmin)*.23
        content+=f'<path d="M {x*.65:.3f} {belt[1]+1:.3f} Q {x*.55:.3f} {belt[1]+5:.3f} {x:.3f} {ymax-1.3:.3f}" fill="none" stroke="#3e4739" stroke-width=".23" opacity=".36"/>'
    content+=f'<rect x="{xmin}" y="{belt[0]}" width="{xmax-xmin}" height="{belt[1]-belt[0]}" fill="url(#belt)"/><path d="M {xmin} {belt[0]+.2} H {xmax}" stroke="#9b8359" stroke-width=".19" opacity=".65"/></g>'
    svg(folder/'coat.svg', bounds, content)
    assets={'coat':{'path':f'res://assets/characters/concept-rig/parts/{view_key}/coat.svg','bounds':bounds,'anatomy':'cloth_only','source_polygon':coat}, 'sleeves':{}}
    for side in ('L','R'):
        key='arm_'+side; part=view['parts'][key]
        # The render mesh contains the complete seam zone. Ownership still
        # rejects paper, head and all other parts before pigment filtering.
        part['render_polygon']=hull(part['polygon']+view['sleeve_seams'][key])
        joints=[[(x-cx)*scale,(y-gy)*scale] for x,y in part['joints']]
        root, elbow, palm=joints
        dx,dy=elbow[0]-root[0],elbow[1]-root[1]; length=math.hypot(dx,dy)
        axis=(dx/length,dy/length); normal=(-axis[1],axis[0])
        radius=1.85 if view['source']=='original' else 1.75
        polygon=[]
        for sign in (-1,1):
            for step in (range(9) if sign<0 else reversed(range(9))):
                t=step/8; along=-.65+(length+.85)*t
                width=radius*(.70+.28*math.sin(math.pi*t)-.06*t)
                polygon.append([root[0]+axis[0]*along+normal[0]*width*sign,
                                root[1]+axis[1]*along+normal[1]*width*sign])
        px=min(p[0] for p in polygon)-.3; py=min(p[1] for p in polygon)-.3
        pw=max(p[0] for p in polygon)-px+.3; ph=max(p[1] for p in polygon)-py+.3
        sleeve_bounds=[px,py,pw,ph]
        sleeve_points=' '.join(f'{x:.4f},{y:.4f}' for x,y in polygon)
        # Concealed arm has actual paint, not the old untextured green tube.
        wash='<defs><linearGradient id="wash"><stop stop-color="#485642"/><stop offset=".5" stop-color="#727d60"/><stop offset="1" stop-color="#657052"/></linearGradient></defs>'
        base=wash+f'<polygon points="{sleeve_points}" fill="url(#wash)" stroke="#332c24" stroke-width=".26" stroke-linejoin="round"/>'
        for fraction in (.25,.61):
            x=root[0]+dx*fraction; y=root[1]+dy*fraction
            base+=f'<path d="M {x-normal[0]*.5:.3f} {y-normal[1]*.5:.3f} l {axis[0]*1.1:.3f} {axis[1]*1.1:.3f}" stroke="#a5aa83" stroke-width=".24" opacity=".42"/>'
        svg(folder/f'{key}_base.svg', sleeve_bounds, base)
        variants={}
        for variant, fraction, alpha in (('flex',.78,.55),('strike',.45,.38)):
            x=root[0]+dx*fraction; y=root[1]+dy*fraction
            stroke=f'<path d="M {x-normal[0]*.7:.3f} {y-normal[1]*.7:.3f} q {axis[0]*.45:.3f} {axis[1]*.45:.3f} {normal[0]*1.4:.3f} {normal[1]*1.4:.3f}" fill="none" stroke="#3e4737" stroke-width=".23" opacity="{alpha}"/>'
            svg(folder/f'{key}_{variant}.svg', sleeve_bounds, stroke)
            variants[variant]=f'res://assets/characters/concept-rig/parts/{view_key}/{key}_{variant}.svg'
        assets['sleeves'][key]={'base':f'res://assets/characters/concept-rig/parts/{view_key}/{key}_base.svg','variants':variants,'bounds':sleeve_bounds,'source_polygon':[[round(x/scale+cx,4),round(y/scale+gy,4)] for x,y in polygon], 'bind':['shoulder','upper_mid','elbow']}
    assets['source_segments']={'head':'head','forearm_L':['arm_L',1],'palm_L':['arm_L',2],'forearm_R':['arm_R',1],'palm_R':['arm_R',2],'boot_L':'leg_L','boot_R':'leg_R'}
    view['modular_art']=assets


def author_atlas(views, output):
    """One explicit shader sampler, retaining individually editable SVGs.

    Canvas mesh TEXTURE is not relied on for cloth, just as the original
    concept pigment uses explicit samplers. Atlas coordinates are generated.
    """
    content=[]
    for row, (key, view) in enumerate(views.items()):
        art=view['modular_art']
        entries=[(art['coat'],'path')]
        for sleeve in art['sleeves'].values():
            entries.extend([(sleeve,'base'),(sleeve['variants'],'flex'),(sleeve['variants'],'strike')])
        for column, (entry, field) in enumerate(entries):
            path=output/entry[field].split('concept-rig/')[1]
            text=path.read_text()
            w=int(re.search(r'width="(\d+)"', text)[1]);h=int(re.search(r'height="(\d+)"', text)[1])
            x,y,bw,bh=map(float,re.search(r'viewBox="([^"]+)"',text)[1].split())
            inner=text[text.index('>')+1:text.rindex('</svg>')]
            for id in re.findall(r'id="([^"]+)"',inner):
                new=f'{key}_{column}_{id}'
                inner=inner.replace(f'id="{id}"',f'id="{new}"').replace(f'url(#{id})',f'url(#{new})')
            sx,sy=w/bw,h/bh
            content.append(f'<g transform="translate({column*128-x*sx} {row*160-y*sy}) scale({sx} {sy})">{inner}</g>')
            entry[field+'_atlas']=[column*128,row*160,w,h]
        art['atlas_size']=[896,2560]
    (output/'cloth-atlas.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="896" height="2560" viewBox="0 0 896 2560">'+''.join(content)+'</svg>\n')
