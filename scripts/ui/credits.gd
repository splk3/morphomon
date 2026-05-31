extends Control
## End credits: Morphomon runs in place at a fixed screen spot, his run
## animation looping so he looks like he is endlessly making progress while
## "running out of the screen". He faces the OPPOSITE direction to the main
## menu run (the menu faces right, so here he faces left). He never actually
## translates — the credits text is the element that moves, rolling upward.
## Any input returns to the main menu, and it auto-returns when the roll ends.

const CREDITS_DIR := "res://backgrounds/credits/"
const ROLL_SECONDS := 34.0

# Fixed on-screen spot where Morphomon runs in place.
const MORPH_POS := Vector2(640, 470)
const MORPH_SCALE := Vector2(2.2, 2.2)

var _palms_cycle := 0.0
var _anim_time := 0.0
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
	_morph.position = MORPH_POS
	_morph.scale = MORPH_SCALE
	# Face the opposite way to the main menu (which faces right): head left,
	# as if running/exiting toward the left edge of the screen.
	_morph.flip_h = true
	$World.add_child(_morph)

	# Roll the credits text upward off the top of the screen.
	var roll := create_tween()
	roll.tween_property($Roll, "position:y", -$Roll.size.y - 200.0, ROLL_SECONDS)\
		.from(720.0)
	roll.tween_callback(_to_menu)

	AudioManager.play_music("credits_theme")


func _process(delta: float) -> void:
	_anim_time += delta

	# Palms surge outward from the vanishing point to fake forward motion.
	_palms_cycle = fmod(_palms_cycle + delta * 0.4, 1.0)
	var scale := lerpf(0.4, 2.4, _palms_cycle)
	_palms.scale = Vector2(scale, scale)
	_palms.modulate.a = clampf(1.2 - _palms_cycle, 0.0, 1.0)

	# Morphomon runs in place: he stays fixed in position (never translates),
	# swapping run frames and bobbing so he reads as endlessly running.
	_morph.position = MORPH_POS + Vector2(0.0, sin(_anim_time * 12.0) * 6.0)
	_morph.scale = MORPH_SCALE
	_morph.texture = _morph_run if fmod(_anim_time, 0.2) < 0.1 else _morph_idle


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") \
			or event.is_action_pressed("jump") or event.is_action_pressed("pause"):
		_to_menu()


func _to_menu() -> void:
	if _finished:
		return
	_finished = true
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
