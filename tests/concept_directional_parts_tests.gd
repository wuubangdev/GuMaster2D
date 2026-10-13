extends RefCounted
## Verify the new renderer's actual asset/anchor contracts, including hidden
## surfaces. Numeric assertions supplement the native visual review.

static func pixel(asset: Dictionary, image: Image, point: Vector2) -> Color:
	var b: Array = asset["bounds"]
	var uv := (point-Vector2(b[0],b[1]))/Vector2(b[2],b[3])
	if uv.x<0 or uv.x>=1 or uv.y<0 or uv.y>=1: return Color.TRANSPARENT
	return image.get_pixelv(Vector2i(uv*Vector2(image.get_size())))

static func run(tree: SceneTree, check: Callable) -> void:
	var actor := GuIllustratedCharacterView.new()
	tree.root.add_child(actor)
	actor.configure(256,64)
	actor.set_active(false)
	var assets_count := 0
	var samples := 0
	var paths := {}
	var worst_anchor := 0.0
	var worst_scale := 0.0
	var coverage := true
	var placement_ok := true
	var registry_ok := true
	var atlas_ok := true
	var records := []
	var gaps := []
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		for d in range(8):
			var view := GuConceptCharacterArt.view_for(look,d)
			var kit: Dictionary = view["directional_art"]
			var parts: Dictionary = kit["parts"]
			var images := {}
			registry_ok=registry_ok and parts.size()==22 and kit["view"]=="%s_%d" % [body,d]
			for key: String in parts:
				var asset: Dictionary = parts[key]
				assets_count+=1
				paths[asset["path"]]=true
				var texture := load(asset["path"]) as Texture2D
				if texture==null:
					registry_ok=false
					continue
				var image := texture.get_image()
				if image.is_compressed(): image.decompress()
				images[key]=image
				coverage=coverage and bool(asset["complete_hidden_surface"]) and float(asset["overlap"])>=.48
				# Sample a small disk around each joint. Testing a single center
				# would miss caps that disappear as the adjacent part rotates.
				for anchor_name: String in asset["anchors"]:
					# Sole marks the outer contact edge, not a concealed joint.
					if anchor_name=="sole": continue
					var anchor: Array = asset["anchors"][anchor_name]
					for angle in range(8):
						var point := Vector2(anchor[0],anchor[1])+Vector2.from_angle(angle*TAU/8)*.20
						var opacity := pixel(asset,image,point).a
						if opacity<=.90: gaps.append({"view":kit["view"],"part":key,"point":str(point),"alpha":opacity})
						coverage=coverage and opacity>.90
				var rect: Array = asset["atlas_rect"]
				var size: Array = kit["atlas_size"]
				atlas_ok=atlas_ok and rect[0]>=2 and rect[1]>=2 and rect[0]+rect[2]<size[0] and rect[1]+rect[3]<size[1]
			var view_error := 0.0
			for weapon in ["sword","spear","unarmed"]:
				look["weapon"]=weapon
				actor.set_appearance(look)
				for action in ["idle","walk","run","attack","cast","defend","channel","hit","dash","death"]:
					for frame in range(25):
						actor.present(action,float(frame)/24*actor.duration(action,weapon),Vector2.DOWN.rotated(d*PI/4),false)
						var snapshot := actor.capture_pose()
						var pose: Dictionary = snapshot["source_pose"]
						for side in ["L","R"]:
							for key in ["shoulder_"+side,"sleeve_"+side,"forearm_"+side,"hand_"+GuConceptDirectionalParts.hand_state(snapshot,side)+"_"+side,"thigh_"+side,"shin_"+side,"boot_cloth_"+side,"boot_leather_"+side]:
								var asset: Dictionary = parts[key]
								var transform := GuConceptDirectionalParts.placement(view,asset,pose)
								var scale_error := absf(transform.x.length()-1)+absf(transform.y.length()-1)
								worst_scale=maxf(worst_scale,scale_error)
								placement_ok=placement_ok and transform.origin.is_finite() and absf(transform.determinant()-1)<.0001
								var anchor_key := "root"
								var target := Vector2.ZERO
								match str(asset["bone"]):
									"shoulder": target=pose["arm_"+side][0]
									"upper_arm":
										anchor_key="tip"
										target=pose["arm_"+side][1]
									"forearm":
										anchor_key="wrist"
										target=pose["wrist_"+side]
									"hand":
										anchor_key="grip"
										target=pose["grip_"+side]
									"thigh":
										anchor_key="tip"
										target=pose["leg_"+side][1]
									"shin":
										anchor_key="tip"
										target=pose["leg_"+side][2]
									"foot": target=pose["leg_"+side][2]
								var p: Array = asset["anchors"][anchor_key]
								var point := Vector2(p[0],p[1])
								if GuConceptJointSkin.supports(asset): point=GuConceptJointSkin.fitted_vertex(point,GuConceptJointSkin.controls(view,asset,pose),asset,GuConceptJointSkin.PoseFit.weights(view,asset,pose))
								view_error=maxf(view_error,(transform*point).distance_to(target))
						samples+=1
			worst_anchor=maxf(worst_anchor,view_error)
			records.append({"view":kit["view"],"max_anchor_error":view_error})
			check.call(view_error<.001,"%s: every limb endpoint and grip stays on its joint across 750 action/weapon poses" % kit["view"])
	var smooth_error := 0.0
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		actor.set_appearance(look)
		for frame in range(256):
			var d := (frame/16)%8
			actor.present_smooth("run" if frame<128 else "attack",float(frame)/60,Vector2.DOWN.rotated(d*PI/4),false,1.0/60,1)
			var s := actor.capture_pose()
			var view := GuConceptCharacterArt.view_for(look,int(s["direction_index"]))
			var pose: Dictionary = s["source_pose"]
			for side in ["L","R"]:
				for part in ["sleeve","thigh","shin","hand_grip"]:
					var asset: Dictionary = view["directional_art"]["parts"][part+"_"+side]
					var transform := GuConceptDirectionalParts.placement(view,asset,pose)
					var a: Array = asset["anchors"]["grip" if part=="hand_grip" else "tip"]
					var target: Vector2 = pose["grip_"+side] if part=="hand_grip" else pose["arm_"+side][1] if part=="sleeve" else pose["leg_"+side][1 if part=="thigh" else 2]
					var point := Vector2(a[0],a[1])
					if GuConceptJointSkin.supports(asset): point=GuConceptJointSkin.fitted_vertex(point,GuConceptJointSkin.controls(view,asset,pose),asset,GuConceptJointSkin.PoseFit.weights(view,asset,pose))
					smooth_error=maxf(smooth_error,(transform*point).distance_to(target))
	check.call(smooth_error<.001,"Actual smooth playback keeps new pieces attached through all direction turns and run-to-attack blends")
	check.call(registry_ok and assets_count==352 and paths.size()==352,"352 independently addressable SVG pieces cover both bodies and all eight directions")
	check.call(coverage,"Joint disks, including concealed elbow/wrist/knee caps, are painted opaque")
	check.call(atlas_ok,"All directional atlas entries retain transparent gutters within bounds")
	check.call(placement_ok and worst_scale<.0001,"Runtime transforms preserve part scale, winding and finite positions")
	check.call(FileAccess.get_sha256("res://assets/characters/concept-rig/character-concept-01.png")=="20432dfcdff4b38f93c5ddd55649e6c5de0d68c56bee2d963d16a2747d80d7ce","Original approved character concept remains byte-identical")
	check.call(FileAccess.get_sha256("res://assets/characters/concept-rig/character-directions-02.png")=="29dfab20fc6eda61bcca24f09f255e515a1d34711b602d019f67561f712ef6e7","Original approved direction sheet remains byte-identical")
	var report := FileAccess.open("res://artifacts/concept41_constraints.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"assets":assets_count,"poses":samples,"max_anchor_error":worst_anchor,"max_scale_error":worst_scale,"smooth_poses":512,"smooth_anchor_error":smooth_error,"opaque_joint_disks":coverage,"coverage_gaps":gaps,"views":records},"  "))
	report.close()
	actor.queue_free()
	await tree.process_frame
