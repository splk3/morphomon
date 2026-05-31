extends SceneTree
## Headless scene-instantiation validator.
##
## `--headless --import --quit` does not surface all GDScript/runtime errors, so
## this script loads and instantiates every key scene (running their `_ready`
## procedural builders) to catch parse and runtime errors.
##
## Run from the repo root:
##   ./godot-executables/Godot_v4.5.2-stable_linux.x86_64 --headless -s res://tools/validate_scenes.gd

func _initialize() -> void:
	var ok := true
	var ui_scenes := [
		"res://scenes/main_menu.tscn",
		"res://scenes/ui/settings_menu.tscn",
		"res://scenes/ui/level_select.tscn",
		"res://scenes/ui/credits.tscn",
		"res://scenes/ui/hud.tscn",
		"res://scenes/ui/pause_menu.tscn",
		"res://scenes/player.tscn",
		"res://scenes/entities/enemy.tscn",
		"res://scenes/entities/rescue_animal.tscn",
		"res://scenes/entities/projectile.tscn",
	]
	for p in ui_scenes:
		if not _try(p):
			ok = false

	var gs := root.get_node_or_null("GameState")
	for id in ["cruise", "ice", "lava", "island", "jungle", "pirate"]:
		if gs:
			gs.pending_level_id = id
		if not _try("res://scenes/levels/base_level.tscn"):
			ok = false

	if not _try("res://scenes/levels/level_boss.tscn"):
		ok = false

	if ok:
		print("VALIDATE_OK")
	else:
		printerr("VALIDATE_FAIL")
	quit(0 if ok else 1)


func _try(path: String) -> bool:
	if not ResourceLoader.exists(path):
		printerr("MISSING: %s" % path)
		return false
	var ps := load(path)
	if ps == null:
		printerr("LOAD_FAILED: %s" % path)
		return false
	var inst = ps.instantiate()
	if inst == null:
		printerr("INSTANTIATE_FAILED: %s" % path)
		return false
	root.add_child(inst)
	inst.queue_free()
	return true
