extends Control

@onready var play_again_button = $VBoxContainer/PlayAgainButton
@onready var quit_button = $VBoxContainer/QuitButton

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	play_again_button.pressed.connect(on_play_again_pressed)
	quit_button.pressed.connect(on_quit_pressed)

func on_play_again_pressed():
	get_tree().change_scene_to_file("res://NOI_CHU/scenes/main.tscn")

func on_quit_pressed():
	get_tree().change_scene_to_file("res://MAIN/scenes/main.tscn")  
