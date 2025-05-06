# ✅ Bổ sung các logic từ Main.gd để cập nhật lại các hàm phụ trợ then chốt
# File: bot_logic.gd (bổ sung và sửa chuẩn hơn theo Main.gd logic)
extends Object

const INF = 99999

var difficulty_level := 5 
var difficulty_config = {
	1: { "depth": 1, "use_alphabeta": false },
	2: { "depth": 2, "use_alphabeta": false },
	3: { "depth": 3, "use_alphabeta": true },
	4: { "depth": 4, "use_alphabeta": true },
	5: { "depth": 4, "use_alphabeta": true }
}

var valid_moves: Dictionary = {}

func is_cell_empty(board: Array, pos: Vector2i) -> bool:
	for piece in board:
		if piece.pos == pos:
			return false
	return true

func get_piece_at(board: Array, pos: Vector2i) -> Dictionary:
	for piece in board:
		if piece.pos == pos:
			return piece
	return {}

func update_valid_moves():
	valid_moves.clear()
	for x in range(5):
		for y in range(5):
			var pos = Vector2i(x, y)
			valid_moves[pos] = []
			var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
			for dir in directions:
				var target = pos + dir
				if target.x >= 0 and target.x < 5 and target.y >= 0 and target.y < 5:
					valid_moves[pos].append(target)

	var edges = [
		[[0, 0], [1, 1]], [[1, 1], [2, 2]], [[2, 2], [3, 3]], [[3, 3], [4, 4]],
		[[0, 4], [1, 3]], [[1, 3], [2, 2]], [[2, 2], [3, 1]], [[3, 1], [4, 0]],
		[[0, 2], [1, 1]], [[0, 2], [1, 3]], [[1, 1], [2, 0]], [[2, 0], [3, 1]],
		[[3, 1], [4, 2]], [[4, 2], [3, 3]], [[3, 3], [2, 4]], [[2, 4], [1, 3]]
	]
	for pair in edges:
		var a = Vector2i(pair[0][0], pair[0][1])
		var b = Vector2i(pair[1][0], pair[1][1])
		if a in valid_moves:
			valid_moves[a].append(b)
		if b in valid_moves:
			valid_moves[b].append(a)

func get_move_count(board: Array, pos: Vector2i) -> int:
	if not valid_moves.has(pos):
		return 0
	var count = 0
	for target in valid_moves[pos]:
		if is_cell_empty(board, target):
			count += 1
	return count

func count_ganh_directions(board: Array, center: Vector2i, phe: String) -> int:
	update_valid_moves()
	var count = 0
	var opposite = ""
	if phe == "Lua":
		opposite = "Nuoc"
	else:
		opposite = "Lua"
	var dirs = [Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), Vector2i(1,-1)]
	for dir in dirs:
		var l = center - dir
		var r = center + dir
		if not (valid_moves.has(l) and valid_moves[l].has(center) and valid_moves.has(r) and valid_moves[r].has(center)):
			continue
		var pl = get_piece_at(board, l)
		var pr = get_piece_at(board, r)
		if pl != {} and pr != {} and pl.has("phe") and pr.has("phe") and pl.phe == opposite and pr.phe == opposite:
			count += 1
	return count

func check_vay(board: Array, phe_di: String) -> Dictionary:
	update_valid_moves()
	var phe_bi_vay = ""
	if phe_di == "Lua":
		phe_bi_vay = "Nuoc"
	else:
		phe_bi_vay = "Lua"
	var count_locked = 0
	var contributors = {}
	for piece in board:
		if piece.phe != phe_bi_vay:
			continue
		var pos = piece.pos
		var neighbors = valid_moves.get(pos, [])
		var has_escape = false
		var count_enemy = 0
		var count_friend = 0
		for n in neighbors:
			if is_cell_empty(board, n):
				has_escape = true
				break
			var other = get_piece_at(board, n)
			if other == null:
				continue
			if other.phe == phe_bi_vay:
				count_friend += 1
			elif other.phe == phe_di:
				count_enemy += 1
				contributors[n] = true
		if not has_escape and count_enemy > count_friend:
			count_locked += 1
	return {
		"enemy_locked": count_locked,
		"our_needed_to_vay": contributors.size()
	}

func get_all_moves(board_data: Array, valid_moves: Dictionary, phe: String) -> Array:
	var moves = []
	for piece in board_data:
		if piece.get("phe", "") != phe:
			continue
		var from_pos = piece.get("pos", Vector2i(-1, -1))
		if not valid_moves.has(from_pos):
			continue
		for to_pos in valid_moves[from_pos]:
			if is_cell_empty(board_data, to_pos):
				moves.append({"from": from_pos, "to": to_pos})
	return moves

func clone_board(board: Array) -> Array:
	var result = []
	for p in board:
		result.append({"pos": p.pos, "phe": p.phe})
	return result

func simulate_move(board: Array, move: Dictionary, phe: String) -> Dictionary:
	var clone = clone_board(board)
	var piece = get_piece_at(clone, move.from)
	var before = get_move_count(clone, move.from)
	piece.pos = move.to
	var after = get_move_count(clone, move.to)
	var ganh_count = count_ganh_directions(clone, move.to, phe)
	var vay_info = check_vay(clone, phe)
	return {
		"board": clone,
		"before_moves": before,
		"after_moves": after,
		"did_ganh": ganh_count > 0,
		"ganh_count": ganh_count,
		"enemy_locked": vay_info.enemy_locked,
		"our_needed_to_vay": vay_info.our_needed_to_vay,
		"empty_symmetry_count": 0,
		"phe_bot": phe
	}

func evaluate_state(simulated: Dictionary) -> int:
	var score = 0
	score += simulated.after_moves - simulated.before_moves
	score += 10 * simulated.ganh_count
	score += 8 * simulated.enemy_locked
	score -= 10 * simulated.empty_symmetry_count
	return score

func minimax(board: Array, valid_moves: Dictionary, depth: int, maximizing: bool, phe_bot: String) -> int:
	if depth == 0:
		return evaluate_state({
			"before_moves": 0,
			"after_moves": 0,
			"did_ganh": false,
			"ganh_count": 0,
			"enemy_locked": 0,
			"our_needed_to_vay": 0,
			"empty_symmetry_count": 0,
			"phe_bot": phe_bot
		})

	var phe = ""
	if maximizing:
		phe = phe_bot
	else:
		if phe_bot == "Lua":
			phe = "Nuoc"
		else:
			phe = "Lua"

	var moves = get_all_moves(board, valid_moves, phe)
	if maximizing:
		var max_eval = -INF
		for move in moves:
			var result = simulate_move(board, move, phe)
			var eval = minimax(result.board, valid_moves, depth - 1, false, phe_bot)
			eval += evaluate_state(result)
			max_eval = max(max_eval, eval)
		return max_eval
	else:
		var min_eval = INF
		for move in moves:
			var result = simulate_move(board, move, phe)
			var eval = minimax(result.board, valid_moves, depth - 1, true, phe_bot)
			eval += evaluate_state(result)
			min_eval = min(min_eval, eval)
		return min_eval

func alphabeta(board: Array, valid_moves: Dictionary, depth: int, alpha: int, beta: int, maximizing: bool, phe_bot: String) -> int:
	if depth == 0:
		return evaluate_state({
			"before_moves": 0,
			"after_moves": 0,
			"did_ganh": false,
			"ganh_count": 0,
			"enemy_locked": 0,
			"our_needed_to_vay": 0,
			"empty_symmetry_count": 0,
			"phe_bot": phe_bot
		})

	var phe = ""
	if maximizing:
		phe = phe_bot
	else:
		if phe_bot == "Lua":
			phe = "Nuoc"
		else:
			phe = "Lua"

	var moves = get_all_moves(board, valid_moves, phe)
	if maximizing:
		var value = -INF
		for move in moves:
			var result = simulate_move(board, move, phe)
			var score = alphabeta(result.board, valid_moves, depth - 1, alpha, beta, false, phe_bot)
			score += evaluate_state(result)
			value = max(value, score)
			alpha = max(alpha, value)
			if alpha >= beta:
				break
		return value
	else:
		var value = INF
		for move in moves:
			var result = simulate_move(board, move, phe)
			var score = alphabeta(result.board, valid_moves, depth - 1, alpha, beta, true, phe_bot)
			score += evaluate_state(result)
			value = min(value, score)
			beta = min(beta, value)
			if beta <= alpha:
				break
		return value

func get_best_move(board_data: Array, valid_moves_input: Dictionary, phe_bot: String) -> Dictionary:
	update_valid_moves()
	valid_moves = valid_moves_input

	var config = difficulty_config.get(difficulty_level, difficulty_config[1])
	var depth = config["depth"]
	var use_ab = config["use_alphabeta"]

	var moves = get_all_moves(board_data, valid_moves, phe_bot)
	var best_score = -INF
	var best_move = {}

	for move in moves:
		var simulated = simulate_move(board_data, move, phe_bot)
		var score = 0
		if use_ab:
			score = alphabeta(simulated.board, valid_moves, depth - 1, -INF, INF, false, phe_bot)
		else:
			score = minimax(simulated.board, valid_moves, depth - 1, false, phe_bot)
		score += evaluate_state(simulated)

		if score > best_score:
			best_score = score
			best_move = move

	return best_move
