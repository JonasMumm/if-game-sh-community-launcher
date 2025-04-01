extends Node

@export var launcher : cave_launcher

var eligible_for_quit : bool

func _process(delta: float) -> void:
	if !OS.has_feature("editor"): 
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	
	eligible_for_quit = !launcher._cave_launched && (eligible_for_quit || !Input.is_key_pressed(KEY_ESCAPE))
	
	if eligible_for_quit && Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
