extends SceneTree
## Bake original modular geometry and named skeletal clips into editable .tscn and standard .glb.
func _initialize() -> void:
	_export.call_deferred()

func _export() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/characters")
	var summary: Array[Dictionary] = []
	for body in ["male","female"]:
		for weapon in ["sword","spear","unarmed"]:
			var model := GuCharacterModel.new()
			model.prefer_baked_assets = false
			root.add_child(model)
			var look := GuCharacterAppearance.default_data()
			look["body"] = body
			look["weapon"] = weapon
			if weapon == "spear":
				look["outfit"] = "crimson"
			elif weapon == "unarmed":
				look["outfit"] = "ivory"
			if body == "female":
				look["hair"] = "ponytail"
			model.set_appearance(look)
			model.blend_transitions = false
			model.set_motion("RESET",0,Vector2.UP)
			var count := model.triangle_count
			var bones := model.skeleton.get_bone_count()
			var surfaces := model.mesh_count
			var animation_count := model.animator.get_animation_list().size()
			_set_owners(model,model)
			# Baked assets must not regenerate duplicate children when instantiated in an editor.
			model.set_script(null)
			var scene := PackedScene.new()
			assert(scene.pack(model) == OK)
			var scene_path := "res://assets/characters/gu_"+str(body)+"_"+str(weapon)+".tscn"
			assert(ResourceSaver.save(scene,scene_path) == OK)
			var document := GLTFDocument.new()
			var state := GLTFState.new()
			assert(document.append_from_scene(model,state) == OK)
			var glb_path := "res://assets/characters/gu_"+str(body)+"_"+str(weapon)+".glb"
			assert(document.write_to_filesystem(state,glb_path) == OK)
			var loaded := GLTFState.new()
			assert(document.append_from_file(glb_path,loaded) == OK)
			var reimported := document.generate_scene(loaded)
			assert(reimported != null)
			var imported_skeleton := _find_skeleton(reimported)
			assert(imported_skeleton != null and imported_skeleton.get_bone_count() == bones)
			summary.append({"body":body,"weapon":weapon,"appearance":look,"triangles":count,"material_surfaces":surfaces,"bones":bones,"animations_including_reset":animation_count,"scene":scene_path,"glb":glb_path,"gltf_roundtrip_bones":imported_skeleton.get_bone_count()})
			reimported.free()
			if weapon=="sword":
				assert(DirAccess.copy_absolute(scene_path,"res://assets/characters/gu_"+str(body)+".tscn")==OK)
				assert(DirAccess.copy_absolute(glb_path,"res://assets/characters/gu_"+str(body)+".glb")==OK)
			model.free()
	var file := FileAccess.open("res://assets/characters/model_manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"generator":"tools/export_character_models.gd", "engine":Engine.get_version_info()["string"],"origin":"Original generated geometry; no third-party character assets", "models":summary},"  "))
	file.close()
	print("CHARACTER_EXPORT_OK ",JSON.stringify(summary))
	quit()

func _set_owners(node: Node, model: Node) -> void:
	for child in node.get_children():
		child.owner = model
		_set_owners(child,model)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null
