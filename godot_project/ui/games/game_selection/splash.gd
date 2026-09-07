extends TextureRect

var tween : Tween;

func on_game_set(game : game_data) -> void:
	rotation_degrees = randf_range(0.0,360.0);
	
	if tween and tween.is_running():
		tween.kill()
		
	tween = get_tree().create_tween()
	tween.tween_property(self, ^"scale", Vector2.ONE, .15).from(Vector2.ONE * 1.5).set_trans(Tween.TRANS_BACK)
