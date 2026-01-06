extends Spatial

# YERIHO - Using PassageToYeriho movement system

const tile_size = 1.0

const CITY_MAP = """################################
#.........:.....:.....:........#
#.........:.....:.....:........#
#..HHH.HHH:.....:....H:H.HHH...#
#..HHH.HHH:.....:....H:H.HHH...#
#.........:.....:.....:........#
#....HHH..:.....:.....:HH......#
#....HHH..:.....:.....:HH......#
#.........:.TTTTTTT...:........#
#.........:.TTTTTTT...:PP......#
#.........:.TTTTTTD::::PF::....#
#.........:.TTTTTTT...:........#
#.........:.TTTTTTT...:.@r.....#
#.........:.....:.....:........#
#bb.......:.....:.....:........#
==b:::::::::::::::mmGm:::::::::=
==::::::::::::::::mm:m::::::::.=
#bb.hhh...:.....:...hh:.hhh....#
#bbccSh.hh:.hhh.:...hh:.hhh....#
#..cc...hh:.hhh.:.....:.I......#
#..cc.hhh.:.....:...hh:........#
#..cc.hhh.:.....:...hh:........#
#.........:.....:.....:........#
################################"""

const COLOR_WALL = Color(0.6, 0.5, 0.4)
const COLOR_GROUND = Color(0.75, 0.68, 0.55)
const COLOR_STREET = Color(0.65, 0.58, 0.45)
const COLOR_TEMPLE = Color(0.9, 0.85, 0.7)
const COLOR_TEMPLE_DOOR = Color(0.9, 0.7, 0.2)
const COLOR_PLAZA = Color(0.8, 0.75, 0.6)
const COLOR_FOUNTAIN = Color(0.4, 0.6, 0.7)
const COLOR_HOUSE_UPPER = Color(0.8, 0.7, 0.55)
const COLOR_HOUSE_LOWER = Color(0.7, 0.6, 0.45)

var is_moving = false
var is_rotating = false
var waiting_for_input = false
var in_priest_menu = false

onready var camera = $Camera
onready var message_label = $MessageLabel
onready var priest_panel = $PriestPanel

# Texture preloading
var texture_mudbrick = null
var texture_temple = null
var texture_ground = null

func _ready():
	# Preload textures
	texture_mudbrick = load("res://assets/textures/walls/yeriho_mudbrick_wall_512.png")
	texture_temple = load("res://assets/textures/walls/temple_rust_red_512.png")
	texture_ground = load("res://assets/textures/ground/terrain/ground_sand_24.png")
	
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.35, 0.35, 0.4)
	env.ambient_light_color = Color(0.9, 0.9, 0.9)
	env.ambient_light_energy = 1.2
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	
	var light = DirectionalLight.new()
	light.rotation_degrees = Vector3(-50, 30, 0)
	light.light_energy = 0.9
	add_child(light)
	
	# Setup interaction popup (autoload singleton)
	InteractionPopup.connect("interaction_complete", self, "_on_interaction_choice")
	
	generate_city()
	position_camera_at_spawn()
	PlayerData.in_dungeon = false

func generate_city():
	var lines = CITY_MAP.split("\n")
	for row in range(lines.size()):
		var line = lines[row]
		for col in range(line.length()):
			var tile = line[col]
			var pos = Vector3(col - 16, 0, row - 12)
			
			match tile:
				"#", "=":
					create_wall(pos)
				".", ":":
					create_floor(pos)
				"T":
					create_temple(pos, col, row)
				"D":
					create_temple_door(pos)
				"P":
					create_floor(pos)
				"F":
					create_fountain(pos)
				"H":
					create_house(pos, COLOR_HOUSE_UPPER, 2.5)
				"h", "b", "c", "m":
					create_house(pos, COLOR_HOUSE_LOWER, 2.0)
				"r":
					create_rubble(pos)

func create_wall(pos):
	var mesh = MeshInstance.new()
	mesh.mesh = CubeMesh.new()
	mesh.mesh.size = Vector3(1.0, 3.0, 1.0)
	var mat = SpatialMaterial.new()
	
	# Use texture if loaded, otherwise fallback to color
	if texture_mudbrick:
		mat.albedo_texture = texture_mudbrick
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

func create_floor(pos):
	var mesh = MeshInstance.new()
	mesh.mesh = CubeMesh.new()
	mesh.mesh.size = Vector3(1.0, 0.1, 1.0)
	var mat = SpatialMaterial.new()
	
	# Use texture if loaded, otherwise fallback to color
	if texture_ground:
		mat.albedo_texture = texture_ground
		mat.uv1_scale = Vector3(1, 1, 1)  # Adjust tiling if needed
	else:
		mat.albedo_color = COLOR_GROUND
	
	mesh.set_surface_material(0, mat)
	mesh.translation = pos + Vector3(0, 0.05, 0)
	add_child(mesh)

func create_temple(pos, col, row):
	# All temple walls are solid with rust red texture
	var mesh = MeshInstance.new()
	mesh.mesh = CubeMesh.new()
	mesh.mesh.size = Vector3(1.0, 4.0, 1.0)
	var mat = SpatialMaterial.new()
	
	# Use rust red texture if loaded
	if texture_temple:
		mat.albedo_texture = texture_temple
	else:
		mat.albedo_color = COLOR_TEMPLE
	
	mesh.set_surface_material(0, mat)
	mesh.translation = pos + Vector3(0, 2.0, 0)
	add_child(mesh)
	
	var body = StaticBody.new()
	var shape = CollisionShape.new()
	shape.shape = BoxShape.new()
	shape.shape.extents = Vector3(0.48, 2.0, 0.48)
	body.add_child(shape)
	mesh.add_child(body)

func create_temple_door(pos):
	# Brown temple wall with NO collision
	create_floor(pos)
	var mesh = MeshInstance.new()
	mesh.mesh = CubeMesh.new()
	mesh.mesh.size = Vector3(1.0, 4.0, 1.0)
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(0.6, 0.45, 0.3)  # Brown door
	mesh.set_surface_material(0, mat)
	mesh.translation = pos + Vector3(0, 2.0, 0)
	add_child(mesh)
	# NO collision body - player walks through and triggers priest

func create_fountain(pos):
	create_floor(pos)
	var mesh = MeshInstance.new()
	mesh.mesh = CylinderMesh.new()
	mesh.mesh.top_radius = 0.4
	mesh.mesh.bottom_radius = 0.4
	mesh.mesh.height = 1.0
	var mat = SpatialMaterial.new()
	mat.albedo_color = COLOR_FOUNTAIN
	mesh.set_surface_material(0, mat)
	mesh.translation = pos + Vector3(0, 0.5, 0)
	add_child(mesh)

func create_house(pos, color, height):
	var mesh = MeshInstance.new()
	mesh.mesh = CubeMesh.new()
	mesh.mesh.size = Vector3(0.95, height, 0.95)
	var mat = SpatialMaterial.new()
	mat.albedo_color = color
	mesh.set_surface_material(0, mat)
	mesh.translation = pos + Vector3(0, height/2, 0)
	add_child(mesh)
	
	var body = StaticBody.new()
	var shape = CollisionShape.new()
	shape.shape = BoxShape.new()
	shape.shape.extents = Vector3(0.45, height/2, 0.45)
	body.add_child(shape)
	mesh.add_child(body)

func create_rubble(pos):
	var mesh = MeshInstance.new()
	mesh.mesh = CubeMesh.new()
	mesh.mesh.size = Vector3(1.0, 1.0, 1.0)
	var mat = SpatialMaterial.new()
	mat.albedo_color = Color(0.4, 0.35, 0.3)
	mesh.set_surface_material(0, mat)
	mesh.translation = pos + Vector3(0, 0.5, 0)
	add_child(mesh)
	
	var body = StaticBody.new()
	var shape = CollisionShape.new()
	shape.shape = BoxShape.new()
	shape.shape.extents = Vector3(0.48, 0.5, 0.48)
	body.add_child(shape)
	mesh.add_child(body)

func position_camera_at_spawn():
	camera.translation = Vector3(24 - 16, 1.6, 12 - 12)
	camera.rotation_degrees.y = 180

func _process(delta):
	if MenuSystem.menu_open:
		return
	
	if in_priest_menu:
		if Input.is_action_just_pressed("ui_accept"):
				# Enter catacombs
				in_priest_menu = false
				priest_panel.visible = false
				print("Yeriho: Attempting to load CatacombsLevel1.tscn")
				get_tree().change_scene("res://scenes/dungeons/CatacombsLevel1.tscn")
		elif Input.is_action_just_pressed("ui_cancel"):
			# Exit temple
			in_priest_menu = false
			priest_panel.visible = false
		return
	
	if waiting_for_input:
		if Input.is_action_just_pressed("ui_accept"):
			waiting_for_input = false
			message_label.visible = false
		return
	
	# Process held-input movement (forward/backward)
	var move_direction = MovementSystem3D.process_movement_input(delta, is_moving)
	if move_direction != 0:
		move_camera(move_direction)
	
	# Process held-input rotation (left/right)
	var rotate_direction = MovementSystem3D.process_rotation_input(delta, is_rotating)
	if rotate_direction != 0:
		# Convert to degrees: -1 (right/CW) = -90, 1 (left/CCW) = +90
		rotate_camera(rotate_direction * 90)

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
	check_temple_entry()

func finish_rotate():
	is_rotating = false

func check_temple_entry():
	# Check if there's a D tile in front of the player
	var pos = camera.translation
	var forward = -camera.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	
	# Get the grid position in front of player
	var front_pos = pos + forward
	var front_grid_x = int(round(front_pos.x + 16))
	var front_grid_z = int(round(front_pos.z + 12))
	
	# Check if tile in front is D
	var lines = CITY_MAP.split("\n")
	if front_grid_z >= 0 and front_grid_z < lines.size():
		var line = lines[front_grid_z]
		if front_grid_x >= 0 and front_grid_x < line.length():
			if line[front_grid_x] == 'D':
				show_priest_menu()

func show_priest_menu():
	in_priest_menu = true
	priest_panel.visible = true

func show_message(text):
	message_label.text = text
	message_label.visible = true
	waiting_for_input = true

# === INTERACTION POPUP HANDLER ===
func _on_interaction_choice(choice_id):
	if choice_id == null:
		return
	
	# Handle interaction choices for Yeriho city
	print("Yeriho: Player chose ", choice_id)
	# Add specific handlers as needed
