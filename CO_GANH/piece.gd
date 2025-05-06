extends Sprite2D

var team: String
var board_pos: Vector2i


func _ready():
	if team == "den":
		texture = preload("res://CO_GANH/assets/sprites/pheLua.png")
	elif team == "trang":
		texture = preload("res://CO_GANH/assets/sprites/pheNuoc.png")
