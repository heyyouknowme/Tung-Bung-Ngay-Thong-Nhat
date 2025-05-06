extends Control

# --- Game state ---
var score: int = 0
var time_left: int = 20
var session_id: String = "default"
var used_words: Array = []
var current_word: String = ""  # Store the actual word separately from display text

# --- UI References ---
@onready var score_label: Label = $MainLayout/ScoreTimerBox/ScoreLabel
@onready var time_label: Label = $MainLayout/ScoreTimerBox/TimeLabel
@onready var current_word_label: Label = $MainLayout/CurrentWordContainer/CurrentWordLabel
@onready var word_input: LineEdit = $MainLayout/InputBar/InputField
@onready var submit_button: Button = $MainLayout/InputBar/SubmitButton
@onready var timer: Timer = $Timer
@onready var toast_label = $MainLayout/ToastContainer/ToastLabel

# --- API URL & callback ---
const SERVER_URL := GameData.api_url

# --- API request & callback ---
@onready var api: HTTPRequest = $APIRequest
var last_callback: Callable

# --- AudioPlayer ---
@onready var music_player = $MusicPlayer
@onready var ding_player = $SFXContainer/DingPlayer
@onready var wrong_player = $SFXContainer/WrongPlayer
@onready var timeout_player = $SFXContainer/TimeoutPlayer

func _ready():
	word_input.focus_mode = Control.FOCUS_ALL

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	timer.wait_time = 1.0
	timer.timeout.connect(_on_timer_tick)
	word_input.text_submitted.connect(_on_word_submitted)
	submit_button.pressed.connect(_on_word_submitted.bind(word_input.text))
	word_input.grab_focus()
	start_new_game()

func api_call(path: String, body: Variant, callback: Callable):
	last_callback = callback  # Lưu lại để gọi sau khi có kết quả

	var headers = ["Content-Type: application/json"]
	var json_data = JSON.stringify(body)
	var method = HTTPClient.METHOD_GET
	var payload := ""

	if body != {}:
		method = HTTPClient.METHOD_POST
		payload = json_data

	api.request(SERVER_URL + path, headers, method, payload)
	api.request_completed.connect(_on_api_response, CONNECT_ONE_SHOT)

func _on_api_response(result, code, headers, body):
	if code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json:
			last_callback.call(json)
	else:
		game_over("💥 Lỗi kết nối server (%d)" % code)

func start_new_game():
	score = 0
	time_left = 20
	used_words.clear()
	update_ui()

	print("🔄 Đang tạo phiên chơi mới...")
	current_word_label.text = "🔄 Đang tạo phiên chơi mới..."
	
	api_call("/game/start", {}, func(result):
		if result.has("session_id"):
			session_id = result.session_id
			print("✅ Đã tạo session mới: %s" % session_id)
			api_call("/game/new_word", {"session_id": session_id}, func(res):
				if res.has("answer"):
					current_word = res.answer
					current_word_label.text = "Từ hiện tại: " + current_word
					timer.start()
					update_ui()
				else:
					wrong_player.play()
					game_over("❌ Không lấy được từ bắt đầu.")
			)
		else:
			wrong_player.play()
			game_over("❌ Phản hồi không hợp lệ từ /start_game")
	)

func is_word_used(word: String) -> bool:
	return word.strip_edges().to_lower() in used_words

func _on_word_submitted(user_word: String):
	if user_word.strip_edges() == "":
		return
	
	user_word = user_word.strip_edges().to_lower()
	word_input.editable = false
	submit_button.disabled = true

	# Check if word is already used
	if is_word_used(user_word):
		wrong_player.play()
		show_toast("❌ Từ này đã được sử dụng!")
		word_input.clear()
		word_input.editable = true
		submit_button.disabled = false
		return
	
	# 1. Validate luật nối từ trước (client-side)
	if not validate_pair(current_word, user_word):
		wrong_player.play()
		game_over("❌ Không đúng luật nối từ!")
		return
	
	# 2. Gửi đến /word/validate (server-side)
	var data = { "word": user_word }
	api_call("/word/validate", data, _on_validate_response)

func _on_validate_response(result):
	if result.valid:
		score += 10
		time_left = 20
		timer.stop()
		used_words.append(word_input.text)
		current_word_label.text = "⏳ Đợi bot..."
		
		# Gửi đến /ask để bot phản hồi
		var data = {
			"prompt": word_input.text,
			"session_id": session_id
		}
		word_input.clear()
		ding_player.play()
		api_call("/ask", data, _on_ask_responded)
	else:
		wrong_player.play()
		game_over("❌ " + result.reason)

func _on_ask_responded(result):
	var status = result.status
	var answer = result.answer
	
	if status == 'error':
		game_over("❌ " + answer)
	elif status == 'unfound':
		var bonus_points = 50
		score += bonus_points
		show_toast("🎉 +%d điểm! Bot không tìm được từ phù hợp" % bonus_points)
		ding_player.play()
		
		update_ui()
		word_input.editable = false
		submit_button.disabled = true

		current_word_label.text = "🔄 Đang lấy từ mới..."
		api_call("/game/new_word", {"session_id": session_id}, func(res):
			if res.has("answer"):
				current_word = res.answer
				current_word_label.text = "Từ hiện tại: " + current_word
				used_words.append(current_word)
				time_left = 20
				timer.start()
				word_input.editable = true
				submit_button.disabled = false
			else:
				wrong_player.play()
				game_over("❌ Không lấy được từ mới.")
		)
	else:
		current_word = answer
		current_word_label.text = "Từ hiện tại: " + current_word
		used_words.append(current_word)
		time_left = 20
		timer.start()
		word_input.editable = true
		submit_button.disabled = false
		
func update_ui():
	score_label.text = "Điểm: %d" % score
	time_label.text = "Thời gian: %d" % time_left

func game_over(reason: String):
	show_toast(reason)
	print(reason)
	timer.stop()
	word_input.editable = false
	submit_button.disabled = true
	await get_tree().create_timer(3.0).timeout
	get_tree().paused = true
	
	# Load và add game_over scene
	var game_over_scene = preload("res://NOI_CHU/scenes/game_over.tscn").instantiate()
	add_child(game_over_scene)

	# Hiện chuột lên (nếu bị bắt trước đó)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func _on_timer_tick():
	time_left -= 1
	update_ui()
	if time_left <= 0:
		timeout_player.play()
		game_over("⏰ Hết giờ!")

func validate_pair(word1: String, word2: String) -> bool:
	var w1 = word1.strip_edges().split(" ")
	var w2 = word2.strip_edges().split(" ")
	return w1.size() > 0 and w2.size() > 0 and w1[-1].to_lower() == w2[0].to_lower()

func show_toast(message: String):
	toast_label.show_message(message)
