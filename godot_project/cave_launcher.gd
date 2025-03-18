class_name cave_launcher
extends Node

signal cave_launched_changed (is_launched : bool, cave : cave_info)

@export var quit_input_handler : input_quit_game_controller

var _cave_running : bool
var _pre_launch_processes : PackedInt32Array
var _connection : butler_connection
var _server : HttpServer
var _browser_pipe : pipe_handler

func _ready() -> void:
	quit_input_handler.quit.connect(quit_cave.bind(true))

func launch_cave(v: cave_info, connection : butler_connection):
	if _cave_running:
		quit_cave(true)
		
	force_clean_up_run_lock(v)
	
	_connection = connection
	_cave_running = true
	cave_launched_changed.emit(_cave_running, v)
	await _connection.wait_for_connection()
	var cave := v.cave;
	var install_location_id = cave.installInfo.installLocation
	
	var install_locations_rq := await connection.send_request("Install.Locations.GetByID",{id = install_location_id});
	var base_path := install_locations_rq.result.installLocation.path as String;
	var prereqsPath := base_path.path_join("prereqs").path_join(str(cave.id))
	_pre_launch_processes = get_all_process_ids()
	connection.add_request_handler("HTMLLaunch", handler_html_launch);
	printerr("Will launch")
	await connection.send_request("Launch",{caveId = cave.id, prereqsDir = prereqsPath})
	quit_cave(false)

static func get_all_process_ids() -> PackedInt32Array:
	var output := []
	OS.execute("powershell.exe", ["-Command", "get-process | Format-List -Property Id"], output)
	var output_string := output[0] as String
	output_string = output_string.replacen("\r","");
	output_string = output_string.replacen(" ","");
	var string_splits := output_string.split("\n",false);
	var pids : PackedInt32Array
	for line in string_splits:
		pids.append(line.split(":",false)[1] as int)
	return pids;
	
static func wait_then_kill(prev_processes : PackedInt32Array, tree : SceneTree):
	var after_launch_processes := get_all_process_ids()
		
	for pid in after_launch_processes:
		if !prev_processes.has(pid):
			print("Kill "+str(pid))
			OS.kill(pid)
			
func handler_html_launch(id: int, method:String, params:Dictionary):
	_server = HttpServer.new()
	_server.register_router("^.*", file_router.new(params.rootFolder))
	_server.port = 39902
	#_server.bind_address = "localhost"
	add_child(_server)
	_server.start()
	
	var env := env_loader.new();
	var command := env.get_string("browser-launch-command");
	print(str(params))
	command = command.replace("$url","http://localhost:"+str(_server.port).path_join(params.indexPath))
	command = command.replace("$userDataDir",ProjectSettings.globalize_path("user://browser_user_data"))
	print("Launch Command: "+command)
	var array : Array
	var pipe_result := OS.execute_with_pipe("cmd.exe",["/c", command],false)
	_browser_pipe = pipe_handler.new(pipe_result);
	_browser_pipe.print_ascii = true
	add_child(_browser_pipe)

func quit_cave(kill_spawned_processes : bool):
	print("QUIT CAVE "+str(kill_spawned_processes))
	if !_cave_running: return;
	_cave_running = false
	_connection.remove_request_handler("HTMLLaunch", handler_html_launch);
	if kill_spawned_processes:
		var after_launch_processes := get_all_process_ids()
		for pid in after_launch_processes:
			if !_pre_launch_processes.has(pid):
				print("Kill "+str(pid))
				OS.kill(pid)
	
	if _server != null:
		_server.queue_free()
		_server = null
		
	if _browser_pipe != null:
		_browser_pipe.queue_free()
		_server = null
	
	get_window().grab_focus()
	cave_launched_changed.emit(false, null)
	_connection.initialize_connection() #don't know why, but not resetting the connection after exiting a cave causes errors when launching another cave

func force_clean_up_run_lock(v:cave_info):
	var folder_path:=v.cave.installInfo.installFolder as String;
	var lock_file_path := folder_path.path_join(".itch").path_join("runlock.json")
	
	if FileAccess.file_exists(lock_file_path):
		print("Has runlock File at "+str(lock_file_path)+", deleting forcefully...")
		var result := DirAccess.remove_absolute(lock_file_path)
		if(result!=OK):
			printerr(result)
