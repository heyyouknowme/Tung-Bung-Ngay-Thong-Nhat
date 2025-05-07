extends Control

@onready var label: Label = $Label
@onready var title: Label = $Label2

var lines: PackedStringArray = []
var current_line := 0
var is_playing := false
var choice_active := false
var selected_index := 0
signal dialogue_closed

func _ready():
	visible = false

func start_from_text(text: String):
	if text:
		lines = text.strip_edges(true, true).split("\n")
# Create a new array to store non-empty lines
		var non_empty_lines = []
# Loop through each line and add to non_empty_lines if not empty
		for line in lines:
			if line.strip_edges().length() > 0:  # Check if the line is not empty
				non_empty_lines.append(line)
		lines = non_empty_lines
		print(lines)
	else:
		push_error("no text")
		return
	if not GameData.is_dialogue_open:
		GameData.is_dialogue_open = true
		start_dialogue()

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

func start_dialogue_timer():
	for i in range(1, 20):
		print(i)
		await get_tree().create_timer(1).timeout
	print("✅ Dialogue timer done!")
	_finish()

func start_dialogue():
	start_dialogue_timer()
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false
	
	current_line = 0
	is_playing = true
	choice_active = false
	visible = true
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
		_finish()
		emit_signal("dialogue_closed")
		return true

func show_line():
	if lines.size() > current_line:
		label.text = lines[current_line]



func _finish():
	print("🛑 Dialogue closed")
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = true
	is_playing = false
	GameData.is_dialogue_open = false
	choice_active = false
	visible = false
	label.text = ""
	title.text = ""

	if Input.is_action_just_pressed("ui_cancel"):
		emit_signal("dialogue_closed")
