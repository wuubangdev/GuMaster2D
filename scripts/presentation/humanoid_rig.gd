class_name GuHumanoidRig
extends RefCounted
## Pure presentation pose. Coordinates are relative to the ground, never simulation cells.

const STRIDE_DISTANCE: float = 38.0

static func sample(facing: Vector2, gait: float, speed: float, time: float, action: String = "", progress: float = 1.0, channel: bool = false, hit: float = 0.0, reduced: bool = false) -> Dictionary:
	var direction := facing.normalized() if facing.length_squared() > 0.0001 else Vector2.DOWN
	var flip := -1.0 if direction.x < -0.01 else 1.0
	var width := lerpf(1.0, 0.72, absf(direction.x))
	var motion := 0.0 if reduced else clampf(speed, 0.0, 1.0)
	var breath := 0.0 if reduced else sin(time * 2.2) * 0.35 * (1.0 - motion)
	var bob := -absf(sin(gait)) * 1.5 * motion + breath
	var t := clampf(progress, 0.0, 1.0)
	var gesture := sin(pow(t, 0.65) * PI) if not action.is_empty() else 0.0
	var lean := absf(direction.x) * 2.0 * motion
	var recoil := 0.0 if reduced else sin(clampf(hit / 0.19, 0.0, 1.0) * PI)
	var drift := sin(gait - 0.7) * 2.5 * motion - absf(direction.x) * motion * 2.0
	if action == "dash":
		lean += 12.0 * gesture
		drift -= 18.0 * gesture if not reduced else 0.0
		bob += 5.0 * gesture
	elif action == "cast_moon":
		lean += 4.0 * gesture
	elif action == "cast_frost":
		bob += 2.0 * gesture
	lean -= recoil * 5.0
	var p := {"flip": flip, "width": width, "back": direction.y < -0.25, "profile": absf(direction.x) > 0.96, "gesture": gesture, "cloth": drift, "direction": direction}
	p["belt"] = Vector2(lean * 0.3, -31 + bob)
	p["chest"] = Vector2(lean, -47 + bob + recoil * 1.5)
	p["neck"] = p["chest"] + Vector2(0, -5)
	p["head"] = p["neck"] + Vector2(lean * 0.15, -7)
	for side in [-1.0, 1.0]:
		var suffix := "l" if side < 0 else "r"
		var cycle := gait + (PI if side < 0 else 0.0)
		var unit := fposmod(cycle / TAU, 1.0)
		# During stance the foot travels back exactly as far as the body travels forward.
		# The return half-cycle lifts it in an arc; a sine-only gait visibly skates.
		var swing := (1.0 - unit * 4.0) if unit < 0.5 else -cos((unit - 0.5) * TAU)
		var lift := sin((unit - 0.5) * TAU) * 6.0 * motion if unit >= 0.5 else 0.0
		swing *= motion
		var foot := Vector2(side * 5.0 * width, 1.0 - lift) + Vector2(absf(direction.x), direction.y) * swing * STRIDE_DISTANCE * 0.25
		var hip: Vector2 = p["belt"] + Vector2(side * 4.5 * width, 4)
		var knee := hip.lerp(foot, 0.57) + Vector2(lift * 0.45, -lift * 0.15)
		var shoulder: Vector2 = p["chest"] + Vector2(side * 8.0 * width, 0)
		var hand := shoulder + Vector2(side * 4.0 - swing * 5.0, 21.0 + swing * 2.0)
		var elbow := shoulder.lerp(hand, 0.53) + Vector2(side * 3.0, 0)
		var pose_hand := hand
		var pose_elbow := elbow
		match action:
			"cast_moon":
				pose_hand = p["chest"] + (Vector2(27 * absf(direction.x), direction.y * 16 - 5) if side > 0 else Vector2(-10, 16))
				pose_elbow = shoulder + (Vector2(11 * absf(direction.x), direction.y * 8 - 1) if side > 0 else Vector2(-5, 7))
			"shield":
				pose_hand = p["chest"] + Vector2(side * 5, -9)
				pose_elbow = shoulder + Vector2(side * 7, 9)
			"cast_frost":
				pose_hand = p["chest"] + Vector2(side * 25, 3)
				pose_elbow = shoulder + Vector2(side * 10, 8)
			"dash":
				pose_hand = shoulder + Vector2(-17, 12 + side * 4)
				pose_elbow = shoulder + Vector2(-8, 10 + side * 3)
		hand = hand.lerp(pose_hand, gesture)
		elbow = elbow.lerp(pose_elbow, gesture)
		if channel:
			var hover := 0.0 if reduced else sin(time * 3.0) * 0.8
			hand = p["chest"] + Vector2(side * 7 + 8, -2 + side * 5 + hover)
			elbow = shoulder + Vector2(side * 7, 9)
		p["hip_" + suffix] = hip
		p["knee_" + suffix] = knee
		p["foot_" + suffix] = foot
		p["shoulder_" + suffix] = shoulder
		p["elbow_" + suffix] = elbow
		p["hand_" + suffix] = hand
	# Mirroring every joint keeps front/back/profile poses and their spell origin coherent.
	for key in p:
		if p[key] is Vector2 and key != "direction":
			p[key] = Vector2(p[key].x * flip, p[key].y)
	return p
