extends Label

func blink_label():
	var tween = get_tree().create_tween()
	tween.set_loops()

	var step1 = tween.tween_property(self, "modulate:a", 0.0, 0.4)
	step1.set_trans(Tween.TRANS_SINE)
	step1.set_ease(Tween.EASE_IN_OUT)

	var step2 = tween.tween_property(self, "modulate:a", 1.0, 0.4)
	step2.set_trans(Tween.TRANS_SINE)
	step2.set_ease(Tween.EASE_IN_OUT)

func _ready():
	blink_label()
