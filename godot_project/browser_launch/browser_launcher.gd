class_name browser_launcher
extends Node

enum mode
{
	None = 0,
	GoogleChrome = 1,
	MicrosoftEdge = 2,
	CustomCommand = 100
}

var in_tree:bool
var browser_pipe : pipe_handler

func _enter_tree():
	in_tree = true
	
func _exit_tree():
	in_tree = false

func launch(save : save_data, url : String):
	if !in_tree:
		LogManager.add_log("browser launcher not in tree!", log_manager.log_type.error)
	
	if !save.is_browser_launch_settings_valid():
		LogManager.add_log("Browser Launch Settings are not valid", log_manager.log_type.error)
		return
	
	if browser_pipe!=null:
		browser_pipe.queue_free()
		browser_pipe = null

	var command := get_launch_command(save, url);
	var pipe_result := OS.execute_with_pipe("cmd.exe",["/c", command], false)
	browser_pipe = pipe_handler.new(pipe_result);
	browser_pipe.print_ascii = true
	add_child(browser_pipe)

static func get_launch_command(save : save_data, url : String) -> String:
	var command := get_base_command(save);
	command = command.replace("$URL","\""+url+"\"")
	command = command.replace("$USER_DATA_DIR", "\""+ProjectSettings.globalize_path("user://browser_user_data")+"\"")
	return command;

static func get_base_command(save : save_data) -> String:
	match save.get_browser_mode_safe():
		mode.GoogleChrome:
			var command := "$PATH_TO_EXECUTABLE --chrome --kiosk $URL --user-data-dir=$USER_DATA_DIR --disable-web-security --disable-features=Translate --incognito"
			return command.replace("$PATH_TO_EXECUTABLE","\""+save.browser_chrome_executable_path+"\"")
		mode.MicrosoftEdge:
			var command := "$PATH_TO_EXECUTABLE --chrome --kiosk $URL --user-data-dir=$USER_DATA_DIR --disable-web-security --disable-features=Translate --incognito -inprivate"
			return command.replace("$PATH_TO_EXECUTABLE","\""+save.browser_edge_executable_path+"\"")
		mode.CustomCommand:
			return save.browser_custom_command
		_:
			return ""
