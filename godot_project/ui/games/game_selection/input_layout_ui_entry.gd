class_name input_layout_ui_entry
extends HBoxContainer

@export var input_layout_packed_scene : PackedScene
@export var target_container : Control
@export var desc_label : Label

var input_layout_instance : input_layout

func set_data(data : collection_game_control):
	if input_layout_instance == null :
		input_layout_instance = (input_layout_packed_scene.instantiate() as input_layout)
	input_layout_instance.fit_to(target_container, data.inputs);
	desc_label.text = data.desc;
