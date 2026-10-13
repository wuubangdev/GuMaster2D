extends SceneTree
## The rendered mesh endpoints, not just rigid placement transforms.
var passed := 0
var failed := 0
func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	if ok: passed+=1
	else: failed+=1; printerr("FAIL: ",label)
func _run() -> void:
	await preload("res://tests/concept_directional_parts_tests.gd").run(self,check)
	await preload("res://tests/character_joint_skin_tests.gd").run(self,check)
	print("CHARACTER48_ATTACHMENTS ",passed,"/",passed+failed)
	quit(1 if failed else 0)
