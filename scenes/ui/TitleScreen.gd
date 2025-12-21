extends Control

func _ready():
	# Wait one frame for autoloads to be ready
	yield(get_tree(), "idle_frame")
	
	# Hide HUD if it exists
	if has_node("/root/HUD"):
		get_node("/root/HUD").hide()

func _process(_delta):
	# Check for ENTER key specifically
	if Input.is_key_pressed(KEY_ENTER) or Input.is_action_just_pressed("ui_accept"):
		start_game()

func start_game():
	# Show HUD when game starts
	if has_node("/root/HUD"):
		get_node("/root/HUD").show()
	
	get_tree().change_scene("res://scenes/StarterZone.tscn")
