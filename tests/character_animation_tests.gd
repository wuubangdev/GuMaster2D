class_name GuCharacterAnimationTests
extends RefCounted
## Exercise actual AnimationPlayer bindings and clip transitions on the agreed
## skeleton, rather than only checking that the animation factory returns data.

const PARENTS: Dictionary = {
	"Hips": "", "Spine": "Hips", "Chest": "Spine", "Neck": "Chest", "Head": "Neck",
	"Shoulder_L": "Chest", "UpperArm_L": "Shoulder_L", "Forearm_L": "UpperArm_L", "Hand_L": "Forearm_L",
	"Shoulder_R": "Chest", "UpperArm_R": "Shoulder_R", "Forearm_R": "UpperArm_R", "Hand_R": "Forearm_R",
	"Thigh_L": "Hips", "Shin_L": "Thigh_L", "Foot_L": "Shin_L",
	"Thigh_R": "Hips", "Shin_R": "Thigh_R", "Foot_R": "Shin_R",
	"Hair": "Head", "Cape": "Chest", "CapeTip": "Cape",
}


static func run(check: Callable, scene_root: Node) -> void:
	var library := GuCharacterAnimations.create_library()
	var model := Node3D.new()
	model.name = "AnimationContractProbe"
	scene_root.add_child(model)
	var skeleton := Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	model.add_child(skeleton)
	for bone: String in GuCharacterAnimations.BONE_RESTS:
		skeleton.add_bone(bone)
		var index := skeleton.find_bone(bone)
		var parent_name: String = PARENTS[bone]
		if not parent_name.is_empty():
			skeleton.set_bone_parent(index, skeleton.find_bone(parent_name))
		var position: Vector3 = GuCharacterAnimations.BONE_RESTS[bone]
		skeleton.set_bone_rest(index, Transform3D(Basis.IDENTITY, position))
		skeleton.set_bone_pose_position(index, position)
	var animator := AnimationPlayer.new()
	animator.name = "AnimationPlayer"
	model.add_child(animator)
	animator.root_node = NodePath("..")
	animator.add_animation_library("", library)
	check.call(library.get_animation_list().size() == 12, "Modular hero library provides RESET and eleven action clips")
	for clip: StringName in library.get_animation_list():
		var animation := library.get_animation(clip)
		animator.play(clip, 0.0)
		animator.seek(animation.length * 0.5, true)
		animator.advance(0.0)
		var hips_index := skeleton.find_bone("Hips")
		var hips := skeleton.get_bone_pose_position(hips_index)
		var chest := skeleton.get_bone_pose_rotation(skeleton.find_bone("Chest"))
		check.call(hips.is_finite() and is_zero_approx(hips.x) and is_zero_approx(hips.z), "%s keeps skeletal translation finite and in place" % clip)
		var rotations_valid := true
		for bone_index: int in range(skeleton.get_bone_count()):
			var quaternion := skeleton.get_bone_pose_rotation(bone_index)
			rotations_valid = rotations_valid and quaternion.is_finite() and is_equal_approx(quaternion.length(), 1.0)
		check.call(rotations_valid, "%s applies finite normalized rotations to actual skeleton bones" % clip)
		if clip != &"RESET":
			check.call(not chest.is_equal_approx(Quaternion.IDENTITY), "%s actually reaches the declared Skeleton3D track target" % clip)
		if animation.loop_mode != Animation.LOOP_NONE:
			var seam_valid := true
			for track: int in range(animation.get_track_count()):
				if animation.track_get_type(track) == Animation.TYPE_ROTATION_3D:
					var first: Quaternion = animation.track_get_key_value(track, 0)
					var last: Quaternion = animation.track_get_key_value(track, animation.track_get_key_count(track) - 1)
					seam_valid = seam_valid and first.is_equal_approx(last)
			check.call(seam_valid, "%s loops without a rotation discontinuity" % clip)
	animator.play("death", 0.0)
	animator.seek(GuCharacterAnimations.duration("death"), true)
	animator.advance(0.0)
	var fallen_height := skeleton.get_bone_pose_position(skeleton.find_bone("Hips")).y
	animator.play("idle", 0.0)
	animator.seek(0.0, true)
	animator.advance(0.0)
	var standing_height := skeleton.get_bone_pose_position(skeleton.find_bone("Hips")).y
	check.call(fallen_height < 0.30 and standing_height > 0.95, "Switching death to idle restores standing height without a leftover pose")
	animator.play("RESET", 0.0)
	animator.advance(0.0)
	var rests_valid := true
	for bone: String in GuCharacterAnimations.BONE_RESTS:
		var index := skeleton.find_bone(bone)
		rests_valid = rests_valid and skeleton.get_bone_pose_position(index).is_equal_approx(GuCharacterAnimations.BONE_RESTS[bone])
		rests_valid = rests_valid and skeleton.get_bone_pose_rotation(index).is_equal_approx(Quaternion.IDENTITY)
	check.call(rests_valid, "RESET restores every local rest translation and rotation after playback")
	animator.play("walk", 0.0)
	animator.seek(GuCharacterAnimations.duration("walk") * 0.25, true)
	animator.advance(0.0)
	var walking_chest := skeleton.get_bone_pose_rotation(skeleton.find_bone("Chest"))
	animator.play("run", 0.0)
	animator.seek(GuCharacterAnimations.duration("run") * 0.25, true)
	animator.advance(0.0)
	var running_chest := skeleton.get_bone_pose_rotation(skeleton.find_bone("Chest"))
	check.call(not walking_chest.is_equal_approx(running_chest), "Running has a distinct forward lean and counter rotation rather than a sped-up walk")
	check.call(model.position.is_zero_approx(), "Playing the complete animation library never moves the gameplay model root")
	model.free()
