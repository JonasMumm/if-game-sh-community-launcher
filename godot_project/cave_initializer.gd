class_name cave_initializer

static func initialize_cave(connection: butler_connection, game: Dictionary, choicer : choice_selector, profileId : int)->cave_info:
	var game_id := game.id as int;
	game.id = game_id
	var fetch_caves_rq = await connection.send_request("Fetch.Caves",{filters={gameId = game_id}});
	var caves = fetch_caves_rq.result.items;
	
	var install_location_id : String
	var has_cave : bool = caves.size() > 0
	var cave : Dictionary;
	if !has_cave:
		var install_locations_rq := await connection.send_request("Install.Locations.List",{});
		install_location_id =install_locations_rq.result.installLocations[0].id #todo: Choose install location
		
		await connection.send_request_freshable("Fetch.DownloadKeys",{profileId = profileId, limit = 24, filters = {gameId = game_id}})
		var find_uploads_rq := await connection.send_request("Game.FindUploads",{game = game})
		
		if !find_uploads_rq.successful: return
		
		var uploads = find_uploads_rq.result.uploads;
		uploads = uploads.filter(func(element): return element.type == "html" || (element.platforms as Dictionary).has("windows"))
		
		var best_upload := {}
		if(uploads.size() == 0): 
			var fetch_uploads_rq := await connection.send_request_freshable("Fetch.GameUploads",{gameId = game_id})
			if !fetch_uploads_rq.successful: return null
			
			var upload_index := await choicer.async_get_choice_index("Select Upload for "+str(game), fetch_uploads_rq.result.uploads.map(func(v): return str(v)), true)
			if upload_index<0:return null
			best_upload = fetch_uploads_rq.result.uploads[upload_index]
		else:
			var upload_index := await choicer.async_get_choice_index("Select Upload for "+str(game), uploads.map(func(v): return str(v)), true)
			if upload_index<0:return null
			best_upload = uploads[upload_index]
		connection.send_request("Downloads.Drive",{})
		var install_queue_rq = await connection.send_request("Install.Queue",{installLocationId = install_location_id, game = game, upload = best_upload, queueDownload = true})		

		if !install_queue_rq.successful:
			return
		connection.send_request("Downloads.Drive",{})
		
		var install_perform_rq = await  connection.send_request("Install.Perform",{id = install_queue_rq.result.id, stagingFolder = install_queue_rq.result.stagingFolder})
		
		if install_perform_rq.successful:
			return await initialize_cave(connection, game, choicer, profileId)
		else:
			printerr("Cave install for "+str(game)+" failed")
			return null;
	else:
		cave = caves[0]

	return cave_info.new(cave);

static func perform_installs(connection: butler_connection):
	var dl_rq = await connection.send_request("Downloads.List",{});
	var downloads = dl_rq.result.downloads;
	for download in downloads:
		if download.error != null: 
			printerr("Download error: "+str(download))
			continue
		#await connection.send_request("Install.Perform",{id = download.id, stagingFolder = download.stagingFolder })
		await connection.send_request("Downloads.Discard",{downloadId = download.id}) #todo: seems stupid we have to discard all supposedly finished downloads here, but else updating a cave fails if the download list already has an entry for that cave
	await connection.send_request("Downloads.ClearFinished",{})

static func check_updates(connection: butler_connection, games : Array[game_data], choicer : choice_selector, profile_id : int) -> void:
	var check_update_rq := await connection.send_request("CheckUpdate", {})
	var updates = check_update_rq.result.updates;
	for update in updates:
		var game_index := games.find_custom(func (c:game_data): return c.cave_info.cave.id == update.caveId)
		if game_index == -1: continue;
		
		var game := games[game_index]
		var cave := game.cave_info.cave
		var choice_index := await choicer.async_get_choice_index("Select Update for "+str(game.collection_game), update.choices.map(func(v): return str(v)), true)
		
		if choice_index == -1: continue

		var best_choice = update.choices[choice_index]
		var update_queue_rq = await connection.send_request("Install.Queue",{caveId = cave.id, reason = "update", upload = best_choice.upload, queueDownload = true})		

		if !update_queue_rq.successful:
			var full_reinstall_choice := await choicer.async_get_choice_index("Update for failed for "+str(game.collection_game.game),["Skip Update","Fresh Install"], false)
			
			if(full_reinstall_choice == 0):
				continue;
				
			if(full_reinstall_choice == 1):
				await connection.send_request("Uninstall.Perform",{caveId = cave.id})
				game.cave_info = await initialize_cave(connection, game.collection_game.game, choicer, profile_id)
				continue
		
		var update_perform_rq = await connection.send_request("Install.Perform",{id = update_queue_rq.result.id, stagingFolder = update_queue_rq.result.stagingFolder})
		
		if update_perform_rq.successful:
			var new_cave := await initialize_cave(connection, game.collection_game.game, choicer, profile_id)
			game.cave_info = new_cave
