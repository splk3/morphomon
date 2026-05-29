extends Node2D
## Final boss: Dr. Morphous. The player must defeat a series of fake Morphomon
## robots in order, switching to the matching unlocked form for each (cycle with
## the Cycle Form action). After the fakes fall, Morphomon scans the doctor,
## copies his form and bonks him with a beaker, then the credits roll.

const PlayerScene := preload("res://scenes/player.tscn")
const EnemyScene := preload("res://scenes/entities/enemy.tscn")
const HudScene := preload("res://scenes/ui/hud.tscn")

const ARENA_LEFT := 60.0
const ARENA_RIGHT := 1220.0
const GROUND_Y := 600.0
const FAKE_FORMS := ["panther", "mammoth", "eagle", "monkey"]

var _player: CharacterBody2D
var _banner: Label
var _scientist: Sprite2D
var _phase := 0
var _active_fake: Node = null
var _ending := false


func _ready() -> void:
	GameState.pending_level_id = "boss"
	_build_background()
	_build_arena()
	_build_player()
	_build_hud()
	_build_banner()
	AudioManager.play_music("boss_theme")
	_show_banner("DR. MORPHOUS")
	await get_tree().create_timer(1.6).timeout
	_next_phase()


func _build_background() -> void:
	var theme := LevelThemes.get_theme("boss")
	var bg := ParallaxBackground.new()
	add_child(bg)
	for info in theme.layers:
		var layer := ParallaxLayer.new()
		layer.motion_scale = Vector2(info.scale, 1.0)
		bg.add_child(layer)
		var spr := Sprite2D.new()
		spr.centered = false
		spr.texture = load(info.tex)
		layer.add_child(spr)


func _build_arena() -> void:
	var body := StaticBody2D.new()
	body.add_to_group("world")
	body.collision_layer = 1
	add_child(body)
	_add_box(body, Rect2(0, GROUND_Y, 1280, 140), Color(0.2, 0.18, 0.26))   # floor
	_add_box(body, Rect2(-40, 0, 60, 720), Color(0.15, 0.13, 0.2))           # left wall
	_add_box(body, Rect2(1260, 0, 60, 720), Color(0.15, 0.13, 0.2))          # right wall


func _add_box(body: StaticBody2D, rect: Rect2, color: Color) -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.position + rect.size / 2.0
	body.add_child(shape)
	var vis := Polygon2D.new()
	vis.color = color
	vis.polygon = PackedVector2Array([
		rect.position, rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size, rect.position + Vector2(0, rect.size.y),
	])
	body.add_child(vis)


func _build_player() -> void:
	_player = PlayerScene.instantiate()
	_player.add_to_group("player")
	_player.position = Vector2(200, GROUND_Y - 60)
	add_child(_player)
	if _player.has_signal("died"):
		_player.died.connect(_on_player_died)
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.limit_left = 0
	cam.limit_right = 1280
	cam.limit_top = 0
	cam.limit_bottom = 720
	_player.add_child(cam)
	cam.make_current()


func _build_hud() -> void:
	var hud := HudScene.instantiate()
	add_child(hud)
	if hud.has_method("bind_player"):
		hud.bind_player(_player, "DR. MORPHOUS")


func _build_banner() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	_banner = Label.new()
	_banner.anchor_right = 1.0
	_banner.offset_top = 120.0
	_banner.offset_bottom = 180.0
	_banner.add_theme_font_size_override("font_size", 44)
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.add_theme_color_override("font_outline_color", Color(0.1, 0, 0.1))
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_banner)


func _show_banner(text: String) -> void:
	_banner.text = text
	_banner.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.6)


func _next_phase() -> void:
	if _phase < FAKE_FORMS.size():
		_spawn_fake(FAKE_FORMS[_phase])
		_show_banner("FAKE MORPHOMON: %s" % FAKE_FORMS[_phase].to_upper())
	else:
		_begin_finale()


func _spawn_fake(form_theme: String) -> void:
	var fake := EnemyScene.instantiate()
	fake.texture_path = "res://sprites/boss/fake_morphomon.svg"
	fake.health = 5
	fake.move_speed = 90.0
	fake.patrol_distance = 380.0
	fake.contact_damage = 1
	fake.position = Vector2(ARENA_RIGHT - 80, GROUND_Y - 30)
	add_child(fake)
	_active_fake = fake
	fake.tree_exited.connect(_on_fake_defeated)


func _on_fake_defeated() -> void:
	if _ending:
		return
	_phase += 1
	AudioManager.play_sfx("explosion")
	# Brief beat before the next robot enters.
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree():
		_next_phase()


func _begin_finale() -> void:
	_scientist = Sprite2D.new()
	_scientist.texture = load("res://sprites/boss/scientist_idle.svg")
	_scientist.scale = Vector2(2.0, 2.0)
	_scientist.position = Vector2(ARENA_RIGHT - 80, GROUND_Y - 60)
	add_child(_scientist)
	_show_banner("SCAN HIM!  (ATTACK)")


func _process(_delta: float) -> void:
	if _scientist and not _ending and is_instance_valid(_player):
		if _player.global_position.distance_to(_scientist.global_position) < 120.0:
			if Input.is_action_just_pressed("attack"):
				_play_ending()


func _play_ending() -> void:
	_ending = true
	AudioManager.play_sfx("transform")
	# Morphomon scans the doctor and copies his robotic form.
	if is_instance_valid(_player):
		var spr: Sprite2D = _player.get_node_or_null("Sprite2D")
		if spr:
			spr.texture = load("res://sprites/boss/fake_morphomon.svg")
		_player.set_physics_process(false)
	# Beaker bonk!
	var beaker := Sprite2D.new()
	beaker.texture = load("res://sprites/boss/scientist_beaker.svg")
	beaker.scale = Vector2(2.0, 2.0)
	beaker.position = _scientist.position + Vector2(-10, -20)
	add_child(beaker)
	AudioManager.play_sfx("hit")
	_show_banner("BONK!")
	await get_tree().create_timer(2.4).timeout
	GameState.mark_complete("boss")
	get_tree().change_scene_to_file("res://scenes/ui/credits.tscn")


func _on_player_died() -> void:
	if _ending:
		return
	AudioManager.play_sfx("explosion")
	get_tree().reload_current_scene()
