## Morphomon player controller with a data-driven transformation system.
##
## Movement, jump, attack style and special ability all come from the current
## form (see `MorphForms`). The base form rolls on treads and fires homing
## missiles; rescued animals grant alternate forms with unique movement and
## attacks. Supports keyboard and gamepad via the project input actions.

extends CharacterBody2D

const SPEED := 200.0
const JUMP_VELOCITY := -400.0
const FLY_FORCE := -260.0
const ATTACK_COOLDOWN := 0.35

const MissileScene := preload("res://scenes/entities/projectile.tscn")

signal health_changed(current: int, maximum: int)
signal form_changed(form_id: String)
signal died

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_right := true

# Runtime movement parameters, overwritten by the active form.
var speed := SPEED
var jump_velocity := JUMP_VELOCITY
var can_fly := false
var double_jump := false
var phase_walls := false
var attack_kind := "missile"
var ability := "dash"

var form_id := "default"
var max_health := 5
var health := 5

var _jumps_used := 0
var _attack_timer := 0.0
var _invuln_timer := 0.0
var _dash_timer := 0.0

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")


func _ready() -> void:
	if _has_game_state():
		apply_form(GameState.current_form)
	else:
		apply_form("default")


func _has_game_state() -> bool:
	# GameState is an autoload; guard so the script still loads in isolation (unit tests).
	return get_tree() != null and get_tree().root.has_node("GameState")


## Switch to a different transformation, updating stats and the visible sprite.
func apply_form(new_form_id: String) -> void:
	form_id = new_form_id
	var data := MorphForms.get_form(form_id)
	speed = data.speed
	jump_velocity = data.jump
	can_fly = data.can_fly
	double_jump = data.double_jump
	phase_walls = data.phase_walls
	attack_kind = data.attack_kind
	ability = data.ability
	if sprite:
		sprite.texture = load(data.idle)
	if _has_game_state():
		GameState.current_form = form_id
	form_changed.emit(form_id)


func transform_into(new_form_id: String) -> void:
	apply_form(new_form_id)
	if _has_game_state():
		GameState.unlock_form(new_form_id)
	_play_sfx("transform")


## Cycle through the forms the player has unlocked so far. Used freely in stages
## and required in the boss fight to match each fake Morphomon.
func cycle_form() -> void:
	if not _has_game_state():
		return
	var forms: Array = GameState.unlocked_forms
	if forms.size() <= 1:
		return
	var idx := forms.find(form_id)
	var next: String = forms[(idx + 1) % forms.size()]
	apply_form(next)
	_play_sfx("select")


func _physics_process(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_invuln_timer = maxf(0.0, _invuln_timer - delta)
	_dash_timer = maxf(0.0, _dash_timer - delta)

	var on_floor := is_on_floor()
	if on_floor:
		_jumps_used = 0

	# Flight (eagle) or gravity.
	if can_fly and Input.is_action_pressed("jump"):
		velocity.y = maxf(velocity.y + FLY_FORCE * delta, FLY_FORCE)
	elif not on_floor:
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump"):
		_try_jump(on_floor)

	if Input.is_action_just_pressed("attack"):
		_attack()

	if Input.is_action_just_pressed("ability"):
		_use_ability()

	if Input.is_action_just_pressed("cycle_form"):
		cycle_form()

	var direction := Input.get_axis("move_left", "move_right")
	var current_speed := speed * (2.0 if _dash_timer > 0.0 else 1.0)
	if direction != 0:
		velocity.x = direction * current_speed
		facing_right = direction > 0
		if sprite:
			sprite.flip_h = not facing_right
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	update_animation()


func _try_jump(on_floor: bool) -> void:
	if on_floor:
		velocity.y = jump_velocity
		_jumps_used = 1
	elif double_jump and _jumps_used < 2:
		velocity.y = jump_velocity * 0.9
		_jumps_used += 1


func _attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = ATTACK_COOLDOWN
	var dir := 1.0 if facing_right else -1.0
	match attack_kind:
		"missile":
			_spawn_projectile(dir, true)
			_play_sfx("shoot")
		"laser":
			_spawn_projectile(dir, false)
			_play_sfx("laser")
		"melee":
			_spawn_melee(dir)
			_play_sfx("hit")


func _spawn_projectile(dir: float, homing: bool) -> void:
	if not is_inside_tree():
		return
	var proj := MissileScene.instantiate()
	proj.global_position = global_position + Vector2(dir * 24.0, -4.0)
	proj.setup(dir, homing)
	get_parent().add_child(proj)


func _spawn_melee(dir: float) -> void:
	if not is_inside_tree():
		return
	var hitbox := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 28)
	shape.shape = rect
	hitbox.add_child(shape)
	hitbox.position = Vector2(dir * 28.0, 0.0)
	hitbox.set_meta("damage", 2)
	hitbox.add_to_group("player_attack")
	add_child(hitbox)
	# Brief active window for the swipe.
	get_tree().create_timer(0.15).timeout.connect(hitbox.queue_free)


func _use_ability() -> void:
	match ability:
		"dash", "roll":
			_dash_timer = 0.25
			_invuln_timer = 0.25  # rolling/dashing briefly dodges damage
		"toss", "swing", "fly":
			# Heavy-lift toss, rigging swing and sustained flight are scaffolded
			# here; see PR notes for the full mechanic roadmap.
			_dash_timer = 0.2


func take_damage(amount: int) -> void:
	if _invuln_timer > 0.0:
		return
	health = max(0, health - amount)
	_invuln_timer = 0.8
	health_changed.emit(health, max_health)
	_play_sfx("hit")
	if health <= 0:
		died.emit()


func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)


func update_animation() -> void:
	if not sprite:
		return
	var data := MorphForms.get_form(form_id)
	var moving := absf(velocity.x) > 5.0
	var tex_path: String = data.run if moving or (can_fly and not is_on_floor()) else data.idle
	sprite.texture = load(tex_path)


func _play_sfx(key: String) -> void:
	if _has_game_state() and get_tree().root.has_node("AudioManager"):
		get_tree().root.get_node("AudioManager").play_sfx(key)
