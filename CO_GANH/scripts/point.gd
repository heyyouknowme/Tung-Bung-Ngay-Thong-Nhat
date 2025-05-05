extends Sprite2D

func _ready():
	blink_sprite()

func blink_sprite():
	var tween := get_tree().create_tween()
	tween.set_loops()

	# Fade out
	var step1 := tween.tween_property(self, "modulate:a", 0.2, 0.4)
	step1.set_trans(Tween.TRANS_SINE)
	step1.set_ease(Tween.EASE_IN_OUT)

	# Fade in
	var step2 := tween.tween_property(self, "modulate:a", 1.0, 0.4)
	step2.set_trans(Tween.TRANS_SINE)
	step2.set_ease(Tween.EASE_IN_OUT)
