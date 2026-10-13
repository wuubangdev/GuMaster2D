"""Author runtime UV masks and joints for the approved character illustrations.

No bitmap is changed: Godot draws the original source pixels through these
editable vector masks. Coordinates are source pixels; native units are 64 per
figure. The existing presentation rig supplies motion, never gameplay state.
"""
from pathlib import Path
import json
import shutil
from author_concept_modular_parts import author as author_modular_parts, author_atlas
from author_directional_character_parts import author as author_directional_parts

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/characters/concept-rig'
OUT.mkdir(parents=True, exist_ok=True)
SOURCE = ROOT / 'docs/game-studio/concepts/ink20'
shutil.copyfile(SOURCE / 'character-concept-01.png', OUT / 'character-concept-01.png')
shutil.copyfile(SOURCE / 'detail-02/character-directions-02.png', OUT / 'character-directions-02.png')

HEAD_FRONT = [(-65,-228),(-67,-251),(-54,-276),(-32,-295),(-23,-297),(-30,-305),(-21,-317),(-5,-323),(14,-319),(29,-309),(28,-297),(43,-285),(57,-267),(65,-248),(60,-226),(65,-215),(59,-199),(44,-185),(23,-175),(0,-171),(-24,-176),(-43,-186),(-55,-200),(-63,-215)]
HEAD_BACK = [(-65,-224),(-66,-247),(-56,-271),(-36,-291),(-18,-299),(-27,-306),(-19,-318),(-2,-323),(16,-319),(30,-307),(27,-297),(44,-285),(59,-264),(65,-241),(63,-215),(53,-194),(32,-178),(8,-171),(-19,-175),(-43,-188),(-58,-207)]
HEAD_PROFILE = [(-70,-227),(-62,-245),(-66,-259),(-52,-279),(-31,-293),(5,-301),(12,-314),(29,-322),(48,-315),(56,-303),(43,-296),(59,-280),(70,-258),(69,-234),(58,-217),(39,-213),(31,-188),(12,-175),(-12,-172),(-33,-181),(-52,-193),(-59,-209),(-67,-215)]
COAT_FRONT = [(-18,-177),(-34,-168),(-39,-147),(-35,-114),(-43,-80),(-56,-44),(-36,-34),(-10,-29),(9,-33),(35,-30),(54,-43),(43,-81),(34,-115),(36,-149),(22,-174),(7,-179)]
COAT_BACK = [(-22,-177),(-40,-162),(-41,-137),(-36,-112),(-43,-75),(-55,-41),(-36,-32),(-9,-30),(11,-33),(34,-31),(56,-43),(45,-78),(36,-110),(40,-143),(34,-164),(17,-178)]
COAT_PROFILE = [(-17,-178),(-35,-164),(-40,-141),(-40,-108),(-45,-76),(-51,-41),(-35,-31),(-7,-34),(16,-29),(40,-40),(34,-78),(32,-111),(36,-144),(24,-169),(5,-179)]

def translate(points, at, flip=False):
    return [[round(at[0] + (-x if flip else x), 2), round(at[1] + y, 2)] for x, y in points]

def part(polygon, pivot, **extra):
    return {'polygon': polygon, 'pivot': pivot, **extra}

def arm_shape(shoulder, hand):
    sx, sy = shoulder; hx, hy = hand
    sign = -1 if hx < 0 else 1
    sx *= sign; hx *= sign
    outline = [(sx-9,sy-5),(sx+9,sy-5),(sx+16,sy+17),
               (hx+11,hy-24),(hx+12,hy-8),(hx+9,hy+8),
               (hx-3,hy+10),(hx-12,hy+5),(hx-10,hy-12),
               (sx-9,sy+27)]
    return [(x*sign,y) for x,y in outline]

def boot_shape(x, profile=False, flip=False):
    points=[(x-13,-45),(x+12,-45),(x+12,-25),(x+17,-13),
            (x+17,-6),(x+8,-3),(x-16,-3),(x-23,-6),(x-22,-11),(x-12,-23)]
    if profile:
        points=[(x-13,-43),(x+11,-43),(x+11,-23),(x+23,-14),
                (x+30,-8),(x+27,-3),(x-9,-3),(x-20,-6),(x-17,-14),(x-13,-24)]
        if flip:
            points=[(2*x-px,py) for px,py in points]
    return points

views={}
centers=[234,434,635,835,1038,1241,1446,1648]
# Inner sleeve seams belong to the moving arm, including the green shoulder
# above the ivory cuff. These are per-view drawing coordinates, not mirrored
# guesses from one front-facing torso. Each seam runs shoulder to cuff.
SLEEVE_SEAMS = {
 'male': [None,
   ([(-23,-171),(-20,-146),(-28,-123),(-36,-101)],[(27,-170),(26,-147),(30,-126),(36,-102)]),
   ([(-35,-168),(-37,-146),(-42,-124),(-47,-103)],[(14,-171),(9,-149),(17,-124),(28,-102)]),
   ([(-23,-169),(-20,-148),(-27,-125),(-35,-102)],[(36,-168),(35,-148),(39,-126),(45,-104)]),
   None,
   ([(-36,-169),(-34,-147),(-39,-125),(-45,-102)],[(24,-169),(20,-146),(28,-124),(36,-103)]),
   None,
   ([(-26,-171),(-25,-147),(-30,-124),(-38,-102)],[(23,-169),(22,-147),(28,-124),(36,-102)])],
 'female': [
   ([(-22,-168),(-20,-146),(-26,-123),(-34,-102)],[(24,-168),(22,-146),(28,-122),(35,-102)]),
   ([(-23,-168),(-20,-147),(-27,-124),(-34,-102)],[(26,-168),(25,-146),(30,-124),(38,-101)]),
   ([(-36,-168),(-36,-147),(-42,-125),(-47,-102)],[(11,-167),(7,-146),(15,-124),(24,-102)]),
   ([(-22,-169),(-18,-149),(-25,-125),(-34,-102)],[(36,-166),(33,-147),(37,-125),(44,-103)]),
   ([(-24,-169),(-22,-148),(-28,-126),(-36,-102)],[(25,-169),(22,-148),(29,-125),(38,-102)]),
   ([(-34,-168),(-31,-147),(-37,-125),(-43,-102)],[(22,-168),(19,-147),(26,-123),(35,-103)]),
   ([(-23,-167),(-14,-146),(-18,-124),(-29,-102)],[(38,-168),(39,-147),(43,-125),(48,-103)]),
   ([(-25,-168),(-24,-146),(-29,-124),(-37,-102)],[(24,-168),(22,-146),(29,-123),(37,-102)])]
}

# Palm centers follow the actual drawings, including the different female
# profile hand positions. Reusing the old approximate centers left fingers
# on the torso and gave the moving arm unrelated bits of the skirt.
hands_by_body={
 'male':[((-55,-85),(54,-85)),((-52,-85),(54,-86)),((-44,-87),(29,-83)),
         ((48,-87),(-43,-85)),((56,-85),(-52,-86)),((50,-84),(-48,-91)),
         ((42,-88),(-27,-83)),((-55,-85),(52,-86))],
 'female':[((-54,-83),(49,-86)),((-51,-83),(54,-82)),((-46,-87),(20,-82)),
           ((49,-86),(-45,-83)),((54,-83),(-49,-82)),((50,-85),(-42,-86)),
           ((37,-86),(-28,-84)),((-53,-83),(53,-82))]}
for body, ground in [('male',431),('female',816)]:
    for d, cx in enumerate(centers):
        at=(cx,ground); profile=d in (2,6); back=d in (3,4,5)
        head=HEAD_PROFILE if profile else HEAD_BACK if back else HEAD_FRONT
        flip=d==6
        if d in (1,3,5,7):
            head=[(x*.96 + (4 if d in (5,7) else -4), y) for x,y in head]
        if body=='female':
            head=[(x*1.02,y+3) for x,y in head]
        coat=COAT_PROFILE if profile else COAT_BACK if back else COAT_FRONT
        # End the moving coat at its painted hem, above the exposed pants.
        # The lower female/profile drawings are shorter than the old template.
        hem_raise=5 if body=='female' else 6 if profile else 0
        coat=[(x,y-hem_raise*max(0,min(1,(y+80)/40))) for x,y in coat]
        parts={'head':part(translate(head,at,flip),[cx,ground-217]),
               'torso':part(translate(coat,at,flip),[cx,ground-115])}
        for side, hand in zip(('R','L'),hands_by_body[body][d]):
            shoulder=(hand[0]*.62,-159 if side=='R' else -162)
            elbow=(hand[0]*.94,-119)
            parts['arm_'+side]=part(translate(arm_shape(shoulder,hand),at),
                                   [cx+shoulder[0],ground+shoulder[1]],
                                   joints=translate([shoulder,elbow,hand],at))
            leg_x=(-29 if side=='R' else 31) if not back else (30 if side=='R' else -30)
            if profile:
                leg_x=-19 if side=='R' else 15
            parts['leg_'+side]=part(translate(boot_shape(leg_x,profile,d==2),at),
                                   [cx+leg_x,ground],
                                   joints=translate([(leg_x,-62),(leg_x,-28),(leg_x,0)],at))
        views[f'{body}_{d}']={'source':'directions','ground':list(at),'scale':64/323,'parts':parts}

def original(d, ground, top, parts):
    views[f'male_{d}']={'source':'original','ground':ground,'scale':64/(ground[1]-top),'parts':parts}

original(0,[726,492],151,{
 'head':part([[656,248],[664,224],[680,206],[700,196],[698,180],[704,160],[715,151],[732,153],[753,162],[763,179],[755,186],[770,194],[781,211],[792,235],[790,254],[783,273],[792,277],[790,291],[778,303],[761,314],[739,321],[716,320],[694,314],[678,304],[667,291],[662,275],[661,266],[656,257]],[726,262]),
 'torso':part([[693,317],[709,321],[727,321],[746,317],[766,320],[775,347],[775,378],[772,406],[780,449],[760,460],[739,465],[716,464],[691,465],[670,455],[678,424],[682,394],[681,357],[681,336]],[726,382]),
 'arm_R':part([[689,326],[677,334],[666,359],[657,375],[666,386],[659,395],[647,406],[648,417],[658,425],[670,417],[677,400],[686,388],[693,365]],[680,338],joints=[[680,338],[669,380],[659,407]]),
 'arm_L':part([[769,326],[779,338],[786,356],[789,376],[783,390],[788,403],[790,414],[784,422],[775,419],[770,407],[768,391],[761,369],[759,341]],[771,337],joints=[[771,337],[778,383],[780,409]]),
 'leg_R':part([[683,451],[708,460],[710,476],[709,488],[697,493],[676,494],[670,490],[675,480],[682,475]],[693,491],joints=[[695,429],[694,471],[693,491]]),
 'leg_L':part([[740,461],[761,455],[768,469],[777,480],[777,490],[766,494],[744,492],[740,483]],[758,491],joints=[[754,429],[754,471],[758,491]])})

original(6,[1022,493],152,{
 'head':part([[953,252],[949,234],[958,209],[972,190],[976,182],[971,175],[976,161],[989,152],[1004,155],[1018,165],[1021,181],[1042,184],[1066,195],[1082,212],[1093,232],[1100,254],[1092,261],[1084,254],[1081,243],[1081,269],[1075,277],[1077,288],[1072,300],[1057,311],[1032,315],[1012,311],[995,304],[985,296],[973,286],[963,270]],[1022,260]),
 'torso':part([[999,314],[1015,315],[1033,315],[1051,323],[1056,347],[1053,374],[1057,403],[1057,436],[1075,454],[1055,464],[1037,469],[1017,461],[992,462],[965,458],[974,431],[982,401],[985,371],[986,337]],[1022,383]),
 'arm_R':part([[1045,339],[1058,345],[1063,371],[1060,386],[1068,400],[1066,416],[1056,422],[1046,411],[1045,395],[1040,372]],[1046,344],joints=[[1046,344],[1052,382],[1057,410]]),
 'arm_L':part([[988,326],[1000,322],[1015,337],[1020,361],[1018,379],[1015,391],[1021,405],[1018,418],[1010,424],[999,425],[991,419],[989,405],[992,394],[988,376],[978,360]],[997,337],joints=[[997,337],[1004,385],[1007,414]]),
 'leg_R':part([[994,457],[1025,464],[1025,479],[1012,488],[989,489],[980,486],[986,480],[994,475]],[1000,491],joints=[[1000,429],[1000,473],[1000,491]]),
 'leg_L':part([[1030,461],[1049,461],[1056,477],[1078,482],[1078,488],[1061,489],[1030,487]],[1050,491],joints=[[1040,429],[1044,473],[1050,491]])})

original(4,[1335,492],151,{
 'head':part([[1267,266],[1263,241],[1273,218],[1287,194],[1311,184],[1310,175],[1314,160],[1327,151],[1345,154],[1359,166],[1363,183],[1380,192],[1391,213],[1402,235],[1407,258],[1401,278],[1391,299],[1372,312],[1348,317],[1320,317],[1297,309],[1280,294],[1268,280]],[1335,261]),
 'torso':part([[1304,314],[1322,319],[1342,319],[1367,314],[1382,327],[1384,355],[1382,380],[1380,403],[1385,433],[1397,457],[1375,464],[1352,467],[1335,463],[1311,466],[1288,460],[1272,457],[1284,427],[1293,397],[1292,365],[1286,341]],[1335,382]),
 'arm_L':part([[1294,325],[1280,334],[1277,357],[1271,378],[1278,390],[1276,403],[1281,417],[1289,419],[1297,408],[1298,390],[1304,370],[1304,348]],[1291,340],joints=[[1291,340],[1286,382],[1286,408]]),
 'arm_R':part([[1378,325],[1390,333],[1405,355],[1403,371],[1404,389],[1410,398],[1408,408],[1400,410],[1391,403],[1388,393],[1397,379],[1394,353]],[1386,340],joints=[[1386,340],[1395,382],[1393,399]]),
 'leg_L':part([[1294,455],[1322,463],[1325,476],[1320,491],[1293,492],[1285,488],[1289,477]],[1307,491],joints=[[1307,429],[1307,473],[1307,491]]),
 'leg_R':part([[1349,465],[1376,460],[1384,474],[1386,490],[1367,493],[1348,490]],[1365,491],joints=[[1365,429],[1365,473],[1365,491]])})

weapon={'source':'original','scale':64/341,'pivot':[659,407],
        'tip':[584,492],
        'polygon':[[646,392],[652,398],[659,410],[662,416],[668,421],[668,425],[664,428],[658,426],[658,421],[584,492],[650,414],[641,405],[640,399]],
        'blade_interior':[[650,414],[653,419],[584,492]]}
for key, view in views.items():
    body, direction = key.split('_'); d=int(direction)
    cx, ground = view['ground']
    if view['source']=='original':
        absolute_seams={
          0: ([[693,328],[695,348],[688,371],[679,386]],[[761,329],[758,349],[764,375],[772,391]]),
          4: ([[1304,326],[1307,348],[1304,372],[1298,392]],[[1368,326],[1364,348],[1373,373],[1380,391]]),
          6: ([[1007,329],[1014,348],[1017,375],[1012,393]],[[1050,334],[1052,352],[1054,378],[1058,396]])
        }
        seams=absolute_seams[d]
    else:
        seams=tuple(translate(seam,(cx,ground)) for seam in SLEEVE_SEAMS[body][d])
    view['sleeve_seams']={}
    for screen_side, seam in enumerate(seams):
        # Select the anatomical side from this view's drawing, not a fixed
        # screen-left assignment (the rear views reverse the two arms).
        side=min(('L','R'),key=lambda s: view['parts']['arm_'+s]['joints'][0][0]) if screen_side==0 else max(('L','R'),key=lambda s: view['parts']['arm_'+s]['joints'][0][0])
        outside=cx+(-90 if screen_side==0 else 90)
        view['sleeve_seams']['arm_'+side]=seam+[[outside,seam[-1][1]+2],[outside,seam[0][1]-8]]
    # Complete the coat underneath BOTH the sleeve and the resting hand.
    # The short shoulder-only patch stopped above the belt: moving a palm
    # left a black-outlined hole all the way down to the skirt (male E).
    # Use this view's actual coat silhouette, clipped to source opacity by
    # Godot; visible collar, belt and skirt paint still renders on top.
    view['body_core']=[p[:] for p in view['parts']['torso']['polygon']]
    # Continue the concealed waist strap under the resting palms too.
    # Its painted clasp and knots stay on the original torso overlay.
    view['waist']=[ground-119,ground-107]
    # The neck belongs to the chest hierarchy, not an independent bobbing block.
    view['neck']=[cx,ground-174] if view['source']=='directions' else {0:[726,321],4:[1335,318],6:[1022,315]}[d]
    eyes=[[cx-24,ground-210,7.5,11],[cx+20,ground-210,8,11]]
    if d in (3,4,5): eyes=[[0,0,0,0],[0,0,0,0]]
    elif d in (2,6): eyes=[[cx+(-35 if d==2 else 31),ground-210,6.5,10],[0,0,0,0]]
    if view['source']=='original':
        eyes={0:[[697,280,8,13],[751,280,8,13]],
              4:[[0,0,0,0],[0,0,0,0]],
              6:[[1059,269,6,10],[0,0,0,0]],
              7:[[318,417,21,28],[411,414,16,27]]}[d]
    view['eyes']=eyes
    if view['source']=='original' and d in (0,4,6):
        # Reserve the baked weapon pixels: the live weapon is a separate
        # source cutout, and unarmed hands must not carry its old guard.
        if d==6:
            view['baked_weapon']=[[1068,407],[1075,414],[1070,420],[1070,426],[1113,486],[1108,488],[1065,433],[1060,431],[1057,426],[1058,421],[1063,417]]
        elif d==4:
            view['baked_weapon']=[[1403,398],[1410,405],[1406,409],[1403,413],[1447,485],[1445,489],[1400,430],[1393,429],[1383,426],[1382,421],[1392,414]]
        for part_id, data in view['parts'].items():
            if part_id.startswith('leg_'):
                data['polygon']=[[x,min(y,491)] for x,y in data['polygon']]
    # Reusing the standing pants above the boot drags its painted creases
    # through the moving knee. Source boots now start at the actual cuff;
    # the hidden pants bridge is drawn from the current knee/ankle instead.
    for side in ('L','R'):
        data=view['parts']['leg_'+side]
        cuff=ground-22
        data['polygon']=[[x,max(y,cuff)] for x,y in data['polygon']]
for key, view in views.items():
    author_modular_parts(key, view, OUT)
author_atlas(views, OUT)
author_directional_parts(views, OUT)

manifest={'revision':'concept-directional-parts-41','contours':'res://assets/characters/concept-rig/contours.json','sources':{
 'original':{'path':'res://assets/characters/concept-rig/character-concept-01.png','size':[1586,992]},
 'directions':{'path':'res://assets/characters/concept-rig/character-directions-02.png','size':[1774,887]}},
 'native_height':64,'views':views,'sword':weapon,
 'layer_ids':{'head':1,'torso':2,'arm_L':3,'arm_R':4,'leg_L':5,'leg_R':6},
 'contract':'Approved head/coat detail retained; complete view-specific SVG limbs, bone-local anchors, painted overlap, explicit hand states and back-view occlusion.'}
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'Authored {len(views)} source views; original drawings unchanged; {OUT}')
