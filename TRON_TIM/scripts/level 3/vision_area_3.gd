extends Area2D

@export var player_path: NodePath

@onready var player = get_node_or_null(player_path)

const CLOSE_TO_PLAYER_DISTANCE = 80     # Khoảng cách để NPC phát hiện player khi đứng yên

# Các tín hiệu
signal player_detected  # Phát khi phát hiện player
signal player_spotted   # Phát khi player trong tầm nhìn

func _ready():
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

func _on_body_entered(body):
	if body == player:
		print("👁️ Player đã vào vùng tầm nhìn")
		# Kiểm tra xem có nên phát hiện player không
		if _should_detect_player():
			emit_signal("player_spotted")

# Được gọi khi player rời khỏi vùng tầm nhìn
func _on_body_exited(body):
	if body == player:
		print("👁️ Player đã rời khỏi vùng tầm nhìn")

		# Dừng countdown ngay lập tức
		if get_parent().has_method("_stop_countdown"):
			get_parent()._stop_countdown()


# Kiểm tra các điều kiện phát hiện
func _should_detect_player() -> bool:
	if not player:
		return false
	
	var is_player_moving = _is_player_moving()
	var distance = global_position.distance_to(player.global_position)
	
	# Trong vùng nhìn thấy và đang di chuyển
	if is_player_moving:
		print("🕵️‍♂️ Player bị phát hiện")
		print(">> player.velocity: ", player.velocity)
		print(">> player.velocity.length(): ", player.velocity.length())
		return true
	
	# Trong khoảng cách gần và đứng im
	if distance <= CLOSE_TO_PLAYER_DISTANCE:
		print("🕵️‍♂️ Checking player... Distance:", distance, "Moving:", is_player_moving)
		print("CLOSE_TO_PLAYER_DISTANCE: " + str(CLOSE_TO_PLAYER_DISTANCE))		# Bắt đầu tất cả các hiệu ứng khi phát hiện
		return true

	
	return false

# Kiểm tra xem player có đang di chuyển hay không 
func _is_player_moving() -> bool:
	return player.has_method("get_velocity") and player.get_velocity().length() > 0.1

# Kiểm tra xem có vật cản giữa NPC và player không
func _check_line_of_sight() -> bool:
	if not player:
		return false
			
	var space_state = get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.new()
	query.from = global_position
	query.to = player.global_position
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	return result.is_empty() or (not result.is_empty() and result["collider"] == player)
