class_name game_ui_state_controller
extends Node

@export var main_ui : main_state_manager
@export var launcher : cave_launcher
@export var connection : butler_connection
@export var games_ui : ui_state_entry
@export var launching_ui : ui_state_entry
@export var running_ui : ui_state_entry

func _ready():
	launcher.cave_launched_changed.connect(on_cave_launched_changed)
	connection.subscribe_notification("LaunchRunning", on_notification_launch)
	
func on_cave_launched_changed(is_launched: bool, cave : cave_info):
	if is_launched :
		main_ui.set_active_content(launching_ui)
		return
		
	if !is_launched:
		main_ui.set_active_content(games_ui)
		return

func on_notification_launch(params : Dictionary):
	main_ui.set_active_content(running_ui)
