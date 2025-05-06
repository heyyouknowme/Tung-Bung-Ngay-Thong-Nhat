extends Node3D  # Gắn vào node gốc của mỗi cây (không phải Sprite3D!)

# random hóa biên độ & thời gian
var sway_amount := randf_range(0.5, 1.0)    # độ lắc (độ)
var sway_duration := randf_range(1.0, 2.2)  # thời gian lắc
var sway_direction := 1 if randi() % 2 == 0 else -1  # xoay trái/phải trước

func _ready():
	sway()

func sway():
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees:z", sway_amount * sway_direction, sway_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	tween = create_tween()
	tween.tween_property(self, "rotation_degrees:z", -sway_amount * sway_direction, sway_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	sway()
