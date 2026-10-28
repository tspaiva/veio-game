extends TestCase

const T := TileTypes.Type

var data: MineData


func before_each() -> void:
	data = MineData.new(8, 8)
	for y in 8:
		for x in 8:
			data.set_tile_silent(Vector2i(x, y), T.ROCK)


func test_out_of_bounds_reads_as_bedrock() -> void:
	assert_eq(data.get_tile(Vector2i(-1, 0)), T.BEDROCK)
	assert_eq(data.get_tile(Vector2i(0, 8)), T.BEDROCK)
	assert_true(data.is_solid(Vector2i(99, 99)))


func test_dig_turns_cell_into_air() -> void:
	data.dig(Vector2i(2, 2), 1)
	assert_eq(data.get_tile(Vector2i(2, 2)), T.AIR)
	assert_false(data.is_solid(Vector2i(2, 2)))


func test_dig_returns_nothing_for_plain_rock() -> void:
	assert_eq(data.dig(Vector2i(2, 2), 1), &"")


func test_hard_rock_needs_tier_two() -> void:
	data.set_tile_silent(Vector2i(3, 3), T.HARD_ROCK)
	assert_false(data.can_dig(Vector2i(3, 3), 1))
	data.dig(Vector2i(3, 3), 1)
	assert_eq(data.get_tile(Vector2i(3, 3)), T.HARD_ROCK, "tier 1 must not dig hard rock")
	data.dig(Vector2i(3, 3), 2)
	assert_eq(data.get_tile(Vector2i(3, 3)), T.AIR)


func test_bedrock_is_never_diggable() -> void:
	data.set_tile_silent(Vector2i(0, 0), T.BEDROCK)
	assert_false(data.can_dig(Vector2i(0, 0), TileTypes.UNDIGGABLE))


func test_air_is_not_diggable() -> void:
	data.set_tile_silent(Vector2i(4, 4), T.AIR)
	assert_false(data.can_dig(Vector2i(4, 4), 1))


func test_dig_emits_tile_changed() -> void:
	var changes: Array = []
	data.tile_changed.connect(func(cell: Vector2i, type: int) -> void: changes.append([cell, type]))
	data.dig(Vector2i(5, 5), 1)
	assert_eq(changes, [[Vector2i(5, 5), T.AIR]])


func test_ladder_needs_revealed_air() -> void:
	var cell := Vector2i(2, 2)
	assert_false(data.place_ladder(cell), "rock cell")
	data.set_tile_silent(cell, T.AIR)
	assert_false(data.place_ladder(cell), "hidden cell")
	data.reveal_silent(cell)
	assert_true(data.place_ladder(cell))
	assert_eq(data.get_tile(cell), T.LADDER)
	assert_false(data.is_solid(cell), "ladders are passable")


func test_digging_a_ladder_refunds_it() -> void:
	var cell := Vector2i(2, 2)
	data.set_tile_silent(cell, T.AIR)
	data.reveal_silent(cell)
	data.place_ladder(cell)
	assert_eq(data.dig(cell, 1), &"ladder")
	assert_eq(data.get_tile(cell), T.AIR)


func test_reveal_is_circular_and_returns_only_new_cells() -> void:
	var first := data.reveal(Vector2i(4, 4), 1.0)
	assert_eq(first.size(), 5, "center plus 4 neighbors")
	assert_true(data.is_revealed(Vector2i(4, 3)))
	assert_false(data.is_revealed(Vector2i(3, 3)), "diagonal is outside radius 1")
	var second := data.reveal(Vector2i(4, 4), 1.0)
	assert_eq(second.size(), 0)


func test_reveal_clips_to_bounds() -> void:
	var cells := data.reveal(Vector2i(0, 0), 1.5)
	assert_eq(cells.size(), 4)


func test_reveal_emits_only_when_something_changes() -> void:
	var emitted := [0]
	data.cells_revealed.connect(func(_cells: Array[Vector2i]) -> void: emitted[0] += 1)
	data.reveal(Vector2i(4, 4), 2.0)
	data.reveal(Vector2i(4, 4), 2.0)
	assert_eq(emitted[0], 1)


# --- Deposits (D15) --------------------------------------------------------

func test_add_deposit_covers_its_cells() -> void:
	var deposit := data.add_deposit(&"iron", Rect2i(2, 3, 2, 2), 50)
	assert_not_null(deposit)
	for cell in [Vector2i(2, 3), Vector2i(3, 3), Vector2i(2, 4), Vector2i(3, 4)]:
		assert_eq(data.get_tile(cell), T.DEPOSIT)
		assert_eq(data.deposit_at(cell), deposit)
	assert_null(data.deposit_at(Vector2i(4, 3)))
	assert_true(data.is_solid(Vector2i(2, 3)), "deposits block movement")


func test_deposits_cannot_overlap_or_leave_the_map() -> void:
	assert_not_null(data.add_deposit(&"iron", Rect2i(2, 2, 2, 2), 50))
	assert_null(data.add_deposit(&"copper", Rect2i(3, 3, 2, 2), 50), "overlap")
	assert_null(data.add_deposit(&"copper", Rect2i(7, 7, 2, 2), 50), "out of bounds")
	assert_eq(data.deposits.size(), 1)


func test_deposit_cannot_be_dug() -> void:
	data.add_deposit(&"iron", Rect2i(2, 2, 2, 2), 50)
	assert_false(data.can_dig(Vector2i(2, 2), 99))
	data.dig(Vector2i(2, 2), 99)
	assert_eq(data.get_tile(Vector2i(2, 2)), T.DEPOSIT)


func test_extract_takes_one_unit_at_a_time() -> void:
	var deposit := data.add_deposit(&"copper", Rect2i(2, 2, 2, 2), 3)
	assert_eq(deposit.extract(1), 1)
	assert_eq(deposit.amount, 2)
	assert_eq(deposit.ratio(), 2.0 / 3.0)
	assert_eq(data.get_tile(Vector2i(2, 2)), T.DEPOSIT, "still there while stock remains")


func test_extract_never_takes_more_than_the_stock() -> void:
	var deposit := data.add_deposit(&"copper", Rect2i(2, 2, 2, 2), 3)
	assert_eq(deposit.extract(10), 3)
	assert_eq(deposit.extract(1), 0)


func test_depleted_deposit_opens_into_cave() -> void:
	var deposit := data.add_deposit(&"crystal", Rect2i(2, 2, 2, 2), 2)
	var depleted: Array = []
	data.deposit_depleted.connect(func(d: Deposit) -> void: depleted.append(d))
	var changed_cells: Array = []
	data.tile_changed.connect(func(cell: Vector2i, _type: int) -> void: changed_cells.append(cell))
	deposit.extract(1)
	deposit.extract(1)
	assert_true(deposit.is_depleted())
	assert_eq(depleted, [deposit])
	assert_eq(changed_cells.size(), 4)
	for cell in deposit.cells():
		assert_eq(data.get_tile(cell), T.AIR)
		assert_null(data.deposit_at(cell))
	assert_eq(data.deposits.size(), 0)


func test_deposits_of_filters_by_ore() -> void:
	data.add_deposit(&"iron", Rect2i(0, 0, 2, 2), 10)
	data.add_deposit(&"copper", Rect2i(4, 0, 2, 2), 10)
	data.add_deposit(&"iron", Rect2i(0, 4, 2, 2), 10)
	assert_eq(data.deposits_of(&"iron").size(), 2)
	assert_eq(data.deposits_of(&"crystal").size(), 0)
