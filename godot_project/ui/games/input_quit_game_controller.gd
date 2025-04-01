class_name input_quit_game_controller
extends Node

signal quit;

const hold_duration_millis:= 1500;
const poll_interval_seconds := 0.3
const executable_dir := "user://EscapeKeyDownTracker/"

var _stdio : FileAccess
var _stderr : FileAccess
var _stdio_timer : Timer
var _buffer : PackedByteArray
var _pid : int

var _was_signal_emitted: bool
var _key_down_unix_millis : int

func _init():
	extract_all_from_zip()

func _enter_tree() -> void:
	_key_down_unix_millis = 0
	
	var executable_path := executable_dir.path_join("EscapeKeyDownTracker.exe");
	
	if(!FileAccess.file_exists(executable_path)):
		printerr("EscapeKeyDownTracker.exe file does not exist")
	
	var executable_path_global := ProjectSettings.globalize_path(executable_path)
	var pipeResult := OS.execute_with_pipe(executable_path_global,[],false)
	_stdio = pipeResult.stdio as FileAccess
	_stderr = pipeResult.stderr as FileAccess
	_pid = pipeResult.pid;
	
	_stdio_timer = Timer.new();
	_stdio_timer.autostart = true;
	_stdio_timer.wait_time = poll_interval_seconds
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
		else:
			_key_down_unix_millis = key_down_unix_millis;
			if _key_down_unix_millis == 0:
				_was_signal_emitted = false

func extract_all_from_zip():
	var zip_reader = ZIPReader.new()
	var err = zip_reader.open("res://EscapeKeyDownTracker/bin/EscapeKeyDownTracker.zip")
	
	if(err!=OK):
		printerr("open zip failed w/ "+error_string(err))
		return
	
	# Destination directory for the extracted files (this folder must exist before extraction).
	# Not all ZIP archives put everything in a single root folder,
	# which means several files/folders may be created in `root_dir` after extraction.
	DirAccess.make_dir_absolute(executable_dir)
	var root_dir = DirAccess.open(executable_dir)

	var files = zip_reader.get_files()
	for file_path in files:
		# If the current entry is a directory.
		if file_path.ends_with("/"):
			root_dir.make_dir_recursive(file_path)
			continue

		# Write file contents, creating folders automatically when needed.
		# Not all ZIP archives are strictly ordered, so we need to do this in case
		# the file entry comes before the folder entry.
		root_dir.make_dir_recursive(root_dir.get_current_dir().path_join(file_path).get_base_dir())
		var result_file_path := root_dir.get_current_dir().path_join(file_path)
		var file = FileAccess.open(result_file_path, FileAccess.WRITE)
		if file != null: #todo: the file may not have opened correctly, because it is still used by previous sessions process if it didnt exit cleanly. deal with that.
			var buffer = zip_reader.read_file(file_path)
			file.store_buffer(buffer)
	zip_reader.close()
