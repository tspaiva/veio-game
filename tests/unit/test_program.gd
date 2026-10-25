extends TestCase

var registry: BlockRegistry


func before_each() -> void:
	registry = BlockRegistry.standard()


func test_from_json_normalizes_ids_to_int() -> void:
	var program := Program.from_json('{"main": [{"id": 7, "op": "return_to_base"}]}')
	assert_not_null(program)
	assert_true(program.main[0].id is int)
	assert_eq(program.validate(registry).size(), 0)


func test_from_json_rejects_non_objects() -> void:
	assert_null(Program.from_json("[1, 2]"))
	assert_null(Program.from_json("not json"))


func test_round_trip_through_dict() -> void:
	var source := Program.load_file("res://data/routines/miner.json")
	var copy := Program.from_dict(source.to_dict())
	assert_eq(copy.to_dict(), source.to_dict())


func test_wrong_list_types_are_errors() -> void:
	var errors := Program.from_dict({"main": {"op": "x"}, "handlers": 3}).validate(registry)
	assert_true(_has(errors, "'main' deve ser uma lista"))
	assert_true(_has(errors, "'handlers' deve ser uma lista"))


func test_unknown_block_is_an_error() -> void:
	assert_true(_has(_errors([{"id": 1, "op": "teleport"}]), "bloco desconhecido"))


func test_duplicate_ids_are_errors() -> void:
	var errors := _errors([{"id": 1, "op": "return_to_base"}, {"id": 1, "op": "unload"}])
	assert_true(_has(errors, "id 1 repetido"))


func test_missing_id_is_an_error() -> void:
	assert_true(_has(_errors([{"op": "unload"}]), "sem id"))


func test_condition_used_as_statement_is_an_error() -> void:
	assert_true(_has(_errors([{"id": 1, "op": "battery_low"}]), "é uma condição"))


func test_action_used_as_condition_is_an_error() -> void:
	var errors := _errors([{"id": 1, "op": "if", "cond": {"id": 2, "op": "mine"}, "then": []}])
	assert_true(_has(errors, "é uma ação"))


func test_if_without_condition_is_an_error() -> void:
	assert_true(_has(_errors([{"id": 1, "op": "if", "then": []}]), "condição ausente"))


func test_when_outside_handlers_is_an_error() -> void:
	var errors := _errors([{"id": 1, "op": "when", "cond": {"id": 2, "op": "battery_low"}, "body": []}])
	assert_true(_has(errors, "só pode ficar em handlers"))


func test_handlers_only_accept_when() -> void:
	var errors := Program.from_dict({"handlers": [{"id": 1, "op": "unload"}]}).validate(registry)
	assert_true(_has(errors, "só blocos 'when'"))


func test_undeclared_param_is_an_error() -> void:
	var errors := _errors([{"id": 1, "op": "goto_nearest_ore", "args": {"ore": {"param": "alvo"}}}])
	assert_true(_has(errors, "parâmetro 'alvo' não declarado"))


func test_invalid_comparator_is_an_error() -> void:
	var cond := {"id": 2, "op": "compare", "cmp": "~", "a": 1, "b": 2}
	assert_true(_has(_errors([{"id": 1, "op": "if", "cond": cond, "then": []}]), "comparador inválido"))


func test_literals_only_allowed_inside_compare() -> void:
	assert_true(_has(_errors([{"id": 1, "op": "if", "cond": 3, "then": []}]), "condição ausente ou inválida"))


func test_missing_parts_are_not_validation_errors() -> void:
	# D5: they fail at runtime with a log, so routines work across loadouts.
	assert_eq(_errors([{"id": 1, "op": "shoot"}]).size(), 0)


func _errors(main: Array) -> PackedStringArray:
	return Program.from_dict({"main": main}).validate(registry)


func _has(errors: PackedStringArray, fragment: String) -> bool:
	for error in errors:
		if error.contains(fragment):
			return true
	fail("no error contains '%s' in %s" % [fragment, errors])
	return true
