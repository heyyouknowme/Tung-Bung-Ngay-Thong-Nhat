extends Button

signal slot_clicked(index)

var index: int = -1
var count: int = 0
var type: String = "dân"
var player: String = "left"
var quan_eaten := false
var is_selected: bool = false

@onready var tween: Tween = null
@onready var count_label: Label = $CountLabel
@onready var piece_container := $PieceContainer
@onready var border_sprite: Sprite2D = $BorderSprite



var piece_textures = [
	preload("res://O_AN_QUAN/assets/pieces/white_piece.png"),
	preload("res://O_AN_QUAN/assets/pieces/brown_piece.png")
]

func _ready():
	# BỎ DÒNG NÀY nếu bạn không cần hiển thị gì mặc định
	# Load hình border
	border_sprite.texture = preload("res://O_AN_QUAN/assets/border.png")
	border_sprite.position = get_rect().size / 2
	# Scale cho đúng với size của Button
	var button_size = get_size()
	var texture_size = border_sprite.texture.get_size()

	# Scale riêng từng chiều
	var scale_x = button_size.x / texture_size.x
	var scale_y = button_size.y / texture_size.y
	if(type == "quan"):
		border_sprite.position.y = border_sprite.position.y + get_rect().size.y / 2 
		scale_y = scale_y * 2

	border_sprite.scale = Vector2(scale_x, scale_y)

	# Đưa viền ra sau tất cả (để quân cờ không bị che)
	border_sprite.z_index = -1
	
	piece_container.position = get_rect().size / 2
	update_display()
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	pass

func _pressed():
	emit_signal("slot_clicked", index)
	play_click_effect()

func update_display():
	if count_label:
		count_label.text = str(count)
	_draw_pieces()

func set_data(i: int, c: int, t: String, o: String, is_quan_eaten := false):
	index = i
	count = c
	type = t
	player = o
	quan_eaten = is_quan_eaten
	update_display()

func _draw_pieces():
	if piece_container:
		for child in piece_container.get_children():
			child.queue_free()
		var num_dan = count
		
		if num_dan < 1:
			return
		# Nếu là Quan, thêm viên đá lớn ở giữa
		if type == "quan":
			if not quan_eaten:
				var sprite = Sprite2D.new()
				if index == 0:
					sprite.texture = preload("res://O_AN_QUAN/assets/pieces/quan_red.png")
				elif abs(index) == 6:
					sprite.texture = preload("res://O_AN_QUAN/assets/pieces/quan_green.png")
				sprite.scale = Vector2(0.5, 0.5)
				sprite.position = Vector2(0, 80)
				piece_container.add_child(sprite)

				num_dan -= 1  # trừ 1 vì 1 quân đã là Quan
			for i in range(num_dan):
				var sprite_dan = Sprite2D.new()
				sprite_dan.texture = piece_textures[randi() % piece_textures.size()]
				sprite_dan.scale = Vector2(0.5, 0.5)

				# Rải quanh tâm container
				sprite_dan.position = Vector2(randf_range(20-40,20+40), randf_range(50-60, 50+60))
				
				piece_container.add_child(sprite_dan)
				
		else:	
			for i in range(num_dan):
				var sprite = Sprite2D.new()
				sprite.texture = piece_textures[randi() % piece_textures.size()]
				sprite.scale = Vector2(0.5, 0.5)

				# Rải quanh tâm container
				sprite.position = Vector2(randf_range(-40, 40), randf_range(-40, 40))
				
				piece_container.add_child(sprite)

func animate_capture(target_global_position: Vector2):
	for child in piece_container.get_children():
		var tween := create_tween()
		var start_pos = child.global_position
		child.global_position = start_pos  # đảm bảo vị trí đúng

		tween.tween_property(child, "global_position", target_global_position, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_callback(Callable(child, "queue_free"))
		
func _on_mouse_entered():
	if is_selected:
		return
	if tween:
		tween.kill()  # Hủy tween cũ nếu có

	tween = create_tween()
	tween.tween_property(border_sprite, "modulate", Color(0.8, 0.8, 0.8, 0.8), 0.2)

func _on_mouse_exited():
	if is_selected:
		return
	if tween:
		tween.kill()  # Hủy tween cũ nếu có

	tween = create_tween()
	tween.tween_property(border_sprite, "modulate", Color(1, 1, 1, 1), 0.2)
	
func play_click_effect():
	is_selected = true
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(border_sprite, "modulate", Color(1.5, 1.5, 1.5, 1), 0.1)
	
func clear_highlight():
	is_selected = false
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(border_sprite, "modulate", Color(1, 1, 1, 1), 0.2)
	
func highlight_pass():
	if is_selected:
		return

	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(border_sprite, "modulate", Color(1.5, 1.5, 1.5, 1.5), 0.5)  # sáng nhanh vàng nhẹ
	tween.tween_property(border_sprite, "modulate", Color(1, 1, 1, 1), 0.15)  # rồi tối lại
