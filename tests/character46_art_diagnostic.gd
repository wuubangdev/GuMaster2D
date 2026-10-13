extends SceneTree
class Plate extends Node2D:
	var snapshot: Dictionary
	var part := 0
	func _draw() -> void:
		var view := GuConceptCharacterArt.view_for(snapshot["appearance"],0)
		var pose: Dictionary = snapshot["source_pose"]
		var scale_factor := float(snapshot["scale"])
		if part==0:
			GuConceptCharacterArt._draw_body_core(self,view,pose,Vector2.ZERO,scale_factor,Color.WHITE)
			GuConceptCharacterArt._draw_part(self,view,"torso",pose,Vector2.ZERO,scale_factor,Color.WHITE)
		else:
			var key: String = ["","shoulder_L","sleeve_L","forearm_L"][part]
			GuConceptDirectionalParts.draw_piece(self,view,key,pose,Vector2.ZERO,scale_factor,Color.WHITE)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	root.size=Vector2i(1280,700)
	root.content_scale_size=root.size
	var bg := ColorRect.new(); bg.color=Color("303a34");bg.size=root.size;root.add_child(bg)
	var actor := GuIllustratedCharacterView.new();root.add_child(actor);actor.configure(256,440);actor.set_active(false)
	actor.present("attack",actor.duration("attack")*.16,Vector2.DOWN)
	actor.hide()
	for part in range(4):
		var plate := Plate.new();plate.part=part;plate.snapshot=actor.capture_pose();plate.material=actor.illustration.material
		plate.position=Vector2(120+part*310,630);root.add_child(plate)
		var label := Label.new();label.text=["Torso ownership","Shoulder stitch","Upper sleeve","Forearm"][part];label.position=Vector2(part*310+30,30);root.add_child(label)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/concept46_cuff_diagnostic.png")
	quit()
