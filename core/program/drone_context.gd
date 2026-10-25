class_name DroneContext
extends RefCounted
## Everything a block can ask of, or do in, the world.
##
## Sensors return plain values. Actions return a `Task` that the runner ticks
## until it finishes. The in-game Drone implements this (M3); tests use a
## fake. Defaults describe a drone that senses nothing and can do nothing,
## so a new capability only needs overriding where it exists.
##
## Adding a part = adding its sensors/actions here and its blocks in
## `StandardBlocks`; the interpreter does not change.


func has_part(_part: StringName) -> bool:
	return false


## This drone's value for a routine parameter (D9), or null if unset.
func param(_name: StringName) -> Variant:
	return null


# --- Sensors ---------------------------------------------------------------

func battery_low() -> bool:
	return false


func cargo_full() -> bool:
	return false


func sees_ore(_ore: StringName) -> bool:
	return false


func threat_nearby() -> bool:
	return false


func threat_distance() -> float:
	return INF


func miner_in_danger() -> bool:
	return false


func enemy_in_range() -> bool:
	return false


func heard_signal(_channel: StringName) -> bool:
	return false


# --- Actions ---------------------------------------------------------------

func move(_direction: StringName, _tiles: int) -> Task:
	return _unsupported("mover")


func return_to_base() -> Task:
	return _unsupported("voltar à base")


func goto_miner() -> Task:
	return _unsupported("ir até o minerador")


func explore() -> Task:
	return _unsupported("explorar")


func dig(_direction: StringName) -> Task:
	return _unsupported("cavar")


func mine() -> Task:
	return _unsupported("minerar")


func unload() -> Task:
	return _unsupported("descarregar")


func recharge() -> Task:
	return _unsupported("recarregar")


func goto_nearest_ore(_ore: StringName) -> Task:
	return _unsupported("ir até minério")


func shoot() -> Task:
	return _unsupported("atirar")


func send_signal(_channel: StringName) -> Task:
	return _unsupported("enviar sinal")


func goto_signal_source(_channel: StringName) -> Task:
	return _unsupported("ir até origem do sinal")


func _unsupported(what: String) -> Task:
	return Task.failed("%s não está disponível" % what)
