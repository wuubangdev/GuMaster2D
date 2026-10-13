extends SceneTree
var passed := 0
var failed := 0
func _initialize() -> void:
	_run.call_deferred()
func check(value: bool, label: String) -> void:
	if value: passed+=1
	else: failed+=1
	print("PASS: " if value else "FAIL: ",label)
func _run() -> void:
	await preload("res://tests/concept_directional_parts_tests.gd").run(self,check)
	print("DIRECTIONAL_TEST_RESULTS ",passed,"/",passed+failed," passed")
	quit(0 if failed==0 else 1)
