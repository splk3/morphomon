extends Control
## Intro cutscene for the Dr. Morphous boss level.
##
## A short, auto-advancing cinematic set at an industrial science-lab/factory:
##   1. EXTERIOR — Morphomon runs across a dim factory yard (lab_sky +
##      factory_far parallax) toward the building_exterior entrance and vanishes
##      into the doorway.
##   2. INTERIOR — a fade lands us inside (factory_interior) where Morphomon
##      steps in and meets the robot scientist, Dr. Morphous, who powers up.
##   3. The scene then transitions into the boss level proper.
##
## Choreography is driven by chained Tweens (as in credits.gd / main_menu.gd);
## per-frame work in _process only handles the looping run-frame swap and bob.
## Any of jump / ui_accept / pause skips straight to the boss level.

const BG_DIR := "res://backgrounds/boss/"
const BOSS_LEVEL := "res://scenes/levels/level_boss.tscn"

const VIEW_W := 1280.0
const VIEW_H := 720.0

# Where the building's entrance door sits on screen (right side of the yard).
const DOOR_POS := Vector2(940, 470)
# Morphomon's start (off the left edge) and ground line for the exterior walk.
const MORPH_START := Vector2(-80, 470)
const MORPH_SCALE := Vector2(2.0, 2.0)

# Interior staging.
const MORPH_INTERIOR_POS := Vector2(380, 470)
const MORPH_INTERIOR_START := Vector2(-80, 470)
const BOSS_POS := Vector2(940, 430)
const BOSS_SCALE := Vector2(2.4, 2.4)

var _anim_time := 0.0
var _running := false        # whether to play the run-frame animation
var _finished := false

var _morph: Sprite2D
var _boss: Sprite2D
var _morph_idle: Texture2D
var _morph_run: Texture2D


func _ready() -> void:
	AudioManager.play_music("boss_theme")
	_build_exterior()
	_play_exterior()


## --- EXTERIOR ----------------------------------------------------------------

func _build_exterior() -> void:
	# Back-to-front parallax-ish layers (static here; Morphomon provides motion).
	_add_bg("lab_sky.svg", 0)
	_add_bg("factory_far.svg", 1)
	_add_bg("building_exterior.svg", 2)

	_morph_idle = load("res://sprites/forms/morphomon_idle.svg")
	_morph_run = load("res://sprites/forms/morphomon_run.svg")
	_morph = Sprite2D.new()
	_morph.name = "Morphomon"
	_morph.texture = _morph_run
	_morph.scale = MORPH_SCALE
	_morph.position = MORPH_START
	_morph.z_index = 10
	$World.add_child(_morph)


func _add_bg(file_name: String, z: int) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.name = file_name.get_basename().to_pascal_case()
	spr.centered = false
	spr.texture = load(BG_DIR + file_name)
	spr.position = Vector2.ZERO
	spr.z_index = z
	# Scale the art to cover the viewport regardless of its native size.
	var tex_size := spr.texture.get_size()
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		spr.scale = Vector2(VIEW_W / tex_size.x, VIEW_H / tex_size.y)
	$World.add_child(spr)
	return spr


func _play_exterior() -> void:
	$Caption.text = "Morphomon tracks Dr. Morphous to an abandoned factory..."
	_running = true

	# Fade in from black, run to the door, then dive into the doorway and fade.
	var t := create_tween()
	t.tween_property($Fade, "color:a", 0.0, 0.8)
	# Run across the yard up to the entrance door.
	t.tween_property(_morph, "position:x", DOOR_POS.x, 2.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Step into the doorway: shrink + fade as if entering the dark interior.
	t.tween_callback(func() -> void: $Caption.text = "...and steps inside.")
	t.tween_property(_morph, "position", DOOR_POS, 0.5)\
		.set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(_morph, "scale", MORPH_SCALE * 0.45, 0.5)
	t.parallel().tween_property(_morph, "modulate:a", 0.0, 0.5)
	# Black out, then swap to the interior.
	t.tween_property($Fade, "color:a", 1.0, 0.6)
	t.tween_callback(_enter_interior)


## --- INTERIOR ----------------------------------------------------------------

func _enter_interior() -> void:
	if _finished:
		return
	# Clear the exterior world and rebuild for the interior beat.
	for child in $World.get_children():
		child.queue_free()
	_morph = null
	_boss = null
	_anim_time = 0.0

	_add_bg("factory_interior.svg", 0)

	# Dr. Morphous: the robot scientist, idle on the right, initially dim.
	_boss = Sprite2D.new()
	_boss.name = "DrMorphous"
	_boss.texture = load("res://sprites/boss/scientist_idle.svg")
	_boss.scale = BOSS_SCALE
	_boss.position = BOSS_POS
	_boss.modulate = Color(0.35, 0.35, 0.45, 1.0)  # powered-down / in shadow
	_boss.z_index = 5
	_boss.flip_h = true  # face left toward the approaching Morphomon
	$World.add_child(_boss)

	# Morphomon enters from the left again, full opacity restored.
	_morph = Sprite2D.new()
	_morph.name = "Morphomon"
	_morph.texture = _morph_run
	_morph.scale = MORPH_SCALE
	_morph.position = MORPH_INTERIOR_START
	_morph.modulate = Color(1, 1, 1, 1)
	_morph.z_index = 10
	$World.add_child(_morph)

	_play_interior()


func _play_interior() -> void:
	$Caption.text = ""
	_running = true

	var t := create_tween()
	# Fade up into the interior.
	t.tween_property($Fade, "color:a", 0.0, 0.6)
	# Walk in and stop, facing the robot.
	t.tween_property(_morph, "position:x", MORPH_INTERIOR_POS.x, 1.4)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_callback(func() -> void: _running = false)
	# Beat: the robot powers up dramatically.
	t.tween_interval(0.3)
	t.tween_callback(func() -> void:
		$Caption.text = "DR. MORPHOUS: \"So the little shapeshifter found me.\""
		AudioManager.play_sfx("transform"))
	t.tween_property(_boss, "modulate", Color(1, 1, 1, 1), 0.6)
	t.parallel().tween_property(_boss, "scale", BOSS_SCALE * 1.08, 0.6)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_boss, "scale", BOSS_SCALE, 0.25)
	t.tween_interval(1.2)
	t.tween_callback(func() -> void:
		$Caption.text = "\"Let's see if you can handle THIS.\"")
	t.tween_interval(1.2)
	# Out to black, then into the fight.
	t.tween_property($Fade, "color:a", 1.0, 0.7)
	t.tween_callback(_to_boss_level)


## --- ANIMATION & INPUT -------------------------------------------------------

func _process(delta: float) -> void:
	_anim_time += delta
	if _morph and _running:
		# Looping run cycle: swap frames to read as running, like credits.gd.
		_morph.texture = _morph_run if fmod(_anim_time, 0.2) < 0.1 else _morph_idle
	elif _morph:
		_morph.texture = _morph_idle


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept") \
			or event.is_action_pressed("pause"):
		_to_boss_level()


func _to_boss_level() -> void:
	if _finished:
		return
	_finished = true
	var err := get_tree().change_scene_to_file(BOSS_LEVEL)
	if err != OK:
		push_error("boss_intro: failed to change to boss level (err %d)" % err)
