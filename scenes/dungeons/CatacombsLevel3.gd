extends Spatial

# Catacombs Level 3 - Moon Sanctum

const tile_size = 1.0

const LEVEL_MAP = """########################
###<....................
###.....................
########################
########################
#####..........#########
#####..........#########
#####...*...*..#########
#####...AA.AA..#########
#####...*...*..#########
#####..........#########
#####..........#########
########################
########...^...#########
########.......#########
########################
########################
########################"""

const COLOR_WALL = Color(0.3, 0.25, 0.2)
const COLOR_CEILING = Color(0.25, 0.2, 0.15)
const COLOR_FLOOR = Color(0.4, 0.35, 0.3)
const COLOR_ALTAR = Color(0.7, 0.65, 0.5)
const COLOR_STATUE = Color(0.5, 0.5, 0.5)

var is_moving = false
var is_rotating = false
var waiting_for_input = false
var blessing_received = false

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
				"<", "^":
					create_floor(pos)
					create_ceiling(pos)
				"A":
					create_floor(pos)
					create_altar(pos)
					create_ceiling(pos)
				"*":
					create_floor(pos)
					create_statue(pos)
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

func create_altar(pos):
	var mesh = MeshInstance.new()
	mesh.mesh = CubeMesh.new()
	mesh.mesh.size = Vector3(1.0, 1.5, 1.0)
	var mat = SpatialMaterial.new()
	mat.albedo_color = COLOR_ALTAR
	mesh.set_surface_material(0, mat)
	mesh.translation = pos + Vector3(0, 0.75, 0)
	add_child(mesh)

func create_statue(pos):
	var mesh = MeshInstance.new()
	mesh.mesh = CylinderMesh.new()
	mesh.mesh.top_radius = 0.3
	mesh.mesh.bottom_radius = 0.3
	mesh.mesh.height = 1.8
	var mat = SpatialMaterial.new()
	mat.albedo_color = COLOR_STATUE
	mesh.set_surface_material(0, mat)
	mesh.translation = pos + Vector3(0, 0.9, 0)
	add_child(mesh)

func position_camera_at_spawn():
	camera.translation = Vector3(11 - 12, 1.6, 1 - 9)
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
				"<":
					get_tree().change_scene("res://scenes/dungeons/CatacombsLevel2.tscn")
				"^":
					if not blessing_received:
						receive_blessing()

func receive_blessing():
	blessing_received = true
	PlayerData.awakened = true
	print("=== YARIKH'S BLESSING ===")
	print("The moon god grants you power!")
	print("SP and MP unlocked!")
	print("You may now leave the city.")
	show_message("=== YARIKH'S BLESSING ===\nThe moon god grants you power!\nSP and MP unlocked!")
	yield(get_tree().create_timer(3.0), "timeout")
	get_tree().change_scene("res://scenes/Yeriho.tscn")

func show_message(text):
	message_label.text = text
	message_label.visible = true
	waiting_for_input = true
