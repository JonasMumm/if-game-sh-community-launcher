@tool

class_name RadialContainer
extends Container

@export_group("Radial Positioning")
@export var center := Vector2.ZERO;
@export var radius := 500.0;
@export var angle_between_items := 15.0;

@export_group("Scaling")
@export var scale_minimum := 0.5;
@export var scale_minimum_index := 3;

@export var items_rotation := 0.0:
	set(value):
		items_rotation = value;
		queue_sort()

@export_group("Selection")
@export var scroll_speed := 5.0;
var _index_selected := 0;

func _get_child_controls() -> Array[Control]:
	var children := get_children();
	var controls_candidates := children.filter(func (node): return node is Control);
	var controls : Array[Control];
	for control in controls_candidates:
		controls.append(control as Control);
	
	return controls;
			
func get_angle_of_child(index : int) -> float:
	return angle_between_items * index;

	
# container implementation
func _notification(what):	
	if what == NOTIFICATION_SORT_CHILDREN:
		var controls := _get_child_controls();
		var control_center := size / 2.0;
				
		var index := 0;
		for control in controls:
			if control == null: continue;
			
			var relative_index := index - _index_selected;
			var index_offset : int = abs(relative_index);
			var angle := get_angle_of_child(index) + items_rotation;
			var offset := radius * Vector2.UP.rotated(deg_to_rad(angle));
			control.position = control_center + center + offset - control.size / 2.0;
			control.z_index = -index_offset;
			if index_offset == 0:
				control.z_index += 15;
			control.scale = Vector2.ONE * lerp(1.0, scale_minimum, float(index_offset)/scale_minimum_index);
			index = index + 1;
	
func _physics_process(delta: float) -> void:
	var target_rotation := -get_angle_of_child(_index_selected);
	
	var difference := target_rotation - items_rotation;
	var new_rotation := items_rotation + difference * scroll_speed * delta;
	
	items_rotation = new_rotation;
	
	
func on_selection_changed(button: game_button) -> void:
	var index_of_button := _get_child_controls().find(button);
	_index_selected = index_of_button;
	queue_sort();
