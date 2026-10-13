extends "res://tests/beast45_review.gd"
## Focused native plate after review widened toad support and webbed feet.
var strip: SubViewport
func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args():quit(2);return
	_run.call_deferred()
func save(name: String) -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var path:="res://artifacts/"+name+".png"
	strip.get_texture().get_image().save_png(path);captures.append(path)
func _run() -> void:
	root.size=Vector2i(960,640);root.content_scale_size=Vector2i(960,640);root.position=Vector2i(-1800,-1200)
	strip=SubViewport.new();strip.size=Vector2i(1920,200);strip.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(strip)
	stage=Node2D.new();strip.add_child(stage)
	var background:=ColorRect.new();background.color=Color("394239");background.size=Vector2(1920,200);stage.add_child(background)
	for d in range(8):
		var tile:=BeastTile.new();tile.species="toad";tile.heading=Vector2.DOWN.rotated(d*PI/4);tile.position=Vector2(d*240+120,133);tile.scale=Vector2.ONE*1.8;stage.add_child(tile);tiles.append(tile)
		label("Đầm độc thiềm · "+DIRECTIONS[d],Vector2(d*240+8,179),Vector2(224,20),12)
	for clip_name in ["idle","walk","windup","strike","hit","death"]:
		for tile in tiles:tile.clip=clip_name;tile.progress=.74 if clip_name=="windup" else .5;tile.sample=.37;tile.queue_redraw()
		await save("beast45_toad_"+clip_name)
	for clip_name in ["walk","attack"]:
		DirAccess.make_dir_recursive_absolute("res://artifacts/beast45_toad_"+clip_name+"_motion")
		for frame in range(24):
			for tile in tiles:
				tile.sample=float(frame)/24
				if clip_name=="walk":tile.clip="walk";tile.progress=0
				elif frame<16:tile.clip="windup";tile.progress=float(frame)/16
				else:tile.clip="strike";tile.progress=float(frame-16)/8
				tile.queue_redraw()
			await save("beast45_toad_"+clip_name+"_motion/frame%03d" % frame)
	# One refreshed complete idle plate incorporates the reviewed feet and
	# back-facing boar marks without rerendering all 64 actors for every frame.
	stage.free();tiles.clear();strip.size=Vector2i(1920,1720)
	stage=Node2D.new();strip.add_child(stage)
	var board_bg:=ColorRect.new();board_bg.color=Color("394239");board_bg.size=Vector2(1920,1720);stage.add_child(board_bg)
	label("CỔ GIỚI / QUÁI THÚ 0.45 · idle",Vector2(28,16),Vector2(1860,40),28)
	label("8 loài · 8 hướng · khớp nối & hình ảnh sau kiểm tra",Vector2(28,56),Vector2(1860,32),18)
	for row in range(Bestiary.all().size()):
		var species: String=Bestiary.all().keys()[row]
		for d in range(8):
			var tile:=Control.new();tile.position=Vector2(d*240,100+row*200);tile.size=Vector2(240,200);tile.clip_contents=true;stage.add_child(tile)
			var bg:=ColorRect.new();bg.color=Color("414a3e") if (d+row)%2==0 else Color("3b453a");bg.size=tile.size-Vector2(2,2);tile.add_child(bg)
			var art:=BeastTile.new();art.species=species;art.heading=Vector2.DOWN.rotated(d*PI/4);art.position=Vector2(120,133);art.scale=Vector2.ONE*(1.35 if Bestiary.species(species).get("elite",false) else 1.8);tile.add_child(art)
			label(Bestiary.species(species)["name"]+" · "+DIRECTIONS[d],Vector2(d*240+8,100+row*200+179),Vector2(224,20),12)
	await save("beast45_idle")
	FileAccess.open("res://artifacts/beast45_toad_native.json",FileAccess.WRITE).store_string(JSON.stringify({"captures":captures,"directions":8,"states":6,"motion_frames":48,"source":"final 0.45 toad anatomy / original eight-species plate preceded this review fix"},"  "))
	print("BEAST45_TOAD_NATIVE ",captures.size()," captures")
	quit()
