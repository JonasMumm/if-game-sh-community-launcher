class_name games_ui_controller
extends Control

@export var game_button_packed_scene:PackedScene
@export var game_buttons_container:Control
@export var launcher : cave_launcher
@export var connection : butler_connection

var _games : Array[game_data]

func set_data(games : Array[game_data]):
	_games = games
	
	var buttons : Array[game_button]
	
	for game in games:
		var button := game_button_packed_scene.instantiate() as game_button
		button._set_data(game)
		var cave := game.cave_info
		button.pressed.connect(launcher.launch_cave.bind(cave, connection))
		game_buttons_container.add_child(button)
		buttons.append(button)
	
	buttons[0].grab_focus()
