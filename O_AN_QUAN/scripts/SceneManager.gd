extends Node

# Các biến dùng chung
var ai_level: String = "easy"
var player_score: int = 0
var ai_score: int = 0
var MAX_DEPTH: int = 1     

# Hàm chuyển scene chuẩn Godot
func change_scene(scene_path: String):
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		print("❌ Lỗi khi chuyển scene:", error)
