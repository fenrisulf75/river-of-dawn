extends Spatial

# Grid settings
var tile_size = 2.0  # Size of each grid square in 3D units
var is_moving = false
var is_rotating = false

# Reference to camera
onready var camera = $Camera

func _process(_delta):
	if is_moving or is_rotating:
		return
	
	# Rotation (90 degrees)
	if Input.is_action_just_pressed("ui_left"):
		rotate_camera(-90)
	elif Input.is_action_just_pressed("ui_right"):
		rotate_camera(90)
	
	# Forward/backward movement
	elif Input.is_action_just_pressed("ui_up"):
		move_camera(1)  # Move forward
	elif Input.is_action_just_pressed("ui_down"):
		move_camera(-1)  # Move backward

func rotate_camera(degrees):
	is_rotating = true
	var target_rotation = camera.rotation_degrees.y + degrees
	
	var tween = create_tween()
	tween.tween_property(camera, "rotation_degrees:y", target_rotation, 0.3)
	tween.tween_callback(self, "finish_rotation")

func finish_rotation():
	is_rotating = false

func move_camera(direction):
	is_moving = true
	
	# Calculate movement based on camera's facing direction
	var forward = -camera.global_transform.basis.z
	forward.y = 0  # Keep movement horizontal
	forward = forward.normalized()
	
	var target_position = camera.global_transform.origin + (forward * tile_size * direction)
	
	# Check for collision using raycast
	var space_state = get_world().direct_space_state
	var from = camera.global_transform.origin
	var to = target_position
	
	var result = space_state.intersect_ray(from, to, [self])
	
	if result:
		# Hit a wall, don't move
		print("Hit wall!")
		is_moving = false
		return
	
	# No collision, move
	var tween = create_tween()
	tween.tween_property(camera, "global_transform:origin", target_position, 0.3)
	tween.tween_callback(self, "finish_move")

func finish_move():
	is_moving = false


func _on_Area_body_entered(body):
	print("Something entered the exit area: ", body.name)
	if body.name == "Camera":
		print("Exiting city...")
		get_tree().change_scene("res://scenes/World.tscn")
	elif body.name == "CameraBody":
		print("CameraBody detected! Exiting city...")
		get_tree().change_scene("res://scenes/World.tscn")
	else:
		print("Unknown body: ", body.name)
