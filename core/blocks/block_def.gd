class_name BlockDef
extends RefCounted
## Describes one block type: what it is, which part unlocks it and, for
## actions and sensors, what it does. CONTROL, EVENT and the logic
## operators have no implementation: `ProgramRunner` handles them itself.

enum Kind {
	ACTION,     ## statement that does something; may span many ticks
	CONDITION,  ## expression returning true/false
	VALUE,      ## expression returning a number
	CONTROL,    ## statement that structures others (if, loops)
	EVENT,      ## top-level `when` handler
}

var op: StringName
var kind: Kind
## Part that unlocks the block; &"" means every chassis has it.
var part: StringName
## Player-facing name, used by the log and (later) the editor.
var label: String
## Argument names the block reads from `args`.
var params: PackedStringArray

# ACTION: func(ctx: DroneContext, args: Dictionary) -> Task
# CONDITION/VALUE: func(ctx: DroneContext, args: Dictionary) -> Variant
var _impl: Callable


func _init(p_op: StringName, p_kind: Kind, p_part: StringName, p_label: String,
		p_params: PackedStringArray = PackedStringArray(), p_impl: Callable = Callable()) -> void:
	op = p_op
	kind = p_kind
	part = p_part
	label = p_label
	params = p_params
	_impl = p_impl


func is_statement() -> bool:
	return kind == Kind.ACTION or kind == Kind.CONTROL


func is_expression() -> bool:
	return kind == Kind.CONDITION or kind == Kind.VALUE


func start(ctx: DroneContext, args: Dictionary) -> Task:
	return _impl.call(ctx, args)


func evaluate(ctx: DroneContext, args: Dictionary) -> Variant:
	return _impl.call(ctx, args)
