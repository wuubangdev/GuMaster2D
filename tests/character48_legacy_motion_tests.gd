extends SceneTree
## Focused entrypoint for contracts changed by projected leg anatomy.
var passed := 0
var failed := 0
var failures := []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		failures.append(label)
		push_error(label)

func _run() -> void:
	await load("res://tests/character_transition_tests.gd").run(self,check)
	await load("res://tests/concept_articulation_tests.gd").run(self,check)
	FileAccess.open("res://artifacts/character48_legacy_motion_tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"failed":failed,"failures":failures},"  "))
	print("CHARACTER48_LEGACY_MOTION ",passed,"/",passed+failed)
	quit(1 if failed else 0)
