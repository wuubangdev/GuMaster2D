extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var actor:=GuIllustratedCharacterView.new()
	root.add_child(actor)
	actor.configure(256,48)
	actor.set_active(false)
	var look:=GuCharacterAppearance.default_data()
	actor.set_appearance(look)
	var rows:=[]
	for d in [0,4,6]:
		for i in range(109,126):
			actor.present("run",actor.duration("run")*float(i)/240,Vector2.DOWN.rotated(d*PI/4))
			var p:Dictionary=actor.capture_pose()["source_pose"]
			rows.append({"d":d,"phase":float(i)/240,"torso":str(p["torso"]),"knee_R":str(p["leg_R"][1]),"knee_L":str(p["leg_L"][1]),"foot_L":str(p["leg_L"][2]),"foot_R":str(p["leg_R"][2]),"contact_L":p["foot_contact_L"],"contact_R":p["foot_contact_R"]})
	FileAccess.open("res://artifacts/character48_detail_probe.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"  "))
	quit()
