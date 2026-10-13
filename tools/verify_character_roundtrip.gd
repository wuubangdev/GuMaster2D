extends SceneTree
## Run after Blender --validate-only --roundtrip-dir artifacts/character_authoring_roundtrip.
## Direct GLB read verifies sources without depending on .godot import metadata.
func _initialize() -> void:
 var directory := "res://artifacts/character_authoring_roundtrip"
 var reports: Array[Dictionary] = []
 for body in ["male", "female"]:
  for weapon in ["sword", "spear", "unarmed"]:
   var path := directory + "/gu_" + str(body) + "_" + str(weapon) + ".glb"
   var document := GLTFDocument.new()
   var state := GLTFState.new()
   if document.append_from_file(path, state) != OK:
    push_error("Could not read Blender roundtrip: " + path)
    quit(1)
    return
   var scene := document.generate_scene(state)
   var bones: Skeleton3D = find_type(scene, "Skeleton3D")
   var player: AnimationPlayer = find_type(scene, "AnimationPlayer")
   if bones == null or bones.get_bone_count() != 22 or player == null or player.get_animation_list().size() != 12:
    push_error("Bone or animation contract lost in roundtrip: " + path)
    quit(1)
    return
   for spec in GuCharacterModel.BONE_SPEC:
    if bones.find_bone(spec[0]) < 0:
     push_error("Bone name lost in roundtrip: " + str(spec[0]))
     scene.free()
     quit(1)
     return
   var mesh_stats := material_counts(scene)
   if mesh_stats.x < 6 or mesh_stats.y < 6:
    push_error("Embedded albedo/normal materials lost in roundtrip: " + path)
    scene.free()
    quit(1)
    return
   reports.append({"asset": path, "bones": bones.get_bone_count(), "clips": Array(player.get_animation_list()), "textured_albedos":mesh_stats.x,"normal_maps":mesh_stats.y})
   scene.free()
 print("CHARACTER_BLEND_GODOT_ROUNDTRIP_OK ",JSON.stringify(reports))
 quit()
func find_type(node: Node, kind: String) -> Node:
 if node.is_class(kind):
  return node
 for child in node.get_children():
  var found = find_type(child, kind)
  if found != null:
   return found
 return null

func material_counts(node: Node) -> Vector2i:
 var counts := Vector2i.ZERO
 if node is MeshInstance3D:
  for surface in range(node.mesh.get_surface_count()):
   var material := node.mesh.surface_get_material(surface) as StandardMaterial3D
   if material!=null:
    counts.x += 1 if material.albedo_texture!=null else 0
    counts.y += 1 if material.normal_enabled and material.normal_texture!=null else 0
 for child in node.get_children():
  counts += material_counts(child)
 return counts
