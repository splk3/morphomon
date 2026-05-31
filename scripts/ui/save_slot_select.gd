extends Control

const MODE_NEW := "new"
const MODE_LOAD := "load"

@onready var title_label: Label = $Panel/Title
@onready var subtitle_label: Label = $Panel/Subtitle
@onready var slot_buttons: Array[Button] = [
	$Panel/Slots/Slot1Button,
	$Panel/Slots/Slot2Button,
	$Panel/Slots/Slot3Button,
]
@onready var unsaved_button: Button = $Panel/Slots/UnsavedButton
@onready var back_button: Button = $Panel/Footer/BackButton

var _mode := MODE_NEW


func _ready() -> void:
	_mode = String(GameState.get_meta("save_slot_mode", MODE_NEW))
	if _mode != MODE_LOAD:
		_mode = MODE_NEW
	_refresh_ui()
	_connect_signals()
	_focus_default()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()


func _connect_signals() -> void:
	for idx in slot_buttons.size():
		var btn := slot_buttons[idx]
		btn.focus_entered.connect(_play_nav)
		btn.pressed.connect(_on_slot_pressed.bind(idx))
	unsaved_button.focus_entered.connect(_play_nav)
	unsaved_button.pressed.connect(_on_unsaved_pressed)
	back_button.focus_entered.connect(_play_nav)
	back_button.pressed.connect(_on_back)


func _refresh_ui() -> void:
	var load_mode := _mode == MODE_LOAD
	title_label.text = "LOAD GAME" if load_mode else "START NEW GAME"
	subtitle_label.text = "Choose a save slot to load." if load_mode else "Choose a slot or play without saving."
	unsaved_button.visible = not load_mode
	for slot_id in slot_buttons.size():
		var btn := slot_buttons[slot_id]
		var summary := _slot_summary(slot_id)
		btn.text = _slot_label(slot_id, summary, load_mode)
		btn.disabled = load_mode and not bool(summary.get("occupied", false))


func _slot_summary(slot_id: int) -> Dictionary:
	var summaries: Array = GameState.get_slot_summaries()
	if slot_id < 0 or slot_id >= summaries.size():
		return {"occupied": false, "main_complete": 0, "boss_complete": false}
	return summaries[slot_id]


func _slot_label(slot_id: int, summary: Dictionary, load_mode: bool) -> String:
	var label := "Slot %d" % (slot_id + 1)
	if bool(summary.get("occupied", false)):
		var cleared := int(summary.get("main_complete", 0))
		var boss_status := "Boss cleared" if bool(summary.get("boss_complete", false)) else "Boss pending"
		var play_state := "Loadable" if load_mode else "Overwrite"
		return "%s\n%s • %d main cleared • %s" % [label, play_state, cleared, boss_status]
	return "%s\nEmpty" % label


func _focus_default() -> void:
	for btn in slot_buttons:
		if not btn.disabled and btn.visible:
			btn.grab_focus()
			return
	if unsaved_button.visible:
		unsaved_button.grab_focus()
	else:
		back_button.grab_focus()


func _play_nav() -> void:
	AudioManager.play_sfx("ui_nav")


func _play_back() -> void:
	AudioManager.play_sfx("ui_back")


func _on_slot_pressed(slot_id: int) -> void:
	if _mode == MODE_LOAD:
		if not GameState.load_game_from_slot(slot_id):
			_play_back()
			return
	else:
		if not GameState.start_new_game_in_slot(slot_id):
			_play_back()
			return
	AudioManager.play_sfx("confirm")
	_continue_game_flow()


func _on_unsaved_pressed() -> void:
	GameState.start_unsaved_session()
	AudioManager.play_sfx("confirm")
	GameState.go_to_level("cruise")


func _continue_game_flow() -> void:
	if GameState.is_complete("cruise"):
		get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
	else:
		GameState.go_to_level("cruise")


func _on_back() -> void:
	_play_back()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
