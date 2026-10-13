"""Complete SVG limb drawings in bone-local space; never edit concept bitmaps.

One explicit contract per body/view/side. Both hidden joint caps are painted,
so a new pose uncovers cloth, not holes or pixels from a neighbouring limb.
Run standalone to rebuild the kit in the existing concept manifest.
"""
from pathlib import Path
import argparse, json, math, re
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
ART_REVISION = 47
# Direction-first fitting guides, sampled from shoulder to elbow. These are
# painted-cloth envelopes, not scales applied to the anatomical bones.
FITS = [
    ([1,.98,.86,.78,.83,.89],[1,1.02,1.05,1.04,1,.93],[1,.99,.95,.94,.92,.89]),
    ([1,.98,.86,.80,.84,.90],[1,1.01,1.04,1.03,1,.94],[1,.99,.96,.94,.93,.91]),
    ([1,.99,.90,.84,.87,.93],[1,1.01,1.03,1.02,1,.96],[1,1,.98,.97,.96,.94]),
    ([1,.99,.89,.82,.85,.91],[1,1.02,1.05,1.04,1,.94],[1,.99,.97,.95,.94,.92]),
    ([1,.98,.87,.79,.83,.90],[1,1.02,1.05,1.04,1,.94],[1,.99,.96,.94,.93,.90]),
    ([1,.99,.88,.81,.85,.91],[1,1.02,1.05,1.04,1,.94],[1,.99,.97,.95,.94,.92]),
    ([1,.99,.91,.85,.87,.93],[1,1.01,1.03,1.02,1,.96],[1,1,.98,.97,.96,.94]),
    ([1,.98,.87,.80,.84,.90],[1,1.01,1.04,1.03,1,.94],[1,.99,.96,.94,.93,.91]),
]

def path(d, fill, stroke=INK, width=.24):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>'
def line(d, color, width=.16): return path(d, 'none', color, width)
def wrap(content, bounds, defs=''):
    x,y,w,h=bounds
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{math.ceil(w*8)}" height="{math.ceil(h*8)}" viewBox="{x} {y} {w} {h}"><defs>{defs}</defs>{content}</svg>\n'
def gradient(name, a, b, horizontal=True):
    return f'<linearGradient id="{name}" x1="0" y1="0" x2="{1 if horizontal else 0}" y2="{0 if horizontal else 1}"><stop stop-color="{a}"/><stop offset="1" stop-color="{b}"/></linearGradient>'
def pigment(name, light, middle, dark):
    """A broad wash, with a quiet middle plane instead of a shiny cylinder."""
    return f'<linearGradient id="{name}" x1="0" y1="0" x2="1" y2=".25"><stop stop-color="{light}"/><stop offset=".36" stop-color="{middle}"/><stop offset=".76" stop-color="{middle}"/><stop offset="1" stop-color="{dark}"/></linearGradient>'
def brush(d, color=INK):
    """Closed, tapered ink shapes stay stable when the joint mesh deforms."""
    return path(d,color,stroke='none')
def native(view, point): return [(point[i]-view['ground'][i])*view['scale'] for i in range(2)]
def distance(a,b): return math.dist(a,b)

def author(views, output=OUT, directions=None):
    entries=[]
    for key, view in views.items():
        body, ds=key.split('_'); d=int(ds)
        if directions is not None and d not in directions:
            for asset in view['directional_art']['parts'].values():
                entries.append((asset,ROOT/asset['path'].removeprefix('res://')))
            continue
        width, plane, toe=VIEWS[d]
        rear='back' in plane
        directory=output/'directional-parts'/key;directory.mkdir(parents=True,exist_ok=True)
        kit={'schema':1,'view':key,'plane':plane,'direction':d,
             'occlusion':'arms_behind_coat' if rear else 'far_arm_behind_coat',
             'parts':{}, 'joint_overlap':.65,
             'art_revision':ART_REVISION,'art_finish':'earth_pigment_tapered_ink_v1',
             'fitting_revision':46,'workflow':['idle','attack','defend','gather','mine','walk','run'],
             'rest_chains':{k:[native(view,p) for p in view['parts'][k]['joints']] for k in ('arm_L','arm_R','leg_L','leg_R')}}
        for side in ('L','R'):
            arm=[native(view,p) for p in view['parts']['arm_'+side]['joints']]
            leg=[native(view,p) for p in view['parts']['leg_'+side]['joints']]
            upper=distance(arm[0],arm[1]); lower=distance(arm[1],arm[2])
            palm_offset=min(1.35,lower*.32); forearm=lower-palm_offset
            screen_sign=1 if arm[2][0]>0 else -1
            # A thumb points toward the medial plane, reversed on the back
            # surface. This is authored for this drawing, not runtime flipping.
            thumb=screen_sign*(-1 if not rear else 1)
            # Match the broad cloth and wrapped arms in the approved concept.
            # The old narrow cylinders made the hands look disconnected.
            r=2.96*width*(.95 if body=='female' else 1)
            if plane=='profile': r*=.91 if arm[0][0]*toe<0 else 1.05
            def add(name, content, bounds, bone, anchors, defs='', overlap=.65):
                asset_id=name+'_'+side; file=directory/(asset_id+'.svg')
                file.write_text(wrap(content,bounds,defs),encoding='utf-8')
                asset={'path':'res://'+file.relative_to(ROOT).as_posix(), 'bounds':bounds,
                       'bone':bone,'side':side,'anchors':anchors,'overlap':overlap,
                       'plane':plane,'complete_hidden_surface':True}
                if bone in ('upper_arm','forearm','thigh','shin'):
                    asset['deform']='joint_cross_sections_v1'
                if bone=='upper_arm':
                    inner,outer,reach=FITS[d]
                    asset['pose_fit']={'fold_inner':inner,'fold_outer':outer,'reach':reach}
                if bone=='shoulder': asset['stitch_length']=abs(anchors['chest_stitch'][0])
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
            shoulder=path(f'M {-extent} -.3 Q {-extent} -1.45 -.5 -1.65 Q .9 -1.6 1.15 .0 L 1.15 1.2 Q 0 1.65 {-extent} 1.15 Z','url(#yoke)',stroke='none')
            shoulder=f'<g transform="scale({screen_sign} 1)">{shoulder}</g>'
            left=-extent-.45 if screen_sign>0 else -2.2
            add('shoulder',shoulder,[left,-2.2,extent+2.65,4.6],'shoulder',{'root':[0,0],'chest_stitch':[-screen_sign*(gap+.35),0]},gradient('yoke','#57664e','#44583f'))
            # Rounded shoulder cap and elbow cap are whole painted surfaces.
            # Sparse folds end inside the panel; no stationary source sleeve.
            u=upper
            silhouette=f'M {-r*.74} 0 C {-r*.70} -2.2 {r*.68} -2.2 {r*.78} -.1 C {r*.88} {u*.24} {r*.85} {u*.66} {r*.99} {u-.05} Q {r*1.05} {u+.39} {r*.84} {u+.65} Q 0 {u+1.04} {-r*.94} {u+.55} Q {-r*1.04} {u+.40} {-r*.98} {u+.08} C {-r*.89} {u*.66} {-r*.92} {u*.27} {-r*.74} 0 Z'
            cloth=pigment('cloth','#748068' if rear else '#7b8367','#657156' if rear else '#6f795a','#424f3c')
            content=path(silhouette,'url(#cloth)',width=.32)
            # The contour is unchanged from the validated 0.46 joint cap.
            # The wash breaks into a broad lit shoulder and a shaded fold;
            # tapered strokes describe cloth volume without tiny hatching.
            content+=brush(f'M {-r*.51} .02 Q {-r*.70} {u*.16} {-r*.56} {u*.38} Q {-r*.48} {u*.49} {-r*.37} {u*.61} L {-r*.16} {u*.54} Q {-r*.38} {u*.29} {-r*.26} {u*.08} Z','#91967a' if rear else '#9a9c7d')
            content+=brush(f'M {r*.55} {u*.16} Q {r*.45} {u*.45} {r*.72} {u*.70} L {r*.87} {u-.46} Q {r*.43} {u*.73} {r*.30} {u*.51} Z','#4a5942')
            content+=brush(f'M {r*.76} {u*.29} Q {r*.68} {u*.65} {r*.90} {u-.34} L {r*.79} {u-.44} Q {r*.52} {u*.65} {r*.76} {u*.29} Z','#333f32')
            if rear:
                # The back has a seam; a profile shows one side fold. Neither
                # repeats the decorative front-facing crease on every view.
                seam=r*(.12 if plane=='back' else -.14*toe)
                content+=brush(f'M {seam} {u*.16} Q {seam-r*.19} {u*.43} {seam+r*.02} {u*.65} L {seam+r*.07} {u*.71} Q {seam-r*.28} {u*.40} {seam} {u*.16} Z','#404d3b')
                content+=brush(f'M {-r*.34} {u*.63} Q {-r*.06} {u*.72} {r*.20} {u*.78} Q {-r*.05} {u*.67} {-r*.34} {u*.63} Z','#aaa88a')
            else:
                content+=brush(f'M {-r*.58} {u*.16} Q {-r*.73} {u*.34} {-r*.46} {u*.53} Q {-r*.57} {u*.38} {-r*.55} {u*.32} Q {-r*.66} {u*.25} {-r*.58} {u*.16} Z','#3e4a38')
                content+=brush(f'M {-r*.38} {u*.75} Q {-r*.05} {u*.62} {r*.29} {u*.67} L {r*.20} {u*.69} Q {-r*.12} {u*.70} {-r*.38} {u*.75} Z','#424d39')
                content+=brush(f'M {-r*.12} {u*.63} Q {r*.08} {u*.58} {r*.26} {u*.62} L {r*.13} {u*.64} Z','#b4af8b')
            # A pressure-weighted contour sits INSIDE the original boundary.
            # It follows the same cubic as the shadow-facing sleeve edge,
            # tapers to zero at the shoulder, and never widens a joint cap.
            content+=brush(f'M {r*.78} -.1 C {r*.88} {u*.24} {r*.85} {u*.66} {r*.99} {u-.05} L {r*.99-.14} {u-.05} C {r*.85-.26} {u*.66} {r*.88-.22} {u*.24} {r*.78} -.1 Z')
            # A thinner turned hem and shaded mouth read as cloth thickness,
            # rather than a broad rigid ivory band across a bent elbow.
            content+=path(f'M {-r*.98} {u-.38} Q 0 {u+.05} {r*.98} {u-.28} Q {r*1.05} {u+.39} {r*.84} {u+.65} Q 0 {u+1.04} {-r*.94} {u+.55} Q {-r*1.04} {u+.40} {-r*.98} {u-.38} Z','#c8b68f',width=.23)
            content+=brush(f'M {r*.46} {u+.06} L {r*.92} {u-.17} Q {r*.99} {u+.34} {r*.80} {u+.55} L {r*.44} {u+.66} Q {r*.62} {u+.34} {r*.46} {u+.06} Z','#ac9976')
            content+=brush(f'M {-r*.82} {u-.12} Q {-r*.29} {u+.17} {r*.07} {u+.17} L {-r*.19} {u+.29} Q {-r*.64} {u+.19} {-r*.82} {u-.12} Z','#e4d4ab')
            content+=brush(f'M {r*.84} {u+.65} Q 0 {u+1.04} {-r*.94} {u+.55} Q 0 {u+.78} {r*.84} {u+.65} Z')
            content+=line(f'M {-r*.87} {u+.40} Q 0 {u+.87} {r*.85} {u+.43}','#4b4837',.22)
            add('sleeve',content,[-r-1,-2.3,2*r+2,u+4.0], 'upper_arm',{'root':[0,0],'tip':[0,u]},cloth)
            # The flared ivory hem belongs to the upper sleeve. The wrapped
            # forearm has a complete dark cap hidden beneath that hem.
            f=forearm; cr=1.72*width; wrist=1.05 if body=='female' else 1.15
            shell=f'M {-cr*.76} -.65 Q 0 -1.10 {cr*.76} -.65 L {cr} .45 Q {cr*.80} {f*.60} {wrist} {f+.32} Q 0 {f+.67} {-wrist} {f+.32} Q {-cr*.84} {f*.60} {-cr} .45 Z'
            content=path(shell,'url(#wrap)',width=.29)
            content+=brush(f'M {-cr*.68} -.18 Q {-cr*.50} {f*.32} {-wrist*.48} {f+.12} L {-wrist*.22} {f-.04} Q {-cr*.41} {f*.28} {-cr*.41} -.05 Z','#7c8269')
            # Curved, overlapping bindings; the slope belongs to the visible
            # surface, rather than mirroring a front bracelet onto the back.
            slope=(.12*toe if toe else .09)*(-1 if rear else 1)
            content+=path(f'M {-cr*.95} .20 Q {-cr*.12} .67 {cr*.94} .32 L {cr*.86} 1.03 Q {cr*.05} 1.39 {-cr*.87} .97 Z','#414939',width=.15)
            content+=path(f'M {-cr*.82} {f*(.29+slope)} Q 0 {f*.41} {cr*.86} {f*(.28-slope)} L {cr*.79} {f*(.46-slope)} Q 0 {f*.56} {-cr*.76} {f*(.46+slope)} Z','#8e8465',width=.17)
            content+=brush(f'M {-cr*.71} {f*(.33+slope)} Q {-cr*.14} {f*.43} {cr*.49} {f*(.33-slope*.7)} Q {-cr*.04} {f*.47} {-cr*.71} {f*(.38+slope)} Z','#b0a17b')
            content+=path(f'M {-wrist*.93} {f-.88} Q 0 {f-.71} {wrist*.97} {f-1.01} L {wrist*.98} {f-.34} Q 0 {f-.03} {-wrist*.98} {f-.20} Z','#343e31',width=.15)
            content+=brush(f'M {cr*.58} {f*.58} Q {cr*.41} {f*.73} {wrist*.66} {f-.29} L {wrist*.57} {f-.17} Q {cr*.29} {f*.74} {cr*.58} {f*.58} Z','#292f26')
            content+=brush(f'M {cr} .45 Q {cr*.80} {f*.60} {wrist} {f+.32} L {wrist-.08} {f+.29} Q {cr*.80-.24} {f*.60} {cr} .45 Z')
            add('forearm',content,[-cr-.6,-1.3,2*cr+1.2,f+2.3], 'forearm',{'root':[0,0],'wrist':[0,f]},pigment('wrap','#737964','#59654f','#3d4838'))
            for state in ('relaxed','grip','fist','cast'):
                s=-1; p=palm_offset; hw=1.20*(.93 if body=='female' else 1)*(.85 if plane=='profile' else 1)
                if state in ('grip','fist'):
                    shape=f'M {-hw*.70} -.50 Q 0 -.66 {hw*.70} -.43 L {hw*1.12} {p-.38} Q {hw*1.30} {p+.92} .2 {p+1.01} L {-hw*.76} {p+.74} Q {-hw*1.18} {p+.18} {-hw} {p-.45} Z'
                else:
                    extra=.45 if state=='cast' else 0
                    shape=f'M {-hw*.64} -.45 Q 0 -.62 {hw*.70} -.45 L {hw*.94} {p+.20} Q {hw+extra} {p+1.22} {hw*.22} {p+1.48} Q {-hw*.85} {p+1.65} {-hw*.95} {p+.47} L {-hw*1.25} {p-.04} Q {-hw*1.43} {p-.51} {-hw*.64} -.45 Z'
                skin=gradient('skin','#c2a580' if rear else '#dfc39a','#ac8b66')
                content=path(shape,'url(#skin)',width=.22)
                content+=brush(f'M {hw*.48} -.12 Q {hw*.70} {p*.65} {hw*.78} {p+.49} Q {hw*.61} {p+.70} {hw*.37} {p+.80} L {hw*.18} {p+.74} Q {hw*.53} {p+.31} {hw*.48} -.12 Z','#b3926c')
                content+=brush(f'M {s*hw*.87} {p-.30} Q {-s*.05} {p-.37} {-s*hw*.31} {p+.34} Q {-s*.05} {p-.13} {s*hw*.48} {p-.17} Z','#795d43')
                if state in ('grip','fist'):
                    content+=brush(f'M {-hw*.49} {p+.30} Q 0 {p+.43} {hw*.61} {p+.23} Q {hw*.14} {p+.55} {-hw*.49} {p+.30} Z','#927252')
                    if state=='fist': content+=line(f'M -.28 {p-.08} L -.22 {p+.20} M .25 {p-.06} L .26 {p+.22}', '#795d43',.14)
                else:content+=line(f'M .16 {p+.60} L .14 {p+1.21}', '#a07e5a',.14)
                content=f'<g transform="scale({-thumb} 1)">{content}</g>'
                add('hand_'+state,content,[-2.1,-1,4.2,p+3.0], 'hand',{'root':[0,0],'grip':[0,p]},skin,.48)
            for part,bone,length,rad in [('thigh','thigh',distance(leg[0],leg[1]),2.12),('shin','shin',distance(leg[1],leg[2]),1.65)]:
                rad*=width*(.94 if body=='female' else 1); l=length
                content=path(f'M {-rad} 0 Q 0 -1.1 {rad} 0 Q {rad*1.05} {l*.43} {rad*.78} {l+.4} Q 0 {l+1.0} {-rad*.78} {l+.4} Q {-rad*1.08} {l*.42} {-rad} 0 Z','url(#pants)',width=.28)
                content+=brush(f'M {-rad*.54} .16 Q {-rad*.68} {l*.30} {-rad*.43} {l*.58} Q {-rad*.18} {l*.64} {-rad*.12} {l*.91} L {rad*.13} {l*.78} Q {rad*.07} {l*.60} {-rad*.21} {l*.42} L {-rad*.28} .30 Z','#7c7b62')
                content+=brush(f'M {rad*.73} {l*.10} Q {rad*.54} {l*.43} {rad*.70} {l*.81} L {rad*.56} {l+.15} Q {rad*.34} {l*.55} {rad*.73} {l*.10} Z','#303c30')
                if part=='thigh':
                    content+=brush(f'M {-rad*.54} {l*.69} Q {-rad*.03} {l*.51} {rad*.40} {l*.73} Q {-rad*.05} {l*.63} {-rad*.54} {l*.69} Z','#424939')
                else:
                    # A diagonal overlap describes a wrapped calf, avoiding
                    # the former single zigzag that read as an extra limb.
                    content+=brush(f'M {-rad*.77} {l*.38} Q 0 {l*.56} {rad*.67} {l*.29} L {rad*.63} {l*.42} Q 0 {l*.69} {-rad*.75} {l*.48} Z','#464e3d')
                    content+=brush(f'M {-rad*.61} {l*.38} Q {-rad*.13} {l*.50} {rad*.50} {l*.35} Q {-rad*.04} {l*.57} {-rad*.61} {l*.43} Z','#929077')
                add(part,content,[-rad-.6,-1.3,2*rad+1.2,l+2.8],bone,{'root':[0,0],'tip':[0,l]},pigment('pants','#666b57','#545e49','#3d4838'))
            for boot in ('cloth','leather'):
                # Upright ankle anchor: side toes extend toward the facing
                # direction; front/rear shoes have separate toe/heel lines.
                spread=2.45*(.94 if body=='female' else 1); tip=toe*(3.8 if plane=='profile' else 1.4)
                minx=min(-spread,tip-spread*.65);maxx=max(spread,tip+spread*.65)
                b=f'M {-spread*.70} -4.25 Q 0 -4.55 {spread*.72} -4.25 L {spread*.77} -1.60 Q {maxx+.30} -.90 {maxx} .05 Q {tip} .72 {minx} .12 Q {minx-.25} -.73 {-spread*.74} -1.62 Z'
                content=path(b,'url(#boot)',width=.32)
                content+=brush(f'M {spread*.41} -3.18 Q {spread*.57} -2.21 {spread*.46} -1.70 L {maxx*.69} -.83 Q {spread*.10} -1.13 {spread*.13} -1.56 L {spread*.18} -3.15 Z','#343e31' if boot=='cloth' else '#443b2d')
                content+=brush(f'M {-spread*.48} -3.21 Q {-spread*.52} -2.40 {-spread*.32} -1.87 L {-spread*.09} -1.69 L {-spread*.15} -2.43 L {-spread*.23} -3.20 Z','#898d72' if boot=='cloth' else '#9d8764')
                # A low ochre sole grounds the original silhouette, instead
                # of outlining the entire boot with a pale rigid stripe.
                content+=brush(f'M {minx+.18} -.36 Q {tip} .16 {maxx-.13} -.33 L {maxx-.16} -.03 Q {tip} .53 {minx+.14} -.02 Z','#98886a' if boot=='cloth' else '#ab9067')
                content+=line(f'M {minx+.22} -.10 Q {tip} .37 {maxx-.18} -.09','#343329',.18)
                content+=path(f'M {-spread*.73} -4.10 L {spread*.73} -4.10 L {spread*.72} -3.35 Q 0 -3.12 {-spread*.71} -3.35 Z','#96957a' if boot=='cloth' else '#958061',width=.16)
                content+=brush(f'M {-spread*.56} -4.00 Q {-spread*.12} -3.85 {spread*.30} -4.00 L {spread*.22} -3.83 Q {-spread*.14} -3.66 {-spread*.56} -3.82 Z','#b5b090' if boot=='cloth' else '#b7a07a')
                if rear:
                    content+=brush('M .02 -3.04 Q -.10 -2.15 .10 -1.12 L .20 -1.32 Q .05 -2.12 .02 -3.04 Z','#2c352b')
                    content+=brush(f'M {-spread*.41} -1.07 Q .02 -1.30 {spread*.42} -1.10 Q .01 -1.49 {-spread*.41} -1.07 Z','#85846b')
                else:
                    content+=brush(f'M {-spread*.52} -1.75 Q {tip*.55} -1.16 {maxx*.67} -.85 Q {tip*.41} -1.47 {-spread*.52} -1.75 Z','#a5a083' if boot=='cloth' else '#b39b73')
                    content+=brush(f'M {-spread*.36} -2.45 Q .04 -2.07 {spread*.53} -2.23 Q .05 -1.86 {-spread*.36} -2.45 Z','#3a4433' if boot=='cloth' else '#524333')
                content+=brush(f'M {spread*.72} -4.25 L {spread*.77} -1.60 Q {maxx+.30} -.90 {maxx} .05 L {maxx-.14} -.09 Q {maxx+.04} -.94 {spread*.77-.24} -1.60 L {spread*.72} -4.25 Z')
                add('boot_'+boot,content,[minx-.8,-5.0,maxx-minx+1.6,6.2],'foot',{'root':[0,0],'sole':[0,.25]},pigment('boot','#6e7560' if boot=='cloth' else '#807052','#515e48' if boot=='cloth' else '#695b42','#3c4736' if boot=='cloth' else '#463e2f'))
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
    parser=argparse.ArgumentParser()
    parser.add_argument('--directions',nargs='+',type=int,choices=range(8),help='Fit these views first; retain every other authored view verbatim.')
    args=parser.parse_args()
    file=OUT/'manifest.json'; manifest=json.loads(file.read_text())
    count=author(manifest['views'],directions=args.directions)
    manifest['revision']='concept-direction-ink-47'
    manifest['contract']='Approved head/coat retained; 0.46 direction-specific rest chains, anchors and cloth envelopes retained; restrained earth pigment, tapered ink creases and view-specific wraps; rigid grip and soles.'
    file.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    print(f'Authored {count} complete directional parts; 16 body/view contracts.')
