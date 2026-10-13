extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var actor := GuIllustratedCharacterView.new()
	tree.root.add_child(actor)
	actor.configure(256,48)
	actor.set_active(false)
	var samples := 0
	var connected := true
	var planted := true
	var neutral := true
	var continuous := true
	var max_foot_error := 0.0
	var max_hand_step := 0.0
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		for weapon in ["sword","spear","unarmed"]:
			look["weapon"]=weapon
			actor.set_appearance(look)
			for d in range(8):
				var facing := Vector2.DOWN.rotated(d*PI/4)
				var view := GuConceptCharacterArt.view_for(look,d)
				actor.present("idle",0,facing,true)
				var rest: Dictionary = actor.capture_pose()["source_pose"]
				for action in ["gather","mine"]:
					var previous := Vector2.INF
					for frame in range(97):
						actor.present(action,actor.duration(action,weapon)*frame/96.0,facing)
						var s := actor.capture_pose()
						var pose: Dictionary = s["source_pose"]
						connected=connected and s["action"]==action and actor.appearance==look
						for side in ["L","R"]:
							var source := GuConceptCharacterRig._joint_list(view,"arm_"+side)
							var chain: PackedVector2Array = pose["arm_"+side]
							for bone in range(2): connected=connected and absf(chain[bone].distance_to(chain[bone+1])-source[bone].distance_to(source[bone+1]))<.0001
							connected=connected and chain[0].distance_to(GuConceptCharacterRig.body_point(pose,source[0]))<.0001
							connected=connected and absf((chain[1]-chain[0]).angle_to(chain[2]-chain[1]))<=GuConceptCharacterRig.ARM_MAX_FLEX+.0001
							var source_leg := GuConceptCharacterRig._joint_list(view,"leg_"+side)
							var foot_error := Vector2(pose["leg_"+side][2]).distance_to(source_leg[2])
							max_foot_error=maxf(max_foot_error,foot_error)
							planted=planted and foot_error<.015
							if frame in [0,96]: neutral=neutral and chain[2].distance_to(rest["arm_"+side][2])<.02
						var hand: Vector2 = pose["grip_R"]
						if previous.is_finite(): max_hand_step=maxf(max_hand_step,hand.distance_to(previous))
						previous=hand
						if action=="mine": connected=connected and is_finite(float(pose["tool_angle"])) and absf(float(pose["weapon_wrist"]))<=.7+.0001
						samples+=1
	continuous=max_hand_step<3.0
	check.call(connected,"Harvest hands retain native arm lengths, shoulder anchors, bounded elbows and a rigid tool for both bodies, all eight views and every equipped weapon")
	check.call(planted,"Gathering and mining leave both feet planted through the full action")
	check.call(neutral and continuous,"Harvest gestures return to their neutral hand anchors without a snapped elbow or discontinuous hand path")
	var sim := LocalAuthority.new()
	var events: Array[Dictionary] = []
	for region in ["forest","ruins"]:
		sim.expedition.region=region
		sim.world=WorldGrid.new(region)
		for site in WorldContent.resources(region):
			sim.player["cell"]=WorldContent.cell(site)
			sim.drain_events()
			var accepted := sim.journey_command("gather",{"id":site["id"]})
			var reward_events := sim.drain_events().filter(func(e: Dictionary): return e["kind"]=="farm_harvest")
			check.call(accepted["ok"] and reward_events.size()==1 and reward_events[0].get("harvest_action","")==("mine" if site["material"] in ["ore","stone"] else "gather"),"Accepted resource selects the correct work gesture: "+str(site["id"]))
			events.append_array(reward_events)
			var inventory := sim.inventory.to_data()
			var denied := sim.journey_command("gather",{"id":site["id"]})
			check.call(not denied["ok"] and sim.inventory.to_data()==inventory and sim.drain_events().filter(func(e: Dictionary): return e["kind"]=="farm_harvest").is_empty(),"Repeated gathering cannot create another reward or animation: "+str(site["id"]))
	var player := ActorView.new()
	player.bind(sim.player,true)
	tree.root.add_child(player)
	player.set_process(false)
	var effects := WorldEffects.new()
	effects.player_view=player
	effects.simulation=sim
	tree.root.add_child(effects)
	effects.set_process(false)
	var event := events[0].duplicate(true)
	event["at"]=Vector2(sim.player["cell"])+Vector2(.5,0)
	player.receive(event)
	player._sync_character()
	event["action_serial"]=player.action_serial
	effects.receive(event)
	check.call(player.action==event["harvest_action"] and player.action_left>0 and player.character_view.current_action==player.action,"A successful harvest starts the actual world actor gesture")
	check.call(float(effects.effects[-1]["harvest_contact"])>0 and float(effects.effects[-1]["life"])>.8,"Resource particles wait for the authored hand/tool contact")
	sim.player["cell"]+=Vector2(.2,0)
	player._process(1.0/60)
	effects._process(1.0/60)
	check.call(player.action_left==0 and effects.effects.is_empty() and not GuCharacterActionMotion.harvesting(player.character_view.current_action),"Movement interrupts work and cancels unplayed contact particles without changing the accepted reward")
	player.receive(event)
	player.receive({"kind":"player_hit"})
	check.call(player.action_left==0,"Taking damage interrupts the gathering pose")
	player.receive(event)
	player.receive({"kind":"cast_moon","at":sim.player["cell"],"to":Vector2(sim.player["cell"])+Vector2.RIGHT})
	check.call(player.action=="cast_moon" and is_equal_approx(player.action_duration,GuCharacterAnimations.duration("attack","sword")),"Sword playback uses the same duration in the world and studio and can interrupt harvesting")
	var report := {"native_poses":samples,"max_foot_drift":max_foot_error,"max_hand_step_per_96_intervals":max_hand_step,"connected":connected,"planted":planted,"continuous":continuous,"neutral":neutral}
	var file := FileAccess.open("res://artifacts/concept42_motion.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("ACTION_MOTION ",JSON.stringify(report))
	actor.queue_free()
	player.queue_free()
	effects.queue_free()
	await tree.process_frame
