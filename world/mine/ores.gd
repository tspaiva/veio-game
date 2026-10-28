class_name Ores
extends RefCounted
## Ore kinds found in deposits (D15): display name, color, hand-extraction
## time and the stock range a new deposit starts with.

const IRON := &"iron"
const COPPER := &"copper"
const CRYSTAL := &"crystal"

const ALL: Array[StringName] = [IRON, COPPER, CRYSTAL]

const _INFO := {
	IRON: {"name": "Ferro", "color": Color("c9b8a6"), "extract_time": 0.5},
	COPPER: {"name": "Cobre", "color": Color("d27a3c"), "extract_time": 0.5},
	CRYSTAL: {"name": "Cristal do Veio", "color": Color("5ef2e6"), "extract_time": 0.9},
}


static func display_name(ore: StringName) -> String:
	return _INFO[ore].name


static func color(ore: StringName) -> Color:
	return _INFO[ore].color


## Seconds for the player to extract one unit by hand.
static func extract_time(ore: StringName) -> float:
	return _INFO[ore].extract_time
