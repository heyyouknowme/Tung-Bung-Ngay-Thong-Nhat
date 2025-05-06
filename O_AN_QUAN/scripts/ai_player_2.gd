extends Node

var MAX_DEPTH: int = 3

# Cấu trúc mô phỏng board state
class SimState:
	var board = []
	var score = {}
	var quan_eaten = []
	var current_player = ""

	func _init(_board, _score, _quan_eaten, _current_player):
		board = []
		for slot in _board:
			board.append({"count": slot.count, "type": slot.type, "player": slot.player})
		
		score = {"left": _score["left"], "right": _score["right"]}
		quan_eaten = [_quan_eaten[0], _quan_eaten[1]]
		current_player = _current_player

		self.score = score
		self.quan_eaten = quan_eaten
		self.current_player = current_player

# Hàm chính để gọi từ game_manager
func get_ai_best_move(board, score, quan_eaten) -> Dictionary:
	var best_move = {"index": -1, "direction": 1}
	var best_value = -INF

	for i in range(7, 12):
		if board[i].count > 0 and board[i].type == "dân":
			for direction in [-1, 1]:
				var state = SimState.new(board, score, quan_eaten, "right")
				var next_state = simulate_move(state, i, direction)
				var value = minimax(next_state, MAX_DEPTH - 1, false, -INF, INF)
				if value > best_value:
					best_value = value
					best_move = {"index": i, "direction": direction}
	#print("Best value with alpha-beta: ", best_value) 
	return best_move


func minimax(state: SimState, depth: int, is_maximizing: bool, alpha: float = -INF, beta: float = INF) -> float:
	if depth == 0 or is_terminal(state):
		return evaluate(state)

	var best = -INF if is_maximizing else INF
	var found_valid_move = false

	var player = state.current_player
	var next_player = "left" if player == "right" else "right"

	if has_no_dan_quan_sim(state, player):
		regenerate_dan_sim(state, player)

	var start = 1 if player == "left" else 7
	var end = 6 if player == "left" else 12

	for i in range(start, end):
		if state.board[i]["count"] > 0 and state.board[i]["type"] == "dân":
			for direction in [-1, 1]:
				found_valid_move = true
				var child = simulate_move(SimState.new(state.board, state.score, state.quan_eaten, player), i, direction)
				child.current_player = next_player
				var val = minimax(child, depth - 1, not is_maximizing, alpha, beta)

				if is_maximizing:
					best = max(best, val)
					alpha = max(alpha, best)
				else:
					best = min(best, val)
					beta = min(beta, best)

				# Alpha-Beta pruning
				if beta <= alpha:
					break
			if beta <= alpha:
				break

	if not found_valid_move:
		return evaluate(state)
		
	#print(best)
	return best



func is_terminal(state: SimState) -> bool:
	return state.board[0]["count"] == 0 and state.board[6]["count"] == 0

func evaluate(state: SimState) -> int:
	return state.score["right"] - state.score["left"]

# Giả lập 1 lượt đi (rải + ăn) theo hướng
func simulate_move(state: SimState, index: int, direction: int) -> SimState:
	var i = index
	var count = state.board[i]["count"]
	state.board[i]["count"] = 0
	
	# Rải quân
	while true:
		# Rải từng quân một
		while count > 0:
			i = (i + direction) % 12
			state.board[i]["count"] += 1
			count -= 1

		# Sau khi rải xong, kiểm tra ô kế tiếp
		var next = (i + direction) % 12

		if state.board[next]["count"] > 0 and state.board[next]["type"] == "dân":
			# Rải tiếp từ ô đó
			i = next
			count = state.board[i]["count"]
			state.board[i]["count"] = 0
			continue
		else:
			# Dừng rải → bắt đầu xét ăn
			break

	var next = (i + direction) % 12

	# Thử ăn liên tiếp
	while true:
		if state.board[next]["count"] == 0:
			var eat_index = (next + direction) % 12
			var eat_slot = state.board[eat_index]

			if eat_slot["count"] > 0:
				# Kiểm tra ăn Quan
				if eat_slot["type"] == "quan":
					var q_index := -1
					if eat_index == 0:
						q_index = 0
					elif abs(eat_index) == 6:
						q_index = 1

					if q_index != -1:
						var total_before = eat_slot["count"]
						if not state.quan_eaten[q_index]:
							if total_before < 6:
								break  # Không đủ điều kiện ăn Quan
							else:
								# Ăn Quan hợp lệ
								state.quan_eaten[q_index] = true
								state.score[state.current_player] += 5
								state.score[state.current_player] += eat_slot["count"] - 1
								state.board[eat_index]["count"] = 0
								next = (eat_index + direction) % 12
						else:
							state.score[state.current_player] += eat_slot["count"]
							state.board[eat_index]["count"] = 0
							next = (eat_index + direction) % 12
					else:
						break

				else:
					state.score[state.current_player] += eat_slot["count"]
					state.board[eat_index]["count"] = 0
					next = (eat_index + direction) % 12
				
			else:
				break
		else:
			break

	return state
	
func regenerate_dan_sim(state: SimState, player: String) -> void:
	if state.score[player] < 5:
		# Không đủ điểm để cấy → kết thúc game
		return

	state.score[player] -= 5

	if player == "left":
		for i in range(1, 6):
			state.board[i]["count"] = 1
	elif player == "right":
		for i in range(7, 12):
			state.board[i]["count"] = 1
			
func has_no_dan_quan_sim(state: SimState, player: String) -> bool:
	if player == "left":
		for i in range(1, 6):
			if state.board[i]["count"] > 0:
				return false
	elif player == "right":
		for i in range(7, 12):
			if state.board[i]["count"] > 0:
				return false
	return true
