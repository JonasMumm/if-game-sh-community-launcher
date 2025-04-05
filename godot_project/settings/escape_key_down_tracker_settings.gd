class_name escape_key_down_tracker_settings
extends Node

const type_win_x64_standalone = "win-x64-standalone"
const type_net_portable = "net8.0-windows"
const types : PackedStringArray = [type_win_x64_standalone,type_net_portable]

@export var choose_type_button : Button
@export var choicer : choice_selector
@export var info_box : settings_info_box

var save : save_data

func _ready():
	choose_type_button.pressed.connect(choose_type)

func init_ui(save : save_data):
	self.save = save
	
	info_box.set_data("Selected architecture/mode: " + save.get_escape_key_down_tracker_type_safe(), true)

func choose_type():
	var index = await choicer.async_get_choice_index("Select Escape Key Down Tracker architecture/type. The .net version requries .net>=8.0 to be installed.",escape_key_down_tracker_settings.types, true)
	if index >= 0:
		save.escape_key_down_tracker_type = types[index]
		save.save_to_file()
