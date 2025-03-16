class_name file_router
extends HttpRouter

var _root_folder : String

func _init(root_folder: String) -> void:
	_root_folder = root_folder;

func handle_get(request: HttpRequest, response: HttpResponse):
	#response.send(200, "Hello!" + request_path_to_file_path(request.path)+"   "+_root_folder)
	var file_path := request_path_to_file_path(request.path);
	if !FileAccess.file_exists(file_path):
		response.send(404,"Not found");
		
	if file_path.ends_with(".br"):
		response.headers["Content-Encoding"] ="br"
	if file_path.ends_with(".gz"):
		response.headers["Content-Encoding"] = "gzip"
		
	var type := "text/html";
	
	if file_path.ends_with(".wasm.br") || file_path.ends_with(".wasm.gz"):
		type = "application/wasm"
	
	if(file_path.ends_with(".css")): type = "text/css"
	
	response.send_raw(200,FileAccess.get_file_as_bytes(file_path),type)
	
func request_path_to_file_path(req_path : String) -> String:
	return _root_folder.path_join(req_path.uri_decode())
