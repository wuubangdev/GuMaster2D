extends "res://tests/concept_character_visual_smoke.gd"
## Body-only and exploded proofs use the same live renderer, no bitmap edits.

class Parts extends Node2D:
	var actor: GuIllustratedCharacterView
	var exploded := false
	var core_only := false
	func _draw() -> void:
		var snapshot := actor.capture_pose()
		var look: Dictionary = snapshot["appearance"]
		var direction := int(snapshot["direction_index"])
		var view := GuConceptCharacterArt.view_for(look,direction)
		var pose: Dictionary = snapshot["source_pose"]
		var factor := float(snapshot["scale"])
		GuConceptCharacterArt._draw_body_core(self,view,pose,Vector2.ZERO,factor,Color.WHITE)
		if core_only: return
		GuConceptCharacterArt._draw_part(self,view,"torso",pose,Vector2.ZERO,factor,Color.WHITE)
		if not exploded: return
		GuConceptCharacterArt._draw_part(self,view,"head",pose,Vector2(0,-10)*factor,factor,Color.WHITE)
		for side in ["L","R"]:
			var x := -26.0 if side=="L" else 26.0
			GuConceptCharacterArt._held_arm(self,snapshot,view,side,pose,{},Vector2(x,0)*factor,factor,Color.WHITE)
			GuConceptCharacterArt._seam(self,view,"leg_"+side,pose["leg_"+side],Vector2(0,12)*factor,factor,Color.WHITE)
			GuConceptCharacterArt._draw_part(self,view,"leg_"+side,pose,Vector2(0,12)*factor,factor,Color.WHITE)

func _run() -> void:
	capture_prefix="concept37"
	root.content_scale_size=Vector2i(1280,800)
	root.size=Vector2i(1280,800)
	root.position=Vector2i(-1800,-1200)
	review_root=Node2D.new()
	root.add_child(review_root)
	var background := ColorRect.new()
	background.color=Color("354139")
	background.size=Vector2(1280,800)
	review_root.add_child(background)
	var title := _review_label("THÂN RIÊNG · KHÔNG CÓ TAY / CHÂN",Vector2(0,14),1280,24)
	_review_label("Render bằng cùng mesh và shader trong game · 16 asset thân riêng theo góc nhìn",Vector2(0,51),1280,16)
	var actors := []
	var pieces := []
	var labels := []
	for body in range(2):
		for d in range(8):
			var actor := GuIllustratedCharacterView.new()
			review_root.add_child(actor)
			actor.configure(256,128)
			actor.position=Vector2(80+d*160,335+body*320)
			actor.set_active(false)
			var look := GuCharacterAppearance.default_data()
			look["body"]="male" if body==0 else "female"
			look["weapon"]="unarmed"
			actor.set_appearance(look)
			actor.present("idle",0,Vector2.DOWN.rotated(d*PI/4),true)
			actor.illustration.hide()
			actors.append(actor)
			var part := Parts.new()
			part.actor=actor
			part.position=actor.position
			part.material=GuConceptCharacterArt.material_for(look)
			review_root.add_child(part)
			pieces.append(part)
			labels.append(_review_label(("Nam" if body==0 else "Nữ")+" · "+DIRECTION_LABELS[d],Vector2(d*160,349+body*320),160,15))
	await _save(capture_prefix+"_body_only")
	for part in pieces:
		part.core_only=true
		part.queue_redraw()
	title.text="ASSET VẢI VECTOR · LỚP RIÊNG DƯỚI CONCEPT"
	await _save(capture_prefix+"_vector_cloth")
	var framebuffer := root.get_texture().get_image()
	var probes := []
	var passed := true
	for i in range(actors.size()):
		var look: Dictionary = actors[i].appearance
		var reference := GuConceptCharacterArt.view_for(look,i%8)
		var source := Vector2(float(reference["ground"][0]),float(reference["ground"][1])-100)
		var native := (source-GuConceptCharacterArt._point(reference["ground"]))*float(reference["scale"])
		var at := Vector2i(actors[i].position+native*2)
		var actual := framebuffer.get_pixelv(at)
		var asset: Dictionary = reference["modular_art"]["coat"]
		var bounds: Array = asset["bounds"]
		var pigment := (load(asset["path"]) as Texture2D).get_image()
		var uv := (native-Vector2(bounds[0],bounds[1]))/Vector2(bounds[2],bounds[3])
		var expected := pigment.get_pixelv(Vector2i(uv*Vector2(pigment.get_size())))
		var error := maxf(absf(actual.r-expected.r),maxf(absf(actual.g-expected.g),absf(actual.b-expected.b)))
		passed=passed and error<.08
		probes.append({"body":look["body"],"direction":i%8,"rgb_error":error})
	var report := FileAccess.open("res://artifacts/concept37_cloth_gpu.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"passed":passed,"sampler":"explicit SVG cloth atlas","views":probes},"  "))
	report.close()
	assert(passed,"All 16 SVG coats render their actual cloth pigment, not an unbound white mesh")
	for part in pieces:
		part.core_only=false
		part.queue_redraw()
	title.text="TÁCH LỚP · THÂN / TAY ÁO / CẲNG TAY / BÀN TAY / CHÂN"
	for i in range(actors.size()):
		if i%2==1:
			pieces[i].hide()
			labels[i].hide()
			continue
		pieces[i].exploded=true
		pieces[i].position.x=160+(i%8)/2*320
		pieces[i].queue_redraw()
		labels[i].position.x=(i%8)/2*320
		labels[i].position.y+=30
		labels[i].size.x=320
	await _save(capture_prefix+"_parts_exploded")
	quit()
