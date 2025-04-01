class_name game_ui_state_controller
extends Node

const running_state_delay := 2.5

@export var main_ui : main_state_manager
@export var launcher : cave_launcher
@export var games_ui : ui_state_entry
@export var launching_ui : ui_state_entry
@export var running_ui : ui_state_entry

var connection : butler_connection
var running_backoff_timer : Timer

func _ready():
	launcher.cave_launched_changed.connect(on_cave_launched_changed)
	launcher.cave_running_changed.connect(on_cave_running_changed)

func on_cave_launched_changed(is_launched: bool, cave : cave_info):
	if is_launched :
		main_ui.set_active_content(launching_ui)
		return
		
	if !is_launched:
		main_ui.set_active_content(games_ui)
		return

func on_cave_running_changed(is_running : bool):
	if running_backoff_timer:
		running_backoff_timer.stop()
		running_backoff_timer.queue_free()

	if is_running:
		running_backoff_timer = Timer.new()
		self.add_child(running_backoff_timer)
		running_backoff_timer.start(running_state_delay)
		await running_backoff_timer.timeout
		main_ui.set_active_content(running_ui)
