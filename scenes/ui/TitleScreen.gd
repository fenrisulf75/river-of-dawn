extends Control

# Title screen with two states:
# 1. Splash state: Shows "Press ENTER to begin"
# 2. Menu state: Shows menu buttons (New Game, Continue, Settings, Quit)

enum State { SPLASH, MENU }
var current_state = State.SPLASH

onready var splash_label = $SplashLabel
onready var menu_container = $MenuContainer
onready var new_game_button = $MenuContainer/VBoxContainer/NewGameButton
onready var continue_button = $MenuContainer/VBoxContainer/ContinueButton
onready var settings_button = $MenuContainer/VBoxContainer/SettingsButton
onready var quit_button = $MenuContainer/VBoxContainer/QuitButton

var selected_button_index = 0
var menu_buttons = []

func _ready():
	# Wait one frame for autoloads to be ready
	yield(get_tree(), "idle_frame")
	
	# Hide HUD if it exists
	if has_node("/root/HUD"):
		get_node("/root/HUD").hide()
	
	# Setup button array for keyboard navigation
	menu_buttons = [
		new_game_button,
		continue_button,
		settings_button,
		quit_button
	]
	
	# Connect button signals
	new_game_button.connect("pressed", self, "_on_new_game_pressed")
	continue_button.connect("pressed", self, "_on_continue_pressed")
	settings_button.connect("pressed", self, "_on_settings_pressed")
	quit_button.connect("pressed", self, "_on_quit_pressed")
	
	# Start in splash state
	show_splash()
	
	# Check if save file exists to enable/disable Continue button
	check_save_file()

func _process(_delta):
	if current_state == State.SPLASH:
		if Input.is_action_just_pressed("ui_accept"):
			show_menu()
	
	elif current_state == State.MENU:
		handle_menu_navigation()

func show_splash():
	current_state = State.SPLASH
	splash_label.visible = true
	menu_container.visible = false

func show_menu():
	current_state = State.MENU
	splash_label.visible = false
	menu_container.visible = true
	
	# Focus first button
	selected_button_index = 0
	update_button_focus()

func handle_menu_navigation():
	# Arrow key navigation
	if Input.is_action_just_pressed("ui_down"):
		selected_button_index = (selected_button_index + 1) % menu_buttons.size()
		update_button_focus()
	
	elif Input.is_action_just_pressed("ui_up"):
		selected_button_index = (selected_button_index - 1 + menu_buttons.size()) % menu_buttons.size()
		update_button_focus()
	
	# Enter/Space to activate
	elif Input.is_action_just_pressed("ui_accept"):
		menu_buttons[selected_button_index].emit_signal("pressed")

func update_button_focus():
	for i in range(menu_buttons.size()):
		if i == selected_button_index:
			menu_buttons[i].grab_focus()

func check_save_file():
	# Check if save file exists
	var save_file = File.new()
	if save_file.file_exists("user://savegame.save"):
		continue_button.disabled = false
	else:
		continue_button.disabled = true

# Button callbacks
func _on_new_game_pressed():
	# Show HUD when game starts
	if has_node("/root/HUD"):
		get_node("/root/HUD").show()
	
	# Reset PlayerData for new game
	PlayerData.reset()
	
	get_tree().change_scene("res://scenes/overworld/StarterZone.tscn")

func _on_continue_pressed():
	# Show HUD when game starts
	if has_node("/root/HUD"):
		get_node("/root/HUD").show()
	
	# Load save file
	PlayerData.load_game()
	
	# TODO: Load the appropriate scene based on save data
	# For now, just load StarterZone
	get_tree().change_scene("res://scenes/overworld/StarterZone.tscn")

func _on_settings_pressed():
	# TODO: Open settings menu
	# For now, show a placeholder message
	print("Settings menu not yet implemented")
	# You can create a SettingsMenu.tscn later
	# get_tree().change_scene("res://scenes/ui/SettingsMenu.tscn")

func _on_quit_pressed():
	get_tree().quit()
