extends Node

func _ready():
	# Chuyển ngay sang màn hình chọn level khi khởi động
	get_tree().change_scene_to_file("res://TRON_TIM/scenes/level_select.tscn")
