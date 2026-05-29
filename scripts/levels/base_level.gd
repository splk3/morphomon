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

const LIGHT_RADIAL := "res://textures/light/radial_glow.svg"
const LIGHT_SOFT := "res://textures/light/soft_glow.svg"

# Eagle laser turret (lava theme) timing, in seconds.
const EAGLE_CHARGE_TIME := 0.5
const EAGLE_FIRE_TIME := 1.0
const EAGLE_COOLDOWN_TIME := 5.0
const EAGLE_BEAM_LEN := 1280.0

var level_id := "cruise"
var level_data: Dictionary = {}
var theme: Dictionary = {}
var theme_id := "island"

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

# Per-level lighting / scenery state.
var _platform_spots: Array = []
var _light_time := 0.0
var _lantern_lights: Array = []          # [{light, base, phase, speed}]
var _lava_lights: Array[PointLight2D] = []
var _player_shadow: Polygon2D

# Eagle laser turret state.
var _eagle: Sprite2D
var _eagle_charge: Sprite2D
var _eagle_beam: Node2D
var _eagle_beam_area: Area2D
var _eagle_state := "idle"
var _eagle_timer := 0.0
var _eagle_firing := false


func _ready() -> void:
	level_id = GameState.pending_level_id if GameState.pending_level_id != "" else "cruise"
	level_data = GameState.get_level(level_id)
	theme = LevelThemes.get_theme(String(level_data.get("theme", "island")))
	theme_id = String(level_data.get("theme", "island"))

	_build_parallax()
	_build_ground()
	_build_player()
	_build_camera()
	_build_entities()
	_build_goal()
	_build_weather()
	_build_lighting()
	_build_hud()

	AudioManager.play_music(String(level_data.get("music", "island_theme")))


# --- Background ---------------------------------------------------------
func _build_parallax() -> void:
	var bg := ParallaxBackground.new()
	add_child(bg)
	var idx := 0
	for layer_info in theme.layers:
		_add_parallax_layer(bg, String(layer_info.tex), float(layer_info.scale))
		# Slot distant scenery just in front of the static sky (index 0) so it sits
		# behind the closer themed layers (island: volcano, mountains, waterfalls).
		if idx == 0 and theme.has("far_layers"):
			for far in theme.far_layers:
				_add_parallax_layer(bg, String(far.tex), float(far.scale))
		idx += 1

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


func _add_parallax_layer(bg: ParallaxBackground, tex: String, scale: float) -> void:
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2(scale, 1.0)
	layer.motion_mirroring = Vector2(VIEW.x, 0)
	bg.add_child(layer)
	var spr := Sprite2D.new()
	spr.centered = false
	spr.texture = load(tex)
	layer.add_child(spr)


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
	_platform_spots = platform_spots
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
	_light_time += delta
	_update_weather(delta)
	_update_lava(delta)
	_update_lights(delta)
	_update_eagle(delta)
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


# --- Per-level lighting & scenery --------------------------------------
## Dispatch to the theme-specific lighting builder. Every effect is guarded by
## `theme_id` so other themes (and the headless validator) never touch the
## theme-specific nodes.
func _build_lighting() -> void:
	var cfg: Dictionary = theme.get("lighting", {})
	match theme_id:
		"ice": _build_ice_lighting(cfg)
		"pirate": _build_pirate_lanterns(cfg)
		"lava":
			_build_lava_lighting(cfg)
			_build_laser_eagle()
		"island": _build_island_lighting(cfg)


func _add_canvas_modulate(color: Color) -> void:
	var cm := CanvasModulate.new()
	cm.color = color
	add_child(cm)


func _make_point_light(tex: String, color: Color, energy: float, tscale: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = load(tex)
	light.color = color
	light.energy = energy
	light.texture_scale = tscale
	return light


## Overcast: a cool-white ambient tint, one broad dim white sky light (uniform,
## shadowless = diffuse), plus a row of blue-white uplights rising from the snow.
func _build_ice_lighting(cfg: Dictionary) -> void:
	_add_canvas_modulate(cfg.get("ambient", Color(0.84, 0.89, 0.98)))

	var sky := DirectionalLight2D.new()
	sky.color = cfg.get("sky_color", Color(0.96, 0.98, 1.0))
	sky.energy = float(cfg.get("sky_energy", 0.35))
	add_child(sky)

	var uplight_color: Color = cfg.get("uplight_color", Color(0.62, 0.78, 1.0))
	var uplight_energy := float(cfg.get("uplight_energy", 0.5))
	var x := 320.0
	while x < LEVEL_LENGTH:
		var up := _make_point_light(LIGHT_SOFT, uplight_color, uplight_energy, 1.4)
		up.position = Vector2(x, GROUND_Y + 40)
		add_child(up)
		x += 720.0


## Galleon: darken to dusk, then string several lantern sprites, each with a warm
## radial light that flickers in `_update_lights`.
func _build_pirate_lanterns(cfg: Dictionary) -> void:
	_add_canvas_modulate(cfg.get("ambient", Color(0.6, 0.58, 0.74)))
	var color: Color = cfg.get("lantern_color", Color(1.0, 0.66, 0.32))
	var energy := float(cfg.get("lantern_energy", 1.2))
	var spots := [
		Vector2(520, 440), Vector2(1400, 410), Vector2(1950, 350),
		Vector2(2500, 420), Vector2(3100, 370), Vector2(3600, 440),
	]
	for i in spots.size():
		var spot: Vector2 = spots[i]
		var lantern := Sprite2D.new()
		lantern.texture = load("res://sprites/effects/lantern.svg")
		lantern.position = spot
		add_child(lantern)

		var light := _make_point_light(LIGHT_RADIAL, color, energy, 0.9)
		light.position = spot + Vector2(0, 6)
		add_child(light)
		_lantern_lights.append({
			"light": light, "base": energy,
			"phase": float(i) * 1.7, "speed": 9.0 + float(i % 3) * 2.5,
		})


## Magma: darken the scene so warm pools of light read clearly, then place
## yellow/orange/red lights along the lava that pulse with the lava animation and
## illuminate the player (Light2D modulates sprites in range).
func _build_lava_lighting(cfg: Dictionary) -> void:
	_add_canvas_modulate(cfg.get("ambient", Color(0.6, 0.42, 0.36)))
	var colors: Array = cfg.get("glow_colors", [Color(1.0, 0.5, 0.15)])
	var energy := float(cfg.get("glow_energy", 1.1))
	var x := 240.0
	var i := 0
	while x < LEVEL_LENGTH:
		var color: Color = colors[i % colors.size()]
		var light := _make_point_light(LIGHT_SOFT, color, energy, 1.6)
		light.position = Vector2(x, GROUND_Y - 8)
		add_child(light)
		_lava_lights.append(light)
		x += 500.0
		i += 1


## Robotic laser-eagle turret perched on the right. It cycles
## cooldown -> charge -> fire and back; the beam is a bluish, self-lit hazard.
func _build_laser_eagle() -> void:
	_eagle = Sprite2D.new()
	_eagle.texture = load("res://sprites/enemies/laser_eagle.svg")
	_eagle.position = Vector2(2680, 340)
	_eagle.flip_h = true  # beak faces left, toward the player's approach
	add_child(_eagle)

	var beak := _eagle.position + Vector2(-44, 8)

	# Charge glow at the beak (hidden until charging).
	_eagle_charge = Sprite2D.new()
	_eagle_charge.texture = load("res://sprites/effects/laser_charge_glow.svg")
	_eagle_charge.position = beak
	_eagle_charge.visible = false
	_eagle_charge.z_index = 5
	add_child(_eagle_charge)

	# Beam node centred on the horizontal beam line; children are local to it.
	_eagle_beam = Node2D.new()
	_eagle_beam.position = Vector2(beak.x - EAGLE_BEAM_LEN / 2.0, beak.y)
	_eagle_beam.visible = false
	add_child(_eagle_beam)

	var beam_spr := Sprite2D.new()
	beam_spr.texture = load("res://sprites/effects/laser_beam.svg")
	# Source sprite is 256x32; stretch to the full beam length.
	beam_spr.scale = Vector2(EAGLE_BEAM_LEN / 256.0, 0.9)
	beam_spr.z_index = 4
	_eagle_beam.add_child(beam_spr)

	# Hazard area wired to the same `take_damage` path enemies use.
	_eagle_beam_area = Area2D.new()
	_eagle_beam_area.collision_mask = 1
	_eagle_beam_area.monitoring = true
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(EAGLE_BEAM_LEN, 26)
	shape.shape = box
	_eagle_beam_area.add_child(shape)
	_eagle_beam.add_child(_eagle_beam_area)

	# Bluish self-illumination above and below the beam.
	var beam_x := -EAGLE_BEAM_LEN / 2.0
	while beam_x <= EAGLE_BEAM_LEN / 2.0:
		var glow := _make_point_light(LIGHT_RADIAL, Color(0.45, 0.7, 1.0), 1.3, 0.45)
		glow.position = Vector2(beam_x, 0)
		_eagle_beam.add_child(glow)
		beam_x += 256.0

	# Start in cooldown so the first volley is delayed.
	_eagle_state = "cooldown"
	_eagle_timer = EAGLE_COOLDOWN_TIME


func _update_eagle(_delta: float) -> void:
	if _eagle == null:
		return
	_eagle_timer -= _delta
	match _eagle_state:
		"cooldown":
			if _eagle_timer <= 0.0:
				_start_eagle_charge()
		"charge":
			# Grow + pulse the charge glow as it winds up.
			var t := 1.0 - clampf(_eagle_timer / EAGLE_CHARGE_TIME, 0.0, 1.0)
			if _eagle_charge:
				var s := lerpf(0.3, 1.4, t) + sin(_light_time * 30.0) * 0.1
				_eagle_charge.scale = Vector2(s, s)
			if _eagle_timer <= 0.0:
				_start_eagle_fire()
		"fire":
			_damage_with_beam()
			if _eagle_beam:
				_eagle_beam.modulate.a = 0.85 + sin(_light_time * 40.0) * 0.15
			if _eagle_timer <= 0.0:
				_end_eagle_fire()


func _start_eagle_charge() -> void:
	_eagle_state = "charge"
	_eagle_timer = EAGLE_CHARGE_TIME
	if _eagle_charge:
		_eagle_charge.visible = true
		_eagle_charge.scale = Vector2(0.3, 0.3)
	AudioManager.play_sfx("laser_charge")


func _start_eagle_fire() -> void:
	_eagle_state = "fire"
	_eagle_timer = EAGLE_FIRE_TIME
	_eagle_firing = true
	if _eagle_charge:
		_eagle_charge.visible = false
	if _eagle_beam:
		_eagle_beam.visible = true
	AudioManager.play_sfx("laser")


func _end_eagle_fire() -> void:
	_eagle_state = "cooldown"
	_eagle_timer = EAGLE_COOLDOWN_TIME
	_eagle_firing = false
	if _eagle_beam:
		_eagle_beam.visible = false


func _damage_with_beam() -> void:
	if not _eagle_firing or _eagle_beam_area == null:
		return
	for body in _eagle_beam_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(1)


## Castaway Cove: a warm sun key light following the player plus simulated
## drop-shadows (platforms, beach trees, and a live shadow under the player) so
## everything appears to cast shadows toward the ground.
func _build_island_lighting(cfg: Dictionary) -> void:
	if _player:
		var sun := _make_point_light(LIGHT_SOFT, cfg.get("sun_color", Color(1.0, 0.95, 0.82)),
			float(cfg.get("sun_energy", 0.3)), 6.0)
		sun.position = Vector2(-300, -480)  # high and to the upper-left
		_player.add_child(sun)

	# Platform drop-shadows, offset down-right (sun from upper-left).
	for spot in _platform_spots:
		var sh := _make_shadow(100.0, 16.0)
		sh.position = Vector2(spot.x + 90 + 20, GROUND_Y + 8)
		add_child(sh)

	# A few beach-tree shadows pooled on the sand.
	for tx in [300.0, 1100.0, 2200.0, 3300.0]:
		var tsh := _make_shadow(72.0, 14.0)
		tsh.position = Vector2(tx + 24, GROUND_Y + 10)
		add_child(tsh)

	# Live shadow that tracks the player (updated in `_update_lights`).
	_player_shadow = _make_shadow(24.0, 9.0, 0.32)
	add_child(_player_shadow)


func _make_shadow(rx: float, ry: float, alpha := 0.28) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.color = Color(0, 0, 0, alpha)
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	poly.polygon = pts
	poly.z_index = -1
	return poly


func _update_lights(_delta: float) -> void:
	# Lantern flame flicker (warm, organic).
	for entry in _lantern_lights:
		var l: PointLight2D = entry.light
		var f: float = float(entry.base) + sin(_light_time * float(entry.speed) + float(entry.phase)) * 0.2
		f += (randf() - 0.5) * 0.12
		l.energy = maxf(0.2, f)

	# Lava pools pulse subtly with the lava animation.
	if not _lava_lights.is_empty():
		var pulse := 0.95 + sin(_light_time * 2.2) * 0.18
		for i in _lava_lights.size():
			_lava_lights[i].energy = pulse + sin(_light_time * 3.3 + float(i)) * 0.1

	# Player drop-shadow tracks the player along the ground.
	if _player_shadow and _player:
		_player_shadow.global_position = Vector2(_player.global_position.x + 12, GROUND_Y + 6)

