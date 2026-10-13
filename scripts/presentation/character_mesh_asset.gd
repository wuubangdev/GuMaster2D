class_name GuCharacterMeshAsset
extends Resource
## Production mesh content, independent of simulation and the live rig/animation clock.
## Native compressed resources share immutable meshes between world and portraits.

@export var revision: String = "art10"
@export var descriptor: Dictionary = {}
@export var rig_bones: PackedStringArray = PackedStringArray()
@export var rig_global_rests: Array[Transform3D] = []
@export var layer_meshes: Array[ArrayMesh] = []
@export var triangles: int = 0
@export var provenance: String = "Godot authoring mesh"

static func path_for(look: Dictionary) -> String:
	return "res://assets/characters/runtime/%s_%s_%s_%s.res" % [look["body"],look["outfit"],look["hair"],look["weapon"]]

static func packed_skin_weights(source: PackedFloat32Array) -> PackedFloat32Array:
	var result := source.duplicate()
	for vertex in range(source.size()/4):
		var sum := 0.0
		for influence in range(4):
			sum += maxf(0,source[vertex*4+influence])
		if not is_finite(sum) or sum<=0:
			continue
		var units := PackedInt32Array([0,0,0,0])
		var largest := 0
		var total := 0
		for influence in range(4):
			units[influence] = roundi(maxf(0,source[vertex*4+influence])/sum*65535.0)
			total += units[influence]
			if units[influence]>units[largest]:
				largest = influence
		units[largest] += 65535-total
		for influence in range(4):
			var value := units[influence]
			result[vertex*4+influence] = (value+.01)/65535.0 if value>0 and value<65535 else float(value)/65535.0
	return result

func is_compatible(look: Dictionary, rig: Skeleton3D) -> bool:
	return compatibility_error(look,rig).is_empty()

func compatibility_error(look: Dictionary, rig: Skeleton3D) -> String:
	if revision!="art10" or descriptor!=look or rig_bones.size()!=rig.get_bone_count() or rig_global_rests.size()!=rig.get_bone_count() or layer_meshes.is_empty():
		return "Descriptor/revision/rig array mismatch"
	for index in range(rig_bones.size()):
		if rig_bones[index]!=rig.get_bone_name(index) or not rig_global_rests[index].is_equal_approx(rig.get_bone_global_rest(index)):
			return "Bone rest/name mismatch at %d" % index
	var actual_triangles := 0
	for mesh in layer_meshes:
		if mesh==null or mesh.get_surface_count()!=1 or mesh.surface_get_material(0)==null:
			return "Missing mesh, single surface or material"
		var arrays := mesh.surface_get_arrays(0)
		var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL]!=null else PackedVector3Array()
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV]!=null else PackedVector2Array()
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		if positions.is_empty() or joints.size()!=positions.size()*4 or weights.size()!=joints.size():
			return "Invalid four-influence layout on "+mesh.resource_name
		if normals.size()!=positions.size() or uv.size()!=positions.size() or indices.is_empty() or indices.size()%3!=0:
			return "Invalid surface layout on "+mesh.resource_name
		for index in indices:
			if index<0 or index>=positions.size():
				return "Invalid triangle index on "+mesh.resource_name
		for vertex in range(positions.size()):
			if not positions[vertex].is_finite():
				return "Non-finite vertex on "+mesh.resource_name
			if not normals[vertex].is_finite() or absf(normals[vertex].length()-1)>.005 or not uv[vertex].is_finite():
				return "Invalid normal/UV on "+mesh.resource_name
			var total := 0.0
			for influence in range(4):
				var offset := vertex*4+influence
				if joints[offset]<0 or joints[offset]>=rig_bones.size() or not is_finite(weights[offset]) or weights[offset]<0:
					return "Invalid bone/weight on "+mesh.resource_name
				total += weights[offset]
			if absf(total-1)>2.0/65535.0:
				return "Weight total %.10f on %s vertex %d" % [total,mesh.resource_name,vertex]
		actual_triangles += arrays[Mesh.ARRAY_INDEX].size()/3
	return "Triangle count mismatch %d/%d" % [actual_triangles,triangles] if actual_triangles!=triangles else ""
