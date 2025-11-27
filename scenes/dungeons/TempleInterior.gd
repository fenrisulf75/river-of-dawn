extends Spatial

# Temple of Yarikh - Interior entrance hall
# Simple room before descending to catacombs

const TILE_SIZE = 1.0

const ROOM_MAP = """##########
#........#
#........#
#...P....#
#........#
#........#
#...>....#
#........#
#...@....#
##########"""

# Colors
const COLOR_WALL = Color(0.8, 0.75, 0.65)
const COLOR_FLOOR = Color(0.7, 0.65, 0.55)
const COLOR_PRIEST = Color(0.9, 0.85, 0.7)
const COLOR_STAIRS = Color(0.6, 0.55, 0.5)

var player_x = 4
var player_y = 8
var player_rotation = 0  # Facing north toward priest
var is_moving = false
var is_rotating = false

var has_spoken_to_priest = false
var interactable_objects = {}

onready var camera = $Camera
onready var collision_body = $Camera/KinematicBody

func _ready():
	generate_room()
	position_player()
	PlayerData.in_dungeon = false  # Still in city

func generate_room():
	var lines = ROOM_MAP.split("\n")
	
	for row in range(lines.size()):
		var line = lines[row]
		for col in range(line.length()):
			var tile = line[col]
			var pos = Vector3(col - 5, 0, row - 5)
			
			match tile:
				"#":
					create_wall(pos)
				".":
					create_floor(pos)
				"@":
					create_floor(pos)
					player_x = col
					player_y = row
				"P":
					create_floor(pos)
					create_priest(pos)
					add_interactable(col, row, "priest", {})
				">":
					create_floor(pos)
					create_stairs_down(pos)
					add_interactable(col, row, "catacombs", {})

func create_wall(pos):
	var mesh_instance = MeshInstance.new()
	var mesh = CubeMesh.new()
	mesh.size = Vector3(1.0, 4.0, 1.0)
	mesh_instance.mesh = mesh
	
	var material = SpatialMaterial.new()
	material.albedo_color = COLOR_WALL
	mesh_instance.set_surface_material(0, material)
	
	mesh_instance.translation = pos + Vector3(0, 2.0, 0)
	add_child(mesh_instance)
	
	# Collision
	var static_body = StaticBody.new()
	var collision_shape = CollisionShape.new()
	var box_shape = BoxShape.new()
	box_shape.extents = Vector3(0.45, 2.0, 0.45)
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)
	mesh_instance.add_child(static_body)

func create_floor(pos):
	var mesh_instance = MeshInstance.new()
	var mesh = CubeMesh.new()
	mesh.size = Vector3(0.95, 0.1, 0.95)
	mesh_instance.mesh = mesh
	
	var material = SpatialMaterial.new()
	material.albedo_color = COLOR_FLOOR
	mesh_instance.set_surface_material(0, material)
	
	mesh_instance.translation = pos + Vector3(0, 0.05, 0)
	add_child(mesh_instance)

func create_priest(pos):
	var mesh_instance = MeshInstance.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.3
	mesh.bottom_radius = 0.3
	mesh.height = 1.8
	mesh_instance.mesh = mesh
	
	var material = SpatialMaterial.new()
	material.albedo_color = COLOR_PRIEST
	mesh_instance.set_surface_material(0, material)
	
	mesh_instance.translation = pos + Vector3(0, 0.9, 0)
	add_child(mesh_instance)

func create_stairs_down(pos):
	var mesh_instance = MeshInstance.new()
	var mesh = CubeMesh.new()
	mesh.size = Vector3(0.8, 0.3, 0.8)
	mesh_instance.mesh = mesh
	
	var material = SpatialMaterial.new()
	material.albedo_color = COLOR_STAIRS
	mesh_instance.set_surface_material(0, material)
	
	mesh_instance.translation = pos + Vector3(0, 0.2, 0)
	add_child(mesh_instance)

func add_interactable(col, row, type, data):
	interactable_objects[Vector2(col, row)] = {"type": type, "data": data}

func position_player():
	camera.translation = Vector3(player_x - 5, 1.6, player_y - 5)
	update_camera_rotation()

func update_camera_rotation():
	match player_rotation:
		0: camera.rotation_degrees = Vector3(0, 180, 0)
		1: camera.rotation_degrees = Vector3(0, 270, 0)
		2: camera.rotation_degrees = Vector3(0, 0, 0)
		3: camera.rotation_degrees = Vector3(0, 90, 0)

func _process(_delta):
	if MenuSystem.menu_open:
		return
	
	if is_moving or is_rotating:
		return
	
	if Input.is_action_just_pressed("ui_left"):
		rotate_player(-1)
	elif Input.is_action_just_pressed("ui_right"):
		rotate_player(1)
	elif Input.is_action_just_pressed("ui_up"):
		move_player_forward()
	elif Input.is_action_just_pressed("ui_down"):
		move_player_backward()
	elif Input.is_action_just_pressed("ui_accept"):
		check_interaction()

func rotate_player(direction):
	is_rotating = true
	player_rotation = (player_rotation + direction) % 4
	if player_rotation < 0:
		player_rotation = 3
	
	var tween = create_tween()
	var target_rot = Vector3(0, 0, 0)
	match player_rotation:
		0: target_rot.y = 180
		1: target_rot.y = 270
		2: target_rot.y = 0
		3: target_rot.y = 90
	tween.tween_property(camera, "rotation_degrees", target_rot, 0.2)
	tween.tween_callback(self, "finish_rotation")

func finish_rotation():
	is_rotating = false

func move_player_forward():
	var dx = 0
	var dy = 0
	match player_rotation:
		0: dy = -1
		1: dx = 1
		2: dy = 1
		3: dx = -1
	try_move(dx, dy)

func move_player_backward():
	var dx = 0
	var dy = 0
	match player_rotation:
		0: dy = 1
		1: dx = -1
		2: dy = -1
		3: dx = 1
	try_move(dx, dy)

func try_move(dx, dy):
	var new_x = player_x + dx
	var new_y = player_y + dy
	
	if is_walkable(new_x, new_y):
		is_moving = true
		player_x = new_x
		player_y = new_y
		
		var target_pos = Vector3(player_x - 5, 1.6, player_y - 5)
		var tween = create_tween()
		tween.tween_property(camera, "translation", target_pos, 0.15)
		tween.tween_callback(self, "finish_move")

func finish_move():
	is_moving = false

func is_walkable(x, y):
	var lines = ROOM_MAP.split("\n")
	if y >= 0 and y < lines.size():
		var line = lines[y]
		if x >= 0 and x < line.length():
			var tile = line[x]
			return tile in [".", "@", "P", ">"]
	return false

func check_interaction():
	var pos = Vector2(player_x, player_y)
	
	if interactable_objects.has(pos):
		var obj = interactable_objects[pos]
		
		match obj["type"]:
			"priest":
				speak_with_priest()
			"catacombs":
				if has_spoken_to_priest:
					enter_catacombs()
				else:
					print("Speak with the priest first...")

func speak_with_priest():
	if not has_spoken_to_priest:
		has_spoken_to_priest = true
		print("=== PRIEST OF YARIKH ===")
		print("Greetings, traveler.")
		print("You seek the moon god's blessing?")
		print("Descend into the catacombs and prove yourself.")
		print("\nThe trials await below...")
	else:
		print("May Yarikh guide your path...")

func enter_catacombs():
	print("You descend into darkness...")
	yield(get_tree().create_timer(1.0), "timeout")
	get_tree().change_scene("res://scenes/dungeons/CatacombsLevel1.tscn")
