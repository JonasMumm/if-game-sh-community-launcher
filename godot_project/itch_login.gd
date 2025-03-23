class_name itch_login
extends Node

@export var cave_launcher : cave_launcher
@export var games_ui : games_ui_controller
@export var games_ui_state : ui_state_entry
@export var choicer : choice_selector
@export var main_ui_manager : main_state_manager
@export var game_ui_state_controller : game_ui_state_controller
@export var cover_image_loader : image_loader

var connection : butler_connection

func _ready() -> void:
	var save_data := save_data.load_from_file()
	connection = butler_connection.new(save_data.butler_path)
	add_child(connection)
	game_ui_state_controller.set_connection(connection)
	LogManager.add_log("Waiting for butler connection. If you don't see any progress, you may need to launch the configuration tool.")
	await connection.wait_for_connection()
	
	var profile := await profile_settings.get_profile_from_profiles(connection, save_data.profile_id)
	
	if profile.is_empty():
		LogManager.add_log("Could'nt sign into profile "+str(save_data.profile_id), log_manager.log_type.error)
		return
	LogManager.add_log("Logged into profile "+str(profile.id)+" ("+str(profile.user.displayName+")"))
	
	#init one location
	var install_locations_rq := await connection.send_request("Install.Locations.List",{});
	if(install_locations_rq.result.installLocations.size() == 0):
		var location_path := ProjectSettings.globalize_path("user://game_installs")
		DirAccess.make_dir_absolute(location_path)
		await connection.send_request("Install.Locations.Add", { path = location_path})
	
	
	var profile_id :int= profile.id;
	var collection_rq := await connection.send_request_freshable("Fetch.Collection",{profileId=profile_id, collectionId=save_data.collection_id})
	
	if !collection_rq.successful: return
	
	var collection = collection_rq.result.collection
	var collection_games_rq := await connection.send_request_freshable("Fetch.Collection.Games",{profileId=profile_id,collectionId=int(collection.id) })
	
	var all_gameData : Array[game_data]
	for collection_game in collection_games_rq.result.items:
		var cave_info := await cave_initializer.initialize_cave(connection, collection_game.game, choicer, profile.id)
		if cave_info != null: 
			var v := await game_data.new(cave_info, collection_game, cover_image_loader)
			all_gameData.append(v)
 
	if save_data.check_for_updates_on_startup:
		await cave_initializer.check_updates(connection, all_gameData, choicer, profile.id)
	
	await do_download_finish_clusterfuck(connection)

	games_ui.set_data(connection, all_gameData)
	main_ui_manager.set_active_content(games_ui_state)
		
func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_DELETE):
		get_tree().quit()

func downloads_drive_w_timeout(connection : butler_connection):
	connection.send_request("Downloads.Drive",{})
	await get_tree().create_timer(5, true);

func do_download_finish_clusterfuck(connection : butler_connection):
	await connection.send_request("Downloads.ClearFinished",{})
	var rq_downloads := await connection.send_request("Downloads.List",{});
	var downloads = rq_downloads.result.downloads;

	if(downloads.size()>0):
		await downloads_drive_w_timeout(connection)

	await connection.send_request("Downloads.ClearFinished",{})
	for v in downloads:
		var rq_perform := await connection.send_request("Install.Perform",{id = v.id, stagingFolder = v.stagingFolder});
		var rq_cancel := await connection.send_request("Install.Cancel",{id = v.id})
		#var rq_discard := await connection.send_request("Downloads.Discard",{downloadId = v.id})

	await connection.send_request("Downloads.ClearFinished",{})
