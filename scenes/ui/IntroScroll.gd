extends Control

# IntroScroll - Atmospheric opening sequence
# Synced scrolling text with narration audio and animated smoke background

# Audio duration: 99.018 seconds (1:39.018)
const AUDIO_DURATION = 99.018

# Timing phases
const FADE_IN_DURATION = 2.0        # Fade in from black
const PRE_SCROLL_PAUSE = 14.6       # Wait for intro atmosphere (16.6s total before vocal)
const VOCAL_START_TIME = 16.6       # When English voice begins
const VOCAL_END_TIME = 92.07        # When English voice ends (1:32.07)
const SCROLL_DURATION = 75.47       # Duration of vocal (92.07 - 16.6)
const POST_SCROLL_PAUSE = 2.0       # Pause after scroll completes
const FADE_OUT_DURATION = 3.0       # Fade out to black before game

onready var smoke_bg = $SmokeBackground
onready var scroll_text = $ScrollText
onready var fade_overlay = $FadeOverlay
onready var audio_player = $AudioPlayer
onready var skip_label = $SkipLabel

var sequence_started = false
var current_time = 0.0
var scroll_start_y = 0.0
var scroll_end_y = 0.0
var scroll_speed = 0.0
var can_skip = true
var sequence_complete = false  # Track if sequence has finished

func _ready():
	# Hide HUD during intro sequence - try multiple methods
	if has_node("/root/HUD"):
		var hud = get_node("/root/HUD")
		hud.visible = false
		hud.modulate.a = 0.0  # Make it invisible even if visible flag doesn't work
		print("IntroScroll: HUD hidden")
	else:
		print("IntroScroll: No HUD found")
	
	# Wait one frame for text to calculate its size
	yield(get_tree(), "idle_frame")
	
	# Hide HUD again after yield
	if has_node("/root/HUD"):
		var hud = get_node("/root/HUD")
		hud.visible = false
		hud.modulate.a = 0.0
	
	# Calculate scroll positions
	# Start: text 1/3 up from bottom already visible
	# End: last line 1/3 down from top
	var viewport_height = get_viewport_rect().size.y
	var text_height = scroll_text.get_content_height()
	
	scroll_start_y = viewport_height * 0.67  # 1/3 from bottom
	scroll_end_y = viewport_height * 0.33 - text_height  # 1/3 from top
	
	print("IntroScroll: Viewport height: ", viewport_height)
	print("IntroScroll: Text height: ", text_height)
	print("IntroScroll: Scroll start Y: ", scroll_start_y)
	print("IntroScroll: Scroll end Y: ", scroll_end_y)
	
	# Calculate scroll speed to complete during audio
	var scroll_distance = scroll_start_y - scroll_end_y
	scroll_speed = scroll_distance / SCROLL_DURATION
	
	print("IntroScroll: Scroll distance: ", scroll_distance)
	print("IntroScroll: Scroll speed: ", scroll_speed)
	
	# Position text at starting point
	scroll_text.rect_position.y = scroll_start_y
	print("IntroScroll: Text positioned at: ", scroll_text.rect_position.y)
	
	# Start with everything hidden/silent
	smoke_bg.modulate.a = 0.0
	scroll_text.modulate.a = 0.0
	fade_overlay.modulate.a = 1.0  # Start black
	skip_label.modulate.a = 0.0
	
	# Begin the sequence
	start_sequence()

func start_sequence():
	sequence_started = true
	current_time = 0.0
	
	# Make absolutely sure HUD is hidden
	if has_node("/root/HUD"):
		var hud = get_node("/root/HUD")
		hud.visible = false
		hud.modulate.a = 0.0
	
	# Start audio immediately
	audio_player.play()
	audio_player.volume_db = -1.1  # Reduce by ~12%
	print("IntroScroll: Audio started at current_time = 0.0")
	
	# Fade in smoke background and fade out black overlay
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(smoke_bg, "modulate:a", 1.0, FADE_IN_DURATION)
	tween.tween_property(fade_overlay, "modulate:a", 0.0, FADE_IN_DURATION)
	
	# Fade in skip label
	tween.tween_property(skip_label, "modulate:a", 0.7, FADE_IN_DURATION)

func _process(delta):
	if not sequence_started:
		return
	
	# AGGRESSIVELY ensure HUD stays hidden during intro
	# Check both as autoload and as scene
	if has_node("/root/HUD"):
		var hud = get_node("/root/HUD")
		hud.visible = false
		hud.hide()
		# Also try to hide any child controls
		for child in hud.get_children():
			if child is Control or child is CanvasItem:
				child.visible = false
				child.hide()
	
	# Handle skip input
	if can_skip and Input.is_action_just_pressed("ui_accept"):
		skip_to_game()
		return
	
	current_time += delta
	
	# === PHASE 1: Fade in smoke/atmosphere (0-2s) ===
	# Handled by start_sequence() - audio also starts here now
	
	# === PHASE 2: Fade in text when vocal begins (at 16.6s) ===
	var fade_in_duration = 2.0
	var time_since_vocal_start = current_time - VOCAL_START_TIME
	
	if time_since_vocal_start >= 0 and time_since_vocal_start < fade_in_duration:
		# Gradually fade in from 0 to 1 over 2 seconds
		scroll_text.modulate.a = time_since_vocal_start / fade_in_duration
	elif time_since_vocal_start >= fade_in_duration and scroll_text.modulate.a < 1.0:
		# Ensure it's at full opacity after fade in completes
		scroll_text.modulate.a = 1.0
	
	# === PHASE 3: Scroll text continuously until vocal ends ===
	# Extended slightly past vocal end to ensure smooth fade completion
	var fade_start_time = 8.0  # Start fading 8 seconds before vocal ends
	var fade_end_time = VOCAL_END_TIME  # Complete fade when vocal ends
	
	if current_time >= VOCAL_START_TIME and current_time <= fade_end_time:
		# Always scroll (continues even during fade)
		scroll_text.rect_position.y -= scroll_speed * delta
		
		# Calculate fade based on how close we are to the end
		var time_remaining = VOCAL_END_TIME - current_time
		
		if time_remaining < fade_start_time:
			# Fade out gradually while STILL scrolling
			var fade_progress = time_remaining / fade_start_time
			scroll_text.modulate.a = fade_progress
		
		# Clamp to end position
		if scroll_text.rect_position.y < scroll_end_y:
			scroll_text.rect_position.y = scroll_end_y
	
	# === PHASE 4: After vocal ends, lock text invisible but DON'T set sequence_complete ===
	# Audio continues for ~7 more seconds, and we need _on_AudioPlayer_finished to fire
	if current_time > VOCAL_END_TIME:
		scroll_text.modulate.a = 0.0
		scroll_text.visible = false

func _on_AudioPlayer_finished():
	print("=== AUDIO FINISHED CALLED ===")
	print("Is in tree: ", is_inside_tree())
	print("Sequence complete before: ", sequence_complete)
	
	# Check if still in tree (prevent resume error)
	if not is_inside_tree():
		print("Returning early - not in tree")
		return
	
	# Only proceed if not already complete (prevents double-triggering)
	if sequence_complete:
		print("Already complete - ignoring duplicate signal")
		return
	
	sequence_complete = true  # Mark as complete to prevent repeats
	audio_player.stop()  # Ensure audio is stopped
	
	print("Starting fade to game...")
	# Audio completed, fade to game immediately
	fade_to_game()

func fade_to_game():
	if sequence_complete == false:
		sequence_complete = true
	
	can_skip = false
	sequence_started = false  # Stop processing
	
	# Quick fade to black
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 2.0)
	
	# Wait for fade, then load game
	yield(tween, "finished")
	
	# Check still in tree after yield
	if is_inside_tree():
		load_game()

func skip_to_game():
	can_skip = false
	audio_player.stop()
	
	# Quick fade to black
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.5)
	
	yield(tween, "finished")
	
	# Check still in tree after yield
	if is_inside_tree():
		load_game()

func load_game():
	# Show HUD if it exists
	if has_node("/root/HUD"):
		get_node("/root/HUD").show()
	
	# Load the game starting zone
	get_tree().change_scene("res://scenes/overworld/StarterZone.tscn")
