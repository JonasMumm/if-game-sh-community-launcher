class_name local_content_router
extends HttpRouter

signal quit_received

var _root_folder : String

func _init(root_folder: String) -> void:
	_root_folder = root_folder;

func handle_get(request: HttpRequest, response: HttpResponse):
	var file_path := request_path_to_file_path(request.path);
	if !FileAccess.file_exists(file_path):
		response.send(404,"Not found "+file_path);
		
	if file_path.ends_with(".br"):
		response.headers["Content-Encoding"] ="br"
	if file_path.ends_with(".gz"):
		response.headers["Content-Encoding"] = "gzip"
		
			
	response.headers["Cross-Origin-Embedder-Policy"] = "require-corp"
	response.headers["Cross-Origin-Resource-Policy"] = "cross-origin"
		
	if file_path.ends_with(".html"):
		response.headers["Cross-Origin-Opener-Policy"] = "same-origin"
		if file_path.begins_with("res://"):
			response.headers["Cross-Origin-Embedder-Policy"] = "credentialless"
		
	var type := "text/html";
	
	if file_path.ends_with(".wasm.br") || file_path.ends_with(".wasm.gz"):
		type = "application/wasm"
	
	if(file_path.ends_with(".css")): type = "text/css"
	if(file_path.ends_with(".js")): type = "text/javascript"
	
	response.send_raw(200,FileAccess.get_file_as_bytes(file_path),type)

func handle_post(request: HttpRequest, response: HttpResponse) -> void:
	if request.path == "/launcherQuit":
		response.send(200)
		quit_received.emit()
	response.send(404,"unknown path "+request.path)

func request_path_to_file_path(req_path : String) -> String:
	var req_path_decoded := req_path.uri_decode()
	var internal_data_route = "/"+cave_launcher.internal_data_route
	if(req_path_decoded.begins_with(internal_data_route)):
		return "res://browser_launch/browser_frontend".path_join(req_path_decoded.substr(internal_data_route.length()))
	return _root_folder.path_join(req_path.uri_decode())
