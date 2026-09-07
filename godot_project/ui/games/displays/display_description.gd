extends Label


func set_game_data(data : game_data) -> void:
	text = GameStringUtility.get_description_text(data);
