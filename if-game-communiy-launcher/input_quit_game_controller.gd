class_name input_quit_game_controller
extends Node

signal quit;

const hold_duration_millis:= 2000;
const poll_interval_seconds := 0.35

var _stdio : FileAccess
var _stderr : FileAccess
var _stdio_timer : Timer
var _buffer : PackedByteArray
var _pid : int

var _was_signal_emitted: bool
var _key_down_unix_millis : int

func _enter_tree() -> void:
	_key_down_unix_millis = 0
	
	var executable_path := "res://EscapeKeyDownTracker/bin/EscapeKeyDownTracker.exe";
	var executable_path_global := ProjectSettings.globalize_path(executable_path)
	var pipeResult := OS.execute_with_pipe(executable_path_global,[],false)
	_stdio = pipeResult.stdio as FileAccess
	_stderr = pipeResult.stderr as FileAccess
	_pid = pipeResult.pid;
	
	_stdio_timer = Timer.new();
	_stdio_timer.autostart = true;
	_stdio_timer.wait_time = 0.3
	_stdio_timer.timeout.connect(on_stdio_timer_timeout)
	add_child(_stdio_timer)
	
func _exit_tree() -> void:
	OS.kill(_pid)

func on_stdio_timer_timeout():
	#https://github.com/godotengine/godot/issues/102340#issuecomment-2629564297
	if _stdio.is_open():
		_buffer.clear()
		while true:
			_buffer.append_array(_stdio.get_buffer(2048))
			if _stdio.get_error() != OK:
				break;
		var key_down_unix_millis : int
		if _buffer.size() != 0:
			var ascii := _buffer.get_string_from_ascii()
			var lines := ascii.split("\n", false)
			var last_element := lines[lines.size()-1];
			key_down_unix_millis = int(last_element)
		else:
			key_down_unix_millis = _key_down_unix_millis
			
		var is_down := key_down_unix_millis != 0;
		var was_down := _key_down_unix_millis != 0;
		if is_down && was_down && !_was_signal_emitted:
			var unix_millis_now := Time.get_unix_time_from_system() * 1000
			var down_duration_millis := unix_millis_now - _key_down_unix_millis
			if(down_duration_millis >= hold_duration_millis):
				_was_signal_emitted = true
				quit.emit()
				printerr("QUIT!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
		else:
			_key_down_unix_millis = key_down_unix_millis;
			if _key_down_unix_millis==0:
				_was_signal_emitted = false
