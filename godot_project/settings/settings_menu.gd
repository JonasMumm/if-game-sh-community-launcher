extends Control

@export var butler : butler_settings
@export var profile : profile_settings
@export var collection : collection_settings

var connection : butler_connection
var save : save_data

func _ready():
	_refresh_all_ui()

func _refresh_all_ui():
	if save != null:
		save.saved.disconnect(_refresh_all_ui)
	
	save = save_data.load_from_file()
	save.saved.connect(_refresh_all_ui)
	
	if connection:
		connection.queue_free()
		
	LogManager.add_log("Making a new butler connection at path "+save.butler_path)
	connection =butler_connection.new(save.butler_path);
	add_child(connection)
	
	butler.init_ui(save, connection)
	profile.init_ui(save, connection)
	collection.init_ui(save, connection)
