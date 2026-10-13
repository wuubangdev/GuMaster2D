extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var catalog := GuCatalog.new()
	var signatures: Array[int] = []
	for definition in catalog.definitions.values():
		var kind: String = definition["kind"]
		var texture := GuSkillArt.texture(kind)
		check.call(texture != null and texture.get_size()==Vector2(256,256),kind+" has a real imported 256px vector illustration")
		if texture == null: continue
		var pixels := texture.get_image()
		signatures.append(hash(pixels.get_data()))
		var opaque := 0
		var gutter_clear := true
		for y in range(pixels.get_height()):
			for x in range(pixels.get_width()):
				var alpha := pixels.get_pixel(x,y).a
				if alpha>.5: opaque+=1
				if x<5 or y<5 or x>250 or y>250: gutter_clear=gutter_clear and alpha<.01
		check.call(gutter_clear and opaque>7000 and opaque<34000,kind+" has clean transparent margins and a readable substantial silhouette")
	check.call(signatures.size()==4 and signatures[0]!=signatures[1] and signatures[0]!=signatures[2] and signatures[0]!=signatures[3] and signatures[1]!=signatures[2] and signatures[1]!=signatures[3] and signatures[2]!=signatures[3],"All four catalog creatures have distinct actual pixel art")
	check.call(GuSkillArt.texture("unknown")==null,"Unknown Gu art fails cleanly without an invented identity")
	var endpoints := true
	var bounded := true
	for frost in [false,true]:
		var start := Vector2(-17,-31)
		var end := Vector2(136,58)
		endpoints=endpoints and WorldEffects.flight_point(start,end,0,frost)==start and WorldEffects.flight_point(start,end,1,frost).distance_to(end)<.00001
		for i in range(101):
			var p := WorldEffects.flight_point(start,end,i/100.0,frost)
			bounded=bounded and p.is_finite() and p.distance_to(start.lerp(end,i/100.0))<=9.001
	check.call(endpoints and bounded,"Moon and frozen-silk paths preserve exact hand/contact endpoints with bounded smooth motion")
	for release in [.08,GuCharacterActionMotion.release_seconds("sword")]:
		var fx := WorldEffects.new()
		tree.root.add_child(fx)
		fx.set_process(false)
		var source := {"kind":"cast_moon","at":Vector2(10,10),"to":Vector2(13,10),"target":"fixture","origin_offset":Vector2(7,-25),"release_time":release}
		var before := source.duplicate(true)
		fx.receive(source)
		fx.receive({"kind":"hit","at":Vector2(13,10),"target":"fixture","amount":35})
		check.call(source==before and fx.effects.size()==2 and is_equal_approx(float(fx.effects[1]["impact_delay"]),.28),"Accepted events remain immutable and hit labels wait for .28s contact")
		fx._process(release-.001)
		check.call(not fx.effects[0].has("launch_offset") and WorldEffects.cast_stage(release-.001,release,.52)["stage"]=="windup","No projectile leaves the hand before its authored release")
		fx._process(.001)
		check.call(fx.effects[0].get("launch_offset")==Vector2(7,-25) and WorldEffects.cast_stage(release,release,.52)["stage"]=="flight","Projectile launches exactly at its authored release from the recorded hand")
		fx._process(.28-release)
		check.call(fx.effects[0].has("impact_point") and WorldEffects.cast_stage(.28,release,.52)["stage"]=="contact","Contact point freezes on the original .28s beat")
		fx._process(.25)
		check.call(not fx.effects.any(func(entry: Dictionary)->bool:return entry["kind"]=="cast_moon"),"Completed cast is removed without orphan effect geometry")
		fx.queue_free()
	await tree.process_frame
