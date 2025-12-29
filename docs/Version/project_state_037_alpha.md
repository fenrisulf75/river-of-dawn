# River of Dawn - Project State v0.3.7-alpha
**Date:** December 25, 2025  
**Lead Designer/Programmer:** Timothy C. Hall  
**Visual Assets:** Visual Artist

---

## Current Build Status

**Version:** 0.3.7-alpha  
**Engine:** Godot 3.5.3 LTS  
**Primary Development Platform:** iMac (with MacBook Air sync via GitHub)

---

## Major Milestone: Path Fixes + Held-Input Movement System

This version completed all path corrections from the v0.3.6 folder reorganization and implemented a centralized held-input movement system to dramatically improve player experience.

---

## Path Issues Fixed

### Texture Path Corrections

**StarterZone.gd (line 296)**
- ❌ **Before**: Cliff tiles loaded sand texture
- ✅ **After**: `res://assets/textures/ground/terrain/ground_cliff_24.png`
- **Result**: Cliffs now display correctly as dark brown rock

**Yeriho.gd (line 60)**
- ❌ **Before**: Missing `/terrain/` subfolder in path
- ✅ **After**: `res://assets/textures/ground/terrain/ground_sand_24.png`
- **Result**: Yeriḥo city floor textures load properly

**CatacombsLevel1.gd (line 50)**
- ❌ **Before**: Missing `/terrain/` subfolder in path
- ✅ **After**: `res://assets/textures/ground/terrain/ground_cliff_24.png`
- **Result**: Catacombs floor texture loads correctly

### Scene Reference Corrections

**Yeriho.tscn (line 3)**
- ❌ **Before**: `res://scenes/Yeriho.gd` (old flat structure)
- ✅ **After**: `res://scenes/cities/Yeriho.gd` (new organized structure)
- **Result**: Scene transition from PassageToYeriho → Yeriḥo now works

**Verification**: All 6 .tscn files audited - only Yeriho.tscn needed fixing

---

## Held-Input Movement System

### New Autoload: MovementSystem2D

**Purpose**: Centralized movement handling for all 2D overworld scenes  
**Location**: `scripts/MovementSystem2D.gd`  
**Autoload Name**: `MovementSystem2D`

### Features
- **Hold to move**: Arrow keys now support continuous movement
- **Responsive**: First press moves immediately (no input lag)
- **Configurable**: Easy global speed adjustments
- **Efficient**: 3 lines of code per scene vs. 15 lines of old tap logic

### Current Settings
```gdscript
const MOVE_RATE = 0.4  # seconds per tile (2.5 tiles/second)
const INITIAL_MOVE_DELAY = 0.2  # delay before continuous movement starts
```

**Tuning Notes**:
- Faster than original 0.5s delay (feels more responsive)
- Speed is comfortable for exploration
- Can be adjusted in one place (scripts/MovementSystem2D.gd)

### Integration Complete

**StarterZone.gd**
- ✅ Fully integrated with MovementSystem2D
- Replaced old tap-only input system
- Movement code reduced from 15 lines → 3 lines
- All existing systems unaffected:
  - Fog of war updates correctly
  - Combat triggers work
  - Interaction prompts display
  - Collision detection unchanged
  - Hazard proximity checks functional

**Implementation Example**:
```gdscript
# Old way (tap-only, 15 lines)
var dx = 0
var dy = 0
if Input.is_action_just_pressed("ui_up"):
    dy = -1
elif Input.is_action_just_pressed("ui_down"):
    # ... etc

# New way (hold-to-move, 3 lines)
var move_direction = MovementSystem2D.process_movement_input(delta, is_moving)
if move_direction != Vector2.ZERO:
    attempt_move(int(move_direction.x), int(move_direction.y))
```

### Future 3D Movement System

**MovementSystem3D.gd** - Created but not yet integrated
- Handles forward/backward movement (hold)
- Handles left/right rotation (hold)
- Separate timing for movement vs. rotation
- Ready to apply to:
  - PassageToYeriho (3D dungeon)
  - Yeriḥo city navigation (3D first-person)
  - Future dungeons and cities

---

## Current Game State

### Playable Content

✅ **Title Screen** → Full menu with River of Dawn branding  
✅ **Dead Sea Shore (StarterZone)** → Complete 2D overworld beginning area with held-input movement  
✅ **PassageToYeriho** → 3D dungeon connecting shore to city (tap-only movement for now)  
✅ **Yeriḥo City** → 3D procedurally generated first major city (tap-only movement for now)

### Working Systems

- **Held-Input Movement (2D):** Smooth continuous movement in StarterZone
- **Fog of War:** Terrain-aware directional vision system
- **Combat System:** Turn-based with equipment bonuses
- **Inventory System:** Equipment management with toggle equip/unequip
- **Menu System:** TAB-accessible inventory and character screens
- **Dialogue/Messages:** SPACE-advance message system
- **Scene Transitions:** Working between 2D and 3D modes

### Visual Assets

- 24×24 ground tiles (terrain, paths, animated brine, special markers)
- 512×512 wall textures (cave stone, mudbrick, temple)
- Ba'al deity symbol tile (custom artwork)
- Curved path tiles for organic-looking roads
- 4-frame animated brine pit cycle
- **Cliff tiles now displaying correctly** (dark brown rock)

---

## Known Issues

### Tabled for Future Work

⚠️ **Catacombs Map Corruption**
- CatacombsLevel1, CatacombsLevel2, CatacombsLevel3 have incorrect ASCII maps
- Maps display nested spiral patterns instead of original designs
- **Status**: Not blocking current work, will redraw when Catacombs work resumes
- **Action**: Check Git history for original layouts or recreate from design notes

⚠️ **Debug Print Statements**
- CatacombsLevel1.gd and CatacombsLevel2.gd have broken debug prints from troubleshooting
- Causes parse errors if attempting to load Catacombs
- **Status**: Can be cleaned up when Catacombs work resumes

### Flagged for Improvement

⚠️ **Yeriḥo Camera Alignment**
- 3D camera doesn't align perfectly to streets and corners
- Makes navigation feel imprecise
- **Priority**: Medium
- **Status**: Flagged for future improvement session

---

## Visual Asset Needs

### Immediate Priority

**Lore Stone Tile** (24×24 texture)
- **Purpose**: Visual marker for lore interaction points in overworld
- **Location**: Near cave entrance and other discovery points
- **Current State**: Displays as generic sand tile (placeholder)
- **Design Notes**: 
  - Should match Bronze Age Canaanite aesthetic
  - Weathered stone with ancient inscriptions
  - Distinguishable from surrounding terrain
  - Atmospheric and mysterious

### Short-Term Priority

**Interaction Popup Screen UI**
- **Purpose**: Display lore text, location descriptions, NPC dialogue
- **Design Requirements**:
  - **Background**: Semi-transparent dark panel (world visible behind it)
  - **Border**: Decorative Bronze Age Canaanite-themed border
  - **Layout**:
    - Left side: Image slot (64×64 or 80×80)
      - Lore stone icon
      - Location marker
      - NPC portrait
      - Item illustration
    - Right side: Scrollable text area
    - Bottom center: "SPACE to continue" prompt
  - **Size**: Approximately 60-70% screen width, 30% height
  - **Position**: Centered on screen
- **Behavior**: 
  - Popup when triggered (NOT persistent bottom bar)
  - World dims slightly but remains visible
  - Separate from TAB menu system
  - Clean, atmospheric presentation

### In Development

**Audio Assets**
- **Main Theme**: Oboe d'amore + cello conversation structure
- **Musical Structure**: AAABCE motif in A minor
- **Narrative Theme**: "Chasing an absent god" - the search for E is the search for the gods
- **Fourth Voice**: English horn under consideration (compromise between creative visions)
- **Development Stage**: Active composition with musical director

---

## Active Priorities

### Immediate (Ready to Implement)
1. **Create lore stone tile** (24×24 texture asset)
2. **Design interaction popup screen** (UI layout and decoration)
3. **Apply held-input to 3D scenes** (PassageToYeriho, Yeriḥo navigation)

### Short-Term
4. **WOO-12:** Make Yeriḥo region fully playable with complete narrative flow
5. **Add 1-2 more lore locations** to StarterZone (minimal but impactful)
6. **Improve Yeriḥo camera alignment** for better street/corner navigation

### Medium-Term
7. **WOO-11:** Implement Lunar Gate puzzle (Level 1→2 in Catacombs)
8. **WOO-10:** Fix Catacombs navigation + redraw all three level maps
9. **WOO-9:** Complete Levant overworld map (120×180 tiles, hand-drawn on graph paper)

### Long-Term
10. **WOO-7:** Implement remaining 9 major cities (Ṣur, ʿAkko, Šekhem, Yerušalem, +5 more)
11. **WOO-8:** Expand corrupted pantheon narrative framework
12. **WOO-16:** Design party companion personalities and dialogue system

---

## Technical Improvements (v0.3.7)

### Code Organization
- Movement logic centralized in autoload singleton
- Single source of truth for movement timing across all scenes
- Easy global adjustments (one file to edit)
- Reduced code duplication (15 lines → 3 lines per scene)
- Consistent behavior project-wide

### Performance
- No performance impact from held-input system
- Delta-based timing ensures smooth frame rate
- Minimal processing overhead
- Efficient state management

### Maintainability
- Clear separation of concerns (movement logic vs. scene logic)
- Easy to apply to new scenes (copy 3 lines)
- Simple to tune (adjust constants in one place)
- Well-documented code with inline comments

---

## Development Workflow

### Tools & Platforms
- **Engine:** Godot 3.5.3 LTS
- **Version Control:** GitHub (fenrisulf75/river-of-dawn)
- **Project Management:** Linear (Woodbridge Creative workspace)
- **Documentation:** Google Drive (project_state docs, design docs)
- **Graphics:** GIMP (primary tool for texture creation)
- **Map Design:** Hand-drawn on 11×17 graph paper → digital translation
- **Audio:** Musical composition in progress (oboe d'amore, cello, English horn)

### Team Structure
- **Tim:** Lead design, programming, systems implementation
- **Visual Artist:** Visual assets, GIMP work, narrative consultation
- **Claude:** Technical implementation partner, code assistance

---

## Git Repository Status

**Latest Commit:** `bb4c406`  
**Commit Message:** "v0.3.6-alpha fixes: folder reorganization path corrections, held-input movement system"

**Files Changed:** 7  
**Insertions:** +85  
**Deletions:** -25

### Changes Include:
- New file: `scripts/MovementSystem2D.gd`
- Modified: `scenes/overworld/StarterZone.gd`
- Modified: `scenes/cities/Yeriho.gd`
- Modified: `scenes/cities/Yeriho.tscn`
- Modified: `scenes/dungeons/CatacombsLevel1.gd`
- Modified: `project.godot` (MovementSystem2D autoload registration)
- Path fixes across multiple files

---

## Project Scope Reminder

**Five-Region Campaign Structure:**
1. **Levant** (current) - 10 cities, Bronze Age Canaanite setting (~1000 BCE)
2. **Mesopotamia** - Babylonian/Assyrian regions
3. **Persia** - Persian Empire zones  
4. **Transition Area** - Bridge between mortal and divine realms
5. **Boss Realm** - Final confrontation with corrupted pantheon

**Current Focus:** Making Levant Region 1 fully playable before expanding to other regions.

**Corrupted Pantheon (Core Deities):**
- **Yarikh** - Moon god
- **Baʿal** - Storm/fertility god  
- **Tharanim** - [Role TBD]

**Narrative Theme:** The gods have become corrupted. Players must "chase an absent god" through five regions to confront the corrupted pantheon and restore balance.

---

## Recent Collaboration Notes

### With Visual Artist
- Working on lore stone tile design (24×24, Bronze Age aesthetic)
- Discussing interaction popup screen layout and decoration
- Considering decorative borders for UI elements
- Planning image assets for lore interactions

### With Musical Director
- Refining main theme structure (AAABCE motif)
- Exploring fourth voice options (English horn as compromise)
- Developing "chasing an absent god" musical narrative
- Oboe d'amore and cello conversational arrangement

### Technical
- Linear workspace fully established for task tracking
- GitHub workflow solidified for iMac ↔ MacBook Air synchronization
- Google Drive documentation structure working well
- Project state docs providing clear development snapshots

---

## Version History

- **v0.3.7-alpha:** Path fixes from reorganization + held-input movement system
- **v0.3.6-alpha:** Complete project folder reorganization
- **v0.3.5-alpha:** Fixed directional fog of war bug, menu improvements
- **v0.3.4-alpha:** Ba'al symbol tile, animated brine, advanced fog of war
- **v0.3.3-alpha:** Fog of war system, curved path tiles
- **v0.3.2-alpha:** Yeriḥo city generation, PassageToYeriho dungeon
- **v0.3.1-alpha:** Combat system, inventory, basic navigation

---

## Development Session Notes (December 25, 2025)

### Focus Areas
- Christmas Day session focused on bug fixes and quality-of-life improvements
- Systematically fixed all path issues from folder reorganization
- Implemented held-input movement system for better player experience
- Established foundation for rapid feature implementation

### Achievements
- All scene transitions now working correctly
- Movement feels significantly more responsive and comfortable
- Code is cleaner and more maintainable
- Ready to expand held-input to 3D scenes
- Visual asset pipeline clearly defined

### Lessons Learned
- Godot 3.5.3 autoload naming is case-sensitive (MovementSystem2D vs. Movementsystem2d)
- Centralized systems save significant development time
- Clear documentation helps coordinate with collaborators
- Small quality-of-life improvements have large impact on gameplay feel

---

**Next Update:** After lore stone tile creation and/or 3D held-input implementation

**Status:** v0.3.7-alpha stable and ready for continued development
