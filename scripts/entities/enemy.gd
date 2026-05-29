extends CharacterBody2D
## Simple patrolling enemy. Walks back and forth, damages the player on contact,
## and can be destroyed by player projectiles or melee hits.

@export var patrol_distance := 96.0
@export var move_speed := 60.0
@export var health := 2
@export var contact_damage := 1
@export var texture_path := "res://sprites/enemies/drone.svg"
@export var death_sfx := "explosion"

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _origin_x := 0.0
var _dir := 1.0

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")


func _ready() -> void:
	add_to_group("enemy")
	_origin_x = global_position.x
	if sprite and ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	if absf(global_position.x - _origin_x) > patrol_distance:
		_dir = signf(_origin_x - global_position.x)
	velocity.x = _dir * move_speed
	if sprite:
		sprite.flip_h = _dir < 0
	move_and_slide()

	_check_melee_and_player()


func _check_melee_and_player() -> void:
	# Take damage from active player melee hitboxes.
	for area in get_tree().get_nodes_in_group("player_attack"):
		if area is Node2D and global_position.distance_to(area.global_position) < 36.0:
			take_damage(int(area.get_meta("damage", 1)))
			return
	# Deal contact damage to the player when overlapping.
	for player in get_tree().get_nodes_in_group("player"):
		if player is Node2D and player.has_method("take_damage"):
			if global_position.distance_to(player.global_position) < 30.0:
				player.take_damage(contact_damage)


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		var mgr := get_tree().root.get_node_or_null("AudioManager")
		if mgr:
			mgr.play_sfx(death_sfx)
		queue_free()
