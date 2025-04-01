class_name game_data
extends RefCounted

var cave_info : cave_info
#https://docs.itch.ovh/butlerd/master/#/?id=collectiongame-struct
var collection_game : Dictionary
var collection_entry : collection_game_info
var image_loader : image_loader

func _init(cave : cave_info, collect_game : Dictionary, images : image_loader):
	cave_info = cave
	collection_game = collect_game
	collection_entry = collection_game_info.from_json(collection_game.blurb)
	collection_entry.apply_overrides_to_game(collection_game.game)
	image_loader = images

#should be done in _init(), but the outside world does not seem to actually await any await calls, therefor let's put it in a separate method.
func preload_image():
	await image_loader.preload_url(get_image_url())

func get_image_url() -> String:
	var url : String;
	
	if(collection_game.game.has("stillCoverUrl")): url = collection_game.game.stillCoverUrl
	
	if url.is_empty() && collection_game.game.has("coverUrl"):
		url = collection_game.game.coverUrl;
	
	#fixup protocol in url: because the itch collection blurb html-form replaces any valid http / https urls with an html-embedded image, its impractical to submit full urls to itch. instead the http:// or https:// protocol definition can be ommited when pasting image links into the blurb form.
	if !url.begins_with("https://") && !url.begins_with("http://"):
		if url.begins_with("s://") || url.begins_with("://"):
			url = "http"+url
		else:
			url = "http://"+url
	return url

func get_image() -> ImageTexture:
	return image_loader.get_image(get_image_url())
