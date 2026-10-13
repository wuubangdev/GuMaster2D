extends "res://tests/test_runner.gd"
## Fast regression for the window/camera/input handoff on the expanded world.
func _run() -> void:
	root.size = Vector2i(1280,800)
	root.content_scale_size = root.size
	await process_frame
	await _test_rpg_windows()
	await _test_keyboard_controls()
	print("KEYBOARD_CHAIN45 ",results.size()-failures,"/",results.size())
	quit(1 if failures else 0)
