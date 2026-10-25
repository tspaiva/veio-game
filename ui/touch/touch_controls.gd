class_name TouchControls
extends CanvasLayer
## On-screen buttons for testing on phones (D13).
## Each button presses an input action, so gameplay code needs no touch logic.
## Hidden until the device reports a touchscreen or a real touch arrives.

const BUTTON_SIZE := 96
const MARGIN := 24

enum Icon { LEFT, RIGHT, UP, DOWN, MODE }

var _buttons: Array[TouchScreenButton] = []


func _ready() -> void:
	_add_button("move_left", Icon.LEFT)
	_add_button("move_right", Icon.RIGHT)
	_add_button("move_down", Icon.DOWN)
	_add_button("move_up", Icon.UP)
	_add_button("toggle_place_mode", Icon.MODE)
	get_viewport().size_changed.connect(_layout)
	_layout()
	visible = DisplayServer.is_touchscreen_available()


# The window stretches with aspect "expand", so anchor buttons to the edges.
func _layout() -> void:
	var screen := get_viewport().get_visible_rect().size
	var bottom := screen.y - MARGIN - BUTTON_SIZE
	var right := screen.x - MARGIN - BUTTON_SIZE
	var spots := [
		Vector2(MARGIN, bottom),
		Vector2(MARGIN * 2 + BUTTON_SIZE, bottom),
		Vector2(right, bottom),
		Vector2(right, bottom - MARGIN - BUTTON_SIZE),
		Vector2(right, MARGIN),
	]
	for i in _buttons.size():
		_buttons[i].position = spots[i]


func _input(event: InputEvent) -> void:
	if not visible and event is InputEventScreenTouch:
		visible = true


## True when `screen_point` is over a visible button. Touches emulate mouse
## clicks, so the player uses this to avoid digging under a button.
func is_over_button(screen_point: Vector2) -> bool:
	if not visible:
		return false
	for button in _buttons:
		if Rect2(button.position, Vector2.ONE * BUTTON_SIZE).has_point(screen_point):
			return true
	return false


func _add_button(action: StringName, icon: Icon) -> void:
	var button := TouchScreenButton.new()
	button.texture_normal = _button_texture(icon)
	button.action = action
	button.modulate = Color(1, 1, 1, 0.5)
	if icon == Icon.MODE:
		var label := Label.new()
		label.text = "MODO"
		label.size = Vector2.ONE * BUTTON_SIZE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)
		button.add_child(label)
	add_child(button)
	_buttons.append(button)


# Circle with an arrow drawn into the image (the default font has no arrow glyphs).
static func _button_texture(icon: Icon) -> Texture2D:
	var size := BUTTON_SIZE
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) / 2.0
	var radius := size / 2.0 - 2.0
	var arrow := _arrow_points(icon, center, size * 0.22)
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := p.distance_to(center)
			if d > radius:
				continue
			var color := Color(0.15, 0.15, 0.2, 0.8)
			if d > radius - 4.0 or (not arrow.is_empty() and Geometry2D.is_point_in_polygon(p, arrow)):
				color = Color(1, 1, 1, 0.9)
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


static func _arrow_points(icon: Icon, c: Vector2, r: float) -> PackedVector2Array:
	match icon:
		Icon.LEFT:
			return PackedVector2Array([c + Vector2(-r, 0), c + Vector2(r, -r), c + Vector2(r, r)])
		Icon.RIGHT:
			return PackedVector2Array([c + Vector2(r, 0), c + Vector2(-r, r), c + Vector2(-r, -r)])
		Icon.UP:
			return PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, r), c + Vector2(-r, r)])
		Icon.DOWN:
			return PackedVector2Array([c + Vector2(0, r), c + Vector2(-r, -r), c + Vector2(r, -r)])
	return PackedVector2Array()
