class_name pre_launch_hint
extends Control

@export var pre_launch_hint_type : String
@export var start_button : Button

func display():
	visible = true
	start_button.grab_focus()
	await start_button.pressed
	visible = false
