extends Control

@onready var menu := $Control  # Menu chính (VBox + buttons)
@onready var pause_button := $TextureButton  # Nút Pause
@onready var resume_button = $Control/VBoxContainer/ResumeButton
@onready var quit_button = $Control/VBoxContainer/QuitButton

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu.visible = false
	pause_button.visible = true
	get_tree().paused = false

	# Kết nối các nút
	resume_button.pressed.connect(_on_resume)
	quit_button.pressed.connect(_on_quit)
	pause_button.pressed.connect(_toggle)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle()

func _toggle():
	if get_tree().paused:
		hide_menu()
	else:
		show_menu()

func show_menu():
	menu.visible = true
	pause_button.visible = false
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func hide_menu():
	menu.visible = false
	pause_button.visible = true
	get_tree().paused = false

func _on_resume():
	hide_menu()

func _on_quit():
	get_tree().change_scene_to_file("res://MAIN/scenes/main.tscn")
