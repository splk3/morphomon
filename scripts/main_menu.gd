extends Control
## Main menu: an energetic, auto-scrolling beach-at-sunset parallax scene with
## Morphomon racing along a coastal road, looping chiptune music, and Start /
## Settings / Quit options. Backgrounds scroll continuously to convey motion.
##
## Depth is layered back-to-front. The horizon (where water meets sky) is the
## farthest point, so its layers scroll slowest; layers get faster toward the
## viewer (lower water, nearer clouds, foreground palms). Morphomon races behind
## the foreground palms but in front of everything else. A warm sun light with
## moving, parallax-anchored shadows and tread dust complete the scene.

const MENU_DIR := "res://backgrounds/menu/"
const VIEW_W := 1280.0

# Layers ordered back (farthest) to front (nearest). Speed is px/sec; faster =
# nearer the camera. Each entry's z_index is derived from its order (index * Z_STEP)
# so Morphomon can be slotted between the road and the foreground palms.
const Z_STEP := 10
const LAYERS := [
	# --- SKY (5 layers): horizon-hugging haze slowest, low clouds fastest ---
	{"tex": "sky_sunset.svg", "speed": 0.0},    # 0  base sky / sun
	{"tex": "sky_haze.svg", "speed": 3.0},      # 1  warm horizon haze (farthest)
	{"tex": "clouds_far.svg", "speed": 9.0},    # 2  tiny high clouds
	{"tex": "clouds.svg", "speed": 18.0},       # 3  mid clouds
	{"tex": "clouds_near.svg", "speed": 30.0},  # 4  big low clouds (nearest sky)
	# --- WATER (5 layers): horizon slowest, near-shore surf fastest ---
	{"tex": "water_horizon.svg", "speed": 5.0}, # 5  shimmer at the horizon (farthest)
	{"tex": "ocean.svg", "speed": 18.0},        # 6  base water body
	{"tex": "water_far.svg", "speed": 40.0},    # 7  mid ripples
	{"tex": "waves.svg", "speed": 90.0},        # 8  swell
	{"tex": "water_near.svg", "speed": 150.0},  # 9  near-shore surf (nearest water)
	# --- LAND ---
	{"tex": "palms_far.svg", "speed": 60.0},    # 10 distant palms
	{"tex": "road.svg", "speed": 240.0},        # 11 road + sea wall
	# (Morphomon is slotted here, between road and the foreground palms.)
	{"tex": "palms_near.svg", "speed": 300.0},  # 12 foreground palms (in front of morph)
]

# Trunk occluder columns (x ranges) authored in palms_near.svg, plus the road's
# sea wall, used so shadows are cast by real scene elements and move with scroll.
const NEAR_PALM_TRUNKS := [Vector2(180, 210), Vector2(1070, 1102)]

var _scrollers: Array = []  # {sprites:[Sprite2D,...], speed:float}
var _morph: Sprite2D
var _morph_run: Texture2D
var _morph_idle: Texture2D
var _dust: CPUParticles2D
var _anim_time := 0.0

const MORPH_BASE_POS := Vector2(360, 560)
var _morph_z := 0


func _ready() -> void:
	_build_lighting()
	_build_background()
	_build_morphomon()
	_build_dust()
	$Menu/VBox/StartButton.pressed.connect(_on_start)
	$Menu/VBox/SettingsButton.pressed.connect(_on_settings)
	$Menu/VBox/QuitButton.pressed.connect(_on_quit)
	$Menu/VBox/StartButton.grab_focus()
	AudioManager.play_music("menu_theme")


## Warm ambient tint + a large sun-like PointLight2D with shadows enabled.
func _build_lighting() -> void:
	var holder := $Parallax

	# Gentle warm ambient so the un-lit scene reads as golden hour, not noon.
	var ambient := CanvasModulate.new()
	ambient.name = "Ambient"
	ambient.color = Color(0.90, 0.82, 0.72)
	holder.add_child(ambient)

	# The sun: a big soft radial light positioned over the painted sun. It does
	# not scroll, so shadows from the moving occluders sweep as the scene scrolls.
	var sun := PointLight2D.new()
	sun.name = "SunLight"
	sun.texture = _make_radial_light_texture(512, Color(1.0, 0.86, 0.6))
	sun.position = Vector2(640, 300)
	sun.energy = 1.15
	sun.texture_scale = 3.0
	sun.color = Color(1.0, 0.88, 0.66)
	sun.shadow_enabled = true
	sun.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	sun.shadow_color = Color(0.18, 0.10, 0.22, 0.55)
	# Keep the light off the UI canvas (z 0+) and focused on the scene art.
	sun.range_z_min = -100
	sun.range_z_max = 200
	sun.z_index = 200
	holder.add_child(sun)


## Procedurally builds the layered parallax background.
func _build_background() -> void:
	var holder := $Parallax
	for i in LAYERS.size():
		var info: Dictionary = LAYERS[i]
		var tex: Texture2D = load(MENU_DIR + info.tex)
		var z := i * Z_STEP
		var pair: Array = []
		for k in 2:
			var spr := Sprite2D.new()
			spr.centered = false
			spr.texture = tex
			spr.position = Vector2(k * VIEW_W, 0)
			spr.z_index = z
			holder.add_child(spr)
			pair.append(spr)
			_attach_occluders(spr, String(info.tex))
		_scrollers.append({"sprites": pair, "speed": float(info.speed)})


## Adds shadow-casting occluders to the foreground palms and the sea wall so the
## sun casts real shadows that travel with the parallax scroll.
func _attach_occluders(spr: Sprite2D, tex_name: String) -> void:
	if tex_name == "palms_near.svg":
		for col in NEAR_PALM_TRUNKS:
			_add_rect_occluder(spr, Rect2(col.x, 540, col.y - col.x, 180))
	elif tex_name == "road.svg":
		# The sea wall strip painted across the top of the road.
		_add_rect_occluder(spr, Rect2(0, 534, VIEW_W, 22))


func _add_rect_occluder(parent: Node2D, rect: Rect2) -> void:
	var occ := LightOccluder2D.new()
	var poly := OccluderPolygon2D.new()
	poly.polygon = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
	])
	occ.occluder = poly
	parent.add_child(occ)


func _build_morphomon() -> void:
	_morph_idle = load("res://sprites/forms/morphomon_idle.svg")
	_morph_run = load("res://sprites/forms/morphomon_run.svg")
	_morph = Sprite2D.new()
	_morph.name = "Morphomon"
	_morph.texture = _morph_run
	_morph.scale = Vector2(2.2, 2.2)
	_morph.position = MORPH_BASE_POS
	# Between the road (z 110) and the foreground palms (z 120): morph races
	# behind the front trees but in front of the road, water and sky.
	_morph_z = 11 * Z_STEP + Z_STEP / 2  # 115
	_morph.z_index = _morph_z
	$Parallax.add_child(_morph)

	# A small occluder so Morphomon casts its own moving sun shadow.
	var occ := LightOccluder2D.new()
	var poly := OccluderPolygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-18, -26), Vector2(18, -26), Vector2(18, 22), Vector2(-18, 22),
	])
	occ.occluder = poly
	_morph.add_child(occ)


## Semi-transparent dust kicked up behind Morphomon's treads, drifting backward.
func _build_dust() -> void:
	_dust = CPUParticles2D.new()
	_dust.name = "TreadDust"
	_dust.texture = _make_radial_light_texture(64, Color(1, 1, 1))
	_dust.z_index = _morph_z - 1  # just behind morph so it reads as kicked-up dust
	_dust.amount = 28
	_dust.lifetime = 0.9
	_dust.preprocess = 0.5
	_dust.local_coords = false
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(10, 8)
	# Emit roughly leftward/backward and slightly up, then settle with gravity.
	_dust.direction = Vector2(-1, -0.35)
	_dust.spread = 28.0
	_dust.initial_velocity_min = 60.0
	_dust.initial_velocity_max = 130.0
	_dust.gravity = Vector2(0, 60)
	_dust.damping_min = 30.0
	_dust.damping_max = 70.0
	_dust.scale_amount_min = 1.4
	_dust.scale_amount_max = 3.2
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0, 0.4))
	scale_curve.add_point(Vector2(0.3, 1.0))
	scale_curve.add_point(Vector2(1, 1.6))
	_dust.scale_amount_curve = scale_curve
	# Warm dusty color that fades to transparent over the particle lifetime.
	_dust.color = Color(0.86, 0.74, 0.56, 0.55)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.92, 0.82, 0.62, 0.0))
	ramp.set_color(1, Color(0.80, 0.66, 0.48, 0.0))
	ramp.add_point(0.18, Color(0.92, 0.82, 0.62, 0.6))
	_dust.color_ramp = ramp
	_dust.emitting = true
	$Parallax.add_child(_dust)
	_position_dust()


## Builds a soft white->transparent radial texture for lights and particles.
func _make_radial_light_texture(size: int, tint: Color) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(tint.r, tint.g, tint.b, 1.0))
	grad.set_color(1, Color(tint.r, tint.g, tint.b, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = size
	tex.height = size
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex


func _position_dust() -> void:
	if _dust and _morph:
		# Behind and below the treads.
		_dust.position = _morph.position + Vector2(-46, 30)


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
		_morph.position.y = MORPH_BASE_POS.y + sin(_anim_time * 12.0) * 6.0
		_position_dust()


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
