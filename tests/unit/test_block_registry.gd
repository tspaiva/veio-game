extends TestCase

const S := preload("res://core/blocks/standard_blocks.gd")


func test_every_standard_block_has_a_label() -> void:
	for def in BlockRegistry.standard().all():
		assert_false(def.label.is_empty(), "%s has a label" % def.op)


func test_palette_without_parts_has_only_chassis_and_control_blocks() -> void:
	var ops := _ops(BlockRegistry.standard().available_for([]))
	assert_true(ops.has(&"if") and ops.has(&"forever") and ops.has(&"return_to_base"))
	assert_false(ops.has(&"mine"))
	assert_false(ops.has(&"explore"))


func test_parts_unlock_their_blocks() -> void:
	var ops := _ops(BlockRegistry.standard().available_for([S.DRILL, S.CARGO]))
	for op in [&"mine", &"dig", &"unload", &"cargo_full"]:
		assert_true(ops.has(op), "%s unlocked" % op)
	assert_false(ops.has(&"shoot"))


func test_explore_is_scout_only() -> void:
	assert_eq(BlockRegistry.standard().get_def(&"explore").part, S.CHASSIS_SCOUT)


func _ops(defs: Array[BlockDef]) -> Array[StringName]:
	var ops: Array[StringName] = []
	for def in defs:
		ops.append(def.op)
	return ops
