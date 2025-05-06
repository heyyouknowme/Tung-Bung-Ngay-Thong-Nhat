extends CanvasLayer

signal bot_selected(level: int)

var selected_level

func _ready():
	$BotDescription.visible = false
	$ConfirmButton.visible = false
	$ConfirmButton.disabled = true
	$ConfirmButton.pressed.connect(_on_confirm_pressed)

	for i in range(1, 6):
		var btn := get_node("Ava" + str(i))
		btn.set_meta("level", i)
		btn.set_meta("desc", _get_bot_desc(i))
		btn.mouse_entered.connect(func(): _on_hover(btn))
		btn.mouse_exited.connect(_on_unhover)
		btn.pressed.connect(func(): _on_avatar_selected(btn))

func _get_bot_desc(level: int) -> String:
	var descs = {
		"1": "                  Lâm(Level 1)\n      Thích chơi đùa với quân cờ",
		"2": "                  Mai(Level 2)\nLuôn sẵn sàng giúp đỡ người mới tập",
		"3": "                  Hoàng(Level 3)\nRất háo hức học hỏi và cải thiện kỹ năng chơi cờ",
		"4": "                  Nghị(Level 4)\nĐã học được nhiều nước đi thông minh.",
		"5": "                  Trân(Level 5)\n                Đã chơi cờ 20 năm!"
	}
	return descs.get(str(level), "Không rõ cấp độ")

func _on_hover(btn):
	$BotDescription.text = btn.get_meta("desc")
	$BotDescription.visible = true

func _on_unhover():
	$BotDescription.visible = false

func _on_avatar_selected(btn):
	selected_level = btn.get_meta("level")
	$ConfirmButton.disabled = false
	$ConfirmButton.visible = true

func _on_confirm_pressed():
	if selected_level != null:
		print("Đã chọn bot cấp độ:", selected_level)
		bot_selected.emit(selected_level)
