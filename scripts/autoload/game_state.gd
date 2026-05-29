extends Node
## Global game progression state (autoload singleton "GameState").
##
## Tracks which levels are complete, which transformation forms the player has
## unlocked, and the player's currently selected form. Persists to
## `user://savegame.cfg` so progress survives between runs.

const SAVE_PATH := "user://savegame.cfg"

## Canonical form identifiers. "default" is Morphomon's base treaded robot form.
const FORM_DEFAULT := "default"
const FORM_PANTHER := "panther"
const FORM_MAMMOTH := "mammoth"
const FORM_EAGLE := "eagle"
const FORM_MONKEY := "monkey"

## Ordered metadata describing every selectable level. The intro cruise level is
## played first; the five themed levels appear on the Mega Man-style select
## grid; the final boss occupies the locked center slot.
const LEVELS := [
	{
		"id": "cruise", "name": "Cruise Ship", "theme": "cruise", "intro": true,
		"scene": "res://scenes/levels/base_level.tscn", "music": "cruise_theme",
		"form": FORM_DEFAULT, "grid": Vector2i(-1, -1),
	},
	{
		"id": "ice", "name": "Frostbite Peaks", "theme": "ice", "intro": false,
		"scene": "res://scenes/levels/base_level.tscn", "music": "ice_theme",
		"form": FORM_MAMMOTH, "animal": "mammoth", "grid": Vector2i(0, 0),
	},
	{
		"id": "lava", "name": "Magma Core", "theme": "lava", "intro": false,
		"scene": "res://scenes/levels/base_level.tscn", "music": "lava_theme",
		"form": FORM_EAGLE, "animal": "eagle", "grid": Vector2i(2, 0),
	},
	{
		"id": "island", "name": "Castaway Cove", "theme": "island", "intro": false,
		"scene": "res://scenes/levels/base_level.tscn", "music": "island_theme",
		"form": FORM_DEFAULT, "animal": "", "grid": Vector2i(0, 2),
	},
	{
		"id": "jungle", "name": "Tangle Jungle", "theme": "jungle", "intro": false,
		"scene": "res://scenes/levels/base_level.tscn", "music": "jungle_theme",
		"form": FORM_PANTHER, "animal": "panther", "grid": Vector2i(2, 2),
	},
	{
		"id": "pirate", "name": "Dead Tide Galleon", "theme": "pirate", "intro": false,
		"scene": "res://scenes/levels/base_level.tscn", "music": "pirate_theme",
		"form": FORM_MONKEY, "animal": "monkey", "grid": Vector2i(1, 0),
	},
	{
		"id": "boss", "name": "Dr. Morphous", "theme": "boss", "intro": false,
		"scene": "res://scenes/levels/level_boss.tscn", "music": "boss_theme",
		"form": FORM_DEFAULT, "grid": Vector2i(1, 1), "final": true,
	},
]

## The five themed levels that must be cleared before the boss unlocks.
const MAIN_LEVEL_IDS := ["ice", "lava", "island", "jungle", "pirate"]

var completed: Dictionary = {}
var unlocked_forms: Array = [FORM_DEFAULT]
var current_form: String = FORM_DEFAULT

## The level a scene transition is heading toward; read by the shared base level
## scene so a single scene file can render every theme.
var pending_level_id: String = ""


func _ready() -> void:
	load_game()


## Begin a level by id, remembering which level the shared base scene should
## build before performing the scene change.
func go_to_level(level_id: String) -> void:
	var level := get_level(level_id)
	if level.is_empty():
		push_error("Unknown level id: %s" % level_id)
		return
	pending_level_id = level_id
	var err := get_tree().change_scene_to_file(String(level.scene))
	if err != OK:
		push_error("Failed to load level scene '%s': %s" % [level.scene, err])


func get_level(level_id: String) -> Dictionary:
	for level in LEVELS:
		if level.id == level_id:
			return level
	return {}


func is_complete(level_id: String) -> bool:
	return completed.get(level_id, false)


func mark_complete(level_id: String) -> void:
	completed[level_id] = true
	var level := get_level(level_id)
	var form := String(level.get("form", ""))
	if form != "" and not unlocked_forms.has(form):
		unlocked_forms.append(form)
	save_game()


func all_main_complete() -> bool:
	for level_id in MAIN_LEVEL_IDS:
		if not is_complete(level_id):
			return false
	return true


## The boss is unlocked once every main level and the intro are complete.
func is_final_unlocked() -> bool:
	return is_complete("cruise") and all_main_complete()


func unlock_form(form: String) -> void:
	if not unlocked_forms.has(form):
		unlocked_forms.append(form)
		save_game()


func has_form(form: String) -> bool:
	return unlocked_forms.has(form)


func reset_progress() -> void:
	completed.clear()
	unlocked_forms = [FORM_DEFAULT]
	current_form = FORM_DEFAULT
	save_game()


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "completed", completed)
	cfg.set_value("progress", "unlocked_forms", unlocked_forms)
	cfg.set_value("progress", "current_form", current_form)
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	completed = cfg.get_value("progress", "completed", {})
	unlocked_forms = cfg.get_value("progress", "unlocked_forms", [FORM_DEFAULT])
	current_form = cfg.get_value("progress", "current_form", FORM_DEFAULT)
