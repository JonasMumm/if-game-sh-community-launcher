class_name collection_game_info

@export var pre_launch_hints : Array[String]
@export var browser_quit_panel_position : String
@export var details : collection_game_details
@export var game_overrides : Dictionary
@export var upload_filter : Dictionary #see https://github.com/JonasMumm/if-game-sh-community-launcher/issues/11

static func from_json(json : String) -> collection_game_info:
	var blurb : String= json
	blurb = blurb.replace("<p>","")
	blurb = blurb.replace("</p>","")
	blurb = blurb.replace("<br>","")
	blurb = blurb.replace("<span>","")
	blurb = blurb.replace("</span>","")
	blurb = blurb.replace("&nbsp;"," ")
	blurb = blurb.replace("\n","")
	var collection_entry = JsonClassConverter.json_string_to_class(collection_game_info, blurb)
	if collection_entry.details == null:
		collection_entry.details = collection_game_details.new()
		
	return collection_entry
		
func apply_overrides_to_game(game:Dictionary):
	for key in game_overrides:
		game[key] = game_overrides[key]
