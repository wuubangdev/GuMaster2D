extends SceneTree
## Interactive test build: opens F6 immediately, leaves the window for human review.
## Run with -- --test-mode; applying a cosmetic look does not write the real player profile.
func _initialize() -> void:
	if not "--test-mode" in OS.get_cmdline_user_args():
		printerr("Interactive studio review requires -- --test-mode.")
		quit(2)
		return
	_open.call_deferred()

func _open() -> void:
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i(1280,800)
	root.title = "GuMaster2D — Pixel 2D 0.11 (Test)"
	var game: GameManager = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.hud.toggle_studio()
