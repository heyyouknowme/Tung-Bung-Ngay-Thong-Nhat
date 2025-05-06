extends CharacterBody3D

@export var speed: float = 15.0
@export var run_multiplier: float = 1.5
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 30.0

@export var camera: Camera3D
@export var sprite: AnimatedSprite3D
@export var skins: Array[SpriteFrames]  # Assign skin animations in Inspector

@export var pause_menu_path: NodePath  # Drag your PauseMenu node here
@onready var pause_menu := get_node(pause_menu_path)

var yaw: float = 0.0
var pitch: float = 0.0
var last_direction := "front"
var can_move: bool = true  # Toggle movement externally (dialogues, etc.)

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Apply selected skin
	var index = GameData.selected_skin_index
	if index < skins.size():
		sprite.frames = skins[index]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:

		if event.keycode == KEY_TAB:
			if event.pressed:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


	if not can_move:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -1.2, 1.2)

		camera.rotation.x = pitch
		rotation.y = yaw

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y -= gravity * delta
		move_and_slide()
		return

	var input_vec = Vector2.ZERO

	if Input.is_action_pressed("walk_up"):
		input_vec.y -= 1
	if Input.is_action_pressed("walk_down"):
		input_vec.y += 1
	if Input.is_action_pressed("walk_left"):
		input_vec.x -= 1
	if Input.is_action_pressed("walk_right"):
		input_vec.x += 1

	input_vec = input_vec.normalized()

	var cam_x = camera.global_transform.basis.x
	var cam_z = camera.global_transform.basis.z
	var move_dir = (cam_x * input_vec.x + cam_z * input_vec.y).normalized()

	var current_speed = speed
	if Input.is_action_pressed("run"):
		current_speed *= run_multiplier

	velocity.x = move_dir.x * current_speed
	velocity.z = move_dir.z * current_speed
	velocity.y -= gravity * delta
	move_and_slide()

	if move_dir.length() > 0.01:
		sprite.rotation.y = facing_rotation_towards(move_dir)

	# Animations
	if input_vec.length() > 0.1:
		var angle = rad_to_deg(atan2(input_vec.x, input_vec.y))
		var anim_dir = ""
		if angle >= -45 and angle < 45:
			anim_dir = "front"
		elif angle >= 45 and angle < 135:
			anim_dir = "right"
		elif angle >= -135 and angle < -45:
			anim_dir = "left"
		else:
			anim_dir = "back"

		var walk_anim = "Walk_" + anim_dir
		if sprite.animation != walk_anim:
			sprite.play(walk_anim)
		last_direction = anim_dir
	else:
		var idle_anim = "Idle_" + last_direction
		if sprite.animation != idle_anim:
			sprite.play(idle_anim)

func facing_rotation_towards(direction: Vector3) -> float:
	return atan2(direction.x, direction.z)
