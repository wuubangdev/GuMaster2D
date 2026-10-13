extends "res://tests/concept_character_visual_smoke.gd"
## Native detail captures: render larger, never resize a screenshot.

func _run() -> void:
	capture_prefix="concept30"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-prefix="): capture_prefix=argument.trim_prefix("--capture-prefix=")
	root.content_scale_size=Vector2i(1280,800)
	root.size=Vector2i(1280,800)
	if "--capture-offscreen" in OS.get_cmdline_user_args(): root.position=Vector2i(-1800,-1200)
	review_root=Node2D.new()
	root.add_child(review_root)
	var background := ColorRect.new()
	background.color=Color("354139")
	background.size=Vector2(1280,800)
	review_root.add_child(background)
	var title := _review_label("TAY ÁO · NHỊP TAY / CHÂN",Vector2(0,14),1280,24)
	_review_label("Render chi tiết trực tiếp bằng Godot · cùng rig và shader trong game",Vector2(0,51),1280,16)
	var actors := []
	for body in range(2):
		for d in [0,2,4,6]:
			var view := GuIllustratedCharacterView.new()
			review_root.add_child(view)
			view.configure(256,192)
			view.position=Vector2(160+(actors.size()%4)*320,390+body*370)
			var look := GuCharacterAppearance.default_data()
			look["body"]="male" if body==0 else "female"
			view.set_appearance(look)
			view.set_active(false)
			actors.append(view)
			_review_label(("Nam" if body==0 else "Nữ")+" · "+DIRECTION_LABELS[d],Vector2((actors.size()-1)%4*320,399+body*370),320,15)
	var combat_detail := "--combat-detail" in OS.get_cmdline_user_args()
	for action in (["attack"] if combat_detail else ["walk","run","defend","channel"]):
		for frame in range(8):
			# Include exact load/contact/follow poses rather than stepping over
			# the contact at .34 when reviewing the weapon arm.
			var phase: float = [0.0,.16,.25,.34,.44,.56,.75,1.0][frame] if combat_detail else float(frame)/8
			title.text="TAY ÁO / CỔ TAY · "+action.to_upper()+" · PHA %.3f" % phase
			for i in range(actors.size()):
				actors[i].present(action,actors[i].duration(action)*phase,Vector2.DOWN.rotated([0,2,4,6][i%4]*PI/4))
			await _save(capture_prefix+"_detail_"+action+"_%02d" % frame)
	quit()
