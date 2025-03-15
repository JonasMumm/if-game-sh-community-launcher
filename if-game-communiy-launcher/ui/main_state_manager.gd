class_name main_state_manager
extends Control

@export var background : Control
var active : ui_state_entry

func _ready():
	for c in get_children():
		if c is ui_state_entry && c != active && c != background: c.hide_state()

func set_active_content(content : ui_state_entry):
	if active : active.hide_state()
	active = content
	active.show_state(self)
