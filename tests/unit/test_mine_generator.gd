extends TestCase

const T := TileTypes.Type


func test_same_seed_gives_same_mine() -> void:
	var a := MineGenerator.generate(42)
	var b := MineGenerator.generate(42)
	assert_eq(_fingerprint(a), _fingerprint(b))
	assert_eq(a.deposits.size(), b.deposits.size())
	for i in a.deposits.size():
		assert_eq(a.deposits[i].rect, b.deposits[i].rect)
		assert_eq(a.deposits[i].amount, b.deposits[i].amount)


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


func test_every_ore_has_deposits() -> void:
	for map_seed in [1, 2, 3, 4, 5]:
		var data := MineGenerator.generate(map_seed)
		for ore in Ores.ALL:
			assert_true(data.deposits_of(ore).size() >= 3, "seed %d has %s deposits" % [map_seed, ore])
		assert_true(data.count_tiles(T.HARD_ROCK) > 0, "seed %d has hard rock" % map_seed)


func test_starter_iron_deposit_near_spawn() -> void:
	# Players need iron for ladders before going deep.
	for map_seed in [1, 2, 3, 4, 5]:
		var data := MineGenerator.generate(map_seed)
		var spawn := MineGenerator.spawn_cell(data)
		var found := false
		for deposit in data.deposits_of(Ores.IRON):
			var center := deposit.rect.get_center()
			if absi(center.x - spawn.x) <= 10 and center.y - data.surface_row <= 8:
				found = true
		assert_true(found, "seed %d has iron within reach of the spawn" % map_seed)


func test_deposits_keep_their_distance() -> void:
	var data := MineGenerator.generate(9)
	for a in data.deposits:
		for b in data.deposits:
			if a != b:
				assert_false(a.rect.grow(MineGenerator.DEPOSIT_SPACING - 1).intersects(b.rect),
					"deposits %d and %d too close" % [a.id, b.id])


func test_crystal_only_deep() -> void:
	var data := MineGenerator.generate(4)
	for deposit in data.deposits_of(Ores.CRYSTAL):
		assert_true(deposit.rect.position.y - data.surface_row >= 35)


func test_deposit_stock_within_rules() -> void:
	var data := MineGenerator.generate(4)
	for deposit in data.deposits:
		assert_true(deposit.amount >= 120 and deposit.amount <= 500, "stock %d" % deposit.amount)


func _fingerprint(data: MineData) -> int:
	var bytes := PackedByteArray()
	for y in data.height:
		for x in data.width:
			bytes.append(data.get_tile(Vector2i(x, y)))
	return hash(bytes)
