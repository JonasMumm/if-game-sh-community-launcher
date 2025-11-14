class_name game_settings
extends Node

const post_launch_backoff_seconds := 3

signal launch_continue;

@export var info_box : settings_info_box
@export var launch_all_button : Button
@export var cave_launcher : cave_launcher
@export var button_container : Control
@export var menu_container : Control

var connection : butler_connection
var save : save_data
var buttons : Array[Button]

func _ready():
	launch_all_button.pressed.connect(launch_all_installed_caves)

func init_ui(save : save_data, connection : butler_connection):
	self.connection = connection
	self.save = save
	
	for b in buttons:
		b.queue_free()
	buttons.clear()
	
	info_box.set_data("Waiting for Butler to get ready...", false)
	await connection.wait_for_connection()
	
	var rq_caves := await connection.send_request("Fetch.Caves",{limit = 100});
	var caves = rq_caves.result.items;
	
	for v in caves:
		var game = v.game
		var btn := Button.new()
		btn.text = "Uninstall "+game.title;
		btn.pressed.connect(on_uninstall_pressed.bind(v))
		button_container.add_child(btn)
		buttons.append(btn)
		
	info_box.set_data("Butler ready!...", true)

func on_uninstall_pressed(cave):
	await connection.send_request("Uninstall.Perform",{caveId = cave.id})
	init_ui(save, connection)
	
func launch_all_installed_caves():
	menu_container.visible = false
	var rq_caves := await connection.send_request("Fetch.Caves",{limit = 100});
	var caves = rq_caves.result.items;
	
	for v in caves:
		var ci := cave_info.new(v)
		cave_launcher.cave_running_changed.connect(on_cave_running_changed)
		cave_launcher.launch_cave(ci, connection, "");
		await launch_continue
		await get_tree().create_timer(post_launch_backoff_seconds).timeout
		cave_launcher.quit_hard()
		cave_launcher.cave_running_changed.disconnect(on_cave_running_changed)
		await get_tree().create_timer(post_launch_backoff_seconds).timeout
	menu_container.visible = true

func on_cave_running_changed(running : bool):
	launch_continue.emit()
