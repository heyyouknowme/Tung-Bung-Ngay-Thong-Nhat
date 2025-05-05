extends Node

var unlocked_levels := [1]  # Mặc định chỉ mở khóa level 1
var current_level : Node = null
var current_level_num := 1

func unlock_level(level_num: int):
	if not unlocked_levels.has(level_num):
		unlocked_levels.append(level_num)
		print("🔓 Mở khóa level %d" % level_num)

func is_level_unlocked(level_num: int) -> bool:
	return unlocked_levels.has(level_num)

func load_level(level_num: int):
	current_level_num = level_num
	get_tree().change_scene_to_file("res://TRON_TIM/scenes/level_%d.tscn" % level_num)

func _on_level_win():
	print("✅ Level %d win!" % current_level_num)
	unlock_level(current_level_num + 1)
	get_tree().change_scene_to_file("res://TRON_TIM/scenes/level_completed.tscn")
