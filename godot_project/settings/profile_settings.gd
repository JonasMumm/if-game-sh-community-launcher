class_name profile_settings
extends Node

@export var info_box : settings_info_box
@export var api_token_edit : LineEdit
@export var api_token_submit : Button
@export var profile_select : Button
@export var choicer : choice_selector

var connection : butler_connection
var save : save_data

func _ready():
	api_token_submit.pressed.connect(register_api_key);
	profile_select.pressed.connect(choose_profile)

func init_ui(save : save_data, connection : butler_connection):
	self.connection = connection
	self.save = save
	api_token_edit.clear()
	
	info_box.set_data("Waiting for Butler to get ready...", false)
	
	await connection.wait_for_connection()
	
	info_box.set_data("Selected profile: "+str(save.profile_id)+"\nfetching profile info.", false)
	
	var profile := await get_profile_from_profiles(connection, save.profile_id);
	
	if profile.is_empty():
		info_box.set_data("Selected Profile: "+str(save.profile_id)+"\nProfile for user could not be found.", false)
	else:
		var user = profile.user
		info_box.set_data("Selected Profile: "+str(user.displayName)+" ("+str(user.username)+")", true)
	
static func get_profile_from_profiles(connection : butler_connection, profile_id : int) -> Dictionary:
	var rq_profiles := await connection.send_request("Profile.List",{})
	var profiles : Array = rq_profiles.result.profiles;
	var index := profiles.find_custom(func (v): return v.id == profile_id);
	
	if index == -1: return {}
	
	return profiles[index];

func register_api_key():
	await connection.wait_for_connection()
	var token := api_token_edit.text
	var rq_auth := await connection.send_request("Profile.LoginWithAPIKey",{apiKey = token})
	if rq_auth.successful:
		select_profile(rq_auth.result.profile.id)

func choose_profile():
	await connection.wait_for_connection()
	var rq_profiles := await connection.send_request("Profile.List",{}) #v.user.displayName+" ("+v.user.username+")"
	var profiles : Array = rq_profiles.result.profiles;
	var profile_index := await choicer.async_get_choice_index("Select Profile",profiles.map(func(v): return v.user.displayName+" ("+v.user.username+")"),true)
	
	if profile_index == -1: 
		return
	
	select_profile(profiles[profile_index].id)

func select_profile(id : int):
	save.profile_id = id
	save.save_to_file()
