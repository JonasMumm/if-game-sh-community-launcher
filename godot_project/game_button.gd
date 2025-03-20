class_name game_button
extends MarginContainer

@export var button: Button
@export var game_name_label : Label
@export var genre_label : Label
@export var player_count_label : Label
@export var session_duration_label : Label

func _set_data(game : game_data):
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
	
