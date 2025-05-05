extends Label

@onready var warning_sound = $"../../WarningSound"

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			if warning_sound:
				warning_sound.play()
		else:
			if warning_sound and warning_sound.playing:
				warning_sound.stop()

# Hàm này có thể được gọi từ bên ngoài để cập nhật giá trị đếm ngược
func update_countdown_display(time_value: int):
	text = str(time_value)
