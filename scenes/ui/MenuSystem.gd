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
var selected_item_index = 0
var inventory_items = []

func _ready():
	menu_panel.visible = false

func _process(_delta):
	if Input.is_action_just_pressed("ui_focus_next"):  # TAB key
		toggle_menu()
	
	# Switch tabs with LEFT/RIGHT when NOT on inventory tab
	if menu_open and tab_container.current_tab != 0:
		if Input.is_action_just_pressed("ui_left"):
			var new_tab = max(0, tab_container.current_tab - 1)
			tab_container.current_tab = new_tab
		elif Input.is_action_just_pressed("ui_right"):
			var new_tab = min(tab_container.get_tab_count() - 1, tab_container.current_tab + 1)
			tab_container.current_tab = new_tab
	
	# Hide combat tab when not in combat
	if combat_tab:
		combat_tab.visible = in_combat
	
	# Handle inventory navigation when menu is open and on inventory tab
	if menu_open and tab_container.current_tab == 0:
		handle_inventory_input()

func handle_inventory_input():
	if Input.is_action_just_pressed("ui_up"):
		selected_item_index = max(0, selected_item_index - 1)
		update_inventory()
	elif Input.is_action_just_pressed("ui_down"):
		selected_item_index = min(len(inventory_items) - 1, selected_item_index + 1)
		update_inventory()
	elif Input.is_action_just_pressed("ui_accept"):  # SPACE to equip
		equip_selected_item()

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
	inventory_items = []
	
	# Build list of equippable items
	if PlayerData.has_dagger:
		inventory_items.append({"name": "Rust-pocked Dagger", "type": "weapon", "equipped": PlayerData.equipped_weapon == "dagger"})
	
	if PlayerData.has_armor:
		inventory_items.append({"name": "Tattered Cloth Armor", "type": "armor", "equipped": PlayerData.equipped_armor == "armor"})
	
	# Non-equippable items
	if PlayerData.has_torch:
		inventory_items.append({"name": "Torch", "type": "item", "equipped": false})
	
	if PlayerData.has_key:
		inventory_items.append({"name": "Cave Key", "type": "item", "equipped": false})
	
	# Clamp selected index
	if len(inventory_items) > 0:
		selected_item_index = clamp(selected_item_index, 0, len(inventory_items) - 1)
	else:
		selected_item_index = 0
		inv_text += "(No items yet)\n\n"
		inv_text += "Use Arrow Keys to select\nPress SPACE to Equip or Unequip"
		if inventory_tab.has_node("Label"):
			inventory_tab.get_node("Label").text = inv_text
		return
	
	# Display items
	for i in range(len(inventory_items)):
		var item = inventory_items[i]
		var prefix = "> " if i == selected_item_index else "  "
		inv_text += prefix + item["name"]
		
		if item["equipped"]:
			inv_text += " [EQUIPPED]"
		
		inv_text += "\n"
	
	inv_text += "\nUse Arrow Keys to select\nPress SPACE to Equip or Unequip"
	
	if inventory_tab.has_node("Label"):
		inventory_tab.get_node("Label").text = inv_text

func equip_selected_item():
	if len(inventory_items) == 0:
		return
	
	var item = inventory_items[selected_item_index]
	
	if item["type"] == "weapon":
		if item["equipped"]:
			PlayerData.unequip_weapon()
		else:
			PlayerData.equip_weapon("dagger")
		update_inventory()
	elif item["type"] == "armor":
		if item["equipped"]:
			PlayerData.unequip_armor()
		else:
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
		char_text += "\n[Attributes are not yet unlocked]"
	
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
