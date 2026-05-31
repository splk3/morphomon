extends CanvasLayer
## Pause overlay shown during levels. Runs while the tree is paused.

func _ready() -> void:
	for button in _menu_buttons():
		button.focus_entered.connect(_play_nav)
		button.pressed.connect(_play_select)
	$Root/Panel/VBox/Resume.pressed.connect(_resume)
	$Root/Panel/VBox/Restart.pressed.connect(_restart)
	$Root/Panel/VBox/LevelSelect.pressed.connect(_level_select)
	$Root/Panel/VBox/MainMenu.pressed.connect(_main_menu)
	$Root/Panel/VBox/Resume.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_play_back()
		_resume()


func _menu_buttons() -> Array[Button]:
	return [
		$Root/Panel/VBox/Resume,
		$Root/Panel/VBox/Restart,
		$Root/Panel/VBox/LevelSelect,
		$Root/Panel/VBox/MainMenu,
	]


func _play_nav() -> void:
	AudioManager.play_sfx("ui_nav")


func _play_select() -> void:
	AudioManager.play_sfx("ui_select")


func _play_back() -> void:
	AudioManager.play_sfx("ui_back")


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
