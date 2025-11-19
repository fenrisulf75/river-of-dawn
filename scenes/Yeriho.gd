extends Spatial

# Yeriho 16x16 ASCII map
const CITY_MAP = """

################
#......TT......#
#......TT......#
#..............#
#===..C....====#
#H==M..S..M====E
W==XH=M==MA====#
#H==M=O=M===H==#
#N==HH====HH=N=#
#L==K====F==L==#
#===S==P==S====#
#H==H====H==H==#
#.==R=====C==.=#
################
"""

# Prefab paths
var wallns_prefab = preload("res://prefabs/WallNS.tscn")
var wallew_prefab = preload("res://prefabs/WallEW.tscn")
var house_prefab = preload("res://prefabs/House.tscn")
var houseb_prefab = preload("res://prefabs/HouseB.tscn")
var housec_prefab = preload("res://prefabs/HouseC.tscn")
var temple_prefab = preload("res://prefabs/TempleBlock.tscn")
var market_prefab = preload("res://prefabs/MarketStall.tscn")
var tavern_prefab = preload("res://prefabs/Tavern.tscn")
var well_prefab = preload("res://prefabs/Well.tscn")
var shrine_prefab = preload("res://prefabs/Shrine.tscn")
var forge_prefab = preload("res://prefabs/Forge.tscn")
var cistern_prefab = preload("res://prefabs/Cistern.tscn")
var kiln_prefab = preload("res://prefabs/Kiln.tscn")
var granary_prefab = preload("res://prefabs/Granary.tscn")

# (then the rest of your existing code: tile_size, is_moving, camera, etc.)

var tile_size = 1.0
var is_moving = false
var is_rotating = false

onready var camera = $Camera

func _process(_delta):
	if is_moving or is_rotating:
		return
	
	if Input.is_action_just_pressed("ui_left"):
		rotate_camera(90)
	elif Input.is_action_just_pressed("ui_right"):
		rotate_camera(-90)
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

func finish_move():
	is_moving = false

func _ready():
	generate_city()
	# Spawn at street tile just west of East Gate
	camera.global_transform.origin = Vector3(6.5, 0.5, -0.5)
	camera.rotation_degrees.y = 90  # Face west into city

func generate_city():
	var lines = CITY_MAP.split("\n")
	var grid_size = 1.0  # Each character = 1 unit
	
	for row in range(lines.size()):
		var line = lines[row]
		for col in range(line.length()):
			var tile = line[col]
			var pos = Vector3(col - 8 + 0.5, 0, row - 8 + 0.5)  # Align to grid centers
			
			match tile:
				"#":
					# Use position to determine orientation
					# Top/bottom rows = E-W walls, left/right columns = N-S walls
					if row == 0 or row == lines.size() - 1:
						# Top or bottom edge = horizontal wall
						spawn_prefab(wallew_prefab, pos)
					elif col == 0 or col == line.length() - 1:
						# Left or right edge = vertical wall
						spawn_prefab(wallns_prefab, pos)
					else:
						# Interior walls - check neighbors
						var left_tile = line[col - 1] if col > 0 else " "
						var right_tile = line[col + 1] if col < line.length() - 1 else " "
						
						if left_tile == "#" or right_tile == "#":
							# Horizontal wall
							spawn_prefab(wallew_prefab, pos)
						else:
							# Vertical wall
							spawn_prefab(wallns_prefab, pos)
				"H":
					spawn_prefab(house_prefab, pos)
				"N":
					spawn_prefab(houseb_prefab, pos)
				"L":
					spawn_prefab(housec_prefab, pos)
				"T":
					if not has_node("Temple"):
						var temple = temple_prefab.instance()
						temple.name = "Temple"
						add_child(temple)
						temple.global_transform.origin = Vector3(0, 0, -6)
				"M":
					spawn_prefab(market_prefab, pos)
				"X":
					spawn_prefab(tavern_prefab, pos)
				"O":
					spawn_prefab(well_prefab, pos)
				"S":
					spawn_prefab(shrine_prefab, pos)
				"F":
					spawn_prefab(forge_prefab, pos)
				"C":
					spawn_prefab(cistern_prefab, pos)
				"K":
					spawn_prefab(kiln_prefab, pos)
				"R":
					spawn_prefab(granary_prefab, pos)
				"P":
					# Plaza - leave empty (walkable space)
					pass

func spawn_prefab(prefab, position):
	var instance = prefab.instance()
	add_child(instance)
	instance.global_transform.origin = Vector3(position.x, 0, position.z)  # Force Y to 0
