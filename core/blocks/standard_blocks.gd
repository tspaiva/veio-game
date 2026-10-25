class_name StandardBlocks
extends RefCounted
## The prototype's block library, grouped by the part that unlocks each
## block (GDD 7.2, D9). Actions and sensors delegate to `DroneContext`.

## Part ids. Chassis are parts too, so class-exclusive blocks use the same rule.
const CHASSIS_SCOUT := &"chassis_scout"
const CHASSIS_MINER := &"chassis_miner"
const CHASSIS_DEFENDER := &"chassis_defender"
const DRILL := &"drill"
const CARGO := &"cargo"
const BATTERY := &"battery"
const ORE_SCANNER := &"ore_scanner"
const THREAT_SENSOR := &"threat_sensor"
const WEAPON := &"weapon"
const ANTENNA := &"antenna"

const PART_LABEL := {
	CHASSIS_SCOUT: "chassi de Batedor",
	CHASSIS_MINER: "chassi de Minerador",
	CHASSIS_DEFENDER: "chassi de Defensor",
	DRILL: "broca",
	CARGO: "compartimento de carga",
	BATTERY: "bateria",
	ORE_SCANNER: "scanner de minério",
	THREAT_SENSOR: "sensor de ameaça",
	WEAPON: "arma",
	ANTENNA: "antena",
}


static func register_all(r: BlockRegistry) -> void:
	# Control and logic: implemented by ProgramRunner.
	r.control(&"if", "se")
	r.control(&"forever", "repetir sempre")
	r.control(&"repeat", "repetir", PackedStringArray(["times"]))
	r.control(&"repeat_until", "repetir até")
	r.event(&"when", "quando")
	r.logic(&"and", "e")
	r.logic(&"or", "ou")
	r.logic(&"not", "não")
	r.logic(&"compare", "comparar")

	# Every chassis.
	r.action(&"wait", &"", "esperar", PackedStringArray(["ticks"]),
		func(_ctx: DroneContext, a: Dictionary) -> Task: return TimedTask.new(int(a.get("ticks", 1))))
	r.action(&"move", &"", "mover", PackedStringArray(["direction", "tiles"]),
		func(ctx: DroneContext, a: Dictionary) -> Task: return ctx.move(StringName(a.get("direction", "")), int(a.get("tiles", 1))))
	r.action(&"return_to_base", &"", "voltar à base", PackedStringArray(),
		func(ctx: DroneContext, _a: Dictionary) -> Task: return ctx.return_to_base())
	r.action(&"goto_miner", &"", "ir até o minerador", PackedStringArray(),
		func(ctx: DroneContext, _a: Dictionary) -> Task: return ctx.goto_miner())

	# Scout chassis.
	r.action(&"explore", CHASSIS_SCOUT, "explorar", PackedStringArray(),
		func(ctx: DroneContext, _a: Dictionary) -> Task: return ctx.explore())

	# Drill.
	r.action(&"dig", DRILL, "cavar", PackedStringArray(["direction"]),
		func(ctx: DroneContext, a: Dictionary) -> Task: return ctx.dig(StringName(a.get("direction", ""))))
	r.action(&"mine", DRILL, "minerar", PackedStringArray(),
		func(ctx: DroneContext, _a: Dictionary) -> Task: return ctx.mine())

	# Cargo.
	r.action(&"unload", CARGO, "descarregar", PackedStringArray(),
		func(ctx: DroneContext, _a: Dictionary) -> Task: return ctx.unload())
	r.condition(&"cargo_full", CARGO, "carga cheia?", PackedStringArray(),
		func(ctx: DroneContext, _a: Dictionary) -> Variant: return ctx.cargo_full())

	# Battery.
	r.action(&"recharge", BATTERY, "recarregar", PackedStringArray(),
		func(ctx: DroneContext, _a: Dictionary) -> Task: return ctx.recharge())
	r.condition(&"battery_low", BATTERY, "bateria baixa?", PackedStringArray(),
		func(ctx: DroneContext, _a: Dictionary) -> Variant: return ctx.battery_low())

	# Ore scanner.
	r.condition(&"sees_ore", ORE_SCANNER, "vejo minério?", PackedStringArray(["ore"]),
		func(ctx: DroneContext, a: Dictionary) -> Variant: return ctx.sees_ore(StringName(a.get("ore", ""))))
	r.action(&"goto_nearest_ore", ORE_SCANNER, "ir até minério mais próximo", PackedStringArray(["ore"]),
		func(ctx: DroneContext, a: Dictionary) -> Task: return ctx.goto_nearest_ore(StringName(a.get("ore", ""))))

	# Threat sensor.
	r.condition(&"threat_nearby", THREAT_SENSOR, "criatura por perto?", PackedStringArray(),
		func(ctx: DroneContext, _a: Dictionary) -> Variant: return ctx.threat_nearby())
	r.condition(&"miner_in_danger", THREAT_SENSOR, "minerador em perigo?", PackedStringArray(),
		func(ctx: DroneContext, _a: Dictionary) -> Variant: return ctx.miner_in_danger())
	r.value(&"threat_distance", THREAT_SENSOR, "distância da criatura", PackedStringArray(),
		func(ctx: DroneContext, _a: Dictionary) -> Variant: return ctx.threat_distance())

	# Weapon.
	r.action(&"shoot", WEAPON, "atirar", PackedStringArray(),
		func(ctx: DroneContext, _a: Dictionary) -> Task: return ctx.shoot())
	r.condition(&"enemy_in_range", WEAPON, "inimigo no alcance?", PackedStringArray(),
		func(ctx: DroneContext, _a: Dictionary) -> Variant: return ctx.enemy_in_range())

	# Antenna.
	r.action(&"send_signal", ANTENNA, "enviar sinal", PackedStringArray(["channel"]),
		func(ctx: DroneContext, a: Dictionary) -> Task: return ctx.send_signal(StringName(a.get("channel", ""))))
	r.condition(&"heard_signal", ANTENNA, "recebi sinal?", PackedStringArray(["channel"]),
		func(ctx: DroneContext, a: Dictionary) -> Variant: return ctx.heard_signal(StringName(a.get("channel", ""))))
	r.action(&"goto_signal_source", ANTENNA, "ir até origem do sinal", PackedStringArray(["channel"]),
		func(ctx: DroneContext, a: Dictionary) -> Task: return ctx.goto_signal_source(StringName(a.get("channel", ""))))


static func part_label(part: StringName) -> String:
	return PART_LABEL.get(part, String(part))
