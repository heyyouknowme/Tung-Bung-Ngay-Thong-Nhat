extends ColorRect

func fade_out(duration := 0.5):
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, duration)
	await tween.finished

func fade_in(duration := 0.5):
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	await tween.finished
	visible = false

func transition_to_scene(path: String, duration := 0.5):
	await fade_out(duration)
	SceneManager.change_scene(path)
	await fade_in(duration)
