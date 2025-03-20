extends Node

func _ready():
	var obj := collection_game_info.new()
	
	obj.pre_launch_hints.append("Hint1")
	obj.details = collection_game_details.new()
	obj.details.genre ="GENREE"
	
	var str:= JsonClassConverter.class_to_json_string(obj)
	var result := JsonClassConverter.json_string_to_class(collection_game_info, str)
	
	print(":")
