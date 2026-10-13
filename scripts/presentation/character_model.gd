class_name GuCharacterModel
extends Node3D
## Original modular, skinned wuxia character. Geometry is editable/exportable, not a flat billboard.
## All meshes share the same named skeleton; appearance has no gameplay authority.

const BONE_SPEC := [
	["Hips", "", Vector3(0,.98,0)], ["Spine","Hips",Vector3(0,.22,0)],
	["Chest","Spine",Vector3(0,.24,0)], ["Neck","Chest",Vector3(0,.14,0)], ["Head","Neck",Vector3(0,.17,0)],
	["Shoulder_L","Chest",Vector3(-.18,.06,0)], ["UpperArm_L","Shoulder_L",Vector3(-.13,0,0)],
	["Forearm_L","UpperArm_L",Vector3(0,-.27,0)], ["Hand_L","Forearm_L",Vector3(0,-.25,0)],
	["Shoulder_R","Chest",Vector3(.18,.06,0)], ["UpperArm_R","Shoulder_R",Vector3(.13,0,0)],
	["Forearm_R","UpperArm_R",Vector3(0,-.27,0)], ["Hand_R","Forearm_R",Vector3(0,-.25,0)],
	["Thigh_L","Hips",Vector3(-.13,-.04,0)], ["Shin_L","Thigh_L",Vector3(0,-.45,0)], ["Foot_L","Shin_L",Vector3(0,-.42,.035)],
	["Thigh_R","Hips",Vector3(.13,-.04,0)], ["Shin_R","Thigh_R",Vector3(0,-.45,0)], ["Foot_R","Shin_R",Vector3(0,-.42,.035)],
	["Hair","Head",Vector3(0,.11,.08)], ["Cape","Chest",Vector3(0,-.08,.10)], ["CapeTip","Cape",Vector3(0,-.32,.01)]
]
var skeleton: Skeleton3D
var animator: AnimationPlayer
var surfaces: Node3D
var skin: Skin
var appearance: Dictionary = {"body":"male", "outfit":"jade", "weapon":"sword", "hair":"topknot"}
var materials: Dictionary = {}
var buckets: Dictionary = {}
var active_clip: String = ""
var last_facing: Vector2 = Vector2.DOWN
var triangle_count: int = 0
var mesh_count: int = 0
var _built: bool = false
var transition_left: float = 0.0
var transition_duration: float = .12
var transition_from: Array[Transform3D] = []
var blend_transitions: bool = true
var motion_family: String = ""
var _building_weapon: bool = false
var prefer_baked_assets: bool = true
var geometry_source: String = "generated"
var geometry_asset_path: String = ""
var geometry_asset: GuCharacterMeshAsset
static var _verified_assets: Dictionary = {}

func _init() -> void:
	name = "GuCharacter"
	_build_rig()

func _ready() -> void:
	if not _built:
		_rebuild()

func _build_rig() -> void:
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	add_child(skeleton)
	for spec in BONE_SPEC:
		skeleton.add_bone(spec[0])
		var index := skeleton.find_bone(spec[0])
		if not str(spec[1]).is_empty():
			skeleton.set_bone_parent(index, skeleton.find_bone(spec[1]))
		var rest := Transform3D(Basis.IDENTITY, spec[2])
		skeleton.set_bone_rest(index, rest)
		skeleton.set_bone_pose_position(index, spec[2])
	skin = Skin.new()
	for i in range(skeleton.get_bone_count()):
		skin.add_bind(i, skeleton.get_bone_global_rest(i).affine_inverse())
	surfaces = Node3D.new()
	surfaces.name = "Surfaces"
	add_child(surfaces)
	animator = AnimationPlayer.new()
	animator.name = "AnimationPlayer"
	animator.root_node = NodePath("..")
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	add_child(animator)

func set_appearance(value: Dictionary) -> void:
	value = GuCharacterAppearance.sanitize(value)
	if appearance == value and _built:
		return
	appearance = value.duplicate(true)
	_rebuild()

func get_appearance() -> Dictionary:
	return appearance.duplicate(true)

func set_motion(action: String, time: float, facing: Vector2, reduced: bool = false) -> void:
	if not _built:
		_rebuild()
	if reduced:
		transition_left = 0
	if facing.is_finite() and facing.length_squared() > .0001:
		last_facing = facing.normalized()
	var direction := last_facing
	var yaw := atan2(-direction.x, -direction.y)
	rotation.y = lerp_angle(rotation.y,yaw,1-exp(-18*get_process_delta_time())) if blend_transitions and not reduced and not active_clip.is_empty() else yaw
	var clip := action if animator.has_animation(action) else "idle"
	if clip != active_clip:
		transition_from.clear()
		if not active_clip.is_empty() and blend_transitions and not reduced:
			for i in range(skeleton.get_bone_count()):
				transition_from.append(skeleton.get_bone_pose(i))
			transition_duration = .12 if clip in ["idle","walk","run"] else .045
			transition_left = transition_duration
		animator.play(clip)
		active_clip = clip
	var animation := animator.get_animation(clip)
	var sample := 0.0 if reduced and clip in ["idle", "walk", "run", "channel", "defend"] else maxf(time, 0)
	if animation.loop_mode == Animation.LOOP_LINEAR:
		sample = fposmod(sample, animation.length)
	else:
		sample = minf(sample, animation.length)
	animator.seek(sample, true)
	if transition_left > 0 and not transition_from.is_empty() and blend_transitions:
		transition_left = maxf(0,transition_left-clampf(get_process_delta_time(),.001,.05))
		var blend := smoothstep(0.0,1.0,1-transition_left/transition_duration)
		for i in range(skeleton.get_bone_count()):
			var target := skeleton.get_bone_pose(i)
			skeleton.set_bone_pose_position(i,transition_from[i].origin.lerp(target.origin,blend))
			skeleton.set_bone_pose_rotation(i,transition_from[i].basis.get_rotation_quaternion().slerp(target.basis.get_rotation_quaternion(),blend))
	skeleton.force_update_all_bone_transforms()

func advance(delta: float) -> void:
	animator.advance(delta)

func hand_position(side: String = "R") -> Vector3:
	return skeleton.get_bone_global_pose(skeleton.find_bone("Hand_" + side)).origin

func _rebuild() -> void:
	for child in surfaces.get_children():
		child.free()
	buckets.clear()
	materials.clear()
	triangle_count = 0
	mesh_count = 0
	_palette()
	if not _load_baked_geometry():
		geometry_source = "generated"
		geometry_asset_path = ""
		geometry_asset = null
		_body()
		_costume()
		_face_and_hair()
		_weapon()
		_commit()
	var family := str(appearance.get("weapon","sword"))
	if family != motion_family:
		animator.stop()
		if animator.has_animation_library(""):
			animator.remove_animation_library("")
		animator.add_animation_library("", GuCharacterAnimations.create_library(family))
		motion_family = family
		active_clip = ""
		transition_left = 0
	_built = true

func _load_baked_geometry() -> bool:
	if not prefer_baked_assets:
		return false
	var path := GuCharacterMeshAsset.path_for(appearance)
	if not ResourceLoader.exists(path):
		return false
	var asset: GuCharacterMeshAsset = _verified_assets.get(path)
	if asset==null:
		asset = load(path) as GuCharacterMeshAsset
		if asset==null or not asset.is_compatible(appearance,skeleton):
			return false
		_verified_assets[path] = asset
	for mesh in asset.layer_meshes:
		var key := mesh.resource_name.trim_prefix("Gu_")
		materials[key] = mesh.surface_get_material(0)
		_attach_mesh(mesh,key)
	triangle_count = asset.triangles
	geometry_asset = asset
	geometry_source = "baked"
	geometry_asset_path = path
	return true

func _attach_mesh(mesh: ArrayMesh, key: String) -> void:
	var instance := MeshInstance3D.new()
	instance.name = "Layer_"+key
	instance.mesh = mesh
	instance.skin = skin
	instance.skeleton = NodePath("../../Skeleton3D")
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	surfaces.add_child(instance)
	mesh_count += 1

func _mat(key: String, color: String, rough: float = .72, metal: float = 0) -> void:
	var material := StandardMaterial3D.new()
	material.resource_name = "Gu_" + key
	material.albedo_color = Color(color)
	material.roughness = rough
	material.metallic = metal
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	materials[key] = material

func _palette() -> void:
	var outfit := str(appearance.get("outfit", "jade"))
	_mat("skin", "d9a47d" if appearance.get("body") == "male" else "edbb97", .82)
	_mat("shadow_skin", "b97960", .84)
	_mat("hair", "1b222d", .62)
	_mat("hair_light", "34414c", .64)
	_mat("eye", "161b25", .45)
	_mat("ivory", "e9dbc0", .8)
	_mat("cloth", "215f67" if outfit == "jade" else ("873c49" if outfit == "crimson" else "d6c8a5"), .94)
	_mat("cloth_dark", "193641" if outfit == "jade" else ("432c3b" if outfit == "crimson" else "69665e"), .92)
	_mat("cloth_light", "3d8c8b" if outfit == "jade" else ("b26365" if outfit == "crimson" else "f0e3c9"), .9)
	_mat("leather", "3b3030", .88)
	_mat("gold", "b99a57", .38, .62)
	_mat("jade", "76c4a3", .32, .12)
	_mat("steel", "b9ced7", .26, .68)
	_mat("steel_dark", "5d7483", .37, .5)
	_mat("lip", "bc8277" if appearance.get("body")=="male" else "bd7974", .66)
	_mat("face_skin", "d3a68b" if appearance.get("body")=="male" else "ddb297", .78)
	_mat("eye_white", "eee9df", .29)
	_mat("iris", "514337", .24)
	for key in ["cloth","cloth_dark","cloth_light","ivory"]:
		_textile(key, "silk_"+outfit+"_albedo.svg", "silk_normal.svg", Vector3(1.6,2.0,1), .20)
	_textile("leather","leather_albedo.svg","leather_normal.svg",Vector3(1.7,1.7,1),.18)
	_textile("hair","hair_albedo.svg","hair_normal.svg",Vector3(1,1.3,1),.23)
	_textile("hair_light","hair_albedo.svg","hair_normal.svg",Vector3(1,1.3,1),.23)
	_textile("steel","metal_albedo.svg","metal_normal.svg",Vector3(1.2,1.2,1),.12)
	_textile("face_skin","skin_albedo.svg","",Vector3.ONE,0)

func _textile(key: String, albedo_file: String, normal_file: String, repeat: Vector3, strength: float) -> void:
	var material: StandardMaterial3D = materials[key]
	material.albedo_texture = load("res://assets/characters/textures/"+albedo_file)
	material.uv1_scale = repeat
	if not normal_file.is_empty():
		material.normal_enabled = true
		material.normal_texture = load("res://assets/characters/textures/"+normal_file)
		material.normal_scale = strength

func _body() -> void:
	var female: bool = appearance.get("body") == "female"
	var width := .87 if female else 1.0
	# Inner anatomy stays inside the fitted tunic; the garment owns its silhouette.
	_shape("Spine", "skin", [Vector4(-.22,.133*width,.091,0), Vector4(-.10,.140*width,.094,0), Vector4(.08,.180*width,.106,0), Vector4(.21,.188*width,.099,0),Vector4(.285,.125*width,.070,0),Vector4(.34,.054,.051,0)], 28, 0, "Chest")
	_ellipsoid("Neck", "skin", Vector3(0,.01,0), Vector3(.057,.092,.055), 20, 12)
	for side in ["L","R"]:
		_shape("Thigh_"+side,"cloth_dark",[Vector4(.015,.086,.091,0),Vector4(-.16,.085,.091,0),Vector4(-.34,.064,.067,0),Vector4(-.46,.058,.059,0)],20,.003)
		_shape("Shin_"+side,"leather",[Vector4(.025,.062,.065,0),Vector4(-.12,.066,.07,0),Vector4(-.31,.052,.056,0),Vector4(-.42,.05,.052,0)],20,.001)
		_ellipsoid("Foot_"+side,"leather",Vector3(0,-.025,-.07),Vector3(.059,.058,.147),24,10)
		_ellipsoid("Foot_"+side,"gold",Vector3(0,-.044,-.075),Vector3(.060,.009,.146),20,6)
		for y in [-.085,-.20,-.31]:
			_shape("Shin_"+side,"gold",[Vector4(y,.068 if y > -.2 else .058,.073 if y > -.2 else .061,0),Vector4(y-.01,.068 if y > -.2 else .058,.073 if y > -.2 else .061,0)],20)
		# All current outfits fully cover the upper arm. Omit its hidden skin
		# shell rather than drawing intersecting caps through weighted shoulders.
		_ellipsoid("Forearm_"+side,"skin",Vector3(0,-.115,0),Vector3(.052,.138,.05),20,10)
		var closed: bool = appearance.get("weapon")=="unarmed" or side=="R" or appearance.get("weapon")=="spear"
		var spear: bool = appearance.get("weapon")=="spear"
		var palm_z := .007 if spear else -.006
		_ellipsoid("Hand_"+side,"skin",Vector3(0,-.043,palm_z),Vector3(.037,.05,.026),20,10)
		for finger in range(4):
			if closed:
				var finger_z := .027 if spear else -.034
				_ellipsoid("Hand_"+side,"skin",Vector3((finger-1.5)*.016,-.072,finger_z),Vector3(.010,.023,.017),10,8)
			else:
				_ellipsoid("Hand_"+side,"skin",Vector3((finger-1.5)*.015,-.090,-.011),Vector3(.009,.031+float(finger%3)*.003,.011),10,8)
		var sign_x := 1.0 if side=="R" else -1.0
		_ellipsoid("Hand_"+side,"skin",Vector3(sign_x*.034,-.05,.037 if spear else -.032) if closed else Vector3(sign_x*.044,-.04,-.012),Vector3(.013,.026,.014),10,8)

func _costume() -> void:
	GuCharacterGarments.build(self)

func _face_and_hair() -> void:
	GuCharacterFace.build(self)

func _weapon() -> void:
	var weapon := str(appearance.get("weapon","sword"))
	if weapon == "unarmed":
		return
	var bone := "Hand_R"
	_building_weapon = true
	if weapon == "spear":
		_tube(bone,"leather",[Vector3(0,.65,-.025),Vector3(0,-.82,-.025)],.019,12)
		for y in [.54,.4,-.13,-.68]:
			_tube(bone,"gold",[Vector3(0,y,-.025),Vector3(0,y-.024,-.025)],.025,12)
		_blade(bone,"steel",Vector3(0,.65,-.025),-.35,.075)
		_tube(bone,"crimson" if materials.has("crimson") else "cloth_light",[Vector3(0,.53,-.005),Vector3(.06,.36,.012),Vector3(.035,.20,.018)],.018,10)
	else:
		_tube(bone,"leather",[Vector3(0,.018,-.034),Vector3(0,-.15,-.034)],.020,12)
		for y in [0.0,-.04,-.08,-.12]:
			_tube(bone,"gold",[Vector3(0,y,-.034),Vector3(0,y-.008,-.034)],.022,12)
		_ellipsoid(bone,"gold",Vector3(0,.027,-.034),Vector3(.025,.025,.024),14,8)
		_tube(bone,"gold",[Vector3(-.11,-.16,-.034),Vector3(0,-.177,-.034),Vector3(.11,-.16,-.034)],.020,12)
		_blade(bone,"steel",Vector3(0,-.18,-.034),.65,.045)
		_tube(bone,"steel_dark",[Vector3(0,-.185,-.05),Vector3(0,-.72,-.05)],.005,6)
		_tube(bone,"cloth_light",[Vector3(.055,-.167,-.028),Vector3(.078,-.25,-.023),Vector3(.054,-.33,-.015)],.008,8)

	_building_weapon = false

func _shape(bone: String, material: String, rings: Array, segments: int = 20, folds: float = 0.0, blend_bone: String = "", shoulder_side: float = 0.0) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for row in range(rings.size()):
		var r: Vector4 = rings[row]
		for col in range(segments+1):
			var theta := TAU*col/segments
			var wrinkle := folds*cos(theta*6+.4*row)
			var shoulder_curve := -shoulder_side*.082*clampf((r.x+.085)/.111,0,1)
			vertices.append(Vector3(sin(theta)*(r.y+wrinkle)+shoulder_curve,r.x,cos(theta)*(r.z+wrinkle)+r.w))
			var lo: Vector4 = rings[maxi(row-1,0)]
			var hi: Vector4 = rings[mini(row+1,rings.size()-1)]
			var dy := hi.x-lo.x
			var center_delta := -shoulder_side*.082*(clampf((hi.x+.085)/.111,0,1)-clampf((lo.x+.085)/.111,0,1))
			var slope := -((hi.y-lo.y)*sin(theta)*sin(theta)/maxf(r.y,.01)+(hi.z-lo.z)*cos(theta)*cos(theta)/maxf(r.z,.01)+center_delta*sin(theta)/maxf(r.y,.01)+(hi.w-lo.w)*cos(theta)/maxf(r.z,.01))/dy if absf(dy)>.0001 else 0.0
			normals.append(Vector3(sin(theta)/maxf(r.y,.01),slope,cos(theta)/maxf(r.z,.01)).normalized())
			uv.append(Vector2(float(col)/segments,float(row)/maxi(rings.size()-1,1)))
	for row in range(rings.size()-1):
		for col in range(segments):
			var a := row*(segments+1)+col
			var b := a+segments+1
			indices.append_array(PackedInt32Array([a,b,a+1,a+1,b,b+1]))
	for cap in [0,rings.size()-1]:
		var ring: Vector4 = rings[cap]
		var center_index := vertices.size()
		var cap_curve := -shoulder_side*.082*clampf((ring.x+.085)/.111,0,1)
		vertices.append(Vector3(cap_curve,ring.x,ring.w))
		var top_cap: bool = ring.x > (Vector4(rings[rings.size()-1]).x if cap==0 else Vector4(rings[0]).x)
		normals.append(Vector3.UP if top_cap else Vector3.DOWN)
		uv.append(Vector2(.5,.5))
		for col in range(segments):
			var a: int = int(cap)*(segments+1)+col
			indices.append_array(PackedInt32Array([a,a+1,center_index]) if top_cap else PackedInt32Array([a,center_index,a+1]))
	_store(bone, material, vertices,normals,uv,indices,blend_bone)

func _ellipsoid(bone: String, material: String, center: Vector3, radii: Vector3, segments: int=16, rings: int=10) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for row in range(rings+1):
		var phi := PI*row/rings
		for col in range(segments+1):
			var theta := TAU*col/segments
			var unit := Vector3(sin(phi)*sin(theta),cos(phi),sin(phi)*cos(theta))
			vertices.append(center+unit*radii)
			normals.append((unit/radii).normalized())
			uv.append(Vector2(float(col)/segments,float(row)/rings))
	for row in range(rings):
		for col in range(segments):
			var a := row*(segments+1)+col
			var b := a+segments+1
			indices.append_array(PackedInt32Array([a,a+1,b,a+1,b+1,b]))
	_store(bone,material,vertices,normals,uv,indices)

func _tube(bone: String, material: String, points: Array, radius: float, segments: int=8, blend_bone: String="") -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for row in range(points.size()):
		var point: Vector3 = points[row]
		var tangent: Vector3 = (Vector3(points[mini(row+1,points.size()-1)])-Vector3(points[maxi(row-1,0)])).normalized()
		var axis := Vector3.RIGHT if absf(tangent.dot(Vector3.UP)) > .9 else Vector3.UP
		var right := tangent.cross(axis).normalized()
		var up := tangent.cross(right).normalized()
		for col in range(segments+1):
			var normal := right*cos(TAU*col/segments)+up*sin(TAU*col/segments)
			vertices.append(point+normal*radius)
			normals.append(normal)
			uv.append(Vector2(float(col)/segments,float(row)/maxi(points.size()-1,1)))
	for row in range(points.size()-1):
		for col in range(segments):
			var a := row*(segments+1)+col
			var b := a+segments+1
			indices.append_array(PackedInt32Array([a,a+1,b,a+1,b+1,b]))
	_store(bone,material,vertices,normals,uv,indices,blend_bone)

func _ribbon(bone: String, material: String, points: Array, half_width: float, blend_bone: String="") -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for row in range(points.size()):
		for col in range(5):
			var t := (col-2)/2.0
			var point: Vector3 = points[row]
			var taper := lerpf(.84,1.04,float(row)/maxi(points.size()-1,1))
			point.x += half_width*t*taper
			if row == points.size()-1:
				point.y += absf(t)*.026
			point.z -= (1-t*t)*.022 if point.z < 0 else -(1-t*t)*.022
			vertices.append(point)
			normals.append(Vector3(t*.15,0,-1 if point.z < 0 else 1).normalized())
			uv.append(Vector2((t+1)/2,float(row)/maxi(points.size()-1,1)))
	for row in range(points.size()-1):
		for col in range(4):
			var a := row*5+col
			indices.append_array(PackedInt32Array([a,a+5,a+1,a+1,a+5,a+6]))
	_store(bone,material,vertices,normals,uv,indices,blend_bone)

func _fabric_panel(bone: String, material: String, rows: Array, depth: float, blend_bone: String="", hem_relief: float=.025) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	var columns := 12
	for row in range(rows.size()):
		var section: Vector4 = rows[row]
		for col in range(columns+1):
			var t := float(col)/columns*2-1
			var face := -1.0 if section.z<0 else 1.0
			var wave := cos(t*PI*2.5+row*.24)*depth*.22
			var curve := (1-t*t)*depth+wave
			var y := section.y+(pow(absf(t),1.5)*hem_relief if row==rows.size()-1 else 0.0)
			if row==rows.size()-1 and hem_relief>.05:
				y -= cos(t*PI*2.0)*.012
			vertices.append(Vector3(section.x+section.w*t,y,section.z+face*curve))
			normals.append(Vector3(t*depth/maxf(section.w,.02),0,face).normalized())
			uv.append(Vector2(float(col)/columns,float(row)/maxi(rows.size()-1,1)))
	for row in range(rows.size()-1):
		for col in range(columns):
			var a := row*(columns+1)+col
			var b := a+columns+1
			indices.append_array(PackedInt32Array([a,b,a+1,a+1,b,b+1]))
	_store(bone,material,vertices,normals,uv,indices,blend_bone)

func _blade(bone: String, material: String, start: Vector3, length: float, width: float) -> void:
	var vertices := PackedVector3Array([start+Vector3(-width,0,0),start+Vector3(0,0,-.015),start+Vector3(width,0,0),start+Vector3(0,0,.015),start+Vector3(-width*.65,-length*.8,0),start+Vector3(0,-length*.8,-.01),start+Vector3(width*.65,-length*.8,0),start+Vector3(0,-length*.8,.01),start+Vector3(0,-length,0)])
	var indices := PackedInt32Array([0,4,1,1,4,5,1,5,2,2,5,6,2,6,3,3,6,7,3,7,0,0,7,4,4,8,5,5,8,6,6,8,7,7,8,4])
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	for point in vertices:
		normals.append(Vector3(signf(point.x-start.x)*.3,0,-1 if point.z<=start.z else 1).normalized())
		uv.append(Vector2(point.x,point.y))
	_store(bone,material,vertices,normals,uv,indices)

func _store(bone: String, material: String, vertices: PackedVector3Array, normals: PackedVector3Array, uv: PackedVector2Array, indices: PackedInt32Array, blend_bone: String="") -> void:
	if not buckets.has(material):
		buckets[material] = {"v":PackedVector3Array(),"n":PackedVector3Array(),"uv":PackedVector2Array(),"i":PackedInt32Array(),"b":PackedInt32Array(),"w":PackedFloat32Array()}
	var bucket: Dictionary = buckets[material]
	var base: int = bucket.v.size()
	var bone_index := skeleton.find_bone(bone)
	var blend_index := skeleton.find_bone(blend_bone) if not blend_bone.is_empty() else bone_index
	var rest := skeleton.get_bone_global_rest(bone_index)
	var grip := GuWeaponRig.grip_transform(str(appearance.get("weapon","sword"))) if _building_weapon else Transform3D.IDENTITY
	for i in range(vertices.size()):
		bucket.v.append(rest*grip*vertices[i])
		bucket.n.append(rest.basis*grip.basis*normals[i])
		bucket.uv.append(uv[i])
		var blend := 0.0
		if blend_bone == "Chest":
			blend = clampf((vertices[i].y+.07)/.14,0,.65) if bone.begins_with("UpperArm_") else clampf((vertices[i].y-.04)/.18,0,1)
		elif blend_bone == "Hips":
			blend = clampf((vertices[i].y+.18)/.2,0,.65)
		elif blend_bone == "CapeTip":
			blend = clampf((-vertices[i].y-.14)/.23,0,1)
		bucket.b.append_array(PackedInt32Array([bone_index,blend_index,0,0]))
		bucket.w.append_array(PackedFloat32Array([1-blend,blend,0,0]))
	for index in indices:
		bucket.i.append(base+index)

func _commit() -> void:
	for key in buckets:
		var bucket: Dictionary = buckets[key]
		# ArrayMesh encodes skin weights as UNORM16. Allocate exactly 65535 units
		# per vertex, retaining the rounding residual in the strongest influence.
		for vertex in range(bucket.v.size()):
			var units := PackedInt32Array([0,0,0,0])
			var largest := 0
			var total := 0
			for influence in range(4):
				var offset := vertex*4+influence
				units[influence] = roundi(float(bucket.w[offset])*65535.0)
				total += units[influence]
				if units[influence]>units[largest]:
					largest = influence
			units[largest] += 65535-total
			for influence in range(4):
				var value := units[influence]
				# Tiny interior bias avoids float32 underflow across a UNORM bin.
				bucket.w[vertex*4+influence] = (value+.01)/65535.0 if value>0 and value<65535 else float(value)/65535.0
		# Godot fronts are clockwise. Resolve authoring pieces consistently instead
		# of letting two-sided shading flip outward normals on reversed faces.
		for triangle in range(0,bucket.i.size(),3):
			var a: int = bucket.i[triangle]
			var b: int = bucket.i[triangle+1]
			var c: int = bucket.i[triangle+2]
			var cross: Vector3 = (bucket.v[b]-bucket.v[a]).cross(bucket.v[c]-bucket.v[a])
			if cross.dot(bucket.n[a]+bucket.n[b]+bucket.n[c])>0:
				bucket.i[triangle+1] = c
				bucket.i[triangle+2] = b
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = bucket.v
		arrays[Mesh.ARRAY_NORMAL] = bucket.n
		arrays[Mesh.ARRAY_TANGENT] = _tangent_frames(bucket)
		arrays[Mesh.ARRAY_TEX_UV] = bucket.uv
		arrays[Mesh.ARRAY_INDEX] = bucket.i
		arrays[Mesh.ARRAY_BONES] = bucket.b
		arrays[Mesh.ARRAY_WEIGHTS] = bucket.w
		var mesh := ArrayMesh.new()
		mesh.resource_name = "Gu_"+str(key)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		mesh.surface_set_material(0,materials[key])
		_attach_mesh(mesh,str(key))
		triangle_count += bucket.i.size()/3
	buckets.clear()

func _tangent_frames(bucket: Dictionary) -> PackedFloat32Array:
	# Accumulate UV derivatives, then orthogonalize against the sculpted normals.
	# Geometry pieces retain separate UV seam vertices and mirrored handedness.
	var along_u := PackedVector3Array()
	var along_v := PackedVector3Array()
	along_u.resize(bucket.v.size())
	along_v.resize(bucket.v.size())
	for triangle in range(0,bucket.i.size(),3):
		var a: int = bucket.i[triangle]
		var b: int = bucket.i[triangle+1]
		var c: int = bucket.i[triangle+2]
		var edge_u: Vector3 = bucket.v[b]-bucket.v[a]
		var edge_v: Vector3 = bucket.v[c]-bucket.v[a]
		var uv_u: Vector2 = bucket.uv[b]-bucket.uv[a]
		var uv_v: Vector2 = bucket.uv[c]-bucket.uv[a]
		var determinant := uv_u.x*uv_v.y-uv_u.y*uv_v.x
		if absf(determinant)<0.0000001:
			continue
		var tangent := (edge_u*uv_v.y-edge_v*uv_u.y)/determinant
		var bitangent := (edge_v*uv_u.x-edge_u*uv_v.x)/determinant
		for vertex: int in [a,b,c]:
			along_u[vertex] += tangent
			along_v[vertex] += bitangent
	var frames := PackedFloat32Array()
	for vertex in range(bucket.v.size()):
		var normal: Vector3 = bucket.n[vertex].normalized()
		var tangent := along_u[vertex]-normal*normal.dot(along_u[vertex])
		if tangent.length_squared()<0.00000001:
			tangent = Vector3.UP.cross(normal)
			if tangent.length_squared()<0.00000001:
				tangent = Vector3.RIGHT.cross(normal)
		tangent = tangent.normalized()
		var handedness := -1.0 if normal.cross(tangent).dot(along_v[vertex])<0 else 1.0
		frames.append_array(PackedFloat32Array([tangent.x,tangent.y,tangent.z,handedness]))
	return frames
