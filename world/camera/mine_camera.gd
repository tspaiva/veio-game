class_name MineCamera
extends Camera2D
## Follows a target; wheel/pinch zooms, middle-drag pans (which stops
## following until `recenter_camera`).

const ZOOM_MIN := 1.0
const ZOOM_MAX := 6.0
const ZOOM_STEP := 1.15
const DEFAULT_ZOOM := 3.0

var target: Node2D
var follow := true

var _bounds := Rect2()
var _touches: Dictionary = {}  # finger index -> screen position
var _pinch_distance := 0.0


func _ready() -> void:
	zoom = Vector2.ONE * DEFAULT_ZOOM
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0


func set_bounds(rect: Rect2) -> void:
	_bounds = rect
	limit_left = int(rect.position.x)
	limit_top = int(rect.position.y)
	limit_right = int(rect.end.x)
	limit_bottom = int(rect.end.y)


## Jumps to the target without smoothing (after a respawn or a new map).
func snap() -> void:
	follow = true
	if target:
		global_position = target.global_position
	reset_smoothing()


## True while two or more fingers are down; touches then mean zoom, not dig.
func is_pinching() -> bool:
	return _touches.size() >= 2


func _process(_delta: float) -> void:
	if follow and target:
		global_position = target.global_position


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("recenter_camera"):
		follow = true
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_by(ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_by(1.0 / ZOOM_STEP)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		follow = false
		global_position = _clamp_to_bounds(global_position - event.relative / zoom)
	elif event is InputEventMagnifyGesture:
		_zoom_by(event.factor)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		_pinch_distance = _current_pinch_distance()
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if is_pinching():
			var distance := _current_pinch_distance()
			if _pinch_distance > 0.0:
				_zoom_by(distance / _pinch_distance)
			_pinch_distance = distance


func _zoom_by(factor: float) -> void:
	zoom = Vector2.ONE * clampf(zoom.x * factor, ZOOM_MIN, ZOOM_MAX)


func _current_pinch_distance() -> float:
	if _touches.size() < 2:
		return 0.0
	var points := _touches.values()
	return (points[0] as Vector2).distance_to(points[1])


func _clamp_to_bounds(point: Vector2) -> Vector2:
	if not _bounds.has_area():
		return point
	return point.clamp(_bounds.position, _bounds.end)
