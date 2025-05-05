extends Control

@onready var bar = $ProgressBar
@onready var label = $StatusLabel
@onready var timer = $Timer

var progress := 0

func _ready():
	progress = 0
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 0

	timer.wait_time = 0.05
	timer.start()

func _on_Timer_timeout():
	if progress < 100:
		progress += 1
		bar.value = progress
		label.text = get_random_text()
	else:
		timer.stop()
		label.text = "✅ Đã tải xong, chuẩn bị vào trò chơi..."
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file("res://scenes/Main.tscn")

func get_random_text() -> String:
	var lines = [
		"🌾 Trải chiếu tre...",
		"🥁 Gõ trống làng...",
		"🎐 Treo đèn lồng...",
		"🔮 Niệm chú triệu hồi bàn cờ...",
		"🧠 Gọi AI trợ giúp..."
	]
	return lines[randi() % lines.size()]
