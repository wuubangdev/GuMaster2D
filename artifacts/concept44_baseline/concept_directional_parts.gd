class_name GuConceptDirectionalParts
extends RefCounted
## Complete drawings are authored first in bone-local coordinates. Runtime
## only places rigid pieces at measured anchors; it never scales their bones
## or stretches a standing-pose fragment across an exposed joint.

static func available(view: Dictionary) -> bool:
	return view.has("directional_art")

static func hand_state(snapshot: Dictionary, side: String) -> String:
	var weapon := str(snapshot["appearance"]["weapon"])
	var prop: Dictionary = snapshot.get("held_prop",GuCharacterHeldProp.desired(snapshot["action"],float(snapshot["phase"]),weapon))
	if side=="R" and prop["kind"]!="none" and float(prop["opacity"])>.01: return "grip"
	if GuCharacterActionMotion.harvesting(snapshot["action"]):
		if side=="L": return "relaxed"
		return "grip" if snapshot["action"]=="mine" or float(snapshot["phase"])>=.49 and float(snapshot["phase"])<.78 else "relaxed"
	if side=="R" and weapon!="unarmed": return "grip"
	if snapshot["action"] in ["cast","channel"]: return "cast"
	if snapshot["action"] in ["attack","defend"]: return "fist"
	return "relaxed"

static func placement(view: Dictionary, asset: Dictionary, pose: Dictionary) -> Transform2D:
	var side := str(asset["side"])
	var bone := str(asset["bone"])
	var arm: PackedVector2Array = pose["arm_"+side]
	var leg: PackedVector2Array = pose["leg_"+side]
	var origin := Vector2.ZERO
	var rotation := 0.0
	match bone:
		"shoulder":
			origin=arm[0]
			rotation=float(pose["torso_rotation"])
		"upper_arm":
			origin=arm[0]
			rotation=Vector2.DOWN.angle_to(arm[1]-arm[0])
		"forearm":
			origin=arm[1]
			rotation=Vector2.DOWN.angle_to(arm[2]-arm[1])
		"hand":
			origin=pose["wrist_"+side]
			rotation=Vector2.DOWN.angle_to(arm[2]-arm[1])+float(pose["hand_rotation_"+side])
		"thigh":
			origin=leg[0]
			rotation=Vector2.DOWN.angle_to(leg[1]-leg[0])
		"shin":
			origin=leg[1]
			rotation=Vector2.DOWN.angle_to(leg[2]-leg[1])
		"foot":
			origin=leg[2]
			rotation=float(pose["foot_rotation_"+side])
	return Transform2D(rotation,origin)

static func draw_piece(canvas: CanvasItem, view: Dictionary, key: String, pose: Dictionary, offset: Vector2, factor: float, tint: Color) -> void:
	var asset: Dictionary = view["directional_art"]["parts"][key]
	var local := placement(view,asset,pose)
	var b: Array = asset["bounds"]
	var corners := PackedVector2Array([Vector2(b[0],b[1]),Vector2(b[0]+b[2],b[1]),Vector2(b[0]+b[2],b[1]+b[3]),Vector2(b[0],b[1]+b[3])])
	var rect: Array = asset["atlas_rect"]
	var atlas := Vector2(view["directional_art"]["atlas_size"][0],view["directional_art"]["atlas_size"][1])
	var uvs := PackedVector2Array()
	for uv in [Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]:
		uvs.append(Vector2(18,0)+(Vector2(rect[0],rect[1])+uv*Vector2(rect[2],rect[3]))/atlas)
	for i in range(4): corners[i]=offset+(local*corners[i])*factor
	canvas.draw_polygon(corners,PackedColorArray([tint]),uvs,GuConceptCharacterArt._texture(str(view["source"])))

static func draw_arm(canvas: CanvasItem, snapshot: Dictionary, view: Dictionary, side: String, pose: Dictionary, rest: Dictionary, offset: Vector2, factor: float, tint: Color, bone_filter: int=-1) -> void:
	if bone_filter!=0:
		draw_piece(canvas,view,"forearm_"+side,pose,offset,factor,tint)
	if bone_filter!=1:
		draw_piece(canvas,view,"shoulder_"+side,pose,offset,factor,tint)
		draw_piece(canvas,view,"sleeve_"+side,pose,offset,factor,tint)
	if bone_filter==0: return
	# Draw the weapon under the gripping fingers, using the same wrist/grip
	# transform that the rig uses for skill origins and the weapon tip.
	if side=="R":
		var prop: Dictionary = snapshot.get("held_prop",GuCharacterHeldProp.desired(snapshot["action"],float(snapshot["phase"]),str(snapshot["appearance"]["weapon"])))
		var prop_tint := tint
		prop_tint.a*=float(prop["opacity"])
		if prop_tint.a>.001:
			match prop["kind"]:
				"pick": GuHarvestToolArt.draw(canvas,snapshot,offset,factor,prop_tint)
				"sword": GuConceptCharacterArt._draw_sword(canvas,snapshot,rest,offset,prop_tint)
				"spear": GuConceptCharacterArt._draw_spear(canvas,snapshot,offset,factor,prop_tint)
	draw_piece(canvas,view,"hand_"+hand_state(snapshot,side)+"_"+side,pose,offset,factor,tint)

static func draw_leg(canvas: CanvasItem, view: Dictionary, side: String, pose: Dictionary, offset: Vector2, factor: float, tint: Color) -> void:
	for part in ["thigh","shin","boot_"+str(pose.get("source_boots","cloth"))]:
		draw_piece(canvas,view,part+"_"+side,pose,offset,factor,tint)
