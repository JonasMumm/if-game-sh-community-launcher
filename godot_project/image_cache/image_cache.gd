class_name image_cache

const default_cache_directory := "user://image_cache"
const default_cache_file_name := "index.json"

@export var url2LocalPath: Dictionary
	
static func load_from_file(index_path : String) -> image_cache:
	return JsonClassConverter.json_file_to_class(image_cache,index_path);
	
static func get_dafault_path() -> String:
	return default_cache_directory.path_join(default_cache_file_name)

func save_to_file(path: String):
	JsonClassConverter.store_json_file(path, JsonClassConverter.class_to_json(self));
	
func add(url : String, path : String):
	url2LocalPath[url] = path

func has_cache_entry(url : String) -> bool:
	return url2LocalPath.has(url)
	
func get_local_path(url : String) -> String:
	return url2LocalPath[url]
