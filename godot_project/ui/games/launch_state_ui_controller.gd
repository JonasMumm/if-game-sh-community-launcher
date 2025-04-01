class_name launch_state_ui_controller
extends Node

const game_name_placeholder = "&&gamename&&"

@export var launcher : cave_launcher
@export var tex_rect : TextureRect
@export var labels : Array[Label]

var games : Array[game_data]
var default_texts : PackedStringArray

func _ready():
	launcher.cave_launched_changed.connect(on_cave_launched_changed)

func set_data(games : Array[game_data]):
	self.games = games

func on_cave_launched_changed(is_launched : bool, cave : cave_info):
	if !is_launched: return
	
	var game_index := games.find_custom(func(v:game_data):return v.cave_info == cave)
	var game := games[game_index]
	var image := game.get_image()
	tex_rect.texture = image
	
	if default_texts.size() == 0:
		for i in range(labels.size()):
			default_texts.append(labels[i].text)
			
	for i in range(labels.size()):
		labels[i].text = default_texts[i].replace(game_name_placeholder,game.collection_game.game.title)
