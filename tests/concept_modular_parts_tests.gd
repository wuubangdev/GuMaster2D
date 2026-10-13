extends RefCounted
## Regression for actual limb remnants outside the former arm masks.

static func run(tree: SceneTree, check: Callable) -> void:
	var view := GuIllustratedCharacterView.new()
	tree.root.add_child(view)
	view.configure(256,48)
	view.set_active(false)
	var current := {}
	var previous := {}
	for name in ["character-concept-01","character-directions-02"]:
		var source := "original" if name=="character-concept-01" else "directions"
		current[source]=(load("res://assets/characters/concept-rig/%s-layers.res" % name) as Texture2D).get_image()
		previous[source]=(load("res://tests/fixtures/concept36_owners/%s-layers.res" % name) as Texture2D).get_image()
	var clean := true
	var asset_count := 0
	var vector_only := true
	var assets_present := true
	var missing := 0
	var rescued := 0
	var anchored := true
	var neutral := true
	var winding := true
	var bow := 0.0
	var poses := 0
	var records := []
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		view.set_appearance(look)
		for d in range(8):
			var reference := GuConceptCharacterArt.view_for(look,d)
			var assets: Dictionary = reference["modular_art"]
			var owner: Image = current[reference["source"]]
			var old: Image = previous[reference["source"]]
			var coat := PackedVector2Array()
			for point: Array in reference["body_core"]: coat.append(GuConceptCharacterArt._point(point))
			var paths := [assets["coat"]["path"]]
			var recovered := 0
			for side in ["L","R"]:
				var key: String = "arm_"+side
				var sleeve: Dictionary = assets["sleeves"][key]
				paths.append(sleeve["base"])
				paths.append(sleeve["variants"]["flex"])
				paths.append(sleeve["variants"]["strike"])
				var seam := PackedVector2Array()
				var former := PackedVector2Array()
				for point: Array in reference["sleeve_seams"][key]: seam.append(GuConceptCharacterArt._point(point))
				for point: Array in reference["parts"][key]["polygon"]: former.append(GuConceptCharacterArt._point(point))
				var bounds := Rect2(seam[0],Vector2.ZERO)
				for point in seam: bounds=bounds.expand(point)
				for y in range(floori(bounds.position.y),ceili(bounds.end.y)):
					for x in range(floori(bounds.position.x),ceili(bounds.end.x)):
						var at := Vector2(x+.5,y+.5)
						if not Geometry2D.is_point_in_polygon(at,seam): continue
						var now := roundi(owner.get_pixel(x,y).r*255)
						clean=clean and now!=64
						if roundi(old.get_pixel(x,y).r*255)!=64 or Geometry2D.is_point_in_polygon(at,former): continue
						if now==int(GuConceptCharacterArt.manifest()["layer_ids"][key])*32: recovered+=1
						elif now!=32: missing+=1
			for path: String in paths:
				var text := FileAccess.get_file_as_string(path)
				vector_only=vector_only and text.begins_with("<svg") and not "<image" in text
				asset_count+=1
				assets_present=assets_present and ResourceLoader.exists(path)
			# No original body pigment may extend outside its new cloth outline.
			for y in range(int(reference["ground"][1])-180,int(reference["ground"][1])):
				for x in range(int(reference["ground"][0])-90,int(reference["ground"][0])+91):
					if roundi(owner.get_pixel(x,y).r*255)==64: clean=clean and Geometry2D.is_point_in_polygon(Vector2(x+.5,y+.5),coat)
			rescued+=recovered
			records.append({"body":body,"direction":d,"formerly_unmasked_sleeve_pixels":recovered})
			for action in ["idle","walk","run","attack","defend","channel","cast","dash","hit","death","respawn"]:
				for frame in range(17):
					view.present(action,view.duration(action)*float(frame)/16,Vector2.DOWN.rotated(d*PI/4),action=="idle")
					var pose: Dictionary = view.capture_pose()["source_pose"]
					for side in ["L","R"]:
						var key: String = "arm_"+side
						var chain: PackedVector2Array = pose[key]
						var controls: PackedVector2Array = pose["cloth_guides"][side]
						anchored=anchored and controls.size()==5 and controls[0].distance_to(chain[0])<.0001 and controls[4].distance_to(chain[1])<.0001
						bow=maxf(bow,controls[2].distance_to(chain[0].lerp(chain[1],.5)))
						var geometry := GuConceptCharacterArt.modular_sleeve_geometry(reference,key)
						var actual := GuConceptCharacterArt.modular_sleeve_vertices(reference,key,pose)
						if action=="idle":
							for i in range(actual.size()): neutral=neutral and actual[i].distance_to((Vector2(geometry["vertices"][i])-GuConceptCharacterArt._point(reference["ground"]))*float(reference["scale"]))<.0001
						for i in range(0,geometry["triangles"].size(),3):
							var a: int = geometry["triangles"][i]
							var b: int = geometry["triangles"][i+1]
							var c: int = geometry["triangles"][i+2]
							if int(geometry["bones"][a])!=0: continue
							var original := (Vector2(geometry["vertices"][b])-Vector2(geometry["vertices"][a])).cross(Vector2(geometry["vertices"][c])-Vector2(geometry["vertices"][a]))
							winding=winding and original*(actual[b]-actual[a]).cross(actual[c]-actual[a])>0
					poses+=1
	check.call(clean,"Clean torso contains neither full stitch zones nor pigment outside its own body silhouette")
	check.call(rescued>0 and missing==0,"Sleeve pigment outside the former arm polygon is actually removed from the chest and retained on the moving arm")
	check.call(asset_count==112 and vector_only,"All 16 views have their own coat and two complete sleeves with separate flex/extension crease SVGs")
	check.call(assets_present,"Every registered modular cloth asset can be loaded by Godot")
	check.call(anchored and bow>.05,"Five active cloth controls relax each sleeve while its anatomical shoulder and elbow remain fixed")
	check.call(neutral and winding,"Independent sleeve meshes keep neutral UV registration and triangle winding over 2992 poses")
	var report := {"passed":clean and rescued>0 and missing==0 and vector_only and asset_count==112 and anchored and bow>.05 and neutral and winding,"assets":asset_count,"poses":poses,"removed_old_body_sleeve_pixels":rescued,"lost_original_sleeve_pixels":missing,"clean_torso":clean,"cloth_anchors":anchored,"maximum_mid_sleeve_bow":bow,"neutral":neutral,"winding":winding,"views":records}
	var output := FileAccess.open("res://artifacts/concept37_modular_parts.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  "))
	output.close()
	view.queue_free()
	await tree.process_frame
