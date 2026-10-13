extends SceneTree
## Run after importing an extracted source package with no pre-existing .godot.
func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args():
		quit(2)
		return
	_run.call_deferred()

func _contains_3d(node: Node) -> bool:
	if node is Node3D or node is SubViewport:
		return true
	for child in node.get_children():
		if _contains_3d(child):
			return true
	return false

func _run() -> void:
	root.size = Vector2i(1280,800)
	await process_frame
	var view := GuPixelCharacterView.new()
	root.add_child(view)
	view.configure(256,48)
	var count := 0
	var records: Dictionary = GuPixelCharacterView.atlas_manifest()["appearances"]
	for key in records:
		var parts := str(key).split("_")
		var look := {"body":parts[0],"outfit":parts[1],"hair":parts[2],"weapon":parts[3]}
		view.set_appearance(look)
		view.present("attack",GuCharacterAnimations.duration("attack",look["weapon"])*.4,Vector2(1,-1))
		assert(view.current_frame_texture() != null and view.current_frame_texture().get_size() == Vector2(80,80))
		assert(view.visual_rect().has_point(view.hand_position()))
		assert(view.appearance == GuCharacterAppearance.sanitize(look))
		count += 1
	assert(count == 36)
	var game: GameManager = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	assert(not _contains_3d(game))
	assert(game.world_view.ground.uses_pixel_art())
	assert(game.world_view.ground.tiles.tile_set.tile_size == Vector2i(32,32))
	assert(GuPixelWolfArt.texture().get_size() == Vector2(2048,384))
	assert(GuPixelEffectsArt.texture() != null)
	assert(int(GuPixelEffectsArt.manifest()["frames"]) == 328)
	assert(GuPixelEffectsArt.region("ice_shard", 4, Vector2.LEFT).has_area())
	assert(game.hud.hp_bar is GuVitalBar)
	assert(game.hud.action_belt.get_global_rect().size.x < root.size.x * .5)
	assert(game.world_view.player_view.character_view is GuIllustratedCharacterView)
	assert(game.hud.portrait_doll.avatar is GuIllustratedCharacterView)
	assert(game.hud.character_doll.avatar is GuIllustratedCharacterView)
	var illustrated := GuIllustratedCharacterView.new()
	root.add_child(illustrated)
	illustrated.configure(256,48)
	for key in records:
		var parts := str(key).split("_")
		var look := {"body":parts[0],"outfit":parts[1],"hair":parts[2],"weapon":parts[3]}
		illustrated.set_appearance(look)
		for direction in range(8):
			illustrated.present("attack",.2,Vector2.DOWN.rotated(direction*PI/4))
			assert(not illustrated.capture_pose().is_empty())
	for key in GuIllustratedCharacterArt.manifest()["parts"]:
		assert(GuIllustratedCharacterArt.part_texture(key) != null)
	assert(GuIllustratedCharacterArt.manifest()["parts"].size()==155)
	assert(not illustrated.sprite.visible and illustrated.illustration.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR)
	assert(GuVectorEffectsArt.KINDS.size()==13)
	print("PIXEL_PORTABILITY_OK legacy 36-atlas appearances; native32px terrain; no3D")
	print("POLISH_PORTABILITY_OK 328 spell frames; compact HUD")
	print("VECTOR_PORTABILITY_OK 155 SVG parts; 216 modular looks; continuous rig; 13 vector effects")
	game.queue_free()
	view.queue_free()
	illustrated.queue_free()
	await process_frame
	quit()
