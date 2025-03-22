class_name games_ui_controller
extends Control

@export var game_button_packed_scene:PackedScene
@export var game_buttons_container:Control
@export var launcher : cave_launcher
@export var launch_button : Button

@export var title_label : Label
@export var cover_texture_rect : TextureRect

var connection : butler_connection
var games : Array[game_data]
var buttons : Array[game_button]
var focused_button : game_button

func _ready():
	launch_button.pressed.connect(on_launch_button_pressed)

func set_data(connection : butler_connection, games : Array[game_data]):
	self.connection = connection
	self.games = games
	
	var buttons : Array[game_button]
	
	for game in games:
		var button := game_button_packed_scene.instantiate() as game_button
		button._set_data(game)
		var cave := game.cave_info
		button.button.pressed.connect(set_focused_button.bind(button))
		button.button.focus_entered.connect(set_focused_button.bind(button))
		game_buttons_container.add_child(button)
		buttons.append(button)
	
	set_focused_button(buttons[0])
	buttons[0].button.grab_focus()

func grab_context_focus(shown : bool):
	if shown: focused_button.button.grab_focus()
	
func set_focused_button(b : game_button):
	focused_button = b
	title_label.text = focused_button._game.collection_game.game.title
	cover_texture_rect.texture = focused_button._game.get_image()
	
func on_launch_button_pressed():
	launcher.launch_cave(focused_button._game.cave_info, connection)
	
