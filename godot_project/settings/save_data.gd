class_name save_data

const save_path := "user://save_data.json";

signal saved;

@export var butler_path : String
@export var profile_id : int
@export var collection_id : int
@export var check_for_updates_on_startup := true
@export var browser_mode : int #browser_launcher.type
@export var browser_chromium_generic_executable_path : String
@export var browser_chrome_executable_path : String
@export var browser_edge_executable_path : String
@export var browser_custom_command : String
@export var local_server_port := 39902

static func load_from_file() -> save_data:
	var loaded: save_data = JsonClassConverter.json_file_to_class(save_data, save_path);
	return loaded;
	
func save_to_file() -> void:
	JsonClassConverter.store_json_file(save_path, JsonClassConverter.class_to_json(self))
	saved.emit()
	
func get_browser_mode_safe()->browser_launcher.mode:
	var values := browser_launcher.mode.values()
	var index := values.find(browser_mode)
	
	if(index==-1):
		return browser_launcher.mode.None
	return values[index]
	
func get_browser_mode_name() -> String:
	var values := browser_launcher.mode.values()
	var index := values.find(browser_mode)
	
	if(index==-1):
		index =0
	return browser_launcher.mode.keys()[index]

func set_browser_mode(v : browser_launcher.mode) -> void:
	browser_mode = v
	
func is_browser_launch_settings_valid() -> bool:
	match get_browser_mode_safe():
		browser_launcher.mode.GoogleChrome:
			return !browser_chrome_executable_path.is_empty() && FileAccess.file_exists(browser_chrome_executable_path)
		browser_launcher.mode.MicrosoftEdge:
			return !browser_edge_executable_path.is_empty() && FileAccess.file_exists(browser_edge_executable_path)
		browser_launcher.mode.CustomCommand:
			return !browser_custom_command.is_empty()
		_:
			return false

func set_browser_executable_path(path : String):
	match get_browser_mode_safe():
		browser_launcher.mode.GoogleChrome:
			browser_chrome_executable_path = path
		browser_launcher.mode.MicrosoftEdge:
			browser_edge_executable_path = path
