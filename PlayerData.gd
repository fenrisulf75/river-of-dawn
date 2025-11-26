extends Node

# PlayerData - Autoload Singleton
# Persists across all scenes, holds player stats and state

# === AWAKENING STATE ===
var awakened = false  # Set to true after Temple ritual

# === PRIMARY RESOURCES ===
var hp = 20
var max_hp = 20
var sp = 10  # Stamina (combat techniques)
var max_sp = 10
var mp = 10  # Spirit (magic, abilities)
var max_mp = 10

# === CORE ATTRIBUTES (Hidden until awakened) ===
var strength = 5
var agility = 5
var endurance = 5
var wisdom = 5
var will = 5
var luck = 5

# === INVENTORY ===
var has_dagger = false
var has_armor = false
var has_torch = false
var has_key = false

var equipped_weapon = ""
var equipped_armor = ""

# === LOCATION STATE ===
var current_scene = ""
var in_dungeon = false  # Hides compass in caves

# === FUNCTIONS ===

func take_damage(amount):
	hp -= amount
	hp = max(0, hp)
	return hp <= 0  # Returns true if dead

func heal(amount):
	hp = min(max_hp, hp + amount)

func use_stamina(amount):
	if sp >= amount:
		sp -= amount
		return true
	return false

func use_spirit(amount):
	if mp >= amount:
		mp -= amount
		return true
	return false

func restore_stamina(amount):
	sp = min(max_sp, sp + amount)

func restore_spirit(amount):
	mp = min(max_mp, mp + amount)

func equip_weapon(weapon_name):
	equipped_weapon = weapon_name
	# Dagger adds +2 damage
	print("Equipped: " + weapon_name)

func equip_armor(armor_name):
	equipped_armor = armor_name
	# Armor reduces damage by 1
	print("Equipped: " + armor_name)

func awaken():
	# Called after Temple ritual
	awakened = true
	print("Player awakened by Yarikh!")

func reset():
	# For game over / restart
	hp = max_hp
	sp = max_sp
	mp = max_mp
	awakened = false
