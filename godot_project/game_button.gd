class_name game_button
extends MarginContainer

@export var button: Button
@export var game_name_label : Label

func _set_data(game : game_data):
	game_name_label.text = str(game.collection_game.game.title);
