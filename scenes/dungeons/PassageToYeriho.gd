extends Spatial
# PassageToYeriho - Transition dungeon from starter zone to Yeriho

const PASSAGE_MAP = """
#############E##
#############7##
##2####~~.###.##
##.##.#~..###.##
##....83..###.##
##..~~#...###6##
##..~~#..###...#
##...##..###...#
##...##...##...#
##...###..##...#
#~..~###..##...#
#~..~##...##...#
#~.~~##~..94...#
#~1~###~~##~~.5#
##@#############
################
"""

onready var camera = $Camera
onready var message_label = $Label

# Texture preloading
var texture_cave_wall = null
var texture_cave_floor = null
var texture_water = null

# Cave materials/meshes (fallback colors)
var wall_color = Color(0.29, 0.29, 0.29)  # Dark grey stone
var floor_color = Color(0.35, 0.35, 0.35)  # Slightly lighter
var water_color = Color(0.17, 0.31, 0.44)  # Dark blue

var is_moving = false
var is_rotating = false
var tile_size = 1.0
var collapsed_points = []
var last_grid_position = Vector3.ZERO
var waiting_for_input = false
var first_move = true
var shown_point1_message = false

func _ready():
	# Preload textures
	texture_cave_wall = load("res://assets/textures/walls/cave_stone_wall_512.png")
	texture_cave_floor = load("res://assets/textures/ground/terrain/ground_cliff_24.png")
	
	generate_passage()

func generate_passage():
	var lines = PASSAGE_MAP.split("\n")
	
	for row in range(lines.size()):
		var line = lines[row]
		for col in range(line.length()):
			var tile = line[col]
			var pos = Vector3(col - 8 + 0.5, 0, row - 8 + 0.5)
			
			match tile:
				"#":
					spawn_wall(pos)
				".":
					spawn_floor(pos)
					spawn_ceiling(pos)
				"~":
					spawn_water(pos)
					spawn_ceiling(pos)
				"@":
					camera.global_transform.origin = Vector3(pos.x, 0.5, pos.z)
					spawn_floor(pos)
					spawn_ceiling(pos)
				"1", "2", "3", "4", "5", "6", "7", "8", "9":
					spawn_floor(pos)
					spawn_ceiling(pos)
				"E":
					spawn_floor(pos)
					spawn_ceiling(pos)
				"+":
					spawn_floor(pos)
					spawn_ceiling(pos)
					
func spawn_wall(position):
	var wall = MeshInstance.new()
	var mesh = CubeMesh.new()
	mesh.size = Vector3(1, 3, 1)
	wall.mesh = mesh
	
	var material = SpatialMaterial.new()
	
	# Use texture if loaded, otherwise fallback to color
	if texture_cave_wall:
		material.albedo_texture = texture_cave_wall
	else:
		material.albedo_color = wall_color
	
	wall.set_surface_material(0, material)
	
	add_child(wall)
	wall.global_transform.origin = Vector3(position.x, 1.5, position.z)
	
	# Add collision
	var body = StaticBody.new()
	wall.add_child(body)
	var shape = CollisionShape.new()
	var box = BoxShape.new()
	box.extents = Vector3(0.45, 1.5, 0.45)
	shape.shape = box
	body.add_child(shape)

func spawn_floor(position):
	var floor_tile = MeshInstance.new()
	var mesh = CubeMesh.new()
	mesh.size = Vector3(1, 0.1, 1)
	floor_tile.mesh = mesh
	
	var material = SpatialMaterial.new()
	
	# Use texture if loaded, otherwise fallback to color
	if texture_cave_floor:
		material.albedo_texture = texture_cave_floor
		material.uv1_scale = Vector3(1, 1, 1)
	else:
		material.albedo_color = floor_color
	
	floor_tile.set_surface_material(0, material)
	
	add_child(floor_tile)
	floor_tile.global_transform.origin = Vector3(position.x, 0.05, position.z)

func spawn_water(position):
	var water = MeshInstance.new()
	var mesh = CubeMesh.new()
	mesh.size = Vector3(1, 0.1, 1)
	water.mesh = mesh
	
	var material = SpatialMaterial.new()
	material.albedo_color = water_color
	
	water.set_surface_material(0, material)
	
	add_child(water)
	water.global_transform.origin = Vector3(position.x, 0, position.z)
	
	# Add collision so you can't walk on water
	var body = StaticBody.new()
	water.add_child(body)
	var shape = CollisionShape.new()
	var box = BoxShape.new()
	box.extents = Vector3(0.45, 0.05, 0.45)
	shape.shape = box
	body.add_child(shape)

func spawn_ceiling(position):
	var ceiling = MeshInstance.new()
	var mesh = CubeMesh.new()
	mesh.size = Vector3(1, 0.1, 1)
	ceiling.mesh = mesh
	
	var material = SpatialMaterial.new()
	
	# Use same texture as walls for ceiling
	if texture_cave_wall:
		material.albedo_texture = texture_cave_wall
	else:
		material.albedo_color = wall_color
	
	ceiling.set_surface_material(0, material)
	
	add_child(ceiling)
	ceiling.global_transform.origin = Vector3(position.x, 2.45, position.z)
	
func _process(_delta):
	# Block all input if menu is open
	if MenuSystem.menu_open:
		return

	if waiting_for_input:
		if Input.is_action_just_pressed("ui_accept"):  # SPACE or ENTER
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

func move_camera(direction):
	is_moving = true
	
	var forward = -camera.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	
	var target_position = camera.global_transform.origin + (forward * tile_size * direction)
	
	# Get the KinematicBody
	var body = camera.get_node("KinematicBody")
	
	# Test the move
	var collision = body.move_and_collide(forward * tile_size * direction, true, true, true)
	
	if collision:
		is_moving = false
		return
	
	# No collision, move
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
	var current_pos = camera.global_transform.origin
	
	if first_move:
		first_move = false
		show_entrance_message()
	else:
		check_current_tile(current_pos)  # Check tile we're standing on
		check_point1_message(current_pos)
	
	check_exit(current_pos)
	
func finish_rotate():
	is_rotating = false

func check_collapse_point(position):
	var forward = -camera.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	
	var behind = -forward
	var behind_pos = position + behind * 1.0
	
	var check_x = int(round(behind_pos.x + 8 - 0.5))
	var check_z = int(round(behind_pos.z + 8 - 0.5))
	
	var lines = PASSAGE_MAP.split("\n")
	
	if check_z >= 0 and check_z < lines.size():
		var line = lines[check_z]
		if check_x >= 0 and check_x < line.length():
			var tile = line[check_x]
			
			if tile in ["3", "4"] and not tile in collapsed_points:
				collapsed_points.append(tile)
				
				# Find the wall spawn position (8 for 3, 9 for 4)
				var wall_tile = "8" if tile == "3" else "9"
				var wall_pos = find_tile_position(wall_tile)
				
				trigger_collapse(tile, wall_pos)
				
func check_point1_message(position):
	if shown_point1_message:
		return
	
	var grid_x = int(round(position.x + 8 - 0.5))
	var grid_z = int(round(position.z + 8 - 0.5))
	
	var lines = PASSAGE_MAP.split("\n")
	if grid_z >= 0 and grid_z < lines.size():
		var line = lines[grid_z]
		if grid_x >= 0 and grid_x < line.length():
			var tile = line[grid_x]
			
			if tile == "1":
				shown_point1_message = true
				message_label.text = "The passage has collapsed here.\nYou must press forward.\n\nPress SPACE to continue"
				message_label.visible = true
				waiting_for_input = true
				
func check_exit(position):
	var grid_x = int(round(position.x + 8 - 0.5))
	var grid_z = int(round(position.z + 8 - 0.5))
	
	var lines = PASSAGE_MAP.split("\n")
	if grid_z >= 0 and grid_z < lines.size():
		var line = lines[grid_z]
		if grid_x >= 0 and grid_x < line.length():
			var tile = line[grid_x]
			
			if tile == "E":
				trigger_exit()

func trigger_collapse(point_id, collapse_position):
	print("Collapse point ", point_id, " triggered at: ", collapse_position)
	
	# Spawn rubble at the exact collapse point
	spawn_wall(collapse_position)
	
	# Show message and wait for player
	message_label.text = "The cave collapses behind you!\n\nPress SPACE to continue"
	message_label.visible = true
	waiting_for_input = true
	
	# Hide message after 3 seconds
	yield(get_tree().create_timer(3.0), "timeout")
	message_label.visible = false

func trigger_exit():
	print("Reached exit to Yeriho!")
	# Show message
	message_label.text = "You see light ahead... Yeriho awaits."
	message_label.visible = true
	
	# Transition after 2 seconds
	yield(get_tree().create_timer(2.0), "timeout")
	get_tree().change_scene("res://scenes/cities/Yeriho.tscn")
	
func show_entrance_message():
	message_label.text = "The passage collapses behind you.\nThere's no turning back now.\n\nPress SPACE to continue"
	message_label.visible = true
	waiting_for_input = true
	
func find_tile_position(target_tile):
	var lines = PASSAGE_MAP.split("\n")
	for row in range(lines.size()):
		var line = lines[row]
		for col in range(line.length()):
			if line[col] == target_tile:
				return Vector3(col - 8 + 0.5, 0, row - 8 + 0.5)
	return Vector3.ZERO

func check_current_tile(position):
	var grid_x = int(round(position.x + 8 - 0.5))
	var grid_z = int(round(position.z + 8 - 0.5))
	
	var lines = PASSAGE_MAP.split("\n")
	if grid_z >= 0 and grid_z < lines.size():
		var line = lines[grid_z]
		if grid_x >= 0 and grid_x < line.length():
			var tile = line[grid_x]
			
			if tile in ["3", "4"] and not tile in collapsed_points:
				collapsed_points.append(tile)
				
				var wall_tile = "8" if tile == "3" else "9"
				var wall_pos = find_tile_position(wall_tile)
				
				trigger_collapse(tile, wall_pos)
