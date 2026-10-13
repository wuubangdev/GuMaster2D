class_name GuCultivationPalette
extends RefCounted
## One immutable material shared by terrain and scenery, never character/UI.
static var _material: ShaderMaterial

static func environment() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = preload("res://assets/shaders/cultivation_palette.gdshader")
	return _material
