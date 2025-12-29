extends Node
# MovementSystem3D - Handles held-input movement and rotation for 3D dungeon/city scenes
# This is an autoload singleton - accessible from any scene as "MovementSystem3D"

# === MOVEMENT SETTINGS ===
const MOVE_RATE = 0.3  # seconds per tile (2.5 tiles/second) - matches 2D
const INITIAL_MOVE_DELAY = 0.2  # delay before continuous movement starts

# === ROTATION SETTINGS ===
const ROTATE_RATE = 0.3  # seconds per 90-degree turn
const INITIAL_ROTATE_DELAY = 0.2  # delay before continuous rotation starts

# === INTERNAL STATE - MOVEMENT ===
var move_input_timer = 0.0
var move_delay_timer = 0.0
var current_move_direction = 0  # -1 = backward, 0 = none, 1 = forward
var is_holding_move = false

# === INTERNAL STATE - ROTATION ===
var rotate_input_timer = 0.0
var rotate_delay_timer = 0.0
var current_rotate_direction = 0  # -1 = left, 0 = none, 1 = right
var is_holding_rotate = false

# === CORE FUNCTION - MOVEMENT ===
# Call this every frame from your scene's _process(delta)
# Returns: int with movement direction (-1 backward, 0 none, 1 forward)
func process_movement_input(delta: float, is_currently_moving: bool) -> int:
	# Check which direction is being held
	var input_direction = 0
	if Input.is_action_pressed("ui_up"):
		input_direction = 1  # forward
	elif Input.is_action_pressed("ui_down"):
		input_direction = -1  # backward
	
	# If direction changed or released, reset timers
	if input_direction != current_move_direction:
		current_move_direction = input_direction
		move_delay_timer = 0.0
		move_input_timer = 0.0
		is_holding_move = false
		
		# On new press (not release), return immediate move
		if input_direction != 0 and not is_currently_moving:
			return input_direction
	
	# If holding a direction and not currently moving
	elif input_direction != 0 and not is_currently_moving:
		# Wait for initial delay before starting continuous movement
		if not is_holding_move:
			move_delay_timer += delta
			if move_delay_timer >= INITIAL_MOVE_DELAY:
				is_holding_move = true
				move_input_timer = 0.0
		else:
			# Continuous movement at MOVE_RATE
			move_input_timer += delta
			if move_input_timer >= MOVE_RATE:
				move_input_timer = 0.0
				return input_direction
	
	# No movement this frame
	return 0

# === CORE FUNCTION - ROTATION ===
# Call this every frame from your scene's _process(delta)
# Returns: int with rotation direction (-1 left/CCW, 0 none, 1 right/CW)
func process_rotation_input(delta: float, is_currently_rotating: bool) -> int:
	# Check which rotation is being held
	var input_direction = 0
	if Input.is_action_pressed("ui_left"):
		input_direction = 1  # rotate left (counter-clockwise, +90 degrees)
	elif Input.is_action_pressed("ui_right"):
		input_direction = -1  # rotate right (clockwise, -90 degrees)
	
	# If direction changed or released, reset timers
	if input_direction != current_rotate_direction:
		current_rotate_direction = input_direction
		rotate_delay_timer = 0.0
		rotate_input_timer = 0.0
		is_holding_rotate = false
		
		# On new press (not release), return immediate rotation
		if input_direction != 0 and not is_currently_rotating:
			return input_direction
	
	# If holding a direction and not currently rotating
	elif input_direction != 0 and not is_currently_rotating:
		# Wait for initial delay before starting continuous rotation
		if not is_holding_rotate:
			rotate_delay_timer += delta
			if rotate_delay_timer >= INITIAL_ROTATE_DELAY:
				is_holding_rotate = true
				rotate_input_timer = 0.0
		else:
			# Continuous rotation at ROTATE_RATE
			rotate_input_timer += delta
			if rotate_input_timer >= ROTATE_RATE:
				rotate_input_timer = 0.0
				return input_direction
	
	# No rotation this frame
	return 0

# === RESET FUNCTION ===
# Call this when entering/exiting menus or cutscenes
func reset():
	move_input_timer = 0.0
	move_delay_timer = 0.0
	current_move_direction = 0
	is_holding_move = false
	
	rotate_input_timer = 0.0
	rotate_delay_timer = 0.0
	current_rotate_direction = 0
	is_holding_rotate = false
