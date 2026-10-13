class_name GuConceptCharacterArt
extends RefCounted
## Approved concept pigment plus independent vector cloth on the live rig.
## UV/mask/asset coordinates are presentation data, never gameplay authority.

const MANIFEST_PATH := "res://assets/characters/concept-rig/manifest.json"
const SPEAR_TIP := Vector2(0,-46)
const SLEEVE_GRID := .80
const SLEEVE_BEND_LIMIT := .14
const SHADER := preload("res://assets/shaders/concept_cutout.gdshader")
static var _manifest: Dictionary = {}
static var _textures: Dictionary = {}
static var _geometry: Dictionary = {}
static var _materials: Dictionary = {}
static var _offsets: Dictionary = {}
static var _contours: Dictionary = {}
static var _owners: Dictionary = {}
static var _sleeve_edges: Dictionary = {}
static var _sleeve_paths: Dictionary = {}
static var _forearm_gaps: Dictionary = {}
static var _elbow_cuts: Dictionary = {}
static var _sleeve_palettes: Dictionary = {}
static var _pigments: Dictionary = {}
static var _body_edges: Dictionary = {}
static var _body_cores: Dictionary = {}
static var _modular_sleeves: Dictionary = {}

static func manifest() -> Dictionary:
	if _manifest.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
		if parsed is Dictionary:
			_manifest = parsed
	return _manifest

static func view_for(look: Dictionary, direction: int) -> Dictionary:
	return manifest().get("views", {}).get("%s_%d" % [look.get("body", "male"), direction], {})

static func material_for(look: Dictionary) -> ShaderMaterial:
	var outfit := str(look.get("outfit", "jade"))
	if not _materials.has(outfit):
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter("original_color",_texture("original"))
		material.set_shader_parameter("directions_color",_texture("directions"))
		material.set_shader_parameter("original_matte",load("res://assets/characters/concept-rig/character-concept-01-matte.res"))
		material.set_shader_parameter("directions_matte",load("res://assets/characters/concept-rig/character-directions-02-matte.res"))
		material.set_shader_parameter("original_layers",load("res://assets/characters/concept-rig/character-concept-01-layers.res"))
		material.set_shader_parameter("directions_layers",load("res://assets/characters/concept-rig/character-directions-02-layers.res"))
		material.set_shader_parameter("cloth_atlas",load("res://assets/characters/concept-rig/cloth-atlas.svg"))
		material.set_shader_parameter("directional_atlas",load("res://assets/characters/concept-rig/directional-atlas.svg"))
		material.set_shader_parameter("outfit_pigment", Color(GuIllustratedCharacterArt.OUTFIT_COLORS[outfit], 0.0 if outfit == "jade" else 1.0))
		_materials[outfit] = material
	return _materials[outfit]

static func _texture(source: String) -> Texture2D:
	if not _textures.has(source):
		_textures[source] = load(str(manifest()["sources"][source]["path"])) as Texture2D
	return _textures[source]

static func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

static func source_position(view: Dictionary, value: Array) -> Vector2:
	return (_point(value) - _point(view["ground"])) * float(view["scale"])

static func joint_offsets(look: Dictionary, direction: int) -> Dictionary:
	var cache_key := "%s_%d" % [look["body"],direction]
	if _offsets.has(cache_key):
		return _offsets[cache_key]
	var view := view_for(look,direction)
	var rest := GuIllustratedCharacterArt.sample("idle",0.0,direction,look,true)
	var offsets := {}
	for key in ["head","torso"]:
		offsets[key] = source_position(view,view["parts"][key]["pivot"])-Vector2(rest[key])
	for side in ["L","R"]:
		var rest_leg := GuIllustratedCharacterArt.leg_joints(rest,side)
		for prefix in ["arm_","leg_"]:
			var key: String = prefix+side
			offsets[key] = []
			for i in range(3):
				var rig_joint: Vector2 = rest["arm_"+side][i] if prefix=="arm_" else rest_leg[i]
				offsets[key].append(source_position(view,view["parts"][key]["joints"][i])-rig_joint)
	_offsets[cache_key] = offsets
	return offsets

static func weapon_tip(snapshot: Dictionary) -> Vector2:
	var factor := float(snapshot["scale"])
	if str(snapshot["appearance"]["weapon"])=="spear":
		return hand_position(snapshot)+SPEAR_TIP.rotated(float(snapshot.get("source_pose",snapshot["pose"])["weapon_angle"]))*factor
	var weapon: Dictionary = manifest()["sword"]
	var view := view_for(snapshot["appearance"],int(snapshot["direction_index"]))
	var transform := sword_attachment(snapshot)
	var mirror: float = transform["mirror"]
	var local := (_point(weapon["tip"])-_point(weapon["pivot"]))*float(weapon["scale"])*Vector2(mirror,1)
	return hand_position(snapshot)+local.rotated(float(transform["angle"]))*factor

static func sword_attachment(snapshot: Dictionary) -> Dictionary:
	var view := view_for(snapshot["appearance"],int(snapshot["direction_index"]))
	var rest := GuIllustratedCharacterArt.sample("idle",0,int(snapshot["direction_index"]),snapshot["appearance"],true)
	var source_hand := source_position(view,view["parts"]["arm_R"]["joints"][2])
	var mirror := -1.0 if source_hand.x>0 else 1.0
	return {"grip":hand_position(snapshot),"mirror":mirror,"angle":(float(snapshot.get("source_pose",snapshot["pose"])["weapon_angle"])-float(rest["weapon_angle"]))*mirror}

static func blend_offsets(previous: Dictionary, target: Dictionary, weight: float) -> Dictionary:
	var result := target.duplicate(true)
	for key: String in target:
		if not previous.has(key):
			continue
		if target[key] is Vector2:
			result[key] = Vector2(previous[key]).lerp(target[key],weight)
		else:
			for i in range(target[key].size()):
				result[key][i] = Vector2(previous[key][i]).lerp(target[key][i],weight)
	return result

static func hand_position(snapshot: Dictionary, side: String = "R") -> Vector2:
	if snapshot.has("source_pose"):
		var pose: Dictionary = snapshot["source_pose"]
		return Vector2(pose.get("grip_"+side,pose["arm_"+side][2]))*float(snapshot["scale"])
	var view := view_for(snapshot["appearance"], int(snapshot["direction_index"]))
	if view.is_empty():
		return Vector2(snapshot["pose"]["arm_"+side][2]) * float(snapshot["scale"])
	var offsets: Dictionary = snapshot.get("source_offsets",joint_offsets(snapshot["appearance"],int(snapshot["direction_index"])))
	return (Vector2(snapshot["pose"]["arm_"+side][2])+Vector2(offsets["arm_"+side][2]))*float(snapshot["scale"])

static func _triangles(key: String, polygon: Array) -> Dictionary:
	if not _geometry.has(key):
		var vertices := PackedVector2Array()
		for point: Array in polygon:
			vertices.append(_point(point))
		_geometry[key] = {"vertices": vertices, "triangles": Geometry2D.triangulate_polygon(vertices)}
	return _geometry[key]

static func _part_geometry(view: Dictionary, key: String) -> Dictionary:
	var cache_key := str(view["source"])+str(view["ground"])+key
	var base := _triangles(cache_key,view["parts"][key].get("render_polygon",view["parts"][key]["polygon"]))
	if key=="head" or key.begins_with("leg_"):
		return base
	var mesh_key := cache_key+"_mesh"
	if not _geometry.has(mesh_key):
		if key=="torso":
			_geometry[mesh_key]=_cloth_geometry(view,base)
			return _geometry[mesh_key]
		var combined := {"vertices":PackedVector2Array(),"triangles":PackedInt32Array(),"bones":PackedInt32Array()}
		for contour in source_contours(view,key):
			var pixels := PackedVector2Array()
			for point in contour: pixels.append(point/float(view["scale"])+_point(view["ground"]))
			var piece := _sleeve_geometry(view,key,{"vertices":pixels})
			var start: int = combined["vertices"].size()
			combined["vertices"].append_array(piece["vertices"])
			combined["bones"].append_array(piece["bones"])
			for index: int in piece["triangles"]: combined["triangles"].append(start+index)
		if combined["vertices"].is_empty(): combined=_sleeve_geometry(view,key,base)
		_cache_sleeve_bindings(view,GuConceptCharacterRig._joint_list(view,key),combined)
		_geometry[mesh_key]=combined
	return _geometry[mesh_key]

static func _sleeve_geometry(view: Dictionary, key: String, base: Dictionary) -> Dictionary:
	# The upper cloth uses a triangular deformation lattice. Clip the UV
	# outline into its cells so every triangle receives one affine map;
	# long thin source triangles cannot flip across a curved bend. The
	# bracer and palm remain independent rigid regions.
	var joints: Array = view["parts"][key]["joints"]
	var elbow := _point(joints[1])
	var axis := (_point(joints[2])-_point(joints[0])).normalized()
	var source := GuConceptCharacterRig._joint_list(view,key)
	var wrist := GuConceptCharacterRig.source_wrist(source)/float(view["scale"])+_point(view["ground"])
	var wrist_axis := (_point(joints[2])-_point(joints[1])).normalized()
	var polygon: PackedVector2Array = base["vertices"]
	var extent := 1.0
	for point in polygon: extent=maxf(extent,point.distance_to(elbow)+1)
	# Keep the original landmark indices for rig diagnostics, while the
	# triangulated render boundary now includes the entire painted stitch.
	var vertices := PackedVector2Array()
	for point: Array in view["parts"][key]["polygon"]: vertices.append(_point(point))
	var bones := PackedInt32Array()
	for point in vertices: bones.append(0 if (point-elbow).dot(axis)<=0 else 2 if (point-wrist).dot(wrist_axis)>=0 else 1)
	var indices := PackedInt32Array()
	for bone in range(3):
		var regions := Geometry2D.intersect_polygons(polygon,_half_plane(elbow,axis*(-1 if bone==0 else 1),extent))
		if bone>0:
			var clipped: Array[PackedVector2Array] = []
			for region: PackedVector2Array in regions:
				clipped.append_array(Geometry2D.intersect_polygons(region,_half_plane(wrist,wrist_axis*(-1 if bone==1 else 1),extent*2)))
			regions=clipped
		else:
			var clipped: Array[PackedVector2Array] = []
			for region: PackedVector2Array in regions:
				clipped.append_array(_sleeve_lattice_regions(view,source,region))
			regions=clipped
		var lookup := {}
		for i in range(vertices.size()):
			if bones[i]==bone: lookup[vertices[i].snapped(Vector2.ONE*.0001)]=i
		for region: PackedVector2Array in regions:
			var mapping := PackedInt32Array()
			for point in region:
				var id := point.snapped(Vector2.ONE*.0001)
				if not lookup.has(id):
					lookup[id]=vertices.size()
					vertices.append(point)
					bones.append(bone)
				mapping.append(lookup[id])
			var triangles := Geometry2D.triangulate_polygon(region)
			for i in range(0,triangles.size(),3):
				var a := mapping[triangles[i]]
				var b := mapping[triangles[i+1]]
				var c := mapping[triangles[i+2]]
				if absf((vertices[b]-vertices[a]).cross(vertices[c]-vertices[a]))>.0001:
					indices.append_array(PackedInt32Array([a,b,c]))
	# Refine only the rigid forearm and hand; cloth already has short cells.
	for subdivision in range(2):
		var edges := {}
		var next := PackedInt32Array()
		for i in range(0,indices.size(),3):
			var triangle := [indices[i],indices[i+1],indices[i+2]]
			if bones[triangle[0]]==0:
				next.append_array(PackedInt32Array(triangle))
				continue
			var midpoints: Array[int] = []
			for edge in range(3):
				var a: int = triangle[edge]
				var b: int = triangle[(edge+1)%3]
				var edge_key := Vector2i(mini(a,b),maxi(a,b))
				if not edges.has(edge_key):
					edges[edge_key]=vertices.size()
					vertices.append((vertices[a]+vertices[b])*.5)
					bones.append(bones[a])
				midpoints.append(edges[edge_key])
			next.append_array(PackedInt32Array([triangle[0],midpoints[0],midpoints[2],midpoints[0],triangle[1],midpoints[1],midpoints[2],midpoints[1],triangle[2],midpoints[0],midpoints[1],midpoints[2]]))
		indices=next
	var geometry := {"vertices":vertices,"triangles":indices,"bones":bones}
	_cache_sleeve_bindings(view,source,geometry)
	return geometry

static func _cache_sleeve_bindings(view: Dictionary, source: PackedVector2Array, geometry: Dictionary) -> void:
	# Bind source vertices once. Runtime evaluates lattice corners once per
	# pose, then only three weighted points per cloth vertex, without repeated
	# cell searches, trigonometry or dictionary allocations in the mesh loop.
	var axis := (source[2]-source[0]).normalized()
	var normal := Vector2(-axis.y,axis.x)
	var native := PackedVector2Array()
	var corners := PackedVector2Array()
	var bends := PackedFloat32Array()
	var ids := PackedInt32Array()
	var weights := PackedVector3Array()
	var lookup := {}
	for point in geometry["vertices"]:
		var at := source_position(view,[point.x,point.y])
		native.append(at)
		if int(geometry["bones"][native.size()-1])!=0:
			ids.append_array(PackedInt32Array([-1,-1,-1]))
			weights.append(Vector3.ZERO)
			continue
		var grid := Vector2((at-source[1]).dot(normal),(at-source[1]).dot(axis))/SLEEVE_GRID
		var cell := Vector2i(floori(grid.x),floori(grid.y))
		var uv := grid-Vector2(cell)
		var vertices := [cell,cell+Vector2i.RIGHT,cell+Vector2i.DOWN] if uv.x+uv.y<=1 else [cell+Vector2i.ONE,cell+Vector2i.DOWN,cell+Vector2i.RIGHT]
		weights.append(Vector3(1-uv.x-uv.y,uv.x,uv.y) if uv.x+uv.y<=1 else Vector3(uv.x+uv.y-1,1-uv.x,1-uv.y))
		for vertex: Vector2i in vertices:
			if not lookup.has(vertex):
				lookup[vertex]=corners.size()
				var local := (normal*vertex.x+axis*vertex.y)*SLEEVE_GRID
				corners.append(local)
				bends.append(smoothstep(-minf(3.2,source[0].distance_to(source[1])*.48),0,local.dot(axis)))
			ids.append(lookup[vertex])
	geometry["native"]=native
	geometry["cloth_corners"]=corners
	geometry["cloth_bends"]=bends
	geometry["cloth_ids"]=ids
	geometry["cloth_weights"]=weights

static func _sleeve_lattice_regions(view: Dictionary, source: PackedVector2Array, region: PackedVector2Array) -> Array[PackedVector2Array]:
	var axis := (source[2]-source[0]).normalized()
	var normal := Vector2(-axis.y,axis.x)
	var local := PackedVector2Array()
	for point in region:
		var at := source_position(view,[point.x,point.y])-source[1]
		local.append(Vector2(at.dot(normal),at.dot(axis))/SLEEVE_GRID)
	var bounds := Rect2(local[0],Vector2.ZERO)
	for at in local: bounds=bounds.expand(at)
	var result: Array[PackedVector2Array] = []
	for y in range(floori(bounds.position.y),ceili(bounds.end.y)):
		for x in range(floori(bounds.position.x),ceili(bounds.end.x)):
			var at := Vector2(x,y)
			for cell in [PackedVector2Array([at,at+Vector2.RIGHT,at+Vector2.DOWN]),PackedVector2Array([at+Vector2.ONE,at+Vector2.DOWN,at+Vector2.RIGHT])]:
				for polygon in Geometry2D.intersect_polygons(local,cell):
					var pixels := PackedVector2Array()
					for point in polygon:
						pixels.append((source[1]+(normal*point.x+axis*point.y)*SLEEVE_GRID)/float(view["scale"])+_point(view["ground"]))
					result.append(pixels)
	return result

static func _half_plane(pivot: Vector2, axis: Vector2, extent: float) -> PackedVector2Array:
	var normal := Vector2(-axis.y,axis.x)
	return PackedVector2Array([pivot-normal*extent,pivot+normal*extent,pivot+normal*extent+axis*extent,pivot-normal*extent+axis*extent])

static func _cloth_geometry(view: Dictionary, base: Dictionary) -> Dictionary:
	# Long boundary slivers from a polygon fan can invert under curved shear.
	# Clip the source outline into short, shared strips aligned with the belt
	# and cloth response. Each neutral vertex still has its exact source UV.
	var polygon: PackedVector2Array = base["vertices"]
	var vertices := polygon.duplicate()
	var indices := PackedInt32Array()
	var lookup := {}
	for i in range(vertices.size()): lookup[vertices[i].snapped(Vector2.ONE*.0001)]=i
	var bounds := Rect2(polygon[0],Vector2.ZERO)
	for point in polygon: bounds=bounds.expand(point)
	var pivot := _point(view["parts"]["torso"]["pivot"])
	var span := 3.0/float(view["scale"])
	var origin := pivot+Vector2(-12,3)/float(view["scale"])
	var first := Vector2i(floori((bounds.position.x-origin.x)/span),floori((bounds.position.y-origin.y)/span))
	var last := Vector2i(ceili((bounds.end.x-origin.x)/span),ceili((bounds.end.y-origin.y)/span))
	var columns: Array[float] = []
	for x in range(first.x,last.x+1): columns.append(origin.x+x*span)
	for side in ["L","R"]:
		var hip_x: float = view["parts"]["leg_"+side]["joints"][0][0]
		if hip_x>columns[0] and hip_x<columns[-1]: columns.append(hip_x)
	columns.sort()
	for y in range(first.y,last.y):
		for x in range(columns.size()-1):
			var width := columns[x+1]-columns[x]
			if width<.0001: continue
			var a := Vector2(columns[x],origin.y+y*span)
			var pieces: Array[PackedVector2Array] = []
			# Match coat_vertex's triangular lattice, including hip clamp cuts.
			# Each curved hem sliver then receives one affine deformation.
			for triangle in [PackedVector2Array([a,a+Vector2(width,0),a+Vector2(0,span)]),PackedVector2Array([a+Vector2(width,span),a+Vector2(0,span),a+Vector2(width,0)])]:
				pieces.append_array(Geometry2D.intersect_polygons(polygon,triangle))
			for cell: PackedVector2Array in pieces:
				var local_indices := Geometry2D.triangulate_polygon(cell)
				var mapping := PackedInt32Array()
				for point in cell:
					var lookup_key := point.snapped(Vector2.ONE*.0001)
					if not lookup.has(lookup_key):
						lookup[lookup_key]=vertices.size()
						vertices.append(point)
					mapping.append(lookup[lookup_key])
				for i in range(0,local_indices.size(),3):
					var ia := mapping[local_indices[i]]
					var ib := mapping[local_indices[i+1]]
					var ic := mapping[local_indices[i+2]]
					# Collinear traced rows can create microscopic slivers. Cull
					# them before submission, rather than allowing float32 collapse
					# after a torso transform (0.01 source px² is subpixel at native).
					if absf((vertices[ib]-vertices[ia]).cross(vertices[ic]-vertices[ia]))>.01:
						indices.append_array(PackedInt32Array([ia,ib,ic]))
	return {"vertices":vertices,"triangles":indices}

static func _coat_fields(pose: Dictionary, view: Dictionary) -> Dictionary:
	var left := GuConceptCharacterRig._joint_list(view,"leg_L")
	var right := GuConceptCharacterRig._joint_list(view,"leg_R")
	var origin := Vector2(pose["rest_torso"])
	return {"left":left[0].x-origin.x,"right":right[0].x-origin.x,
		"stride_L":clampf((Vector2(pose["leg_L"][2])-GuConceptCharacterRig.body_point(pose,left[2])).x*.18,-1.4,1.4),
		"stride_R":clampf((Vector2(pose["leg_R"][2])-GuConceptCharacterRig.body_point(pose,right[2])).x*.18,-1.4,1.4),
		"lift_L":float(pose["cloth_lift_L"]),"lift_R":float(pose["cloth_lift_R"]),"sway":float(pose["cloth_sway"])}

static func coat_vertex(pose: Dictionary, point: Vector2, view: Dictionary = {}, fields: Dictionary = {}) -> Vector2:
	if point.y<=3: return point
	var section := clampf((point.y-3)/3,0,4)
	var row := floorf(section)
	var weight := lerpf(smoothstep(0,4,row),smoothstep(0,4,minf(row+1,4)),section-row)
	if view.is_empty():
		var u := clampf((point.x+12)/24,0,1)
		if Vector2(pose["leg_forward"]).y<0: u=1-u
		return point+Vector2(float(pose["cloth_sway"])*weight,-lerpf(float(pose["cloth_lift_L"]),float(pose["cloth_lift_R"]),u)*weight)
	var field := fields if not fields.is_empty() else _coat_fields(pose,view)
	var x0 := -12+floorf((point.x+12)/3)*3
	var x1 := x0+3
	for hip: float in [field["left"],field["right"]]:
		if hip<=point.x: x0=maxf(x0,hip)
		else: x1=minf(x1,hip)
	var tx := clampf((point.x-x0)/(x1-x0),0,1)
	var ty := section-row
	var u0 := clampf((x0-float(field["left"]))/(float(field["right"])-float(field["left"])),0,1)
	var u1 := clampf((x1-float(field["left"]))/(float(field["right"])-float(field["left"])),0,1)
	var w0 := smoothstep(0,4,row)
	var w1 := smoothstep(0,4,minf(row+1,4))
	var weighted_u := u0*w0*(1-tx-ty)+u1*w0*tx+u0*w1*ty if tx+ty<=1 else u1*w1*(tx+ty-1)+u0*w1*(1-tx)+u1*w0*(1-ty)
	return point+Vector2((float(field["sway"])+float(field["stride_L"]))*weight+(float(field["stride_R"])-float(field["stride_L"]))*weighted_u,-float(field["lift_L"])*weight-(float(field["lift_R"])-float(field["lift_L"]))*weighted_u)

static func part_indices(view: Dictionary, key: String) -> PackedInt32Array:
	return _part_geometry(view,key)["triangles"]

static func arm_vertex(point: Vector2, source: PackedVector2Array, posed: PackedVector2Array, bone: int) -> Vector2:
	var original := source[bone+1]-source[bone]
	var target := posed[bone+1]-posed[bone]
	return posed[bone]+(point-source[bone]).rotated(original.angle_to(target))

static func arm_point(point: Vector2, source: PackedVector2Array, pose: Dictionary, key: String, bone: int) -> Vector2:
	if bone==2:
		return GuConceptCharacterRig.hand_vertex(point,source,pose[key],float(pose.get("hand_rotation_"+key.right(1),0)))
	return sleeve_point(point,source,pose[key],bone,sleeve_deformation(source,pose[key]))

static func sleeve_deformation(source: PackedVector2Array, chain: PackedVector2Array) -> Dictionary:
	var upper := (source[1]-source[0]).angle_to(chain[1]-chain[0])
	var lower := (source[2]-source[1]).angle_to(chain[2]-chain[1])
	var turn := wrapf(lower-upper,-PI,PI)
	# Cloth shares a little of the forearm's turn near the elbow. A smooth
	# bound avoids a velocity kink when flexion passes the soft bend limit.
	# Keep the bracer, fingers and source bone lengths rigid.
	return {"upper":upper,"lower":lower,"turn":turn,
		"upper_bend":SLEEVE_BEND_LIMIT*tanh(turn/(SLEEVE_BEND_LIMIT*2)),
		"upper_span":minf(3.2,source[0].distance_to(source[1])*.48),
		"guides":GuConceptClothGuides.sample(source,chain),"lattice":{}}

static func sleeve_point(point: Vector2, source: PackedVector2Array, chain: PackedVector2Array, bone: int, deformation: Dictionary) -> Vector2:
	if bone!=0: return arm_vertex(point,source,chain,bone)
	var local := point-source[1]
	var axis := (source[2]-source[0]).normalized()
	var normal := Vector2(-axis.y,axis.x)
	var grid := Vector2(local.dot(normal),local.dot(axis))/SLEEVE_GRID
	var cell := Vector2i(floori(grid.x),floori(grid.y))
	var uv := grid-Vector2(cell)
	var corners := [cell,cell+Vector2i.RIGHT,cell+Vector2i.DOWN] if uv.x+uv.y<=1 else [cell+Vector2i.ONE,cell+Vector2i.DOWN,cell+Vector2i.RIGHT]
	var weights := Vector3(1-uv.x-uv.y,uv.x,uv.y) if uv.x+uv.y<=1 else Vector3(uv.x+uv.y-1,1-uv.x,1-uv.y)
	var result := Vector2.ZERO
	for i in range(3):
		var corner: Vector2i = corners[i]
		if not deformation["lattice"].has(corner):
			var native := (normal*corner.x+axis*corner.y)*SLEEVE_GRID
			var weight := smoothstep(-float(deformation["upper_span"]),0,native.dot(axis))
			var angle := float(deformation["upper"])+float(deformation["upper_bend"])*weight
			deformation["lattice"][corner]=chain[1]+native.rotated(angle)+GuConceptClothGuides.offset_at(source[1]+native,source,chain,deformation["guides"])
		result+=Vector2(deformation["lattice"][corner])*weights[i]
	return result

static func source_contours(view: Dictionary, key: String) -> Array[PackedVector2Array]:
	if _contours.is_empty():
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(manifest()["contours"])))
		for view_key: String in data["views"]:
			var reference: Dictionary = manifest()["views"][view_key]
			var parts := {}
			for part_key: String in data["views"][view_key]:
				var paths: Array[PackedVector2Array] = []
				for path: Array in data["views"][view_key][part_key]:
					var points := PackedVector2Array()
					for point: Array in path: points.append(source_position(reference,point))
					paths.append(points)
				parts[part_key]=paths
			_contours[str(reference["source"])+str(reference["ground"])]=parts
	return _contours[str(view["source"])+str(view["ground"])][key]

static func _part_point(view: Dictionary, key: String, pose: Dictionary, native: Vector2, joints: PackedVector2Array, bone: int=0) -> Vector2:
	var pivot := source_position(view,view["parts"][key]["pivot"])
	if key=="head":
		return Vector2(pose["head"])+(native-pivot).rotated(float(pose["head_rotation"]))
	if key=="torso":
		return Vector2(pose["torso"])+coat_vertex(pose,native-pivot,view).rotated(float(pose["torso_rotation"]))
	if key.begins_with("leg_"):
		return Vector2(pose[key][2])+(native-joints[2]).rotated(float(pose["foot_rotation_"+key.right(1)]))
	return arm_point(native,joints,pose,key,bone)

static func outline_paths(view: Dictionary, key: String, pose: Dictionary) -> Array[PackedVector2Array]:
	if key.begins_with("arm_"): return _sleeve_outline_paths(view,key,pose,-1,false)
	var paths: Array[PackedVector2Array] = []
	var joints := GuConceptCharacterRig._joint_list(view,key) if key.begins_with("leg_") else PackedVector2Array()
	var contours := _body_source_edges(view) if key=="torso" else source_contours(view,key)
	for contour in contours:
		var line := PackedVector2Array()
		var count := contour.size() if key=="torso" else contour.size()+1
		for i in range(count): line.append(_part_point(view,key,pose,contour[i%contour.size()],joints))
		if line.size()>=2: paths.append(line)
	return paths

static func _draw_outline(canvas: CanvasItem, view: Dictionary, key: String, pose: Dictionary, offset: Vector2, factor: float, tint: Color, bone_filter: int = -1) -> void:
	var width := .48 if key=="head" else .52 if key.begins_with("leg_") else .50
	var paths := _sleeve_outline_paths(view,key,pose,bone_filter) if key.begins_with("arm_") else outline_paths(view,key,pose)
	for path in paths:
		var points := PackedVector2Array()
		for point in path: points.append(offset+point*factor)
		GuConceptInkStroke.draw(canvas,points,width*factor,Color("332c24")*tint)

static func _sleeve_source_edges(view: Dictionary, key: String) -> Array[PackedVector2Array]:
	# Owner boundaries against the coat/neck are cuts for compositing, not
	# additional ink contours. Outlining them made detached sleeve stripes.
	var cache_key := str(view["source"])+str(view["ground"])+key
	if _sleeve_edges.has(cache_key): return _sleeve_edges[cache_key]
	var source := str(view["source"])
	if not _owners.has(source):
		var name := "character-concept-01" if source=="original" else "character-directions-02"
		_owners[source]=(load("res://assets/characters/concept-rig/%s-layers.res" % name) as Texture2D).get_image()
	var owners: Image = _owners[source]
	var paths: Array[PackedVector2Array] = []
	for contour in source_contours(view,key):
		var line := PackedVector2Array()
		for i in range(contour.size()):
			var a := contour[i]
			var b := contour[(i+1)%contour.size()]
			var center := (a+b)*.5/float(view["scale"])+_point(view["ground"])
			var normal := Vector2(-(b-a).y,(b-a).x).normalized()
			var shared := false
			for distance in [-2.0,0.0,2.0]:
				var pixel := Vector2i(center+normal*distance)
				if pixel.x<0 or pixel.y<0 or pixel.x>=owners.get_width() or pixel.y>=owners.get_height(): continue
				var owner := roundi(owners.get_pixelv(pixel).r*255)
				shared=shared or owner in [32,64]
			if shared:
				if line.size()>1: paths.append(line)
				line=PackedVector2Array()
			else:
				if line.is_empty(): line.append(a)
				line.append(b)
		if line.size()>1: paths.append(line)
	_sleeve_edges[cache_key]=paths
	return paths

static func _sleeve_outline_paths(view: Dictionary, key: String, pose: Dictionary, bone_filter: int = -1, ownership_edges: bool = true) -> Array[PackedVector2Array]:
	var paths: Array[PackedVector2Array] = []
	var joints := GuConceptCharacterRig._joint_list(view,key)
	var deformation := sleeve_deformation(joints,pose[key])
	for path in _source_sleeve_paths(view,key,ownership_edges):
		var bone := int(path["bone"])
		if not (bone_filter<0 or bone_filter==bone or (bone_filter==1 and bone==2)): continue
		var line := PackedVector2Array()
		for point in path["points"]:
			line.append(arm_point(point,joints,pose,key,bone) if bone==2 else sleeve_point(point,joints,pose[key],bone,deformation))
		paths.append(line)
	return paths

static func _source_sleeve_paths(view: Dictionary, key: String, ownership_edges: bool) -> Array[Dictionary]:
	var cache_key := str(view["source"])+str(view["ground"])+key+str(ownership_edges)
	if _sleeve_paths.has(cache_key): return _sleeve_paths[cache_key]
	var paths: Array[Dictionary] = []
	var joints := GuConceptCharacterRig._joint_list(view,key)
	var axis := (joints[2]-joints[0]).normalized()
	var wrist := GuConceptCharacterRig.source_wrist(joints)
	var wrist_axis := (joints[2]-joints[1]).normalized()
	var normal := Vector2(-axis.y,axis.x)
	var edges := _sleeve_source_edges(view,key) if ownership_edges else source_contours(view,key)
	for source_edge in edges:
		var edge := source_edge.duplicate()
		if not ownership_edges: edge.append(edge[0])
		var line := PackedVector2Array()
		var current_bone := -1
		for i in range(1,edge.size()):
			var previous := edge[i-1]
			var point := edge[i]
			var cuts: Array[float] = [0.0,1.0]
			for plane in [[joints[1],axis],[wrist,wrist_axis]]:
				var first := (previous-Vector2(plane[0])).dot(Vector2(plane[1]))
				var last := (point-Vector2(plane[0])).dot(Vector2(plane[1]))
				if first*last<0: cuts.append(-first/(last-first))
			# Split ink at exactly the same triangular lattice edges as UVs.
			# A long contour chord must not cut across a curved cloth cell.
			var from := Vector2((previous-joints[1]).dot(normal),(previous-joints[1]).dot(axis))/SLEEVE_GRID
			var to := Vector2((point-joints[1]).dot(normal),(point-joints[1]).dot(axis))/SLEEVE_GRID
			for distances in [Vector2(from.x,to.x),Vector2(from.y,to.y),Vector2(from.x+from.y,to.x+to.y)]:
				if absf(distances.y-distances.x)<.00001: continue
				for grid_line in range(floori(minf(distances.x,distances.y))+1,ceili(maxf(distances.x,distances.y))):
					cuts.append((grid_line-distances.x)/(distances.y-distances.x))
			cuts.sort()
			for segment in range(cuts.size()-1):
				var a := previous.lerp(point,cuts[segment])
				var b := previous.lerp(point,cuts[segment+1])
				if a.distance_squared_to(b)<.00000001: continue
				var center := (a+b)*.5
				var bone := 0 if (center-joints[1]).dot(axis)<=0 else 2 if (center-wrist).dot(wrist_axis)>=0 else 1
				if bone!=current_bone:
					if line.size()>1: paths.append({"bone":current_bone,"points":line})
					line=PackedVector2Array()
				if line.is_empty(): line.append(a)
				line.append(b)
				current_bone=bone
		if line.size()>1: paths.append({"bone":current_bone,"points":line})
	_sleeve_paths[cache_key]=paths
	return paths

static func arm_bone_indices(view: Dictionary, key: String, bone: int) -> PackedInt32Array:
	var geometry := _part_geometry(view,key)
	var cache_key := "bone_indices_%d" % bone
	if geometry.has(cache_key): return geometry[cache_key]
	var all_indices: PackedInt32Array = geometry["triangles"]
	var result := PackedInt32Array()
	for i in range(0,all_indices.size(),3):
		var region := int(geometry["bones"][all_indices[i]])
		# Rear depth pass 1 includes both forearm and its attached palm.
		if region==bone or (bone==1 and region==2):
			result.append_array(PackedInt32Array([all_indices[i],all_indices[i+1],all_indices[i+2]]))
	geometry[cache_key]=result
	return result

static func part_vertices(view: Dictionary, key: String, pose: Dictionary) -> PackedVector2Array:
	var part: Dictionary = view["parts"][key]
	var geometry := _part_geometry(view,key)
	var original: PackedVector2Array = geometry["vertices"]
	var vertices := PackedVector2Array()
	var pivot := source_position(view,part["pivot"])
	var source_joints := PackedVector2Array()
	var posed_joints := PackedVector2Array()
	if key.begins_with("arm_") or key.begins_with("leg_"):
		for i in range(3):
			source_joints.append(source_position(view,part["joints"][i]))
			posed_joints.append(pose[key][i])
	var sleeve := sleeve_deformation(source_joints,posed_joints) if key.begins_with("arm_") else {}
	var coat_fields := _coat_fields(pose,view) if key=="torso" else {}
	var cloth_targets := PackedVector2Array()
	if key.begins_with("arm_"):
		for i in range(geometry["cloth_corners"].size()):
			var corner: Vector2 = geometry["cloth_corners"][i]
			cloth_targets.append(posed_joints[1]+corner.rotated(float(sleeve["upper"])+float(sleeve["upper_bend"])*float(geometry["cloth_bends"][i]))+GuConceptClothGuides.offset_at(source_joints[1]+corner,source_joints,posed_joints,sleeve["guides"]))
	for i in range(original.size()):
		var point := original[i]
		var native: Vector2 = geometry["native"][i] if key.begins_with("arm_") else (point-_point(view["ground"]))*float(view["scale"])
		var transformed := native
		if key=="head":
			transformed = Vector2(pose["head"])+(native-pivot).rotated(float(pose["head_rotation"]))
		elif key=="torso":
			var local := native-pivot
			local = coat_vertex(pose,local,view,coat_fields)
			transformed = Vector2(pose["torso"])+local.rotated(float(pose["torso_rotation"]))
		elif key.begins_with("leg_"):
			# The boot retains its painted dimensions. A textured pants bridge
			# supplies the hidden anatomy between hip and boot, never stretch it.
			transformed = posed_joints[2]+(native-source_joints[2]).rotated(float(pose["foot_rotation_"+key.right(1)]))
		else:
			var bone := int(geometry["bones"][i])
			if bone==0:
				var ids: PackedInt32Array = geometry["cloth_ids"]
				var weights: Vector3 = geometry["cloth_weights"][i]
				transformed=cloth_targets[ids[i*3]]*weights.x+cloth_targets[ids[i*3+1]]*weights.y+cloth_targets[ids[i*3+2]]*weights.z
			else:
				transformed = arm_point(native,source_joints,pose,key,bone) if bone==2 else arm_vertex(native,source_joints,posed_joints,bone)
		vertices.append(transformed)
	return vertices

static func _draw_part(canvas: CanvasItem, view: Dictionary, key: String, pose: Dictionary, offset: Vector2, factor: float, tint: Color, bone_filter: int = -1) -> void:
	var geometry := _part_geometry(view,key)
	var texture := _texture(str(view["source"]))
	var source_size := Vector2(texture.get_size())
	var vertices := part_vertices(view,key,pose)
	var uvs := PackedVector2Array()
	var layer_page := Vector2(float(manifest()["layer_ids"][key])*2,0)
	for i in range(vertices.size()):
		vertices[i] = offset+vertices[i]*factor
		uvs.append(Vector2(geometry["vertices"][i])/source_size+layer_page)
	var color := tint
	if key.begins_with("leg_") and snapshot_boots(pose)=="leather":
		color *= Color(1.12,0.94,0.78)
	# Submit the subdivided part once, rather than hundreds of per-triangle
	# canvas commands. Hold meshes for this canvas's complete draw frame,
	# including several afterimage poses drawn by a shared VFX canvas.
	var frame := Engine.get_process_frames()
	if int(canvas.get_meta("concept_mesh_frame",-1))!=frame:
		canvas.set_meta("concept_mesh_frame",frame)
		canvas.set_meta("concept_draw_meshes",[])
	var colors := PackedColorArray()
	colors.resize(vertices.size())
	colors.fill(color)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_COLOR]=colors
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=geometry["triangles"] if bone_filter<0 else arm_bone_indices(view,key,bone_filter)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	canvas.get_meta("concept_draw_meshes").append(mesh)
	canvas.draw_mesh(mesh,texture)
	_draw_outline(canvas,view,key,pose,offset,factor,tint,bone_filter)

static func _body_source_edges(view: Dictionary) -> Array[PackedVector2Array]:
	var cache_key := str(view["source"])+str(view["ground"])
	if _body_edges.has(cache_key): return _body_edges[cache_key]
	var paths: Array[PackedVector2Array] = []
	# Outline the completed coat once. The torso ownership contour also
	# contains the removed standing arms/hands; stroking those interior cuts
	# painted a black sleeve-shaped hole even after the arm moved away.
	for contour in source_contours(view,"body_core"):
		var line := contour.duplicate()
		line.append(contour[0])
		paths.append(line)
	_body_edges[cache_key]=paths
	return paths

static func _body_core_geometry(view: Dictionary) -> Dictionary:
	var cache_key := str(view["source"])+str(view["ground"])
	if _body_cores.has(cache_key): return _body_cores[cache_key]
	var geometry := {"vertices":PackedVector2Array(),"triangles":PackedInt32Array()}
	for contour in source_contours(view,"body_core"):
		var polygon := PackedVector2Array()
		for point in contour: polygon.append(point/float(view["scale"])+_point(view["ground"]))
		var piece := _cloth_geometry(view,{"vertices":polygon})
		var first: int = geometry["vertices"].size()
		geometry["vertices"].append_array(piece["vertices"])
		for index: int in piece["triangles"]: geometry["triangles"].append(first+index)
	if view.has("modular_art"):
		geometry["colors"]=PackedColorArray()
		geometry["colors"].resize(geometry["vertices"].size())
		geometry["colors"].fill(Color.WHITE)
		_body_cores[cache_key]=geometry
		return geometry
	var texture := _texture(str(view["source"]))
	var source := texture.get_image()
	if source.is_compressed(): source.decompress()
	var name := "character-concept-01" if view["source"]=="original" else "character-directions-02"
	var owners := (load("res://assets/characters/concept-rig/%s-layers.res" % name) as Texture2D).get_image()
	var colors := PackedColorArray()
	var rows := {}
	for point: Vector2 in geometry["vertices"]:
		var row := roundi(point.y)
		if not rows.has(row):
			var sum := Vector3.ZERO
			var count := 0
			# Recover only hidden green cloth; collar, belt, skin and old sleeve
			# ink never become a second detail on the chest. Sample the same
			# view's wash, keeping the underpaint quiet under moving appendages.
			for y in range(row-3,row+4):
				for x in range(int(view["ground"][0])-35,int(view["ground"][0])+36):
					if owners.get_pixel(x,y).r*255<63.5 or owners.get_pixel(x,y).r*255>64.5: continue
					var color := source.get_pixel(x,y)
					if color.g-color.r<.008 or color.g-color.b<.025 or color.g<.24: continue
					sum+=Vector3(color.r,color.g,color.b)
					count+=1
			rows[row]=Color(sum.x/count,sum.y/count,sum.z/count) if count>0 else sleeve_pigment(view,"arm_L")
		colors.append(rows[row])
	# A standing sleeve/palm also hides the waist strap. Green underpaint
	# alone produced a featureless vertical strip through the belt. Continue
	# the same view's leather pigment inside the completed coat silhouette;
	# all original strap, clasp and knot pixels render untouched above it.
	var waist: Array = view["waist"]
	var leather := Vector3.ZERO
	var leather_samples := 0
	for y in range(int(waist[0]),int(waist[1])):
		for x in range(int(view["ground"][0])-38,int(view["ground"][0])+39):
			if roundi(owners.get_pixel(x,y).r*255)!=64: continue
			var color := source.get_pixel(x,y)
			if color.r<.18 or color.r>.60 or color.r-color.g<.02 or color.g-color.b<.025: continue
			leather+=Vector3(color.r,color.g,color.b)
			leather_samples+=1
	var belt_color := Color(leather.x/leather_samples,leather.y/leather_samples,leather.z/leather_samples) if leather_samples>0 else Color("5c4832")
	var cx := float(view["ground"][0])
	var strip := PackedVector2Array([Vector2(cx-90,waist[0]),Vector2(cx+90,waist[0]),Vector2(cx+90,waist[1]),Vector2(cx-90,waist[1])])
	for contour in source_contours(view,"body_core"):
		var outline := PackedVector2Array()
		for point in contour: outline.append(point/float(view["scale"])+_point(view["ground"]))
		for polygon: PackedVector2Array in Geometry2D.intersect_polygons(outline,strip):
			var piece := _cloth_geometry(view,{"vertices":polygon})
			var first: int = geometry["vertices"].size()
			geometry["vertices"].append_array(piece["vertices"])
			for index: int in piece["triangles"]: geometry["triangles"].append(first+index)
			for point in piece["vertices"]:
				var t := clampf((point.y-float(waist[0]))/(float(waist[1])-float(waist[0])),0,1)
				colors.append(belt_color.lightened(.07).lerp(belt_color.darkened(.22),t))
	geometry["colors"]=colors
	_body_cores[cache_key]=geometry
	return geometry

static func body_core_vertices(view: Dictionary, pose: Dictionary) -> PackedVector2Array:
	var geometry := _body_core_geometry(view)
	var pivot := source_position(view,view["parts"]["torso"]["pivot"])
	var vertices := PackedVector2Array()
	var fields := _coat_fields(pose,view)
	for point: Vector2 in geometry["vertices"]:
		var native := (point-_point(view["ground"]))*float(view["scale"])
		vertices.append(Vector2(pose["torso"])+coat_vertex(pose,native-pivot,view,fields).rotated(float(pose["torso_rotation"])))
	return vertices

static func _draw_body_core(canvas: CanvasItem, view: Dictionary, pose: Dictionary, offset: Vector2, factor: float, tint: Color) -> void:
	var frame := Engine.get_process_frames()
	if int(canvas.get_meta("concept_mesh_frame",-1))!=frame:
		canvas.set_meta("concept_mesh_frame",frame)
		canvas.set_meta("concept_draw_meshes",[])
	var geometry := _body_core_geometry(view)
	var vertices := body_core_vertices(view,pose)
	var colors := PackedColorArray()
	for i in range(vertices.size()):
		vertices[i]=offset+vertices[i]*factor
		colors.append(Color(geometry["colors"][i])*tint)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_COLOR]=colors
	arrays[Mesh.ARRAY_INDEX]=geometry["triangles"]
	var texture: Texture2D = null
	if view.has("modular_art"):
		var asset: Dictionary = view["modular_art"]["coat"]
		# All cloth uses one explicit atlas sampler; keep the canvas binding
		# on this view's existing source rather than binding 112 SVG textures.
		texture=_texture(str(view["source"]))
		var bounds: Array = asset["bounds"]
		var rect: Array = asset["path_atlas"]
		var uvs := PackedVector2Array()
		for point: Vector2 in geometry["vertices"]:
			var native := (point-_point(view["ground"]))*float(view["scale"])
			var uv := (native-Vector2(bounds[0],bounds[1]))/Vector2(bounds[2],bounds[3])
			uvs.append(modular_atlas_uv(view,rect,uv))
		arrays[Mesh.ARRAY_TEX_UV]=uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	canvas.get_meta("concept_draw_meshes").append(mesh)
	canvas.draw_mesh(mesh,texture)

static func snapshot_boots(pose: Dictionary) -> String:
	return str(pose.get("source_boots", "cloth"))

static func source_elbow_cuts(view: Dictionary, key: String) -> PackedVector2Array:
	var cache_key := str(view["source"])+str(view["ground"])+key
	if _elbow_cuts.has(cache_key): return _elbow_cuts[cache_key]
	var source := GuConceptCharacterRig._joint_list(view,key)
	var axis := (source[2]-source[0]).normalized()
	var cuts := PackedVector2Array()
	for contour in source_contours(view,key):
		for i in range(contour.size()):
			var a := contour[i]
			var b := contour[(i+1)%contour.size()]
			var first := (a-source[1]).dot(axis)
			var last := (b-source[1]).dot(axis)
			if first*last>=0: continue
			var cut := a.lerp(b,-first/(last-first))-source[1]
			# A cut farther away belongs to an occluded coat fragment.
			if cut.length()>4.5 or cut.length()<.05: continue
			var duplicate := false
			for existing in cuts: duplicate=duplicate or existing.distance_to(cut)<.01
			if not duplicate: cuts.append(cut)
	_elbow_cuts[cache_key]=cuts
	return cuts

static func elbow_cloth_bridges(view: Dictionary, key: String, joints: PackedVector2Array) -> Array[Dictionary]:
	var source := GuConceptCharacterRig._joint_list(view,key)
	var deformation := sleeve_deformation(source,joints)
	var turn := float(deformation["turn"])
	var bridges: Array[Dictionary] = []
	if absf(turn)<.002: return bridges
	var axis := (source[2]-source[0]).normalized()
	for cut in source_elbow_cuts(view,key):
		var upper_edge := sleeve_point(source[1]+cut,source,joints,0,deformation)-joints[1]
		var lower_edge := sleeve_point(source[1]+cut,source,joints,1,deformation)-joints[1]
		var upper := cut.angle_to(upper_edge)
		var lower := cut.angle_to(lower_edge)
		var cloth_turn := wrapf(lower-upper,-PI,PI)
		# Only the opening side needs cloth. The closing side already overlaps
		# both source pieces; outlining its sector creates a spurious elbow cap.
		if cut.cross(axis)*cloth_turn<=0 or absf(cloth_turn)<.002: continue
		var arc := PackedVector2Array()
		for step in range(9):
			var t := float(step)/8
			# Cloth rounds toward the hinge under compression, rather than
			# drawing a full circular disk. Endpoints stay on the two cutouts.
			var radius := 1-.12*absf(sin(cloth_turn*.5))*sin(t*PI)
			var length := lerpf(upper_edge.length(),lower_edge.length(),t)
			arc.append(joints[1]+Vector2.from_angle(cut.angle()+upper+cloth_turn*t)*length*radius)
		var polygon := PackedVector2Array([joints[1]])
		polygon.append_array(arc)
		bridges.append({"polygon":polygon,"outline":arc,"cut":cut,"turn":cloth_turn,"upper_angle":upper,"lower_angle":lower})
	return bridges

static func sleeve_pigment(view: Dictionary, key: String) -> Color:
	var cache_key := str(view["source"])+str(view["ground"])+key
	if _sleeve_palettes.has(cache_key): return _sleeve_palettes[cache_key]
	_sleeve_source_edges(view,key)
	var source_name := str(view["source"])
	if not _pigments.has(source_name): _pigments[source_name]=_texture(source_name).get_image()
	var pigment: Image = _pigments[source_name]
	var owner: Image = _owners[source_name]
	var source := GuConceptCharacterRig._joint_list(view,key)
	var normal := Vector2(-(source[1]-source[0]).y,(source[1]-source[0]).x).normalized()
	var total := Color(0,0,0,0)
	var count := 0
	for step in range(9):
		for across in [-.75,0.0,.75]:
			var native: Vector2 = source[0].lerp(source[1],lerpf(.20,.85,float(step)/8))+normal*across
			var pixel := Vector2i(native/float(view["scale"])+_point(view["ground"]))
			if pixel.x<0 or pixel.y<0 or pixel.x>=owner.get_width() or pixel.y>=owner.get_height(): continue
			if roundi(owner.get_pixelv(pixel).r*255)!=int(manifest()["layer_ids"][key])*32: continue
			var color := pigment.get_pixelv(pixel)
			# Reject dark ink, ivory cuffs and skin; bridge only the green wash.
			if color.r<.19 or color.r>.67 or color.g<color.r*.90 or color.g<color.b*1.02: continue
			total+=color
			count+=1
	var result := total/float(count) if count>0 else Color("696e58")
	result.a=1
	_sleeve_palettes[cache_key]=result
	return result

static func _seam(canvas: CanvasItem, view: Dictionary, key: String, joints: PackedVector2Array, offset: Vector2, factor: float, tint: Color) -> void:
	if not key.begins_with("arm_"):
		_draw_pants(canvas,joints,offset,factor,tint)
		return
	var pigment := sleeve_pigment(view,key)
	for bridge in elbow_cloth_bridges(view,key,joints):
		var arc: PackedVector2Array = bridge["outline"].duplicate()
		for i in range(arc.size()): arc[i]=offset+arc[i]*factor
		var center := offset+joints[1]*factor
		# Near-neutral afterimages have subpixel wedges. Submit this known
		# star-shaped fan directly; screen-space polygon triangulation loses
		# its tiny edges after translation to large world coordinates.
		for i in range(arc.size()-1):
			if absf((arc[i]-center).cross(arc[i+1]-center))<.00001: continue
			canvas.draw_primitive(PackedVector2Array([center,arc[i],arc[i+1]]),PackedColorArray([pigment*tint]),PackedVector2Array())
		GuConceptInkStroke.draw(canvas,arc,.26*factor,Color("332c24")*tint)

static func pants_contour(joints: PackedVector2Array) -> PackedVector2Array:
	var hip := joints[0]
	var knee := joints[1]
	var cuff := joints[2]+Vector2(0,-3.5)
	# Some authored knees are below the boot cuff. They are inside the boot,
	# not an exposed pants fold; folding a tube back to that cuff crosses its
	# own silhouette. Keep the exposed knee between hip and cuff instead.
	var reach := cuff-hip
	var u := (knee-hip).dot(reach)/maxf(.0001,reach.length_squared())
	if u<.15 or u>.85:
		knee=hip.lerp(cuff,.55)
	else:
		var on_axis := hip+reach*u
		knee=on_axis+(knee-on_axis).limit_length(reach.length()*.25)
	var line := PackedVector2Array([hip])
	if hip.distance_to(knee)>.01: line.append(knee)
	if cuff.distance_to(line[-1])>.01: line.append(cuff)
	if line.size()<2: line.append(hip+Vector2(0,.02))
	# Offset/union handles very short folded limbs without self-intersection
	# and produces rounded joints instead of a separate visible knee cap.
	var regions := Geometry2D.offset_polyline(line,1.35,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND)
	return regions[0] if not regions.is_empty() else PackedVector2Array()

static func _draw_pants(canvas: CanvasItem, joints: PackedVector2Array, offset: Vector2, factor: float, tint: Color) -> void:
	# The cuff-only source cutout carries no standing-pose pants stripes.
	# A single curved silhouette follows this frame's knee and disappears
	# under the robe and boot. No separate knee cap or doubled shin strokes.
	var path := pants_contour(joints)
	for i in range(path.size()): path[i]=offset+path[i]*factor
	var colors := PackedColorArray()
	var axis := (joints[2]-joints[0]).normalized()
	var normal := Vector2(-axis.y,axis.x)
	for point in path:
		var across := ((point-offset)/factor-joints[0]).dot(normal)
		colors.append(Color("494d42").lerp(Color("626657"),clampf(.5+across*.22,0,1))*tint)
	canvas.draw_polygon(path,colors)
	var outline := path.duplicate()
	outline.append(path[0])
	GuConceptInkStroke.draw(canvas,outline,.32*factor,Color("332c24")*tint)

static func _draw_sword(canvas: CanvasItem, snapshot: Dictionary, rest: Dictionary, offset: Vector2, tint: Color) -> void:
	var weapon: Dictionary = manifest()["sword"]
	var geometry := _triangles("original_sword",weapon["polygon"])
	var texture := _texture(str(weapon["source"]))
	var size := Vector2(texture.get_size())
	var hand := hand_position(snapshot)
	var transform := sword_attachment(snapshot)
	var mirror: float = transform["mirror"]
	var angle: float = transform["angle"]
	canvas.draw_set_transform(offset+hand,angle,Vector2(mirror,1)*float(snapshot["scale"]))
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	for point in geometry["vertices"]:
		vertices.append((point-_point(weapon["pivot"]))*float(weapon["scale"]))
		uvs.append(point/size+Vector2(14,0))
	var color := tint
	canvas.draw_polygon(vertices,PackedColorArray([color]),uvs,texture)
	canvas.draw_set_transform(Vector2.ZERO)

static func _held_arm(canvas: CanvasItem, snapshot: Dictionary, view: Dictionary, side: String, pose: Dictionary, rest: Dictionary, offset: Vector2, factor: float, tint: Color, bone_filter: int = -1) -> void:
	if GuConceptDirectionalParts.available(view):
		GuConceptDirectionalParts.draw_arm(canvas,snapshot,view,side,pose,rest,offset,factor,tint,bone_filter)
		return
	if bone_filter!=1:
		_draw_modular_sleeve(canvas,view,"arm_"+side,pose,offset,factor,tint)
	if side=="R" and bone_filter!=0:
		if str(snapshot["appearance"]["weapon"])=="sword":
			_draw_sword(canvas,snapshot,rest,offset,tint)
		elif str(snapshot["appearance"]["weapon"])=="spear":
			_draw_spear(canvas,snapshot,offset,factor,tint)
	if bone_filter!=0:
		_seam(canvas,view,"arm_"+side,pose["arm_"+side],offset,factor,tint)
		_draw_missing_forearm(canvas,view,"arm_"+side,pose,offset,factor,tint)
		_draw_wrist_seam(canvas,view,"arm_"+side,pose,offset,factor,tint)
	_draw_part(canvas,view,"arm_"+side,pose,offset,factor,tint,bone_filter)

static func source_forearm_gap(view: Dictionary, key: String) -> float:
	var cache_key := str(view["source"])+str(view["ground"])+key
	if _forearm_gaps.has(cache_key): return _forearm_gaps[cache_key]
	_sleeve_source_edges(view,key)
	var owner: Image = _owners[str(view["source"])]
	var source := GuConceptCharacterRig._joint_list(view,key)
	var wrist := GuConceptCharacterRig.source_wrist(source)
	var expected := int(manifest()["layer_ids"][key])*32
	var first := 0.0
	for step in range(17):
		var t := float(step)/16
		var pixel := Vector2i(source[1].lerp(wrist,t)/float(view["scale"])+_point(view["ground"]))
		if roundi(owner.get_pixelv(pixel).r*255)==expected: break
		first=t
	# Ignore subpixel cuts at the elbow. Only replace a sustained missing
	# source interval, such as the baked sword's erased male W/N cuff.
	var distance := source[1].distance_to(wrist)*first
	_forearm_gaps[cache_key]=first if distance>=.45 and first<1 else 0.0
	return _forearm_gaps[cache_key]

static func missing_forearm_contour(view: Dictionary, key: String, pose: Dictionary) -> PackedVector2Array:
	var gap := source_forearm_gap(view,key)
	if gap<=0: return PackedVector2Array()
	var chain: PackedVector2Array = pose[key]
	var wrist := Vector2(pose["wrist_"+key.right(1)])
	var axis := (wrist-chain[1]).normalized()
	var normal := Vector2(-axis.y,axis.x)
	var start := chain[1]-axis*.12
	var end := chain[1].lerp(wrist,gap)+axis*.22
	var polygon := PackedVector2Array()
	for side in [-1.0,1.0]:
		for step in range(5):
			var t := float(step if side<0 else 4-step)/4
			polygon.append(start.lerp(end,t)+normal*(lerpf(.78,.66,t)+.05*sin(t*PI))*side)
	return polygon

static func _draw_missing_forearm(canvas: CanvasItem, view: Dictionary, key: String, pose: Dictionary, offset: Vector2, factor: float, tint: Color) -> void:
	var polygon := missing_forearm_contour(view,key,pose)
	if polygon.is_empty(): return
	for i in range(polygon.size()): polygon[i]=offset+polygon[i]*factor
	canvas.draw_colored_polygon(polygon,Color("515748")*tint)
	for side in range(2):
		var edge := PackedVector2Array()
		for i in range(5): edge.append(polygon[side*5+i])
		GuConceptInkStroke.draw(canvas,edge,.24*factor,Color("332c24")*tint)

static func _draw_wrist_seam(canvas: CanvasItem, view: Dictionary, key: String, pose: Dictionary, offset: Vector2, factor: float, tint: Color) -> void:
	var turn := float(pose.get("hand_rotation_"+key.right(1),0))
	if absf(turn)<.002: return
	var source := GuConceptCharacterRig._joint_list(view,key)
	var wrist := GuConceptCharacterRig.source_wrist(source)
	var axis := (source[2]-source[1]).normalized()
	var chain: PackedVector2Array = pose[key]
	var delta := axis.angle_to(chain[2]-chain[1])
	var pivot := Vector2(pose["wrist_"+key.right(1)])
	for contour in source_contours(view,key):
		for i in range(contour.size()):
			var a := contour[i]
			var b := contour[(i+1)%contour.size()]
			var first := (a-wrist).dot(axis)
			var last := (b-wrist).dot(axis)
			if first*last>=0: continue
			var cut := a.lerp(b,-first/(last-first))-wrist
			if cut.length()>2.6 or cut.length()<.05: continue
			var arc := PackedVector2Array([offset+pivot*factor])
			for step in range(7): arc.append(offset+(pivot+cut.rotated(delta+turn*float(step)/6))*factor)
			canvas.draw_colored_polygon(arc,Color("b6a07a")*tint)

static func _draw_spear(canvas: CanvasItem, snapshot: Dictionary, offset: Vector2, factor: float, tint: Color) -> void:
	var angle := float(snapshot["source_pose"]["weapon_angle"])
	var grip := offset+hand_position(snapshot)
	var points := PackedVector2Array()
	for point in [Vector2(0,5.5),Vector2(0,-37)]: points.append(grip+point.rotated(angle)*factor)
	GuConceptInkStroke.draw(canvas,points,1.10*factor,Color("332c24")*tint)
	GuConceptInkStroke.draw(canvas,points,.60*factor,Color("a18c68")*tint)
	var blade := PackedVector2Array()
	for point in [SPEAR_TIP,Vector2(2.05,-38.0),Vector2(.6,-34.9),Vector2(-.6,-34.9),Vector2(-2.05,-38.0)]: blade.append(grip+point.rotated(angle)*factor)
	canvas.draw_colored_polygon(blade,Color("d8d5b9")*tint)
	blade.append(blade[0])
	GuConceptInkStroke.draw(canvas,blade,.32*factor,Color("332c24")*tint)
	for y in [-2.8,-1.8,1.8,2.8]:
		var wrap := PackedVector2Array([grip+Vector2(-.65,y).rotated(angle)*factor,grip+Vector2(.65,y+.15).rotated(angle)*factor])
		GuConceptInkStroke.draw(canvas,wrap,.28*factor,Color("443b30")*tint)

static func exposed_upper_sleeve(view: Dictionary, key: String, pose: Dictionary) -> PackedVector2Array:
	var chain: PackedVector2Array = pose[key]
	var source := GuConceptCharacterRig._joint_list(view,key)
	var axis := (chain[1]-chain[0]).normalized()
	var normal := Vector2(-axis.y,axis.x)
	# A source upper arm is partly hidden by the standing coat. When it
	# rotates away, that absent pigment must not look like a detached hand.
	# Fill only its upper sleeve, with the actual source width; no palm cap,
	# lower-arm tube or extra stripe is added to the approved drawing.
	var width := 1.65
	if view["source"]=="original" and key=="arm_R": width=1.85
	# Start under the shoulder rather than .8 units beyond it. On W/N,
	# the old offset left a visible gap between the coat and revealed sleeve.
	var root := chain[0]-axis*.65
	var elbow := chain[1]
	var polygon := PackedVector2Array()
	for side in [-1.0,1.0]:
		for step in range(9):
			var t := float(step if side<0 else 8-step)/8
			var radius := width*(lerpf(.70,.64,t)+.32*sin(t*PI))
			var center := root.lerp(elbow,t)+normal*(width*.10*sin(t*PI))
			polygon.append(center+normal*radius*side)
	return polygon

static func _draw_exposed_upper_sleeve(canvas: CanvasItem, view: Dictionary, key: String, pose: Dictionary, offset: Vector2, factor: float, tint: Color) -> void:
	var source := GuConceptCharacterRig._joint_list(view,key)
	var chain: PackedVector2Array = pose[key]
	var delta := (source[1]-source[0]).angle_to(chain[1]-chain[0])-float(pose["torso_rotation"])
	if absf(delta)<.24: return
	var polygon := exposed_upper_sleeve(view,key,pose)
	var pigment := sleeve_pigment(view,key)
	var colors := PackedColorArray()
	for i in range(polygon.size()):
		polygon[i]=offset+polygon[i]*factor
		colors.append((pigment.darkened(.10) if i<polygon.size()/2 else pigment.lightened(.05))*tint)
	canvas.draw_polygon(polygon,colors)
	for side in range(2):
		var edge := PackedVector2Array()
		for i in range(9): edge.append(polygon[side*9+i])
		GuConceptInkStroke.draw(canvas,edge,.30*factor,Color("332c24")*tint)

static func modular_sleeve_geometry(view: Dictionary, key: String) -> Dictionary:
	var asset: Dictionary = view["modular_art"]["sleeves"][key]
	var cache_key := str(asset["base"])
	if not _modular_sleeves.has(cache_key):
		_modular_sleeves[cache_key]=_sleeve_geometry(view,key,_triangles(cache_key,asset["source_polygon"]))
	return _modular_sleeves[cache_key]

static func modular_atlas_uv(view: Dictionary, rect: Array, uv: Vector2) -> Vector2:
	return Vector2(16,0)+(Vector2(rect[0],rect[1])+uv*Vector2(rect[2],rect[3]))/_point(view["modular_art"]["atlas_size"])

static func modular_sleeve_vertices(view: Dictionary, key: String, pose: Dictionary) -> PackedVector2Array:
	var geometry := modular_sleeve_geometry(view,key)
	var source := GuConceptCharacterRig._joint_list(view,key)
	var deformation := sleeve_deformation(source,pose[key])
	var vertices := PackedVector2Array()
	for point: Vector2 in geometry["vertices"]:
		vertices.append(sleeve_point((point-_point(view["ground"]))*float(view["scale"]),source,pose[key],0,deformation))
	return vertices

static func _draw_modular_sleeve(canvas: CanvasItem, view: Dictionary, key: String, pose: Dictionary, offset: Vector2, factor: float, tint: Color) -> void:
	if not view.has("modular_art"):
		_draw_exposed_upper_sleeve(canvas,view,key,pose,offset,factor,tint)
		return
	var asset: Dictionary = view["modular_art"]["sleeves"][key]
	var frame := Engine.get_process_frames()
	if int(canvas.get_meta("concept_mesh_frame",-1))!=frame:
		canvas.set_meta("concept_mesh_frame",frame)
		canvas.set_meta("concept_draw_meshes",[])
	var geometry := modular_sleeve_geometry(view,key)
	var source := GuConceptCharacterRig._joint_list(view,key)
	var chain: PackedVector2Array = pose[key]
	var deformation := sleeve_deformation(source,chain)
	var vertices := modular_sleeve_vertices(view,key,pose)
	var uvs := PackedVector2Array()
	var bounds: Array = asset["bounds"]
	for i in range(geometry["vertices"].size()):
		var point: Vector2 = geometry["vertices"][i]
		var native := (point-_point(view["ground"]))*float(view["scale"])
		vertices[i]=offset+vertices[i]*factor
		uvs.append((native-Vector2(bounds[0],bounds[1]))/Vector2(bounds[2],bounds[3]))
	var indices := PackedInt32Array()
	for i in range(0,geometry["triangles"].size(),3):
		var a: int = geometry["triangles"][i]
		if int(geometry["bones"][a])==0: indices.append_array(geometry["triangles"].slice(i,i+3))
	var flex := absf(float(deformation["turn"]))/ARM_FLEX_NORMALIZER
	for variant in ["base","flex","strike"]:
		var weight := 1.0 if variant=="base" else smoothstep(.15,.8,flex) if variant=="flex" else 1-smoothstep(.08,.35,flex)
		if weight<.001: continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=vertices
		var rect: Array = asset["base_atlas"] if variant=="base" else asset["variants"][variant+"_atlas"]
		var atlas_uvs := PackedVector2Array()
		for uv in uvs: atlas_uvs.append(modular_atlas_uv(view,rect,uv))
		arrays[Mesh.ARRAY_TEX_UV]=atlas_uvs
		arrays[Mesh.ARRAY_INDEX]=indices
		var colors := PackedColorArray()
		colors.resize(vertices.size())
		colors.fill(Color(tint,tint.a*weight))
		arrays[Mesh.ARRAY_COLOR]=colors
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_2D_VERTICES)
		canvas.get_meta("concept_draw_meshes").append(mesh)
		canvas.draw_mesh(mesh,_texture(str(view["source"])))

const ARM_FLEX_NORMALIZER := 2.35619449

static func draw(canvas: CanvasItem, snapshot: Dictionary, offset: Vector2, tint: Color) -> void:
	var look: Dictionary = snapshot["appearance"]
	var direction := int(snapshot["direction_index"])
	var view := view_for(look,direction)
	if view.is_empty():
		return
	var pose: Dictionary = (snapshot["source_pose"] if snapshot.has("source_pose") else GuConceptCharacterRig.sample(snapshot)).duplicate(true)
	pose["source_boots"] = look.get("boots", "cloth")
	var rest := GuIllustratedCharacterArt.sample("idle",0.0,direction,look,true)
	var factor := float(snapshot["scale"])
	var color := tint
	color.a *= float(pose["alpha"])
	var far_arm := "L" if float(pose["arm_depth_L"]) <= float(pose["arm_depth_R"])+0.001 else "R"
	var near_arm := "R" if far_arm=="L" else "L"
	var back := direction in [3,4,5]
	var back_stride: bool = back and not GuConceptDirectionalParts.available(view) and snapshot["action"] in ["walk","run","attack","cast","defend","channel"]
	var hands_in_front: bool = not back and snapshot["action"] in ["defend","channel"]
	# An overhead sword preparation passes behind the head. Submit that
	# sleeve/weapon before the head throughout the stroke; the release grip
	# is below/outside its silhouette and remains fully visible without a
	# phase-dependent depth pop or a hand pasted over the face.
	var sword_behind_head: bool = not back and bool(snapshot.get("arms_behind_head",snapshot["action"]=="mine" or snapshot["action"]=="attack" and str(look["weapon"])=="sword"))
	for side in ["L","R"]:
		var contact := float(pose.get("foot_contact_"+side,1))
		var foot: Vector2 = pose["foot_ground_"+side]
		canvas.draw_set_transform(offset+(foot+Vector2(0,.2))*factor,0,Vector2(3.3,0.8)*factor)
		canvas.draw_circle(Vector2.ZERO,1,Color(0.025,0.04,0.04,0.16*contact*color.a),true,-1,true)
	canvas.draw_set_transform(Vector2.ZERO)
	# The ponytail remains an independent cosmetic attachment.
	var source_head: Vector2 = pose["head"]
	if str(look["hair"])=="ponytail":
		GuIllustratedCharacterArt._piece(canvas,"tail_ponytail_%d" % direction,offset+(source_head+Vector2(0,2))*factor,float(pose["tail_rotation"]),Vector2.ONE*factor*0.7,color)
		canvas.draw_set_transform(Vector2.ZERO)
	if not hands_in_front: _held_arm(canvas,snapshot,view,far_arm,pose,rest,offset,factor,color,0 if back_stride else -1)
	var far_leg := "L" if Vector2(pose["foot_ground_L"]).y<Vector2(pose["foot_ground_R"]).y else "R"
	for side in [far_leg,"R" if far_leg=="L" else "L"]:
		if GuConceptDirectionalParts.available(view):
			GuConceptDirectionalParts.draw_leg(canvas,view,side,pose,offset,factor,color)
		else:
			_seam(canvas,view,"leg_"+side,pose["leg_"+side],offset,factor,color)
			_draw_part(canvas,view,"leg_"+side,pose,offset,factor,color)
	if back:
		_held_arm(canvas,snapshot,view,near_arm,pose,rest,offset,factor,color,0 if back_stride else -1)
	_draw_body_core(canvas,view,pose,offset,factor,color)
	_draw_part(canvas,view,"torso",pose,offset,factor,color)
	if back_stride:
		for side in [far_arm,near_arm]: _held_arm(canvas,snapshot,view,side,pose,rest,offset,factor,color,1)
	if hands_in_front: _held_arm(canvas,snapshot,view,far_arm,pose,rest,offset,factor,color)
	if sword_behind_head: _held_arm(canvas,snapshot,view,near_arm,pose,rest,offset,factor,color)
	_draw_part(canvas,view,"head",pose,offset,factor,color)
	if not back and not sword_behind_head:
		_held_arm(canvas,snapshot,view,near_arm,pose,rest,offset,factor,color)
	if str(look.get("hat", "none"))!="none":
		GuIllustratedCharacterArt._piece(canvas,"hat_%s_%d" % [look["hat"],direction],offset+source_head*factor,float(pose["head_rotation"]),Vector2.ONE*factor*0.82,color)
	canvas.draw_set_transform(Vector2.ZERO)
