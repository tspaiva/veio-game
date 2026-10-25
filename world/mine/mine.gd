class_name Mine
extends Node2D
## Renders a `MineData` (terrain + fog) and owns the terrain collision.
## All gameplay changes go through `data`; this node only mirrors them.

const TILE_SIZE := 16

const SKY_COLOR := Color("1d2a3f")
const CAVE_COLOR := Color("120f12")

var data: MineData

var _terrain: TileMapLayer
var _fog: TileMapLayer


func _ready() -> void:
	var tile_set := MineTileset.build(TILE_SIZE)
	_terrain = _make_layer("Terrain", tile_set, true)
	_fog = _make_layer("Fog", tile_set, false)


func setup(p_data: MineData) -> void:
	if data:
		data.tile_changed.disconnect(_on_tile_changed)
		data.cells_revealed.disconnect(_on_cells_revealed)
	data = p_data
	data.tile_changed.connect(_on_tile_changed)
	data.cells_revealed.connect(_on_cells_revealed)

	_terrain.clear()
	_fog.clear()
	for y in data.height:
		for x in data.width:
			var cell := Vector2i(x, y)
			_paint_terrain(cell, data.get_tile(cell))
			if not data.is_revealed(cell):
				_paint_fog(cell)
	queue_redraw()


## Center of `cell` in global coordinates.
func cell_to_world(cell: Vector2i) -> Vector2:
	return to_global(_terrain.map_to_local(cell))


func world_to_cell(point: Vector2) -> Vector2i:
	return _terrain.local_to_map(_terrain.to_local(point))


func bounds() -> Rect2:
	return Rect2(global_position, Vector2(data.width, data.height) * TILE_SIZE)


func _draw() -> void:
	if data == null:
		return
	var width := data.width * TILE_SIZE
	var surface_y := data.surface_row * TILE_SIZE
	draw_rect(Rect2(0, 0, width, surface_y), SKY_COLOR)
	draw_rect(Rect2(0, surface_y, width, (data.height - data.surface_row) * TILE_SIZE), CAVE_COLOR)


func _make_layer(layer_name: String, tile_set: TileSet, collision: bool) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tile_set
	layer.collision_enabled = collision
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(layer)
	return layer


func _paint_terrain(cell: Vector2i, type: int) -> void:
	if type == TileTypes.Type.AIR:
		_terrain.erase_cell(cell)
	else:
		_terrain.set_cell(cell, MineTileset.SOURCE_ID, Vector2i(type, 0))


# Hidden cells next to a revealed one get a translucent tile, which softens
# the edge of the explored area.
func _paint_fog(cell: Vector2i) -> void:
	var coords := MineTileset.FOG_EDGE if _touches_revealed(cell) else MineTileset.FOG_FULL
	_fog.set_cell(cell, MineTileset.SOURCE_ID, coords)


func _touches_revealed(cell: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if (dx != 0 or dy != 0) and data.is_revealed(cell + Vector2i(dx, dy)):
				return true
	return false


func _on_tile_changed(cell: Vector2i, type: int) -> void:
	_paint_terrain(cell, type)


func _on_cells_revealed(cells: Array[Vector2i]) -> void:
	var border := {}
	for cell in cells:
		_fog.erase_cell(cell)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				border[cell + Vector2i(dx, dy)] = true
	for cell: Vector2i in border:
		if data.in_bounds(cell) and not data.is_revealed(cell):
			_paint_fog(cell)
