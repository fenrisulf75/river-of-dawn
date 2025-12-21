extends CanvasLayer

onready var hp_text = $Panel/HPText
onready var hp_fill = $Panel/HPFill
onready var hp_bg = $Panel/HPBackground

func _ready():
	# Hide on title screen
	check_scene()

func _process(_delta):
	check_scene()
	update_hud()

func check_scene():
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_name = current_scene.name
		# Hide HUD on title screen
		if scene_name == "TitleScreen":
			visible = false
		else:
			visible = true

func update_hud():
	hp_text.text = "HP: %d/%d" % [PlayerData.hp, PlayerData.max_hp]
	
	# Scale the red fill bar
	if PlayerData.max_hp > 0:
		var percent = float(PlayerData.hp) / float(PlayerData.max_hp)
		hp_fill.rect_scale.x = percent
	else:
		hp_fill.rect_scale.x = 0
