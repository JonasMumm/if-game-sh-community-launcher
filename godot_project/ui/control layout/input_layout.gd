class_name input_layout
extends Control

var x_min : float
var x_max : float
var y_min : float
var y_max : float
var registered_parent : Control

func fit_to(target_parent : Control, inputs : Array[String]):
	x_min = 999999.0;
	x_max = -999999.0;
	y_min = 999999.0;
	y_max = -999999.0;
	
	for child in get_children():
		var child_control := child as Control
		
		if child_control == null:
			continue;
		
		var shall_show := inputs.find(child.name) != -1;
		
		if !shall_show:
			var input_layout_entry_instance := child_control as input_layout_entry;
			if input_layout_entry_instance != null:
				for tag in input_layout_entry_instance.active_for_tags:
					if inputs.find(tag) != -1:
						shall_show = true
						break;
		
		if shall_show:
			var _pos := child_control.position;
			var _size := child_control.size;
			var _scale := child_control.scale;
			x_min = minf(x_min, _pos.x)
			x_max = maxf(x_max, _pos.x + _size.x * _scale.x)
			y_min = minf(y_min, _pos.y)
			y_max = maxf(y_max, _pos.y + _size.y * _scale.y)
			child_control.visible = true;
		else:
			child_control.visible = false;
	
	if registered_parent != null:
		registered_parent.resized.disconnect(on_parent_size_changed);

	registered_parent = target_parent;
	target_parent.add_child(self)
	target_parent.resized.connect(on_parent_size_changed);
	on_parent_size_changed();
	
func on_parent_size_changed():
	var available_size := registered_parent.size;
	
	if available_size == Vector2.ZERO: return
	
	var base_size := Vector2(x_max - x_min, y_max-y_min);
	var target_scale := minf(available_size.x/base_size.x,available_size.y/base_size.y);
	scale = Vector2(target_scale, target_scale);
	position = Vector2(-x_min * target_scale, -y_min * target_scale);
