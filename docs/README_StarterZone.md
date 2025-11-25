# River of Dawn - Starter Zone Implementation

## Overview
This is the top-down 2D overworld beginning area set on the western shore of the Dead Sea (Yām ha-Melaḥ). The player awakens disoriented and must navigate to find equipment, learn about the world, and ultimately acquire a key to enter the cave that leads to PassageToYeriho.

## Files Created

### Core Scene Files
- **StarterZone.tscn** - Main scene file with camera and UI setup
- **StarterZone.gd** - Main gameplay script with map generation, movement, and interactions
- **CombatUI.tscn** - Combat interface scene
- **CombatUI.gd** - Turn-based combat system for the hyena encounter

### Documentation
- **starter_zone_map.html** - Visual map reference (HTML)
- **README_StarterZone.md** - This file

## Map Details

### Dimensions
32×32 tile grid, 24 pixels per tile

### Tile Types
- `#` - Cliff/Rock (impassable)
- `X` - Brine Pits (impassable, toxic fumes when adjacent)
- `~` - Dead Sea (impassable water)
- `.` - Walkable ground
- `:` - Worn footpath (keeper's trail)

### Interactive Points
- `P` - Player spawn point (southeast shore)
- `G` - Cave entrance (locked, requires key from hyena)
- `S` - Shrine of Ba'al (ruined, optional lore)
- `D` - Hyena encounter location (combat trigger)
- `K` - Torn satchel (empty, in canyon)
- `L` - Starting loot (dagger + light armor)
- `!` - Skeleton keeper (with note)
- `B` - Lore stone (Dead Sea identification)

## Player Flow

### Intended Path
1. **Spawn** at `P` on the shore
2. **Move north** → find `L` (loot: dagger + armor)
3. **Continue north** → find `!` (skeleton with note about satchel)
4. **Move north** → read `B` (lore stone about Dead Sea)
5. **Blocked by brine** → move west into canyon
6. **Enter canyon** → find `K` (torn satchel - empty, no key!)
7. **Exit canyon** → `D` hyena ambushes the player
8. **Defeat hyena** → key drops from its belly
9. **Optional** → visit `S` (Shrine of Ba'al)
10. **Follow path** to `G` (cave entrance)
11. **Use key** → unlock cave → transition to PassageToYeriho

### Key Design Elements
- **Funneling**: Cliffs and brine pits guide player through deliberate narrative path
- **Environmental storytelling**: Each point reveals part of the keeper's failed journey
- **Earned progression**: Key only obtained through combat victory
- **One-way momentum**: Matches the design of PassageToYeriho

## Features Implemented

### Movement System
- WASD or Arrow Keys for grid-based movement
- Smooth tweening between tiles (0.15s per move)
- Collision detection for all impassable tiles
- Camera follows player

### Interaction System
- Press SPACE to interact with objects
- On-screen prompt when near interactive objects
- Message display with pause-and-continue
- Automatic proximity detection (current tile + adjacent)

### Combat System
- Turn-based combat UI
- Attack and Defend options
- Damage ranges (player: 3-6 with dagger, enemy: 2-5)
- Defending reduces incoming damage by 50%
- Victory → key drops from hyena's belly
- Defeat → respawn at starting position

### State Tracking
- Player inventory (dagger, armor, key)
- Object states (examined, taken, defeated)
- Combat status tracking
- Progressive narrative through examined objects

### Environmental Feedback
- Proximity warnings near brine pits ("The fumes sting your lungs")
- Quick messages for environmental hazards
- Persistent UI prompts for interactions

## Color Palette

### Terrain
- Cliff: `#453828` (dark brown rock)
- Brine Pits: `#a68c40` (yellowish toxic)
- Dead Sea: `#263847` (dark blue-grey)
- Ground: `#c0ae8c` (sandy tan)
- Path: `#a6946f` (worn brown)

### Interactive
- Player: `#3399dd` (blue)
- Interactive objects: `#e0b050` (golden yellow)
- Enemy: `#cc3333` (red)

## Integration with Existing Systems

### Scene Transition
When the player unlocks and enters the cave at `G`, the scene will transition to:
```gdscript
get_tree().change_scene("res://scenes/PassageToYeriho.tscn")
```

Currently commented out for testing, but ready to enable.

### Matching PassageToYeriho
- Both use grid-based movement
- Both use message pause system (SPACE to continue)
- Both track state for one-way progression
- Both use environmental storytelling

## Testing the Scene

### In Godot
1. Copy all files to your River of Dawn project
2. Open `StarterZone.tscn` in Godot 3.5.3
3. Run the scene (F6)
4. Use WASD/Arrows to move
5. Press SPACE to interact with objects

### Expected Flow
- Start at spawn point
- Pick up loot (should see message)
- Read skeleton note
- Find empty satchel in canyon
- Return and trigger hyena combat
- Win combat → receive key
- Go to cave → unlock with key

## Known Issues / TODO

### Completed ✅
- Grid-based movement
- Tile rendering from ASCII map
- Interaction system
- Combat system
- State tracking
- Scene structure

### Pending 🚧
- Dog/hyena combat trigger logic needs refinement
  - Currently triggers when within 4 tiles after examining satchel
  - May need more precise positioning
- Game over/respawn needs full reset of collected items
- Audio cues (wind, footsteps, combat)
- Visual polish (sprites, animations)

### Future Enhancements 📋
- Sprite-based graphics (replace ColorRects)
- Animated player character
- Particle effects for brine pits
- Ambient sound system
- Music integration
- Minimap display
- Inventory UI panel

## Code Architecture

### StarterZone.gd Structure
```
Constants (map data, tile size, colors)
↓
State Variables (player position, inventory, flags)
↓
Node References (camera, UI labels, combat)
↓
_ready() - Initialize scene
↓
generate_zone() - Convert ASCII to tiles
↓
_process() - Handle input and movement
↓
Interaction Functions
↓
Helper Functions
```

### Key Functions
- `generate_zone()` - ASCII map to visual tiles
- `attempt_move()` - Movement with collision
- `check_interaction()` - Handle SPACE press
- `interact_with()` - Process specific interactions
- `trigger_dog_encounter()` - Start combat
- `on_combat_finished()` - Handle combat results

## Notes for Tim

### Integration Steps
1. **Copy files** to your project's appropriate folders:
   - `StarterZone.gd` → `res://scenes/`
   - `StarterZone.tscn` → `res://scenes/`
   - `CombatUI.gd` → `res://scenes/` or `res://ui/`
   - `CombatUI.tscn` → `res://scenes/` or `res://ui/`

2. **Update resource paths** in `.tscn` files if needed

3. **Test standalone** before connecting to PassageToYeriho

4. **Enable scene transition** when ready:
   - Uncomment the `change_scene()` line in `check_cave_entry()`

5. **Sync with GitHub** when stable

### Compatibility Notes
- Built for Godot 3.5.3 (matches your existing project)
- Uses same design patterns as PassageToYeriho
- Grid alignment principles consistent with your 3D scenes
- Message/pause system identical to cave passage

### Visual Improvements
The current implementation uses simple ColorRects for tiles. When ready to add visual polish:
- Replace ColorRects with Sprite2D nodes
- Add your photography-based textures
- Consider using a TileMap node for better performance
- Add particle effects for environmental atmosphere

## Design Philosophy Alignment

This implementation follows your established principles:
- ✅ **Structure first, aesthetics later**
- ✅ **Grid-based clarity**
- ✅ **Retro authenticity** (Ultima-style overhead view)
- ✅ **Environmental storytelling**
- ✅ **One-way progression** (cave seals behind, key must be earned)
- ✅ **Clean code** (commented, organized, maintainable)

## Liora's Narrative Integration

All of Liora's design elements are implemented:
- ✅ Funneling through terrain
- ✅ Keeper's story through found objects
- ✅ Key in hyena's belly (earned through combat)
- ✅ Optional shrine interaction
- ✅ Atmospheric messaging
- ✅ Environmental hazard feedback

---

**Status**: Ready for testing and integration
**Created**: November 25, 2025
**Godot Version**: 3.5.3
**Next Steps**: Test → Polish → Connect to PassageToYeriho
