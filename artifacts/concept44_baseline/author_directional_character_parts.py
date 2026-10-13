"""Complete SVG limb drawings in bone-local space; never edit concept bitmaps.

One explicit contract per body/view/side. Both hidden joint caps are painted,
so a new pose uncovers cloth, not holes or pixels from a neighbouring limb.
Run standalone to rebuild the kit in the existing concept manifest.
"""
from pathlib import Path
import json, math, re
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/characters/concept-rig'
# Width, exposed plane, toe direction. Profile arms have a genuinely narrower
# side plane; rear views show seams instead of front-facing cuff decoration.
VIEWS = [
    (1.00, 'front', 0), (.94, 'quarter_front', -1), (.82, 'profile', -1),
    (.96, 'quarter_back', -1), (1.02, 'back', 0), (.96, 'quarter_back', 1),
    (.82, 'profile', 1), (.94, 'quarter_front', 1),
]
INK = '#332c24'

def path(d, fill, stroke=INK, width=.24):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>'
def line(d, color, width=.16): return path(d, 'none', color, width)
def wrap(content, bounds, defs=''):
    x,y,w,h=bounds
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{math.ceil(w*8)}" height="{math.ceil(h*8)}" viewBox="{x} {y} {w} {h}"><defs>{defs}</defs>{content}</svg>\n'
def gradient(name, a, b, horizontal=True):
    return f'<linearGradient id="{name}" x1="0" y1="0" x2="{1 if horizontal else 0}" y2="{0 if horizontal else 1}"><stop stop-color="{a}"/><stop offset="1" stop-color="{b}"/></linearGradient>'
def native(view, point): return [(point[i]-view['ground'][i])*view['scale'] for i in range(2)]
def distance(a,b): return math.dist(a,b)

def author(views, output=OUT):
    entries=[]
    for key, view in views.items():
        body, ds=key.split('_'); d=int(ds)
        width, plane, toe=VIEWS[d]
        rear='back' in plane
        directory=output/'directional-parts'/key;directory.mkdir(parents=True,exist_ok=True)
        kit={'schema':1,'view':key,'plane':plane,'direction':d,
             'occlusion':'arms_behind_coat' if rear else 'far_arm_behind_coat',
             'parts':{}, 'joint_overlap':.65}
        for side in ('L','R'):
            arm=[native(view,p) for p in view['parts']['arm_'+side]['joints']]
            leg=[native(view,p) for p in view['parts']['leg_'+side]['joints']]
            upper=distance(arm[0],arm[1]); lower=distance(arm[1],arm[2])
            palm_offset=min(1.35,lower*.32); forearm=lower-palm_offset
            screen_sign=1 if arm[2][0]>0 else -1
            # A thumb points toward the medial plane, reversed on the back
            # surface. This is authored for this drawing, not runtime flipping.
            thumb=screen_sign*(-1 if not rear else 1)
            r=2.28*width*(.94 if body=='female' else 1)
            if plane=='profile': r*=.91 if arm[0][0]*toe<0 else 1.05
            def add(name, content, bounds, bone, anchors, defs='', overlap=.65):
                asset_id=name+'_'+side; file=directory/(asset_id+'.svg')
                file.write_text(wrap(content,bounds,defs),encoding='utf-8')
                asset={'path':'res://'+file.relative_to(ROOT).as_posix(), 'bounds':bounds,
                       'bone':bone,'side':side,'anchors':anchors,'overlap':overlap,
                       'plane':plane,'complete_hidden_surface':True}
                kit['parts'][asset_id]=asset;entries.append((asset,file))
            # The arm roots in the concept sit outside the cropped torso.
            # A body-bound, fully painted shoulder yoke joins the chest to
            # the rotating sleeve without leaving a detached capsule.
            sx,sy=view['parts']['arm_'+side]['joints'][0]
            poly=view['body_core']; crossings=[]
            for a,b in zip(poly,poly[1:]+poly[:1]):
                if min(a[1],b[1])<=sy<max(a[1],b[1]):
                    crossings.append(a[0]+(b[0]-a[0])*(sy-a[1])/(b[1]-a[1]))
            gap=min(abs(sx-x) for x in crossings)*view['scale'] if crossings else 1.5
            extent=max(2.3,gap+.85)
            shoulder=path(f'M {-extent} -.3 Q {-extent} -1.45 -.5 -1.65 Q 1.3 -1.6 1.65 .0 L 1.75 1.2 Q 0 1.65 {-extent} 1.15 Z','url(#yoke)',width=.18)
            shoulder=f'<g transform="scale({screen_sign} 1)">{shoulder}</g>'
            left=-extent-.45 if screen_sign>0 else -2.2
            add('shoulder',shoulder,[left,-2.2,extent+2.65,4.6],'shoulder',{'root':[0,0],'chest_stitch':[-screen_sign*(gap+.35),0]},gradient('yoke','#57664e','#44583f'))
            # Rounded shoulder cap and elbow cap are whole painted surfaces.
            # Sparse folds end inside the panel; no stationary source sleeve.
            u=upper
            silhouette=f'M {-r*.78} 0 C {-r*.82} -1.65 {r*.86} -1.65 {r*.92} -.1 C {r*.90} {u*.34} {r*1.07} {u*.74} {r*1.10} {u+.30} Q 0 {u+1.06} {-r*1.08} {u+.24} C {-r*1.03} {u*.68} {-r*.91} {u*.28} {-r*.78} 0 Z'
            cloth=gradient('cloth','#536651' if rear else '#66765b','#344638')
            content=path(silhouette,'url(#cloth)')
            content+=path(f'M {-r*1.05} {u-.80} Q 0 {u-.35} {r*1.06} {u-.80} L {r*1.10} {u+.30} Q 0 {u+1.06} {-r*1.08} {u+.24} Z','#c3b18a',width=.19)
            content+=line(f'M {-r*.83} {u-.35} Q 0 {u+.02} {r*.84} {u-.32}', '#e2d0a8',.16)
            content+=line(f'M {-r*.45} .30 Q {-r*.70} {u*.38} {-r*.46} {u*.64}', '#859078',.18)
            content+=line(f'M {r*.72} {u*.62} Q {r*.20} {u*.76} {r*.39} {u*.89}', '#304033',.22)
            if rear:content+=line(f'M .25 .8 Q .6 {u*.32} .15 {u*.61}', '#43533f',.17)
            add('sleeve',content,[-r-1,-1.8,2*r+2,u+3.2], 'upper_arm',{'root':[0,0],'tip':[0,u]},cloth)
            # The flared ivory hem belongs to the upper sleeve. The wrapped
            # forearm has a complete dark cap hidden beneath that hem.
            f=forearm; cr=1.14*width; wrist=.78 if body=='female' else .86
            shell=f'M {-cr*.76} -.65 Q 0 -1.10 {cr*.76} -.65 L {cr} .45 Q {cr*.80} {f*.60} {wrist} {f+.32} Q 0 {f+.67} {-wrist} {f+.32} Q {-cr*.84} {f*.60} {-cr} .45 Z'
            content=path(shell,'url(#wrap)')
            content+=path(f'M {-cr} .15 Q 0 .47 {cr} .15 L {cr*.89} 1.10 Q 0 1.35 {-cr*.89} 1.10 Z','#424b3e',width=.16)
            content+=line(f'M {-cr*.70} .55 Q 0 .82 {cr*.72} .55','#7c8069',.14)
            content+=line(f'M {-wrist*.60} {f-.40} L {wrist*.72} {f-.65}', '#28332c',.22)
            if rear: content+=line(f'M .12 1.8 L .17 {max(1.85,f-.90)}','#899079',.16)
            else:content+=line(f'M {-cr*.63} 1.75 L {wrist*.50} {max(1.8,f-.85)}','#899079',.18)
            add('forearm',content,[-cr-.6,-1.3,2*cr+1.2,f+2.3], 'forearm',{'root':[0,0],'wrist':[0,f]},gradient('wrap','#69715d','#424f41'))
            for state in ('relaxed','grip','fist','cast'):
                s=-1; p=palm_offset; hw=.92*(.93 if body=='female' else 1)*(.76 if plane=='profile' else 1)
                if state in ('grip','fist'):
                    shape=f'M {-hw*.70} -.50 Q 0 -.66 {hw*.70} -.43 L {hw*1.12} {p-.38} Q {hw*1.30} {p+.92} .2 {p+1.01} L {-hw*.76} {p+.74} Q {-hw*1.18} {p+.18} {-hw} {p-.45} Z'
                else:
                    extra=.45 if state=='cast' else 0
                    shape=f'M {-hw*.64} -.45 Q 0 -.62 {hw*.70} -.45 L {hw*.94} {p+.20} Q {hw+extra} {p+1.22} {hw*.22} {p+1.48} Q {-hw*.85} {p+1.65} {-hw*.95} {p+.47} L {-hw*1.25} {p-.04} Q {-hw*1.43} {p-.51} {-hw*.64} -.45 Z'
                skin=gradient('skin','#c2a580' if rear else '#dfc39a','#ac8b66')
                content=path(shape,'url(#skin)',width=.22)
                content+=line(f'M {s*hw*.87} {p-.30} Q {-s*.05} {p-.37} {-s*hw*.31} {p+.34}', '#795d43',.18)
                if state in ('grip','fist'):
                    content+=line(f'M {-hw*.49} {p+.30} Q 0 {p+.43} {hw*.61} {p+.23}', '#927252',.15)
                    if state=='fist': content+=line(f'M -.28 {p-.08} L -.22 {p+.20} M .25 {p-.06} L .26 {p+.22}', '#795d43',.14)
                else:content+=line(f'M .16 {p+.60} L .14 {p+1.21}', '#a07e5a',.14)
                content=f'<g transform="scale({-thumb} 1)">{content}</g>'
                add('hand_'+state,content,[-1.8,-1,3.6,p+3.0], 'hand',{'root':[0,0],'grip':[0,p]},skin,.48)
            for part,bone,length,rad in [('thigh','thigh',distance(leg[0],leg[1]),1.55),('shin','shin',distance(leg[1],leg[2]),1.28)]:
                rad*=width*(.94 if body=='female' else 1); l=length
                content=path(f'M {-rad} 0 Q 0 -1.1 {rad} 0 L {rad*.78} {l+.4} Q 0 {l+1.0} {-rad*.78} {l+.4} Z','url(#pants)',width=.22)
                content+=line(f'M {-rad*.45} .5 Q {-rad*.52} {l*.5} {-rad*.35} {max(.6,l-.50)}', '#747460',.18)
                add(part,content,[-rad-.6,-1.3,2*rad+1.2,l+2.8],bone,{'root':[0,0],'tip':[0,l]},gradient('pants','#626655','#40473b'))
            for boot in ('cloth','leather'):
                # Upright ankle anchor: side toes extend toward the facing
                # direction; front/rear shoes have separate toe/heel lines.
                spread=1.7*(.94 if body=='female' else 1); tip=toe*(3.4 if plane=='profile' else 1.2)
                minx=min(-spread,tip-spread*.65);maxx=max(spread,tip+spread*.65)
                b=f'M {-spread*.70} -4.25 Q 0 -4.55 {spread*.72} -4.25 L {spread*.77} -1.60 Q {maxx+.30} -.90 {maxx} .05 Q {tip} .72 {minx} .12 Q {minx-.25} -.73 {-spread*.74} -1.62 Z'
                content=path(b,'url(#boot)',width=.26)
                content+=line(f'M {minx+.22} -.12 Q {tip} .39 {maxx-.18} -.11','#2b3028',.22)
                content+=path(f'M {-spread*.73} -4.10 L {spread*.73} -4.10 L {spread*.72} -3.35 Q 0 -3.12 {-spread*.71} -3.35 Z','#96957a' if boot=='cloth' else '#958061',width=.16)
                if rear:content+=line('M .05 -2.9 L .12 -1.0','#a5a087',.17)
                else:content+=line(f'M {-spread*.5} -1.75 Q {tip*.7} -1.04 {maxx*.65} -.79','#a9a28a',.18)
                add('boot_'+boot,content,[minx-.8,-5.0,maxx-minx+1.6,6.2],'foot',{'root':[0,0],'sole':[0,.25]},gradient('boot','#6d7160' if boot=='cloth' else '#807052','#454d40' if boot=='cloth' else '#4e4435'))
        view['directional_art']=kit
    # 8 source pixels per native unit; 2px transparent gutter around each
    # cell prevents neighbouring pieces bleeding under linear filtering.
    cell_w,cell_h,cols=96,144,20
    atlas_w,atlas_h=cell_w*cols,math.ceil(len(entries)/cols)*cell_h
    groups=[]
    for i,(asset,file) in enumerate(entries):
        x=(i%cols)*cell_w+2;y=(i//cols)*cell_h+2
        bx,by,w,h=asset['bounds'];pw=math.ceil(w*8);ph=math.ceil(h*8)
        assert pw+4<=cell_w and ph+4<=cell_h,(file,pw,ph)
        raw=file.read_text(); inner=raw[raw.index('>')+1:raw.rfind('</svg>')]
        inner=re.sub(r'id="([^"]+)"',lambda m:f'id="p{i}_{m[1]}"',inner)
        inner=re.sub(r'url\(#([^\)]+)\)',lambda m:f'url(#p{i}_{m[1]})',inner)
        groups.append(f'<g transform="translate({x} {y}) scale({pw/w} {ph/h}) translate({-bx} {-by})">{inner}</g>')
        asset['atlas_rect']=[x,y,pw,ph]
    atlas=output/'directional-atlas.svg'
    atlas.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{atlas_w}" height="{atlas_h}" viewBox="0 0 {atlas_w} {atlas_h}">'+''.join(groups)+'</svg>\n')
    for view in views.values(): view['directional_art']['atlas_size']=[atlas_w,atlas_h]
    return len(entries)

if __name__=='__main__':
    file=OUT/'manifest.json'; manifest=json.loads(file.read_text())
    count=author(manifest['views'])
    manifest['revision']='concept-directional-parts-41'
    manifest['contract']='Approved head/coat detail retained; complete view-specific SVG limbs, bone-local anchors, painted overlap, explicit hand states and back-view occlusion.'
    file.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    print(f'Authored {count} complete directional parts; 16 body/view contracts.')
