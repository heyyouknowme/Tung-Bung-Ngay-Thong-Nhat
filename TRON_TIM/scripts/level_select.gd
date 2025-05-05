extends Control

@onready var button1 = $VBoxContainer/HBoxContainer/ButtonLevel1
@onready var button2 = $VBoxContainer/HBoxContainer/ButtonLevel2
@onready var button3 = $VBoxContainer/CenterContainer/ButtonLevel3

func _ready():
	# Mở khóa theo trạng thái Global
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_setup_button(button1, 1)
	_setup_button(button2, 2)
	_setup_button(button3, 3)

func _setup_button(button: Button, level_num: int):
	var unlocked = Global.is_level_unlocked(level_num)
	button.disabled = not unlocked
	button.modulate.a = 1.0 if unlocked else 0.5
	
	# Thêm hiệu ứng "khóa" nếu cần
	button.text = "Level %d" % [level_num]
	
	# Kết nối sự kiện clicked với hàm load level
	button.pressed.connect(func(): _on_level_button_pressed(level_num))

func _on_level_button_pressed(level_num: int):
	Global.load_level(level_num)
