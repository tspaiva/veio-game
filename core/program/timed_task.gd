class_name TimedTask
extends Task
## Succeeds after a fixed number of ticks (the tick it starts on counts).

var _remaining: int


func _init(ticks: int) -> void:
	_remaining = maxi(ticks, 1)


func tick(_ctx: DroneContext) -> Status:
	_remaining -= 1
	return Status.SUCCESS if _remaining <= 0 else Status.RUNNING
