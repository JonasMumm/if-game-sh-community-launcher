class_name game_data
extends RefCounted

var cave_info : cave_info
var collection_game : Dictionary

func _init(cave : cave_info, game : Dictionary):
	cave_info = cave
	collection_game = game
