extends Node2D

# Starter Zone - Dead Sea Shore
# Top-down 2D overworld beginning area

# === MAP DATA ===
const ZONE_MAP = """##################XXXXXXXXXXXXXX
################...XXXXXXXXXXXXX
########.....D........XXXXXXXXXX
#######....###.........XXXXXXXXX
######...###..............XXXXXX
#####...#####.............XXXXXX
####...#######.............XXXXX
####...#######...............XXX
####...###S###...............XX~
###...###.::..................~~
###...###..:..................~~
###.K.###..::.................~~
###..#####..:.................~~
####.#####..:.............L...~~
##########.::.............!.~~~~
#########..:................~~~~
#########..:...XXX..........~~~~
########...:...XXXX.........~~~~
#######...::..XXXX........B.~~~~
##.###..:::...XXXX..........~~~~
##......:....XXXXX.........~~~~~
##.....::...XXXXXX........~~~~~~
#G::::::...XXXXXXX........~~~~~~
##.........XXXXXX.........~~~~~~
##.........XXXXXXX.......~~~~~~~
##........XXXXXXXX.......~~~~~~~
###.......XXXXXXX........~~~~~~~
###.......XXXXXXX.......~~~~~~~~
####......XXXXXXXX......~~~~~~~~
#######..XXXXXXXXX.....P~~~~~~~~
#########XXXXXXXXXXX....~~~~~~~~
################XXXXXXXX~~~~~~~~"""

# === TILE SETTINGS ===
const TILE_SIZE = 24  # pixels per tile
const MAP_WIDTH = 32
const MAP_HEIGHT = 32

# === COLORS ===
const COLOR_CLIFF = Color(0.27, 0.22, 0.18)  # Dark brown rock
const COLOR_BRINE = Color(0.65, 0.55, 0.25)  # Yellowish toxic
const COLOR_SEA = Color(0.15, 0.25, 0.35)     # Dark blue-grey
const COLOR_GROUND = Color(0.75, 0.68, 0.55)  # Sandy tan
const COLOR_PATH = Color(0.65, 0.58, 0.45)    # Worn path brown
const COLOR_PLAYER = Color(0.2, 0.6, 0.9)     # Blue
const COLOR_INTERACT = Color(0.0, 1.0, 1.0)   # Bright cyan
const COLOR_JACKAL = Color(1.0, 0.2, 0.2)     # Bright red for jackal
const COLOR_FOG = Color(0.0, 0.0, 0.0)        # Black fog of war

# === PLAYER STATE ===
var player_grid_x = 0
var player_grid_y = 0
var is_moving = false
var has_dagger = false
var has_armor = false
var has_key = false
var dog_defeated = false
var examined_skeleton = false
var examined_satchel = false
var dog_triggered = false  # Track if jackal combat has been triggered
var movement_speed = 0.15  # seconds per tile

# === FOG OF WAR ===
var fog_tiles = {}  # {Vector2(x,y): ColorRect node}
var explored_tiles = {}  # {Vector2(x,y): true}
const VISION_RADIUS = 3  # How many tiles player can see

# === INTERACTION STATE ===
var interactable_objects = {}  # {grid_pos: {type, used, data}}
var required_interactions = {}  # Track which interactions are required first time

# === REFERENCES ===
onready var camera = $Camera2D
onready var message_label = $UI/MessageLabel
onready var prompt_label = $UI/PromptLabel
onready var combat_ui = $CombatUI
var waiting_for_input = false
var current_message = ""
var in_combat = false

func _ready():
	# Set viewport background to black
	VisualServer.set_default_clear_color(Color(0, 0, 0))
	
	# Show HUD for gameplay
	if has_node("/root/HUD"):
		get_node("/root/HUD").show()
	
	# Generate the map
	generate_zone()
	
	# Find and set player spawn
	find_spawn_point()
	
	# Create fog of war layer
	create_fog_of_war()
	
	# Center camera on player
	update_camera()
	
	# Setup UI
	message_label.visible = false
	prompt_label.visible = false
	
	# Setup combat
	combat_ui.connect("combat_finished", self, "on_combat_finished")
	
	# Initial vision reveal
	update_fog_of_war()
	
	# Show intro message
	yield(get_tree().create_timer(0.5), "timeout")
	show_message("You awaken on sun-scorched sand, the Salt Sea stretching before you.\nDesert cliffs behind. Poisonous brine pits ahead.\nNo memory of how you came to be here.\n\nBut something drives you onward...\n\nPress SPACE to continue")

func create_fog_of_war():
	# Create black fog tiles over entire map
	var lines = ZONE_MAP.split("\n")
	for row in range(lines.size()):
		var line = lines[row]
		for col in range(line.length()):
			var pos = Vector2(col, row)
			var screen_pos = Vector2(col * TILE_SIZE, row * TILE_SIZE)
			
			var fog = ColorRect.new()
			fog.rect_position = screen_pos
			fog.rect_size = Vector2(TILE_SIZE, TILE_SIZE)
			fog.color = COLOR_FOG
			fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fog.name = "Fog_%d_%d" % [col, row]
			add_child(fog)
			
			fog_tiles[pos] = fog

func update_fog_of_war():
	# Reveal tiles within vision radius
	var player_pos = Vector2(player_grid_x, player_grid_y)
	
	for y in range(player_grid_y - VISION_RADIUS, player_grid_y + VISION_RADIUS + 1):
		for x in range(player_grid_x - VISION_RADIUS, player_grid_x + VISION_RADIUS + 1):
			var tile_pos = Vector2(x, y)
			
			# Check if within map bounds
			if x >= 0 and x < MAP_WIDTH and y >= 0 and y < MAP_HEIGHT:
				# Check if within vision radius (circular)
				if player_pos.distance_to(tile_pos) <= VISION_RADIUS:
					reveal_tile(tile_pos)

func reveal_tile(tile_pos):
	# Mark as explored
	explored_tiles[tile_pos] = true
	
	# Remove fog
	if fog_tiles.has(tile_pos):
		fog_tiles[tile_pos].queue_free()
		fog_tiles.erase(tile_pos)

func generate_zone():
	var lines = ZONE_MAP.split("\n")
	
	for row in range(lines.size()):
		var line = lines[row]
		for col in range(line.length()):
			var tile = line[col]
			var pos = Vector2(col * TILE_SIZE, row * TILE_SIZE)
			
			match tile:
				"#":
					draw_tile(pos, COLOR_CLIFF, "res://assets/textures/ground/ground_cliff_24.png")
				"X":
					draw_tile(pos, COLOR_BRINE, "res://assets/textures/ground/ground_brine_24.png")
				"~":
					draw_tile(pos, COLOR_SEA, "res://assets/textures/ground/ground_sea_24.png")
				".":
					draw_tile(pos, COLOR_GROUND, "res://assets/textures/ground/ground_sand_24.png")
				":":
					draw_tile(pos, COLOR_PATH, "res://assets/textures/ground/ground_path_24.png")
				"P":
					draw_tile(pos, COLOR_GROUND, "res://assets/textures/ground/ground_sand_24.png")
					player_grid_x = col
					player_grid_y = row
				"G":
					draw_tile(pos, COLOR_PATH, "res://assets/textures/ground/ground_path_24.png")
					add_interactable(col, row, "cave", {"locked": true})
					draw_marker(pos, "G", COLOR_INTERACT)
					required_interactions[Vector2(col, row)] = true  # Always check on step
				"S":
					draw_tile(pos, COLOR_GROUND, "res://assets/textures/ground/ground_sand_24.png")
					add_interactable(col, row, "shrine", {"visited": false})
					draw_marker(pos, "S", COLOR_INTERACT)
					required_interactions[Vector2(col, row)] = true
				"D":
					draw_tile(pos, COLOR_GROUND, "res://assets/textures/ground/ground_sand_24.png")
					add_interactable(col, row, "jackal", {"alive": true})
					# Don't draw marker yet - will appear after satchel is examined
				"K":
					draw_tile(pos, COLOR_GROUND, "res://assets/textures/ground/ground_sand_24.png")
					add_interactable(col, row, "satchel", {"examined": false})
					# Don't draw marker yet - will appear after skeleton
					# Don't add to required_interactions yet - skeleton reveals it
				"L":
					draw_tile(pos, COLOR_GROUND, "res://assets/textures/ground/ground_sand_24.png")
					add_interactable(col, row, "loot", {"taken": false})
					# Don't draw marker yet - will appear after skeleton
					# Don't add to required_interactions yet - skeleton reveals it
				"!":
					draw_tile(pos, COLOR_GROUND, "res://assets/textures/ground/ground_sand_24.png")
					add_interactable(col, row, "skeleton", {"examined": false})
					draw_marker(pos, "!", COLOR_INTERACT)
					required_interactions[Vector2(col, row)] = true
				"B":
					draw_tile(pos, COLOR_GROUND, "res://assets/textures/ground/ground_sand_24.png")
					add_interactable(col, row, "lore_stone", {"read": false})
					draw_marker(pos, "B", COLOR_INTERACT)
					required_interactions[Vector2(col, row)] = true
	
	# Draw player
	draw_player()

func draw_tile(pos, color, texture_path = ""):
	if texture_path != "":
		# Use sprite with texture
		var sprite = Sprite.new()
		var tex = load(texture_path)
		if tex:
			sprite.texture = tex
			sprite.position = pos + Vector2(TILE_SIZE/2, TILE_SIZE/2)
			sprite.centered = true
			add_child(sprite)
			return
	
	# Fallback to colored rectangle
	var rect = ColorRect.new()
	rect.rect_position = pos
	rect.rect_size = Vector2(TILE_SIZE, TILE_SIZE)
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)

func draw_marker(pos, text, color):
	var label = Label.new()
	label.rect_position = pos + Vector2(TILE_SIZE / 4, TILE_SIZE / 8)
	label.text = text
	label.add_color_override("font_color", color)
	# Note: add_font_size_override doesn't exist in Godot 3.x - removed
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func draw_player():
	var player_sprite = ColorRect.new()
	player_sprite.name = "Player"
	player_sprite.rect_size = Vector2(TILE_SIZE * 0.6, TILE_SIZE * 0.6)
	player_sprite.color = COLOR_PLAYER
	player_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(player_sprite)
	update_player_visual()

func update_player_visual():
	var player = get_node_or_null("Player")
	if player:
		var center_offset = Vector2(TILE_SIZE * 0.2, TILE_SIZE * 0.2)
		player.rect_position = Vector2(player_grid_x * TILE_SIZE, player_grid_y * TILE_SIZE) + center_offset

func add_interactable(x, y, type, data):
	var key = Vector2(x, y)
	interactable_objects[key] = {
		"type": type,
		"data": data
	}

func find_spawn_point():
	var lines = ZONE_MAP.split("\n")
	for row in range(lines.size()):
		var line = lines[row]
		for col in range(line.length()):
			if line[col] == "P":
				player_grid_x = col
				player_grid_y = row
				return

func _process(_delta):
	if in_combat:
		return
	
	# Block all input if menu is open
	if MenuSystem.menu_open:
		return
	
	if waiting_for_input:
		if Input.is_action_just_pressed("ui_accept"):
			waiting_for_input = false
			message_label.visible = false
			
			# Update prompt now that message is gone
			update_prompt()
			
			# Check if we're at cave entrance with key
			check_cave_entry()
		return
	
	if is_moving:
		return
	
	# Check for interaction - ONLY on current tile, not adjacent
	if Input.is_action_just_pressed("ui_accept"):
		check_interaction()
		return
	
	# Movement
	var dx = 0
	var dy = 0
	
	if Input.is_action_just_pressed("ui_up"):
		dy = -1
	elif Input.is_action_just_pressed("ui_down"):
		dy = 1
	elif Input.is_action_just_pressed("ui_left"):
		dx = -1
	elif Input.is_action_just_pressed("ui_right"):
		dx = 1
	
	if dx != 0 or dy != 0:
		attempt_move(dx, dy)

func attempt_move(dx, dy):
	var target_x = player_grid_x + dx
	var target_y = player_grid_y + dy
	
	# Bounds check
	if target_x < 0 or target_x >= MAP_WIDTH or target_y < 0 or target_y >= MAP_HEIGHT:
		return
	
	# Check if tile is walkable
	if is_walkable(target_x, target_y):
		is_moving = true
		player_grid_x = target_x
		player_grid_y = target_y
		
		# Animate movement
		var tween = create_tween()
		var player = get_node("Player")
		var target_pos = Vector2(target_x * TILE_SIZE, target_y * TILE_SIZE) + Vector2(TILE_SIZE * 0.2, TILE_SIZE * 0.2)
		tween.tween_property(player, "rect_position", target_pos, movement_speed)
		tween.tween_callback(self, "finish_move")
		
		update_camera()
		
		# Update fog of war
		update_fog_of_war()
		
		# Check for hazard proximity
		check_hazards(target_x, target_y)

func is_walkable(x, y):
	var lines = ZONE_MAP.split("\n")
	if y >= 0 and y < lines.size():
		var line = lines[y]
		if x >= 0 and x < line.length():
			var tile = line[x]
			# Walkable tiles
			return tile in [".", ":", "P", "G", "S", "D", "K", "L", "!", "B"]
	return false

func finish_move():
	is_moving = false
	check_triggers()
	# Only update prompt if not waiting for input (no message showing)
	if not waiting_for_input:
		update_prompt()

func check_triggers():
	var pos = player_grid_pos()
	
	# Check if we landed on a required interaction tile
	if required_interactions.has(pos):
		if interactable_objects.has(pos):
			var obj = interactable_objects[pos]
			var data = obj["data"]
			
			# Don't auto-trigger if already completed
			if data.has("examined") and data["examined"]:
				required_interactions.erase(pos)
				return
			if data.has("taken") and data["taken"]:
				required_interactions.erase(pos)
				return
			if data.has("read") and data["read"]:
				required_interactions.erase(pos)
				return
			if data.has("visited") and data["visited"]:
				required_interactions.erase(pos)
				return
			
			# Auto-trigger required interactions
			interact_with(obj["type"], obj["data"], pos)
			
			# Don't erase cave from required_interactions - check every time
			if obj["type"] != "cave":
				required_interactions.erase(pos)  # No longer required after first trigger
			return
	
	# Check if jackal should attack after satchel examination
	# Jackal attacks when player reaches the D marker position
	if examined_satchel and not dog_defeated and not dog_triggered:
		var dog_pos = find_tile_position("D")
		if dog_pos != Vector2(-1, -1):
			# If player is at or very close to dog position
			if pos.distance_to(dog_pos) < 1.5:
				dog_triggered = true
				trigger_dog_encounter()

func check_hazards(x, y):
	# Check adjacent tiles for brine pits
	var lines = ZONE_MAP.split("\n")
	var adjacent = [
		Vector2(x-1, y), Vector2(x+1, y),
		Vector2(x, y-1), Vector2(x, y+1)
	]
	
	for adj in adjacent:
		if adj.y >= 0 and adj.y < lines.size():
			var line = lines[int(adj.y)]
			if adj.x >= 0 and adj.x < line.length():
				if line[int(adj.x)] == "X":
					show_quick_message("The fumes sting your lungs.", 1.5)
					return

func check_interaction():
	var pos = player_grid_pos()
	
	# ONLY check current tile - no adjacent checking
	if interactable_objects.has(pos):
		var obj = interactable_objects[pos]
		interact_with(obj["type"], obj["data"], pos)

func interact_with(type, data, pos):
	match type:
		"loot":
			if not data["taken"]:
				show_message("You find a rust-pocked dagger and tattered cloth armor.\n\n[TUTORIAL]\nPress TAB to open your inventory.\nSelect items and press SPACE to equip them.\nEquipped items increase your combat effectiveness.\n\nPress SPACE to continue")
				data["taken"] = true
				PlayerData.has_dagger = true
				PlayerData.has_armor = true
				remove_marker_at(pos)
				# Also remove from interactables so no more prompt
				interactable_objects.erase(pos)
		
		"skeleton":
			if not data["examined"]:
				show_message("A skeleton reaches toward something...\n\nA note clutched in bone fingers reads:\n\n\"Jackals attacked... Took my food satchel...\nIn my ignorance I left the key inside it...\nIf only I could have reached my dagger...\nMay Ba'al forgive my ignorance.\"\n\nPress SPACE to continue")
				data["examined"] = true
				examined_skeleton = true
				# Don't remove marker - keep "!" visible
				
				# Reveal K and L markers AND make them auto-trigger
				var satchel_pos = find_tile_position("K")
				if satchel_pos != Vector2(-1, -1):
					var satchel_screen_pos = Vector2(satchel_pos.x * TILE_SIZE, satchel_pos.y * TILE_SIZE)
					draw_marker(satchel_screen_pos, "K", COLOR_INTERACT)
					required_interactions[satchel_pos] = true  # Make K auto-trigger
				
				var loot_pos = find_tile_position("L")
				if loot_pos != Vector2(-1, -1):
					var loot_screen_pos = Vector2(loot_pos.x * TILE_SIZE, loot_pos.y * TILE_SIZE)
					draw_marker(loot_screen_pos, "L", COLOR_INTERACT)
					required_interactions[loot_pos] = true  # Make L auto-trigger
			else:
				# Can re-read the note
				show_message("The keeper's note:\n\n\"Jackals attacked... Took my food satchel...\nIn my ignorance I left the key inside it...\nIf only I could have reached my dagger...\nMay Ba'al forgive my ignorance.\"\n\nPress SPACE to continue")
		
		"lore_stone":
			if not data["read"]:
				# First time - auto-trigger
				show_message("A carved warning stone:\n\nYām ha-Melaḥ — The Salt Sea.\nA place forsaken by gods and men.\n\nPress SPACE to continue")
				data["read"] = true
			else:
				# Subsequent visits - player can read again
				show_message("A carved warning stone:\n\nYām ha-Melaḥ — The Salt Sea.\nA place forsaken by gods and men.\n\nPress SPACE to continue")
		
		"satchel":
			if not data["examined"]:
				show_message("A torn satchel lies in the canyon.\n\nInside: food scraps, puncture marks.\nNo key.\n\nPress SPACE to continue")
				data["examined"] = true
				examined_satchel = true
				remove_marker_at(pos)
				
				# Show the jackal marker now that player knows about the threat
				var dog_pos = find_tile_position("D")
				if dog_pos != Vector2(-1, -1):
					var dog_screen_pos = Vector2(dog_pos.x * TILE_SIZE, dog_pos.y * TILE_SIZE)
					draw_marker(dog_screen_pos, "D", COLOR_JACKAL)
			else:
				# Can re-examine
				show_message("The torn satchel with food scraps and puncture marks.\n\nPress SPACE to continue")
		
		"shrine":
			if not data["visited"]:
				# First time - auto-trigger
				show_message("A forgotten shrine to Ba'al.\nThe keeper never returned.\n\nPress SPACE to continue")
				data["visited"] = true
			else:
				# Subsequent visits - can re-examine
				show_message("A forgotten shrine to Ba'al.\nThe keeper never returned.\n\nPress SPACE to continue")
		
		"cave":
			if data["locked"] and not PlayerData.has_key:
				show_message("The cave entrance is locked.\nYou need a key.\n\nPress SPACE to continue")
				# Don't remove from required_interactions - check again next time
			elif PlayerData.has_key:
				show_message("The key fits. Wind howls from within...\n\nPress SPACE to enter")
				# Will trigger transition on next accept
				# Don't remove from required_interactions yet
		
		"jackal":
			# Jackal is only triggered via check_triggers, not direct interaction
			pass

func trigger_dog_encounter():
	in_combat = true
	prompt_label.visible = false
	combat_ui.start_combat(has_dagger)

func on_combat_finished(player_won):
	in_combat = false
	
	if player_won:
		PlayerData.has_key = true
		dog_defeated = true
		
		# Remove jackal marker
		var dog_pos = find_tile_position("D")
		if dog_pos != Vector2(-1, -1):
			remove_marker_at(dog_pos)
			# Also remove from interactables
			interactable_objects.erase(dog_pos)
		
		show_message("The sickly jackal falls.\n\nYour final blow splits its swollen belly—\nsomething gleams within the gore.\n\nA key! The keeper's key!\n\nPress SPACE to continue")
	else:
		show_message("You have been defeated...\n\nGame Over\n\nPress SPACE to restart")
		yield(get_tree().create_timer(1.0), "timeout")
		waiting_for_input = false
		# Reset to spawn
		find_spawn_point()
		update_player_visual()
		update_camera()

func show_message(text):
	message_label.text = text
	message_label.visible = true
	waiting_for_input = true
	prompt_label.visible = false

func show_quick_message(text, duration):
	message_label.text = text
	message_label.visible = true
	yield(get_tree().create_timer(duration), "timeout")
	message_label.visible = false

func update_prompt():
	var pos = player_grid_pos()
	
	# ONLY check current tile for interactions
	if interactable_objects.has(pos):
		var obj = interactable_objects[pos]
		var data = obj["data"]
		
		# Don't show prompt for jackal (it's auto-triggered)
		if obj["type"] == "jackal":
			prompt_label.visible = false
			return
		
		# Don't show prompt for K or L if skeleton hasn't been examined yet
		if (obj["type"] == "satchel" or obj["type"] == "loot") and not examined_skeleton:
			prompt_label.visible = false
			return
		
		# Don't show prompt if this is a required interaction that's been completed
		if required_interactions.has(pos):
			# Check if it's been examined/taken/read
			if data.has("examined") and data["examined"]:
				prompt_label.visible = false
				return
			if data.has("taken") and data["taken"]:
				prompt_label.visible = false
				return
			if data.has("read") and data["read"]:
				prompt_label.visible = false
				return
			if data.has("visited") and data["visited"]:
				prompt_label.visible = false
				return
		
		# Show prompt for optional interactions and unexamined required ones
		prompt_label.text = "Press SPACE to interact"
		prompt_label.visible = true
		return
	
	prompt_label.visible = false

func update_camera():
	camera.position = Vector2(player_grid_x * TILE_SIZE, player_grid_y * TILE_SIZE)

func player_grid_pos():
	return Vector2(player_grid_x, player_grid_y)

func find_tile_position(tile_char):
	var lines = ZONE_MAP.split("\n")
	for row in range(lines.size()):
		var line = lines[row]
		for col in range(line.length()):
			if line[col] == tile_char:
				return Vector2(col, row)
	return Vector2(-1, -1)

func remove_marker_at(pos):
	# Find and remove the marker label at this position
	for child in get_children():
		if child is Label:
			var marker_grid = Vector2(int(child.rect_position.x / TILE_SIZE), int(child.rect_position.y / TILE_SIZE))
			if marker_grid == pos:
				child.queue_free()
				return

func check_cave_entry():
	var pos = player_grid_pos()
	var cave_pos = find_tile_position("G")
	
	# Check if player is at cave
	if pos == cave_pos:
		if PlayerData.has_key:
			# Transition to PassageToYeriho
			show_message("Wind rushes through the cave...\n\nTransitioning to Cave of Collapse")
			yield(get_tree().create_timer(2.0), "timeout")
			get_tree().change_scene("res://scenes/PassageToYeriho.tscn")
