extends Control
@onready var fadetransition := $"ColorRect2"
@onready var sound := $Sound_Button

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$VBoxContainer/TextureButton.connect("pressed", Callable(self, "_on_level_pressed").bind("easy"))
	$VBoxContainer/TextureButton2.connect("pressed", Callable(self, "_on_level_pressed").bind("medium"))
	$VBoxContainer/TextureButton3.connect("pressed", Callable(self, "_on_level_pressed").bind("hard"))


func _on_level_pressed(level: String):
	sound.play()
	SceneManager.ai_level = level
	await fadetransition.transition_to_scene("res://O_AN_QUAN/scenes/main.tscn", 0.5)

func _on_exit_pressed():
	sound.play()
	get_tree().quit()
