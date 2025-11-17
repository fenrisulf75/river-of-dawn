extends KinematicBody2D

# Tile size (must match TileMap cell size)
var tile_size = 64

# Movement state
var is_moving = false

func _physics_process(_delta):
	if is_moving:
		return
	
	# Check for input
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		direction = Vector2.RIGHT
	elif Input.is_action_pressed("ui_left"):
		direction = Vector2.LEFT
	elif Input.is_action_pressed("ui_down"):
		direction = Vector2.DOWN
	elif Input.is_action_pressed("ui_up"):
		direction = Vector2.UP
	
	if direction != Vector2.ZERO:
		attempt_move(direction)

func attempt_move(direction):
	# Check if target position is valid using a raycast
	var space_state = get_world_2d().direct_space_state
	var target_pos = position + (direction * tile_size)
	
	# Raycast from center to check for collisions
	var result = space_state.intersect_point(target_pos + Vector2(32, 32), 32, [], collision_mask)
	
	# Filter out self
	var has_collision = false
	for hit in result:
		if hit.collider != self:
			has_collision = true
			break
	
	if has_collision:
		print("COLLISION DETECTED!")
		return
	
	print("No collision, moving")
	
	# No collision, perform the move
	is_moving = true
	
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 0.25)
	tween.tween_callback(self, "finish_move")

func finish_move():
	is_moving = false
