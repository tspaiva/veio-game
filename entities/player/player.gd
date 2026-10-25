class_name Player
extends CharacterBody2D
## The field technician: walks with gravity, climbs ladders, digs and places
## ladders with the pointer, and reveals the fog around itself (D2, D7).

signal notice(text: String)

const HALF_SIZE := Vector2(5, 7)

const SPEED := 90.0
const GRAVITY := 900.0
const MAX_FALL_SPEED := 480.0
const JUMP_VELOCITY := -260.0
const CLIMB_SPEED := 75.0

## Max distance, in tiles, from the player's center to a target cell's center.
const REACH := 2.6
const REVEAL_RADIUS := 5.0
const LADDER_COST := 1  # iron

const START_INVENTORY := {&"iron": 20, &"copper": 0, &"crystal": 0}

var tool_tier := 1
var inventory: Dictionary = {}
## When true, the primary action places ladders instead of digging (touch).
var place_mode := false
## Returns true when the pointer is over UI that should not reach the world.
var is_pointer_blocked: Callable = func() -> bool: return false

var _mine: Mine
var _last_cell := Vector2i(-9999, -9999)
var _target := Vector2i.ZERO
var _target_valid := false
var _dig_cell := Vector2i(-9999, -9999)
var _dig_progress := 0.0
var _blocked_notice_cell := Vector2i(-9999, -9999)
var _primary_was_down := false


func reset(mine: Mine, cell: Vector2i) -> void:
	_mine = mine
	global_position = mine.cell_to_world(cell)
	velocity = Vector2.ZERO
	inventory = START_INVENTORY.duplicate()
	place_mode = false
	_last_cell = Vector2i(-9999, -9999)
	_cancel_dig()


func current_cell() -> Vector2i:
	return _mine.world_to_cell(global_position)


## Rows below the surface; negative when above ground.
func depth() -> int:
	return current_cell().y - _mine.data.surface_row


func is_on_ladder() -> bool:
	# Checks the body center and the feet, so the player keeps climbing until
	# the feet clear the top rung and can step onto the ground beside it.
	var feet := global_position + Vector2(0, HALF_SIZE.y - 1)
	return _is_ladder(global_position) or _is_ladder(feet)


func _physics_process(delta: float) -> void:
	if _mine == null:
		return
	_move(delta)
	_reveal_if_moved()
	_update_target()
	_handle_tools(delta)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_place_mode"):
		place_mode = not place_mode
		notice.emit("Modo: colocar escada" if place_mode else "Modo: cavar")


func _move(delta: float) -> void:
	var walk := Input.get_axis("move_left", "move_right")
	velocity.x = walk * SPEED

	if is_on_ladder():
		var climb := Input.get_axis("move_up", "move_down")
		velocity.y = climb * CLIMB_SPEED
		if climb != 0.0 and walk == 0.0:
			_center_on_column()
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	else:
		if walk == 0.0 and is_on_floor() and not _mine.data.is_solid(_cell_below()):
			# The body is narrower than a tile but rarely aligned with one, so
			# slide into a hole dug right below instead of standing on its edges.
			_center_on_column()
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		var wants_jump := Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("move_up")
		if wants_jump and is_on_floor():
			velocity.y = JUMP_VELOCITY

	move_and_slide()


func _cell_below() -> Vector2i:
	return _mine.world_to_cell(global_position + Vector2(0, HALF_SIZE.y + 1))


# Steers horizontally toward the center of the current tile column.
func _center_on_column() -> void:
	var column_x := _mine.cell_to_world(current_cell()).x
	velocity.x = clampf((column_x - global_position.x) * 12.0, -SPEED, SPEED)


func _reveal_if_moved() -> void:
	var cell := current_cell()
	if cell != _last_cell:
		_last_cell = cell
		_mine.data.reveal(cell, REVEAL_RADIUS)


func _update_target() -> void:
	_target = _mine.world_to_cell(get_global_mouse_position())
	var distance := (_mine.cell_to_world(_target) - global_position).length() / Mine.TILE_SIZE
	_target_valid = distance <= REACH


func _handle_tools(delta: float) -> void:
	var blocked: bool = is_pointer_blocked.call()
	# Mouse clicks emulated from touch update the button mask but not input
	# actions, so the left button is read directly as well.
	var down := Input.is_action_pressed("dig") or (Input.get_mouse_button_mask() & MOUSE_BUTTON_MASK_LEFT) != 0
	var just_down := down and not _primary_was_down
	_primary_was_down = down

	var primary := down and not blocked
	var wants_place := Input.is_action_just_pressed("place") and not blocked
	if place_mode:
		wants_place = wants_place or (just_down and not blocked)
		primary = false

	if wants_place:
		_try_place_ladder()
	if primary:
		_dig(delta)
	else:
		_cancel_dig()


func _dig(delta: float) -> void:
	var data := _mine.data
	# Never dig the cell the player occupies (it would drop them off a ladder).
	if not _target_valid or _target == current_cell() or not data.is_revealed(_target):
		_cancel_dig()
		return
	var type := data.get_tile(_target)
	if type == TileTypes.Type.AIR:
		_cancel_dig()
		return
	if not data.can_dig(_target, tool_tier):
		if _blocked_notice_cell != _target:
			_blocked_notice_cell = _target
			notice.emit("%s: precisa de uma ferramenta melhor" % TileTypes.DISPLAY_NAME[type])
		_cancel_dig()
		return

	if _target != _dig_cell:
		_dig_cell = _target
		_dig_progress = 0.0
	_dig_progress += delta
	if _dig_progress >= TileTypes.DIG_TIME[type]:
		_collect(data.dig(_target, tool_tier))
		_cancel_dig()


func _cancel_dig() -> void:
	_dig_cell = Vector2i(-9999, -9999)
	_dig_progress = 0.0


func _collect(drop: StringName) -> void:
	match drop:
		&"":
			pass
		&"ladder":
			inventory[&"iron"] += LADDER_COST
		_:
			inventory[drop] = inventory.get(drop, 0) + 1


func _try_place_ladder() -> void:
	if not _target_valid or not _mine.data.can_place_ladder(_target):
		return
	if inventory[&"iron"] < LADDER_COST:
		notice.emit("Sem ferro para fazer escada")
		return
	if _mine.data.place_ladder(_target):
		inventory[&"iron"] -= LADDER_COST


func _is_ladder(point: Vector2) -> bool:
	return _mine.data.get_tile(_mine.world_to_cell(point)) == TileTypes.Type.LADDER


func _draw() -> void:
	# Placeholder art: suit, visor and helmet lamp.
	draw_rect(Rect2(-HALF_SIZE, HALF_SIZE * 2), Color("e08a2e"))
	draw_rect(Rect2(Vector2(-3, -5), Vector2(6, 3)), Color("9fe3ff"))
	draw_rect(Rect2(Vector2(-1, -7), Vector2(2, 1)), Color("fff3b0"))
	if _mine != null:
		_draw_target()


func _draw_target() -> void:
	var data := _mine.data
	var actionable: bool
	if place_mode:
		actionable = _target_valid and data.can_place_ladder(_target)
	else:
		actionable = _target_valid and _target != current_cell() and data.is_revealed(_target) \
			and data.can_dig(_target, tool_tier)
	if not actionable and not _target_valid:
		return

	var size := Vector2(Mine.TILE_SIZE, Mine.TILE_SIZE)
	var rect := Rect2(to_local(_mine.cell_to_world(_target)) - size / 2.0, size)
	var color := Color(1, 1, 1, 0.8) if actionable else Color(1, 0.3, 0.3, 0.5)
	draw_rect(rect, color, false, 1.0)

	if _dig_cell == _target and _dig_progress > 0.0:
		var ratio := _dig_progress / TileTypes.DIG_TIME[data.get_tile(_target)]
		draw_rect(Rect2(rect.position + Vector2(0, size.y - 3), Vector2(size.x * ratio, 2)), Color("fff3b0"))
