class_name log_manager
extends Node

enum log_type
{
	log,
	warning,
	error
}

const capacity := 10

var logs : PackedStringArray
var loop_index : int
var cached_string : String
var cached_string_valid := false

func _init():
	logs.resize(capacity)
	pass
	
func add_log(log: String, type : log_type):
	logs[loop_index] = log
	loop_index = (loop_index + 1) % capacity 
	cached_string_valid = false
	
	if(type == log_type.log): print(log)
	elif (type == log_type.warning): print(log)
	elif (type == log_type.error): printerr(log)
	
func get_log_string()->String:
	if cached_string_valid : return cached_string
	
	var index := loop_index
	var str := ""
	for v in range(capacity):
		var i := (loop_index + v) % capacity
		str += "\n" + logs[i]
	cached_string = str;
	cached_string_valid = true
	return cached_string
