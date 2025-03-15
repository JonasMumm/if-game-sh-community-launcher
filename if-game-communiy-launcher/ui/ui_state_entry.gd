class_name ui_state_entry
extends Control

signal show_state_changed(shown:bool);

func hide_state():
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
	show_state_changed.emit(false)

func show_state(parent : Control):
	reparent(parent, false)
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	show_state_changed.emit(true)
