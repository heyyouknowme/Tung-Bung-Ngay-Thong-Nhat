extends Node2D

@onready var camera = $Camera2D
@onready var bounds = $MapBounds/CollisionShape2D

func _ready():
	if bounds.shape is RectangleShape2D:
		var rect = bounds.shape
		var size = rect.size
		var center = bounds.global_position

		camera.limit_left = int(center.x - size.x / 2)
		camera.limit_right = int(center.x + size.x / 2)
		camera.limit_top = int(center.y - size.y / 2)
		camera.limit_bottom = int(center.y + size.y / 2)

		print("Camera limits:", camera.limit_left, camera.limit_right, camera.limit_top, camera.limit_bottom)
