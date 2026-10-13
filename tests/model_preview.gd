extends SceneTree
func _initialize() -> void:
	if DisplayServer.get_name()=="headless" or not "--test-mode" in OS.get_cmdline_user_args():
		quit(2)
		return
	_run.call_deferred()
func _run() -> void:
	root.size = Vector2i(1280,800)
	root.content_scale_size = Vector2i(1280,800)
	root.title = "GuMaster — New Character Model"
	var back := ColorRect.new()
	back.color = Color("152023")
	back.size = Vector2(1280,800)
	root.add_child(back)
	for i in range(3):
		var view := GuCharacterViewport.new()
		view.configure(640,430)
		view.model.blend_transitions = false
		root.add_child(view)
		view.position = Vector2(215+i*420,640)
		var look := GuCharacterAppearance.default_data()
		if i == 1:
			look["body"] = "female"
			look["hair"] = "ponytail"
		view.set_appearance(look)
		view.present("idle",0,Vector2.DOWN if i < 2 else Vector2.UP)
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://artifacts/new_model_preview.png")
	print("MODEL_PREVIEW ",result)
	quit(result)
