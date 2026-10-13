extends SceneTree
var passed := 0
var failed := 0
var records: Array[Dictionary] = []
func _initialize() -> void:
	if "--test-mode" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	if ok: passed+=1
	else: failed+=1
	records.append({"check":label,"passed":ok})
	print("PASS: " if ok else "FAIL: ",label)
func _run() -> void:
	await preload("res://tests/gu45_art_tests.gd").run(self,check)
	var output := FileAccess.open("res://artifacts/gu45_tests.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":records},"  "))
	print("GU45_TESTS ",passed,"/",passed+failed)
	quit(0 if failed==0 else 1)
