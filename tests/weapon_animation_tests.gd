class_name GuWeaponAnimationTests
extends RefCounted
## Probe the real AnimationPlayer and Skeleton3D, including interpolated keys.
## A static pose dictionary cannot establish that both hands remain on a spear.


static func run(check: Callable, scene_root: Node) -> void:
	var rig := Node3D.new()
	rig.name = "WeaponMotionContractProbe"
	scene_root.add_child(rig)
	var skeleton := Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	rig.add_child(skeleton)
	for bone: String in GuCharacterAnimations.BONE_RESTS:
		skeleton.add_bone(bone)
		var index := skeleton.find_bone(bone)
		var parent: String = GuCharacterAnimations.BONE_PARENTS[bone]
		if not parent.is_empty():
			skeleton.set_bone_parent(index, skeleton.find_bone(parent))
		var rest: Vector3 = GuCharacterAnimations.BONE_RESTS[bone]
		skeleton.set_bone_rest(index, Transform3D(Basis.IDENTITY, rest))
		skeleton.set_bone_pose_position(index, rest)
	var animator := AnimationPlayer.new()
	rig.add_child(animator)
	animator.root_node = NodePath("..")
	var snapshots: Dictionary = {}
	var attack_metrics: Dictionary = {}
	for weapon: String in GuWeaponRig.FAMILIES:
		var library := GuCharacterAnimations.create_library(weapon)
		if animator.has_animation_library(""):
			animator.remove_animation_library("")
		animator.add_animation_library("", library)
		check.call(library.get_animation_list().size() == 12 and library.get_meta("weapon_family") == weapon, "%s supplies exactly eleven semantic actions, RESET, and its weapon family" % weapon)
		check.call(GuCharacterAnimations.create_library(weapon) == library, "%s reuses immutable clips across portraits and live characters" % weapon)
		var finite_poses := true
		var loops_closed := true
		for clip: StringName in library.get_animation_list():
			var animation := library.get_animation(clip)
			_pose_at(animator, skeleton, clip, animation.length * 0.37)
			for bone_index: int in range(skeleton.get_bone_count()):
				var rotation := skeleton.get_bone_pose_rotation(bone_index)
				finite_poses = finite_poses and rotation.is_finite() and absf(rotation.length() - 1.0) < 0.0001
			var hips := skeleton.get_bone_pose_position(skeleton.find_bone("Hips"))
			finite_poses = finite_poses and hips.is_finite() and is_zero_approx(hips.x) and is_zero_approx(hips.z)
			if animation.loop_mode != Animation.LOOP_NONE:
				for track: int in range(animation.get_track_count()):
					if animation.track_get_type(track) == Animation.TYPE_ROTATION_3D:
						var first: Quaternion = animation.track_get_key_value(track, 0)
						var last: Quaternion = animation.track_get_key_value(track, animation.track_get_key_count(track) - 1)
						loops_closed = loops_closed and absf(first.dot(last)) > 0.99999
			if clip in ["idle", "walk", "run", "attack", "defend"]:
				snapshots[weapon + "/" + str(clip)] = [skeleton.get_bone_global_pose(skeleton.find_bone("Hand_R")), skeleton.get_bone_global_pose(skeleton.find_bone("Hand_L"))]
		check.call(finite_poses, "%s clips reach actual bones with finite normalized rotations and no gameplay XZ translation" % weapon)
		check.call(loops_closed, "%s closes every looping bone rotation at the end of the cycle" % weapon)
		var attack := library.get_animation("attack")
		var tip_positions: Array[Vector3] = []
		var wrist_positions: Array[Vector3] = []
		for sample: int in range(61):
			_pose_at(animator, skeleton, "attack", attack.length * float(sample) / 60.0)
			var hand := skeleton.get_bone_global_pose(skeleton.find_bone("Hand_R"))
			tip_positions.append(hand * GuWeaponRig.weapon_tip(weapon))
			wrist_positions.append(hand.origin)
		var tip_travel := 0.0
		var wrist_travel := 0.0
		for position: Vector3 in tip_positions:
			tip_travel = maxf(tip_travel, position.distance_to(tip_positions[0]))
		for position: Vector3 in wrist_positions:
			wrist_travel = maxf(wrist_travel, position.distance_to(wrist_positions[0]))
		attack_metrics[weapon] = {"tip_excursion_m": tip_travel, "wrist_excursion_m": wrist_travel}
		check.call(tip_positions[0].distance_to(tip_positions[-1]) < 0.001, "%s attack recovers the weapon or fist to its original ready stance" % weapon)
		check.call(attack.get_marker_time("visual_strike") > 0.0 and attack.get_marker_time("recovery") > attack.get_marker_time("visual_strike"), "%s exposes ordered strike and recovery markers without gameplay callbacks" % weapon)
		if weapon == "spear":
			for clip: String in GuWeaponRig.support_states(weapon):
				var animation := library.get_animation(clip)
				var maximum_error := 0.0
				for sample: int in range(121):
					_pose_at(animator, skeleton, clip, animation.length * float(sample) / 120.0)
					var right := skeleton.get_bone_global_pose(skeleton.find_bone("Hand_R"))
					var left := skeleton.get_bone_global_pose(skeleton.find_bone("Hand_L"))
					maximum_error = maxf(maximum_error, left.origin.distance_to(right * GuWeaponRig.support_grip(weapon)))
				check.call(maximum_error < 0.008, "Spear %s keeps the actual interpolated support wrist within 8 mm of its shaft anchor (%.4f m)" % [clip, maximum_error])
				check.call(animation.get_meta("support_grip_active", false) and float(animation.get_meta("baked_support_error_m", 1.0)) < 0.0001, "Spear %s records its support-grip contract and measured baked error" % clip)
		_pose_at(animator, skeleton, "RESET", 0.0)
		var reset_valid := true
		for bone: String in GuCharacterAnimations.BONE_RESTS:
			var index := skeleton.find_bone(bone)
			reset_valid = reset_valid and skeleton.get_bone_pose_rotation(index).is_equal_approx(Quaternion.IDENTITY)
			reset_valid = reset_valid and skeleton.get_bone_pose_position(index).is_equal_approx(GuCharacterAnimations.BONE_RESTS[bone])
		check.call(reset_valid, "%s RESET restores all twenty-two bone rotations and translations after weapon playback" % weapon)
	for clip: String in ["idle", "walk", "run", "attack", "defend"]:
		var different := true
		for pair: Vector2i in [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)]:
			var first: Array = snapshots[GuWeaponRig.FAMILIES[pair.x] + "/" + clip]
			var second: Array = snapshots[GuWeaponRig.FAMILIES[pair.y] + "/" + clip]
			different = different and (not first[0].is_equal_approx(second[0]) or not first[1].is_equal_approx(second[1]))
		check.call(different, "%s has distinct actual sword, spear, and unarmed hand poses" % clip)
	check.call(float(attack_metrics["sword"]["tip_excursion_m"]) > 0.65, "Sword attack makes a substantial blade arc with follow-through")
	check.call(float(attack_metrics["spear"]["tip_excursion_m"]) > 0.30, "Spear attack extends and turns the held shaft through a readable thrust")
	check.call(float(attack_metrics["unarmed"]["wrist_excursion_m"]) > 0.25, "Unarmed attack extends the fist through a readable punch")
	check.call(GuCharacterAnimations.create_library("invalid") == GuCharacterAnimations.create_library("sword"), "Unknown visual weapons resolve to the validated sword motion family")
	check.call(rig.position.is_zero_approx(), "Weapon motion playback never moves the gameplay model root")
	print("WEAPON_MOTION_METRICS ", JSON.stringify(attack_metrics))
	rig.free()


static func _pose_at(animator: AnimationPlayer, skeleton: Skeleton3D, clip: StringName, time: float) -> void:
	animator.play(clip, 0.0)
	animator.seek(time, true)
	animator.advance(0.0)
	skeleton.force_update_all_bone_transforms()
