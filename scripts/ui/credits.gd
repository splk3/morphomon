extends Control
## End credits: Morphomon races away from the camera into the screen toward a
## sunset over the beach-side road while the credits roll upward. Mirrors the
## main menu vibe but with forward (into-screen) motion. Any input returns to
## the main menu, and it auto-returns when the roll finishes.

const CREDITS_DIR := "res://backgrounds/credits/"
const ROLL_SECONDS := 34.0

var _palms_cycle := 0.0
var _morph_cycle := 0.0
var _morph: Sprite2D
var _palms: Sprite2D
var _morph_idle: Texture2D
var _morph_run: Texture2D
var _finished := false


func _ready() -> void:
	$Sky.texture = load(CREDITS_DIR + "sky_sunset.svg")
	$Road.texture = load(CREDITS_DIR + "road_vanishing.svg")

	_palms = Sprite2D.new()
	_palms.centered = true
	_palms.position = Vector2(640, 360)
	_palms.texture = load(CREDITS_DIR + "palms_sides.svg")
	$World.add_child(_palms)

	_morph_idle = load("res://sprites/forms/morphomon_idle.svg")
	_morph_run = load("res://sprites/forms/morphomon_run.svg")
	_morph = Sprite2D.new()
	_morph.texture = _morph_run
	$World.add_child(_morph)

	# Roll the credits text upward off the top of the screen.
	var roll := create_tween()
	roll.tween_property($Roll, "position:y", -$Roll.size.y - 200.0, ROLL_SECONDS)\
		.from(720.0)
	roll.tween_callback(_to_menu)

	AudioManager.play_music("credits_theme")


func _process(delta: float) -> void:
	# Palms surge outward from the vanishing point to fake forward motion.
	_palms_cycle = fmod(_palms_cycle + delta * 0.4, 1.0)
	var scale := lerpf(0.4, 2.4, _palms_cycle)
	_palms.scale = Vector2(scale, scale)
	_palms.modulate.a = clampf(1.2 - _palms_cycle, 0.0, 1.0)

	# Morphomon shrinks toward the horizon center, looping (racing into screen).
	_morph_cycle = fmod(_morph_cycle + delta * 0.5, 1.0)
	var m_scale := lerpf(2.6, 0.3, _morph_cycle)
	_morph.scale = Vector2(m_scale, m_scale)
	_morph.position = Vector2(640, lerpf(620.0, 330.0, _morph_cycle))
	_morph.texture = _morph_run if fmod(_morph_cycle * 20.0, 1.0) < 0.5 else _morph_idle


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") \
			or event.is_action_pressed("jump") or event.is_action_pressed("pause"):
		_to_menu()


func _to_menu() -> void:
	if _finished:
		return
	_finished = true
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
