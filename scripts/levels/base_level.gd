extends Node2D
## Shared, data-driven level used by every themed stage.
##
## Reads `GameState.pending_level_id`, then procedurally assembles the parallax
## background, weather effects, ground/platforms, player, enemies, the rescue
## animal, collectibles and the exit goal for that theme. This lets a single
## scene render the cruise intro and all five themed levels.

const PlayerScene := preload("res://scenes/player.tscn")
const EnemyScene := preload("res://scenes/entities/enemy.tscn")
const RescueScene := preload("res://scenes/entities/rescue_animal.tscn")
const HudScene := preload("res://scenes/ui/hud.tscn")
const PauseScene := preload("res://scenes/ui/pause_menu.tscn")

const LEVEL_LENGTH := 4200.0
const GROUND_Y := 620.0
const VIEW := Vector2(1280, 720)

var level_id := "cruise"
var level_data: Dictionary = {}
var theme: Dictionary = {}

var _player: CharacterBody2D
var _camera: Camera2D
var _hud: CanvasLayer
var _weather: Array[Sprite2D] = []
var _weather_speed := 0.0
var _lava_frames: Array[Texture2D] = []
var _lava_sprites: Array[Sprite2D] = []
var _lava_timer := 0.0
var _lava_index := 0
var _completed := false


func _ready() -> void:
	level_id = GameState.pending_level_id if GameState.pending_level_id != "" else "cruise"
	level_data = GameState.get_level(level_id)
	theme = LevelThemes.get_theme(String(level_data.get("theme", "island")))

	_build_parallax()
	_build_ground()
	_build_player()
	_build_camera()
	_build_entities()
	_build_goal()
	_build_weather()
	_build_hud()

	AudioManager.play_music(String(level_data.get("music", "island_theme")))


# --- Background ---------------------------------------------------------
func _build_parallax() -> void:
	var bg := ParallaxBackground.new()
	add_child(bg)
	for layer_info in theme.layers:
		var layer := ParallaxLayer.new()
		layer.motion_scale = Vector2(layer_info.scale, 1.0)
		layer.motion_mirroring = Vector2(VIEW.x, 0)
		bg.add_child(layer)
		var spr := Sprite2D.new()
		spr.centered = false
		spr.texture = load(layer_info.tex)
		layer.add_child(spr)
		# Distant layers (the moving ones) tile horizontally via motion_mirroring.

	# Animated lava strip drawn just above the ground for the lava theme.
	if theme.has("lava_anim"):
		for path in theme.lava_anim:
			_lava_frames.append(load(path))
		for i in 4:
			var lava := Sprite2D.new()
			lava.centered = false
			lava.texture = _lava_frames[0]
			lava.position = Vector2(i * VIEW.x, 0)
			lava.z_index = -1
			add_child(lava)
			_lava_sprites.append(lava)


# --- Geometry -----------------------------------------------------------
func _build_ground() -> void:
	var body := StaticBody2D.new()
	body.add_to_group("world")
	body.collision_layer = 1
	add_child(body)

	# Continuous ground strip.
	_add_solid(body, Rect2(0, GROUND_Y, LEVEL_LENGTH, 120), theme.ground)

	# A handful of floating platforms for vertical play.
	var platform_spots := [
		Vector2(520, 500), Vector2(900, 430), Vector2(1400, 470),
		Vector2(1950, 410), Vector2(2500, 480), Vector2(3100, 430),
		Vector2(3600, 500),
	]
	for spot in platform_spots:
		_add_solid(body, Rect2(spot.x, spot.y, 180, 28), theme.platform)


func _add_solid(body: StaticBody2D, rect: Rect2, color: Color) -> void:
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.position + rect.size / 2.0
	body.add_child(shape)

	var visual := Polygon2D.new()
	visual.color = color
	visual.polygon = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
	])
	body.add_child(visual)


# --- Player & camera ----------------------------------------------------
func _build_player() -> void:
	_player = PlayerScene.instantiate()
	_player.add_to_group("player")
	_player.position = Vector2(120, GROUND_Y - 60)
	add_child(_player)
	if _player.has_signal("died"):
		_player.died.connect(_on_player_died)


func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.limit_left = 0
	_camera.limit_top = -200
	_camera.limit_right = int(LEVEL_LENGTH)
	_camera.limit_bottom = int(GROUND_Y + 120)
	_player.add_child(_camera)
	_camera.make_current()


# --- Entities -----------------------------------------------------------
func _build_entities() -> void:
	var enemy_texture := _enemy_texture_for_theme()
	var enemy_spots := [700.0, 1250.0, 1800.0, 2400.0, 2950.0, 3500.0, 3900.0]
	for x in enemy_spots:
		var enemy := EnemyScene.instantiate()
		enemy.position = Vector2(x, GROUND_Y - 30)
		enemy.texture_path = enemy_texture
		add_child(enemy)

	# Rescue animal at the midpoint for levels that grant a form.
	var animal := String(level_data.get("animal", ""))
	if animal != "":
		var rescue := RescueScene.instantiate()
		rescue.form_id = String(level_data.get("form", "default"))
		rescue.animal_texture = "res://sprites/animals/%s.svg" % animal
		rescue.position = Vector2(LEVEL_LENGTH * 0.45, GROUND_Y - 40)
		add_child(rescue)

	# Scatter collectibles.
	for i in 8:
		var gear := _make_pickup("res://sprites/items/gear.svg")
		gear.position = Vector2(400 + i * 460, GROUND_Y - 90)
		add_child(gear)


func _enemy_texture_for_theme() -> String:
	match String(level_data.get("theme", "")):
		"ice": return "res://sprites/enemies/snowball.svg"
		"cruise", "island", "pirate": return "res://sprites/enemies/crab.svg"
		"jungle": return "res://sprites/enemies/bat.svg"
		_: return "res://sprites/enemies/drone.svg"


func _make_pickup(tex: String) -> Area2D:
	var area := Area2D.new()
	area.collision_mask = 1
	var spr := Sprite2D.new()
	spr.texture = load(tex)
	area.add_child(spr)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14
	shape.shape = circle
	area.add_child(shape)
	area.body_entered.connect(func(body): if body.is_in_group("player"): area.queue_free())
	return area


# --- Goal ---------------------------------------------------------------
func _build_goal() -> void:
	var goal := Area2D.new()
	goal.position = Vector2(LEVEL_LENGTH - 80, GROUND_Y - 80)
	goal.collision_mask = 1
	var spr := Sprite2D.new()
	spr.texture = load("res://sprites/items/health.svg")
	spr.scale = Vector2(2, 2)
	goal.add_child(spr)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(48, 160)
	shape.shape = box
	goal.add_child(shape)
	goal.body_entered.connect(_on_goal_entered)
	add_child(goal)


func _on_goal_entered(body: Node) -> void:
	if _completed or not body.is_in_group("player"):
		return
	_completed = true
	complete_level()


func complete_level() -> void:
	AudioManager.play_sfx("confirm")
	GameState.mark_complete(level_id)
	if level_id == "boss":
		get_tree().change_scene_to_file("res://scenes/ui/credits.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")


# --- Weather & HUD ------------------------------------------------------
func _build_weather() -> void:
	if not theme.has("fx_tex"):
		return
	match theme.fx:
		"snow": _weather_speed = 180.0
		"rain": _weather_speed = 520.0
		"embers": _weather_speed = -90.0  # embers drift upward
		_: return
	var tex: Texture2D = load(theme.fx_tex)
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	for i in 2:
		var spr := Sprite2D.new()
		spr.centered = false
		spr.texture = tex
		spr.position = Vector2(0, i * VIEW.y)
		layer.add_child(spr)
		_weather.append(spr)


func _build_hud() -> void:
	_hud = HudScene.instantiate()
	add_child(_hud)
	if _hud.has_method("bind_player"):
		_hud.bind_player(_player, String(level_data.get("name", "")))


# --- Process loop -------------------------------------------------------
func _process(delta: float) -> void:
	_update_weather(delta)
	_update_lava(delta)
	if Input.is_action_just_pressed("pause"):
		_toggle_pause()


func _update_weather(delta: float) -> void:
	if _weather.is_empty():
		return
	for spr in _weather:
		spr.position.y += _weather_speed * delta
		if _weather_speed > 0 and spr.position.y >= VIEW.y:
			spr.position.y -= VIEW.y * 2
		elif _weather_speed < 0 and spr.position.y <= -VIEW.y:
			spr.position.y += VIEW.y * 2


func _update_lava(delta: float) -> void:
	if _lava_sprites.is_empty():
		return
	_lava_timer += delta
	if _lava_timer >= 0.4:
		_lava_timer = 0.0
		_lava_index = (_lava_index + 1) % _lava_frames.size()
		for spr in _lava_sprites:
			spr.texture = _lava_frames[_lava_index]


func _toggle_pause() -> void:
	if _hud and _hud.has_node("PauseHolder"):
		return
	var existing := get_node_or_null("PauseMenu")
	if existing:
		existing.queue_free()
		get_tree().paused = false
		return
	var pause := PauseScene.instantiate()
	pause.name = "PauseMenu"
	add_child(pause)
	get_tree().paused = true


func _on_player_died() -> void:
	AudioManager.play_sfx("explosion")
	get_tree().paused = false
	GameState.go_to_level(level_id)
