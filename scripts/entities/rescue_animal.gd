extends Area2D
## A trapped animal the player rescues in the first half of a level. Touching it
## transforms Morphomon into the matching robotic form and grants its powers.

@export var form_id := "panther"
@export var animal_texture := "res://sprites/animals/panther.svg"

signal rescued(form_id: String)

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if sprite and ResourceLoader.exists(animal_texture):
		sprite.texture = load(animal_texture)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("transform_into"):
		body.transform_into(form_id)
		var mgr := get_tree().root.get_node_or_null("AudioManager")
		if mgr:
			mgr.play_sfx("rescue")
		rescued.emit(form_id)
		queue_free()
