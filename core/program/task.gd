class_name Task
extends RefCounted
## A running action. `ProgramRunner` ticks it once per simulation tick until
## it stops returning RUNNING. Subclasses override `tick` and `cancel`.
##
## The base class is an action that finishes instantly, or fails instantly
## when built with `Task.failed()`.

enum Status { RUNNING, SUCCESS, FAILURE }

## Why the task failed, shown in the drone log.
var failure_reason := ""

var _fails := false


## An action that succeeds on its first tick.
static func done() -> Task:
	return Task.new()


## An action that fails on its first tick with `reason`.
static func failed(reason: String) -> Task:
	var task := Task.new()
	task._fails = true
	task.failure_reason = reason
	return task


func tick(_ctx: DroneContext) -> Status:
	return Status.FAILURE if _fails else Status.SUCCESS


## Called when a `when` handler interrupts the task before it finished.
func cancel(_ctx: DroneContext) -> void:
	pass
