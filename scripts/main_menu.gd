extends Control
## Main menu: an energetic, auto-scrolling beach-at-sunset parallax scene with
## Morphomon racing along a coastal road, looping chiptune music, and Start /
## Settings / Quit options. Backgrounds scroll continuously to convey motion.

const MENU_DIR := "res://backgrounds/menu/"
const VIEW_W := 1280.0

# Layer file + scroll speed (px/sec). Faster = nearer the camera.
const LAYERS := [
	{"tex": "sky_sunset.svg", "speed": 0.0},
	{"tex": "clouds.svg", "speed": 14.0},
	{"tex": "ocean.svg", "speed": 22.0},
	{"tex": "palms_far.svg", "speed": 60.0},
	{"tex": "waves.svg", "speed": 110.0},
	{"tex": "road.svg", "speed": 240.0},
	{"tex": "palms_near.svg", "speed": 300.0},
]

var _scrollers: Array = []  # {sprites:[Sprite2D,Sprite2D], speed:float}
var _morph: Sprite2D
var _morph_run: Texture2D
var _morph_idle: Texture2D
var _anim_time := 0.0


func _ready() -> void:
	_build_background()
	_build_morphomon()
	$Menu/VBox/StartButton.pressed.connect(_on_start)
	$Menu/VBox/SettingsButton.pressed.connect(_on_settings)
	$Menu/VBox/QuitButton.pressed.connect(_on_quit)
	$Menu/VBox/StartButton.grab_focus()
	AudioManager.play_music("menu_theme")


func _build_background() -> void:
	var holder := $Parallax
	for info in LAYERS:
		var tex: Texture2D = load(MENU_DIR + info.tex)
		var pair: Array = []
		for i in 2:
			var spr := Sprite2D.new()
			spr.centered = false
			spr.texture = tex
			spr.position = Vector2(i * VIEW_W, 0)
			holder.add_child(spr)
			pair.append(spr)
		_scrollers.append({"sprites": pair, "speed": float(info.speed)})


func _build_morphomon() -> void:
	_morph_idle = load("res://sprites/forms/morphomon_idle.svg")
	_morph_run = load("res://sprites/forms/morphomon_run.svg")
	_morph = Sprite2D.new()
	_morph.texture = _morph_run
	_morph.scale = Vector2(2.2, 2.2)
	_morph.position = Vector2(360, 560)
	$Parallax.add_child(_morph)


func _process(delta: float) -> void:
	_anim_time += delta
	for scroller in _scrollers:
		if scroller.speed <= 0.0:
			continue
		for spr in scroller.sprites:
			spr.position.x -= scroller.speed * delta
			if spr.position.x <= -VIEW_W:
				spr.position.x += VIEW_W * 2.0
	# Race animation: swap run frames and bob to suggest speed over the road.
	if _morph:
		_morph.texture = _morph_run if fmod(_anim_time, 0.2) < 0.1 else _morph_idle
		_morph.position.y = 560 + sin(_anim_time * 12.0) * 6.0


func _on_start() -> void:
	AudioManager.play_sfx("confirm")
	# The intro cruise level always plays first; after it, the level select opens.
	if GameState.is_complete("cruise"):
		get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
	else:
		GameState.go_to_level("cruise")


func _on_settings() -> void:
	AudioManager.play_sfx("select")
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")


func _on_quit() -> void:
	get_tree().quit()
