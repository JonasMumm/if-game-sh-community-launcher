class_name GameStringUtility

static func get_time_text(details : collection_game_details) -> String:
	var out := ""
	var hours := floori(details.session_duration_seconds /60/60)
	var minutes := floori(details.session_duration_seconds /60)
	if hours>0:
		out = str(hours)+" h"
	elif minutes>1:
		out = str(minutes)+" min"
	elif details.session_duration_seconds>0:
		out = str(details.session_duration_seconds)+" s"
	else:
		out = ""

	return out;
	
static func get_playercount_text(details : collection_game_details) -> String:
	var out := "";
	if details.players_max != details.players_min:
		out = str(details.players_min) + "-" + str(details.players_max)
	else:
		out = str(details.players_max)
			
	return out;
	
static func get_authors_text(details : collection_game_details) -> String:
	var out := "";
	var authors := details.authors
	if !authors.is_empty():
		out = "by "+ authors

	return out;
	
static func get_description_text(details : game_data) -> String:
	var out := "";	
	var game = details.collection_game.game;
	if game.has("shortText"):
		out = game.shortText
		
	return out;