class_name GuConceptJointSkin
extends RefCounted
## Continuous cloth cross-sections around an anatomical chain. Endpoints
## remain on the real bones; limited transverse rotation eases each seam.
## Palms, weapons and boots retain their rigid transforms.

const COLUMNS := 4
const ROWS := 12
const PoseFit = preload("res://scripts/presentation/concept_pose_fit.gd")
static var _meshes: Dictionary = {}

static func supports(asset: Dictionary) -> bool:
	return asset.get("deform","")=="joint_cross_sections_v1"

static func controls(view: Dictionary, asset: Dictionary, pose: Dictionary) -> Vector4:
	var side := str(asset["side"])
	var bone := str(asset["bone"])
	var arm: PackedVector2Array = pose["arm_"+side]
	var leg: PackedVector2Array = pose["leg_"+side]
	var chain := arm if bone in ["upper_arm","forearm"] else leg
	var flex := (chain[1]-chain[0]).angle_to(chain[2]-chain[1])
	var length: float
	var start := 0.0
	var end := 0.0
	var bow := 0.0
	match bone:
		"upper_arm":
			length=chain[0].distance_to(chain[1])
			var source := GuConceptCharacterRig._joint_list(view,"arm_"+side)
			var rest := (source[1]-source[0]).rotated(float(pose["torso_rotation"]))
			start=clampf((chain[1]-chain[0]).angle_to(rest)*.18,-.20,.20)
			end=clampf(flex*.18,-.24,.24)
			bow=sin(flex)*.15
		"forearm":
			length=chain[1].distance_to(pose["wrist_"+side])
			start=clampf(-flex*.10,-.14,.14)
			end=clampf(float(pose["hand_rotation_"+side])*.2,-.12,.12)
			bow=-sin(flex)*.08
		"thigh":
			length=chain[0].distance_to(chain[1])
			end=clampf(flex*.10,-.14,.14)
			bow=sin(flex)*.08
		"shin":
			length=chain[1].distance_to(chain[2])
			start=clampf(-flex*.10,-.14,.14)
			end=clampf((chain[2]-chain[1]).angle_to(Vector2.DOWN.rotated(float(pose["foot_rotation_"+side])))*.10,-.14,.14)
			bow=-sin(flex)*.06
	return Vector4(length,start,end,bow)

static func vertex(point: Vector2, skin: Vector4) -> Vector2:
	var t := clampf(point.y/maxf(.01,skin.x),0,1)
	# Flatten derivatives at both seams; denser rows near joints prevent
	# large automatic triangles from cutting across a bent cloth surface.
	var twist := skin.y*(1-smoothstep(0,.42,t))+skin.z*smoothstep(.55,1,t)
	var bow := skin.w*pow(sin(t*PI),2)
	return Vector2(point.x*cos(twist)+bow,point.y+point.x*sin(twist))

static func mesh(view: Dictionary, asset: Dictionary, segment: int = 0) -> Dictionary:
	var key := str(asset["path"])+":"+str(segment)
	if _meshes.has(key): return _meshes[key]
	var b: Array = asset["bounds"]
	var top := float(b[1])
	var bottom := top+float(b[3])
	if segment!=0:
		var cuff := minf(1.4,float(asset["anchors"]["wrist"][1])*.32)
		if segment<0: bottom=cuff
		else: top=cuff
	var rect: Array = asset["atlas_rect"]
	var atlas: Array = view["directional_art"]["atlas_size"]
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for row in range(ROWS+1):
		for column in range(COLUMNS+1):
			var unit := Vector2(float(column)/COLUMNS,float(row)/ROWS)
			var point := Vector2(float(b[0])+unit.x*float(b[2]),lerpf(top,bottom,unit.y))
			vertices.append(point)
			var uv := (point-Vector2(b[0],b[1]))/Vector2(b[2],b[3])
			uvs.append(Vector2(18,0)+(Vector2(rect[0],rect[1])+uv*Vector2(rect[2],rect[3]))/Vector2(atlas[0],atlas[1]))
			if row<ROWS and column<COLUMNS:
				var i := row*(COLUMNS+1)+column
				indices.append_array(PackedInt32Array([i,i+1,i+COLUMNS+2,i,i+COLUMNS+2,i+COLUMNS+1]))
	var result := {"vertices":vertices,"uvs":uvs,"indices":indices}
	_meshes[key]=result
	return result

static func draw(canvas: CanvasItem, view: Dictionary, asset: Dictionary, pose: Dictionary, local: Transform2D, offset: Vector2, factor: float, tint: Color, segment: int = 0) -> void:
	var data := mesh(view,asset,segment)
	var skin := controls(view,asset,pose)
	var fit := PoseFit.weights(view,asset,pose)
	var points: PackedVector2Array = data["vertices"].duplicate()
	for i in range(points.size()): points[i]=offset+(local*fitted_vertex(points[i],skin,asset,fit))*factor
	# One cached-topology draw per piece, not a draw command per triangle.
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(),data["indices"],points,PackedColorArray([tint]),data["uvs"],PackedInt32Array(),PackedFloat32Array(),GuConceptCharacterArt._texture(str(view["source"])).get_rid())

static func projected_vertex(point: Vector2, skin: Vector4, asset: Dictionary) -> Vector2:
	# Front/back legs bend toward the camera: their projected length changes
	# while their physical bones do not. Fit the drawing between those two
	# projected joints. Preserve the overlap caps outside the bone interval
	# so foreshortening cannot expose a hole at the knee or boot cuff.
	if asset.get("bone", "") in ["thigh", "shin"]:
		var rest_length := float(asset["anchors"]["tip"][1])
		if point.y < 0:
			pass
		elif point.y > rest_length:
			point.y = skin.x + point.y - rest_length
		else:
			point.y *= skin.x / maxf(.01, rest_length)
	return point

static func fitted_vertex(point: Vector2, skin: Vector4, asset: Dictionary, fit: Vector3) -> Vector2:
	point=projected_vertex(point,skin,asset)
	return vertex(PoseFit.vertex(point,skin.x,asset,fit),skin)
