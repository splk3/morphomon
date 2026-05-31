extends Area2D
## Player projectile: a homing missile (default form) or a straight laser
## (eagle form). Travels until it hits an enemy or times out.

const SPEED := 420.0
const LIFETIME := 3.0
const TURN_RATE := 4.0  # radians/sec for homing

var _velocity := Vector2.ZERO
var _homing := false
var _life := LIFETIME

@onready var sprite: Sprite2D = $Sprite2D


func setup(dir: float, homing: bool) -> void:
	_homing = homing
	_velocity = Vector2(dir * SPEED, 0.0)


func _ready() -> void:
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)
	if _homing and sprite:
		sprite.texture = load("res://sprites/items/missile.svg")
	elif sprite:
		sprite.texture = load("res://sprites/items/laser.svg")


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	if _homing:
		var target := _nearest_enemy()
		if target:
			var desired := (target.global_position - global_position).normalized() * SPEED
			_velocity = _velocity.lerp(desired, TURN_RATE * delta)
	global_position += _velocity * delta
	rotation = _velocity.angle()


func _nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var best := INF
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node2D:
			var d := global_position.distance_squared_to(enemy.global_position)
			if d < best:
				best = d
				nearest = enemy
	return nearest


func _on_hit(node: Node) -> void:
	if node.is_in_group("enemy"):
		if node.has_method("take_damage"):
			node.take_damage(2)
		queue_free()
	elif node.is_in_group("world"):
		queue_free()
