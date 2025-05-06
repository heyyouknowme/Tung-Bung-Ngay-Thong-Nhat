extends CharacterBody3D

@onready var npc_sprite: Sprite3D = $Sprite3D
@onready var npc_animation: AnimatedSprite3D = $AnimatedSprite3D
@onready var npc_animation_2: AnimatedSprite3D = $AnimatedSprite3D2
@onready var detection_area: Area3D = $Area3D
@onready var dialogue_box: Control = $DialoguePanel  # Adjust path if needed

var is_player_inside: bool = false
var just_closed: bool = false  # Short cooldown after dialogue ends
@export var input_file: String
var dialogue_file_path: String

func _ready():
	dialogue_file_path = "res://MAIN/dialogues/" + input_file

	detection_area.body_entered.connect(_on_Area3D_body_entered)
	detection_area.body_exited.connect(_on_Area3D_body_exited)

	# ✅ Connect the signal emitted when dialogue finishes (No or ESC)
	if dialogue_box and dialogue_box.has_signal("dialogue_closed"):
		dialogue_box.dialogue_closed.connect(_on_dialogue_closed)

func _on_Area3D_body_entered(body: Node):
	if body.is_in_group("player"):
		is_player_inside = true
		show_sprite()

func _on_Area3D_body_exited(body: Node):
	if body.is_in_group("player"):
		is_player_inside = false
		hide_sprite()
		dialogue_box.finish()
		# Reset cooldown when player leaves
		GameData.dialogue_cooldown = false

func show_sprite():
	npc_sprite.visible = true

func hide_sprite():
	npc_sprite.visible = false

func _input(event: InputEvent):
	# Block interaction if player not nearby, just closed, or under cooldown
	if not is_player_inside or just_closed or GameData.dialogue_cooldown:
		return

	if event.is_action_pressed("interact"):
		if dialogue_box.visible:
			if dialogue_box.has_method("advance"):
				var reached_end = dialogue_box.advance()
				if reached_end:
					# Reached end of dialogue → short cooldown
					just_closed = true
					await start_close_cooldown()
		else:
			dialogue_box.start_from_file(dialogue_file_path)

func _on_dialogue_closed():
	print("❌ Dialogue closed by player → entering cooldown")
	GameData.dialogue_cooldown = true
	start_dialogue_cooldown()

func start_close_cooldown():
	await get_tree().create_timer(0.2).timeout
	just_closed = false
	print("✅ Short cooldown ended — ready to talk again")

func start_dialogue_cooldown():
	await get_tree().create_timer(1.0).timeout
	GameData.dialogue_cooldown = false
	print("🕓 Dialogue cooldown ended — player can interact again")
