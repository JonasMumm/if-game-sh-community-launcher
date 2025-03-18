class_name butler_settings
extends Node

const broth_url := "https://broth.itch.ovh/butler/$CHANNEL/LATEST/archive/default"
const zip_file_path := "user://butler-temp.zip"
const butler_install_path := "user://butler"

@export var info : settings_info_box
@export var choicer : choice_selector
@export var request : HTTPRequest

@export var install_button : Button
@export var uninstall_button : Button

var save : save_data
var connection : butler_connection

func _ready():
	request.request_completed.connect(on_request_completed)
	install_button.pressed.connect(install_butler);
	uninstall_button.pressed.connect(uninstall_butler);

func init_ui(save : save_data, connection : butler_connection):
	self.save = save;
	self.connection = connection
	var global_butler_path := ProjectSettings.globalize_path(save.butler_path)
	info.set_data("Waiting for butler to initialize...\nCurrent butler path: "+global_butler_path, false)
	await connection.wait_for_connection()
	info.set_data("Butler connected!\nCurrent butler path: "+global_butler_path, true)

func install_butler():
	var channels:= PackedStringArray(["windows-amd64","windows-386"])
	var choice := await choicer.async_get_choice_index("Select butler channel to install.",channels, true);
	
	if(choice==-1): return
	
	var url := broth_url.replace("$CHANNEL",channels[choice])
	LogManager.add_log("Requesting butler from "+url)
	request.download_file = zip_file_path
	var error = request.request(url)
	if error != OK:
		LogManager.add_log("An error occurred in the HTTP request: "+error_string(error), log_manager.log_type.error)

func on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	LogManager.add_log("Request finished with result "+str(result)+" and response code "+str(response_code))
	if result != HTTPRequest.RESULT_SUCCESS:
		LogManager.add_log(", that is bad.", log_manager.log_type.error)
	
	if response_code == 307:
		var location_tag := "Location: "
		for str in headers:
			if(str.begins_with(location_tag)):
				var url := str.substr(location_tag.length())
				LogManager.add_log("Redirecting to "+url)
				request.request(url)
				return
		
		LogManager.add_log("Didnt find a location to redirect to!")
		return
	
	extract_all_from_zip(zip_file_path,butler_install_path);
	save.butler_path = butler_install_path.path_join("butler.exe") #todo: thats very windows
	LogManager.add_log("Butler path set!")
	save.save_to_file()
	
static func extract_all_from_zip(zip_file_path:String, extract_into_folder : String):
	var zip_reader = ZIPReader.new()
	var err = zip_reader.open(zip_file_path)
	
	if(err!=OK):
		LogManager.add_log("open zip failed w/ "+error_string(err))
		return
	
	# Destination directory for the extracted files (this folder must exist before extraction).
	# Not all ZIP archives put everything in a single root folder,
	# which means several files/folders may be created in `root_dir` after extraction.
	DirAccess.make_dir_absolute(extract_into_folder)
	var root_dir = DirAccess.open(extract_into_folder)

	var files = zip_reader.get_files()
	for file_path in files:
		# If the current entry is a directory.
		if file_path.ends_with("/"):
			root_dir.make_dir_recursive(file_path)
			continue

		# Write file contents, creating folders automatically when needed.
		# Not all ZIP archives are strictly ordered, so we need to do this in case
		# the file entry comes before the folder entry.
		root_dir.make_dir_recursive(root_dir.get_current_dir().path_join(file_path).get_base_dir())
		var result_file_path := root_dir.get_current_dir().path_join(file_path)
		var file = FileAccess.open(result_file_path, FileAccess.WRITE)
		var buffer = zip_reader.read_file(file_path)
		file.store_buffer(buffer)
	zip_reader.close()

func uninstall_butler():
	var choice := await choicer.async_get_choice_index("Do you want to uninstall butler?",["Yes","No"], false)
	
	if choice != 0: return
	
	await connection.wait_for_connection()
	await connection.send_request("Meta.Shutdown",{})
	DirAccess.remove_absolute(butler_install_path)
	save.butler_path = ""
	save.save_to_file()
