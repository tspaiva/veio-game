extends TestCase
## The routines each class starts with (D8, D9), run against a fake drone.

const S := preload("res://core/blocks/standard_blocks.gd")
const ROUTINES := ["miner", "defender", "scout"]

var registry: BlockRegistry
var ctx: FakeContext


func before_each() -> void:
	registry = BlockRegistry.standard()
	ctx = FakeContext.new()


func test_all_starter_routines_load_and_validate() -> void:
	for routine in ROUTINES:
		var program := _load(routine)
		assert_not_null(program, "%s loads" % routine)
		if program != null:
			assert_eq(program.validate(registry), PackedStringArray(), "%s is valid" % routine)
			assert_eq(String(program.drone_class), routine)


func test_miner_mines_its_target_ore() -> void:
	ctx.parts = [S.CHASSIS_MINER, S.DRILL, S.CARGO, S.BATTERY, S.ORE_SCANNER]
	ctx.params[&"target_ore"] = "copper"
	ctx.sensors[&"sees_ore"] = [&"copper"]
	var runner := _run("miner", 2)
	assert_eq(ctx.calls, [[&"goto_nearest_ore", &"copper"], [&"mine"]])
	assert_eq(runner.state, ProgramRunner.State.RUNNING)


func test_miner_unloads_when_full() -> void:
	ctx.parts = [S.CHASSIS_MINER, S.DRILL, S.CARGO, S.BATTERY, S.ORE_SCANNER]
	ctx.sensors[&"cargo_full"] = true
	_run("miner", 2)
	assert_eq(ctx.ops(), [&"return_to_base", &"unload"])


func test_miner_starter_flaw_ignores_low_battery() -> void:
	# D8: the starter routine works but never checks the battery. Fixing it is
	# the player's first programming task.
	ctx.parts = [S.CHASSIS_MINER, S.DRILL, S.CARGO, S.BATTERY, S.ORE_SCANNER]
	ctx.sensors[&"battery_low"] = true
	ctx.sensors[&"sees_ore"] = [&"iron"]
	_run("miner", 4)
	assert_false(ctx.ops().has(&"return_to_base"))
	assert_false(ctx.ops().has(&"recharge"))


func test_defender_shoots_whenever_enemy_in_range() -> void:
	ctx.parts = [S.CHASSIS_DEFENDER, S.WEAPON, S.THREAT_SENSOR, S.ANTENNA, S.BATTERY]
	ctx.durations[&"goto_miner"] = 20
	ctx.sensors[&"miner_in_danger"] = true
	var runner := _run("defender", 2)
	assert_eq(ctx.ops(), [&"goto_miner"])
	ctx.sensors[&"enemy_in_range"] = true
	runner.tick()
	assert_eq(ctx.ops(), [&"goto_miner", &"shoot"])
	assert_eq(ctx.cancelled, [&"goto_miner"])


func test_defender_answers_help_signal() -> void:
	ctx.parts = [S.CHASSIS_DEFENDER, S.WEAPON, S.THREAT_SENSOR, S.ANTENNA, S.BATTERY]
	ctx.sensors[&"heard_signal"] = [&"socorro"]
	_run("defender", 1)
	assert_eq(ctx.calls, [[&"goto_signal_source", &"socorro"]])


func test_scout_explores_and_recharges() -> void:
	ctx.parts = [S.CHASSIS_SCOUT, S.BATTERY, S.ANTENNA]
	var runner := _run("scout", 2)
	assert_eq(ctx.ops(), [&"explore", &"explore"])
	ctx.sensors[&"battery_low"] = true
	runner.tick()
	runner.tick()
	assert_eq(ctx.ops(), [&"explore", &"explore", &"return_to_base", &"recharge"])


func _load(routine: String) -> Program:
	return Program.load_file("res://data/routines/%s.json" % routine)


func _run(routine: String, ticks: int) -> ProgramRunner:
	var runner := ProgramRunner.new(_load(routine), ctx, registry)
	for i in ticks:
		runner.tick()
	return runner
