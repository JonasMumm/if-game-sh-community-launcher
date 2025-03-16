class_name butler_daemon_process_launcher
extends Node

signal butler_daemon_started(process: butler_daemon_process)

var _stdio : FileAccess;
var _stderr : FileAccess;
var _butler_daemon_process:butler_daemon_process
var _stdio_timer: Timer
var _buffer : PackedByteArray

func _ready() -> void:
	_butler_daemon_process = butler_daemon_process.new()
	var env := env_loader.new()
	
	var butlerExecutablePath:= env.get_string("butlerExecutablePath");
	var butlerDbPath:= ProjectSettings.globalize_path("user://butler.db");
	
	var processId := 	OS.get_process_id()
	
	var pipeResult := OS.execute_with_pipe(butlerExecutablePath,["daemon","-v","--json","--dbpath", "\""+butlerDbPath+"\"", "--destiny-pid", str(processId)],false)
	_stdio = pipeResult["stdio"] as FileAccess
	_stderr = pipeResult["stderr"] as FileAccess
	_butler_daemon_process.pid = pipeResult["pid"] as int
	print("Butler daemon pid ="+str(_butler_daemon_process.pid))

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
			var ascii = _buffer.get_string_from_ascii()
		
			var json = JSON.new()
			for line in ascii.split("\n", true):
				print(line)
				var dictionary = json.parse_string(line)
				if dictionary != null && dictionary.get("type") == "butlerd/listen-notification":
					_butler_daemon_process.secret = dictionary["secret"]
					_butler_daemon_process.tcp_ip = dictionary["tcp"]["address"]
					on_butler_daemon_started()

	if _stderr.is_open():
		_buffer.clear()
		while true:
			_buffer.append_array(_stderr.get_buffer(2048))
			if _stderr.get_error() != OK:
				break;
		if _buffer.size() == 0 : return
		var ascii = _buffer.get_string_from_ascii()

		for line in ascii.split("\n", true):
			printerr(line)

func on_butler_daemon_started():
	#_stdio_timer.queue_free()
	print("Launch completed "+_butler_daemon_process.tcp_ip+" "+_butler_daemon_process.secret)
	butler_daemon_started.emit(_butler_daemon_process)
