class_name choice_selector
extends Control

signal choice_selected(choice_index:int)

@export var choice_text:Label
@export var choice_button_container:Control
@export var choice_button_packed_scene:PackedScene

func _init():
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func async_get_choice_index(choice_title: String, choices: PackedStringArray, allow_cancel : bool) -> int:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	
	if choice_button_container.get_child_count()>0:
		printerr("Choice still pending")
	
	choice_text.text = choice_title
	
	if allow_cancel:
		AddButton(-1,"<Cancel Selection>")
	
	for v in range(choices.size()):
		AddButton(v,choices[v])
	
	var index = await choice_selected
	return index
	
func AddButton(choice_index:int, caption:String):
	var button := choice_button_packed_scene.instantiate() as Button
	button.text = caption
	button.pressed.connect(func() : 
		for i in range(choice_button_container.get_child_count()-1,-1,-1):
			choice_button_container.get_child(i).queue_free()
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		choice_selected.emit(choice_index))
	choice_button_container.add_child(button)
