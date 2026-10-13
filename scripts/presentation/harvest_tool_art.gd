class_name GuHarvestToolArt
extends RefCounted
## Original short prospecting pick. Rigid handle and steel head share the
## gripping palm transform; no copied game art or screen-fixed implement.
static func draw(canvas: CanvasItem, snapshot: Dictionary, offset: Vector2, factor: float, tint: Color) -> void:
	var pose: Dictionary = snapshot["source_pose"]
	var grip := offset+GuConceptCharacterArt.hand_position(snapshot)
	var angle := float(pose.get("tool_angle",0))
	var shaft := PackedVector2Array([grip+Vector2(0,3).rotated(angle)*factor,grip+Vector2(0,-11).rotated(angle)*factor])
	GuConceptInkStroke.draw(canvas,shaft,1.12*factor,Color("30291f")*tint)
	GuConceptInkStroke.draw(canvas,shaft,.70*factor,Color("9a7950")*tint)
	var head := PackedVector2Array()
	for p in [Vector2(-6,-8),Vector2(-4,-11.5),Vector2(-1,-12.5),Vector2(2,-12),Vector2(6,-9.8),Vector2(7,-7.8),Vector2(3,-9.9),Vector2(-1,-10.3),Vector2(-3.4,-9.7)]:
		head.append(grip+p.rotated(angle)*factor)
	canvas.draw_colored_polygon(head,Color("9dada8")*tint)
	head.append(head[0])
	GuConceptInkStroke.draw(canvas,head,.35*factor,Color("302b24")*tint)
	for y in [-2.0,0.0,2.0]:
		var binding := PackedVector2Array([grip+Vector2(-.5,y).rotated(angle)*factor,grip+Vector2(.5,y+.2).rotated(angle)*factor])
		GuConceptInkStroke.draw(canvas,binding,.28*factor,Color("493d2d")*tint)
