extends Node2D

var pieces: Array = []  # mỗi phần tử là {type: "dân"/"quan", color: "red"/"green"}

@onready var piece_container := $PieceContainer

var piece_textures = [
	preload("res://O_AN_QUAN/assets/pieces/white_piece.png"),
	preload("res://O_AN_QUAN/assets/pieces/brown_piece.png")
]

func add_piece(piece_type: String, color := ""):
	pieces.append({ "type": piece_type, "color": color })
	_draw_pieces()

func clear_all():
	pieces.clear()
	_draw_pieces()

func _draw_pieces():
	for child in piece_container.get_children():
		child.queue_free()

	for i in range(pieces.size()):
		var piece = pieces[i]
		var sprite = Sprite2D.new()

		if piece.type == "quan":
			if(piece.color == "red"):
				sprite.texture = preload("res://O_AN_QUAN/assets/pieces/quan_red.png")
			else: 
				sprite.texture = preload("res://O_AN_QUAN/assets/pieces/quan_green.png")
			sprite.scale = Vector2(0.5, 0.5)
		else:
			sprite.texture = piece_textures[randi() % piece_textures.size()]
			sprite.scale = Vector2(0.5, 0.5)

		sprite.position = Vector2(randf_range(-40, 40), randf_range(-40, 40))
		piece_container.add_child(sprite)
