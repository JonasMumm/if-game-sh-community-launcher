extends Label


func set_game_data(data : game_data) -> void:
	text = GameStringUtility.get_time_text(data.collection_entry.details);
