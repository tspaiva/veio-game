extends Node2D
## Main scene: generates a mine and wires player, camera and UI together.
##
## Seed sources, in order: `--seed=<n>` on the command line, `?seed=<n>` in
## the page URL (web build), otherwise random. `new_map` rolls a new seed.

@onready var mine: Mine = $Mine
@onready var player: Player = $Player
@onready var camera: MineCamera = $Camera
@onready var hud: Hud = $Hud
@onready var touch_controls: TouchControls = $TouchControls

var map_seed := 0


func _ready() -> void:
	player.notice.connect(hud.flash)
	player.is_pointer_blocked = func() -> bool:
		return camera.is_pinching() or touch_controls.is_over_button(get_viewport().get_mouse_position())
	camera.target = player
	start(_initial_seed())


func start(p_map_seed: int) -> void:
	map_seed = p_map_seed
	var data := MineGenerator.generate(map_seed)
	mine.setup(data)
	player.reset(mine, MineGenerator.spawn_cell(data))
	camera.set_bounds(mine.bounds())
	camera.snap()
	hud.flash("Seed %d" % map_seed)


func _process(_delta: float) -> void:
	hud.show_stats(map_seed, player.depth(), player.inventory, player.place_mode)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("new_map"):
		start(_random_seed())


func _initial_seed() -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed=") and arg.trim_prefix("--seed=").is_valid_int():
			return arg.trim_prefix("--seed=").to_int()
	if OS.has_feature("web"):
		var from_url = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('seed')")
		if from_url is String and from_url.is_valid_int():
			return from_url.to_int()
	return _random_seed()


func _random_seed() -> int:
	return randi() % 1_000_000
