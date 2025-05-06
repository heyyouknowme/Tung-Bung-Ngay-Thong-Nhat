extends TextureButton

func _ready():
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)

func _on_mouse_entered():
	self.modulate = Color(1.3, 1.3, 1.3)  # làm sáng lên (RGB > 1.0)

func _on_mouse_exited():
	self.modulate = Color(1, 1, 1)  # trở về bình thường
