extends RefCounted
## A projected leg may shorten on screen, but its physical thigh/shin must
## still reconstruct from XY and depth to the unchanged authored lengths.

static func physical_lengths(pose: Dictionary, side: String) -> Vector2:
	var key := "leg_"+side
	if not pose.has("leg_depth_"+side): return Vector2(INF,INF)
	var chain: PackedVector2Array = pose[key]
	var depth: PackedFloat32Array = pose["leg_depth_"+side]
	if depth.size()!=3: return Vector2(INF,INF)
	var result := Vector2.ZERO
	for bone in range(2):
		result[bone]=sqrt(chain[bone].distance_squared_to(chain[bone+1])+pow(float(depth[bone+1])-float(depth[bone]),2))
	return result

static func inspect(pose: Dictionary, view: Dictionary, side: String) -> Dictionary:
	var result := {"lengths":false,"bounds":false,"profile_rigid":false,"stance_knee":false,"projected":false}
	for field in ["leg_physical_lengths_","leg_projection_","leg_depth_"]:
		if not pose.has(field+side): return result
	var source := GuConceptCharacterRig._joint_list(view,"leg_"+side)
	var authored := Vector2(source[0].distance_to(source[1]),source[1].distance_to(source[2]))
	var declared: Vector2 = pose["leg_physical_lengths_"+side]
	var ratio: Vector2 = pose["leg_projection_"+side]
	var reconstructed := physical_lengths(pose,side)
	var chain: PackedVector2Array = pose["leg_"+side]
	var observed := Vector2(chain[0].distance_to(chain[1]),chain[1].distance_to(chain[2]))
	result["lengths"]=declared.distance_to(authored)<.0001 and reconstructed.distance_to(authored)<.0005 and observed.distance_to(authored*ratio)<.0005
	result["bounds"]=ratio.is_finite() and ratio.x>=.35-.0001 and ratio.y>=.35-.0001 and ratio.x<=1.0001 and ratio.y<=1.0001
	var direction := int(view["directional_art"]["direction"])
	result["profile_rigid"]=direction not in [2,6] or ratio.distance_to(Vector2.ONE)<.0001
	# The frontal shoe keeps an upright sole; a knee below that sole reverses
	# the visible shin even when a joint-centre alpha probe reports no gap.
	result["stance_knee"]=direction not in [0,4] or float(pose["foot_contact_"+side])<.995 or chain[1].y<=chain[2].y+.0001
	result["projected"]=minf(ratio.x,ratio.y)<.98
	return result
