extends SceneTree
## Run after a cold import in a clean copy without .godot or artifacts.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var model := GuCharacterModel.new()
	root.add_child(model)
	var count := 0
	var artist := 0
	for body in ["male","female"]:
		for outfit in ["jade","crimson","ivory"]:
			for hair in ["topknot","ponytail"]:
				for weapon in ["sword","spear","unarmed"]:
					model.set_appearance({"body":body,"outfit":outfit,"hair":hair,"weapon":weapon})
					assert(model.geometry_source=="baked" and model.geometry_asset!=null)
					assert(model.geometry_asset.is_compatible(model.appearance,model.skeleton))
					for instance in model.surfaces.get_children():
						var material := instance.mesh.surface_get_material(0) as StandardMaterial3D
						assert(material!=null)
						for texture in [material.albedo_texture,material.normal_texture]:
							if texture!=null:
								assert(texture.get_image()!=null and not texture.get_image().is_empty())
					if model.geometry_asset.provenance.begins_with("Artist GLB:"):
						artist += 1
					count += 1
	model.free()
	assert(count==36 and artist>=1)
	print("RUNTIME_PORTABILITY_OK ",count," baked appearances, ",artist," artist resource; clean cache and no artifacts")
	quit()
