extends BaseForm
class_name BirdForm

## A creature form capable of gliding through the air.

@export var glide_gravity_multiplier := 0.15
@export var air_speed := 300.0

func _init():
	speed = 250.0 # Faster than human (200)
	jump_velocity = -350.0 # Slightly weaker jump than human

var facing_right = true

func handle_physics(delta: float):
	if not player:
		return

	# Determine current gravity
	var current_gravity = gravity
	if not player.is_on_floor() and player.velocity.y > 0:
		if Input.is_action_pressed("jump"):
			current_gravity *= glide_gravity_multiplier
			# Slow the falling speed when gliding
			player.velocity.y = min(player.velocity.y, 50.0)

	# Add the gravity.
	if not player.is_on_floor():
		player.velocity.y += current_gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.velocity.y = jump_velocity

	# Get input direction
	var direction = Input.get_axis("move_left", "move_right")
	
	# Horizontal movement
	var current_speed = speed if player.is_on_floor() else air_speed
	
	if direction != 0:
		player.velocity.x = direction * current_speed
		if direction > 0 and not facing_right:
			_set_facing(true)
		elif direction < 0 and facing_right:
			_set_facing(false)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, current_speed)

	player.move_and_slide()

func _set_facing(is_right: bool):
	facing_right = is_right
	if player.sprite:
		player.sprite.flip_h = !is_right
		player.sprite.modulate = Color.CYAN

func enter():
	super.enter()
	if player and player.sprite:
		player.sprite.modulate = Color.CYAN

func exit():
	super.exit()
	if player and player.sprite:
		player.sprite.modulate = Color.WHITE

func update_animations():
	if not player or not player.animation_player:
		return
	
	if not player.is_on_floor():
		if Input.is_action_pressed("jump") and player.velocity.y > 0:
			# Reuse jump animation for glide for now
			player.animation_player.play("jump")
		else:
			player.animation_player.play("jump")
	elif abs(player.velocity.x) > 0:
		player.animation_player.play("run")
	else:
		player.animation_player.play("idle")
