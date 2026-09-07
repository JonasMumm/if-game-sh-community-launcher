class_name game_button
extends Control

const launch_click_threshold_usec := 80000 #0.08 seconds

signal launch_pressed

@export var button: Button
@export var game_name_label : Label
@export var genre_label : Label
@export var player_count_label : Label
@export var session_duration_label : Label
@export var cover : TextureRect

@export var info_visivility_container : Control
@export var genre_visivility_container : Control
@export var stats_visivility_container : Control

var _game : game_data
var focus_usec := 0
var down_usec := 0

func _ready():
	button.button_down.connect(on_button_down)
	button.focus_entered.connect(on_focus_entered)
	button.pressed.connect(on_pressed)

func _set_data(game : game_data):
	_game = game
	if game_name_label:
		game_name_label.text = str(game.collection_game.game.title)
	if genre_label:
		genre_label.text = str(game.collection_entry.details.genre)
	
	var details := game.collection_entry.details
	
	if player_count_label:
		player_count_label.text = GameStringUtility.get_playercount_text(details)
		
	if session_duration_label:
		session_duration_label.text = GameStringUtility.get_time_text(details)
	
	if cover:
		cover.texture = game.get_image()
	
	if genre_visivility_container:
		genre_visivility_container.visible = !genre_label.text.is_empty()
	if stats_visivility_container:
		stats_visivility_container.visible = !player_count_label.text.is_empty() || !session_duration_label.text.is_empty()
	if info_visivility_container:
		info_visivility_container.visible = genre_visivility_container.visible || stats_visivility_container.visible

func on_button_down():
	down_usec = Time.get_ticks_usec();
	
func on_focus_entered():
	focus_usec = Time.get_ticks_usec();
	
func on_pressed():
	var diff := absi(down_usec-focus_usec)
	if diff > launch_click_threshold_usec:
		launch_pressed.emit()
