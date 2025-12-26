extends Node
# MovementSystem2D - Handles held-input movement for all 2D overworld scenes
# This is an autoload singleton - accessible from any scene as "MovementSystem2D"

# === MOVEMENT SETTINGS ===
const MOVE_RATE = 0.4  # seconds per tile (2.5 tiles/second)
const INITIAL_MOVE_DELAY = 0.2  # delay before continuous movement starts

# === INTERNAL STATE ===
var move_input_timer = 0.0
var move_delay_timer = 0.0
var current_direction = Vector2.ZERO
var is_holding_direction = false

# === CORE FUNCTION ===
# Call this every frame from your scene's _process(delta)
# Returns: Vector2 with movement direction (x, y) or Vector2.ZERO if no movement
func process_movement_input(delta: float, is_currently_moving: bool) -> Vector2:
	# Check which direction is being held
	var input_direction = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		input_direction.y = -1
	elif Input.is_action_pressed("ui_down"):
		input_direction.y = 1
	elif Input.is_action_pressed("ui_left"):
		input_direction.x = -1
	elif Input.is_action_pressed("ui_right"):
		input_direction.x = 1
	
	# If direction changed or released, reset timers
	if input_direction != current_direction:
		current_direction = input_direction
		move_delay_timer = 0.0
		move_input_timer = 0.0
		is_holding_direction = false
		
		# On new press (not release), return immediate move
		if input_direction != Vector2.ZERO and not is_currently_moving:
			return input_direction
	
	# If holding a direction and not currently moving
	elif input_direction != Vector2.ZERO and not is_currently_moving:
		# Wait for initial delay before starting continuous movement
		if not is_holding_direction:
			move_delay_timer += delta
			if move_delay_timer >= INITIAL_MOVE_DELAY:
				is_holding_direction = true
				move_input_timer = 0.0
		else:
			# Continuous movement at MOVE_RATE
			move_input_timer += delta
			if move_input_timer >= MOVE_RATE:
				move_input_timer = 0.0
				return input_direction
	
	# No movement this frame
	return Vector2.ZERO

# === RESET FUNCTION ===
# Call this when entering/exiting menus or cutscenes
func reset():
	move_input_timer = 0.0
	move_delay_timer = 0.0
	current_direction = Vector2.ZERO
	is_holding_direction = false
