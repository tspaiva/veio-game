class_name MineData
extends RefCounted
## Pure grid model of the mine: tile types, ore deposits and fog of war.
## Holds no nodes, so it can be generated and tested headless.
## Views (the Mine node, pathfinding later) listen to the signals.

signal tile_changed(cell: Vector2i, type: int)
signal cells_revealed(cells: Array[Vector2i])
signal deposit_depleted(deposit: Deposit)

var width: int
var height: int
## Row of the ground surface; rows above it are open sky.
var surface_row: int
var map_seed: int

var deposits: Array[Deposit] = []

var _tiles: PackedByteArray
var _revealed: PackedByteArray
var _deposit_at: Dictionary = {}  # Vector2i -> Deposit
var _next_deposit_id := 1


func _init(p_width: int, p_height: int, p_surface_row: int = 0, p_map_seed: int = 0) -> void:
	width = p_width
	height = p_height
	surface_row = p_surface_row
	map_seed = p_map_seed
	_tiles = PackedByteArray()
	_tiles.resize(width * height)
	_revealed = PackedByteArray()
	_revealed.resize(width * height)


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


## Out-of-bounds cells read as bedrock so nothing can leave the map.
func get_tile(cell: Vector2i) -> int:
	if not in_bounds(cell):
		return TileTypes.Type.BEDROCK
	return _tiles[_index(cell)]


func set_tile(cell: Vector2i, type: int) -> void:
	if not in_bounds(cell) or _tiles[_index(cell)] == type:
		return
	_tiles[_index(cell)] = type
	tile_changed.emit(cell, type)


## Fills without emitting signals; meant for generators.
func set_tile_silent(cell: Vector2i, type: int) -> void:
	_tiles[_index(cell)] = type


func is_solid(cell: Vector2i) -> bool:
	return TileTypes.is_solid(get_tile(cell))


func can_dig(cell: Vector2i, tool_tier: int) -> bool:
	return in_bounds(cell) and TileTypes.is_diggable(get_tile(cell), tool_tier)


## Turns the cell into air. Returns &"ladder" when a ladder was removed (so
## its cost can be refunded), otherwise &"". Does nothing if the tool cannot
## dig the cell; deposits are extracted, never dug.
func dig(cell: Vector2i, tool_tier: int) -> StringName:
	if not can_dig(cell, tool_tier):
		return &""
	var was_ladder := get_tile(cell) == TileTypes.Type.LADDER
	set_tile(cell, TileTypes.Type.AIR)
	return &"ladder" if was_ladder else &""


## Places a deposit over `rect` (D15). Fails, returning null, if it leaves the
## map, touches bedrock or overlaps another deposit. Meant for generators:
## the cells change silently.
func add_deposit(ore: StringName, rect: Rect2i, amount: int) -> Deposit:
	var deposit := Deposit.new(_next_deposit_id, ore, rect, amount)
	for cell in deposit.cells():
		if not in_bounds(cell) or _deposit_at.has(cell) or get_tile(cell) == TileTypes.Type.BEDROCK:
			return null
	_next_deposit_id += 1
	for cell in deposit.cells():
		set_tile_silent(cell, TileTypes.Type.DEPOSIT)
		_deposit_at[cell] = deposit
	deposit.depleted.connect(_on_deposit_depleted)
	deposits.append(deposit)
	return deposit


func deposit_at(cell: Vector2i) -> Deposit:
	return _deposit_at.get(cell)


func deposits_of(ore: StringName) -> Array[Deposit]:
	var result: Array[Deposit] = []
	for deposit in deposits:
		if deposit.ore == ore:
			result.append(deposit)
	return result


func can_place_ladder(cell: Vector2i) -> bool:
	return in_bounds(cell) and get_tile(cell) == TileTypes.Type.AIR and is_revealed(cell)


func place_ladder(cell: Vector2i) -> bool:
	if not can_place_ladder(cell):
		return false
	set_tile(cell, TileTypes.Type.LADDER)
	return true


func is_revealed(cell: Vector2i) -> bool:
	return in_bounds(cell) and _revealed[_index(cell)] == 1


## Reveals every cell within `radius` tiles of `center` (euclidean).
## Returns only the cells that were hidden before, and emits them if any.
func reveal(center: Vector2i, radius: float) -> Array[Vector2i]:
	var revealed: Array[Vector2i] = []
	var r := ceili(radius)
	var r_sq := radius * radius
	for y in range(center.y - r, center.y + r + 1):
		for x in range(center.x - r, center.x + r + 1):
			var cell := Vector2i(x, y)
			if not in_bounds(cell) or Vector2(cell - center).length_squared() > r_sq:
				continue
			var i := _index(cell)
			if _revealed[i] == 0:
				_revealed[i] = 1
				revealed.append(cell)
	if not revealed.is_empty():
		cells_revealed.emit(revealed)
	return revealed


## Reveals without emitting signals; meant for generators.
func reveal_silent(cell: Vector2i) -> void:
	_revealed[_index(cell)] = 1


func count_tiles(type: int) -> int:
	return _tiles.count(type)


# An empty deposit opens up into cave.
func _on_deposit_depleted(deposit: Deposit) -> void:
	deposits.erase(deposit)
	for cell in deposit.cells():
		_deposit_at.erase(cell)
		set_tile(cell, TileTypes.Type.AIR)
	deposit_depleted.emit(deposit)


func _index(cell: Vector2i) -> int:
	return cell.y * width + cell.x
