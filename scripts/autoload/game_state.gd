extends Node
## Global game progression state (autoload singleton "GameState").
##
## Tracks which levels are complete, which transformation forms the player has
## unlocked, and the player's currently selected form. Persists to
## `user://savegame.cfg` so progress survives between runs.

const SAVE_PATH := "user://savegame.cfg"
const SLOT_COUNT := 3
const UNSAVED_SLOT_ID := -1
const META_SECTION := "meta"
const META_ACTIVE_SLOT_KEY := "active_slot"
const SLOT_SECTION_PREFIX := "slot_"
const LEGACY_PROGRESS_SECTION := "progress"

## Canonical form identifiers. "default" is Morphomon's base treaded robot form.
const FORM_DEFAULT := "default"
const FORM_PANTHER := "panther"
const FORM_MAMMOTH := "mammoth"
const FORM_EAGLE := "eagle"
const FORM_MONKEY := "monkey"
const FORM_SWORDFISH := "swordfish"
const FORM_ALIEN := "alien"
const FORM_STUFFED_BEAR := "stuffed_bear"

## Ordered metadata describing every selectable level. The intro cruise level is
## played first; the eight themed levels appear on the Mega Man-style select
## grid around the locked center boss slot.
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
		"id": "ocean_floor", "name": "Abyssal Trench", "theme": "ocean_floor", "intro": false,
		"scene": "res://scenes/levels/base_level.tscn", "music": "ocean_floor_theme",
		"form": FORM_SWORDFISH, "animal": "swordfish", "grid": Vector2i(0, 1),
	},
	{
		"id": "space", "name": "Orbit Breaker", "theme": "space", "intro": false,
		"scene": "res://scenes/levels/base_level.tscn", "music": "space_theme",
		"form": FORM_ALIEN, "animal": "alien", "grid": Vector2i(2, 1),
	},
	{
		"id": "factory", "name": "Cogwork Foundry", "theme": "factory", "intro": false,
		"scene": "res://scenes/levels/base_level.tscn", "music": "factory_theme",
		"form": FORM_STUFFED_BEAR, "animal": "stuffed_bear", "grid": Vector2i(1, 2),
	},
	{
		"id": "boss", "name": "Dr. Morphous", "theme": "boss", "intro": false,
		"scene": "res://scenes/levels/boss_intro.tscn", "music": "boss_theme",
		"form": FORM_DEFAULT, "grid": Vector2i(1, 1), "final": true,
	},
]

## Every non-intro, non-boss stage that must be cleared before the boss unlocks.
const MAIN_LEVEL_IDS := [
	"ice", "lava", "island", "jungle", "pirate", "ocean_floor", "space", "factory",
]

var completed: Dictionary = {}
var unlocked_forms: Array = [FORM_DEFAULT]
var current_form: String = FORM_DEFAULT
var active_slot_id: int = UNSAVED_SLOT_ID
var save_enabled := false

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
	_apply_progress_data(_default_progress_data())
	save_game()


func save_game() -> void:
	if not save_enabled:
		return
	if not _is_valid_slot_id(active_slot_id):
		push_error("Cannot save game without an active slot.")
		return
	var cfg := ConfigFile.new()
	var load_err := cfg.load(SAVE_PATH)
	if load_err != OK and load_err != ERR_FILE_NOT_FOUND:
		push_error("Failed to read save file '%s': %s" % [SAVE_PATH, load_err])
		return
	cfg.set_value(META_SECTION, META_ACTIVE_SLOT_KEY, active_slot_id)
	_write_slot_data(cfg, active_slot_id, _session_progress_data())
	var save_err := cfg.save(SAVE_PATH)
	if save_err != OK:
		push_error("Failed to write save file '%s': %s" % [SAVE_PATH, save_err])


func load_game() -> void:
	var cfg := ConfigFile.new()
	var load_err := cfg.load(SAVE_PATH)
	if load_err == ERR_FILE_NOT_FOUND:
		start_unsaved_session()
		return
	if load_err != OK:
		push_error("Failed to read save file '%s': %s" % [SAVE_PATH, load_err])
		start_unsaved_session()
		return
	_migrate_legacy_save_if_needed(cfg)
	var configured_active_slot := int(cfg.get_value(META_SECTION, META_ACTIVE_SLOT_KEY, UNSAVED_SLOT_ID))
	if can_load_slot(configured_active_slot):
		_load_slot_data_into_session(cfg, configured_active_slot)
		return
	for slot_id in SLOT_COUNT:
		if can_load_slot(slot_id):
			_load_slot_data_into_session(cfg, slot_id)
			return
	start_unsaved_session()


func get_slot_summaries() -> Array:
	var cfg := ConfigFile.new()
	var load_err := cfg.load(SAVE_PATH)
	if load_err != OK and load_err != ERR_FILE_NOT_FOUND:
		push_error("Failed to read save file '%s': %s" % [SAVE_PATH, load_err])
	var summaries: Array = []
	for slot_id in SLOT_COUNT:
		var summary := {
			"slot_id": slot_id,
			"active": slot_id == active_slot_id and save_enabled,
			"occupied": _slot_has_progress(cfg, slot_id),
			"main_complete": 0,
			"total_complete": 0,
			"boss_complete": false,
			"current_form": FORM_DEFAULT,
			"updated_at": 0,
		}
		if summary.occupied:
			var data := _read_slot_data(cfg, slot_id)
			var slot_completed: Dictionary = data.completed
			summary.main_complete = _count_main_complete(slot_completed)
			summary.total_complete = slot_completed.size()
			summary.boss_complete = bool(slot_completed.get("boss", false))
			summary.current_form = String(data.current_form)
			summary.updated_at = int(data.updated_at)
		summaries.append(summary)
	return summaries


func can_load_slot(slot_id: int) -> bool:
	if not _is_valid_slot_id(slot_id):
		return false
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	return _slot_has_progress(cfg, slot_id)


func start_new_game_in_slot(slot_id: int) -> bool:
	if not _is_valid_slot_id(slot_id):
		push_error("Invalid save slot id: %s" % slot_id)
		return false
	active_slot_id = slot_id
	save_enabled = true
	_apply_progress_data(_default_progress_data())
	save_game()
	return true


func load_game_from_slot(slot_id: int) -> bool:
	if not _is_valid_slot_id(slot_id):
		push_error("Invalid save slot id: %s" % slot_id)
		return false
	var cfg := ConfigFile.new()
	var load_err := cfg.load(SAVE_PATH)
	if load_err != OK:
		push_error("Failed to read save file '%s': %s" % [SAVE_PATH, load_err])
		return false
	if not _slot_has_progress(cfg, slot_id):
		push_error("Save slot %s is empty." % slot_id)
		return false
	_load_slot_data_into_session(cfg, slot_id)
	save_game()
	return true


func clear_slot(slot_id: int) -> bool:
	if not _is_valid_slot_id(slot_id):
		push_error("Invalid save slot id: %s" % slot_id)
		return false
	var cfg := ConfigFile.new()
	var load_err := cfg.load(SAVE_PATH)
	if load_err != OK and load_err != ERR_FILE_NOT_FOUND:
		push_error("Failed to read save file '%s': %s" % [SAVE_PATH, load_err])
		return false
	var section := _slot_section(slot_id)
	for key in ["completed", "unlocked_forms", "current_form", "updated_at"]:
		cfg.erase_section_key(section, key)
	var meta_active_slot := int(cfg.get_value(META_SECTION, META_ACTIVE_SLOT_KEY, UNSAVED_SLOT_ID))
	if meta_active_slot == slot_id:
		cfg.set_value(META_SECTION, META_ACTIVE_SLOT_KEY, UNSAVED_SLOT_ID)
	var save_err := cfg.save(SAVE_PATH)
	if save_err != OK:
		push_error("Failed to write save file '%s': %s" % [SAVE_PATH, save_err])
		return false
	if active_slot_id == slot_id:
		start_unsaved_session()
	return true


func start_unsaved_session() -> void:
	active_slot_id = UNSAVED_SLOT_ID
	save_enabled = false
	_apply_progress_data(_default_progress_data())


func _load_slot_data_into_session(cfg: ConfigFile, slot_id: int) -> void:
	var data := _read_slot_data(cfg, slot_id)
	active_slot_id = slot_id
	save_enabled = true
	_apply_progress_data(data)


func _read_slot_data(cfg: ConfigFile, slot_id: int) -> Dictionary:
	var section := _slot_section(slot_id)
	return {
		"completed": cfg.get_value(section, "completed", {}),
		"unlocked_forms": cfg.get_value(section, "unlocked_forms", [FORM_DEFAULT]),
		"current_form": cfg.get_value(section, "current_form", FORM_DEFAULT),
		"updated_at": int(cfg.get_value(section, "updated_at", 0)),
	}


func _write_slot_data(cfg: ConfigFile, slot_id: int, data: Dictionary) -> void:
	var section := _slot_section(slot_id)
	cfg.set_value(section, "completed", data.completed)
	cfg.set_value(section, "unlocked_forms", data.unlocked_forms)
	cfg.set_value(section, "current_form", data.current_form)
	cfg.set_value(section, "updated_at", int(Time.get_unix_time_from_system()))


func _session_progress_data() -> Dictionary:
	return {
		"completed": completed.duplicate(true),
		"unlocked_forms": unlocked_forms.duplicate(true),
		"current_form": current_form,
	}


func _default_progress_data() -> Dictionary:
	return {
		"completed": {},
		"unlocked_forms": [FORM_DEFAULT],
		"current_form": FORM_DEFAULT,
	}


func _apply_progress_data(data: Dictionary) -> void:
	completed = _sanitize_completed(data.get("completed", {}))
	unlocked_forms = _sanitize_forms(data.get("unlocked_forms", [FORM_DEFAULT]))
	current_form = _sanitize_current_form(data.get("current_form", FORM_DEFAULT), unlocked_forms)


func _sanitize_completed(value: Variant) -> Dictionary:
	var source: Dictionary = value if value is Dictionary else {}
	var result: Dictionary = {}
	for key in source.keys():
		result[String(key)] = bool(source[key])
	return result


func _sanitize_forms(value: Variant) -> Array:
	var source: Array = value if value is Array else []
	var forms: Array = []
	for form_value in source:
		var form_id := String(form_value)
		if form_id != "" and not forms.has(form_id):
			forms.append(form_id)
	if not forms.has(FORM_DEFAULT):
		forms.insert(0, FORM_DEFAULT)
	return forms


func _sanitize_current_form(value: Variant, forms: Array) -> String:
	var form_id := String(value)
	if form_id == "" or not forms.has(form_id):
		return FORM_DEFAULT
	return form_id


func _is_valid_slot_id(slot_id: int) -> bool:
	return slot_id >= 0 and slot_id < SLOT_COUNT


func _slot_section(slot_id: int) -> String:
	return "%s%s" % [SLOT_SECTION_PREFIX, slot_id]


func _slot_has_progress(cfg: ConfigFile, slot_id: int) -> bool:
	if not _is_valid_slot_id(slot_id):
		return false
	var section := _slot_section(slot_id)
	return cfg.has_section_key(section, "completed")


func _count_main_complete(slot_completed: Dictionary) -> int:
	var count := 0
	for level_id in MAIN_LEVEL_IDS:
		if bool(slot_completed.get(level_id, false)):
			count += 1
	return count


func _migrate_legacy_save_if_needed(cfg: ConfigFile) -> void:
	if not cfg.has_section_key(LEGACY_PROGRESS_SECTION, "completed"):
		return
	if _slot_has_progress(cfg, 0):
		return
	var migrated := {
		"completed": cfg.get_value(LEGACY_PROGRESS_SECTION, "completed", {}),
		"unlocked_forms": cfg.get_value(LEGACY_PROGRESS_SECTION, "unlocked_forms", [FORM_DEFAULT]),
		"current_form": cfg.get_value(LEGACY_PROGRESS_SECTION, "current_form", FORM_DEFAULT),
	}
	_write_slot_data(cfg, 0, migrated)
	cfg.erase_section(LEGACY_PROGRESS_SECTION)
	cfg.set_value(META_SECTION, META_ACTIVE_SLOT_KEY, 0)
	var save_err := cfg.save(SAVE_PATH)
	if save_err != OK:
		push_error("Failed to migrate legacy save file '%s': %s" % [SAVE_PATH, save_err])
