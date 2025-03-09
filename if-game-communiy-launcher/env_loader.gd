class_name env_loader
extends RefCounted

const envPath := "res://env.json";
var _env : Dictionary

func _init() -> void:
	var file := FileAccess.open(envPath, FileAccess.READ)
	var content := file.get_as_text();
	file.close()
	var json := JSON.new();
	_env = json.parse_string(content) as Dictionary;

func get_string(key: String) -> String:
	return _env[key]
