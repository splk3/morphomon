extends Node2D

@onready var camera = $Camera2D
@onready var player = $Player
@onready var hud = $HUD

func _ready():
	if player and hud:
		var form_manager = player.get_node("FormManager")
		if form_manager:
			hud.setup_connections(form_manager)

func _process(_delta):
	# Make camera follow player position
	if player and camera:
		camera.global_position = player.global_position
