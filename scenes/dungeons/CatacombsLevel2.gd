extends Spatial

# Catacombs Level 2 - Winding Galleries

const tile_size = 1.0

const LEVEL_MAP = """########################
###<....................
###.##################.#
###.#................#.#
###.#.##############.#.#
###...#..............#.#
#####.#.##############.#
#####.#................#
#####.################.#
#####..................#
#######################.
#.......................
#.#####################.
#.#..........1..........
#.#.####################
#.#..........2..........
#.#....................#
#.#####################.
#.......................
#.######################
#.................>.....
########################
########################
########################"""

const COLOR_WALL = Color(0.3, 0.25, 0.2)
const COLOR_CEILING = Color(0.25, 0.2, 0.15)
const COLOR_FLOOR = Color(0.4, 0.35, 0.3)

var is_moving = false
var is_rotating = false
var waiting_for_input = false

onready var camera = $Camera
onready var message_label = $MessageLabel

# Texture preloading
var texture_cave_wall = null
var texture_cave_floor = null

func _ready():
	# Preload textures
	texture_cave_wall = load("res://assets/textures/walls/cave_stone_wall_512.png")
	texture_cave_floor = load("res://assets/textures/ground/ground_cliff_24.png")
	
	generate_level()
	position_camera_at_spawn()
	PlayerData.in_dungeon = true

func generate_level():
	var lines = LEVEL_MAP.split("\n")
	for row in range(lines.size()):
		var line = lines[row]
		for col in range(line.length()):
			var tile = line[col]
			var pos = Vector3(col - 12, 0, row - 12)
			
			match tile:
				"#":
					create_wall(pos)
					create_ceiling(pos)
				".":
					create_floor(pos)
					create_ceiling(pos)
				"<", ">", "1", "2":
					create_floor(pos)
					create_ceiling(pos)

func create_wall(pos):
	var mesh = MeshInstance.new()
	mesh.mesh = CubeMesh.new()
	mesh.mesh.size = Vector3(1.0, 3.0, 1.0)
	var mat = SpatialMaterial.new()
	
	# Use texture if loaded, otherwise fallback to color
	if texture_cave_wall:
		mat.albedo_texture = texture_cave_wall
	else:
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
	
	# Use texture if loaded, otherwise fallback to color
	if texture_cave_floor:
		mat.albedo_texture = texture_cave_floor
		mat.uv1_scale = Vector3(1, 1, 1)
	else:
		mat.albedo_color = COLOR_FLOOR
	
	mesh.set_surface_material(0, mat)
	mesh.translation = pos + Vector3(0, 0.05, 0)
	add_child(mesh)

func position_camera_at_spawn():
	camera.translation = Vector3(11 - 12, 1.6, 1 - 12)
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
	var grid_y = int(round(pos.z + 12))
	
	var lines = LEVEL_MAP.split("\n")
	if grid_y >= 0 and grid_y < lines.size():
		var line = lines[grid_y]
		if grid_x >= 0 and grid_x < line.length():
			var tile = line[grid_x]
			
			match tile:
				"<":
					get_tree().change_scene("res://scenes/dungeons/CatacombsLevel1.tscn")
				">":
					get_tree().change_scene("res://scenes/dungeons/CatacombsLevel3.tscn")
				"1":
					show_message("A skeleton clutches an ancient inscription...")
				"2":
					show_message("A vision flashes: shadows moving in moonlight...")

func show_message(text):
	message_label.text = text
	message_label.visible = true
	waiting_for_input = true
