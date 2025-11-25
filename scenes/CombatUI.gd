extends CanvasLayer

# Simple combat UI for the dog/hyena encounter

signal combat_finished(player_won)

var player_hp = 20
var player_max_hp = 20
var enemy_hp = 15
var enemy_max_hp = 15
var enemy_name = "Hyena"

var player_damage_range = [3, 6]  # With dagger
var enemy_damage_range = [2, 5]

var combat_active = false
var waiting_for_player = false

onready var combat_panel = $CombatPanel
onready var status_label = $CombatPanel/StatusLabel
onready var action_label = $CombatPanel/ActionLabel
onready var hp_label = $CombatPanel/HPLabel
onready var attack_button = $CombatPanel/AttackButton
onready var defend_button = $CombatPanel/DefendButton

func _ready():
	combat_panel.visible = false
	attack_button.connect("pressed", self, "on_attack_pressed")
	defend_button.connect("pressed", self, "on_defend_pressed")

func start_combat(player_has_weapon):
	combat_active = true
	combat_panel.visible = true
	
	# Adjust damage if no weapon
	if not player_has_weapon:
		player_damage_range = [1, 3]
	
	update_display()
	show_action("A hyena attacks!")
	yield(get_tree().create_timer(1.5), "timeout")
	player_turn()

func player_turn():
	waiting_for_player = true
	show_action("Your turn - choose action")
	attack_button.disabled = false
	defend_button.disabled = false

func on_attack_pressed():
	if not waiting_for_player:
		return
	
	waiting_for_player = false
	attack_button.disabled = true
	defend_button.disabled = true
	
	# Player attacks
	var damage = randi() % (player_damage_range[1] - player_damage_range[0] + 1) + player_damage_range[0]
	enemy_hp -= damage
	show_action("You strike for %d damage!" % damage)
	update_display()
	
	yield(get_tree().create_timer(1.0), "timeout")
	
	if enemy_hp <= 0:
		end_combat(true)
	else:
		enemy_turn()

func on_defend_pressed():
	if not waiting_for_player:
		return
	
	waiting_for_player = false
	attack_button.disabled = true
	defend_button.disabled = true
	
	# Player defends (reduces next attack)
	show_action("You brace for impact...")
	update_display()
	
	yield(get_tree().create_timer(1.0), "timeout")
	enemy_turn(true)

func enemy_turn(player_defending = false):
	var damage = randi() % (enemy_damage_range[1] - enemy_damage_range[0] + 1) + enemy_damage_range[0]
	
	if player_defending:
		damage = int(damage * 0.5)  # Defending reduces damage
	
	player_hp -= damage
	show_action("%s attacks for %d damage!" % [enemy_name, damage])
	update_display()
	
	yield(get_tree().create_timer(1.5), "timeout")
	
	if player_hp <= 0:
		end_combat(false)
	else:
		player_turn()

func update_display():
	hp_label.text = "HP: %d/%d | %s: %d/%d" % [player_hp, player_max_hp, enemy_name, enemy_hp, enemy_max_hp]
	status_label.text = "Combat"

func show_action(text):
	action_label.text = text

func end_combat(player_won):
	combat_active = false
	waiting_for_player = false
	
	if player_won:
		show_action("Victory! The hyena falls.")
		yield(get_tree().create_timer(2.0), "timeout")
		show_action("The belly tears open... something falls out.\n\nYou find a key!")
		yield(get_tree().create_timer(3.0), "timeout")
	else:
		show_action("You have been defeated...")
		yield(get_tree().create_timer(2.0), "timeout")
	
	combat_panel.visible = false
	emit_signal("combat_finished", player_won)
