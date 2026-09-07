extends Label


func set_game_data(data : game_data) -> void:
	text = GameStringUtility.get_playercount_text(data.collection_entry.details)
