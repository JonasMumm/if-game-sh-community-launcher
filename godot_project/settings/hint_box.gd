@tool
extends MarginContainer

@export var label : Label
@export_multiline var text : String:
	set(value): 
		if label:
			label.text = value
	get: 
		return label.text
@export var hint_content : Control
@export var check_button : CheckButton
@export var enabled : bool:
	set(value): 
		if!check_button: return
		check_button.button_pressed = value
		on_pressed()
	get: return check_button.button_pressed
@export var enabled_by_default : bool

func _ready():
	check_button.pressed.connect(on_pressed)
	check_button.set_pressed_no_signal(enabled_by_default)
	on_pressed()
	
func on_pressed():
	hint_content.visible = check_button.button_pressed
