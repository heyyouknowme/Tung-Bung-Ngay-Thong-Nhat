extends Control
@onready var fadetransition := $"ColorRect2"

func _ready():
	# Gọi set_result ngay khi scene vừa load, dùng dữ liệu từ Singleton
	set_result(SceneManager.player_score, SceneManager.ai_score, SceneManager.ai_level) 

func set_result(player_score: int, ai_score: int, level_chosen: String):
	var bg = $BackgroundRect
	var result_label = $VBoxContainer/ResultLabel
	var player_score_label = $VBoxContainer/PlayerScoreLabel
	var ai_score_label = $VBoxContainer/AIScoreLabel
	
	player_score_label.text = "Điểm của bạn: %d" % player_score
	ai_score_label.text = "Điểm của máy: %d" % ai_score

	if player_score > ai_score:
		$Sound_Win.play()
		result_label.text = "Chiến Thắng"
		bg.texture = preload("res://O_AN_QUAN/assets/bg_win.png")
		
	elif player_score < ai_score:
		$Sound_Lose.play()
		result_label.text = "Thất Bại"
		bg.texture = preload("res://O_AN_QUAN/assets/bg_lose.png")
	else:
		$Sound_Draw.play()
		result_label.text = "Ngang Tài"
		bg.texture = preload("res://O_AN_QUAN/assets/bg_draw.png")

func _on_retry_button_pressed():
	$Sound_Button.play() 
	await fadetransition.transition_to_scene("res://O_AN_QUAN/scenes/main.tscn", 0.5)

func _on_back_button_pressed():
	$Sound_Button.play()
	await fadetransition.transition_to_scene("res://O_AN_QUAN/scenes/SelectLevel.tscn", 0.5)
