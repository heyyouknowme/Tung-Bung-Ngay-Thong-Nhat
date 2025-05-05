# scripts/game_manager.gd
extends Node

var board := []  # danh sách 12 slot
var current_player := "left"
var score := {"left": 0, "right": 0}
var selected_index := -1
var quan_eaten := [false, false]  # Quan trái (slot 0), Quan phải (slot 6)
var AIPlayer
var ai_level: String = "easy"  # default nếu không set từ ngoài
var previous_counts := []
@onready var captured_left = get_node("/root/main/Board/CapturedSlotLeft")
@onready var captured_right = get_node("/root/main/Board/CapturedSlotRight")
var game_over := false
var current_selected_slot: Node = null
@onready var sound_drop := $"../Sounds/Sound_DropPiece"
@onready var sound_eat := $"../Sounds/Sound_Eat"
@onready var sound_button := $"../Sounds/Sound_Button"
@onready var turn_notification := $"../CanvasLayer/TurnNotification"
@onready var turn_label := $"../CanvasLayer/TurnNotification/TurnLabel"
@onready var fadetransition := $"../CanvasLayer/ColorRect2"

func _ready():

	ai_level = SceneManager.ai_level
	match ai_level:
		"easy":
			AIPlayer = preload("res://O_AN_QUAN/scripts/ai_player_1.gd").new()
		"medium":
			AIPlayer = preload("res://O_AN_QUAN/scripts/ai_player_2.gd").new()
		"hard":
			AIPlayer = preload("res://O_AN_QUAN/scripts/ai_player_3.gd").new()
	setup_board()

func setup_board():
	var init_data = [
		{"type": "quan", "player": "none", "count": 1},   # Slot 0
		{"type": "dân", "player": "left", "count": 5},    # Slot 1
		{"type": "dân", "player": "left", "count": 5},
		{"type": "dân", "player": "left", "count": 5},
		{"type": "dân", "player": "left", "count": 5},
		{"type": "dân", "player": "left", "count": 5},    # Slot 5
		{"type": "quan", "player": "none", "count": 1},   # Slot 6
		{"type": "dân", "player": "right", "count": 5},
		{"type": "dân", "player": "right", "count": 5},
		{"type": "dân", "player": "right", "count": 5},
		{"type": "dân", "player": "right", "count": 5},   # Slot 10
		{"type": "dân", "player": "right", "count": 5},  # Slot 11
	]
	
	var board_node = get_node("/root/main/Board")

	for i in range(12):
		if i == 0 or i == 6:
			board_node = get_node("/root/main/Board/MainBoard")
		elif i < 6:
			board_node = get_node("/root/main/Board/MainBoard/DanSlot/Left")
		else:
			board_node = get_node("/root/main/Board/MainBoard/DanSlot/Right")
		var slot = board_node.get_node("BoardSlot%d" % i)
		var data = init_data[i]
		slot.set_data(i, data.count, data.type, data.player, (i == 0 and quan_eaten[0]) or (abs(i) == 6 and quan_eaten[1]))
		slot.connect("slot_clicked", Callable(self, "_on_slot_clicked"))
		board.append(slot)
		
	previous_counts = board.map(func(s): return s.count)
	
	show_turn_notification("Lượt của bạn")
	

		
func _on_slot_clicked(index: int):
	sound_button.play()
	var slot = board[index]

	# Nếu có ô cũ đang selected ➔ clear nó
	if current_selected_slot and current_selected_slot != slot:
		current_selected_slot.clear_highlight()

	# Gán ô mới là current
	current_selected_slot = slot

	# Highlight ô mới
	slot.play_click_effect()

	if slot.player != current_player:
		return
	if slot.type == "quan":
		return
	if slot.count <= 0:
		return

	selected_index = index
	show_direction_choice()
	
func show_direction_choice():
	var popup = get_node("/root/main/CanvasLayer/DirectionPopup")
	var viewport_size = get_viewport().get_visible_rect().size

# Canh giữa thủ công
	popup.position = Vector2((viewport_size.x - popup.size.x / 3) / 2, viewport_size.y / 3 * 2)
	popup.show()

func hide_direction_choice():
	var popup = get_node("/root/main/CanvasLayer/DirectionPopup")
	popup.hide()


func start_rain_with_direction(direction: int) -> void:
	if game_over:
		return
	var selected_slot = board[selected_index]
	selected_slot.clear_highlight()
	await handle_rain(selected_index, direction)
	if game_over:
		return
	update_board()
	switch_turn()
	
func handle_rain(start_index: int, direction: int):
	var i = start_index

	while true:
		var count = board[i].count
		board[i].count = 0
		update_board()
		await get_tree().create_timer(0.5).timeout  # Delay trước khi rải

		# Rải từng quân một
		while count > 0:
			i = (i + direction) % 12
			board[i].count += 1
			board[i].highlight_pass()
			sound_drop.play()
			update_board()
			await get_tree().create_timer(0.5).timeout
			count -= 1

		var next = (i + direction) % 12
		if board[next].count == 0:
			await get_tree().create_timer(0.5).timeout
			await try_eat(i, direction)
			break
		elif board[next].count > 0 and board[next].type == "dân":
			i = next
			await get_tree().create_timer(0.5).timeout
		else:
			break

func try_eat(last_index: int, direction: int):
	var next = (last_index + direction) % 12
	var next_slot = board[next]
	
	if next_slot.count == 0:
		
		var eat_index = (next + direction) % 12
		var eat_slot = board[eat_index]
		var capture_slot_path
		if(current_player == "left"):
			capture_slot_path  = "/root/main/Board/CapturedSlotLeft" 
		else:
			capture_slot_path = "/root/main/Board/CapturedSlotRight"
		var capture_slot_node = get_node(capture_slot_path)
		
		if eat_slot.count > 0:
			
			if eat_slot.type == "quan":
				var quan_index = -1
				if eat_index == 0:
					quan_index = 0
				elif abs(eat_index) == 6:
					quan_index = 1
					 
				if quan_index != -1:
					
					if not quan_eaten[quan_index]:
						if eat_slot.count < 6:
							return  # ❌ Không đủ điều kiện ăn Quan
						else:
							# ✅ Ăn Quan hợp lệ
							sound_eat.play()
							eat_slot.highlight_pass()
							
							eat_slot.animate_capture(capture_slot_node.global_position)
							await get_tree().create_timer(0.5).timeout
							add_to_captured_slot(current_player, eat_index, eat_slot.count, eat_slot.type)
							quan_eaten[quan_index] = true
							eat_slot.quan_eaten = true
							score[current_player] += 5
							score[current_player] += eat_slot.count - 1
							board[eat_index].count = 0
							
							update_board()
							await try_eat(eat_index, direction)  # Đệ quy ăn tiếp
					else:
						sound_eat.play()
						eat_slot.highlight_pass()
						
						eat_slot.animate_capture(capture_slot_node.global_position)
						await get_tree().create_timer(0.5).timeout
						add_to_captured_slot(current_player, eat_index, eat_slot.count, eat_slot.type)
						score[current_player] += eat_slot.count
						board[eat_index].count = 0
						update_board()
						await try_eat(eat_index, direction)  # Đệ quy ăn tiếp
			else:
			# 🟢 Ăn phần còn lại (dân hoặc quân còn lại sau khi ăn Quan)
				sound_eat.play()
				eat_slot.highlight_pass()
				eat_slot.animate_capture(capture_slot_node.global_position)
				await get_tree().create_timer(0.5).timeout
				add_to_captured_slot(current_player, eat_index, eat_slot.count, eat_slot.type)
				score[current_player] += eat_slot.count
				board[eat_index].count = 0
				update_board()
				await try_eat(eat_index, direction)  # Đệ quy ăn tiếp


func add_to_captured_slot(player: String, slot_index: int, count: int, type: String):
	var target_slot = captured_left if(player == "left") else captured_right
	var quan_index = 0 if(slot_index == 0) else 1
	
	if type == "quan" and !quan_eaten[quan_index]:
		if count >= 1:
			target_slot.add_piece("quan",  "red" if(slot_index == 0) else "green")
		for i in range(count - 1):
			target_slot.add_piece("dân")
	else:
		for i in range(count):
			target_slot.add_piece("dân")

			
func switch_turn():
	if game_over:
		return
	current_player = "right" if current_player == "left" else "left"
	
	if check_game_over():
		return
	
	if has_no_dan_quan(current_player):
		await regenerate_dan(current_player)
	
	
	if current_player == "right":
		show_turn_notification("Lượt của máy")
		await get_tree().create_timer(1.5).timeout
		var ai_move = AIPlayer.get_ai_best_move(board, score, quan_eaten)
		if ai_move["index"] != -1:
			selected_index = ai_move["index"]
			await start_rain_with_direction(ai_move["direction"])
	else: 
		show_turn_notification("Lượt của bạn")
		

func show_turn_notification(text: String):
	turn_label.text = text
	turn_notification.visible = true
	# Ẩn sau 1.5 giây cho đẹp
	await get_tree().create_timer(1.5).timeout
	turn_notification.visible = false
	
	
func update_board():
	update_score_display()
	
	for i in range(board.size()):
		var slot = board[i]

		# Lần đầu chưa có previous_counts, thì update tất cả
		if previous_counts.size() != board.size() or previous_counts[i] != slot.count:
			slot.update_display()
	# Cập nhật lại mảng count sau mỗi lượt
	previous_counts = board.map(func(s): return s.count)

func check_game_over():
	var quan_left = board[0].count
	var quan_right = board[6].count
	
	if quan_left == 0 and quan_right == 0:
		game_over = true
		collect_remaining_quan()
		update_board()
		show_end_game()
		return true  # 🛑 Đã kết thúc
	return false  # ✅ Chưa kết thúc

		

func show_end_game():
	SceneManager.player_score = score["left"]
	SceneManager.ai_score = score["right"]
	await fadetransition.transition_to_scene("res://O_AN_QUAN/scenes/EndGame.tscn", 0.5)

	
func has_no_dan_quan(player: String) -> bool:
	if player == "left":
		for i in range(1, 6):
			if board[i].count > 0:
				return false
	elif player == "right":
		for i in range(7, 12):
			if board[i].count > 0:
				return false
	return true

func regenerate_dan(player: String) -> void:
	
	var cost = 5
	if score[player] < cost:
		
		print("⚠️ Người chơi %s không đủ điểm để cấy lại quân. Trò chơi kết thúc!" % player)
		game_over = true
		collect_remaining_quan()
		show_end_game()
		return
	if game_over:
		return
		
	score[player] -= cost
	
	if player == "left":
		for i in range(1, 6):
			sound_drop.play()
			await get_tree().create_timer(0.5).timeout
			board[i].count = 1
			update_board()
	elif player == "right":
		for i in range(7, 12):
			sound_drop.play()
			await get_tree().create_timer(0.5).timeout
			board[i].count = 1
			update_board()

	update_board()

func collect_remaining_quan():
	for i in range(1, 6):
		await get_tree().create_timer(0.5).timeout
		add_to_captured_slot("left", i, board[i].count, board[i].type)
		score["left"] += board[i].count
		board[i].count = 0
	for i in range(7, 12):
		await get_tree().create_timer(0.5).timeout
		add_to_captured_slot("right", i, board[i].count, board[i].type)
		score["right"] += board[i].count
		board[i].count = 0

func update_score_display():
	get_node("/root/main/CanvasLayer/LeftScoreLabel").text = "Điểm của bạn: %d" % score["left"]
	get_node("/root/main/CanvasLayer/RightScoreLabel").text = "Điểm của máy: %d" % score["right"]

func _on_left_button_pressed() -> void:
	sound_button.play()
	hide_direction_choice()
	var direction = -1 if current_player == "left" else 1
	start_rain_with_direction(direction)

func _on_right_button_pressed() -> void:
	sound_button.play()
	hide_direction_choice()
	var direction = 1 if current_player == "left" else -1
	start_rain_with_direction(direction)
