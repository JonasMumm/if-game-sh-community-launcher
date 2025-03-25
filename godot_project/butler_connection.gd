class_name butler_connection
extends Node

signal connected;

enum auth_state
{
	no_auth,
	auth_requested,
	authenticated
}

class in_flight_request extends RefCounted:
	signal completed
	var request_id : int
	var error : Dictionary
	var result : Dictionary
	var successful: bool
	
	func _init(id:int) -> void:
		request_id = id
		
class request_error extends RefCounted:
	var code : int
	var message : String

var _tcpPeer : StreamPeerTCP
var _jsonrpc : jsonrpc_butler
var _json : JSON
var _authenticated : auth_state
var _butler_daemon_process : butler_daemon_process
var _request_id : int
var _in_flight_requests : Array[in_flight_request]
var request_handlers : Dictionary[String,Callable]
var process_launcher : butler_daemon_process_launcher
var _notification_subscribers : Array[Dictionary]
var butler_path : String

func _init(butler_path : String) -> void:
	self.butler_path = butler_path
	_jsonrpc = jsonrpc_butler.new()
	_json = JSON.new()
	
func _enter_tree():
	initialize_connection();
	
func initialize_connection():
	_authenticated = auth_state.no_auth
	_tcpPeer = null
	
	if(process_launcher != null): process_launcher.queue_free()
	
	process_launcher = butler_daemon_process_launcher.new(butler_path)
	add_child(process_launcher)
	await process_launcher.butler_daemon_started
	var process := process_launcher._butler_daemon_process;
	process_launcher.queue_free()
	_butler_daemon_process = process;
	print(str(_butler_daemon_process.tcp_ip))
	_tcpPeer = StreamPeerTCP.new()
	var host := process.tcp_ip.split(":")[0];
	var port := process.tcp_ip.split(":")[1].to_int();
	var tcp_open_result := _tcpPeer.connect_to_host(host, port)
	
	print("Connecting to "+host+":"+str(port))
	
	if tcp_open_result != OK:
		printerr(tcp_open_result)

func _exit_tree() -> void:
	if _tcpPeer:_tcpPeer.disconnect_from_host()

func _process(delta: float) -> void:
	if _tcpPeer!=null:
		if(_tcpPeer.get_status() == _tcpPeer.Status.STATUS_NONE):
			_tcpPeer = null
			initialize_connection();
			return
		_tcpPeer.poll()
		if _tcpPeer.get_available_bytes()>0:
			var received := _tcpPeer.get_utf8_string(_tcpPeer.get_available_bytes())
			var received_messages := received.split("\n", false);
			for message in received_messages:
				LogManager.add_log("Receive RPC: " + message, log_manager.log_type.log)
				var jsonrpc := JSON.parse_string(message) as Dictionary
				var id := jsonrpc.get("id",-1) as int
				if id == -1: 
					jsonrpc_handle_notification(jsonrpc["method"],jsonrpc["params"]);
					continue
				
				if jsonrpc.has("result"):
					jsonrpc_handle_result(id, jsonrpc["result"]);
					continue;
					
				if jsonrpc.has("method"):
					jsonrpc_handle_request(id, jsonrpc["method"], jsonrpc["params"]);
					continue;
				jsonrpc_handle_error(id,jsonrpc["error"])
			
		if _authenticated == auth_state.no_auth && _tcpPeer!= null && _tcpPeer.get_status() == _tcpPeer.Status.STATUS_CONNECTED:
			print("Authenticating...")
			_authenticated = auth_state.auth_requested
			var rq = await send_request("Meta.Authenticate", {secret = _butler_daemon_process.secret})
			
			if rq.successful && rq.result["ok"]:
				_authenticated = auth_state.authenticated
				print("Butler Authenticated!")
				connected.emit()
			else:
				printerr("Auth Failed! "+str(rq.result))
				printerr(rq.error.message)

func jsonrpc_handle_notification(method_name: String, params: Dictionary):
	for sub in _notification_subscribers:
		if sub.method == method_name: sub.callback.call(params)
	
func jsonrpc_handle_result(id : int, result : Dictionary):
	for i in range(_in_flight_requests.size()):
		var rq := _in_flight_requests[i]
		if rq.request_id == id:
			rq.result = result
			rq.successful = true;
			_in_flight_requests.remove_at(i)
			rq.completed.emit()
			return;
	printerr("No Request found for id "+str(id))
	
func jsonrpc_handle_request(id: int, method: String, params: Dictionary):
	if request_handlers.has(method):
		var handler := request_handlers[method]
		handler.call(id, method, params)
	else:
		printerr(method+" request has no handler!");
	
func jsonrpc_handle_error(id : int, error : Dictionary):
	printerr("butler error: "+str(error.code)+" - "+str(error.message))
	
	for i in range(_in_flight_requests.size()):
		var rq := _in_flight_requests[i]
		if rq.request_id == id:
			rq.error = error
			_in_flight_requests.remove_at(i)
			rq.completed.emit()
			return;
	printerr("No Request found for id "+str(id))

func send_request(method: String, params: Variant) -> in_flight_request:
	_request_id+=1;
	var rpc := _jsonrpc.make_request(method, params, _request_id)
	var request := in_flight_request.new(_request_id)
	_in_flight_requests.append(request)
	send_rpc(rpc)
	await  request.completed
	return request
	
func send_request_freshable(method: String, params: Variant) -> in_flight_request:
	var rq1 = await send_request(method, params)
	rq1.result["stale"] = true
	if rq1.result.get("stale",false) == true :
		params.fresh = true
		var rq2 := await send_request(method, params)
		if(rq2.successful):
			return rq2
	return rq1
	
func send_response(id : int, params : Dictionary):
	var rpc := _jsonrpc.make_response(params, id)
	send_rpc(rpc)
	
func send_rpc(jsonrpc:Dictionary):
	sanitize_numbers_dict(jsonrpc)
	var json = _json.stringify(jsonrpc)
	LogManager.add_log("Send RPC: "+json, log_manager.log_type.log)
	_tcpPeer.put_data(json.to_utf8_buffer())
	_tcpPeer.put_data("\n".to_utf8_buffer())
	
func wait_for_connection():
	if _authenticated == auth_state.authenticated : return
	await connected
	
func sanitize_numbers_dict(jsonrpc:Dictionary):
	for key in jsonrpc.keys():
		var value = jsonrpc[key]
		
		if value is float:
			jsonrpc[key] = value as int
			
		if(value is Dictionary):
			sanitize_numbers_dict(value)
			
		if value is Array:
			sanitize_numbers_array(value)
			
func sanitize_numbers_array(arr : Array):
	for i in range(arr.size()):
		var value = arr[i]
		
		if value is float:
			arr[i] = value as int
			
		if(value is Dictionary):
			sanitize_numbers_dict(value)
			
		if value is Array:
			sanitize_numbers_array(value)
			
func add_request_handler(method: String, handler : Callable):
	if request_handlers.has(method):
		printerr(method+" request already has a handler subscribed");
	else:
		request_handlers[method] = handler;
		
func remove_request_handler(method: String, handler : Callable):
	if !request_handlers.has(method):
		printerr(method+" request doesnt even have a handler subscribed");
	else:
		request_handlers.erase(method);

func subscribe_notification(method : String, subscriber : Callable):
	_notification_subscribers.append({"method" : method, "callback" : subscriber})
	
func unsubscribe_notification(method : String, subscriber : Callable):
	var index := _notification_subscribers.find_custom(func(v:Dictionary): return v.method == method && v.callback == subscriber)
	
	assert(index >= 0)
	_notification_subscribers.remove_at(index);
