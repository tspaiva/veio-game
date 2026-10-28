class_name MineTileset
extends RefCounted
## Builds the mine TileSet in code, with procedurally drawn placeholder art.
##
## Atlas layout: row 0 holds one tile per `TileTypes.Type` at column == type;
## row 1 holds the fog tiles (`FOG_FULL`, `FOG_EDGE`).
## Solid tile types get a full-square collision polygon on physics layer 0.

const SOURCE_ID := 0
const FOG_FULL := Vector2i(0, 1)
const FOG_EDGE := Vector2i(1, 1)

const T := TileTypes.Type

const BASE_COLOR := {
	T.DIRT: Color("6b4a2f"),
	T.ROCK: Color("5a5a63"),
	T.HARD_ROCK: Color("34343d"),
	# Backdrop under a deposit; `DepositView` draws the ore on top.
	T.DEPOSIT: Color("2a2730"),
	T.BEDROCK: Color("17161c"),
}


static func build(tile_size: int) -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(tile_size, tile_size)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)

	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(_draw_atlas(tile_size))
	source.texture_region_size = Vector2i(tile_size, tile_size)
	# The source must belong to the TileSet before tiles get physics data.
	tile_set.add_source(source, SOURCE_ID)

	var half := tile_size / 2.0
	var square := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half),
	])
	for type in range(1, TileTypes.COUNT):
		var coords := Vector2i(type, 0)
		source.create_tile(coords)
		if TileTypes.is_solid(type):
			var tile_data := source.get_tile_data(coords, 0)
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, square)

	source.create_tile(FOG_FULL)
	source.create_tile(FOG_EDGE)
	return tile_set


static func _draw_atlas(size: int) -> Image:
	var image := Image.create(size * TileTypes.COUNT, size * 2, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234  # fixed: art must not change between runs

	for type in range(1, TileTypes.COUNT):
		var origin := Vector2i(type * size, 0)
		if type == T.LADDER:
			_draw_ladder(image, origin, size)
		else:
			_draw_speckled(image, origin, size, BASE_COLOR[type], rng)

	image.fill_rect(Rect2i(FOG_FULL * size, Vector2i(size, size)), Color("050507"))
	image.fill_rect(Rect2i(FOG_EDGE * size, Vector2i(size, size)), Color(0.02, 0.02, 0.03, 0.72))
	return image


static func _draw_speckled(image: Image, origin: Vector2i, size: int, base: Color, rng: RandomNumberGenerator) -> void:
	for y in size:
		for x in size:
			var shade := rng.randf_range(-0.06, 0.06)
			image.set_pixel(origin.x + x, origin.y + y, base.lightened(shade) if shade > 0 else base.darkened(-shade))
	# Dark bottom/right edge so the grid reads at a glance.
	for i in size:
		image.set_pixel(origin.x + i, origin.y + size - 1, base.darkened(0.25))
		image.set_pixel(origin.x + size - 1, origin.y + i, base.darkened(0.25))


static func _draw_ladder(image: Image, origin: Vector2i, size: int) -> void:
	var wood := Color("a8763e")
	var dark := wood.darkened(0.35)
	for y in size:
		for x in [2, 3, size - 4, size - 3]:
			image.set_pixel(origin.x + x, origin.y + y, wood if x % 2 == 0 else dark)
	for y in range(1, size, 4):
		for x in range(4, size - 4):
			image.set_pixel(origin.x + x, origin.y + y, wood)
			image.set_pixel(origin.x + x, origin.y + y + 1, dark)
