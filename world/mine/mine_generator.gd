class_name MineGenerator
extends RefCounted
## Builds a layer-1 mine from a seed (D3). Same seed, same mine.
##
## Layout, top to bottom: open sky, a flat surface, a dirt band of noisy
## thickness, then rock with caves and hard-rock pockets. Ore comes in
## deposits (D15) scattered by depth, with one iron deposit always close to
## the spawn. The map is framed by bedrock.

const DEFAULT_WIDTH := 128
const DEFAULT_HEIGHT := 192
const SURFACE_ROW := 10

## Depth (rows below the surface) where each feature starts appearing.
const CAVE_MIN_DEPTH := 12
const HARD_ROCK_MIN_DEPTH := 18

## Half-width of the area around the spawn kept free of caves.
const SPAWN_CLEAR_RADIUS := 6

## Minimum gap, in tiles, between two deposits.
const DEPOSIT_SPACING := 5
const PLACEMENT_ATTEMPTS := 40

## How many deposits of each ore, from which depth, in which sizes and with
## what starting stock.
const DEPOSIT_RULES := [
	{"ore": &"iron", "count": 14, "min_depth": 3, "sizes": [Vector2i(2, 2), Vector2i(3, 2)], "stock": [300, 500]},
	{"ore": &"copper", "count": 10, "min_depth": 6, "sizes": [Vector2i(2, 2), Vector2i(3, 2)], "stock": [250, 400]},
	{"ore": &"crystal", "count": 6, "min_depth": 35, "sizes": [Vector2i(2, 2)], "stock": [120, 200]},
]

## The guaranteed iron deposit: this many tiles beside the spawn column and
## this many rows below the surface.
const STARTER_OFFSET_X := Vector2i(3, 8)
const STARTER_DEPTH := Vector2i(3, 6)
const STARTER_STOCK := 400


static func generate(map_seed: int, width: int = DEFAULT_WIDTH, height: int = DEFAULT_HEIGHT) -> MineData:
	var data := MineData.new(width, height, SURFACE_ROW, map_seed)
	_fill_terrain(data, map_seed)
	_place_deposits(data, map_seed)
	return data


static func spawn_cell(data: MineData) -> Vector2i:
	return Vector2i(data.width / 2, data.surface_row - 1)


static func _fill_terrain(data: MineData, map_seed: int) -> void:
	var dirt := _noise(map_seed, 0.05)
	var caves := _noise(map_seed + 1, 0.06)
	var hard := _noise(map_seed + 2, 0.08)
	var spawn_x := data.width / 2

	for y in data.height:
		for x in data.width:
			var cell := Vector2i(x, y)
			var depth := y - SURFACE_ROW
			var type: int

			if x == 0 or x == data.width - 1 or y == data.height - 1:
				type = TileTypes.Type.BEDROCK
			elif depth < 0:
				type = TileTypes.Type.AIR
			else:
				var dirt_depth := 5.0 + 3.0 * dirt.get_noise_1d(x)
				type = TileTypes.Type.DIRT if depth < dirt_depth else TileTypes.Type.ROCK

				var near_spawn := absi(x - spawn_x) <= SPAWN_CLEAR_RADIUS
				if depth >= CAVE_MIN_DEPTH and not near_spawn and caves.get_noise_2d(x, y * 1.8) > 0.38:
					type = TileTypes.Type.AIR
				elif depth >= HARD_ROCK_MIN_DEPTH and hard.get_noise_2d(x, y) > 0.45:
					type = TileTypes.Type.HARD_ROCK

			data.set_tile_silent(cell, type)
			# Sky and the surface row start visible.
			if depth <= 0:
				data.reveal_silent(cell)


static func _place_deposits(data: MineData, map_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed
	var taken: Array[Rect2i] = []

	var side := 1 if rng.randf() < 0.5 else -1
	var starter := Rect2i(
		Vector2i(data.width / 2 + side * rng.randi_range(STARTER_OFFSET_X.x, STARTER_OFFSET_X.y),
			SURFACE_ROW + rng.randi_range(STARTER_DEPTH.x, STARTER_DEPTH.y)),
		Vector2i(2, 2))
	if side < 0:
		starter.position.x -= starter.size.x - 1
	_try_place(data, taken, Ores.IRON, starter, STARTER_STOCK)

	for rule in DEPOSIT_RULES:
		var placed := 0
		for _attempt in rule.count * PLACEMENT_ATTEMPTS:
			if placed >= rule.count:
				break
			var size: Vector2i = rule.sizes[rng.randi_range(0, rule.sizes.size() - 1)]
			var top := SURFACE_ROW + int(rule.min_depth)
			if top + size.y >= data.height - 1:
				break
			var rect := Rect2i(
				Vector2i(rng.randi_range(1, data.width - 1 - size.x), rng.randi_range(top, data.height - 1 - size.y)),
				size)
			var stock := rng.randi_range(rule.stock[0], rule.stock[1])
			if _try_place(data, taken, rule.ore, rect, stock):
				placed += 1


static func _try_place(data: MineData, taken: Array[Rect2i], ore: StringName, rect: Rect2i, stock: int) -> bool:
	var padded := rect.grow(DEPOSIT_SPACING)
	for other in taken:
		if padded.intersects(other):
			return false
	if data.add_deposit(ore, rect, stock) == null:
		return false
	taken.append(rect)
	return true


static func _noise(map_seed: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = map_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_octaves = 2
	return noise
