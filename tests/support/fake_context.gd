class_name FakeContext
extends DroneContext
## Scriptable DroneContext for interpreter tests.
##
## Set `parts`, `params` and `sensors`; every action is recorded in `calls`
## as [op, args...] and lasts `durations[op]` ticks (default 1), failing if
## `failing[op]` is true.

var parts: Array[StringName] = []
var params: Dictionary = {}
## Sensor name -> value, e.g. { &"battery_low": true, &"threat_distance": 3.0 }.
var sensors: Dictionary = {}
var durations: Dictionary = {}
var failing: Dictionary = {}

var calls: Array = []
var cancelled: Array[StringName] = []


func has_part(part: StringName) -> bool:
	return parts.has(part)


func param(name: StringName) -> Variant:
	return params.get(name)


## Ops of the recorded calls, in order.
func ops() -> Array[StringName]:
	var result: Array[StringName] = []
	for call in calls:
		result.append(call[0])
	return result


func battery_low() -> bool: return sensors.get(&"battery_low", false)
func cargo_full() -> bool: return sensors.get(&"cargo_full", false)
func sees_ore(ore: StringName) -> bool: return sensors.get(&"sees_ore", []).has(ore)
func threat_nearby() -> bool: return sensors.get(&"threat_nearby", false)
func threat_distance() -> float: return sensors.get(&"threat_distance", INF)
func miner_in_danger() -> bool: return sensors.get(&"miner_in_danger", false)
func enemy_in_range() -> bool: return sensors.get(&"enemy_in_range", false)
func heard_signal(channel: StringName) -> bool: return sensors.get(&"heard_signal", []).has(channel)

func move(direction: StringName, tiles: int) -> Task: return _action(&"move", [direction, tiles])
func return_to_base() -> Task: return _action(&"return_to_base")
func goto_miner() -> Task: return _action(&"goto_miner")
func explore() -> Task: return _action(&"explore")
func dig(direction: StringName) -> Task: return _action(&"dig", [direction])
func mine() -> Task: return _action(&"mine")
func unload() -> Task: return _action(&"unload")
func recharge() -> Task: return _action(&"recharge")
func goto_nearest_ore(ore: StringName) -> Task: return _action(&"goto_nearest_ore", [ore])
func shoot() -> Task: return _action(&"shoot")
func send_signal(channel: StringName) -> Task: return _action(&"send_signal", [channel])
func goto_signal_source(channel: StringName) -> Task: return _action(&"goto_signal_source", [channel])


func _action(op: StringName, args: Array = []) -> Task:
	calls.append([op] + args)
	return FakeTask.new(self, op, durations.get(op, 1), failing.get(op, false))


class FakeTask extends Task:
	var _ctx: FakeContext
	var _op: StringName
	var _remaining: int
	var _fail: bool

	func _init(ctx: FakeContext, op: StringName, ticks: int, fail: bool) -> void:
		_ctx = ctx
		_op = op
		_remaining = ticks
		_fail = fail
		failure_reason = "falha simulada" if fail else ""

	func tick(_c: DroneContext) -> Status:
		_remaining -= 1
		if _remaining > 0:
			return Status.RUNNING
		return Status.FAILURE if _fail else Status.SUCCESS

	func cancel(_c: DroneContext) -> void:
		_ctx.cancelled.append(_op)
