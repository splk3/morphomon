extends Area2D
class_name Scannable

## Component attached to creatures that can be scanned to unlock new forms.

@export var form_name: String = "Frog"
@export var form_script_path: String = "res://scripts/frog_form.gd"
@export var scan_time_required: float = 1.5

var current_scan_time: float = 0.0
var is_being_scanned: bool = false

signal scan_completed(form_name: String, script_path: String)
signal scan_progressed(progress: float)

@onready var progress_bar: ProgressBar = $ProgressBar

func _ready():
	if progress_bar:
		progress_bar.visible = false
		progress_bar.max_value = 1.0

func _process(delta):
	if is_being_scanned:
		current_scan_time += delta
		var progress = current_scan_time / scan_time_required
		if progress_bar:
			progress_bar.visible = true
			progress_bar.value = progress
		scan_progressed.emit(progress)
		
		if current_scan_time >= scan_time_required:
			complete_scan()
	else:
		# Reset progress if scan is interrupted
		current_scan_time = move_toward(current_scan_time, 0, delta * 2)
		if progress_bar:
			progress_bar.value = current_scan_time / scan_time_required
			if current_scan_time <= 0:
				progress_bar.visible = false

func start_scanning():
	is_being_scanned = true

func stop_scanning():
	is_being_scanned = false

func complete_scan():
	is_being_scanned = false
	current_scan_time = 0.0
	scan_completed.emit(form_name, form_script_path)
	print("Scan complete! Unlocked: ", form_name)
