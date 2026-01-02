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
- `TcpReader` (Shared/Communication/) - TCP socket connection to Netrek servers
- `PacketAnalyzer` (Shared/Communication/) - Parses Netrek binary protocol packets into game state

**Entry Points**:
- macOS: `NetrekMacOS/Global Group/AppDelegate.swift` - Creates main window with `EverythingView`, runs 20Hz update timer
- iPadOS: `NetrekIPad/Global Group/AppDelegate.swift` + `SceneDelegate.swift`

### Networking
- Game servers: TCP port 2592 (e.g., `pickled.netrek.org`, `continuum.us.netrek.org`)
- Meta-server: TCP port 3521 (`metaserver.netrek.org`)
- Raw binary protocol - no HTTP/REST

### UI Pattern
- MVVM with SwiftUI
- Canvas-based rendering for tactical/strategic map views
- Platform-specific: NSWindow management (macOS), UIWindow/scene management (iPadOS)

## Testing

No automated tests configured. Testing is manual play-testing only.

## Key Enumerations

Located in `Shared/Enumerations/`:
- `Team` - 4 factions (Federation, Roman, Klingon, Orion)
- `ShipType` - 7 ship classes (Scout, Destroyer, Cruiser, Battleship, Assault, Starbase, Galaxy)
- `GameState` - Connection/game state machine states
- `AlertCondition` - Ship alert states
