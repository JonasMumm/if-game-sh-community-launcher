extends Label


func set_game_data(data : game_data) -> void:
	text = data.collection_game.game.title
