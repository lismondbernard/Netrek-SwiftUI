# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Netrek SwiftUI is a modern macOS and iPadOS client for the classic Internet team strategy game Netrek (originally from 1989). This is a complete Swift/SwiftUI reimplementation with no legacy code reuse.

## Build Commands

Open `Netrek2.xcodeproj` in Xcode:
- **macOS target**: Select "Netrek" scheme, build for macOS (Cmd+B)
- **iPadOS target**: Select "Netrek" scheme, build for iOS/iPadOS simulator or device (use iPhone 17 Pro simulator, iOS 26.2)

No package managers or external dependencies - pure Swift/SwiftUI.

## Architecture

### Dual-Target Structure
- **Shared/** - Cross-platform code (~86 Swift files)
- **NetrekMacOS/** - macOS-specific code (AppDelegate, views, window management)
- **NetrekIPad/** - iPadOS-specific code (AppDelegate, SceneDelegate, touch handling)

### Core Components

**Game State Machine** (`GameState` enum):
```
noServerSelected → serverSelected → serverConnected → serverSlotFound → loginAccepted → gameActive
```

**Key Classes**:
- `Universe` (Shared/Model/) - Singleton holding all game state (players, planets, weapons). Uses `@Published` for reactive UI updates.
- `Player`, `Planet` (Shared/Model/) - Game entity representations
- `TcpReader` (Shared/Communication/) - TCP socket connection to Netrek servers using Apple's Network framework
- `PacketAnalyzer` (Shared/Communication/) - Parses Netrek binary protocol packets into game state

**Entry Points**:
- macOS: `NetrekMacOS/Global Group/AppDelegate.swift` - Creates main window with `EverythingView`, runs 20Hz update timer
- iPadOS: `NetrekIPad/Global Group/AppDelegate.swift` + `SceneDelegate.swift`

### Networking
- Game servers: TCP port 2592 (e.g., `pickled.netrek.org`, `continuum.us.netrek.org`)
- Meta-server: TCP port 3521 (`metaserver.netrek.org`)
- Raw binary protocol - no HTTP/REST
- Well-known servers defined in `Shared/Global/Globals.swift`

### UI Pattern
- MVVM with SwiftUI
- Canvas-based rendering for tactical/strategic map views
- Platform-specific: NSWindow management (macOS), UIWindow/scene management (iPadOS)

### Update Cycle
1. 20Hz timer fires from AppDelegate
2. TcpReader receives incoming packets
3. PacketAnalyzer parses binary packets
4. Universe singleton updated with new game state
5. SwiftUI views automatically refresh via @Published properties

## Testing

No automated tests configured. Testing is manual play-testing only.

## Key Enumerations

Located in `Shared/Enumerations/`:
- `Team` - 6 factions (Independent, Federation, Roman, Kazari, Orion, Ogg)
- `ShipType` - 7 ship classes (Scout, Destroyer, Cruiser, Battleship, Assault, Starbase, Battlecruiser)
- `GameState` - Connection/game state machine states
- `AlertCondition` - Ship alert states (Green, Yellow, Red)
- `SlotStatus` - Player slot states (Free, Outfit, Alive, Explode, Dead, Observe)

## Game Controller Support

MFI (Made for iPhone) game controller support is implemented using Apple's GameController framework.

### Files
- `Shared/Controllers/GameControllerInputState.swift` - Tracks analog stick values and dead zone
- `Shared/Controllers/GameControllerManager.swift` - Singleton managing controller connections and input

### Button Mapping

| Controller Input | Game Action |
|-----------------|-------------|
| Left Stick | Set Course (continuous) |
| Right Stick | Aim Direction (for weapons) |
| D-pad | Set Course (alternative) |
| A Button | Fire Torpedo |
| B Button | Fire Laser/Phaser |
| X Button | Toggle Shields |
| Y Button | Toggle Cloak |
| Left Shoulder | Decrease Speed |
| Right Shoulder | Increase Speed |
| Left Trigger | Detonate Enemy Torps |
| Right Trigger | Fire Plasma |

### Architecture

```
GCController events
    → GameControllerManager (button handlers + 20Hz timer)
    → GameControllerInputState (tracks analog values)
    → KeymapController.execute(command, location:)
    → MakePacket → TcpReader.send()
```

The controller manager is initialized in both AppDelegates during `applicationDidFinishLaunching`. Controller connections are detected automatically via `GCControllerDidConnect` notifications.

## Important Notes

- Do not directly modify files under `NetrekMacOS/Resources/Netrek.help` - that directory is built from `Netrek.pchelp` by the HelpCrafter application
- The `packets.swift` file contains C-style packet struct definitions matching the Netrek protocol
