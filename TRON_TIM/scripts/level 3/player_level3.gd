extends CharacterBody2D

@onready var sprite := $AnimatedSprite2D
@onready var footstep_sound: AudioStreamPlayer2D = $FootstepSound
@onready var light = $PointLight2D
@onready var stand_label = $"../UI/StandStillLabel"
@export var speed := 180.0
@export var stand_time_threshold := 5.0  # thời gian chờ (giây)

var is_moving := false
var stand_timer := 0.0
var was_moving := true
var triggered_gameover := false  # đặt ở đầu script

func _physics_process(delta):
	var input_vector = Vector2(
		Input.get_action_strength("walk_right") - Input.get_action_strength("walk_left"),
		Input.get_action_strength("walk_down") - Input.get_action_strength("walk_up")
	)

	velocity = input_vector.normalized() * speed
	move_and_slide()

	is_moving = input_vector.length() > 0.1
	
	if abs(input_vector.x) > abs(input_vector.y):
		if input_vector.x > 0:
			sprite.play("walk_right")
		else:
			sprite.play("walk_left")
	else:
		if input_vector.y > 0:
			sprite.play("walk_down")
		else:
			sprite.play("walk_up")

	if is_moving:
		if not footstep_sound.playing:
			footstep_sound.play()
		
		if not was_moving:
			stand_timer = 0.0
		light.enabled = true  # 💡 bật sáng khi đi
		was_moving = true
		stand_label.visible = false
	else:
		footstep_sound.stop()
		stand_timer += delta
		was_moving = false
		light.enabled = false  # 🌑 tắt khi đứng yên


		var time_left = int(ceil(stand_time_threshold - stand_timer))
		stand_label.text = "Đứng yên: %ss" % time_left
		stand_label.visible = true

	if stand_timer >= stand_time_threshold and not triggered_gameover:
		triggered_gameover = true
		stand_label.text = "🚨 Phát hiện!"
		stand_label.modulate = Color.RED
		print("🚨 Đứng yên quá lâu!")
		get_tree().change_scene_to_file("res://TRON_TIM/scenes/gameover.tscn")

func get_is_moving() -> bool:
	return is_moving
