class_name cave_launcher
extends Node

const internal_data_route = "IFgameSHCommunityLauncherData";
const notification_launch_running := "LaunchRunning"
const request_prereqs := "PrereqsFailed"

signal cave_launched_changed (is_launched : bool, cave : cave_info)
signal cave_running_changed (is_running : bool)

@export var quit_input_handler : input_quit_game_controller
@export var browser_launcher : browser_launcher

var _cave_running : bool
var _pre_launch_processes : PackedInt32Array
var _connection : butler_connection
var _server : HttpServer
var _router : file_router

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
	connection.add_request_handler(request_prereqs, handler_prereqs_failed);
	connection.subscribe_notification(notification_launch_running, on_notification_launch)
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
	var save := save_data.load_from_file()
	_server = HttpServer.new()
	_router = file_router.new(params.rootFolder)
	_router.quit_received.connect(on_router_quit_received)
	_server.register_router("^.*", _router)
	_server.port = save.local_server_port
	add_child(_server)
	_server.start()
	var file :String= params.indexPath
	var frameFile := internal_data_route.path_join("index.html")
	var url := "http://localhost:"+str(_server.port).path_join(frameFile)
	url+="?iframeTarget="+("/"+file).uri_encode()
	url+="&closePanelLocation="+"topLeft"
	LogManager.add_log("Preparing to launch url "+url)
	browser_launcher.launch(save, url)
	cave_running_changed.emit(true)

func quit_cave(kill_spawned_processes : bool):
	if !_cave_running: return;
	_cave_running = false
	_connection.remove_request_handler("HTMLLaunch", handler_html_launch);
	_connection.remove_request_handler(request_prereqs, handler_prereqs_failed);
	quit_input_handler.quit.disconnect(quit_hard)
	if kill_spawned_processes:
		var after_launch_processes := get_all_process_ids()
		for pid in after_launch_processes:
			if !_pre_launch_processes.has(pid):
				print("Kill "+str(pid))
				OS.kill(pid)
	
	if _server != null:
		_server.queue_free()
		_server = null#
		
	if _router != null:
		_router.quit_received.disconnect(on_router_quit_received)
		_router = null
	
	get_window().grab_focus()
	cave_launched_changed.emit(false, null)
	cave_running_changed.emit(false)
	_connection.initialize_connection() #don't know why, but not resetting the connection after exiting a cave causes errors when launching another cave

func on_router_quit_received():
	quit_cave(true)

func force_clean_up_run_lock(v:cave_info):
	var folder_path:=v.cave.installInfo.installFolder as String;
	var lock_file_path := folder_path.path_join(".itch").path_join("runlock.json")
	
	if FileAccess.file_exists(lock_file_path):
		print("Has runlock File at "+str(lock_file_path)+", deleting forcefully...")
		var result := DirAccess.remove_absolute(lock_file_path)
		if(result!=OK):
			printerr(result)

func on_notification_launch(params : Dictionary):
	quit_input_handler.quit.connect(quit_hard)
	cave_running_changed.emit(true)

func quit_hard():
	quit_cave(true)

func handler_prereqs_failed(id: int, method:String, params:Dictionary):
	LogManager.add_log("Launching without Prereqs!",log_manager.log_type.error)
	_connection.send_response(id,{"continue" = true})
