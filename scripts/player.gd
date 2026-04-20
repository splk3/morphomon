extends CharacterBody2D

## Player controller that delegates logic to the active FormManager state.

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var form_manager: FormManager = $FormManager
@onready var scanner: Scanner = $Scanner

func _physics_process(delta):
	if form_manager:
		form_manager.process_physics(delta)
	else:
		# Fallback if FormManager is missing (should not happen in production)
		move_and_slide()
	
	# Update scanner direction based on sprite flip
	if scanner and sprite:
		scanner.target_position.x = 100 if !sprite.flip_h else -100

func _process(_delta):
	if form_manager:
		form_manager.process_animations()
		
		# Debug toggle for shapeshifting (cycles through unlocked forms)
		if Input.is_action_just_pressed("debug_transform"):
			form_manager.switch_to_next_form()
