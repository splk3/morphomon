extends Node
class_name FormManager

## Manages switching between different player forms.

@export var initial_form_path: NodePath

var current_form: BaseForm
var player: CharacterBody2D

func _ready():
	player = get_parent()
	
	# Wait a frame to ensure all children are ready
	await get_tree().process_frame
	
	if initial_form_path:
		var initial_form = get_node(initial_form_path)
		if initial_form is BaseForm:
			switch_form(initial_form)

func switch_form(new_form: BaseForm):
	if current_form:
		current_form.exit()
	
	current_form = new_form
	current_form.player = player
	current_form.enter()
	form_changed.emit(current_form.name)
	print("Switched to form: ", current_form.name)

func add_form(form_name: String, script_path: String):
	# Check if form already exists
	if has_node(form_name):
		return
		
	var new_node = Node.new()
	new_node.name = form_name
	new_node.set_script(load(script_path))
	add_child(new_node)
	form_unlocked.emit(form_name)
	print("Registered new form: ", form_name)

func switch_to_next_form():
	var forms = get_children()
	if forms.size() <= 1:
		return
		
	var current_index = forms.find(current_form)
	var next_index = (current_index + 1) % forms.size()
	switch_form(forms[next_index])

func process_physics(delta: float):
	if current_form:
		current_form.handle_physics(delta)

func process_animations():
	if current_form:
		current_form.update_animations()
ons()
