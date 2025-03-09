class_name cave_initializer

static func initialize_cave(connection: butler_connection, game: Dictionary)->cave_info:
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
		
		var find_uploads_rq := await connection.send_request("Game.FindUploads",{game = game})
		var uploads = find_uploads_rq.result.uploads;
		uploads = uploads.filter(func(element): return element.type == "html" || (element.platforms as Dictionary).has("windows"))
		
		if(uploads.size() == 0): 
			printerr("No Cave available for "+str(game_id));
			return null;
		var best_upload = uploads[0]
		for upload in uploads: #todo: manual upload selection
			if upload.updatedAt > best_upload.updatedAt:
				best_upload = upload
		best_upload.id = best_upload.id as int
		var install_queue_rq = await connection.send_request("Install.Queue",{installLocationId = install_location_id, game = game, upload = best_upload, queueDownload = true})		
		printerr("Install Queued now perform");
		
		var install_perform_rq = await  connection.send_request("Install.Perform",{id = install_queue_rq.result.id, stagingFolder = install_queue_rq.result.stagingFolder})
		printerr("performed!");
		
		if install_perform_rq.successful:
			return await initialize_cave(connection, game)
		else:
			printerr("Cave install for "+str(game)+" failed")
			return null;
	else:
		cave = caves[0]
	return cave_info.new(cave);
