class_name Deposit
extends RefCounted
## An ore deposit (D15): a solid block of cells with a shared stock that
## miners extract one unit at a time, like a gold mine in Age of Mythology.
## Several miners can work it at once from any side. When the stock runs
## out, `MineData` turns its cells into open cave.

signal changed(deposit: Deposit)
signal depleted(deposit: Deposit)

var id: int
var ore: StringName
## Cells covered, in tile coordinates.
var rect: Rect2i
var amount: int
var capacity: int


func _init(p_id: int, p_ore: StringName, p_rect: Rect2i, p_amount: int) -> void:
	id = p_id
	ore = p_ore
	rect = p_rect
	amount = p_amount
	capacity = p_amount


## Removes up to `units` from the stock and returns how many were taken.
func extract(units: int = 1) -> int:
	var taken := mini(units, amount)
	if taken <= 0:
		return 0
	amount -= taken
	changed.emit(self)
	if amount == 0:
		depleted.emit(self)
	return taken


func is_depleted() -> bool:
	return amount <= 0


## Remaining stock from 0.0 (empty) to 1.0 (untouched).
func ratio() -> float:
	return float(amount) / capacity if capacity > 0 else 0.0


func has_cell(cell: Vector2i) -> bool:
	return rect.has_point(cell)


func cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			result.append(Vector2i(x, y))
	return result
