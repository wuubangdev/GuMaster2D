extends RefCounted

static func run(tree: SceneTree, check: Callable) -> void:
	var actor := GuIllustratedCharacterView.new()
	tree.root.add_child(actor)
	actor.configure(256,176)
	actor.set_active(false)
	var max_anchor_error := 0.0
	var max_displacement := 0.0
	var min_area_ratio := INF
	var max_area_ratio := 0.0
	var finite := true
	var poses := 0
	var mesh_samples := 0
	var deformed := 0
	var rigid := true
	var cuffs_sealed := true
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		actor.set_appearance(look)
		for d in range(8):
			var view := GuConceptCharacterArt.view_for(look,d)
			for side in ["L","R"]:
				var asset: Dictionary = view["directional_art"]["parts"]["forearm_"+side]
				var back := GuConceptJointSkin.mesh(view,asset,-1)
				var front := GuConceptJointSkin.mesh(view,asset,1)
				for col in range(GuConceptJointSkin.COLUMNS+1):
					var end := GuConceptJointSkin.ROWS*(GuConceptJointSkin.COLUMNS+1)+col
					cuffs_sealed=cuffs_sealed and Vector2(back["vertices"][end]).distance_to(front["vertices"][col])<.00001 and Vector2(back["uvs"][end]).distance_to(front["uvs"][col])<.00001
			for action in ["idle","walk","run","attack","defend","gather","mine","cast","channel","hit","dash","death"]:
				for frame in range(9):
					actor.present(action,actor.duration(action)*frame/8.0,Vector2.DOWN.rotated(d*PI/4))
					var pose: Dictionary = actor.capture_pose()["source_pose"]
					for side in ["L","R"]:
						for key in ["sleeve","forearm","thigh","shin"]:
							var asset: Dictionary = view["directional_art"]["parts"][key+"_"+side]
							var data := GuConceptJointSkin.mesh(view,asset)
							var control := GuConceptJointSkin.controls(view,asset,pose)
							var vertices: PackedVector2Array = data["vertices"].duplicate()
							var projected := PackedVector2Array()
							var fit := GuConceptJointSkin.PoseFit.weights(view,asset,pose)
							for i in range(vertices.size()):
								projected.append(GuConceptJointSkin.projected_vertex(vertices[i],control,asset))
								var p := GuConceptJointSkin.fitted_vertex(vertices[i],control,asset,fit)
								finite=finite and p.is_finite()
								var displacement := p.distance_to(projected[i])
								max_displacement=maxf(max_displacement,displacement)
								if displacement>.01: deformed+=1
								vertices[i]=p
							for anchor: Array in asset["anchors"].values():
								var point := Vector2(anchor[0],anchor[1])
								max_anchor_error=maxf(max_anchor_error,GuConceptJointSkin.fitted_vertex(point,control,asset,fit).distance_to(GuConceptJointSkin.projected_vertex(point,control,asset)))
							var indices: PackedInt32Array = data["indices"]
							for tri in range(0,indices.size(),3):
								var a := indices[tri]
								var b := indices[tri+1]
								var c := indices[tri+2]
								var area := (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a])
								var rest_area: float = (projected[b]-projected[a]).cross(projected[c]-projected[a])
								min_area_ratio=minf(min_area_ratio,area/rest_area)
								max_area_ratio=maxf(max_area_ratio,area/rest_area)
							mesh_samples+=1
						for key in ["hand_grip","hand_relaxed","boot_cloth","boot_leather"]:
							rigid=rigid and not GuConceptJointSkin.supports(view["directional_art"]["parts"][key+"_"+side])
					poses+=1
	check.call(finite and min_area_ratio>.2 and max_area_ratio<2.0,"Cloth meshes remain finite and unfolded through 12 actions, 8 views and both bodies")
	check.call(max_anchor_error<.0001,"Skinned shoulder/elbow/wrist/hip/knee/ankle centerlines retain their exact anatomical anchors")
	check.call(deformed>0 and max_displacement>.1 and max_displacement<3,"Joint cloth visibly responds to bending with bounded fitting around physically projected bones")
	check.call(rigid,"Hands, grip sockets and boot soles are excluded from cloth deformation")
	check.call(cuffs_sealed,"Under-cuff and visible forearm meshes share identical seam vertices and UVs in all 32 arms")
	var report := {"poses":poses,"meshes":mesh_samples,"max_anchor_error":max_anchor_error,"max_cloth_displacement":max_displacement,"min_triangle_area_ratio_after_projection":min_area_ratio,"max_triangle_area_ratio_after_projection":max_area_ratio,"finite":finite,"rigid_hands_and_boots":rigid}
	FileAccess.open("res://artifacts/concept44_skin.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("JOINT_SKIN ",JSON.stringify(report))
	actor.queue_free()
	await tree.process_frame
