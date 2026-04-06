class_name performance_control
extends Object

static func set_performance_mode(high_fps : bool):
	Engine.max_fps = 30 if high_fps else 4
