class_name TileTypes
extends RefCounted
## Static table of mine tile types: digging rules and placeholder names.
## Values are indexed by `Type` and stored per cell in `MineData`.
## Ore is not a tile type: deposits (D15) cover cells of type DEPOSIT and
## hold the ore and its stock themselves.

enum Type {
	AIR,
	DIRT,
	ROCK,
	HARD_ROCK,
	DEPOSIT,
	BEDROCK,
	LADDER,
}

const COUNT := 7

## Tool tier that can never dig a tile. Deposits are extracted, not dug.
const UNDIGGABLE := 99

# Seconds to dig with a tier-1 tool. Indexed by Type.
const DIG_TIME: Array[float] = [
	0.0,   # AIR
	0.25,  # DIRT
	0.6,   # ROCK
	1.5,   # HARD_ROCK
	0.0,   # DEPOSIT
	0.0,   # BEDROCK
	0.15,  # LADDER
]

# Minimum tool tier required to dig. Indexed by Type.
const TIER: Array[int] = [
	0,           # AIR
	1,           # DIRT
	1,           # ROCK
	2,           # HARD_ROCK
	UNDIGGABLE,  # DEPOSIT
	UNDIGGABLE,  # BEDROCK
	1,           # LADDER
]

const DISPLAY_NAME: Array[String] = [
	"Ar", "Terra", "Rocha", "Rocha dura", "Jazida", "Leito rochoso", "Escada",
]


## Blocks movement for walkers and fliers.
static func is_solid(type: int) -> bool:
	return type != Type.AIR and type != Type.LADDER


static func is_diggable(type: int, tool_tier: int) -> bool:
	return type != Type.AIR and TIER[type] != UNDIGGABLE and tool_tier >= TIER[type]
