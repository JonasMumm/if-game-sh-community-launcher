class_name settings_info_box
extends MarginContainer

@export var bg : ColorRect
@export var info_label : Label

func set_data(text : String, valid : bool):
	bg.color = Color.SEA_GREEN if valid else Color.RED;
	info_label.text = text
