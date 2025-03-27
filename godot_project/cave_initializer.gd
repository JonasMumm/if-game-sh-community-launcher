class_name cave_initializer

static func initialize_cave(connection: butler_connection, game: Dictionary, upload_filter : Dictionary, choicer : choice_selector, profileId : int)->cave_info:
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
		
		var uploads : Array = find_uploads_rq.result.uploads;
		uploads = uploads.filter(func(element): return element.type == "html" || (element.platforms as Dictionary).has("windows"))
		
		var best_upload := {}
		if(uploads.size() == 0): 
			var fetch_uploads_rq := await connection.send_request_freshable("Fetch.GameUploads",{gameId = game_id})
			if !fetch_uploads_rq.successful: return null
			
			uploads = fetch_uploads_rq.result.uploads;
			best_upload = await select_upload(str(game.title), uploads, upload_filter, choicer)
			if best_upload.is_empty(): return null
		else:
			best_upload = await select_upload(str(game.title), uploads, upload_filter, choicer)
			if best_upload.is_empty(): return null
		connection.send_request("Downloads.Drive",{})
		var install_queue_rq = await connection.send_request("Install.Queue",{installLocationId = install_location_id, game = game, upload = best_upload, queueDownload = true})		

		if !install_queue_rq.successful:
			return
		connection.send_request("Downloads.Drive",{})
		
		var install_perform_rq = await  connection.send_request("Install.Perform",{id = install_queue_rq.result.id, stagingFolder = install_queue_rq.result.stagingFolder})
		
		if install_perform_rq.successful:
			return await initialize_cave(connection, game, upload_filter, choicer, profileId)
		else:
			printerr("Cave install for "+str(game)+" failed")
			return null;
	else:
		cave = caves[0]

	return cave_info.new(cave);

static func check_updates(connection: butler_connection, games : Array[game_data], choicer : choice_selector, profile_id : int) -> void:
	var check_update_rq := await connection.send_request("CheckUpdate", {})
	var updates = check_update_rq.result.updates;
	for update in updates:
		var game_index := games.find_custom(func (c:game_data): return c.cave_info.cave.id == update.caveId)
		if game_index == -1: continue;
		
		var game := games[game_index]
		var cave := game.cave_info.cave
		var uploads = update.choices.map(func(v): return v.upload);
		var best_upload = await select_upload(game.collection_game.game.title, uploads, game.collection_entry.upload_filter,choicer);

		connection.send_request("Downloads.Drive",{})
		var update_queue_rq = await connection.send_request("Install.Queue",{caveId = cave.id, reason = "update", upload = best_upload, queueDownload = true})		

		if !update_queue_rq.successful:
			var full_reinstall_choice := await choicer.async_get_choice_index("Update for failed for "+str(game.collection_game.game),["Skip Update","Fresh Install"], false)
			
			if(full_reinstall_choice == 0):
				continue;
				
			if(full_reinstall_choice == 1):
				await connection.send_request("Uninstall.Perform",{caveId = cave.id})
				game.cave_info = await initialize_cave(connection, game.collection_game.game, game.collection_entry.upload_filter, choicer, profile_id)
				continue
		
		connection.send_request("Downloads.Drive",{})
		var update_perform_rq = await connection.send_request("Install.Perform",{id = update_queue_rq.result.id, stagingFolder = update_queue_rq.result.stagingFolder})
		
		if update_perform_rq.successful:
			var new_cave := await initialize_cave(connection, game.collection_game.game, game.collection_entry.upload_filter, choicer, profile_id)
			game.cave_info = new_cave

static func filter_uploads(uploads : Array, upload_filter : Dictionary) -> Array[Dictionary]:
	var results : Array[Dictionary]
	for v in uploads:
		results.append(v)
		
	for filter_key in upload_filter:
		var filter_value :String = upload_filter[filter_key]
		filter_value = trim_whitespace(filter_value).uri_decode().replace("&lt;","<").replace("&gt;",">")
		var comparison_operation : Callable
		if filter_value.begins_with("=="):
			comparison_operation = comparison_equal
			filter_value = filter_value.substr(2)
		elif filter_value.begins_with(">="):
			comparison_operation = comparison_greater_equal
			filter_value = filter_value.substr(2)
		elif filter_value.begins_with(">"):
			comparison_operation = comparison_greater
			filter_value = filter_value.substr(1)
		elif filter_value.begins_with("<="):
			comparison_operation = comparison_less_equal
			filter_value = filter_value.substr(2)
		elif filter_value.begins_with("<"):
			comparison_operation = comparison_less
			filter_value = filter_value.substr(1)
		else:
			comparison_operation = comparison_equal

		for i in range(results.size()-1,-1,-1):
			var upload = results[i]
			var valid:bool = upload.has(filter_key) && comparison_operation.call(trim_whitespace(str(upload[filter_key])), filter_value)
			if !valid:
				results.remove_at(i)
	return results

static func trim_whitespace(v : String):
	return v.replace(" ","")

static func comparison_equal(v1 : String, v2 : String)->bool:
	return v1 == v2
	
static func comparison_greater_equal(v1 : String, v2 : String)->bool:
	return v1 >= v2
	
static func comparison_greater(v1 : String, v2 : String)->bool:
	return v1 > v2
	
static func comparison_less_equal(v1 : String, v2 : String)->bool:
	return v1 <= v2

static func comparison_less(v1 : String, v2 : String)->bool:
	return v1 < v2
	
static func select_upload(game_name : String, uploads : Array, upload_filter : Dictionary, choicer : choice_selector) -> Dictionary:
	var filtered_uploads := filter_uploads(uploads, upload_filter)
	if filtered_uploads.size() == 0:
		return {}
	elif filtered_uploads.size() > 1:
		var choice_index := await choicer.async_get_choice_index("Select Upload for "+str(game_name), filtered_uploads.map(func(v): return str(v)), true)
		if choice_index == -1: return {}
		return filtered_uploads[choice_index]
	else:
		return filtered_uploads[0]
