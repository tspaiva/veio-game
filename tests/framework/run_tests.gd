extends SceneTree
## Minimal headless test runner.
##
## Usage:
##   godot --headless --path . -s res://tests/framework/run_tests.gd [-- --filter=<text>]
##
## Discovers every `test_*.gd` under `res://tests/unit`, runs each `test_*`
## method on a fresh instance and exits with code 1 if anything failed.
## `--filter` keeps only tests whose "<file>::<method>" contains the text.

const TEST_ROOT := "res://tests/unit"


func _initialize() -> void:
	quit(_run_all(_parse_filter()))


func _run_all(filter: String) -> int:
	var files := _find_test_files(TEST_ROOT)
	if files.is_empty():
		printerr("No test files found under %s" % TEST_ROOT)
		return 1

	var passed := 0
	var failed := 0
	for path in files:
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			printerr("FAIL %s: could not load script" % path)
			failed += 1
			continue

		for method in script.get_script_method_list():
			var test_name: String = method.name
			if not test_name.begins_with("test_"):
				continue
			var full_name := "%s::%s" % [path.get_file().get_basename(), test_name]
			if not filter.is_empty() and not full_name.contains(filter):
				continue

			var failures := _run_test(script, test_name)
			if failures.is_empty():
				passed += 1
				print("  ok   %s" % full_name)
			else:
				failed += 1
				print("  FAIL %s" % full_name)
				for failure in failures:
					print("         %s" % failure)

	print("\n%d passed, %d failed" % [passed, failed])
	if passed + failed == 0:
		printerr("No tests matched.")
		return 1
	return 1 if failed > 0 else 0


func _run_test(script: GDScript, test_name: String) -> PackedStringArray:
	var instance = script.new()
	if not instance is TestCase:
		return PackedStringArray(["%s does not extend TestCase" % script.resource_path])
	instance.before_each()
	instance.call(test_name)
	instance.after_each()
	return instance.failures


func _find_test_files(dir_path: String) -> PackedStringArray:
	var result := PackedStringArray()
	for sub in DirAccess.get_directories_at(dir_path):
		result.append_array(_find_test_files(dir_path.path_join(sub)))
	for file in DirAccess.get_files_at(dir_path):
		if file.begins_with("test_") and file.ends_with(".gd"):
			result.append(dir_path.path_join(file))
	result.sort()
	return result


func _parse_filter() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			return arg.trim_prefix("--filter=")
	return ""
