class_name game_button
extends MarginContainer

const launch_click_threshold_usec := 80000 #0.08 seconds

signal launch_pressed

@export var button: Button
@export var game_name_label : Label
@export var genre_label : Label
@export var player_count_label : Label
@export var session_duration_label : Label
@export var cover : TextureRect

var _game : game_data
var focus_usec := 0
var down_usec := 0

func _ready():
	button.button_down.connect(on_button_down)
	button.focus_entered.connect(on_focus_entered)
	button.pressed.connect(on_pressed)

func _set_data(game : game_data):
	_game = game
	game_name_label.text = str(game.collection_game.game.title)
	genre_label.text = str(game.collection_entry.details.genre)
	
	var details := game.collection_entry.details
	
	if details.players_max != 0:
		if details.players_max != details.players_min:
			player_count_label.text = str(details.players_min)+"-"+str(details.players_max)
		else:
			player_count_label.text=str(details.players_max)
	else:
		player_count_label.text = ""
		
	var hours := floori(details.session_duration_seconds /60/60)
	var minutes := floori(details.session_duration_seconds /60)
	if hours>0:
		session_duration_label.text = str(hours)+" h"
	elif minutes>1:
		session_duration_label.text = str(minutes)+" min"
	elif details.session_duration_seconds>0:
		session_duration_label.text = str(details.session_duration_seconds)+" s"
	else:
		session_duration_label.text = ""
	
	cover.texture = game.get_image()

func on_button_down():
	down_usec = Time.get_ticks_usec();
	
func on_focus_entered():
	focus_usec = Time.get_ticks_usec();
	
func on_pressed():
	var diff := absi(down_usec-focus_usec)
	if diff > launch_click_threshold_usec:
		launch_pressed.emit()
