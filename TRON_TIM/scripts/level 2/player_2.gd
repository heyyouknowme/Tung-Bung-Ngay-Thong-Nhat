extends CharacterBody2D

@export var speed := 120.0

@onready var sprite := $AnimatedSprite2D
@onready var footstep_sound: AudioStreamPlayer2D = $FootstepSound
var is_walking := false

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("walk_right") - Input.get_action_strength("walk_left")
	input_vector.y = Input.get_action_strength("walk_down") - Input.get_action_strength("walk_up")
	input_vector = input_vector.normalized()

	velocity = input_vector * speed
	move_and_slide()

	if input_vector != Vector2.ZERO:
		if not footstep_sound.playing:
			footstep_sound.play()
		
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
	else:
		sprite.stop()
		footstep_sound.stop()
