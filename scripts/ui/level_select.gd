extends Control
## Mega Man-style stage select. Shows the five themed levels in a 3x3 grid with
## the final-boss stage locked in the center until every other level is cleared.
## Completed levels are marked; clearing the last one plays an unlock animation
## that reveals and auto-focuses the center boss stage.

const CELL_SIZE := Vector2(220, 150)
const PORTRAITS := {
	"ice": "res://sprites/animals/mammoth.svg",
	"lava": "res://sprites/animals/eagle.svg",
	"island": "res://sprites/forms/morphomon_idle.svg",
	"jungle": "res://sprites/animals/panther.svg",
	"pirate": "res://sprites/animals/monkey.svg",
	"boss": "res://sprites/boss/scientist_idle.svg",
}

var _cells: Dictionary = {}
var _boss_cell: Button


func _ready() -> void:
	_build_grid()
	$Footer/MenuButton.pressed.connect(_on_menu)
	AudioManager.play_music("menu_theme")
	_maybe_unlock_boss()


func _build_grid() -> void:
	var grid: GridContainer = $Center/Grid
	for child in grid.get_children():
		child.queue_free()
	# Map grid coordinates -> level for quick lookup.
	var by_pos := {}
	for level in GameState.LEVELS:
		if level.get("intro", false):
			continue
		by_pos[level.grid] = level

	for row in 3:
		for col in 3:
			var pos := Vector2i(col, row)
			if by_pos.has(pos):
				grid.add_child(_make_cell(by_pos[pos]))
			else:
				var spacer := Control.new()
				spacer.custom_minimum_size = CELL_SIZE
				grid.add_child(spacer)


func _make_cell(level: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = CELL_SIZE
	btn.add_theme_font_size_override("font_size", 18)
	btn.icon = load(PORTRAITS.get(level.id, PORTRAITS["island"]))
	btn.expand_icon = true
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP

	var is_boss: bool = level.get("final", false)
	var complete: bool = GameState.is_complete(level.id)
	var label := String(level.name)
	if complete:
		label = "✔ " + label + "\nCLEARED"
	if is_boss:
		_boss_cell = btn
		if not GameState.is_final_unlocked():
			btn.disabled = true
			btn.icon = null
			label = "???\nLOCKED"
	btn.text = label
	btn.pressed.connect(_on_level_pressed.bind(level.id))
	_cells[level.id] = btn
	return btn


func _maybe_unlock_boss() -> void:
	if _boss_cell == null:
		return
	if GameState.is_final_unlocked() and not GameState.is_complete("boss"):
		# Reveal the center stage with a celebratory pulse and focus it.
		AudioManager.play_sfx("rescue")
		var tween := create_tween()
		_boss_cell.pivot_offset = CELL_SIZE / 2.0
		_boss_cell.scale = Vector2(0.2, 0.2)
		tween.tween_property(_boss_cell, "scale", Vector2(1.15, 1.15), 0.5)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(_boss_cell, "scale", Vector2.ONE, 0.2)
		tween.tween_callback(_boss_cell.grab_focus)
	else:
		_focus_first_available()


func _focus_first_available() -> void:
	for level in GameState.LEVELS:
		if _cells.has(level.id) and not _cells[level.id].disabled:
			_cells[level.id].grab_focus()
			return


func _on_level_pressed(level_id: String) -> void:
	AudioManager.play_sfx("confirm")
	GameState.go_to_level(level_id)


func _on_menu() -> void:
	AudioManager.play_sfx("select")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
