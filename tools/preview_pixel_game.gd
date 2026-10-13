extends SceneTree
## Native interactive pixel review. The real saved profile stays isolated.
func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args():
		printerr("Pixel review requires -- --test-mode.")
		quit(2)
		return
	_open.call_deferred()

func _open() -> void:
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i(1280,800)
	root.title = "GuMaster2D — Ink Drawing 2D 0.19 (Test)"
	var game: GameManager = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.hud.showing_intro = false
	game.hud.toast_left = 0.0
