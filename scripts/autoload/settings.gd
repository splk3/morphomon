extends Node
## Persistent user settings (autoload singleton "Settings").
##
## Manages graphics (resolution, fullscreen), audio (master/music/SFX volume),
## and rebindable controls (keyboard + gamepad). Values persist to
## `user://settings.cfg` and are applied on boot.

const SAVE_PATH := "user://settings.cfg"

## Selectable windowed resolutions.
const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

## Actions the player may remap. Each may hold a keyboard and a gamepad binding.
const REBINDABLE_ACTIONS := [
	"move_left", "move_right", "move_up", "move_down",
	"jump", "attack", "ability", "cycle_form", "pause",
]

var resolution_index := 0
var fullscreen := false
var master_volume := 1.0
var music_volume := 0.8
var sfx_volume := 0.9

## Default bindings captured from project.godot at first launch so "reset to
## defaults" can restore them.
var _default_events: Dictionary = {}


func _ready() -> void:
	_capture_defaults()
	load_settings()
	apply_all()


func _capture_defaults() -> void:
	for action in REBINDABLE_ACTIONS:
		if InputMap.has_action(action):
			_default_events[action] = InputMap.action_get_events(action).duplicate()


func apply_all() -> void:
	apply_video()
	apply_audio()


# --- Video --------------------------------------------------------------
func apply_video() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var res: Vector2i = RESOLUTIONS[clampi(resolution_index, 0, RESOLUTIONS.size() - 1)]
		DisplayServer.window_set_size(res)
		_center_window(res)


func _center_window(res: Vector2i) -> void:
	var screen := DisplayServer.screen_get_size()
	DisplayServer.window_set_position((screen - res) / 2)


# --- Audio --------------------------------------------------------------
func apply_audio() -> void:
	_set_bus("Master", master_volume)
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)


func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0, 1.0)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)


# --- Controls -----------------------------------------------------------
## Replace the keyboard or gamepad binding for an action with the given event,
## preserving the binding for the other device class.
func rebind_action(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		return
	var keep_joypad := event is InputEventKey
	for existing in InputMap.action_get_events(action):
		var existing_is_key := existing is InputEventKey
		# Remove the binding of the same device class we are replacing.
		if existing_is_key != keep_joypad:
			InputMap.action_erase_event(action, existing)
	InputMap.action_add_event(action, event)


func reset_controls() -> void:
	for action in REBINDABLE_ACTIONS:
		if not _default_events.has(action):
			continue
		InputMap.action_erase_events(action)
		for event in _default_events[action]:
			InputMap.action_add_event(action, event)


func get_binding_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "-"
	var key_text := ""
	var pad_text := ""
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			key_text = event.as_text_physical_keycode()
		elif event is InputEventJoypadButton:
			pad_text = "Pad %d" % event.button_index
		elif event is InputEventJoypadMotion:
			pad_text = "Axis %d" % event.axis
	var parts := []
	if key_text != "":
		parts.append(key_text)
	if pad_text != "":
		parts.append(pad_text)
	return " / ".join(parts) if parts.size() > 0 else "-"


# --- Persistence --------------------------------------------------------
func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "resolution_index", resolution_index)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	for action in REBINDABLE_ACTIONS:
		cfg.set_value("controls", action, _serialize_events(action))
	cfg.save(SAVE_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	resolution_index = cfg.get_value("video", "resolution_index", resolution_index)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	master_volume = cfg.get_value("audio", "master", master_volume)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	for action in REBINDABLE_ACTIONS:
		var data: Array = cfg.get_value("controls", action, [])
		if data.is_empty() or not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		for entry in data:
			var event := _deserialize_event(entry)
			if event:
				InputMap.action_add_event(action, event)


func _serialize_events(action: String) -> Array:
	var result := []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			result.append({"t": "key", "code": event.physical_keycode})
		elif event is InputEventJoypadButton:
			result.append({"t": "btn", "idx": event.button_index})
		elif event is InputEventJoypadMotion:
			result.append({"t": "axis", "axis": event.axis, "value": event.axis_value})
	return result


func _deserialize_event(entry: Dictionary) -> InputEvent:
	match entry.get("t", ""):
		"key":
			var k := InputEventKey.new()
			k.physical_keycode = entry.get("code", 0)
			return k
		"btn":
			var b := InputEventJoypadButton.new()
			b.button_index = entry.get("idx", 0)
			return b
		"axis":
			var a := InputEventJoypadMotion.new()
			a.axis = entry.get("axis", 0)
			a.axis_value = entry.get("value", 1.0)
			return a
	return null
