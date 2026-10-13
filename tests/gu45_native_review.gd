extends "res://tests/polish_visual_smoke.gd"
## Native catalog + effect timeline, followed by four actual numeric input casts.
var checks: Array[Dictionary] = []
var failures := 0

class ArtBoard extends Node2D:
	var mode := "icons"
	var phase_value := .3
	func _draw() -> void:
		var font := GuPixelUI.HAND_FONT
		var names := ["Nguyệt Quang Cổ","Bạch Ngọc Cổ","Bạch Hạc Cổ","Băng Tằm Cổ"]
		for i in range(4):
			var x := 160.0+i*320
			var kind: String = GuSkillArt.KINDS[i]
			if mode=="icons":
				GuSkillArt.draw(self,kind,Vector2(x,250),94)
				GuPixelUI.brush_fill(self,Rect2(x-49,414,98,76),Color("292f29"),i,0)
				GuSkillArt.draw(self,kind,Vector2(x-22,452),16)
				GuSkillArt.draw(self,kind,Vector2(x+24,452),24)
				GuSkillArt.draw(self,kind,Vector2(x,596),48,Color(.38,.38,.38))
				draw_string(font,Vector2(x-145,382),names[i],HORIZONTAL_ALIGNMENT_CENTER,290,22,Color("dcd7b7"))
				draw_string(font,Vector2(x-145,521),"32px / 48px • thanh kỹ năng",HORIZONTAL_ALIGNMENT_CENTER,290,16,Color("9ca792"))
				draw_string(font,Vector2(x-145,681),"Cổ đói / thiếu chân nguyên",HORIZONTAL_ALIGNMENT_CENTER,290,16,Color("9ca792"))
			else:
				GuSkillArt.draw(self,kind,Vector2(x,151),27)
				draw_string(font,Vector2(x-145,202),names[i],HORIZONTAL_ALIGNMENT_CENTER,290,20,Color("dcd7b7"))
				var samples := [phase_value] if mode=="motion" else [.12,.32,.50,.74,.92]
				for n in range(samples.size()):
					var p: float = samples[n]
					if mode=="motion": p=clampf(p*.64/[.52,.64,.38,.64][i],0,1)
					var at := Vector2(x-45,300+n*88 if mode!="motion" else 400)
					if i in [0,3]:
						var life := .52 if i==0 else .64
						var release := GuCharacterActionMotion.release_seconds("sword") if i==0 else .08
						var stage := WorldEffects.cast_stage(p*life,release,life)
						var q: float = stage["progress"]
						if stage["stage"]=="finished": continue
						var point := at
						var effect := "moon_charge" if i==0 else "frost_charge"
						if stage["stage"]=="flight":
							point=WorldEffects.flight_point(at,at+Vector2(90,0),q,i==3)
							effect="moon_blade" if i==0 else "ice_shard"
						elif stage["stage"]=="contact":
							point=at+Vector2(90,0)
							effect="moon_impact" if i==0 else "ice_impact"
						GuVectorEffectsArt.draw(self,effect,point,q)
					elif i==1:
						GuVectorEffectsArt.draw(self,"shield_cast",at+Vector2(45,0),p,Vector2.RIGHT,Color(1,1,1,minf(1,(1-p)*3)))
					else:
						var point := at+Vector2(p*90,0)
						GuVectorEffectsArt.draw(self,"dash_feather",point,p,Vector2.RIGHT,Color(1,1,1,(1-p)*.8))
						GuVectorEffectsArt.draw(self,"dash_wake",point,p,Vector2.RIGHT,Color(1,1,1,(1-p)*.65))
					if mode!="motion": draw_string(font,Vector2(x-144,at.y+5),"%d%%" % roundi(p*100),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("9ca792"))

func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless": quit(2); return
	root.size=Vector2i(1280,800)
	root.content_scale_size=Vector2i(1280,800)
	if "--capture-offscreen" in OS.get_cmdline_user_args(): root.position=Vector2i(-1800,-1200)
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks.append({"check":label,"passed":ok})
	if not ok: failures+=1; printerr("FAIL: ",label)

func snap(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/"+name+".png"
	check(root.get_texture().get_image().save_png(path)==OK,"Native capture "+name)
	records.append({"file":path,"renderer":"native Godot canvas"})

func _run() -> void:
	var board := CanvasLayer.new()
	board.layer=100
	root.add_child(board)
	var background := ColorRect.new()
	background.size=Vector2(1280,800)
	background.color=Color("222a27")
	board.add_child(background)
	var title := Label.new()
	title.text="CỔ LINH  /  NÉT MỰC & NGỌC"
	title.position=Vector2(38,30)
	title.add_theme_font_override("font",GuPixelUI.HAND_FONT)
	title.add_theme_font_size_override("font_size",32)
	board.add_child(title)
	var art := ArtBoard.new()
	board.add_child(art)
	if "--world-only" not in OS.get_cmdline_user_args(): await snap("gu45_icons")
	art.mode="timeline"
	title.text="THI TRIỂN  /  TỤ KHÍ → PHÓNG → TIẾP XÚC"
	art.queue_redraw()
	if "--world-only" not in OS.get_cmdline_user_args(): await snap("gu45_fx_board")
	DirAccess.make_dir_recursive_absolute("res://artifacts/gu45_fx")
	art.mode="motion"
	for frame in range(0 if "--world-only" in OS.get_cmdline_user_args() else 32):
		art.phase_value=frame/31.0
		art.queue_redraw()
		await snap("gu45_fx/frame%03d" % frame)
	board.queue_free()
	await process_frame
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.world_view.process_mode=Node.PROCESS_MODE_DISABLED
	game.hud.showing_intro=false
	for button in game.hud.skill_buttons: button.set_process(false)
	var names := ["moon","shield","dash","frost"]
	for slot in range(4):
		_fixture()
		_accept(slot)
		check(game.simulation.cooldowns[slot]>0,"Actual numeric input accepts "+names[slot])
		_step(.06)
		await snap("gu45_world_"+names[slot]+"_windup")
		_step(.18)
		await snap("gu45_world_"+names[slot]+"_release")
		_step(.08)
		await snap("gu45_world_"+names[slot]+"_contact")
	_fixture()
	_key(KEY_G)
	await process_frame
	await snap("gu45_gu_board")
	var output := FileAccess.open("res://artifacts/gu45_native_world.json" if "--world-only" in OS.get_cmdline_user_args() else "res://artifacts/gu45_native.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"passed":checks.size()-failures,"failed":failures,"checks":checks,"captures":records,"accepted_slots":accepted_slots},"  "))
	print("GU45_NATIVE ",checks.size()-failures,"/",checks.size()," captures=",records.size())
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)
