extends SceneTree
## Resolve airborne diagonal knee velocity at decreasing sample intervals;
## a real branch discontinuity does not disappear as the interval shrinks.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var hashes := {}
	for path in ["scripts/presentation/concept_character_rig.gd","scripts/presentation/illustrated_character_art.gd"]:
		hashes[path]=FileAccess.get_sha256("res://"+path)
	var actor := GuIllustratedCharacterView.new()
	root.add_child(actor)
	actor.configure(256,48)
	actor.set_active(false)
	var rows := []
	var traces := []
	for direction in [3,5]:
		var side := "R" if direction==3 else "L"
		var start := .70 if direction==3 else .20
		for subdivisions in [12,120,1200,12000]:
			var previous := PackedVector2Array()
			var maximum := 0.0
			var max_foot := 0.0
			var max_angle := 0.0
			var peak := {}
			for frame in range(subdivisions+1):
				var phase: float = start+.05*float(frame)/subdivisions
				actor.present("walk",actor.duration("walk")*phase,Vector2.DOWN.rotated(direction*PI/4))
				var pose: Dictionary=actor.capture_pose()["source_pose"]
				var chain: PackedVector2Array=pose["leg_"+side]
				if not previous.is_empty():
					var step := chain[1].distance_to(previous[1])
					max_foot=maxf(max_foot,chain[2].distance_to(previous[2]))
					max_angle=maxf(max_angle,absf((previous[1]-previous[0]).angle_to(chain[1]-chain[0])))
					if step>maximum:
						maximum=step
						peak={"phase":phase,"hip":str(chain[0]),"knee":str(chain[1]),"sole":str(chain[2]),"contact":pose["foot_contact_"+side],"projection":str(pose["leg_projection_"+side])}
				if subdivisions==120: traces.append({"direction":direction,"phase":phase,"knee":str(chain[1]),"sole":str(chain[2])})
				previous=chain
			rows.append({"direction":direction,"side":side,"phase_step":.05/subdivisions,"max_knee_step":maximum,"max_foot_step":max_foot,"max_thigh_angle_step":max_angle,"peak":peak})
	FileAccess.open("res://artifacts/character48_diagonal_probe.json",FileAccess.WRITE).store_string(JSON.stringify({"rows":rows,"traces":traces,"source_sha256":hashes},"  "))
	print("CHARACTER48_DIAGONAL ",JSON.stringify(rows))
	quit()
