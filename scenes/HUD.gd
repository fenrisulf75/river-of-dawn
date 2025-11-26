extends CanvasLayer

# Persistent HUD - Always visible across all scenes

onready var hp_bar = $HUD/HPBar
onready var hp_label = $HUD/HPBar/HPLabel
onready var sp_bar = $HUD/SPBar
onready var sp_label = $HUD/SPBar/SPLabel
onready var mp_bar = $HUD/MPBar
onready var mp_label = $HUD/MPBar/MPLabel

func _ready():
	# SP and MP hidden until awakened
	sp_bar.visible = false
	mp_bar.visible = false
	update_hud()

func _process(_delta):
	update_hud()

func update_hud():
	# HP (always visible)
	hp_label.text = "HP: %d/%d" % [PlayerData.hp, PlayerData.max_hp]
	if PlayerData.max_hp > 0:
		hp_bar.value = (float(PlayerData.hp) / float(PlayerData.max_hp)) * 100.0
	else:
		hp_bar.value = 0
	
	# SP/MP (only if awakened)
	if PlayerData.awakened:
		if not sp_bar.visible:
			sp_bar.visible = true
			mp_bar.visible = true
		
		sp_label.text = "SP: %d/%d" % [PlayerData.sp, PlayerData.max_sp]
		if PlayerData.max_sp > 0:
			sp_bar.value = (float(PlayerData.sp) / float(PlayerData.max_sp)) * 100.0
		else:
			sp_bar.value = 0
		
		mp_label.text = "MP: %d/%d" % [PlayerData.mp, PlayerData.max_mp]
		if PlayerData.max_mp > 0:
			mp_bar.value = (float(PlayerData.mp) / float(PlayerData.max_mp)) * 100.0
		else:
			mp_bar.value = 0
