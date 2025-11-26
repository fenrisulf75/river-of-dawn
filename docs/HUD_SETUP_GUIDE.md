# Persistent HUD & Menu System - Setup Guide

## Files Created:

1. **PlayerData.gd** - Singleton holding all player stats
2. **HUD.tscn** + **HUD.gd** - Persistent UI overlay (HP/SP/MP bars + compass)
3. **MenuSystem.tscn** + **MenuSystem.gd** - TAB menu (Inventory/Character/Combat)

## Setup Steps:

### 1. Add Autoload Singletons

In Godot, go to **Project → Project Settings → AutoLoad**

Add these two autoloads (in this order):

**Name:** PlayerData  
**Path:** res://PlayerData.gd  
**Singleton:** ✓ Enabled

**Name:** HUD  
**Path:** res://HUD.tscn  
**Singleton:** ✓ Enabled

**Name:** MenuSystem  
**Path:** res://MenuSystem.tscn  
**Singleton:** ✓ Enabled

### 2. Update Input Map

**Project → Project Settings → Input Map**

Add new action:
- **ui_cancel** → Tab key (for opening menu)

### 3. Update StarterZone.gd

Replace equipment tracking with PlayerData:

```gdscript
# OLD - Remove these:
var has_dagger = false
var has_armor = false
var has_key = false

# NEW - Use PlayerData instead:
# When picking up loot:
PlayerData.has_dagger = true
PlayerData.has_armor = true

# When getting key:
PlayerData.has_key = true

# When checking if player has key:
if PlayerData.has_key:
```

Also set dungeon state:

```gdscript
func _ready():
    PlayerData.in_dungeon = false  # StarterZone is outdoors
    PlayerData.current_scene = "StarterZone"
```

### 4. Update PassageToYeriho.gd

At the start of _ready():

```gdscript
func _ready():
    PlayerData.in_dungeon = true  # Hide compass in cave
    PlayerData.current_scene = "PassageToYeriho"
```

### 5. Update Combat System

Replace CombatUI with MenuSystem combat tab:

In StarterZone.gd (or wherever combat starts):

```gdscript
# OLD:
combat_ui.start_combat(has_dagger)

# NEW:
MenuSystem.start_combat("Hyena", 15)
```

### 6. Test the System

**HUD Tests:**
- [ ] HP bar visible at top-left
- [ ] SP/MP bars hidden initially
- [ ] Compass visible in StarterZone
- [ ] Compass hidden in PassageToYeriho

**Menu Tests:**
- [ ] Press TAB - menu opens
- [ ] See Inventory tab
- [ ] See Character tab (attributes locked message)
- [ ] Press TAB again - menu closes

**Awakening Test:**
- [ ] In console: `PlayerData.awaken()`
- [ ] SP/MP bars fade in on HUD
- [ ] Character tab shows all attributes

**Combat Test:**
- [ ] Combat triggers
- [ ] Combat tab appears
- [ ] Enemy portrait shows (left side)
- [ ] Combat log and actions (right side)
- [ ] HUD bars stay visible at top

## Pre-Temple vs Post-Temple:

**Before Temple (default):**
- Only HP visible on HUD
- Compass shows (when outdoors)
- Character sheet shows "locked" message
- SP/MP exist internally but hidden

**After Temple (PlayerData.awaken()):**
- SP and MP bars fade in
- Character sheet shows all 6 attributes
- Deeper gameplay unlocked

## Color Scheme:

**HUD Bars:**
- HP: Red (#CC3333)
- SP: Yellow (#CCAA33)
- MP: Blue (#3366CC)

**Compass:**
- Background: Dark grey (alpha 0.7)
- Arrow: Gold (#FFCC33)

## Notes:

- HUD persists across ALL scene changes
- MenuSystem accessible everywhere via TAB
- PlayerData singleton stores all state
- Combat integrates into menu system
- System ready for torch pickup before cave

## Next Steps:

1. Add torch pickup in StarterZone
2. Require torch to enter PassageToYeriho
3. Create Temple awakening scene
4. Add equipment bonuses to combat
5. Polish combat UI with better enemy portraits
