class_name GuIllustratedCharacterCanvas
extends Node2D
## Shared source textures and per-frame indexed meshes; no private game clock.
var snapshot: Dictionary = {}

func _init() -> void:
	name = "IllustratedCharacterArt"
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	material = GuIllustratedCharacterArt.ink_material()

func _draw() -> void:
	GuIllustratedCharacterArt.draw(self,snapshot)
