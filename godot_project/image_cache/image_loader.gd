class_name image_loader
extends Node

const default_cache_directory := "user://image_cache"
const default_cache_file_name := "index.json"

@export var path:= default_cache_directory.path_join(default_cache_file_name)
@export var fallback_image : Texture2D

var cache : image_cache;
var loaded_images : Dictionary[String,ImageTexture]

var preload_index : int 

func _enter_tree():
	cache = image_cache.load_from_file(path)

func preload_urls(urls : PackedStringArray):
	for url in urls:
		await preload_url(url)
		
func preload_url(url : String):
	if url.is_empty(): return;

	if(cache.has_cache_entry(url)): return;
	await download_image(url)

func download_image(url : String):
	var time := Time.get_unix_time_from_system();
	var extension := url.get_extension()
	var index_dir := path.get_base_dir()
	var file_path := index_dir.path_join("img").path_join(str(time)+"_"+str(preload_index)+"."+extension)
	DirAccess.make_dir_recursive_absolute(file_path.get_base_dir())
	preload_index += 1
	var request := HTTPRequest.new()
	request.request_completed.connect(on_request_completed)
	request.download_file = file_path
	add_child(request)
	LogManager.add_log("Requesting resource from url "+str(url)+" to path "+file_path)
	var error := request.request(url)
	if error != OK:
		LogManager.add_log("An error occurred in the HTTP request: "+error_string(error), log_manager.log_type.error)
	await request.request_completed;
	
	if FileAccess.file_exists(file_path):
		cache.add(url,file_path)
		cache.save_to_file(path)
		
	request.queue_free()

func on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	LogManager.add_log("Resource Request finished with result "+str(result)+" and response code "+str(response_code))
	
func get_image(url : String) -> Texture2D:
	if loaded_images.has(url): return loaded_images[url]
	
	if !cache.has_cache_entry(url):
		return fallback_image
	
	var file_path := cache.get_local_path(url)
	
	var image := Image.load_from_file(file_path)
	var texture := ImageTexture.create_from_image(image)
	#todo: free image??
	loaded_images[url] = texture
	return texture
