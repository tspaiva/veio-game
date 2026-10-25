extends TestCase

const S := preload("res://core/blocks/standard_blocks.gd")

var ctx: FakeContext
var registry: BlockRegistry
var _next_id := 1


func before_each() -> void:
	ctx = FakeContext.new()
	registry = BlockRegistry.standard()
	_next_id = 1


# --- Sequencing ------------------------------------------------------------

func test_actions_run_in_order_one_start_per_tick() -> void:
	ctx.durations[&"return_to_base"] = 3
	var runner := _runner([_b("return_to_base"), _b("wait", {"ticks": 1})])
	runner.tick()
	assert_eq(ctx.ops(), [&"return_to_base"])
	assert_eq(runner.state, ProgramRunner.State.RUNNING)
	runner.tick()
	assert_eq(ctx.ops().size(), 1, "still travelling on tick 2")
	runner.tick()
	assert_eq(ctx.ops(), [&"return_to_base"], "wait is not a context call")
	assert_true(runner.drone_log.has_text("esperar"), "wait started when travel ended")


func test_program_halts_when_main_ends() -> void:
	var runner := _runner([_b("return_to_base")])
	runner.tick()
	runner.tick()
	assert_eq(runner.state, ProgramRunner.State.HALTED)
	assert_true(runner.drone_log.has_text("programa terminou"))
	runner.tick()
	assert_eq(ctx.ops().size(), 1, "a halted program does nothing")


func test_forever_repeats_body() -> void:
	var runner := _runner([_loop("forever", [_b("return_to_base")])])
	for i in 5:
		runner.tick()
	assert_eq(ctx.ops().size(), 5)


func test_repeat_runs_body_n_times() -> void:
	ctx.parts = [S.CARGO, S.BATTERY]
	var runner := _runner([_loop("repeat", [_b("unload")], {"times": 3}), _b("recharge")])
	for i in 6:
		runner.tick()
	assert_eq(ctx.ops(), [&"unload", &"unload", &"unload", &"recharge"])


func test_repeat_until_checks_before_each_pass() -> void:
	ctx.sensors[&"cargo_full"] = true
	ctx.parts = [S.CARGO]
	var runner := _runner([_loop("repeat_until", [_b("mine")], {}, _c("cargo_full")), _b("unload")])
	runner.tick()
	assert_eq(ctx.ops(), [&"unload"], "condition already true: body skipped")


func test_repeat_until_stops_when_condition_turns_true() -> void:
	ctx.parts = [S.CARGO, S.DRILL]
	var runner := _runner([_loop("repeat_until", [_b("mine")], {}, _c("cargo_full")), _b("unload")])
	runner.tick()
	runner.tick()
	ctx.sensors[&"cargo_full"] = true
	runner.tick()
	assert_eq(ctx.ops(), [&"mine", &"mine", &"unload"])


# --- Conditions ------------------------------------------------------------

func test_if_takes_then_or_else() -> void:
	ctx.parts = [S.BATTERY]
	var program := [_if(_c("battery_low"), [_b("recharge")], [_b("return_to_base")])]
	var runner := _runner(program)
	runner.tick()
	assert_eq(ctx.ops(), [&"return_to_base"])
	assert_true(runner.drone_log.has_text("se bateria baixa? → não"))

	ctx.calls.clear()
	ctx.sensors[&"battery_low"] = true
	runner.reset()
	runner.tick()
	assert_eq(ctx.ops(), [&"recharge"])


func test_logic_operators() -> void:
	ctx.parts = [S.BATTERY, S.CARGO]
	ctx.sensors[&"cargo_full"] = true
	var both := {"id": _id(), "op": "and", "a": _c("battery_low"), "b": _c("cargo_full")}
	var either := {"id": _id(), "op": "or", "a": _c("battery_low"), "b": _c("cargo_full")}
	var negated := {"id": _id(), "op": "not", "a": _c("battery_low")}
	var runner := _runner([
		_if(both, [_b("move", {"direction": "up", "tiles": 1})]),
		_if(either, [_b("move", {"direction": "down", "tiles": 1})]),
		_if(negated, [_b("move", {"direction": "left", "tiles": 1})]),
	])
	for i in 3:
		runner.tick()
	assert_eq(ctx.calls, [[&"move", &"down", 1], [&"move", &"left", 1]])


func test_compare_with_value_block() -> void:
	ctx.parts = [S.THREAT_SENSOR]
	ctx.sensors[&"threat_distance"] = 2.0
	var near := {"id": _id(), "op": "compare", "cmp": "<", "a": _c("threat_distance"), "b": 3}
	var runner := _runner([_if(near, [_b("return_to_base")], [_b("explore")])])
	runner.tick()
	assert_eq(ctx.ops(), [&"return_to_base"])


func test_compare_with_missing_sensor_is_false() -> void:
	var near := {"id": _id(), "op": "compare", "cmp": "<", "a": _c("threat_distance"), "b": 3}
	var runner := _runner([_if(near, [_b("return_to_base")], [_b("goto_miner")])])
	runner.tick()
	assert_eq(ctx.ops(), [&"goto_miner"])


# --- Missing parts and failures (D5) ---------------------------------------

func test_action_without_part_fails_with_log_and_continues() -> void:
	var runner := _runner([_b("mine"), _b("return_to_base")])
	runner.tick()
	assert_eq(ctx.ops(), [&"return_to_base"], "mine skipped, next block ran")
	assert_true(runner.drone_log.has_text("minerar: sem broca"))


func test_condition_without_part_is_false_with_log() -> void:
	ctx.sensors[&"battery_low"] = true
	var runner := _runner([_if(_c("battery_low"), [_b("recharge")], [_b("return_to_base")])])
	runner.tick()
	assert_eq(ctx.ops(), [&"return_to_base"])
	assert_true(runner.drone_log.has_text("sem bateria"))


func test_scout_only_block_needs_scout_chassis() -> void:
	var runner := _runner([_b("explore")])
	runner.tick()
	assert_true(runner.drone_log.has_text("explorar: sem chassi de Batedor"))
	ctx.parts = [S.CHASSIS_SCOUT]
	runner.reset()
	runner.tick()
	assert_eq(ctx.ops(), [&"explore"])


func test_failed_action_logs_and_continues() -> void:
	ctx.failing[&"return_to_base"] = true
	var runner := _runner([_b("return_to_base"), _b("goto_miner")])
	runner.tick()
	runner.tick()
	assert_eq(ctx.ops(), [&"return_to_base", &"goto_miner"])
	assert_true(runner.drone_log.has_text("voltar à base falhou: falha simulada"))


# --- Step budget (D11) -----------------------------------------------------

func test_loop_without_actions_goes_idle_instead_of_hanging() -> void:
	var runner := _runner([_loop("forever", [])])
	runner.tick()
	assert_eq(runner.state, ProgramRunner.State.IDLE)
	assert_true(runner.drone_log.has_text("ocioso"))


func test_loop_of_failing_blocks_goes_idle() -> void:
	var runner := _runner([_loop("forever", [_b("mine")])])
	runner.tick()
	runner.tick()
	assert_eq(runner.state, ProgramRunner.State.IDLE)
	assert_eq(ctx.calls.size(), 0)


# --- When handlers (D1) ----------------------------------------------------

func test_when_interrupts_action_and_restarts_main() -> void:
	ctx.parts = [S.THREAT_SENSOR, S.CHASSIS_SCOUT]
	ctx.durations[&"explore"] = 10
	var runner := _runner(
		[_b("explore"), _b("goto_miner")],
		[_when(_c("threat_nearby"), [_b("return_to_base")])])
	runner.tick()
	assert_eq(ctx.ops(), [&"explore"])

	ctx.sensors[&"threat_nearby"] = true
	runner.tick()
	assert_eq(ctx.cancelled, [&"explore"])
	assert_eq(ctx.ops(), [&"explore", &"return_to_base"])
	assert_true(runner.is_in_handler())
	assert_true(runner.drone_log.has_text("explorar interrompido"))

	ctx.sensors[&"threat_nearby"] = false
	runner.tick()
	assert_false(runner.is_in_handler())
	assert_eq(ctx.ops(), [&"explore", &"return_to_base", &"explore"], "main restarted from the top")


func test_when_is_level_triggered() -> void:
	ctx.parts = [S.WEAPON]
	var runner := _runner(
		[_loop("forever", [_b("wait", {"ticks": 5})])],
		[_when(_c("enemy_in_range"), [_b("shoot")])])
	ctx.sensors[&"enemy_in_range"] = true
	for i in 4:
		runner.tick()
	assert_eq(ctx.ops(), [&"shoot", &"shoot", &"shoot", &"shoot"], "keeps shooting while in range")


func test_handler_does_not_interrupt_itself() -> void:
	ctx.parts = [S.THREAT_SENSOR]
	ctx.durations[&"return_to_base"] = 5
	ctx.sensors[&"threat_nearby"] = true
	var runner := _runner([], [_when(_c("threat_nearby"), [_b("return_to_base")])])
	for i in 4:
		runner.tick()
	assert_eq(ctx.ops(), [&"return_to_base"], "still running its own action")
	assert_eq(ctx.cancelled.size(), 0)
	runner.tick()
	assert_eq(ctx.ops(), [&"return_to_base", &"return_to_base"], "body ended, condition holds: runs again")
	assert_eq(ctx.cancelled.size(), 0)


func test_higher_priority_handler_preempts_lower() -> void:
	ctx.parts = [S.THREAT_SENSOR, S.WEAPON]
	ctx.durations[&"goto_miner"] = 10
	var runner := _runner([], [
		_when(_c("enemy_in_range"), [_b("shoot")]),
		_when(_c("miner_in_danger"), [_b("goto_miner")]),
	])
	ctx.sensors[&"miner_in_danger"] = true
	runner.tick()
	assert_eq(ctx.ops(), [&"goto_miner"])
	ctx.sensors[&"enemy_in_range"] = true
	runner.tick()
	assert_eq(ctx.ops(), [&"goto_miner", &"shoot"])
	assert_eq(ctx.cancelled, [&"goto_miner"])


func test_lower_priority_handler_waits_for_higher() -> void:
	ctx.parts = [S.THREAT_SENSOR, S.WEAPON]
	ctx.durations[&"shoot"] = 5
	var runner := _runner([], [
		_when(_c("enemy_in_range"), [_b("shoot")]),
		_when(_c("miner_in_danger"), [_b("goto_miner")]),
	])
	ctx.sensors[&"enemy_in_range"] = true
	runner.tick()
	ctx.sensors[&"miner_in_danger"] = true
	runner.tick()
	assert_eq(ctx.ops(), [&"shoot"])
	assert_eq(ctx.cancelled.size(), 0)


func test_handler_wakes_halted_program() -> void:
	ctx.parts = [S.THREAT_SENSOR]
	var runner := _runner([_b("unload")], [_when(_c("threat_nearby"), [_b("return_to_base")])])
	ctx.parts.append(S.CARGO)
	runner.tick()
	runner.tick()
	assert_eq(runner.state, ProgramRunner.State.HALTED)
	ctx.sensors[&"threat_nearby"] = true
	runner.tick()
	assert_eq(ctx.ops(), [&"unload", &"return_to_base"])


# --- Parameters (D9) -------------------------------------------------------

func test_param_uses_drone_value_then_declared_default() -> void:
	ctx.parts = [S.ORE_SCANNER]
	var main := [_b("goto_nearest_ore", {"ore": {"param": "target_ore"}})]
	var params := {"target_ore": {"type": "ore", "default": "iron"}}

	var runner := _runner(main, [], params)
	runner.tick()
	assert_eq(ctx.calls[-1], [&"goto_nearest_ore", &"iron"], "falls back to default")

	ctx.params[&"target_ore"] = "copper"
	runner.reset()
	runner.tick()
	assert_eq(ctx.calls[-1], [&"goto_nearest_ore", &"copper"], "drone value wins")


# --- Debugging -------------------------------------------------------------

func test_current_block_tracks_running_action() -> void:
	ctx.durations[&"return_to_base"] = 3
	var first := _b("return_to_base")
	var loop := _loop("forever", [first])
	var runner := _runner([loop])
	var entered: Array[int] = []
	runner.block_entered.connect(func(id: int) -> void: entered.append(id))
	runner.tick()
	assert_eq(runner.current_block_id, first.id)
	assert_eq(entered, [loop.id, first.id], "loop block, then the action")


func test_set_program_restarts_with_new_routine() -> void:
	var runner := _runner([_loop("forever", [_b("return_to_base")])])
	runner.tick()
	runner.set_program(_program([_loop("forever", [_b("goto_miner")])]))
	runner.tick()
	assert_eq(ctx.ops(), [&"return_to_base", &"goto_miner"])


func test_invalid_program_errors_and_never_runs() -> void:
	var runner := _runner([_b("no_such_block")])
	assert_eq(runner.state, ProgramRunner.State.ERROR)
	runner.tick()
	assert_eq(ctx.calls.size(), 0)
	assert_true(runner.drone_log.has_text("bloco desconhecido"))


# --- Helpers ---------------------------------------------------------------

func _runner(main: Array, handlers: Array = [], params: Dictionary = {}) -> ProgramRunner:
	return ProgramRunner.new(_program(main, handlers, params), ctx, registry)


func _program(main: Array, handlers: Array = [], params: Dictionary = {}) -> Program:
	return Program.from_dict({"main": main, "handlers": handlers, "params": params})


func _id() -> int:
	_next_id += 1
	return _next_id


func _b(op: String, args: Dictionary = {}) -> Dictionary:
	return {"id": _id(), "op": op, "args": args}


func _c(op: String, args: Dictionary = {}) -> Dictionary:
	return {"id": _id(), "op": op, "args": args}


func _if(cond: Dictionary, then_blocks: Array, else_blocks: Array = []) -> Dictionary:
	return {"id": _id(), "op": "if", "cond": cond, "then": then_blocks, "else": else_blocks}


func _loop(op: String, body: Array, args: Dictionary = {}, cond: Variant = null) -> Dictionary:
	var block := {"id": _id(), "op": op, "body": body, "args": args}
	if cond != null:
		block.cond = cond
	return block


func _when(cond: Dictionary, body: Array) -> Dictionary:
	return {"id": _id(), "op": "when", "cond": cond, "body": body}
