extends Node3D

func _ready():
	loop_play()

func loop_play() -> void:
	while true:
		for child in get_children():
			if child is AudioStreamPlayer:
				child.play()
				await child.finished
