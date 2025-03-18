class_name browser_settings
extends Node

const example_url := "https://ifgamesh.itch.io/"

@export var root_control : Control
@export var info_box : settings_info_box
@export var select_mode_button : Button
@export var select_executable_button : Button
@export var select_executable_file_dialog : FileDialog
@export var launch_command_container : Control
@export var launch_command_line_edit : LineEdit
@export var launch_command_accept_button : Button
@export var test_launch_button : Button
@export var launcher : browser_launcher
@export var server_port_line_edit : LineEdit
@export var server_port_accept_button : Button
@export var choicer : choice_selector

var save : save_data

func _ready():
	select_mode_button.pressed.connect(select_mode)
	select_executable_button.pressed.connect(select_executable)
	select_executable_file_dialog.file_selected.connect(on_executable_selected)
	select_executable_file_dialog.visibility_changed.connect(on_file_dialog_visibility_changed)
	launch_command_accept_button.pressed.connect(save_command)
	server_port_accept_button.pressed.connect(save_port)
	test_launch_button.pressed.connect(test_launch)

func init_ui(save : save_data):
	self.save = save
	
	info_box.set_data("Mode: "+save.get_browser_mode_name()+"\nBase Launch Command: "+browser_launcher.get_base_command(save)+"\nExample Launch Command: "+browser_launcher.get_launch_command(save,example_url), save.is_browser_launch_settings_valid())
	
	var show_command_line_edit = save.get_browser_mode_safe() == browser_launcher.mode.CustomCommand
	var show_browser_executable := !show_command_line_edit && save.get_browser_mode_safe() != browser_launcher.mode.None
	
	launch_command_container.visible = show_command_line_edit
	select_executable_button.visible = show_browser_executable
	
	launch_command_line_edit.text = save.browser_custom_command
	server_port_line_edit.text = str(save.local_server_port)
	
func select_mode():
	var values := browser_launcher.mode.values()
	
	var choice_index := await choicer.async_get_choice_index("Select Browser Mode", values.map(func(v):return str(browser_launcher.mode.find_key(v))), true)
	
	if(choice_index == -1):
		return
	
	save.set_browser_mode(values[choice_index])
	save.save_to_file()
	
func select_executable():
	select_executable_file_dialog.popup_centered_clamped()
	
func on_executable_selected(path : String):
	save.set_browser_executable_path(path)
	save.save_to_file()
	
func on_file_dialog_visibility_changed():
	root_control.visible = !select_executable_file_dialog.visible

func save_command():
	save.browser_custom_command = launch_command_line_edit.text.trim_suffix(" ")
	save.save_to_file()
	
func save_port():
	save.local_server_port = server_port_line_edit.text.to_int()
	save.save_to_file()
	
func test_launch():
	launcher.launch(save, example_url)
