extends CanvasLayer
## Pause overlay shown during levels. Runs while the tree is paused.

func _ready() -> void:
	$Root/Panel/VBox/Resume.pressed.connect(_resume)
	$Root/Panel/VBox/Restart.pressed.connect(_restart)
	$Root/Panel/VBox/LevelSelect.pressed.connect(_level_select)
	$Root/Panel/VBox/MainMenu.pressed.connect(_main_menu)
	$Root/Panel/VBox/Resume.grab_focus()


func _resume() -> void:
	get_tree().paused = false
	queue_free()


func _restart() -> void:
	get_tree().paused = false
	GameState.go_to_level(GameState.pending_level_id)


func _level_select() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")


func _main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
