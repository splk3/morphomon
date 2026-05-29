extends Control
## Settings menu with Graphics, Audio and Controls tabs.
##
## Graphics: resolution + fullscreen. Audio: master/music/SFX volume sliders.
## Controls: per-action rebinding that captures the next keyboard key or gamepad
## button/axis. All changes apply immediately and persist via the Settings
## singleton.

var _rebinding_action := ""
var _row_buttons: Dictionary = {}

@onready var resolution_option: OptionButton = $Panel/Margin/Tabs/Graphics/Grid/ResolutionOption
@onready var fullscreen_check: CheckButton = $Panel/Margin/Tabs/Graphics/Grid/FullscreenCheck
@onready var master_slider: HSlider = $Panel/Margin/Tabs/Audio/Grid/MasterSlider
@onready var music_slider: HSlider = $Panel/Margin/Tabs/Audio/Grid/MusicSlider
@onready var sfx_slider: HSlider = $Panel/Margin/Tabs/Audio/Grid/SFXSlider
@onready var controls_list: VBoxContainer = $Panel/Margin/Tabs/Controls/Scroll/ControlsList
@onready var rebind_hint: Label = $Panel/Margin/Tabs/Controls/Hint


func _ready() -> void:
	_populate_graphics()
	_populate_audio()
	_populate_controls()
	$Panel/Margin/Tabs/Graphics/Grid/ResolutionOption.item_selected.connect(_on_resolution_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	$Panel/Footer/BackButton.pressed.connect(_on_back)
	$Panel/Footer/ResetButton.pressed.connect(_on_reset_controls)
	$Panel/Footer/BackButton.grab_focus()


# --- Graphics -----------------------------------------------------------
func _populate_graphics() -> void:
	resolution_option.clear()
	for res in Settings.RESOLUTIONS:
		resolution_option.add_item("%d x %d" % [res.x, res.y])
	resolution_option.selected = Settings.resolution_index
	fullscreen_check.button_pressed = Settings.fullscreen


func _on_resolution_selected(index: int) -> void:
	Settings.resolution_index = index
	Settings.apply_video()
	Settings.save_settings()


func _on_fullscreen_toggled(pressed: bool) -> void:
	Settings.fullscreen = pressed
	Settings.apply_video()
	Settings.save_settings()


# --- Audio --------------------------------------------------------------
func _populate_audio() -> void:
	master_slider.min_value = 0.0
	master_slider.max_value = 1.0
	master_slider.step = 0.05
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	master_slider.value = Settings.master_volume
	music_slider.value = Settings.music_volume
	sfx_slider.value = Settings.sfx_volume


func _on_master_changed(v: float) -> void:
	Settings.master_volume = v
	Settings.apply_audio()
	Settings.save_settings()


func _on_music_changed(v: float) -> void:
	Settings.music_volume = v
	Settings.apply_audio()
	Settings.save_settings()


func _on_sfx_changed(v: float) -> void:
	Settings.sfx_volume = v
	Settings.apply_audio()
	Settings.save_settings()
	AudioManager.play_sfx("select")


# --- Controls -----------------------------------------------------------
func _populate_controls() -> void:
	for child in controls_list.get_children():
		child.queue_free()
	_row_buttons.clear()
	for action in Settings.REBINDABLE_ACTIONS:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 40)
		var name_label := Label.new()
		name_label.text = action.capitalize()
		name_label.custom_minimum_size = Vector2(220, 0)
		name_label.add_theme_font_size_override("font_size", 20)
		row.add_child(name_label)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(260, 0)
		btn.add_theme_font_size_override("font_size", 18)
		btn.text = Settings.get_binding_text(action)
		btn.pressed.connect(_begin_rebind.bind(action))
		row.add_child(btn)
		controls_list.add_child(row)
		_row_buttons[action] = btn


func _begin_rebind(action: String) -> void:
	_rebinding_action = action
	rebind_hint.text = "Press a key or gamepad button for '%s'  (Esc to cancel)" % action.capitalize()
	if _row_buttons.has(action):
		_row_buttons[action].text = "..."


func _input(event: InputEvent) -> void:
	if _rebinding_action == "":
		return
	var captured: InputEvent = null
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_cancel_rebind()
			return
		captured = event
	elif event is InputEventJoypadButton and event.pressed:
		captured = event
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.6:
		captured = event
	if captured:
		Settings.rebind_action(_rebinding_action, captured)
		Settings.save_settings()
		var action := _rebinding_action
		_rebinding_action = ""
		rebind_hint.text = "Click a binding to remap it."
		if _row_buttons.has(action):
			_row_buttons[action].text = Settings.get_binding_text(action)
		AudioManager.play_sfx("confirm")
		get_viewport().set_input_as_handled()


func _cancel_rebind() -> void:
	var action := _rebinding_action
	_rebinding_action = ""
	rebind_hint.text = "Click a binding to remap it."
	if _row_buttons.has(action):
		_row_buttons[action].text = Settings.get_binding_text(action)


func _on_reset_controls() -> void:
	Settings.reset_controls()
	Settings.save_settings()
	_populate_controls()
	AudioManager.play_sfx("select")


func _on_back() -> void:
	AudioManager.play_sfx("select")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
