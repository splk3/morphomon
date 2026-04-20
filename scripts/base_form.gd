extends Node
class_name BaseForm

## Base class for all player forms (Human, Bird, Wolf, etc.)

# Movement constants that can be overridden by specific forms
@export var speed := 200.0
@export var jump_velocity := -400.0

# References to be set by the FormManager
var player: CharacterBody2D
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# Ensure the node is disabled by default until the FormManager activates it
	set_physics_process(false)
	set_process(false)

## Called when the form becomes active
func enter():
	set_physics_process(true)
	set_process(true)

## Called when the form is no longer active
func exit():
	set_physics_process(false)
	set_process(false)

## Handle movement logic - to be overridden
func handle_physics(delta: float):
	pass

## Handle animation logic - to be overridden
func update_animations():
	pass
