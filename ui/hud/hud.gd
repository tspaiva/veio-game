class_name Hud
extends CanvasLayer
## Prototype HUD: map seed, depth, inventory, tool mode and control hints.

const NOTICE_SECONDS := 2.5

const CONTROLS_HINT := "A/D andar · Espaço/W pular · W/S subir e descer escada · " \
	+ "Clique esq. cavar · Clique dir. escada · Q alternar modo · " \
	+ "Roda zoom · Botão do meio arrastar · C centralizar · N novo mapa"

var _stats: Label
var _notice: Label
var _hint: Label
var _notice_left := 0.0


func _ready() -> void:
	_stats = _make_label(Vector2(12, 8), 16)
	_notice = _make_label(Vector2(12, 92), 16)
	_notice.modulate = Color("fff3b0")
	_hint = _make_label(Vector2.ZERO, 13)
	_hint.text = CONTROLS_HINT
	_hint.modulate = Color(1, 1, 1, 0.6)
	_hint.visible = not DisplayServer.is_touchscreen_available()
	get_viewport().size_changed.connect(_layout)
	_layout()


# Keeps the hint on the bottom edge; the window stretches with aspect "expand".
func _layout() -> void:
	_hint.position = Vector2(12, get_viewport().get_visible_rect().size.y - 30)


func show_stats(map_seed: int, depth: int, inventory: Dictionary, place_mode: bool) -> void:
	_stats.text = "Seed %d   Profundidade %d\nFerro %d   Cobre %d   Cristal %d\nModo: %s" % [
		map_seed, maxi(depth, 0),
		inventory.get(&"iron", 0), inventory.get(&"copper", 0), inventory.get(&"crystal", 0),
		"escada" if place_mode else "cavar",
	]


func flash(text: String) -> void:
	_notice.text = text
	_notice_left = NOTICE_SECONDS


func _process(delta: float) -> void:
	if _notice_left > 0.0:
		_notice_left -= delta
		if _notice_left <= 0.0:
			_notice.text = ""


func _make_label(at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	return label
