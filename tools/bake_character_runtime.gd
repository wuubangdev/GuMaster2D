extends SceneTree
## Bake all 36 authoring looks, or replace ONE look from an artist-exported GLB.
## --from-glb res://artist/model.glb --body male --outfit jade --hair topknot --weapon sword
var options: Dictionary = {}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for index in range(0,args.size(),2):
		if index+1>=args.size():
			printerr("Baker options require --name value pairs")
			quit(2)
			return
		options[args[index]] = args[index+1]
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/characters/runtime")
	if options.has("--from-glb"):
		var look := GuCharacterAppearance.default_data()
		for field in look:
			look[field] = str(options.get("--"+field,look[field]))
		if not GuCharacterAppearance.validate(look):
			printerr("Invalid appearance descriptor")
			quit(2)
			return
		var asset := _from_glb(str(options["--from-glb"]),look)
		if asset==null:
			quit(1)
			return
		_save(asset)
		_update_manifest(asset)
		print("CHARACTER_RUNTIME_ARTIST_OK ",GuCharacterMeshAsset.path_for(look))
		quit()
		return
	var manifest: Array[Dictionary] = []
	var model := GuCharacterModel.new()
	model.prefer_baked_assets = false
	root.add_child(model)
	for body in ["male","female"]:
		for outfit in ["jade","crimson","ivory"]:
			for hair in ["topknot","ponytail"]:
				for weapon in ["sword","spear","unarmed"]:
					model.set_appearance({"body":body,"outfit":outfit,"hair":hair,"weapon":weapon})
					var asset := _rig_asset(model,model.get_appearance())
					for instance in model.surfaces.get_children():
						asset.layer_meshes.append(instance.mesh)
					asset.triangles = model.triangle_count
					asset.provenance = "Original authoring mesh; tools/bake_character_runtime.gd"
					assert(asset.is_compatible(asset.descriptor,model.skeleton))
					_save(asset)
					manifest.append({"appearance":asset.descriptor,"path":GuCharacterMeshAsset.path_for(asset.descriptor),"triangles":asset.triangles,"layers":asset.layer_meshes.size(),"rig_bones":asset.rig_bones.size(),"sha256":FileAccess.get_sha256(GuCharacterMeshAsset.path_for(asset.descriptor))})
	model.free()
	var file := FileAccess.open("res://assets/characters/runtime/manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"revision":"art10","rig_contract":"GuHumanoid/1","generator":"tools/bake_character_runtime.gd","assets":manifest},"  "))
	file.close()
	print("CHARACTER_RUNTIME_BAKE_OK ",manifest.size()," appearance assets")
	quit()

func _save(asset: GuCharacterMeshAsset) -> void:
	assert(ResourceSaver.save(asset,GuCharacterMeshAsset.path_for(asset.descriptor),ResourceSaver.FLAG_COMPRESS)==OK)

func _update_manifest(asset: GuCharacterMeshAsset) -> void:
	var path := "res://assets/characters/runtime/manifest.json"
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {"revision":"art10","rig_contract":"GuHumanoid/1","assets":[]}
	var record := {"appearance":asset.descriptor,"path":GuCharacterMeshAsset.path_for(asset.descriptor),"triangles":asset.triangles,"layers":asset.layer_meshes.size(),"rig_bones":asset.rig_bones.size(),"sha256":FileAccess.get_sha256(GuCharacterMeshAsset.path_for(asset.descriptor)),"provenance":asset.provenance}
	var replaced := false
	for index in range(data["assets"].size()):
		if data["assets"][index]["appearance"]==asset.descriptor:
			data["assets"][index] = record
			replaced = true
	if not replaced:
		data["assets"].append(record)
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"  "))
	file.close()

func _rig_asset(model: GuCharacterModel, look: Dictionary) -> GuCharacterMeshAsset:
	var asset := GuCharacterMeshAsset.new()
	asset.descriptor = look.duplicate(true)
	for index in range(model.skeleton.get_bone_count()):
		asset.rig_bones.append(model.skeleton.get_bone_name(index))
		asset.rig_global_rests.append(model.skeleton.get_bone_global_rest(index))
	return asset

func _from_glb(path: String, look: Dictionary) -> GuCharacterMeshAsset:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	if document.append_from_file(path,state)!=OK:
		printerr("Could not read artist GLB: ",path)
		return null
	var imported := document.generate_scene(state)
	if imported==null:
		printerr("Could not construct artist GLB scene")
		return null
	root.add_child(imported)
	var reference := GuCharacterModel.new()
	var source := _skeleton(imported)
	if source==null or source.get_bone_count()!=22:
		printerr("Artist GLB must preserve the 22-bone rig")
		imported.free()
		reference.free()
		return null
	for index in range(22):
		var name := reference.skeleton.get_bone_name(index)
		var other := source.find_bone(name)
		if other<0 or not (source.global_transform*source.get_bone_global_rest(other)).origin.is_equal_approx(reference.skeleton.get_bone_global_rest(index).origin):
			printerr("Artist bone rest/unit differs: ",name)
			imported.free()
			reference.free()
			return null
	var asset := _rig_asset(reference,look)
	asset.provenance = "Artist GLB: "+path+" SHA256="+FileAccess.get_sha256(path)
	var instances: Array[MeshInstance3D] = []
	_meshes(imported,instances)
	var valid := true
	for instance in instances:
		if instance.skin==null or instance.mesh==null:
			continue
		var remap: Array[int] = []
		for bind in range(instance.skin.get_bind_count()):
			var name := str(instance.skin.get_bind_name(bind))
			if name.is_empty():
				name = source.get_bone_name(instance.skin.get_bind_bone(bind))
			remap.append(reference.skeleton.find_bone(name))
		for surface in range(instance.mesh.get_surface_count()):
			var arrays := instance.mesh.surface_get_arrays(surface)
			if arrays[Mesh.ARRAY_VERTEX]==null or arrays[Mesh.ARRAY_NORMAL]==null or arrays[Mesh.ARRAY_TEX_UV]==null or arrays[Mesh.ARRAY_BONES]==null or arrays[Mesh.ARRAY_WEIGHTS]==null:
				printerr("Artist surface requires positions, normals, UV and four skin influences: ",instance.name)
				valid = false
				continue
			var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var transform := instance.global_transform
			if positions.is_empty() or normals.size()!=positions.size() or bones.size()!=positions.size()*4 or arrays[Mesh.ARRAY_WEIGHTS].size()!=bones.size() or transform.basis.determinant()<=0:
				printerr("Artist surface uses an unsupported mesh/skin or mirrored transform: ",instance.name)
				valid = false
				continue
			for vertex in range(positions.size()):
				positions[vertex] = transform*positions[vertex]
				normals[vertex] = (transform.basis.inverse().transposed()*normals[vertex]).normalized()
			for bind in range(bones.size()):
				if bones[bind]<0 or bones[bind]>=remap.size() or remap[bones[bind]]<0:
					valid = false
					break
				bones[bind] = remap[bones[bind]]
			arrays[Mesh.ARRAY_VERTEX] = positions
			arrays[Mesh.ARRAY_NORMAL] = normals
			arrays[Mesh.ARRAY_BONES] = bones
			# Generate UV-derived tangent frames even for solid artist materials.
			arrays[Mesh.ARRAY_TANGENT] = null
			if arrays[Mesh.ARRAY_INDEX]==null:
				var indices := PackedInt32Array()
				for vertex in range(positions.size()):
					indices.append(vertex)
				arrays[Mesh.ARRAY_INDEX] = indices
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			var material := instance.mesh.surface_get_material(surface)
			if material==null:
				printerr("Artist surface has no material: ",instance.name)
				valid = false
				continue
			var surface_tool := SurfaceTool.new()
			surface_tool.create_from(mesh,0)
			surface_tool.generate_tangents()
			mesh = surface_tool.commit()
			var final_arrays := mesh.surface_get_arrays(0)
			final_arrays[Mesh.ARRAY_WEIGHTS] = GuCharacterMeshAsset.packed_skin_weights(final_arrays[Mesh.ARRAY_WEIGHTS])
			mesh = ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,final_arrays)
			var key := material.resource_name.trim_prefix("Gu_")
			while key.right(1).is_valid_int():
				key = key.left(key.length()-1)
			mesh.resource_name = "Gu_"+key
			mesh.surface_set_material(0,material)
			asset.layer_meshes.append(mesh)
			asset.triangles += final_arrays[Mesh.ARRAY_INDEX].size()/3
	var mismatch := asset.compatibility_error(look,reference.skeleton)
	valid = valid and mismatch.is_empty()
	imported.free()
	reference.free()
	if not valid:
		printerr("Artist mesh has incompatible skin/geometry: ",mismatch)
		return null
	return asset

func _skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _skeleton(child)
		if found!=null:
			return found
	return null

func _meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_meshes(child,result)
