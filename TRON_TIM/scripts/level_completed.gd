extends Node

func _ready():
	await get_tree().create_timer(4.0).timeout  # Chờ 2 giây
	get_tree().change_scene_to_file("res://TRON_TIM/scenes/level_select.tscn")
