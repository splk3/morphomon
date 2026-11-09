extends Control
## Settings menu with Graphics, Audio and Controls tabs.
##
## Graphics: resolution + fullscreen. Audio: master/music/SFX volume sliders.
## Controls: per-action rebinding that captures the next keyboard key or gamepad
## button/axis. Resolution changes are staged until Apply; other settings persist
## immediately through the Settings singleton.

## Seconds to wait for the player to confirm a new resolution before reverting.
const RESOLUTION_CONFIRM_TIMEOUT := 10

var _rebinding_action := ""
var _pending_resolution_index := 0
var _row_buttons: Dictionary = {}

var _confirm_dialog: ConfirmationDialog
var _confirm_timer: Timer
var _confirm_seconds_left := 0
var _resolution_before_apply := 0
var _confirming := false

@onready var resolution_option: OptionButton = $Panel/Margin/Tabs/Graphics/Grid/ResolutionOption
@onready var fullscreen_check: CheckButton = $Panel/Margin/Tabs/Graphics/Grid/FullscreenCheck
@onready var master_slider: HSlider = $Panel/Margin/Tabs/Audio/Grid/MasterSlider
@onready var music_slider: HSlider = $Panel/Margin/Tabs/Audio/Grid/MusicSlider
@onready var sfx_slider: HSlider = $Panel/Margin/Tabs/Audio/Grid/SFXSlider
@onready var controls_list: VBoxContainer = $Panel/Margin/Tabs/Controls/Scroll/ControlsList
@onready var rebind_hint: Label = $Panel/Margin/Tabs/Controls/Hint
@onready var apply_button: Button = $Panel/Footer/ApplyButton
@onready var back_button: Button = $Panel/Footer/BackButton
@onready var reset_button: Button = $Panel/Footer/ResetButton


func _ready() -> void:
	_populate_graphics()
	_populate_audio()
	_populate_controls()
	_register_menu_sfx()
	resolution_option.item_selected.connect(_on_resolution_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	apply_button.pressed.connect(_on_apply)
	back_button.pressed.connect(_on_back)
	reset_button.pressed.connect(_on_reset_controls)
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _rebinding_action != "" or _confirming:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()


func _register_menu_sfx() -> void:
	for control in [
		resolution_option, fullscreen_check, master_slider, music_slider, sfx_slider,
		apply_button, back_button, reset_button,
	]:
		control.focus_entered.connect(_play_nav)
	resolution_option.item_selected.connect(_play_select_for_index)
	fullscreen_check.pressed.connect(_play_select)
	apply_button.pressed.connect(_play_select)
	reset_button.pressed.connect(_play_select)


func _play_nav() -> void:
	AudioManager.play_sfx("ui_nav")


func _play_select() -> void:
	AudioManager.play_sfx("ui_select")


func _play_select_for_index(_index: int) -> void:
	_play_select()


func _play_back() -> void:
	AudioManager.play_sfx("ui_back")


# --- Graphics -----------------------------------------------------------
func _populate_graphics() -> void:
	Settings.refresh_resolutions()
	resolution_option.clear()
	for res in Settings.resolutions:
		resolution_option.add_item("%d x %d" % [res.x, res.y])
	_pending_resolution_index = Settings.resolution_index
	resolution_option.selected = _pending_resolution_index
	fullscreen_check.button_pressed = Settings.fullscreen


func _on_resolution_selected(index: int) -> void:
	_pending_resolution_index = index


func _on_apply() -> void:
	if _confirming:
		return
	# In fullscreen, apply_video() ignores the windowed size, so a resolution
	# change has no visible effect and needs no confirmation.
	if _pending_resolution_index == Settings.resolution_index or Settings.fullscreen:
		Settings.resolution_index = _pending_resolution_index
		Settings.apply_video()
		Settings.save_settings()
		return
	_resolution_before_apply = Settings.resolution_index
	Settings.resolution_index = _pending_resolution_index
	Settings.apply_video()
	_start_resolution_confirmation()


func _start_resolution_confirmation() -> void:
	_confirming = true
	_confirm_seconds_left = RESOLUTION_CONFIRM_TIMEOUT
	if _confirm_dialog == null:
		_confirm_dialog = ConfirmationDialog.new()
		_confirm_dialog.title = "Keep Display Settings?"
		_confirm_dialog.exclusive = true
		_confirm_dialog.get_ok_button().text = "Keep"
		_confirm_dialog.get_cancel_button().text = "Revert"
		_confirm_dialog.confirmed.connect(_on_confirm_keep)
		_confirm_dialog.canceled.connect(_on_confirm_revert)
		add_child(_confirm_dialog)
	if _confirm_timer == null:
		_confirm_timer = Timer.new()
		_confirm_timer.wait_time = 1.0
		_confirm_timer.one_shot = false
		_confirm_timer.timeout.connect(_on_confirm_tick)
		add_child(_confirm_timer)
	_update_confirm_text()
	_confirm_dialog.popup_centered()
	_confirm_dialog.get_ok_button().grab_focus()
	_confirm_timer.start()


func _update_confirm_text() -> void:
	var res := Settings.get_resolution(Settings.resolution_index)
	var unit := "second" if _confirm_seconds_left == 1 else "seconds"
	_confirm_dialog.dialog_text = (
		"Resolution set to %d x %d.\n\nKeep this setting?\n\nReverting in %d %s..."
		% [res.x, res.y, _confirm_seconds_left, unit]
	)


func _on_confirm_tick() -> void:
	_confirm_seconds_left -= 1
	if _confirm_seconds_left <= 0:
		_on_confirm_revert()
	else:
		_update_confirm_text()


func _on_confirm_keep() -> void:
	if not _confirming:
		return
	_confirming = false
	_close_confirmation()
	Settings.save_settings()
	_play_select()


func _on_confirm_revert() -> void:
	if not _confirming:
		return
	_confirming = false
	_close_confirmation()
	Settings.resolution_index = _resolution_before_apply
	Settings.apply_video()
	_pending_resolution_index = _resolution_before_apply
	resolution_option.selected = _resolution_before_apply
	Settings.save_settings()
	_play_back()


func _close_confirmation() -> void:
	if _confirm_timer:
		_confirm_timer.stop()
	if _confirm_dialog and _confirm_dialog.visible:
		_confirm_dialog.hide()


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
		btn.focus_entered.connect(_play_nav)
		btn.pressed.connect(_play_select)
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
			get_viewport().set_input_as_handled()
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
		_play_select()
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


func _on_back() -> void:
	_play_back()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
