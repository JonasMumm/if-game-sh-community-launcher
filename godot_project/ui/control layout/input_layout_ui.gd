class_name input_layout_ui
extends VBoxContainer

@export var input_layout_ui_entry_packed_scene : PackedScene

var entry_pool : Array[input_layout_ui_entry];
	
func set_data(data : Array[collection_game_control]):
	visible = data.size() > 0;
	
	if !visible: return;
	
	for i in range(data.size(), entry_pool.size()):
		entry_pool[i].visible = false;
	
	for i in range(entry_pool.size(), data.size()):
		var new_entry:= (input_layout_ui_entry_packed_scene.instantiate() as input_layout_ui_entry)
		self.add_child(new_entry)
		entry_pool.append(new_entry)
		
	for i in range(0, data.size()):
		entry_pool[i].set_data(data[i])
		entry_pool[i].visible = true;
