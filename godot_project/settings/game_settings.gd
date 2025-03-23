class_name game_settings
extends Node

@export var info_box : settings_info_box
@export var button_container : Control

var connection : butler_connection
var save : save_data
var buttons : Array[Button]

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
