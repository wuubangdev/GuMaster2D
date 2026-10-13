class_name BeastAttackGeometry
extends RefCounted
## One world-space footprint supplies authority, ground warnings and impact VFX.
## Positions/radii are cells. Rendering projects each point through WorldGrid.
static func build(mob: Dictionary, attack: Dictionary) -> Dictionary:
	var origin: Vector2 = mob["cell"]
	var aim: Vector2 = mob.get("aim",origin)
	var facing: Vector2 = mob.get("facing",Vector2.RIGHT)
	if facing.length_squared() < .001: facing = Vector2.RIGHT
	var kind: String = attack.get("style","melee")
	var radius: float = attack.get("radius",.72 if kind == "charge" else 1.05)
	var geometry := {"kind":kind,"origin":origin,"aim":aim,"facing":facing.normalized(),"radius":radius,"range":float(attack["range"]),"half_angle":float(attack.get("half_angle",.9)),"centers":[aim]}
	if kind == "stomp": geometry["centers"] = [origin]
	elif kind == "burst":
		var side := facing.normalized().orthogonal()
		geometry["centers"] = [aim,aim+side*1.65,aim-side*1.65]
	return geometry

static func contains(geometry: Dictionary, point: Vector2) -> bool:
	var origin: Vector2 = geometry["origin"]
	var radius: float = geometry["radius"]
	match geometry["kind"]:
		"charge":
			return point.distance_to(Geometry2D.get_closest_point_to_segment(point,origin,geometry["aim"])) <= radius
		"spit","stomp","burst":
			for center in geometry["centers"]:
				if point.distance_to(center) <= radius: return true
			return false
		_:
			var delta := point-origin
			return delta.length() <= float(geometry["range"]) and (delta.length_squared()<.0001 or delta.normalized().dot(geometry["facing"]) >= cos(float(geometry["half_angle"])))

static func polygons(geometry: Dictionary) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var origin: Vector2 = geometry["origin"]
	var aim: Vector2 = geometry["aim"]
	var radius: float = geometry["radius"]
	match geometry["kind"]:
		"spit","stomp","burst":
			for center in geometry["centers"]:
				var points := PackedVector2Array()
				for i in range(65): points.append(Vector2(center)+Vector2.from_angle(TAU*i/64)*radius)
				result.append(points)
		"charge":
			var points := PackedVector2Array()
			var angle := (aim-origin).angle()
			for i in range(33): points.append(aim+Vector2.from_angle(angle-PI/2+PI*i/32)*radius)
			for i in range(33): points.append(origin+Vector2.from_angle(angle+PI/2+PI*i/32)*radius)
			points.append(points[0])
			result.append(points)
		_:
			var angle: float = Vector2(geometry["facing"]).angle()
			var half: float = geometry["half_angle"]
			var points := PackedVector2Array([origin])
			for i in range(49): points.append(origin+Vector2.from_angle(angle-half+half*2*i/48)*float(geometry["range"]))
			points.append(origin)
			result.append(points)
	return result
