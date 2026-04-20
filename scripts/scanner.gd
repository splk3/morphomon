extends RayCast2D
class_name Scanner

## Player-attached scanner that detects Scannable areas.

@onready var form_manager: FormManager = get_node("../FormManager")
@onready var beam: Line2D = $Beam

var current_target: Scannable = null

func _ready():
	if beam:
		beam.visible = false
	# Scannables should be on a specific collision layer (e.g., layer 2)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, true)
	collide_with_areas = true
	collide_with_bodies = false

func _physics_process(_delta):
	if Input.is_action_pressed("scan"):
		enabled = true
		if beam:
			beam.visible = true
			# Update beam end point based on collision or max range
			var end_point = target_position
			if is_colliding():
				end_point = to_local(get_collision_point())
			beam.points[1] = end_point
			# Energy flicker effect
			beam.width = randf_range(1.5, 3.5)
		_check_for_target()
	else:
		enabled = false
		if beam:
			beam.visible = false
		_clear_target()

func _check_for_target():
	if is_colliding():
		var collider = get_collider()
		if collider is Scannable:
			if current_target != collider:
				_clear_target()
				current_target = collider
				current_target.start_scanning()
				if not current_target.scan_completed.is_connected(_on_scan_completed):
					current_target.scan_completed.connect(_on_scan_completed)
	else:
		_clear_target()

func _clear_target():
	if current_target:
		current_target.stop_scanning()
		if current_target.scan_completed.is_connected(_on_scan_completed):
			current_target.scan_completed.disconnect(_on_scan_completed)
		current_target = null

func _on_scan_completed(form_name: String, script_path: String):
	if form_manager:
		form_manager.add_form(form_name, script_path)
