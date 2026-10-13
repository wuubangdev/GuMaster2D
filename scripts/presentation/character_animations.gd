class_name GuCharacterAnimations
extends RefCounted
## Original in-place motion library for the shared Gu humanoid skeleton.
## Position/rotation tracks target genuine Skeleton3D bones. No animation moves
## the gameplay root, changes a hitbox, applies damage, or spends resources.

const WALK_STRIDE_METERS: float = 0.75
const RUN_STRIDE_METERS: float = 1.55
const SAMPLE_RATE: float = 30.0
const CLIP_DURATIONS: Dictionary = {
	"RESET": 0.1, "idle": 3.2, "walk": 1.05, "run": 0.68,
	"attack": 0.76, "defend": 2.0, "cast": 0.90, "channel": 2.4,
	"dash": 0.42, "hit": 0.38, "death": 1.15, "respawn": 1.0,
}
const LOOPING: Array[String] = ["idle", "walk", "run", "defend", "channel"]
const BONE_RESTS: Dictionary = {
	"Hips": Vector3(0, 0.98, 0),
	"Spine": Vector3(0, 0.22, 0),
	"Chest": Vector3(0, 0.24, 0),
	"Neck": Vector3(0, 0.14, 0),
	"Head": Vector3(0, 0.19, 0),
	"Shoulder_L": Vector3(-0.19, 0.06, 0),
	"UpperArm_L": Vector3(-0.13, 0, 0),
	"Forearm_L": Vector3(0, -0.27, 0),
	"Hand_L": Vector3(0, -0.25, 0),
	"Shoulder_R": Vector3(0.19, 0.06, 0),
	"UpperArm_R": Vector3(0.13, 0, 0),
	"Forearm_R": Vector3(0, -0.27, 0),
	"Hand_R": Vector3(0, -0.25, 0),
	"Thigh_L": Vector3(-0.13, -0.04, 0),
	"Shin_L": Vector3(0, -0.45, 0),
	"Foot_L": Vector3(0, -0.42, 0.035),
	"Thigh_R": Vector3(0.13, -0.04, 0),
	"Shin_R": Vector3(0, -0.45, 0),
	"Foot_R": Vector3(0, -0.42, 0.035),
	"Hair": Vector3(0, 0.11, 0.08),
	"Cape": Vector3(0, -0.08, 0.10),
	"CapeTip": Vector3(0, -0.32, 0.01),
}
const LABELS: Dictionary = {
	"idle": "Đứng / thở", "walk": "Đi bộ", "run": "Chạy",
	"attack": "Tấn công", "defend": "Phòng thủ", "cast": "Thi triển Cổ",
	"channel": "Vận công", "dash": "Lướt", "hit": "Trúng đòn",
	"death": "Gục xuống", "respawn": "Hồi sinh",
}

const WEAPON_DURATIONS: Dictionary = {
	"sword": {"attack": GuCharacterActionMotion.SWORD_SECONDS},
	"spear": {"idle": 3.5, "attack": 0.94, "defend": 2.6},
	"unarmed": {"idle": 2.8, "attack": 0.62, "defend": 1.8},
}
const BONE_PARENTS: Dictionary = {
	"Hips": "", "Spine": "Hips", "Chest": "Spine", "Neck": "Chest", "Head": "Neck",
	"Shoulder_L": "Chest", "UpperArm_L": "Shoulder_L", "Forearm_L": "UpperArm_L", "Hand_L": "Forearm_L",
	"Shoulder_R": "Chest", "UpperArm_R": "Shoulder_R", "Forearm_R": "UpperArm_R", "Hand_R": "Forearm_R",
	"Thigh_L": "Hips", "Shin_L": "Thigh_L", "Foot_L": "Shin_L",
	"Thigh_R": "Hips", "Shin_R": "Thigh_R", "Foot_R": "Shin_R",
	"Hair": "Head", "Cape": "Chest", "CapeTip": "Cape",
}

static var _shared_libraries: Dictionary = {}


static func clip_names() -> Array[String]:
	var result: Array[String] = []
	for clip: String in LABELS:
		result.append(clip)
	return result


static func action_labels() -> Dictionary:
	return LABELS.duplicate()


static func duration(clip: String, weapon: String = "sword") -> float:
	if GuCharacterActionMotion.harvesting(clip): return float(GuCharacterActionMotion.HARVEST_DURATIONS[clip])
	var overrides: Dictionary = WEAPON_DURATIONS.get(GuWeaponRig.family(weapon), {})
	return float(overrides.get(clip, CLIP_DURATIONS.get(clip, 1.0)))


static func create_library(weapon: String = "sword") -> AnimationLibrary:
	# Character portraits and the live actor share immutable animation resources.
	var family := GuWeaponRig.family(weapon)
	if _shared_libraries.has(family):
		return _shared_libraries[family]
	var library := AnimationLibrary.new()
	library.resource_name = "Gu humanoid motion v2 / " + family
	library.set_meta("weapon_family", family)
	library.set_meta("rig_contract", "GuHumanoid/1")
	for clip: String in CLIP_DURATIONS:
		library.add_animation(StringName(clip), _create_clip(clip, family))
	_shared_libraries[family] = library
	return library


static func _create_clip(clip: String, weapon: String) -> Animation:
	var animation := Animation.new()
	animation.resource_name = clip
	animation.length = duration(clip, weapon)
	# The fast spear extension needs denser keys to retain a rigid two-hand grip
	# between samples; a 30 Hz bake can drift despite exact contact at each key.
	var sampling_rate := 60.0 if weapon == "spear" and clip == "attack" else SAMPLE_RATE
	animation.step = 1.0 / sampling_rate
	animation.loop_mode = Animation.LOOP_LINEAR if clip in LOOPING else Animation.LOOP_NONE
	animation.set_meta("skeleton_contract", "GuHumanoid/1")
	animation.set_meta("in_place", true)
	animation.set_meta("weapon_family", weapon)
	animation.set_meta("support_grip_active", clip in GuWeaponRig.support_states(weapon))
	var tracks: Dictionary = {}
	for bone: String in BONE_RESTS:
		var position_track := animation.add_track(Animation.TYPE_POSITION_3D)
		var rotation_track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(position_track, NodePath("Skeleton3D:" + bone))
		animation.track_set_path(rotation_track, NodePath("Skeleton3D:" + bone))
		animation.track_set_interpolation_type(position_track, Animation.INTERPOLATION_LINEAR)
		animation.track_set_interpolation_type(rotation_track, Animation.INTERPOLATION_LINEAR)
		tracks[bone] = Vector2i(position_track, rotation_track)
		# All local translations are explicitly restored when clips change. Hips
		# receives dense vertical keys below; the remaining rests stay constant.
		if bone != "Hips":
			animation.position_track_insert_key(position_track, 0.0, BONE_RESTS[bone])
			animation.position_track_insert_key(position_track, animation.length, BONE_RESTS[bone])
	var intervals := maxi(1, ceili(animation.length * sampling_rate))
	var support_error := 0.0
	for key_index: int in range(intervals + 1):
		var time := animation.length * float(key_index) / float(intervals)
		var normalized := float(key_index) / float(intervals)
		var pose := _sample(clip, normalized, weapon)
		if clip in GuWeaponRig.support_states(weapon):
			var right := _bone_transform(pose, "Hand_R")
			var left := _bone_transform(pose, "Hand_L")
			support_error = maxf(support_error, left.origin.distance_to(right * GuWeaponRig.support_grip(weapon)))
		for bone: String in BONE_RESTS:
			var pair: Vector2i = tracks[bone]
			var angles: Vector3 = pose.get(bone, Vector3.ZERO)
			var rotation := Quaternion.from_euler(angles * (PI / 180.0)).normalized()
			animation.rotation_track_insert_key(pair.y, time, rotation)
			if bone == "Hips":
				var position: Vector3 = BONE_RESTS[bone]
				position.y += float(pose.get("height", 0.0))
				animation.position_track_insert_key(pair.x, time, position)
	animation.set_meta("baked_support_error_m", support_error)
	if clip == "attack":
		animation.add_marker("anticipation", 0.0)
		animation.add_marker("visual_strike", animation.length * (0.47 if weapon == "spear" else 0.44))
		animation.add_marker("recovery", animation.length * 0.66)
	elif clip == "cast":
		animation.add_marker("visual_release", 0.49)
	return animation


static func _sample(clip: String, t: float, weapon: String = "sword") -> Dictionary:
	var pose: Dictionary = {}
	match clip:
		"idle":
			pose = _idle(t)
		"walk":
			pose = _locomotion(t, false)
		"run":
			pose = _locomotion(t, true)
		"attack":
			pose = _attack(t)
		"defend":
			pose = _defend(t)
		"cast":
			pose = _cast(t)
		"channel":
			pose = _channel(t)
		"dash":
			pose = _dash(t)
		"hit":
			pose = _hit(t)
		"death":
			pose = _death(t)
		"respawn":
			pose = _respawn(t)
	return _weapon_pose(clip, t, weapon, pose)


static func _ready_pose() -> Dictionary:
	return {
		"UpperArm_L": Vector3(3, -5, -7),
		"UpperArm_R": Vector3(5, 7, 7),
		"Forearm_L": Vector3(8, 0, 0),
		"Forearm_R": Vector3(12, 0, 0),
		"Hand_L": Vector3(-3, 0, 3),
		"Hand_R": Vector3(-5, 0, -3),
		"Thigh_L": Vector3(0, 0, -1),
		"Thigh_R": Vector3(0, 0, 1),
	}


static func _idle(t: float) -> Dictionary:
	var pose := _ready_pose()
	var breath := sin(t * TAU)
	var sway := sin(t * TAU - 0.5)
	pose["height"] = breath * 0.004
	pose["Spine"] = Vector3(-1.5 - breath * 0.8, sway * 0.5, sway * 0.4)
	pose["Chest"] = Vector3(1.5 + breath * 1.2, -sway * 0.4, -sway * 0.3)
	pose["Neck"] = Vector3(breath * 0.3, 0, 0)
	pose["Head"] = Vector3(-breath * 0.5, sway * 0.8, 0)
	pose["Shoulder_L"] = Vector3(0, 0, -breath * 0.7)
	pose["Shoulder_R"] = Vector3(0, 0, breath * 0.7)
	pose["UpperArm_L"] += Vector3(breath * 0.9, 0, -sway * 0.5)
	pose["UpperArm_R"] += Vector3(breath * 0.9, 0, -sway * 0.5)
	pose["Hair"] = Vector3(sin(t * TAU - 0.35) * 1.5, sway * 0.8, 0)
	pose["Cape"] = Vector3(-2 + sin(t * TAU - 0.4) * 1.2, 0, sway * 0.6)
	pose["CapeTip"] = Vector3(sin(t * TAU - 0.9) * 2.0, 0, 0)
	return pose


static func _locomotion(t: float, running: bool) -> Dictionary:
	var phase := t * TAU
	var wave := sin(phase)
	var pose: Dictionary = {}
	var drop := -0.078 if running else -0.042
	var bounce := 0.023 if running else 0.009
	pose["height"] = drop + cos(phase * 2.0) * bounce
	pose["Hips"] = Vector3(0, wave * (4.5 if running else 2.2), wave * (2.6 if running else 1.6))
	pose["Spine"] = Vector3(-11.0 if running else -3.0, -wave * (5.0 if running else 2.5), -wave * 1.3)
	pose["Chest"] = Vector3(-3.0 if running else -0.5, -wave * (5.5 if running else 2.5), wave * 1.0)
	pose["Neck"] = Vector3(6.0 if running else 1.5, 0, 0)
	pose["Head"] = Vector3(4.0 if running else 1.5, wave * 1.1, -wave * 0.5)
	for side: String in ["L", "R"]:
		var offset := 0.0 if side == "L" else 0.5
		var cycle := fposmod(t + offset, 1.0)
		var leg := _leg_cycle(cycle, float(pose["height"]), running)
		var sign_value := -1.0 if side == "L" else 1.0
		pose["Thigh_" + side] = Vector3(leg.x, 0, sign_value * 1.0)
		pose["Shin_" + side] = Vector3(leg.y, 0, 0)
		pose["Foot_" + side] = Vector3(leg.z, 0, 0)
		# Opposite arm follows the forward leg. Elbows stay relaxed walking and
		# fold for the more compact, faster run silhouette.
		var arm_wave := -cos(cycle * TAU)
		pose["Shoulder_" + side] = Vector3(0, arm_wave * 2, sign_value * 2)
		pose["UpperArm_" + side] = Vector3(arm_wave * (36 if running else 18), sign_value * 4, sign_value * (11 if running else 7))
		pose["Forearm_" + side] = Vector3((62 if running else 15) + arm_wave * 7, 0, 0)
		pose["Hand_" + side] = Vector3(-8, sign_value * 3, 0)
	pose["Hair"] = Vector3((-13 if running else -4) + sin(phase - 0.6) * (5 if running else 2), -wave * 2, 0)
	pose["Cape"] = Vector3((-22 if running else -7) + sin(phase * 2 - 0.5) * (6 if running else 2), 0, wave * 2)
	pose["CapeTip"] = Vector3((-12 if running else -3) + sin(phase * 2 - 1.1) * (8 if running else 3), 0, -wave * 3)
	return pose


static func _leg_cycle(t: float, height: float, running: bool) -> Vector3:
	var stance := 0.43 if running else 0.61
	var reach := 0.34 if running else 0.23
	var ankle_z: float
	var ankle_lift := 0.0
	var world_pitch: float
	if t < stance:
		var progress := t / stance
		ankle_z = lerpf(-reach, reach, progress)
		world_pitch = _curve(progress, [0.0, 0.13, 0.66, 0.88, 1.0], [14.0, 0.0, 0.0, -18.0, -30.0])
	else:
		var progress := (t - stance) / (1.0 - stance)
		ankle_z = lerpf(reach, -reach, _smooth(progress))
		ankle_lift = sin(progress * PI) * (0.23 if running else 0.105)
		world_pitch = _curve(progress, [0.0, 0.30, 0.65, 0.90, 1.0], [-30.0, -12.0, -3.0, 14.0, 14.0])
	# Bake two-bone sagittal IK into local rotations. During stance the ankle
	# remains on the ground; swing clears it before the next heel contact.
	var drop := 0.94 + height - 0.070 - ankle_lift
	var upper_length := 0.45
	var lower_length := 0.42
	var distance_squared := drop * drop + ankle_z * ankle_z
	var knee_cos := clampf((distance_squared - upper_length * upper_length - lower_length * lower_length) / (2 * upper_length * lower_length), -1.0, 1.0)
	var knee := acos(knee_cos)
	var hip := atan2(-ankle_z, drop) + atan2(lower_length * sin(knee), upper_length + lower_length * cos(knee))
	var hip_degrees := rad_to_deg(hip)
	var knee_degrees := -rad_to_deg(knee)
	return Vector3(hip_degrees, knee_degrees, world_pitch - hip_degrees - knee_degrees)


static func _attack(t: float) -> Dictionary:
	var ready := _ready_pose()
	var anticipation := {
		"height": -0.06, "Hips": Vector3(0, -16, -3),
		"Spine": Vector3(-8, -12, -2), "Chest": Vector3(-3, -17, -3),
		"Head": Vector3(7, 26, 1),
		"UpperArm_R": Vector3(97, -43, 37), "Forearm_R": Vector3(49, 0, -17),
		"Hand_R": Vector3(-16, -10, 4),
		"UpperArm_L": Vector3(32, 25, -30), "Forearm_L": Vector3(52, 0, 8),
		"Thigh_L": Vector3(18, 0, -3), "Shin_L": Vector3(-29, 0, 0), "Foot_L": Vector3(11, 0, 0),
		"Thigh_R": Vector3(2, 0, 4), "Shin_R": Vector3(-14, 0, 0), "Foot_R": Vector3(12, 0, 0),
		"Cape": Vector3(-8, -6, 3), "CapeTip": Vector3(-4, -7, 0),
	}
	var strike := {
		"height": -0.045, "Hips": Vector3(0, 20, 4),
		"Spine": Vector3(-6, 19, 2), "Chest": Vector3(-5, 25, 4),
		"Head": Vector3(8, -39, -1),
		"UpperArm_R": Vector3(102, 47, -27), "Forearm_R": Vector3(12, 8, -13),
		"Hand_R": Vector3(5, 0, -8),
		"UpperArm_L": Vector3(-20, -10, -20), "Forearm_L": Vector3(38, 0, 0),
		"Thigh_L": Vector3(10, 0, -3), "Shin_L": Vector3(-21, 0, 0), "Foot_L": Vector3(11, 0, 0),
		"Thigh_R": Vector3(17, 0, 4), "Shin_R": Vector3(-27, 0, 0), "Foot_R": Vector3(10, 0, 0),
		"Hair": Vector3(-12, -12, -5), "Cape": Vector3(-19, 15, -4), "CapeTip": Vector3(-13, 19, 3),
	}
	var follow := strike.duplicate()
	follow["UpperArm_R"] = Vector3(70, 65, -42)
	follow["Forearm_R"] = Vector3(23, 12, -18)
	follow["Chest"] = Vector3(-1, 31, 3)
	return _pose_curve(t, [0.0, 0.25, 0.34, 0.47, 0.66, 1.0], [ready, anticipation, anticipation, strike, follow, ready])


static func _defend(t: float) -> Dictionary:
	var wave := sin(t * TAU)
	var pose := _ready_pose()
	pose["height"] = -0.05 + wave * 0.003
	pose["Spine"] = Vector3(-7 + wave * 0.7, -9, 0)
	pose["Chest"] = Vector3(-3, -5, 0)
	pose["Head"] = Vector3(8, 13, 0)
	pose["UpperArm_L"] = Vector3(76 + wave * 0.6, -22, -17)
	pose["Forearm_L"] = Vector3(63, 0, 8)
	pose["Hand_L"] = Vector3(4, -13, 15)
	pose["UpperArm_R"] = Vector3(68 + wave * 0.6, 28, 19)
	pose["Forearm_R"] = Vector3(67, 0, -13)
	pose["Hand_R"] = Vector3(-8, 10, -10)
	pose["Thigh_L"] = Vector3(16, 0, -3)
	pose["Shin_L"] = Vector3(-29, 0, 0)
	pose["Foot_L"] = Vector3(13, 0, 0)
	pose["Thigh_R"] = Vector3(12, 0, 3)
	pose["Shin_R"] = Vector3(-23, 0, 0)
	pose["Foot_R"] = Vector3(11, 0, 0)
	pose["Cape"] = Vector3(-6 + wave, 0, 0)
	pose["CapeTip"] = Vector3(-2 + cos(t * TAU) * 1.5, 0, 0)
	return pose


static func _cast(t: float) -> Dictionary:
	var ready := _ready_pose()
	var gather := {
		"height": -0.025, "Spine": Vector3(-5, -9, 0), "Chest": Vector3(-3, -12, 0),
		"Head": Vector3(7, 19, -2),
		"UpperArm_L": Vector3(51, -25, -29), "Forearm_L": Vector3(65, 0, 17),
		"Hand_L": Vector3(-12, 10, 25),
		"UpperArm_R": Vector3(63, 24, 12), "Forearm_R": Vector3(82, 0, -12),
		"Hand_R": Vector3(-21, -12, -14), "Cape": Vector3(-4, -5, 0),
	}
	var release := {
		"height": 0.006, "Spine": Vector3(-8, 8, 0), "Chest": Vector3(-5, 9, 0),
		"Head": Vector3(10, -15, 0),
		"UpperArm_R": Vector3(104, 3, 4), "Forearm_R": Vector3(5, 0, 0),
		"Hand_R": Vector3(-11, 0, 0),
		"UpperArm_L": Vector3(48, -18, -31), "Forearm_L": Vector3(47, 0, 18),
		"Hand_L": Vector3(-6, 12, 20),
		"Hair": Vector3(-8, -3, 0), "Cape": Vector3(-12, 5, 0), "CapeTip": Vector3(-8, 3, 0),
	}
	return _pose_curve(t, [0.0, 0.31, 0.45, 0.56, 0.68, 1.0], [ready, gather, gather, release, release, ready])


static func _channel(t: float) -> Dictionary:
	var wave := sin(t * TAU)
	var pose := _ready_pose()
	pose["height"] = -0.022 + wave * 0.004
	pose["Spine"] = Vector3(-4 - wave * 0.8, 0, 0)
	pose["Chest"] = Vector3(-1 + wave * 0.6, 0, 0)
	pose["Head"] = Vector3(7 + wave, 0, 0)
	pose["UpperArm_L"] = Vector3(58 + wave * 2.0, -20, -18)
	pose["UpperArm_R"] = Vector3(58 - wave * 2.0, 20, 18)
	pose["Forearm_L"] = Vector3(68 - wave, 0, 9)
	pose["Forearm_R"] = Vector3(68 + wave, 0, -9)
	pose["Hand_L"] = Vector3(-4, 23 + wave * 2, 11)
	pose["Hand_R"] = Vector3(-4, -23 - wave * 2, -11)
	pose["Hair"] = Vector3(sin(t * TAU - 0.4) * 2, 0, 0)
	pose["Cape"] = Vector3(-4 - wave * 2, 0, 0)
	pose["CapeTip"] = Vector3(-2 + sin(t * TAU - 0.7) * 3, 0, 0)
	return pose


static func _dash(t: float) -> Dictionary:
	var ready := _ready_pose()
	var crouch := {
		"height": -0.15, "Spine": Vector3(-19, 0, 0), "Chest": Vector3(-14, 0, 0),
		"Head": Vector3(24, 0, 0),
		"UpperArm_L": Vector3(-27, -10, -14), "Forearm_L": Vector3(44, 0, 0),
		"UpperArm_R": Vector3(-31, 10, 14), "Forearm_R": Vector3(33, 0, 0),
		"Thigh_L": Vector3(39, 0, -2), "Shin_L": Vector3(-70, 0, 0), "Foot_L": Vector3(31, 0, 0),
		"Thigh_R": Vector3(31, 0, 2), "Shin_R": Vector3(-63, 0, 0), "Foot_R": Vector3(32, 0, 0),
		"Hair": Vector3(-17, 0, 0), "Cape": Vector3(-29, 0, 0), "CapeTip": Vector3(-22, 0, 0),
	}
	var extension := {
		"height": -0.045, "Spine": Vector3(-25, 0, 0), "Chest": Vector3(-13, 0, 0),
		"Head": Vector3(29, 0, 0),
		"UpperArm_L": Vector3(-46, 0, -8), "Forearm_L": Vector3(23, 0, 0),
		"UpperArm_R": Vector3(-51, 0, 8), "Forearm_R": Vector3(21, 0, 0),
		"Thigh_L": Vector3(55, 0, -2), "Shin_L": Vector3(-71, 0, 0), "Foot_L": Vector3(16, 0, 0),
		"Thigh_R": Vector3(-30, 0, 2), "Shin_R": Vector3(-18, 0, 0), "Foot_R": Vector3(14, 0, 0),
		"Hair": Vector3(-35, 0, 0), "Cape": Vector3(-51, 0, 0), "CapeTip": Vector3(-33, 0, 0),
	}
	return _pose_curve(t, [0.0, 0.19, 0.38, 0.65, 1.0], [ready, crouch, extension, extension, ready])


static func _hit(t: float) -> Dictionary:
	var ready := _ready_pose()
	var recoil := {
		"height": -0.042, "Hips": Vector3(0, -4, 2),
		"Spine": Vector3(15, -7, 3), "Chest": Vector3(10, -8, 3),
		"Head": Vector3(-14, 4, -2),
		"UpperArm_L": Vector3(34, 0, -23), "Forearm_L": Vector3(30, 0, 0),
		"UpperArm_R": Vector3(38, 0, 23), "Forearm_R": Vector3(24, 0, 0),
		"Thigh_L": Vector3(12, 0, -2), "Shin_L": Vector3(-24, 0, 0), "Foot_L": Vector3(12, 0, 0),
		"Thigh_R": Vector3(12, 0, 2), "Shin_R": Vector3(-24, 0, 0), "Foot_R": Vector3(12, 0, 0),
		"Hair": Vector3(12, 0, -3), "Cape": Vector3(-10, 0, 0), "CapeTip": Vector3(6, 0, 0),
	}
	return _pose_curve(t, [0.0, 0.16, 0.35, 0.65, 1.0], [ready, recoil, recoil, _mix_pose(recoil, ready, 0.75), ready])


static func _death(t: float) -> Dictionary:
	var ready := _ready_pose()
	var stagger := _hit(0.25)
	var collapse := {
		"height": -0.42, "Hips": Vector3(29, -7, -4),
		"Spine": Vector3(13, 0, 0), "Chest": Vector3(8, 0, 0),
		"Head": Vector3(-12, 9, -6),
		"UpperArm_L": Vector3(13, 0, -37), "Forearm_L": Vector3(39, 0, 0),
		"UpperArm_R": Vector3(16, 0, 29), "Forearm_R": Vector3(27, 0, 0),
		"Thigh_L": Vector3(49, 0, -4), "Shin_L": Vector3(-78, 0, 0), "Foot_L": Vector3(17, 0, 0),
		"Thigh_R": Vector3(42, 0, 4), "Shin_R": Vector3(-67, 0, 0), "Foot_R": Vector3(19, 0, 0),
		"Hair": Vector3(22, 0, 0), "Cape": Vector3(-13, 0, 0), "CapeTip": Vector3(-7, 0, 0),
	}
	var fallen := {
		"height": -0.78, "Hips": Vector3(79, -5, -3),
		"Spine": Vector3(4, 0, 0), "Chest": Vector3(3, 0, 0),
		"Head": Vector3(-7, 16, -6),
		"UpperArm_L": Vector3(-7, -13, -39), "Forearm_L": Vector3(18, 0, 0),
		"Hand_L": Vector3(5, 5, 13),
		"UpperArm_R": Vector3(-9, 11, 31), "Forearm_R": Vector3(13, 0, 0),
		"Hand_R": Vector3(3, -5, -10),
		"Thigh_L": Vector3(8, 0, -5), "Shin_L": Vector3(-21, 0, 0), "Foot_L": Vector3(4, 0, 0),
		"Thigh_R": Vector3(13, 0, 5), "Shin_R": Vector3(-26, 0, 0), "Foot_R": Vector3(5, 0, 0),
		"Hair": Vector3(32, 0, 0), "Cape": Vector3(10, 0, 0), "CapeTip": Vector3(-13, 0, 0),
	}
	return _pose_curve(t, [0.0, 0.15, 0.31, 0.63, 0.86, 1.0], [ready, stagger, collapse, fallen, fallen, fallen])


static func _respawn(t: float) -> Dictionary:
	var ready := _ready_pose()
	var kneeling := {
		"height": -0.19, "Spine": Vector3(-19, 0, 0), "Chest": Vector3(-11, 0, 0),
		"Head": Vector3(15, 0, 0),
		"UpperArm_L": Vector3(23, 0, -14), "Forearm_L": Vector3(20, 0, 0),
		"UpperArm_R": Vector3(31, 0, 12), "Forearm_R": Vector3(25, 0, 0),
		"Thigh_L": Vector3(45, 0, -3), "Shin_L": Vector3(-86, 0, 0), "Foot_L": Vector3(41, 0, 0),
		"Thigh_R": Vector3(36, 0, 3), "Shin_R": Vector3(-70, 0, 0), "Foot_R": Vector3(34, 0, 0),
		"Cape": Vector3(-11, 0, 0), "CapeTip": Vector3(-6, 0, 0),
	}
	var rise := _mix_pose(kneeling, ready, 0.75)
	rise["height"] = 0.014
	rise["Chest"] = Vector3(-4, 0, 0)
	rise["Head"] = Vector3(3, 0, 0)
	return _pose_curve(t, [0.0, 0.22, 0.76, 1.0], [kneeling, kneeling, rise, ready])


static func _weapon_pose(clip: String, t: float, weapon: String, base_pose: Dictionary) -> Dictionary:
	if clip == "RESET":
		return base_pose
	var pose := base_pose.duplicate()
	var wave := sin(t * TAU)
	match weapon:
		"spear":
			if clip == "attack":
				pose = _spear_attack(t)
			elif clip in ["idle", "walk", "run", "defend"]:
				pose["Hips"] = Vector3(pose.get("Hips", Vector3.ZERO)) + Vector3(0, -9, 0)
				pose["Chest"] = Vector3(pose.get("Chest", Vector3.ZERO)) + Vector3(0, -7, 0)
				var hand_position := Vector3(0.19, -0.14, -0.15)
				var shaft_direction := Vector3(-0.85, 0.05, -0.52).normalized()
				if clip == "walk":
					hand_position += Vector3(wave * 0.005, cos(t * TAU * 2.0) * 0.006, wave * 0.008)
				elif clip == "run":
					hand_position = Vector3(0.19, -0.10, -0.09) + Vector3(0, wave * 0.008, wave * 0.014)
					shaft_direction = Vector3(-0.79, 0.46, -0.41).normalized()
				elif clip == "defend":
					hand_position = Vector3(0.16, -0.045, -0.19) + Vector3(0, wave * 0.003, 0)
					shaft_direction = Vector3(-0.97, 0.035, -0.24).normalized()
					pose["Head"] = Vector3(7 + wave * 0.4, 25, 0)
				_spear_hands(pose, hand_position, shaft_direction)
		"unarmed":
			if clip == "attack":
				pose = _unarmed_attack(t)
			elif clip == "idle":
				pose["Hips"] = Vector3(0, -6, 0)
				pose["Chest"] = Vector3(1 + wave * 0.7, -9, 0)
				pose["UpperArm_L"] = Vector3(18 + wave, -13, -10)
				pose["UpperArm_R"] = Vector3(24 - wave, 13, 8)
				pose["Forearm_L"] = Vector3(63, 0, 8)
				pose["Forearm_R"] = Vector3(58, 0, -8)
				pose["Hand_L"] = Vector3(-10, -12, 8)
				pose["Hand_R"] = Vector3(-10, 12, -8)
			elif clip in ["walk", "run"]:
				for side: String in ["L", "R"]:
					var side_sign := -1.0 if side == "L" else 1.0
					var arm: Vector3 = pose["UpperArm_" + side]
					arm.x *= 0.72 if clip == "walk" else 0.88
					arm.z = side_sign * (7.0 if clip == "walk" else 10.0)
					pose["UpperArm_" + side] = arm
					pose["Forearm_" + side] = Vector3(43 if clip == "walk" else 80, 0, -side_sign * 4)
					pose["Hand_" + side] = Vector3(-9, side_sign * 9, -side_sign * 4)
			elif clip == "defend":
				pose["Hips"] = Vector3(0, -9, 0)
				pose["Chest"] = Vector3(-4, -14, 0)
				pose["UpperArm_L"] = Vector3(24 + wave * 0.6, -13, -7)
				pose["UpperArm_R"] = Vector3(35 - wave * 0.6, 19, 9)
				pose["Forearm_L"] = Vector3(112, -2, 5)
				pose["Forearm_R"] = Vector3(98, 4, -5)
				pose["Hand_L"] = Vector3(-14, -12, 10)
				pose["Hand_R"] = Vector3(-12, 12, -10)
		_:
			if clip == "attack":
				pose = _sword_attack(t)
			elif clip == "idle":
				pose["UpperArm_R"] = Vector3(8 + wave * 0.6, 14, 11)
				pose["Forearm_R"] = Vector3(24, 0, -3)
				pose["Hand_R"] = Vector3(15, 7, -7)
			elif clip in ["walk", "run"]:
				var right_arm: Vector3 = pose["UpperArm_R"]
				right_arm.x = right_arm.x * 0.46 - (12 if clip == "run" else 0)
				right_arm.z = 13 if clip == "run" else 11
				pose["UpperArm_R"] = right_arm
				pose["Forearm_R"] = Vector3(32 if clip == "run" else 25, 0, -7)
				pose["Hand_R"] = Vector3(18 if clip == "run" else 13, 12, -8)
			elif clip == "defend":
				pose["UpperArm_R"] = Vector3(60 + wave * 0.5, 24, 9)
				pose["Forearm_R"] = Vector3(79, 0, -10)
				pose["Hand_R"] = Vector3(-38, 20, -18)
				pose["UpperArm_L"] = Vector3(29 + wave * 0.6, -17, -18)
				pose["Forearm_L"] = Vector3(72, 0, 6)
				pose["Hand_L"] = Vector3(-12, -9, 12)
	return pose


static func _sword_attack(t: float) -> Dictionary:
	# Three readable beats: coil, diagonal cut, then a decelerating follow-through.
	# This is presentation timing only; semantic markers never invoke gameplay.
	var ready := _weapon_pose("idle", 0.0, "sword", _idle(0.0))
	var coil := _attack(0.28)
	coil["UpperArm_R"] = Vector3(105, -42, 33)
	coil["Forearm_R"] = Vector3(61, -4, -12)
	coil["Hand_R"] = Vector3(-36, -12, 7)
	var strike := _attack(0.49)
	strike["UpperArm_R"] = Vector3(110, 42, -22)
	strike["Forearm_R"] = Vector3(13, 4, -8)
	strike["Hand_R"] = Vector3(4, -3, -12)
	var follow := _attack(0.66)
	follow["UpperArm_R"] = Vector3(61, 67, -37)
	follow["Forearm_R"] = Vector3(21, 5, -16)
	follow["Hand_R"] = Vector3(13, 8, -18)
	follow["Chest"] = Vector3(-1, 29, 3)
	return _pose_curve(t, [0.0, 0.23, 0.34, 0.46, 0.65, 0.82, 1.0], [ready, coil, coil, strike, follow, _mix_pose(follow, ready, 0.72), ready])


static func _unarmed_attack(t: float) -> Dictionary:
	# Compact straight punch with a protected off hand and elbow recovery.
	var ready := _weapon_pose("idle", 0.0, "unarmed", _idle(0.0))
	var coil := ready.duplicate()
	coil["height"] = -0.038
	coil["Hips"] = Vector3(0, -15, -1)
	coil["Spine"] = Vector3(-6, -10, 0)
	coil["Chest"] = Vector3(-3, -19, 0)
	coil["Head"] = Vector3(7, 37, 0)
	coil["UpperArm_R"] = Vector3(41, -13, 16)
	coil["Forearm_R"] = Vector3(106, 0, -4)
	coil["Hand_R"] = Vector3(-8, 6, -6)
	coil["UpperArm_L"] = Vector3(32, -15, -8)
	coil["Forearm_L"] = Vector3(111, 0, 7)
	coil["Thigh_L"] = Vector3(13, 0, -2)
	coil["Shin_L"] = Vector3(-23, 0, 0)
	coil["Foot_L"] = Vector3(10, 0, 0)
	coil["Thigh_R"] = Vector3(10, 0, 2)
	coil["Shin_R"] = Vector3(-20, 0, 0)
	coil["Foot_R"] = Vector3(10, 0, 0)
	var punch := coil.duplicate()
	punch["height"] = -0.023
	punch["Hips"] = Vector3(0, 14, 1)
	punch["Spine"] = Vector3(-7, 8, 0)
	punch["Chest"] = Vector3(-4, 17, 0)
	punch["Head"] = Vector3(8, -32, 0)
	punch["UpperArm_R"] = Vector3(90, 12, -6)
	punch["Forearm_R"] = Vector3(7, -2, -4)
	punch["Hand_R"] = Vector3(-7, 2, -4)
	punch["UpperArm_L"] = Vector3(37, -12, -8)
	punch["Forearm_L"] = Vector3(110, 0, 6)
	punch["Hair"] = Vector3(-9, -6, 0)
	punch["Cape"] = Vector3(-12, 11, 0)
	punch["CapeTip"] = Vector3(-6, 14, 0)
	var recoil := _mix_pose(punch, coil, 0.50)
	return _pose_curve(t, [0.0, 0.20, 0.29, 0.43, 0.52, 0.71, 1.0], [ready, coil, coil, punch, punch, recoil, ready])


static func _spear_attack(t: float) -> Dictionary:
	var ready := _idle(0.0)
	ready["Hips"] = Vector3(0, -9, 0)
	ready["Chest"] = Vector3(1.5, -7, 0)
	var coil := _defend(0.0)
	coil["height"] = -0.074
	coil["Hips"] = Vector3(0, -17, -1)
	coil["Spine"] = Vector3(-5, -13, 0)
	coil["Chest"] = Vector3(-2, -19, 0)
	coil["Head"] = Vector3(7, 43, 0)
	var thrust := coil.duplicate()
	thrust["height"] = -0.035
	thrust["Hips"] = Vector3(0, -20, 0)
	thrust["Spine"] = Vector3(-9, -14, 0)
	thrust["Chest"] = Vector3(-4, -24, 0)
	thrust["Head"] = Vector3(11, 51, 0)
	thrust["Hair"] = Vector3(-10, 6, 0)
	thrust["Cape"] = Vector3(-19, 4, 0)
	thrust["CapeTip"] = Vector3(-12, 7, 0)
	var pose := _pose_curve(t, [0.0, 0.22, 0.35, 0.47, 0.58, 0.78, 1.0], [ready, coil, coil, thrust, thrust, _mix_pose(thrust, ready, 0.75), ready])
	var main_ready := Vector3(0.19, -0.14, -0.15)
	var main_coil := Vector3(0.22, -0.20, 0.02)
	var main_thrust := Vector3(0.05, -0.10, -0.32)
	var main := _vector_curve(t, [0.0, 0.22, 0.35, 0.47, 0.58, 0.78, 1.0], [main_ready, main_coil, main_coil, main_thrust, main_thrust, main_thrust.lerp(main_ready, 0.75), main_ready])
	var dir_ready := Vector3(-0.85, 0.05, -0.52).normalized()
	var dir_coil := Vector3(-0.92, 0.10, -0.38).normalized()
	var dir_thrust := Vector3(-0.92, 0.035, -0.39).normalized()
	var direction := _vector_curve(t, [0.0, 0.22, 0.35, 0.47, 0.58, 0.78, 1.0], [dir_ready, dir_coil, dir_coil, dir_thrust, dir_thrust, dir_thrust.lerp(dir_ready, 0.75), dir_ready]).normalized()
	_spear_hands(pose, main, direction)
	return pose


static func _spear_hands(pose: Dictionary, hand_in_chest: Vector3, shaft_in_chest: Vector3) -> void:
	# The left wrist is solved from the actual animated right-hand grip. Chest and
	# hips twists therefore move both hands and shaft together, rather than making
	# a visually plausible pose that disconnects when the torso turns.
	var chest := _bone_transform(pose, "Chest")
	var hand_basis := chest.basis * Basis(Quaternion(Vector3.DOWN, shaft_in_chest.normalized()))
	var right_target := chest * hand_in_chest
	_solve_arm(pose, "R", right_target, hand_basis, chest.basis * Vector3(0.9, -0.35, 0.42))
	var right := _bone_transform(pose, "Hand_R")
	var support := right * GuWeaponRig.support_grip("spear")
	_solve_arm(pose, "L", support, hand_basis, chest.basis * Vector3(-0.9, -0.35, 0.35))


static func _solve_arm(pose: Dictionary, side: String, wrist: Vector3, wrist_basis: Basis, pole_hint: Vector3) -> void:
	var shoulder := _bone_transform(pose, "Shoulder_" + side)
	var arm_rest: Vector3 = BONE_RESTS["UpperArm_" + side]
	var origin := shoulder * arm_rest
	var toward := wrist - origin
	var distance := clampf(toward.length(), 0.018, 0.5195)
	var direction := toward.normalized()
	var upper_length := 0.27
	var lower_length := 0.25
	var along := (upper_length * upper_length - lower_length * lower_length + distance * distance) / (2.0 * distance)
	var bend := sqrt(maxf(0.0, upper_length * upper_length - along * along))
	var pole := pole_hint - direction * pole_hint.dot(direction)
	if pole.length_squared() < 0.000001:
		pole = direction.cross(Vector3.UP)
	var elbow := origin + direction * along + pole.normalized() * bend
	var upper_world := Basis(Quaternion(Vector3.DOWN, (elbow - origin).normalized()))
	var forearm_world := Basis(Quaternion(Vector3.DOWN, (wrist - elbow).normalized()))
	var upper_local := shoulder.basis.inverse() * upper_world
	var forearm_local := upper_world.inverse() * forearm_world
	var hand_local := forearm_world.inverse() * wrist_basis
	pose["UpperArm_" + side] = upper_local.get_euler() * (180.0 / PI)
	pose["Forearm_" + side] = forearm_local.get_euler() * (180.0 / PI)
	pose["Hand_" + side] = hand_local.get_euler() * (180.0 / PI)


static func _bone_transform(pose: Dictionary, bone: String) -> Transform3D:
	var angles: Vector3 = pose.get(bone, Vector3.ZERO)
	var position: Vector3 = BONE_RESTS[bone]
	if bone == "Hips":
		position.y += float(pose.get("height", 0.0))
	var local := Transform3D(Basis(Quaternion.from_euler(angles * (PI / 180.0))), position)
	var parent: String = BONE_PARENTS[bone]
	if parent.is_empty():
		return local
	return _bone_transform(pose, parent) * local


static func _vector_curve(t: float, times: Array, values: Array) -> Vector3:
	for index: int in range(times.size() - 1):
		if t <= float(times[index + 1]):
			var span := float(times[index + 1]) - float(times[index])
			var progress := clampf((t - float(times[index])) / span, 0.0, 1.0)
			var start: Vector3 = values[index]
			var finish: Vector3 = values[index + 1]
			return start.lerp(finish, _smooth(progress))
	return values[-1]


static func _pose_curve(t: float, times: Array, poses: Array) -> Dictionary:
	for index: int in range(times.size() - 1):
		if t <= float(times[index + 1]):
			var span := float(times[index + 1]) - float(times[index])
			var progress := clampf((t - float(times[index])) / span, 0.0, 1.0)
			return _mix_pose(poses[index], poses[index + 1], _smooth(progress))
	return poses[-1].duplicate()


static func _mix_pose(from: Dictionary, to: Dictionary, weight: float) -> Dictionary:
	var result: Dictionary = {}
	for bone: String in BONE_RESTS:
		var start: Vector3 = from.get(bone, Vector3.ZERO)
		var end: Vector3 = to.get(bone, Vector3.ZERO)
		result[bone] = start.lerp(end, weight)
	result["height"] = lerpf(float(from.get("height", 0.0)), float(to.get("height", 0.0)), weight)
	return result


static func _curve(t: float, times: Array, values: Array) -> float:
	for index: int in range(times.size() - 1):
		if t <= float(times[index + 1]):
			var span := float(times[index + 1]) - float(times[index])
			var progress := clampf((t - float(times[index])) / span, 0.0, 1.0)
			return lerpf(float(values[index]), float(values[index + 1]), _smooth(progress))
	return float(values[-1])


static func _smooth(value: float) -> float:
	return value * value * (3.0 - 2.0 * value)
