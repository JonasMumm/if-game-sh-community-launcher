extends Node

@export var games_launcher_frontend : PackedScene
@export var settings : PackedScene

func _ready():
	var args := OS.get_cmdline_args()
	
	var ps := settings if args.find("--setup") != -1 else games_launcher_frontend
	var instance := ps.instantiate()
	add_child(instance)
