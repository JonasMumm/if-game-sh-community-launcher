class_name pipe_handler
extends Node

signal received_bytes(buffer: PackedByteArray)
signal received_err(buffer: PackedByteArray)

var _stdio : FileAccess;
var _stderr : FileAccess;
var _pid : int;
var _stdio_timer : Timer;
var _buffer : PackedByteArray

var print_ascii : bool

func _init(pipeResult : Dictionary) -> void:
	_stdio = pipeResult.stdio as FileAccess
	_stderr = pipeResult.stderr as FileAccess
	_pid = pipeResult.pid;
	
func _enter_tree() -> void:
	_stdio_timer = Timer.new();
	_stdio_timer.autostart = true;
	_stdio_timer.wait_time = 0.3
	_stdio_timer.timeout.connect(on_stdio_timer_timeout)
	add_child(_stdio_timer)

func on_stdio_timer_timeout():
	#https://github.com/godotengine/godot/issues/102340#issuecomment-2629564297
	if _stdio.is_open():
		_buffer.clear()
		while true:
			_buffer.append_array(_stdio.get_buffer(2048))
			if _stdio.get_error() != OK:
				break;
		if _buffer.size() != 0:
			if print_ascii:
				var ascii = _buffer.get_string_from_ascii()
				LogManager.add_log(ascii)
			received_bytes.emit(_buffer)
			
	if _stderr.is_open():
		_buffer.clear()
		while true:
			_buffer.append_array(_stderr.get_buffer(2048))
			if _stderr.get_error() != OK:
				break;
		if _buffer.size() != 0:
			if print_ascii:
				var ascii = _buffer.get_string_from_ascii()
				printerr(ascii)
			received_err.emit(_buffer)
