extends "res://tests/character_action_motion_review.gd"
## Sequences deliberately include entry, exit and interruptions. Capture
## at 30 FPS while advancing the actual view at 120 Hz between images.
const CLIPS := {
	"sword":{"label":"Đứng → vung kiếm → thu tay","seconds":1.2},
	"mine":{"label":"Lấy cuốc → khai khoáng → cất cuốc","seconds":1.4},
	"cancel":{"label":"Ngắt khai khoáng → đi → đổi hướng","seconds":1.2},
	"gather":{"label":"Hái lượm → thu tay → xoay người","seconds":1.4},
}

static func sequence(clip: String, time: float) -> Dictionary:
	var action := "idle"
	var clock := time
	var turn := 0
	match clip:
		"sword":
			if time>=.16 and time<.80: action="attack"; clock=time-.16
			elif time>=.80: clock=time-.80
		"mine":
			if time>=.12 and time<1.08: action="mine"; clock=time-.12
			elif time>=1.08: clock=time-1.08
		"cancel":
			if time<.36: action="mine"
			elif time<.78: action="walk"; clock=time-.36
			else: clock=time-.78; turn=2
		"gather":
			if time>=.12 and time<1: action="gather"; clock=time-.12
			elif time>=1: clock=time-1; turn=4
	return {"action":action,"time":clock,"turn":turn}

func _run() -> void:
	capture_prefix="concept43"
	root.content_scale_size=Vector2i(2560,900)
	root.size=Vector2i(2560,900)
	root.position=Vector2i(-1800,-1200)
	review_root=Node2D.new()
	root.add_child(review_root)
	var background := ColorRect.new()
	background.color=Color("354139")
	background.size=Vector2(2560,900)
	review_root.add_child(background)
	var title := _review_label("0.43 · LIÊN KẾT ĐỘNG TÁC",Vector2(0,18),2560,26)
	_review_label("Nam / Nữ · 8 hướng xuất phát · render trực tiếp bằng Godot",Vector2(0,55),2560,17)
	var overlays := []
	for body in range(2):
		for d in range(8):
			var actor := GuIllustratedCharacterView.new()
			review_root.add_child(actor)
			actor.configure(256,176)
			actor.position=Vector2(160+d*320,345+body*370)
			actor.set_active(false)
			var look := GuCharacterAppearance.default_data()
			look["body"]="male" if body==0 else "female"
			actor.set_appearance(look)
			review_views.append(actor)
			var layer := Layers.new()
			layer.actor=actor
			layer.position=actor.position
			layer.hide()
			review_root.add_child(layer)
			overlays.append(layer)
			direction_labels.append(_review_label("",Vector2(d*320,410+body*370),320,17))
	var metadata := {}
	for clip: String in CLIPS:
		var duration: float = CLIPS[clip]["seconds"]
		var frames := roundi(duration*30)
		var folder := "concept43_"+clip
		DirAccess.make_dir_recursive_absolute("res://artifacts/"+folder)
		for i in range(review_views.size()): review_views[i].present("idle",0,Vector2.DOWN.rotated((i%8)*PI/4))
		var frame_data := []
		for frame in range(frames):
			for substep in range(4):
				var time := (frame*4+substep)/120.0
				var sample := sequence(clip,time)
				for i in range(review_views.size()):
					var facing := Vector2.DOWN.rotated(((i%8)+int(sample["turn"]))*PI/4)
					review_views[i].present_smooth(sample["action"],sample["time"],facing,false,1.0/120,1 if sample["action"]=="walk" else 0)
			title.text="0.43 · %s · %02d / %02d" % [CLIPS[clip]["label"],frame+1,frames]
			var info := []
			for i in range(review_views.size()):
				var s := review_views[i].capture_pose()
				direction_labels[i].text=("Nam" if i<8 else "Nữ")+" · "+DIRECTION_LABELS[int(s["direction_index"])]
				info.append({"direction":s["direction_index"],"action":s["action"],"prop":s["held_prop"]})
			frame_data.append(info)
			await _save(folder+"/frame%03d" % frame)
			if frame in [6,12,24,30]:
				for layer: Layers in overlays: layer.show(); layer.queue_redraw()
				await _save(folder+"_bones_%02d" % frame)
				for layer in overlays: layer.hide()
		metadata[clip]={"frames":frames,"duration":duration,"label":CLIPS[clip]["label"],"states":frame_data}
	FileAccess.open("res://artifacts/concept43_native.json",FileAccess.WRITE).store_string(JSON.stringify({"captures":captures,"source":"native Godot renderer / 120 Hz smooth view sampled at 30 FPS","views":16,"clips":metadata},"  "))
	quit()
