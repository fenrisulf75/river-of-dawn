extends Spatial

# Yeriho 16x16 ASCII map
const CITY_MAP = """
################
#..==BBBBBB==..#
#..=B......B=..#
#..=B...D..B=..#
#..=B......B=..#
#..==BBBBBB==..#
#====.?C...====#
#H==M..S..M===E
W===T==M==A====#
#H==M==O==M==H=#
#N.=HH==..==HN.#
#..==K=...=F===#
#==.S==P==S..==#
#H.==H====H==..#
#.==R==...==C=.#
################
"""

# Prefab paths
var wall_prefab = preload("res://prefabs/WallSegment.tscn")
var house_prefab = preload("res://prefabs/House.tscn")
var temple_prefab = preload("res://prefabs/TempleBlock.tscn")
var market_prefab = preload("res://prefabs/MarketStall.tscn")

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
		# Hit something, don't move
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

func generate_city():
	var lines = CITY_MAP.split("\n")
	var grid_size = 1.0  # Each character = 1 unit
	
	for row in range(lines.size()):
		var line = lines[row]
		for col in range(line.length()):
			var tile = line[col]
			var pos = Vector3(col - 8, 0, row - 8) 
			
			match tile:
				"#":
					spawn_prefab(wall_prefab, pos)
				"H", "N":
					print("House at: ", pos)
					spawn_prefab(house_prefab, pos)
				"B":
					print("Temple at: ", pos)
					spawn_prefab(temple_prefab, pos)
				"M":
					print("Market at: ", pos)
					spawn_prefab(market_prefab, pos)
				# Add more as needed: T, S, O, etc.

func spawn_prefab(prefab, position):
	var instance = prefab.instance()
	add_child(instance)
	instance.global_transform.origin = Vector3(position.x, 0, position.z)  # Force Y to 0
