class_name game_data
extends RefCounted

var cave_info : cave_info
#https://docs.itch.ovh/butlerd/master/#/?id=collectiongame-struct
var collection_game : Dictionary
var collection_entry : collection_game_info

func _init(cave : cave_info, col_game : Dictionary):
	cave_info = cave
	collection_game = col_game
	
	var blurb : String= collection_game.blurb
	blurb = blurb.replace("<p>","")
	blurb = blurb.replace("</p>","")
	blurb = blurb.replace("&nbsp; ","")
	blurb = blurb.replace("\n","")
	collection_entry = JsonClassConverter.json_string_to_class(collection_game_info, blurb)
	
	if collection_entry.details == null:
		collection_entry.details = collection_game_details.new()
