extends BaseForm
class_name HumanForm

## The default human "Boy" form.

var facing_right = true

func handle_physics(delta: float):
	if not player:
		return

	# Add the gravity.
	if not player.is_on_floor():
		player.velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction != 0:
		player.velocity.x = direction * speed
		# Flip sprite based on direction
		if direction > 0 and not facing_right:
			_set_facing(true)
		elif direction < 0 and facing_right:
			_set_facing(false)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, speed)

	player.move_and_slide()

func _set_facing(is_right: bool):
	facing_right = is_right
	if player.sprite:
		player.sprite.flip_h = !is_right

func update_animations():
	if not player or not player.animation_player:
		return
	
	if not player.is_on_floor():
		player.animation_player.play("jump")
	elif abs(player.velocity.x) > 0:
		player.animation_player.play("run")
	else:
		player.animation_player.play("idle")
