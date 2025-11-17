extends Spatial

var tile_size = 1.0
var is_moving = false
var is_rotating = false

onready var camera = $Camera

func _process(_delta):
	if is_moving or is_rotating:
		return
	
	if Input.is_action_just_pressed("ui_left"):
		rotate_camera(-90)
	elif Input.is_action_just_pressed("ui_right"):
		rotate_camera(90)
	elif Input.is_action_just_pressed("ui_up"):
		move_camera(1)
	elif Input.is_action_just_pressed("ui_down"):
		move_camera(-1)

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
	
	var forward = -camera.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	
	var target_position = camera.global_transform.origin + (forward * tile_size * direction)
	
	var tween = create_tween()
	tween.tween_property(camera, "global_transform:origin", target_position, 0.3)
	tween.tween_callback(self, "finish_move")

func finish_move():
	is_moving = false
