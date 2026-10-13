extends "res://tests/concept_character_visual_smoke.gd"
## All review frames use the production CanvasItem renderer and shader.

class Layers extends Node2D:
	var actor: GuIllustratedCharacterView
	var mode := "bones"
	func _draw() -> void:
		var s := actor.capture_pose()
		var view := GuConceptCharacterArt.view_for(s["appearance"],int(s["direction_index"]))
		var pose: Dictionary = s["source_pose"]
		var factor := float(s["scale"])
		if mode=="bones":
			for side in ["L","R"]:
				for prefix in ["arm_","leg_"]:
					var joints: PackedVector2Array = pose[prefix+side]
					var points := PackedVector2Array()
					for point in joints: points.append(point*factor)
					draw_polyline(points,Color("e6b954"),1.25,true)
					for point in points: draw_circle(point,2,Color("e6b954"))
			return
		GuConceptCharacterArt._draw_body_core(self,view,pose,Vector2.ZERO,factor,Color.WHITE)
		GuConceptCharacterArt._draw_part(self,view,"torso",pose,Vector2.ZERO,factor,Color.WHITE)
		if mode=="body": return
		GuConceptCharacterArt._draw_part(self,view,"head",pose,Vector2(0,-7)*factor,factor,Color.WHITE)
		for side in ["L","R"]:
			var shift := Vector2(-23 if side=="L" else 23,0)*factor
			GuConceptDirectionalParts.draw_arm(self,s,view,side,pose,{},shift,factor,Color.WHITE)
			GuConceptDirectionalParts.draw_leg(self,view,side,pose,Vector2(0,10)*factor,factor,Color.WHITE)

func _run() -> void:
	capture_prefix="concept42"
	root.content_scale_size=Vector2i(2560,900)
	root.size=Vector2i(2560,900)
	root.position=Vector2i(-1800,-1200)
	review_root=Node2D.new()
	root.add_child(review_root)
	var background := ColorRect.new()
	background.color=Color("354139")
	background.size=Vector2(2560,900)
	review_root.add_child(background)
	var title := _review_label("0.42 · VUNG KIẾM / HÁI LƯỢM / KHAI KHOÁNG",Vector2(0,18),2560,26)
	_review_label("Nam / Nữ · 8 hướng · render trực tiếp bằng Godot",Vector2(0,55),2560,17)
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
			actor.present("idle",0,Vector2.DOWN.rotated(d*PI/4),true)
			review_views.append(actor)
			var layer := Layers.new()
			layer.actor=actor
			layer.position=actor.position
			layer.hide()
			review_root.add_child(layer)
			overlays.append(layer)
			_review_label(("Nam" if body==0 else "Nữ")+" · "+DIRECTION_LABELS[d],Vector2(d*320,410+body*370),320,17)
	for action in ["attack","gather","mine"]:
		var folder: String = "concept42_"+action
		DirAccess.make_dir_recursive_absolute("res://artifacts/"+folder)
		for frame in range(32):
			var phase := float(frame)/32
			title.text="0.42 · %s · frame %02d / 32 · %.2f s" % [action,frame+1,phase*GuCharacterAnimations.duration(action)]
			for i in range(review_views.size()):
				var actor := review_views[i]
				actor.present_smooth(action,phase*actor.duration(action),Vector2.DOWN.rotated((i%8)*PI/4),false,actor.duration(action)/32,0)
			await _save(folder+"/frame%03d" % frame)
			if frame in [5,11,16,24]:
				for layer: Layers in overlays:
					layer.mode="bones"
					layer.show()
					layer.queue_redraw()
				await _save(folder+"_bones_%02d" % frame)
				for layer in overlays: layer.hide()
		for i in range(review_views.size()): review_views[i].present("idle",0,Vector2.DOWN.rotated((i%8)*PI/4),true)
	var report := FileAccess.open("res://artifacts/concept42_native.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"captures":captures,"source":"native Godot live renderer / smooth playback","views":16,"frames_per_action":32},"  "))
	quit()
