extends Area2D

@export var player_path: NodePath
@export var countdown_label: Label

@onready var player = get_node(player_path)

var countdown_time := 3.0
var countdown_timer: Timer

func _ready():
	countdown_timer = Timer.new()
	countdown_timer.wait_time = 1.0
	countdown_timer.one_shot = false
	add_child(countdown_timer)

	countdown_timer.timeout.connect(_on_timer_tick)

	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

	if countdown_label:
		countdown_label.visible = false
	else:
		push_error("❌ countdown_label chưa được gán!")

func _on_body_entered(body):
	if body == player:
		countdown_time = 3.0
		countdown_label.text = str(int(countdown_time))
		countdown_label.visible = true
		countdown_timer.start()

func _on_body_exited(body):
	if body == player:
		countdown_timer.stop()
		countdown_label.visible = false

func _on_timer_tick():
	countdown_time -= 1.0
	if countdown_time <= 0:
		countdown_timer.stop()
		countdown_label.visible = false
		get_tree().change_scene_to_file("res://TRON_TIM/scenes/gameover.tscn")
	else:
		countdown_label.text = str(int(countdown_time))
