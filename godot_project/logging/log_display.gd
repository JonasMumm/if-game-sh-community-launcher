extends Control

@export var log_label:RichTextLabel;

func _process(delta):
	if !visible : return
	var str := LogManager.get_log_string()
	if str != log_label.text:
		log_label.text = str
