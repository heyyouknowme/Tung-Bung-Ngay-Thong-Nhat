extends CharacterBody2D

@export var patrol_points: Array[Node2D] = []
@export var player_path: NodePath
@onready var player: Node2D = get_node_or_null(player_path)
@onready var sprite = $AnimatedSprite2D
@onready var vision_root = $VisionRoot
@onready var vision_area = $VisionRoot/VisionCone/Area2D
#@onready var warning_sound = $"../WarningSound"  

const CELL_SIZE = 64*3
const ROTATION_EPSILON = deg_to_rad(5)  # chỉ xoay VisionRoot nếu lệch trên 5 độ
const CLOSE_TO_PLAYER_DISTANCE = 200     # Khoảng cách để NPC đứng yên khi gần player
const PATH_UPDATE_TIME = 3.0            # Cập nhật đường đi mỗi 2 giây

var astar_full_map := AStar2D.new()
var path := PackedVector2Array()
var current_path_index := 0
var speed := 160
var is_chasing := false
var patrol_index := 0
var last_target_position := Vector2.ZERO  # Ghi nhớ vị trí player cũ khi đuổi
var chase_update_timer := Timer.new()
var previous_position := Vector2.ZERO
var stuck_check_timer := Timer.new()

func _ready():
	if patrol_points.is_empty():
		push_warning("⚠️ Chưa gán patrol_points trong Inspector!")
		return

	if not player:
		push_warning("⚠️ Chưa gán player_path trong Inspector!")
		
	if vision_area:
		# Chỉ kết nối một signal và một hàm xử lý
		vision_area.connect("body_entered", Callable(self, "_on_body_entered"))
		vision_area.connect("body_exited", Callable(self, "_on_body_exited"))
	else:
		push_error("❌ Không tìm thấy Area2D trong VisionCone!")

	_generate_astar_full_map()
	
	stuck_check_timer.wait_time = 1.0
	stuck_check_timer.one_shot = false
	stuck_check_timer.timeout.connect(_check_if_stuck)
	add_child(stuck_check_timer)
	stuck_check_timer.start()
	
	# Thiết lập timer với thời gian là 2 giây
	chase_update_timer.wait_time = PATH_UPDATE_TIME
	chase_update_timer.autostart = false  # Chỉ bắt đầu khi đuổi theo
	chase_update_timer.one_shot = false
	chase_update_timer.timeout.connect(_update_chase_path)
	add_child(chase_update_timer)
	
	_go_to_nearest_patrol_point()  # Bắt đầu với điểm tuần tra gần nhất

func _reverse_direction():
	if path.size() > 1:
		path.reverse()
		current_path_index = 0
	else:
		# Nếu không có path, đổi patrol_index
		patrol_index = (patrol_index + 1) % patrol_points.size()
		_set_path_to_target(patrol_points[patrol_index].global_position)

func _check_if_stuck():
	var distance_moved = global_position.distance_to(previous_position)
	
	if distance_moved < 5.0 and velocity.length() > 0.1:
		print("🚫 NPC có vẻ bị kẹt → xoay hướng")
		_reverse_direction()
	else:
		# cập nhật lại vị trí nếu di chuyển được
		previous_position = global_position

func _update_chase_path():
	if is_chasing and player:
		# Chỉ cập nhật đường đi nếu player đã di chuyển đủ xa
		if player.global_position.distance_to(last_target_position) > 110:
			var from_id = _get_closest_astar_id(astar_full_map, global_position)
			var to_id = _get_closest_astar_id(astar_full_map, player.global_position)
			
			if from_id != -1 and to_id != -1:
				path = astar_full_map.get_point_path(from_id, to_id)
				current_path_index = 0
				last_target_position = player.global_position
				print("🔄 Cập nhật đường đuổi")

func _go_to_nearest_patrol_point():
	if patrol_points.is_empty():
		return
		
	var nearest_id := 0
	var min_dist := INF
	for i in range(patrol_points.size()):
		var dist = global_position.distance_to(patrol_points[i].global_position)
		if dist < min_dist:
			min_dist = dist
			nearest_id = i
	patrol_index = nearest_id
	_set_path_to_target(patrol_points[patrol_index].global_position)
	print("🚶 Đi đến điểm tuần tra gần nhất: " + str(patrol_index))

func _physics_process(delta):
	if not player:
		return
		
	# Xử lý di chuyển
	if path.is_empty():
		velocity = Vector2.ZERO
		#sprite.play("idle")
		return

	# Kiểm tra nếu đang đuổi và quá gần player thì đứng yên
	#if is_chasing and player and global_position.distance_to(player.global_position) < CLOSE_TO_PLAYER_DISTANCE:
		#velocity = Vector2.ZERO
		##sprite.play("idle")
		#return
	
	var target_speed = 180
	if is_chasing and player and global_position.distance_to(player.global_position) < CLOSE_TO_PLAYER_DISTANCE:
		target_speed = 120
	speed = lerp(speed, target_speed, 0.1)  # Giảm mượt


	if current_path_index < path.size():
		var target = path[current_path_index]
		var direction = (target - global_position).normalized()
		velocity = direction * speed
		
		# Cập nhật hoạt ảnh và xoay hướng nhìn
		if abs(direction.x) > abs(direction.y):
			sprite.play("walk_right" if direction.x > 0 else "walk_left")
		else:
			sprite.play("walk_down" if direction.y > 0 else "walk_up")

		# Xoay VisionRoot nếu đang di chuyển
		if velocity.length() > 0.1:
			var desired_angle = direction.angle() + deg_to_rad(180)  # nếu cần xoay ngược
			if abs(vision_root.rotation - desired_angle) > ROTATION_EPSILON:
				vision_root.rotation = desired_angle


		move_and_slide()

		# Kiểm tra nếu đã đến điểm tiếp theo
		if global_position.distance_to(target) < 105:
			current_path_index += 1
			if current_path_index >= path.size():
				path.clear()
				if not is_chasing:
					_next_patrol()
	
	queue_redraw()

func _generate_astar_full_map():
	var id := 0
	var occupied = {}
	
	# Tạo lưới điểm đồng đều
	for y in range(-10, 11):
		for x in range(-10, 11):
			var pos = Vector2(x, y) * CELL_SIZE + Vector2(CELL_SIZE/2, CELL_SIZE/2)
			if _is_position_blocked(pos):
				continue
			astar_full_map.add_point(id, pos)
			occupied[Vector2i(x, y)] = id
			id += 1
	
	# Kết nối các điểm lân cận
	for pos in occupied.keys():
		var center_id = occupied[pos]
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
			Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(1,1)]:
			var neighbor = pos + offset
			if occupied.has(neighbor):
				astar_full_map.connect_points(center_id, occupied[neighbor])

func _is_position_blocked(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_point(query)
	
	for collision in result:
		var collider = collision["collider"]
		# Bỏ qua va chạm với Area2D của chính NPC
		if collider == vision_area or collider == self:
			continue
		# Bỏ qua va chạm với player
		if collider == player:
			continue
		return true
		
	return false

# Thống nhất một phương thức để thiết lập đường đi
func _set_path_to_target(target: Vector2):
	# Nếu là điểm tuần tra, đi thẳng đến đó
	if not is_chasing:
		path.clear()
		path.append(target)
		current_path_index = 0
	# Nếu đang đuổi, sử dụng AStar
	else:
		var from_id = _get_closest_astar_id(astar_full_map, global_position)
		var to_id = _get_closest_astar_id(astar_full_map, target)
		
		if from_id != -1 and to_id != -1:
			path = astar_full_map.get_point_path(from_id, to_id)
			current_path_index = 0

func _get_closest_astar_id(astar: AStar2D, pos: Vector2) -> int:
	var closest_id = -1
	var min_dist = INF
	
	for id in astar.get_point_ids():
		var dist = astar.get_point_position(id).distance_to(pos)
		if dist < min_dist:
			min_dist = dist
			closest_id = id
			
	return closest_id

func _next_patrol():
	if patrol_points.is_empty():
		return
		
	patrol_index = (patrol_index + 1) % patrol_points.size()
	_set_path_to_target(patrol_points[patrol_index].global_position)
	print("➡️ Đi đến điểm tuần tra tiếp theo: " + str(patrol_index))

func _on_body_entered(body: Node2D) -> void:
	if body == player and not is_chasing:
		is_chasing = true
		last_target_position = player.global_position
		print("👁️ Bắt đầu đuổi theo player")
		
		# Thiết lập đường đi đến player và bắt đầu timer
		_set_path_to_target(player.global_position)
		chase_update_timer.start()

func _on_body_exited(body: Node2D):
	if body == player and is_chasing:
		print("👋 Mất dấu player")
		# Đợi 1 giây trước khi từ bỏ
		await get_tree().create_timer(1.0).timeout
		
		# Kiểm tra lại một lần nữa xem có thực sự mất dấu không
		if vision_area and not vision_area.get_overlapping_bodies().has(player):
			is_chasing = false
			chase_update_timer.stop()
			print("🔍 Quay lại tuần tra")
			_go_to_nearest_patrol_point()

#func _draw():
	#if path.size() > 1:
		#for i in range(path.size() - 1):
			#draw_line(to_local(path[i]), to_local(path[i+1]), Color.YELLOW, 2)

	#tô màu cho các điểm patrol
	#for p in patrol_points:
		#draw_circle(to_local(p.global_position), 5, Color.RED)
