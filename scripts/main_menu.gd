extends Control

func _ready():
	# Connect button signals
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	# Change to the main game level
	get_tree().change_scene_to_file("res://scenes/level1.tscn")

func _on_quit_pressed():
	# Quit the game
	get_tree().quit()
