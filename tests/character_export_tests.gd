extends RefCounted
## Validate all six deliverable GLBs directly, independent of imported .godot cache.
static func run(tree: SceneTree, check: Callable) -> void:
	for body in ["male","female"]:
		for weapon in ["sword","spear","unarmed"]:
			var label := str(body)+"/"+str(weapon)
			var document := GLTFDocument.new()
			var state := GLTFState.new()
			var path := "res://assets/characters/gu_%s_%s.glb" % [body,weapon]
			var loaded := document.append_from_file(path,state)
			check.call(loaded==OK, "Baked "+label+" GLB is readable without project import cache")
			if loaded!=OK:
				continue
			var scene := document.generate_scene(state)
			tree.root.add_child(scene)
			var skeleton := find_type(scene,"Skeleton3D") as Skeleton3D
			var animator := find_type(scene,"AnimationPlayer") as AnimationPlayer
			check.call(skeleton!=null and skeleton.get_bone_count()==22, "Exported "+label+" preserves the shared 22-bone skeleton")
			var clips_ok := animator!=null
			if animator!=null:
				for clip in GuCharacterAnimations.clip_names():
					clips_ok = clips_ok and animator.has_animation(clip)
				clips_ok = clips_ok and is_equal_approx(animator.get_animation("attack").length,GuCharacterAnimations.duration("attack",weapon))
			check.call(clips_ok, "Exported "+label+" preserves all eleven clips and the selected weapon attack duration")
			if animator!=null and skeleton!=null and animator.has_animation("attack"):
				animator.play("attack")
				animator.seek(GuCharacterAnimations.duration("attack",weapon)*.38,true)
				var arm := skeleton.find_bone("UpperArm_R")
				check.call(not skeleton.get_bone_pose_rotation(arm).is_equal_approx(Quaternion.IDENTITY), "Reimported "+label+" weapon arm responds to actual animation tracks")
			var meshes: Array[MeshInstance3D] = []
			find_meshes(scene,meshes)
			var textile_albedos := 0
			var normal_maps := 0
			var tangent_surfaces := 0
			for instance in meshes:
				for surface in range(instance.mesh.get_surface_count()):
					var material := instance.mesh.surface_get_material(surface) as StandardMaterial3D
					if material!=null:
						if material.albedo_texture!=null:
							textile_albedos += 1
						if material.normal_enabled and material.normal_texture!=null:
							normal_maps += 1
					var arrays := instance.mesh.surface_get_arrays(surface)
					if arrays[Mesh.ARRAY_TANGENT]!=null and arrays[Mesh.ARRAY_TANGENT].size()==arrays[Mesh.ARRAY_VERTEX].size()*4:
						tangent_surfaces += 1
			check.call(textile_albedos>=6 and normal_maps>=6 and tangent_surfaces>=6, "Reimported "+label+" retains embedded albedo/normal maps and textured tangent frames")
			scene.free()
			var packed := load("res://assets/characters/gu_%s_%s.tscn" % [body,weapon]) as PackedScene
			var baked: Node = packed.instantiate() if packed!=null else null
			if baked!=null:
				tree.root.add_child(baked)
			check.call(baked!=null and baked.get_child_count()==3 and find_type(baked,"Skeleton3D")!=null, "Editable "+label+" Godot scene opens without regenerating duplicate rig or mesh children")
			if baked!=null:
				baked.free()

static func find_type(node: Node, kind: String) -> Node:
	if node.is_class(kind):
		return node
	for child in node.get_children():
		var result := find_type(child,kind)
		if result!=null:
			return result
	return null

static func find_meshes(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		find_meshes(child,meshes)
