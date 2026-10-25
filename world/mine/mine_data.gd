class_name MineData
extends RefCounted
## Pure grid model of the mine: tile types and fog of war.
## Holds no nodes, so it can be generated and tested headless.
## Views (the Mine node, pathfinding later) listen to the signals.

signal tile_changed(cell: Vector2i, type: int)
signal cells_revealed(cells: Array[Vector2i])

var width: int
var height: int
## Row of the ground surface; rows above it are open sky.
var surface_row: int
var map_seed: int

var _tiles: PackedByteArray
var _revealed: PackedByteArray


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


## Turns the cell into air and returns what it dropped (&"" for nothing).
## Returns &"" and changes nothing if the tool cannot dig it.
func dig(cell: Vector2i, tool_tier: int) -> StringName:
	if not can_dig(cell, tool_tier):
		return &""
	var drop: StringName = TileTypes.DROP[get_tile(cell)]
	set_tile(cell, TileTypes.Type.AIR)
	return drop


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


func _index(cell: Vector2i) -> int:
	return cell.y * width + cell.x
