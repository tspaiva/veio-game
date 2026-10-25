class_name TileTypes
extends RefCounted
## Static table of mine tile types: digging rules, drops and placeholder colors.
## Values are indexed by `Type` and stored per cell in `MineData`.

enum Type {
	AIR,
	DIRT,
	ROCK,
	HARD_ROCK,
	IRON,
	COPPER,
	CRYSTAL,
	BEDROCK,
	LADDER,
}

const COUNT := 9

## Tool tier that can never dig a tile (bedrock).
const UNDIGGABLE := 99

# Seconds to dig with a tier-1 tool. Indexed by Type.
const DIG_TIME: Array[float] = [
	0.0,   # AIR
	0.25,  # DIRT
	0.6,   # ROCK
	1.5,   # HARD_ROCK
	0.8,   # IRON
	0.8,   # COPPER
	1.2,   # CRYSTAL
	0.0,   # BEDROCK
	0.15,  # LADDER
]

# Minimum tool tier required to dig. Indexed by Type.
const TIER: Array[int] = [
	0,           # AIR
	1,           # DIRT
	1,           # ROCK
	2,           # HARD_ROCK
	1,           # IRON
	1,           # COPPER
	1,           # CRYSTAL
	UNDIGGABLE,  # BEDROCK
	1,           # LADDER
]

# Resource yielded when dug; &"" yields nothing. Indexed by Type.
const DROP: Array[StringName] = [
	&"",         # AIR
	&"",         # DIRT
	&"",         # ROCK
	&"",         # HARD_ROCK
	&"iron",     # IRON
	&"copper",   # COPPER
	&"crystal",  # CRYSTAL
	&"",         # BEDROCK
	&"ladder",   # LADDER: refunded when removed
]

const DISPLAY_NAME: Array[String] = [
	"Ar", "Terra", "Rocha", "Rocha dura", "Ferro", "Cobre", "Cristal do Veio", "Leito rochoso", "Escada",
]


## Blocks movement for walkers and fliers.
static func is_solid(type: int) -> bool:
	return type != Type.AIR and type != Type.LADDER


static func is_diggable(type: int, tool_tier: int) -> bool:
	return type != Type.AIR and tool_tier >= TIER[type]
