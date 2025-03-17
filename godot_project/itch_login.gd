class_name itch_login
extends Node

@export var cave_launcher : cave_launcher
@export var games_ui : games_ui_controller
@export var games_ui_state : ui_state_entry
@export var choicer : choice_selector
@export var main_ui_manager : main_state_manager
@export var game_ui_state_controller : game_ui_state_controller

var connection : butler_connection

func _ready() -> void:
	var save_data := save_data.load_from_file()
	connection = butler_connection.new(save_data.butler_path)
	add_child(connection)
	game_ui_state_controller.set_connection(connection)
	await connection.wait_for_connection()
	
	var env = env_loader.new()
	var api_key = env.get_string("itch-api-key");
	var rq := await connection.send_request("Profile.LoginWithAPIKey",{apiKey = api_key});
	
	var profile:Dictionary
	var profile_list_rq = await connection.send_request("Profile.List",{});
	var profile_index = await choicer.async_get_choice_index("Select Profile",profile_list_rq.result.profiles.map(func(v): return str(v)), false)
	profile = profile_list_rq.result["profiles"][profile_index]
		
	print("Logged into profile "+str(profile["id"])+" ("+str(profile["user"]["displayName"]+")"))
	
	#init one location
	var install_locations_rq := await connection.send_request("Install.Locations.List",{});
	if(install_locations_rq.result.installLocations.size() == 0):
		var location_path := ProjectSettings.globalize_path("user://game_installs")
		DirAccess.make_dir_absolute(location_path)
		await connection.send_request("Install.Locations.Add", { path = location_path})
	
	
	var profile_id := profile["id"] as int;
	var collections_rq := await connection.send_request_freshable("Fetch.ProfileCollections",{profileId=profile_id}) #todo: paging
	var collections = collections_rq.result.items
	
	var collection_index := 0
	if collections.size()>1:
		collection_index = await choicer.async_get_choice_index("Select Collection",collections.map(func(v):return str(v)), false)
	
	var collection = collections[collection_index]
	
	var collection_games_rq := await connection.send_request_freshable("Fetch.Collection.Games",{profileId=profile_id,collectionId=int(collection.id) })
	
	var all_gameData : Array[game_data]
	for collection_game in collection_games_rq.result.items:
		var cave_info := await cave_initializer.initialize_cave(connection, collection_game.game, choicer, profile.id)
		if cave_info != null: 
			all_gameData.append(game_data.new(cave_info, collection_game))
 
	#await cave_initializer.perform_installs(connection) probably bs
	await cave_initializer.check_updates(connection, all_gameData, choicer, profile.id)
	
	games_ui.set_data(all_gameData)
	main_ui_manager.set_active_content(games_ui_state)
		
func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_DELETE):
		get_tree().quit()
