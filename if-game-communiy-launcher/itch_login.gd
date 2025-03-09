class_name itch_login
extends Node

@export var connection : butler_connection
@export var cave_launcher : cave_launcher
@export var games_ui : games_ui_controller

func _ready() -> void:
	await connection.wait_for_connection()
	
	var env = env_loader.new()
	var api_key = env.get_string("itch-api-key");
	var rq := await connection.send_request("Profile.LoginWithAPIKey",{apiKey = api_key});
	
	var profile:Dictionary
	if !rq.successful:
		var profile_list_rq = await connection.send_request("Profile.List",{});
		profile = profile_list_rq.result["profiles"][0]
	else:
		profile = rq.result["profile"]
		
	print("Logged into profile "+str(profile["id"])+" ("+str(profile["user"]["displayName"]+")"))
	
	var profile_id := profile["id"] as int;
	var collections_rq := await connection.send_request_freshable("Fetch.ProfileCollections",{profileId=profile_id}) #todo: paging
	var collections = collections_rq.result.items
	var collection = collections[0]
	
	var collection_games_rq := await connection.send_request_freshable("Fetch.Collection.Games",{profileId=profile_id,collectionId=int(collection.id) })
	
	var all_gameData : Array[game_data]
	for collection_game in collection_games_rq.result.items:
		var cave_info := await cave_initializer.initialize_cave(connection, collection_game.game)
		if cave_info != null: 
			all_gameData.append(game_data.new(cave_info, collection_game))

	games_ui.set_data(all_gameData)
	games_ui.process_mode = Node.PROCESS_MODE_INHERIT
		
func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_DELETE):
		get_tree().quit()
