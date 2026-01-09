extends Node2D

@onready var camera = $Camera2D
@onready var player = $Player

func _process(_delta):
	# Make camera follow player position
	if player and camera:
		camera.global_position = player.global_position
