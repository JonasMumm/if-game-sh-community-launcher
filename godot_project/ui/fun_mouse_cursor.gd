class_name fun_mouse_cursor
extends Control

@export var canvas_layer : CanvasLayer
@export var mouse_anchor_top : Control
@export var mouse_anchor_bottom : Control
@export var mouse_visual_size : Control
@export var mouse_visual_pos : Control
@export var bottom_offset : Vector2
@export var over_scale : float

@export var wobbler_lambda : float;
@export var wobbler_acceleration : float;
@export var min_size : float;

@export var wind_scale : float;
@export var wind_variance: Vector3;

@export var mouse_visual_size_level_2 : Control
@export var mouse_visual_pos_level_2 : Control
@export var mouse_level_2_offset : Vector2
@export var mouse_visual_size_level_3 : Control
@export var mouse_visual_pos_level_3 : Control
@export var mouse_level_3_offset : Vector2


var wobbler_x : wobbler;
var wobbler_y : wobbler;
var wind_noise : FastNoiseLite;

func _ready():
	wind_noise = FastNoiseLite.new();
	wind_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	wind_noise.seed = randi_range(0,9000);
	var global_mouse_pos := get_global_mouse_position()
	mouse_anchor_top.global_position = global_mouse_pos;
	mouse_anchor_bottom.global_position = global_mouse_pos + bottom_offset;
	wobbler_x = wobbler.new(mouse_anchor_bottom.global_position.x,mouse_anchor_bottom.global_position.x, wobbler_acceleration, wobbler_lambda, 0, true);
	wobbler_y = wobbler.new(mouse_anchor_bottom.global_position.y,mouse_anchor_bottom.global_position.y, wobbler_acceleration, wobbler_lambda, 0, true);

func _process(delta:float):
	var global_mouse_pos := get_global_mouse_position()
	mouse_anchor_top.global_position = global_mouse_pos;
	var bottom_target = global_mouse_pos + bottom_offset;
	wobbler_x.target = bottom_target.x;
	wobbler_y.target = bottom_target.y;
	
	wind_noise.offset += wind_variance * delta;
	wobbler_x.speed += wind_noise.get_noise_2d(0,-wind_noise.offset.y) * wind_scale;
	wobbler_y.speed += wind_noise.get_noise_2d(-wind_noise.offset.y,0) * wind_scale;
	
	var bottom_pos := Vector2(wobbler_x.update(delta), wobbler_y.update(delta));
	var pos_pre_clamp_delta := bottom_pos - mouse_anchor_top.global_position;
	
	if pos_pre_clamp_delta.length() < min_size:
		bottom_pos = mouse_anchor_top.global_position + pos_pre_clamp_delta.normalized() * min_size;
		wobbler_x.current = bottom_pos.x;
		wobbler_y.current = bottom_pos.y;
	mouse_anchor_bottom.global_position = bottom_pos;
	mouse_visual_size.custom_minimum_size = Vector2(0,(mouse_anchor_top.global_position-mouse_anchor_bottom.global_position).length() * over_scale)
	mouse_visual_pos.position = (mouse_anchor_top.global_position + mouse_anchor_bottom.global_position) * 0.5 - mouse_visual_pos.size * 0.5
	var pos_diff := mouse_anchor_bottom.global_position - mouse_anchor_top.global_position;
	mouse_visual_pos.rotation = atan2(pos_diff.y, pos_diff.x) - PI * 0.5;
	
	mouse_visual_pos_level_2.position = mouse_visual_pos.position + mouse_level_2_offset;
	mouse_visual_pos_level_3.position = mouse_visual_pos.position + mouse_level_3_offset;
	mouse_visual_pos_level_2.rotation = mouse_visual_pos.rotation
	mouse_visual_pos_level_3.rotation = mouse_visual_pos.rotation
	mouse_visual_size_level_2.custom_minimum_size = mouse_visual_size.custom_minimum_size;
	mouse_visual_size_level_3.custom_minimum_size = mouse_visual_size.custom_minimum_size;
	
