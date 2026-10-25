class_name ProgramRunner
extends RefCounted
## Runs a `Program` for one drone, one simulation tick at a time (D1, D11).
##
## Each tick:
##   1. `when` handlers are checked, highest priority first. A true one that
##      outranks what is running cancels the current action and runs its
##      body. Handlers are level-triggered: while the condition holds, the
##      handler runs again as soon as its body ends.
##   2. The running action, if any, is ticked. If still RUNNING, the tick ends.
##   3. Otherwise control blocks and conditions run instantly until the next
##      action starts (at most one action starts per tick). After
##      STEP_BUDGET steps without an action the drone is IDLE for this tick.
##
## When a handler body ends, `main` restarts from the top. When `main` ends
## the drone HALTS (handlers can still wake it). A block whose part is
## missing fails and logs why (D5); a failed action logs and execution
## continues with the next block.

signal block_entered(block_id: int)

enum State { RUNNING, IDLE, HALTED, ERROR }

const STEP_BUDGET := 32
const NO_HANDLER := -1

var program: Program
var ctx: DroneContext
var registry: BlockRegistry
var drone_log := DroneLog.new()
var state := State.RUNNING
## Block to highlight in the editor/debugger.
var current_block_id := -1
var tick_count := 0

# Frames: { "blocks": Array, "index": int, "loop": StringName,
#           "remaining": int, "block": Dictionary }
var _stack: Array[Dictionary] = []
var _task: Task
var _task_label := ""
var _active_handler := NO_HANDLER


func _init(p_program: Program, p_ctx: DroneContext, p_registry: BlockRegistry) -> void:
	ctx = p_ctx
	registry = p_registry
	set_program(p_program)


## Swaps the routine and restarts it (D6). Invalid programs put the runner
## in ERROR with the reasons in the log.
func set_program(p_program: Program) -> void:
	program = p_program
	var errors := program.validate(registry)
	if not errors.is_empty():
		_cancel_task()
		_stack.clear()
		state = State.ERROR
		for error in errors:
			_log("erro: " + error)
		return
	reset()


func reset() -> void:
	_cancel_task()
	_active_handler = NO_HANDLER
	_stack = [_frame(program.main)]
	state = State.RUNNING


func is_in_handler() -> bool:
	return _active_handler != NO_HANDLER


func tick() -> void:
	if state == State.ERROR:
		return
	tick_count += 1
	_check_handlers()

	if _task != null:
		var status := _task.tick(ctx)
		if status == Task.Status.RUNNING:
			state = State.RUNNING
			return
		_finish_task(status)

	_run_steps()


# Starts the highest-priority true handler that outranks what is running.
# Returns true if one fired.
func _check_handlers() -> bool:
	var outranked := program.handlers.size() if _active_handler == NO_HANDLER else _active_handler
	for i in outranked:
		var handler: Dictionary = program.handlers[i]
		if not _truthy(_eval(handler.cond)):
			continue
		if _task != null:
			_log("%s interrompido" % _task_label)
		_cancel_task()
		_active_handler = i
		_stack = [_frame(handler.get("body", []))]
		state = State.RUNNING
		_enter(handler)
		_log("quando %s" % _expr_label(handler.cond))
		return true
	return false


func _run_steps() -> void:
	for _i in STEP_BUDGET:
		if _stack.is_empty():
			if is_in_handler():
				# A handler whose condition still holds runs again right away,
				# so `when enemy in range: shoot` fires every tick.
				_active_handler = NO_HANDLER
				if not _check_handlers():
					_stack = [_frame(program.main)]
					_log("fim do quando: programa reiniciado")
				continue
			if state != State.HALTED:
				_log("programa terminou")
			state = State.HALTED
			return
		if _step():
			return
	state = State.IDLE
	_log("ocioso: nenhuma ação em %d passos" % STEP_BUDGET)


# Runs one instant step. Returns true when an action was started.
func _step() -> bool:
	var frame: Dictionary = _stack[-1]
	var blocks: Array = frame.blocks
	if frame.index >= blocks.size():
		_end_of_list(frame)
		return false

	var block: Dictionary = blocks[frame.index]
	frame.index += 1
	_enter(block)

	match StringName(block.op):
		&"if":
			var taken := _truthy(_eval(block.cond))
			_log("se %s → %s" % [_expr_label(block.cond), "sim" if taken else "não"])
			var branch: Array = block.get("then" if taken else "else", [])
			if not branch.is_empty():
				_stack.append(_frame(branch))
		&"forever":
			_stack.append(_frame(block.get("body", []), &"forever"))
		&"repeat":
			var times := int(_resolve_args(block).get("times", 0))
			if times > 0:
				_stack.append(_frame(block.get("body", []), &"repeat", times))
		&"repeat_until":
			if not _truthy(_eval(block.cond)):
				_stack.append(_frame(block.get("body", []), &"repeat_until", 0, block))
		_:
			return _start_action(block)
	return false


func _end_of_list(frame: Dictionary) -> void:
	match frame.loop:
		&"forever":
			frame.index = 0
		&"repeat":
			frame.remaining -= 1
			if frame.remaining > 0:
				frame.index = 0
			else:
				_stack.pop_back()
		&"repeat_until":
			if _truthy(_eval(frame.block.cond)):
				_stack.pop_back()
			else:
				frame.index = 0
		_:
			_stack.pop_back()


# Returns true if the action started (even if it finished at once).
func _start_action(block: Dictionary) -> bool:
	var def := registry.get_def(StringName(block.op))
	if not _has_part_for(def):
		return false
	var args := _resolve_args(block)
	_task = def.start(ctx, args)
	_task_label = _describe(def, args)
	_log(_task_label)
	state = State.RUNNING
	var status := _task.tick(ctx)
	if status != Task.Status.RUNNING:
		_finish_task(status)
	return true


func _finish_task(status: Task.Status) -> void:
	if status == Task.Status.FAILURE:
		var reason := _task.failure_reason
		_log("%s falhou%s" % [_task_label, ": " + reason if not reason.is_empty() else ""])
	_task = null


func _cancel_task() -> void:
	if _task != null:
		_task.cancel(ctx)
		_task = null


func _eval(expr: Variant) -> Variant:
	if not expr is Dictionary:
		return expr  # number literal inside compare
	match StringName(expr.op):
		&"and":
			return _truthy(_eval(expr.a)) and _truthy(_eval(expr.b))
		&"or":
			return _truthy(_eval(expr.a)) or _truthy(_eval(expr.b))
		&"not":
			return not _truthy(_eval(expr.a))
		&"compare":
			return _compare(expr.cmp, _eval(expr.a), _eval(expr.b))
	var def := registry.get_def(StringName(expr.op))
	if not _has_part_for(def):
		return null
	return def.evaluate(ctx, _resolve_args(expr))


func _compare(cmp: String, a: Variant, b: Variant) -> bool:
	var numeric := [TYPE_INT, TYPE_FLOAT]
	if not typeof(a) in numeric or not typeof(b) in numeric:
		return false
	match cmp:
		"<": return a < b
		"<=": return a <= b
		">": return a > b
		">=": return a >= b
		"==": return is_equal_approx(a, b)
		"!=": return not is_equal_approx(a, b)
	return false


func _has_part_for(def: BlockDef) -> bool:
	if def.part == &"" or ctx.has_part(def.part):
		return true
	_log("%s: sem %s" % [def.label, StandardBlocks.part_label(def.part)])
	return false


func _resolve_args(block: Dictionary) -> Dictionary:
	var resolved := {}
	var args: Dictionary = block.get("args", {})
	for key in args:
		var value = args[key]
		if value is Dictionary and value.has("param"):
			var param_name := StringName(str(value.param))
			value = ctx.param(param_name)
			if value == null:
				value = program.param_default(param_name)
		resolved[key] = value
	return resolved


func _truthy(value: Variant) -> bool:
	return value is bool and value


func _enter(block: Dictionary) -> void:
	current_block_id = block.id
	block_entered.emit(block.id)


func _frame(blocks: Array, loop: StringName = &"", remaining: int = 0, block: Dictionary = {}) -> Dictionary:
	return {"blocks": blocks, "index": 0, "loop": loop, "remaining": remaining, "block": block}


func _describe(def: BlockDef, args: Dictionary) -> String:
	if args.is_empty():
		return def.label
	var values := PackedStringArray()
	for key in def.params:
		if args.has(key):
			values.append(str(args[key]))
	return "%s [%s]" % [def.label, ", ".join(values)]


func _expr_label(expr: Variant) -> String:
	if not expr is Dictionary:
		return str(expr)
	match StringName(expr.op):
		&"and":
			return "(%s e %s)" % [_expr_label(expr.a), _expr_label(expr.b)]
		&"or":
			return "(%s ou %s)" % [_expr_label(expr.a), _expr_label(expr.b)]
		&"not":
			return "não %s" % _expr_label(expr.a)
		&"compare":
			return "%s %s %s" % [_expr_label(expr.a), expr.cmp, _expr_label(expr.b)]
	var def := registry.get_def(StringName(expr.op))
	return _describe(def, _resolve_args(expr))


func _log(text: String) -> void:
	drone_log.add(tick_count, text)
