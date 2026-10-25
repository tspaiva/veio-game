class_name MineGenerator
extends RefCounted
## Builds a layer-1 mine from a seed (D3). Same seed, same mine.
##
## Layout, top to bottom: open sky, a flat surface, a dirt band of noisy
## thickness, then rock with caves, hard-rock pockets and ore veins.
## The map is framed by bedrock.

const DEFAULT_WIDTH := 128
const DEFAULT_HEIGHT := 192
const SURFACE_ROW := 10

## Depth (rows below the surface) where each feature starts appearing.
const CAVE_MIN_DEPTH := 12
const HARD_ROCK_MIN_DEPTH := 18
const CRYSTAL_MIN_DEPTH := 35

## Half-width of the area around the spawn kept free of caves.
const SPAWN_CLEAR_RADIUS := 6


static func generate(map_seed: int, width: int = DEFAULT_WIDTH, height: int = DEFAULT_HEIGHT) -> MineData:
	var data := MineData.new(width, height, SURFACE_ROW, map_seed)

	var dirt := _noise(map_seed, 0.05)
	var caves := _noise(map_seed + 1, 0.06)
	var hard := _noise(map_seed + 2, 0.08)
	var iron := _noise(map_seed + 3, 0.14)
	var copper := _noise(map_seed + 4, 0.14)
	var crystal := _noise(map_seed + 5, 0.18)

	var spawn_x := width / 2

	for y in height:
		for x in width:
			var cell := Vector2i(x, y)
			var depth := y - SURFACE_ROW
			var type: int

			if x == 0 or x == width - 1 or y == height - 1:
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
				elif depth >= CRYSTAL_MIN_DEPTH and crystal.get_noise_2d(x, y) > 0.62:
					type = TileTypes.Type.CRYSTAL
				elif depth >= 3 and iron.get_noise_2d(x, y) > 0.5:
					type = TileTypes.Type.IRON
				elif depth >= 3 and copper.get_noise_2d(x, y) > 0.55:
					type = TileTypes.Type.COPPER

			data.set_tile_silent(cell, type)
			# Sky and the surface row start visible.
			if depth <= 0:
				data.reveal_silent(cell)

	return data


static func spawn_cell(data: MineData) -> Vector2i:
	return Vector2i(data.width / 2, data.surface_row - 1)


static func _noise(map_seed: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = map_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_octaves = 2
	return noise
