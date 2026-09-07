class_name games_ui_controller
extends Control

@export var games_ui_list_layout_data: games_ui_list_layout_data
@export var launcher : cave_launcher
@export var launch_button : Button

@export var title_label : Label
@export var cover_texture_rect : TextureRect
@export var author_label : Label
@export var input_layout_manager : input_layout_ui
@export var shortText_label : Label
@export var pre_launch_hints : Array[pre_launch_hint]

var connection : butler_connection
var games : Array[game_data]
var buttons : Array[game_button]
var focused_button : game_button

signal focused_button_changed(button : game_button)
signal game_changed(data : game_data)


func _ready():
	launch_button.pressed.connect(on_launch_button_pressed)

func set_data(connection : butler_connection, games : Array[game_data]):
	self.connection = connection
	self.games = games
	
	var buttons : Array[game_button]
	
	var games_to_show := games;
	while games_to_show.size() < 5:
		games_to_show.append_array(games_to_show);
	
	for game in games_to_show:
		var button := games_ui_list_layout_data.button_packed_scene.instantiate() as game_button
		button._set_data(game)
		var cave := game.cave_info
		button.button.pressed.connect(set_focused_button.bind(button))
		button.button.focus_entered.connect(set_focused_button.bind(button))
		button.launch_pressed.connect(on_launch_button_pressed)
		games_ui_list_layout_data.button_container.add_child(button)
		buttons.append(button)
	
	set_focused_button(buttons[0])

func grab_context_focus(shown : bool):
	if shown: focused_button.button.grab_focus()
	
func set_focused_button(b : game_button):
	focused_button = b
	focused_button_changed.emit(b)
	
	# obsolete, use game_changed signal instead
	if title_label:
		title_label.text = focused_button._game.collection_game.game.title
	cover_texture_rect.texture = focused_button._game.get_image()
	
	# obsolete, use game_changed signal instead
	if shortText_label:
		var game = focused_button._game.collection_game.game
		if game.has("shortText"):
			shortText_label.text = "\""+game.shortText+"\""
		else :
			shortText_label.text = ""
		
	# obsolete, use game_changed signal instead
	if author_label:
		author_label.text = GameStringUtility.get_authors_text(focused_button._game.collection_entry.details)
		author_label.visible = !author_label.text.is_empty()
	
	input_layout_manager.set_data(focused_button._game.collection_entry.controls)
	game_changed.emit(focused_button._game)
	focused_button.button.grab_focus()
	
func on_launch_button_pressed():
	var hints := focused_button._game.collection_entry.pre_launch_hints
	
	for hint_type in hints:
		var hint_node_index := pre_launch_hints.find_custom(func (plh : pre_launch_hint): return plh.pre_launch_hint_type == hint_type)
		if hint_node_index >=0:
			await pre_launch_hints[hint_node_index].display()
	launch_button.grab_focus()
	var game := focused_button._game;
	var err := game.run_pre_launch_options();
	if err != OK:
		printerr(err);
		return;
	launcher.launch_cave(game.cave_info, connection, game.collection_entry.browser_quit_panel_position)
	
