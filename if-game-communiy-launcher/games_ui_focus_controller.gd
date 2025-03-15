extends Node

@export var games_ui : games_ui_controller
@export var games_ui_state : ui_state_entry

func _enter_tree():
	games_ui_state.show_state_changed.connect(games_ui.grab_context_focus) 

func _exit_tree():
	games_ui_state.show_state_changed.disconnect(games_ui.grab_context_focus) 
