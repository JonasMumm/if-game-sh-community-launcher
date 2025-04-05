class_name directory_copy

static func copy(dir_from : String, dir_to : String) -> Error:
	var a := error_string(DirAccess.make_dir_recursive_absolute(dir_to))
	
	var files = DirAccess.get_files_at(dir_from)
	for file in files:
		var err := DirAccess.copy_absolute(dir_from.path_join(file), dir_to.path_join(file))
		if err != OK:
			return err

	var dirs = DirAccess.get_directories_at(dir_from)
	for dir in dirs:
		var err := copy(dir_from.path_join(dir), dir_to.path_join(dir))
		if err != OK:
			return err
	return OK
