extends SceneTree
## Exercise the exact deformed vertices submitted to the renderer, not only
## the underlying rigid bone transforms.
var checks: Array = []
var failures := 0
func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok: failures+=1; printerr("FAIL: ",label)
func _run() -> void:
	var actor := GuIllustratedCharacterView.new()
	root.add_child(actor)
	actor.configure(256,156)
	actor.set_active(false)
	var south := "--south-only" in OS.get_cmdline_user_args()
	var directions := [0] if south else [0,1,2,3,4,5,6,7]
	var actions := ["idle","attack","defend","gather","mine","walk","run","cast","channel","dash","hit","death","respawn"]
	var min_area := INF
	var max_area := 0.0
	var max_anchor := 0.0
	var max_idle := 0.0
	var max_fit := 0.0
	var finite := true
	var meshes := 0
	for body in ["male","female"]:
		var look := GuCharacterAppearance.default_data()
		look["body"]=body
		actor.set_appearance(look)
		for direction in directions:
			var view := GuConceptCharacterArt.view_for(look,direction)
			check(view["directional_art"].get("fitting_revision",0)==46,"Authored rest and fitting contract "+body+"/"+str(direction))
			for action in actions:
				for frame in range(17):
					actor.present(action,actor.duration(action)*frame/16.0,Vector2.DOWN.rotated(direction*PI/4))
					var pose: Dictionary = actor.capture_pose()["source_pose"]
					for side in ["L","R"]:
						for part in ["sleeve","shoulder"]:
							var asset: Dictionary = view["directional_art"]["parts"][part+"_"+side]
							var mesh := GuConceptJointSkin.mesh(view,asset)
							var fit := GuConceptJointSkin.PoseFit.weights(view,asset,pose)
							var skin := GuConceptJointSkin.controls(view,asset,pose) if part=="sleeve" else Vector4.ZERO
							var vertices := PackedVector2Array()
							for p: Vector2 in mesh["vertices"]:
								var v := fitted(p,view,asset,pose,skin,fit)
								finite=finite and v.is_finite()
								vertices.append(v)
								max_fit=maxf(max_fit,v.distance_to(p))
								if action=="idle" and frame==0:
									var legacy := GuConceptJointSkin.vertex(p,skin) if part=="sleeve" else p
									max_idle=maxf(max_idle,v.distance_to(legacy))
							for a: Array in asset["anchors"].values():
								var p := Vector2(a[0],a[1])
								max_anchor=maxf(max_anchor,fitted(p,view,asset,pose,skin,fit).distance_to(p))
							for i in range(0,mesh["indices"].size(),3):
								var a: int = mesh["indices"][i]
								var b: int = mesh["indices"][i+1]
								var c: int = mesh["indices"][i+2]
								var rest: float = (mesh["vertices"][b]-mesh["vertices"][a]).cross(mesh["vertices"][c]-mesh["vertices"][a])
								var area := (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a])/rest
								min_area=minf(min_area,area)
								max_area=maxf(max_area,area)
							meshes+=1
	check(finite and min_area>.20 and max_area<2.0,"Actual sleeve and shoulder draw meshes remain finite without inversion")
	check(max_anchor<.0001,"Chest stitch, shoulder root and elbow anchors remain fixed through fitting")
	check(max_idle<.001,"Rest fitting preserves the authored idle silhouette")
	check(max_fit>.15 and max_fit<3,"Fitting changes cloth silhouette within a bounded envelope")
	var report := {"passed":checks.size()-failures,"failed":failures,"checks":checks,"directions":directions,"actions":actions,"meshes":meshes,"minimum_area_ratio":min_area,"maximum_area_ratio":max_area,"maximum_anchor_error":max_anchor,"maximum_idle_displacement":max_idle,"maximum_fitted_displacement":max_fit}
	FileAccess.open("res://artifacts/concept46_fit_tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("POSE_FIT ",JSON.stringify(report))
	actor.queue_free()
	await process_frame
	quit(1 if failures else 0)
func fitted(p: Vector2, view: Dictionary, asset: Dictionary, pose: Dictionary, skin: Vector4, fit: Vector3) -> Vector2:
	if asset["bone"]=="shoulder": return GuConceptJointSkin.PoseFit.shoulder(p,view,asset,pose)
	return GuConceptJointSkin.fitted_vertex(p,skin,asset,fit)
