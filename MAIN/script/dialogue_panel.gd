extends Control

@onready var label: Label = $Label
@onready var title: Label = $Label2
@onready var choice_box: HBoxContainer = $ChoiceBox
@onready var selector: TextureRect = $Selector
@onready var buttons := [
	$ChoiceBox/YesButton,
	$ChoiceBox/AgainButton,
	$ChoiceBox/NoButton
]

@export var target_scene_path: String = "res://path/to/next_scene.tscn"

var lines: PackedStringArray = []
var current_line := 0
var is_playing := false
var choice_active := false
var selected_index := 0
var player
signal dialogue_closed


func _ready():
	choice_box.visible = false
	selector.visible = false
	selector.z_index = 100  # ✅ Ensure it's above all buttons
	visible = false
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = GameData.player_position
		  # 🛠 Restore player position
	$ChoiceBox/YesButton.pressed.connect(on_yes_selected)
	$ChoiceBox/AgainButton.pressed.connect(on_again_selected)
	$ChoiceBox/NoButton.pressed.connect(on_no_selected)

func start_from_file(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		lines = file.get_as_text().strip_edges(true, true).split("\n")
		file.close()
	else:
		push_error("❌ Failed to load dialogue file: " + path)
		return
	if not GameData.is_dialogue_open:
		GameData.is_dialogue_open = true
		start_dialogue()

func start_dialogue():
	if player:
		player.can_move = false
	
	current_line = 0
	is_playing = true
	choice_active = false
	visible = true
	choice_box.visible = false
	selector.visible = false
	if lines.size() > 0:
		title.text = lines[current_line]
		current_line += 1
		show_line()

func advance():
	if not is_playing:
		return false
	
	current_line += 1
	if current_line < lines.size():
		show_line()
		return false
	else:
		show_choices()
		return true

func show_line():
	label.text = lines[current_line]

func show_choices():
	print("Showing choices")
	is_playing = false
	choice_active = true
	choice_box.visible = true

	selected_index = 0
	selector.visible = true

	

	print("Choice box visible: ", choice_box.visible)
	print("Selector visible: ", selector.visible)
	print("Selector texture: ", selector.texture)
	print("Selector size: ", selector.size)
	print("Selector position: ", selector.position)

func update_selector_position():
	var target_btn = buttons[selected_index]
	if not is_instance_valid(target_btn):
		print("❌ Invalid target button")
		return

	if selector.size == Vector2.ZERO and selector.texture:
		selector.size = selector.texture.get_size()

	var btn_pos = target_btn.get_global_rect().position
	selector.global_position = Vector2(btn_pos.x - 50,  btn_pos.y + target_btn.size.y/2 + 20)
	selector.visible = true

	print("🎯 Button pos: ", btn_pos)
	print("🎯 Selector pos: ", selector.global_position)





func _input(event: InputEvent):
	if not visible or not choice_active:
		return
		
	if event.is_action_pressed("walk_right") or event.is_action_pressed("ui_left"):
		selected_index = (selected_index - 1 + buttons.size()) % buttons.size()
		update_selector_position()
	elif event.is_action_pressed("walk_left") or event.is_action_pressed("ui_right"):
		selected_index = (selected_index + 1) % buttons.size()
		update_selector_position()
	elif event.is_action_pressed("interact"):
		print("✅ Pressed Interact on index:", selected_index)
		match selected_index:
			0: on_yes_selected()
			1: on_again_selected()
			2: on_no_selected()
	elif event.is_action_pressed("ui_cancel"):
		print("🔙 Cancel (ESC) pressed")
		finish()

func on_yes_selected():
	print("🟢 YES selected → changing scene to: ", target_scene_path)
	
	# 1. Save player position before changing scene
	GameData.player_position = player.global_position
	
	# 2. Finish dialogue or pause menu
	finish()

	# 3. Change to the new scene
	get_tree().change_scene_to_file(target_scene_path)


func on_again_selected():
	print("🔁 AGAIN selected → restarting dialogue")
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false
	
	current_line = -1
	is_playing = true
	choice_active = false
	visible = true
	choice_box.visible = false
	selected_index = 0
	update_selector_position()
	selector.visible = false

	if lines.size() > 0:
		current_line += 1
		show_line()

func on_no_selected():
	print("❌ NO selected → closing dialogue")
	finish()
	emit_signal("dialogue_closed")

func finish():
	print("🛑 Dialogue closed")
	if player:
		player.can_move = true
	GameData.is_dialogue_open = false
	is_playing = false
	choice_active = false
	visible = false
	choice_box.visible = false
	selector.visible = false
	label.text = ""
	title.text = ""

	if Input.is_action_just_pressed("ui_cancel"):
		emit_signal("dialogue_closed")
