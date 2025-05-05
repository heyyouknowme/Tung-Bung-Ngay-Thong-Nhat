extends CanvasLayer

@onready var timer_label = $LevelTimerLabel
@onready var level_timer = $LevelTimer
@onready var timeout_sound = $"../CountDownSound"  
@onready var reng_sound = $"../RengSound"  

var time_left := 30  # thời gian level 3
var on_level_win : Callable = func(): pass

func _ready():
	timer_label.text = str(time_left)
	level_timer.timeout.connect(_on_timer_tick)
	level_timer.start()  # ← Bắt đầu đếm
	
	# Đảm bảo Global biết cấp độ hiện tại
	Global.current_level = self
	Global.current_level_num = 3  # tùy level
	
	# Kết nối UI với hệ thống mở khóa
	var ui_node = self  # Điều chỉnh đường dẫn nếu cần
	if ui_node and ui_node.has_method("_on_level_complete"):
		ui_node.on_level_win = Global._on_level_win

func _on_timer_tick():
	time_left -= 1
	timer_label.text = str(time_left)
	
	if time_left <= 3:
		timeout_sound.play()
		
	if time_left == 1:
		reng_sound.play()
	
	if time_left < 0:
		level_timer.stop()
		_on_level_complete()

func _on_level_complete():
	level_timer.stop()
	if on_level_win:
		on_level_win.call()  # Gọi callback từ Global
