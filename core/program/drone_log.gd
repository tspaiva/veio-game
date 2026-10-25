class_name DroneLog
extends RefCounted
## Ring buffer of the last things a drone did, shown when it is downed (GDD 8.2).
## Repeated consecutive entries collapse into one with a count, so a drone
## stuck in a loop does not push everything else out.

const DEFAULT_CAPACITY := 32

var capacity: int

# Each entry: { "tick": int, "text": String, "count": int }
var _entries: Array[Dictionary] = []


func _init(p_capacity: int = DEFAULT_CAPACITY) -> void:
	capacity = p_capacity


func add(tick: int, text: String) -> void:
	if not _entries.is_empty() and _entries[-1].text == text:
		_entries[-1].count += 1
		_entries[-1].tick = tick
		return
	_entries.append({"tick": tick, "text": text, "count": 1})
	if _entries.size() > capacity:
		_entries.pop_front()


func entries() -> Array[Dictionary]:
	return _entries.duplicate()


func size() -> int:
	return _entries.size()


func last_text() -> String:
	return "" if _entries.is_empty() else _entries[-1].text


## The newest `count` entries, oldest first, formatted for display.
func lines(count: int = DEFAULT_CAPACITY) -> PackedStringArray:
	var result := PackedStringArray()
	for entry in _entries.slice(maxi(_entries.size() - count, 0)):
		var repeat := " ×%d" % entry.count if entry.count > 1 else ""
		result.append("[%d] %s%s" % [entry.tick, entry.text, repeat])
	return result


func has_text(fragment: String) -> bool:
	for entry in _entries:
		if entry.text.contains(fragment):
			return true
	return false


func clear() -> void:
	_entries.clear()
