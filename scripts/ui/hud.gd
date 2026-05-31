extends CanvasLayer
## In-level heads-up display: shows the level name, the current transformation
## form, and the player's remaining health. Updates reactively via player signals.

@onready var level_label: Label = $Root/TopBar/LevelLabel
@onready var form_label: Label = $Root/TopBar/FormLabel
@onready var health_label: Label = $Root/TopBar/HealthLabel

var _player: Node


func bind_player(player: Node, level_name: String) -> void:
	_player = player
	if level_label:
		level_label.text = level_name
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_health_changed)
	if player.has_signal("form_changed"):
		player.form_changed.connect(_on_form_changed)
	# Initialise from current state.
	_on_health_changed(player.health, player.max_health)
	_on_form_changed(player.form_id)


func _on_health_changed(current: int, maximum: int) -> void:
	if health_label:
		health_label.text = "HP %s" % "♥".repeat(max(current, 0)) + "·".repeat(max(maximum - current, 0))


func _on_form_changed(form_id: String) -> void:
	if form_label:
		form_label.text = "FORM: %s" % MorphForms.get_form(form_id).name.to_upper()
