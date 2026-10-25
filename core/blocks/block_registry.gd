class_name BlockRegistry
extends RefCounted
## All known block types, keyed by op. Each part registers the blocks it
## unlocks (see `StandardBlocks`), so adding a part never touches the
## interpreter.

var _defs: Dictionary = {}  # StringName -> BlockDef


## A registry with every standard block.
static func standard() -> BlockRegistry:
	var registry := BlockRegistry.new()
	StandardBlocks.register_all(registry)
	return registry


func register(def: BlockDef) -> void:
	assert(not _defs.has(def.op), "duplicate block op %s" % def.op)
	_defs[def.op] = def


func has(op: StringName) -> bool:
	return _defs.has(op)


func get_def(op: StringName) -> BlockDef:
	return _defs.get(op)


func all() -> Array[BlockDef]:
	var result: Array[BlockDef] = []
	result.assign(_defs.values())
	return result


## Blocks a drone with `parts` can run: the editor palette (GDD 7.2).
func available_for(parts: Array) -> Array[BlockDef]:
	var result: Array[BlockDef] = []
	for def: BlockDef in _defs.values():
		if def.part == &"" or parts.has(def.part):
			result.append(def)
	return result


func action(op: StringName, part: StringName, label: String, params: PackedStringArray, impl: Callable) -> void:
	register(BlockDef.new(op, BlockDef.Kind.ACTION, part, label, params, impl))


func condition(op: StringName, part: StringName, label: String, params: PackedStringArray, impl: Callable) -> void:
	register(BlockDef.new(op, BlockDef.Kind.CONDITION, part, label, params, impl))


func value(op: StringName, part: StringName, label: String, params: PackedStringArray, impl: Callable) -> void:
	register(BlockDef.new(op, BlockDef.Kind.VALUE, part, label, params, impl))


## Interpreter-implemented statement (if, loops).
func control(op: StringName, label: String, params: PackedStringArray = PackedStringArray()) -> void:
	register(BlockDef.new(op, BlockDef.Kind.CONTROL, &"", label, params))


## Interpreter-implemented expression (and, or, not, compare).
func logic(op: StringName, label: String) -> void:
	register(BlockDef.new(op, BlockDef.Kind.CONDITION, &"", label))


func event(op: StringName, label: String) -> void:
	register(BlockDef.new(op, BlockDef.Kind.EVENT, &"", label))
