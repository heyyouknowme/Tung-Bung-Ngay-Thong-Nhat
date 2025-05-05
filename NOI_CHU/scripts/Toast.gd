extends Label

@onready var toast_label: Label = $"."

func show_message(message: String, duration := 2.0):
	toast_label.text = message
	visible = true
	await get_tree().create_timer(duration).timeout
	visible = false
