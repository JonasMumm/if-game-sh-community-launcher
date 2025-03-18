class_name collection_settings
extends Node

@export var info_box : settings_info_box
@export var choose_collection_button : Button
@export var check_updates_toggle : CheckButton
@export var choicer : choice_selector

var connection : butler_connection
var save : save_data

func _ready():
	choose_collection_button.pressed.connect(choose_collection)
	check_updates_toggle.pressed.connect(refresh_update_check)

func init_ui(save : save_data, connection : butler_connection):
	self.connection = connection
	self.save = save
	check_updates_toggle.set_pressed_no_signal(save.check_for_updates_on_startup)
	
	info_box.set_data("Waiting for Butler to get ready...", false)
	await connection.wait_for_connection()
	
	info_box.set_data("Selected collection: "+str(save.collection_id)+"\nfetching collection info.", false)
	
	var collection := await get_collection(save.collection_id);
	
	if collection.is_empty():
		info_box.set_data("Selected collection: "+str(save.collection_id) + "\nCollection could not be found.", false)
	else:
		info_box.set_data("Selected collection: "+str(collection.title)+" ("+str(collection.gamesCount)+")", true)

func get_collection(collection_id : int) -> Dictionary:
	var rq_collections := await connection.send_request_freshable("Fetch.Collection",{profileId = save.profile_id, collectionId=collection_id})
	if !rq_collections.successful: return {}
	return rq_collections.result.collection;
	
func refresh_update_check():
	save.check_for_updates_on_startup = check_updates_toggle.button_pressed
	save.save_to_file()

func choose_collection():
	await connection.wait_for_connection()
	
	var rq_collections := await connection.send_request_freshable("Fetch.ProfileCollections",{profileId = save.profile_id, limit = 50 })
	
	if!rq_collections.successful: return
	
	var collections :Array = rq_collections.result.items;
	var choice_index := await choicer.async_get_choice_index("Choose Collection", collections.map(func(v): return str(v.title)+" ("+str(v.gamesCount)+")" ), true)

	if choice_index == -1: return
	
	save.collection_id = collections[choice_index].id	
	save.save_to_file()
	pass
