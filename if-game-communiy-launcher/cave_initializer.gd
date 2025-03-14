class_name cave_initializer

static func initialize_cave(connection: butler_connection, game: Dictionary, choicer : choice_selector)->cave_info:
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
		
		if !find_uploads_rq.successful: return
		
		var uploads = find_uploads_rq.result.uploads;
		uploads = uploads.filter(func(element): return element.type == "html" || (element.platforms as Dictionary).has("windows"))
		
		var best_upload := {}
		if(uploads.size() == 0): 
			printerr("No Cave available for "+str(game_id));
			
			var fetch_uploads_rq := await connection.send_request_freshable("Fetch.GameUploads",{gameId = game_id})
			if !fetch_uploads_rq.successful: return null
			
			var upload_index := await choicer.async_get_choice_index("Select Upload for "+str(game), fetch_uploads_rq.result.uploads.map(func(v): return str(v)), true)
			if upload_index<0:return null
			best_upload = fetch_uploads_rq.result.uploads[upload_index]
		else:
			var upload_index := await choicer.async_get_choice_index("Select Upload for "+str(game), uploads.map(func(v): return str(v)), true)
			if upload_index<0:return null
			best_upload = uploads[upload_index]
		var install_queue_rq = await connection.send_request("Install.Queue",{installLocationId = install_location_id, game = game, upload = best_upload, queueDownload = true})		

		if !install_queue_rq.successful:
			return
		
		var install_perform_rq = await  connection.send_request("Install.Perform",{id = install_queue_rq.result.id, stagingFolder = install_queue_rq.result.stagingFolder})
		
		if install_perform_rq.successful:
			return await initialize_cave(connection, game, choicer)
		else:
			printerr("Cave install for "+str(game)+" failed")
			return null;
	else:
		cave = caves[0]
		
		var chech_update_rq := await connection.send_request("CheckUpdate", {caveIds=[cave.id]})
		var updates = chech_update_rq.result.updates;
		
		if updates.size() > 0:
			var update = updates[0]
			var best_choice = update.choices[0]
			for choice in update.choices: #todo: manual upload selection
				if choice.confidence > best_choice.confidence:
					best_choice = choice
			var update_queue_rq = await connection.send_request("Install.Queue",{caveId = cave.id, reason = "update", upload = best_choice.upload, queueDownload = true})		

			if !update_queue_rq.successful:
				return cave_info.new(cave);
		
			var update_perform_rq = await  connection.send_request("Install.Perform",{id = update_queue_rq.result.id, stagingFolder = update_queue_rq.result.stagingFolder})
		
			if update_perform_rq.successful:
				return await initialize_cave(connection, game, choicer)

	return cave_info.new(cave);
