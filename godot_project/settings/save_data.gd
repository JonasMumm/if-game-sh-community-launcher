class_name save_data

const save_path := "user://save_data.json";

signal saved;

@export var butler_path : String
@export var profile_id : int
@export var profile_name_hint : String
@export var collection_id : int
@export var collection_hint : String
@export var browser_mode : int #0 = uninitialized / none
@export var browser_chromium_generic_executable_path : String
@export var browser_chrome_executable_path : String
@export var browser_edge_executable_path : String
@export var browser_custom_command : String

static func load_from_file() -> save_data:
	var loaded: save_data = JsonClassConverter.json_file_to_class(save_data, save_path);
	return loaded;
	
func save_to_file() -> void:
	JsonClassConverter.store_json_file(save_path, JsonClassConverter.class_to_json(self))
	saved.emit()
