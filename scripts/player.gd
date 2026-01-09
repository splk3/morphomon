extends CharacterBody2D

# Player movement constants
const SPEED = 200.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var facing_right = true

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction != 0:
		velocity.x = direction * SPEED
		# Flip sprite based on direction
		if direction > 0 and not facing_right:
			if sprite:
				sprite.flip_h = false
			facing_right = true
		elif direction < 0 and facing_right:
			if sprite:
				sprite.flip_h = true
			facing_right = false
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	# Update animations
	update_animation()

func update_animation():
	# Null check to handle potential missing AnimationPlayer node
	if not animation_player:
		return
	
	if not is_on_floor():
		animation_player.play("jump")
	elif abs(velocity.x) > 0:
		animation_player.play("run")
	else:
		animation_player.play("idle")
