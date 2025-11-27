extends Spatial

# Catacombs Level 1 - Hall of Four Signs

const tile_size = 1.0

const LEVEL_MAP = """########################
##########....##########
##########.@..##########
##########....##########
######............######
######.11......22.######
######............######
###......######......###
###......#++++#......###
###..33..#..>.#..44..###
###......#....#......###
###......######......###
######............######
######............######
##########....##########
##########....##########
########################
########################"""

const COLOR_WALL = Color(0.3, 0.25, 0.2)
const COLOR_CEILING = Color(0.25, 0.2, 0.15)
const COLOR_FLOOR = Color(0.4, 0.35, 0.3)
const COLOR_DOOR = Color(0.5, 0.4, 0.3)

var is_moving = false
var is_rotating = false
var waiting_for_input = false

var sign1 = false
var sign2 = false
var sign3 = false
var sign4 = false
var door_open = false

onready var camera = $Camera
onready var message_label = $MessageLabel

func _ready():
	generate_level()
	position_camera_at_spawn()
	PlayerData.in_dungeon = true

func generate_level():
	var lines = LEVEL_MAP.split("\n")
	for row in range(lines.size()):
		var line = lines[row]
		for col in range(line.length()):
			var tile = line[col]
			var pos = Vector3(col - 12, 0, row - 9)
			
			match tile:
				"#":
					create_wall(pos)
					create_ceiling(pos)
				".":
					create_floor(pos)
					create_ceiling(pos)
				"+":
					if not door_open:
						create_door(pos)
					else:
						create_floor(pos)
					create_ceiling(pos)
				">":
					create_floor(pos)
					create_stairs(pos)
					create_ceiling(pos)
				"1", "2", "3", "4":
					create_floor(pos)
					create_shrine(pos, int(tile))
					create_ceiling(pos)

func create_wall(pos):
	var mesh = MeshInstance.new()
	mesh.mesh = CubeMesh.new()
	mesh.mesh.size = Vector3(1.0, 3.0, 1.0)
	var mat = SpatialMaterial.new()
	mat.albedo_color = COLOR_WALL
	mesh.set_surface_material(0, mat)
	mesh.translation = pos + Vector3(0, 1.5, 0)
	add_child(mesh)
	
	var body = StaticBody.new()
	var shape = CollisionShape.new()
	shape.shape = BoxShape.new()
	shape.shape.extents = Vector3(0.48, 1.5, 0.48)
	body.add_child(shape)
	mesh.add_child(body)

func create_ceiling(pos):
	var mesh = MeshInstance.new()
	mesh.mesh = CubeMesh.new()
	mesh.mesh.size = Vector3(1.0, 0.1, 1.0)
	var mat = SpatialMaterial.new()
	mat.albedo_color = COLOR_CEILING
	mesh.set_surface_material(0, mat)
	mesh.translation = pos + Vector3(0, 2.95, 0)
	add_child(mesh)

func create_floor(pos):
	var mesh = MeshInstance.new()
	mesh.mesh = CubeMesh.new()
	mesh.mesh.size = Vector3(1.0, 0.1, 1.0)
	var mat = SpatialMaterial.new()
	mat.albedo_color = COLOR_FLOOR
	mesh.set_surface_material(0, mat)
	mesh.translation = pos + Vector3(0, 0.05, 0)
	add_child(mesh)

func create_door(pos):
	var mesh = MeshInstance.new()
	mesh.mesh = CubeMesh.new()
	mesh.mesh.size = Vector3(1.0, 2.5, 0.3)
	mesh.name = "Door"
	var mat = SpatialMaterial.new()
	mat.albedo_color = COLOR_DOOR
	mesh.set_surface_material(0, mat)
	mesh.translation = pos + Vector3(0, 1.25, 0)
	add_child(mesh)
	
	var body = StaticBody.new()
	var shape = CollisionShape.new()
	shape.shape = BoxShape.new()
	shape.shape.extents = Vector3(0.48, 1.25, 0.15)
	body.add_child(shape)
	mesh.add_child(body)

func create_stairs(pos):
	var mesh = MeshInstance.new()
	mesh.mesh = CubeMesh.new()
	mesh.mesh.size = Vector3(0.8, 0.3, 0.8)
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(0.6, 0.5, 0.4)
	mesh.set_surface_material(0, mat)
	mesh.translation = pos + Vector3(0, 0.2, 0)
	add_child(mesh)

func create_shrine(pos, num):
	var mesh = MeshInstance.new()
	mesh.mesh = CylinderMesh.new()
	mesh.mesh.top_radius = 0.3
	mesh.mesh.bottom_radius = 0.3
	mesh.mesh.height = 1.5
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(0.7, 0.6, 0.4)
	mesh.set_surface_material(0, mat)
	mesh.translation = pos + Vector3(0, 0.75, 0)
	add_child(mesh)

func position_camera_at_spawn():
	camera.translation = Vector3(11 - 12, 1.6, 2 - 9)
	camera.rotation_degrees.y = 180

func _process(_delta):
	if MenuSystem.menu_open:
		return
	
	if waiting_for_input:
		if Input.is_action_just_pressed("ui_accept"):
			waiting_for_input = false
			message_label.visible = false
		return
	
	if is_moving or is_rotating:
		return
	
	if Input.is_action_just_pressed("ui_up"):
		move_camera(1)
	elif Input.is_action_just_pressed("ui_down"):
		move_camera(-1)
	elif Input.is_action_just_pressed("ui_left"):
		rotate_camera(90)
	elif Input.is_action_just_pressed("ui_right"):
		rotate_camera(-90)
	elif Input.is_action_just_pressed("ui_accept"):
		check_interaction()

func move_camera(direction):
	is_moving = true
	var forward = -camera.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var target_position = camera.global_transform.origin + (forward * tile_size * direction)
	var body = camera.get_node("KinematicBody")
	var collision = body.move_and_collide(forward * tile_size * direction, true, true, true)
	if collision:
		is_moving = false
		return
	var tween = create_tween()
	tween.tween_property(camera, "global_transform:origin", target_position, 0.3)
	tween.tween_callback(self, "finish_move")

func rotate_camera(degrees):
	is_rotating = true
	var current_rotation = camera.rotation_degrees.y
	var target_rotation = current_rotation + degrees
	var tween = create_tween()
	tween.tween_property(camera, "rotation_degrees:y", target_rotation, 0.2)
	tween.tween_callback(self, "finish_rotate")

func finish_move():
	is_moving = false

func finish_rotate():
	is_rotating = false

func check_interaction():
	var pos = camera.translation
	var grid_x = int(round(pos.x + 12))
	var grid_y = int(round(pos.z + 9))
	
	var lines = LEVEL_MAP.split("\n")
	if grid_y >= 0 and grid_y < lines.size():
		var line = lines[grid_y]
		if grid_x >= 0 and grid_x < line.length():
			var tile = line[grid_x]
			
			match tile:
				"1": activate_shrine(1)
				"2": activate_shrine(2)
				"3": activate_shrine(3)
				"4": activate_shrine(4)
				">":
					if door_open:
						get_tree().change_scene("res://scenes/dungeons/CatacombsLevel2.tscn")

func activate_shrine(num):
	match num:
		1:
			if not sign1:
				sign1 = true
				show_message("Shrine 1 activated!")
				check_door()
		2:
			if not sign2:
				sign2 = true
				show_message("Shrine 2 activated!")
				check_door()
		3:
			if not sign3:
				sign3 = true
				show_message("Shrine 3 activated!")
				check_door()
		4:
			if not sign4:
				sign4 = true
				show_message("Shrine 4 activated!")
				check_door()

func check_door():
	if sign1 and sign2 and sign3 and sign4 and not door_open:
		door_open = true
		show_message("The stone door rumbles open!")
		for child in get_children():
			if child.name == "Door":
				child.queue_free()

func show_message(text):
	message_label.text = text
	message_label.visible = true
	waiting_for_input = true
