class_name main_state_manager
extends Control

@export var background : Control
@export var mouse_fun_controller : fun_mouse_cursor
var active : ui_state_entry

func _ready():
	for c in get_children():
		if c is ui_state_entry && c != active && c != background: c.hide_state()
		
	performance_control.set_performance_mode(true)

func set_active_content(content : ui_state_entry):
	if active : active.hide_state()
	active = content
	active.show_state(self)
	performance_control.set_performance_mode(content.high_performance_mode)
	mouse_fun_controller.process_mode =Node.PROCESS_MODE_INHERIT if content.cursor_fun else PROCESS_MODE_DISABLED
	mouse_fun_controller.visible = content.cursor_fun
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if content.cursor_fun else Input.MOUSE_MODE_VISIBLE
