extends CanvasLayer

# InteractionPopup - Handles NPC dialogue, object examination, shops, etc.
# Features animated portrait (6-frame cycle) and configurable button options

signal interaction_complete(choice)

onready var control = $Control
onready var portrait_sprite = $Control/PopupPanel/ContentMargin/MainContainer/PortraitSection/PortraitFrame/PortraitSprite
onready var portrait_label = $Control/PopupPanel/ContentMargin/MainContainer/PortraitSection/PortraitLabel
onready var name_label = $Control/PopupPanel/ContentMargin/MainContainer/DialogueSection/NameLabel
onready var dialogue_scroll = $Control/PopupPanel/ContentMargin/MainContainer/DialogueSection/DialogueScroll
onready var dialogue_text = $Control/PopupPanel/ContentMargin/MainContainer/DialogueSection/DialogueScroll/DialogueText
onready var button_container = $Control/PopupPanel/ContentMargin/MainContainer/DialogueSection/ButtonContainer
onready var button1 = $Control/PopupPanel/ContentMargin/MainContainer/DialogueSection/ButtonContainer/Button1
onready var button2 = $Control/PopupPanel/ContentMargin/MainContainer/DialogueSection/ButtonContainer/Button2
onready var button3 = $Control/PopupPanel/ContentMargin/MainContainer/DialogueSection/ButtonContainer/Button3
onready var close_button = $Control/PopupPanel/ContentMargin/MainContainer/DialogueSection/ButtonContainer/CloseButton
onready var animation_timer = $Control/PopupPanel/ContentMargin/MainContainer/PortraitSection/AnimationTimer

# Portrait animation
var portrait_frames = []  # Array of 6 Texture resources
var current_frame = 0
var portrait_animation_enabled = false

func _ready():
	visible = false
	set_process_input(false)

func _input(event):
	# ESC to close
	if event.is_action_pressed("ui_cancel"):
		close_popup()
		get_tree().set_input_as_handled()

# Show popup with NPC/object data
func show_interaction(data: Dictionary):
	"""
	data = {
		"character_name": "Elder Thamos",
		"portrait_name": "Elder",  # Optional: for portrait label
		"portrait_frames": [tex1, tex2, tex3, tex4, tex5, tex6],  # Optional: 6-frame animation
		"dialogue": "Welcome, traveler. The city of Yeriḥo has stood for generations...",
		"buttons": [
			{"label": "Accept Quest", "id": "accept"},
			{"label": "Ask About City", "id": "ask_city"},
			{"label": "Trade", "id": "trade"}
		]
	}
	"""
	
	# Set character name
	name_label.text = data.get("character_name", "Unknown")
	
	# Set portrait label
	portrait_label.text = data.get("portrait_name", "")
	
	# Setup portrait animation if frames provided
	if data.has("portrait_frames") and len(data["portrait_frames"]) == 6:
		portrait_frames = data["portrait_frames"]
		portrait_animation_enabled = true
		current_frame = 0
		portrait_sprite.texture = portrait_frames[0]
		animation_timer.start()
	else:
		portrait_animation_enabled = false
		animation_timer.stop()
		# Use single portrait if provided
		if data.has("portrait_texture"):
			portrait_sprite.texture = data["portrait_texture"]
		else:
			portrait_sprite.texture = null
	
	# Set dialogue text
	dialogue_text.bbcode_text = data.get("dialogue", "...")
	
	# Reset scroll position to top
	dialogue_scroll.scroll_vertical = 0
	
	# Configure buttons
	setup_buttons(data.get("buttons", []))
	
	# Show popup
	visible = true
	set_process_input(true)
	
	# Pause game
	get_tree().paused = true

func setup_buttons(button_configs: Array):
	# Hide all buttons first
	button1.visible = false
	button2.visible = false
	button3.visible = false
	
	# Configure visible buttons based on config
	for i in range(min(button_configs.size(), 3)):
		var btn_config = button_configs[i]
		var button = get_button_by_index(i)
		
		if button:
			button.text = btn_config.get("label", "Option")
			button.set_meta("choice_id", btn_config.get("id", ""))
			button.visible = true
	
	# Close button always visible
	close_button.visible = true

func get_button_by_index(index: int) -> Button:
	match index:
		0: return button1
		1: return button2
		2: return button3
	return null

func close_popup():
	visible = false
	set_process_input(false)
	animation_timer.stop()
	portrait_animation_enabled = false
	get_tree().paused = false
	emit_signal("interaction_complete", null)

# Portrait animation cycle
func _on_AnimationTimer_timeout():
	if not portrait_animation_enabled or portrait_frames.empty():
		return
	
	current_frame = (current_frame + 1) % 6
	portrait_sprite.texture = portrait_frames[current_frame]

# Button callbacks
func _on_Button1_pressed():
	var choice_id = button1.get_meta("choice_id") if button1.has_meta("choice_id") else ""
	handle_choice(choice_id)

func _on_Button2_pressed():
	var choice_id = button2.get_meta("choice_id") if button2.has_meta("choice_id") else ""
	handle_choice(choice_id)

func _on_Button3_pressed():
	var choice_id = button3.get_meta("choice_id") if button3.has_meta("choice_id") else ""
	handle_choice(choice_id)

func _on_CloseButton_pressed():
	close_popup()

func handle_choice(choice_id: String):
	# Emit signal with choice, let calling scene handle it
	visible = false
	set_process_input(false)
	animation_timer.stop()
	portrait_animation_enabled = false
	get_tree().paused = false
	emit_signal("interaction_complete", choice_id)
