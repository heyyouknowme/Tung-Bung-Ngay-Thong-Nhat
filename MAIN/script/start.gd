extends Control

@export var next_scene_path: String = "res://scenes/main_menu.tscn"  # Set this in Inspector!

func _input(event):
	if event.is_pressed():
		print("🎮 Any input detected. Switching to:", next_scene_path)
		get_tree().change_scene_to_file(next_scene_path)
