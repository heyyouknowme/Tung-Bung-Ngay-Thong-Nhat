extends Label

@export var countdown_time := 3.0
@onready var warning_sound = $"../../WarningSound"

signal countdown_finished

var time_left := countdown_time
var counting := false

func _ready():
	hide()

func _process(delta):
	if counting:
		time_left -= delta
		if time_left <= 0:
			counting = false
			hide()
			emit_signal("countdown_finished")
		else:
			text = str(ceil(time_left))

func start_countdown():
	time_left = countdown_time
	counting = true
	text = str(ceil(time_left))
	show()

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			if warning_sound:
				warning_sound.play()
		else:
			if warning_sound and warning_sound.playing:
				warning_sound.stop()
