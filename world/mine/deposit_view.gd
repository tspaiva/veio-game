class_name DepositView
extends Node2D
## Draws a deposit as a cluster of ore chunks over its backdrop tiles, with
## the remaining stock. Chunks vanish from the outside in as the stock drops,
## so the deposit visibly shrinks (D15).

const CHUNKS_PER_TILE := 6
## Label height in world pixels. The text is rasterized LABEL_OVERSAMPLE
## times larger and scaled down, so it stays sharp under camera zoom.
const LABEL_SIZE := 7
const LABEL_OVERSAMPLE := 4

var deposit: Deposit

# Chunks sorted from the center outward: [position: Vector2, radius: float].
var _chunks: Array = []


func setup(p_deposit: Deposit, tile_size: int) -> void:
	deposit = p_deposit
	position = Vector2(deposit.rect.position * tile_size)
	_build_chunks(Vector2(deposit.rect.size * tile_size))
	deposit.changed.connect(func(_d: Deposit) -> void: queue_redraw())
	deposit.depleted.connect(func(_d: Deposit) -> void: queue_free())
	queue_redraw()


func _build_chunks(area: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = deposit.id * 7919  # fixed per deposit: same look every frame
	var center := area / 2.0
	var count := deposit.rect.get_area() * CHUNKS_PER_TILE
	for i in count:
		var radius := rng.randf_range(1.6, 3.4)
		var pos := Vector2(rng.randf_range(radius + 1, area.x - radius - 1), rng.randf_range(radius + 1, area.y - radius - 1))
		_chunks.append([pos, radius])
	_chunks.sort_custom(func(a: Array, b: Array) -> bool:
		return a[0].distance_squared_to(center) < b[0].distance_squared_to(center))


func _draw() -> void:
	if deposit == null or deposit.is_depleted():
		return
	var color := Ores.color(deposit.ore)
	var visible_count := ceili(_chunks.size() * deposit.ratio())
	for i in visible_count:
		var pos: Vector2 = _chunks[i][0]
		var radius: float = _chunks[i][1]
		draw_circle(pos, radius + 0.8, color.darkened(0.55))
		draw_circle(pos, radius, color.darkened(0.1 * (i % 3)))
		draw_circle(pos - Vector2(radius, radius) * 0.35, radius * 0.35, color.lightened(0.35))

	var k := LABEL_OVERSAMPLE
	var font := ThemeDB.fallback_font
	var width := deposit.rect.size.x * Mine.TILE_SIZE * k
	var baseline := Vector2(0, (deposit.rect.size.y * Mine.TILE_SIZE - 2) * k)
	var text := str(deposit.amount)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE / k)
	draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, width, LABEL_SIZE * k, 4 * k, Color.BLACK)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, width, LABEL_SIZE * k, Color.WHITE)
	draw_set_transform(Vector2.ZERO)
