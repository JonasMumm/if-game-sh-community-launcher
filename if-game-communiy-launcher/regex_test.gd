extends Node

func _ready() -> void:
	var testStr := "/ujdu"
	var regex := "^.*"
	var r := RegEx.new()
	r.compile(regex)
	var matches := r.search(testStr)
	print("match "+str(matches))
