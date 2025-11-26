extends CanvasLayer

# Unified Menu System - TAB to toggle, tabs for Inventory/Character/Combat

signal menu_closed

onready var menu_panel = $MenuPanel
onready var tab_container = $MenuPanel/Tabs
onready var inventory_tab = $MenuPanel/Tabs/Inventory
onready var character_tab = $MenuPanel/Tabs/Character
onready var combat_tab = $MenuPanel/Tabs/Combat

var menu_open = false
var in_combat = false

func _ready():
	menu_panel.visible = false

func _process(_delta):
	if Input.is_action_just_pressed("ui_focus_next"):  # TAB key
		toggle_menu()
	
	# Hide combat tab when not in combat
	if combat_tab:
		combat_tab.visible = in_combat

func toggle_menu():
	menu_open = not menu_open
	menu_panel.visible = menu_open
	
	if not menu_open:
		emit_signal("menu_closed")
	else:
		update_inventory()
		update_character()

func update_inventory():
	var inv_text = "=== INVENTORY ===\n\n"
	
	if PlayerData.has_dagger:
		inv_text += "Weapon: Rust-pocked Dagger"
		if PlayerData.equipped_weapon == "dagger":
			inv_text += " [EQUIPPED]\n"
		else:
			inv_text += " (Press E to equip)\n"
	
	if PlayerData.has_armor:
		inv_text += "Armor: Tattered Cloth Armor"
		if PlayerData.equipped_armor == "armor":
			inv_text += " [EQUIPPED]\n"
		else:
			inv_text += " (Press A to equip)\n"
	
	if PlayerData.has_torch:
		inv_text += "Torch\n"
	
	if PlayerData.has_key:
		inv_text += "Cave Key\n"
	
	if not PlayerData.has_dagger and not PlayerData.has_armor and not PlayerData.has_torch and not PlayerData.has_key:
		inv_text += "(No items yet)"
	
	if inventory_tab.has_node("Label"):
		inventory_tab.get_node("Label").text = inv_text

func _input(event):
	if menu_open and tab_container.current_tab == 0:  # Inventory tab
		if event.is_action_pressed("ui_focus_prev"):  # E key
			if PlayerData.has_dagger and PlayerData.equipped_weapon != "dagger":
				PlayerData.equip_weapon("dagger")
				update_inventory()
		elif event.is_action_pressed("ui_accept") and event.shift:  # Shift+Space for armor
			if PlayerData.has_armor and PlayerData.equipped_armor != "armor":
				PlayerData.equip_armor("armor")
				update_inventory()

func update_character():
	var char_text = "=== CHARACTER ===\n\n"
	
	char_text += "HP: %d/%d\n" % [PlayerData.hp, PlayerData.max_hp]
	
	if PlayerData.awakened:
		char_text += "SP: %d/%d\n" % [PlayerData.sp, PlayerData.max_sp]
		char_text += "MP: %d/%d\n\n" % [PlayerData.mp, PlayerData.max_mp]
		
		char_text += "=== ATTRIBUTES ===\n"
		char_text += "Strength (STR): %d\n" % PlayerData.strength
		char_text += "Agility (AGI): %d\n" % PlayerData.agility
		char_text += "Endurance (END): %d\n" % PlayerData.endurance
		char_text += "Wisdom (WIS): %d\n" % PlayerData.wisdom
		char_text += "Will (WIL): %d\n" % PlayerData.will
		char_text += "Luck (LUK): %d\n" % PlayerData.luck
	else:
		char_text += "\n[Attributes locked until awakening]"
	
	if character_tab.has_node("Label"):
		character_tab.get_node("Label").text = char_text

func start_combat(enemy_name, enemy_hp):
	in_combat = true
	menu_open = true
	menu_panel.visible = true
	tab_container.current_tab = 2  # Switch to combat tab
	
	if combat_tab.has_node("EnemyName"):
		combat_tab.get_node("EnemyName").text = enemy_name
	
	update_combat_display(enemy_hp, enemy_hp)

func update_combat_display(enemy_hp, enemy_max_hp):
	if combat_tab.has_node("EnemyHP"):
		combat_tab.get_node("EnemyHP").text = "Enemy HP: %d/%d" % [enemy_hp, enemy_max_hp]

func end_combat():
	in_combat = false
	menu_open = false
	menu_panel.visible = false
