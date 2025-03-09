class_name game_button
extends Button

func _set_data(game : game_data):
	text = str(game.collection_game.game.title);
