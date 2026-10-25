class_name Program
extends RefCounted
## A routine as data (GDD 12, PLAN 4): a tree of blocks loaded from JSON.
##
## Blocks stay plain Dictionaries so they serialize trivially and the
## future editor and text mode can share them. Statement lists hold blocks
## with `op`, `id` and, depending on the op, `args`, `cond`, `then`, `else`
## and `body`. Expressions (`cond`, `a`, `b`) use the same shape; inside
## `compare`, `a` and `b` may also be number literals.

const FORMAT := 1
const COMPARATORS := ["<", "<=", ">", ">=", "==", "!="]

var name := ""
var drone_class: StringName = &""
## Parameter declarations: name -> { "type": String, "default": Variant }.
var params: Dictionary = {}
var main: Array = []
## `when` blocks, highest priority first.
var handlers: Array = []
var format := FORMAT

# Problems found while reading the data, reported by `validate`.
var _load_errors := PackedStringArray()


static func from_dict(data: Dictionary) -> Program:
	var program := Program.new()
	program.format = int(data.get("format", FORMAT))
	program.name = str(data.get("name", ""))
	program.drone_class = StringName(str(data.get("class", "")))
	var params_data = data.get("params", {})
	if params_data is Dictionary:
		program.params = params_data.duplicate(true)
	else:
		program._load_errors.append("'params' deve ser um objeto")
	for key in ["main", "handlers"]:
		var list = data.get(key, [])
		if list is Array:
			program.set(key, _normalized(list))
		else:
			program._load_errors.append("'%s' deve ser uma lista" % key)
	return program


## Returns null if the text is not a JSON object.
static func from_json(text: String) -> Program:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return null
	return from_dict(json.data)


## Returns null if the file is missing or not a JSON object.
static func load_file(path: String) -> Program:
	if not FileAccess.file_exists(path):
		return null
	return from_json(FileAccess.get_file_as_string(path))


func to_dict() -> Dictionary:
	return {
		"format": format,
		"class": String(drone_class),
		"name": name,
		"params": params.duplicate(true),
		"handlers": handlers.duplicate(true),
		"main": main.duplicate(true),
	}


func param_default(param_name: StringName) -> Variant:
	var decl: Dictionary = params.get(String(param_name), {})
	return decl.get("default")


## Structural errors, in Portuguese for the player. Empty means runnable.
## Missing parts are not errors: they fail at runtime (D5).
func validate(registry: BlockRegistry) -> PackedStringArray:
	var errors := _load_errors.duplicate()
	if format != FORMAT:
		errors.append("formato %d não suportado" % format)
	var seen := {}
	for handler in handlers:
		_validate_handler(handler, registry, errors, seen)
	_validate_list(main, "main", registry, errors, seen)
	return errors


func _validate_handler(handler: Variant, registry: BlockRegistry, errors: PackedStringArray, seen: Dictionary) -> void:
	if not handler is Dictionary or handler.get("op") != "when":
		errors.append("handlers: só blocos 'when' são permitidos")
		return
	_check_id(handler, errors, seen)
	_validate_expr(handler.get("cond"), "when.cond", registry, errors, seen, false)
	_validate_list(handler.get("body"), "when.body", registry, errors, seen)


func _validate_list(list: Variant, where: String, registry: BlockRegistry, errors: PackedStringArray, seen: Dictionary) -> void:
	if not list is Array:
		errors.append("%s: deve ser uma lista de blocos" % where)
		return
	for block in list:
		_validate_statement(block, where, registry, errors, seen)


func _validate_statement(block: Variant, where: String, registry: BlockRegistry, errors: PackedStringArray, seen: Dictionary) -> void:
	if not block is Dictionary:
		errors.append("%s: bloco inválido" % where)
		return
	_check_id(block, errors, seen)
	var op := StringName(str(block.get("op", "")))
	var def := registry.get_def(op)
	var at := "%s: bloco %s (%s)" % [where, block.get("id"), op]
	if def == null:
		errors.append("%s: bloco desconhecido" % at)
		return
	if def.kind == BlockDef.Kind.EVENT:
		errors.append("%s: 'when' só pode ficar em handlers" % at)
		return
	if not def.is_statement():
		errors.append("%s: é uma condição, não uma ação" % at)
		return
	_validate_args(block, at, errors)

	match op:
		&"if":
			_validate_expr(block.get("cond"), at + ".cond", registry, errors, seen, false)
			if block.has("then"):
				_validate_list(block.then, at + ".then", registry, errors, seen)
			if block.has("else"):
				_validate_list(block["else"], at + ".else", registry, errors, seen)
		&"forever", &"repeat":
			_validate_list(block.get("body"), at + ".body", registry, errors, seen)
		&"repeat_until":
			_validate_expr(block.get("cond"), at + ".cond", registry, errors, seen, false)
			_validate_list(block.get("body"), at + ".body", registry, errors, seen)


func _validate_expr(expr: Variant, where: String, registry: BlockRegistry, errors: PackedStringArray,
		seen: Dictionary, allow_literal: bool) -> void:
	if allow_literal and (expr is int or expr is float):
		return
	if not expr is Dictionary:
		errors.append("%s: condição ausente ou inválida" % where)
		return
	_check_id(expr, errors, seen)
	var op := StringName(str(expr.get("op", "")))
	var def := registry.get_def(op)
	var at := "%s: bloco %s (%s)" % [where, expr.get("id"), op]
	if def == null:
		errors.append("%s: bloco desconhecido" % at)
		return
	if not def.is_expression():
		errors.append("%s: é uma ação, não uma condição" % at)
		return
	_validate_args(expr, at, errors)

	match op:
		&"and", &"or":
			_validate_expr(expr.get("a"), at + ".a", registry, errors, seen, false)
			_validate_expr(expr.get("b"), at + ".b", registry, errors, seen, false)
		&"not":
			_validate_expr(expr.get("a"), at + ".a", registry, errors, seen, false)
		&"compare":
			if not expr.get("cmp") in COMPARATORS:
				errors.append("%s: comparador inválido" % at)
			_validate_expr(expr.get("a"), at + ".a", registry, errors, seen, true)
			_validate_expr(expr.get("b"), at + ".b", registry, errors, seen, true)


func _validate_args(block: Dictionary, at: String, errors: PackedStringArray) -> void:
	var args = block.get("args", {})
	if not args is Dictionary:
		errors.append("%s: 'args' deve ser um objeto" % at)
		return
	for key in args:
		var value = args[key]
		if value is Dictionary and value.has("param") and not params.has(str(value.param)):
			errors.append("%s: parâmetro '%s' não declarado" % [at, value.param])


func _check_id(block: Dictionary, errors: PackedStringArray, seen: Dictionary) -> void:
	var id = block.get("id")
	if not id is int:
		errors.append("bloco %s sem id numérico" % block.get("op", "?"))
	elif seen.has(id):
		errors.append("id %d repetido" % id)
	else:
		seen[id] = true


# JSON numbers arrive as floats; block ids are ints everywhere else.
static func _normalized(value: Variant) -> Variant:
	if value is Array:
		var list := []
		for item in value:
			list.append(_normalized(item))
		return list
	if value is Dictionary:
		var copy := {}
		for key in value:
			copy[key] = _normalized(value[key])
		if copy.get("id") is float and is_equal_approx(copy.id, roundf(copy.id)):
			copy.id = int(copy.id)
		return copy
	return value
