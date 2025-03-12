class_name main_state_manager
extends Control

@export var background : Control
var active : Control

func _ready():
	for c in get_children():
		if c != active && c != background: hidec(c)

func set_active_content(content : Control):
	if active : hidec(active)
		
	active = content
	showc(active)

func hidec(n:Control):
	n.process_mode = Node.PROCESS_MODE_DISABLED
	n.visible = false

func showc(n:Control):
	n.reparent(self, false)
	n.process_mode = Node.PROCESS_MODE_INHERIT
	n.visible = true
