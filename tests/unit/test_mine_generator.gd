extends TestCase

const T := TileTypes.Type


func test_same_seed_gives_same_mine() -> void:
	var a := MineGenerator.generate(42)
	var b := MineGenerator.generate(42)
	assert_eq(_fingerprint(a), _fingerprint(b))


func test_different_seeds_give_different_mines() -> void:
	var a := MineGenerator.generate(1)
	var b := MineGenerator.generate(2)
	assert_ne(_fingerprint(a), _fingerprint(b))


func test_map_is_framed_by_bedrock() -> void:
	var data := MineGenerator.generate(7)
	for y in data.height:
		assert_eq(data.get_tile(Vector2i(0, y)), T.BEDROCK, "left wall row %d" % y)
		assert_eq(data.get_tile(Vector2i(data.width - 1, y)), T.BEDROCK, "right wall row %d" % y)
	for x in data.width:
		assert_eq(data.get_tile(Vector2i(x, data.height - 1)), T.BEDROCK, "floor col %d" % x)


func test_sky_is_open_and_revealed() -> void:
	var data := MineGenerator.generate(7)
	for y in data.surface_row:
		for x in range(1, data.width - 1):
			var cell := Vector2i(x, y)
			assert_eq(data.get_tile(cell), T.AIR)
			assert_true(data.is_revealed(cell))


func test_underground_starts_hidden() -> void:
	var data := MineGenerator.generate(7)
	assert_false(data.is_revealed(Vector2i(data.width / 2, data.surface_row + 1)))


func test_spawn_stands_on_solid_ground() -> void:
	for map_seed in [1, 2, 3, 4, 5]:
		var data := MineGenerator.generate(map_seed)
		var spawn := MineGenerator.spawn_cell(data)
		assert_eq(data.get_tile(spawn), T.AIR, "seed %d spawn cell" % map_seed)
		assert_true(data.is_solid(spawn + Vector2i.DOWN), "seed %d ground under spawn" % map_seed)


func test_every_resource_appears() -> void:
	for map_seed in [1, 2, 3, 4, 5]:
		var data := MineGenerator.generate(map_seed)
		for type in [T.IRON, T.COPPER, T.CRYSTAL, T.HARD_ROCK]:
			assert_true(data.count_tiles(type) > 0, "seed %d has %s" % [map_seed, TileTypes.DISPLAY_NAME[type]])


func test_iron_is_reachable_near_the_surface() -> void:
	# Players need iron for ladders before going deep.
	for map_seed in [1, 2, 3, 4, 5]:
		var data := MineGenerator.generate(map_seed)
		var found := false
		for y in range(data.surface_row, data.surface_row + 20):
			for x in data.width:
				if data.get_tile(Vector2i(x, y)) == T.IRON:
					found = true
		assert_true(found, "seed %d has iron in the top 20 rows" % map_seed)


func _fingerprint(data: MineData) -> int:
	var bytes := PackedByteArray()
	for y in data.height:
		for x in data.width:
			bytes.append(data.get_tile(Vector2i(x, y)))
	return hash(bytes)
