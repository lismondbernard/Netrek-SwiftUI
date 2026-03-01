# Netrek SwiftUI Architecture

## Overview

Netrek SwiftUI is a modern macOS and iPadOS client for the classic multiplayer space combat game Netrek. The architecture follows MVVM (Model-View-ViewModel) principles with SwiftUI for the presentation layer.

## Project Structure

```
Netrek2.xcodeproj/
├── Shared/                    # Cross-platform code (86+ files)
│   ├── Communication/         # Network protocol implementation
│   ├── Constants/            # Game and packet constants
│   ├── Enumerations/         # Core enums (Team, ShipType, GameState, etc.)
│   ├── Global/               # Global utilities (GameLogger)
│   ├── Managers/             # Business logic managers
│   ├── Model/                # Game entity models
│   ├── Mocks/                # Test mocks for SwiftUI previews
│   ├── Protocols/            # Protocol definitions
│   ├── ViewModels/           # MVVM view models
│   └── Views/                # Shared SwiftUI views
├── NetrekMacOS/              # macOS-specific code
│   ├── Global Group/         # AppDelegate, main entry point
│   ├── Controllers/          # macOS controllers (keymap, preferences)
│   └── Views/                # macOS-specific views
└── NetrekIPad/               # iPadOS-specific code
    ├── Global Group/         # AppDelegate, SceneDelegate
    ├── Controllers/          # iOS controllers (audio, etc.)
    └── Views/                # iPadOS-specific views
```

## Architecture Layers

### 1. Model Layer (`Shared/Model/`)

**Core Classes:**
- `Universe` - Singleton containing all game state
  - 32 `Player` objects
  - 40 `Planet` objects
  - 256 `Torpedo` objects
  - 32 `Laser` objects
  - 256 `Plasma` objects
  - Uses `@Published` for reactive updates
- `Player`, `Planet`, `Torpedo`, `Laser`, `Plasma` - Game entities
  - All conform to `ObservableObject`
  - Individual entities publish their own changes

**Design Pattern:** Observable singleton with nested observable objects

### 2. ViewModel Layer (`Shared/ViewModels/`)

**Purpose:** Provide view-specific data transformations and business logic

**Key ViewModels:**
- `TacticalViewModel` - Tactical (zoomed-in) view state
  - Filters visible entities based on player position
  - Provides coordinate transformations (screen ↔ game world)
  - Handles zoom level (`visualWidth`)
- `StrategicViewModel` - Strategic (galaxy map) view state
  - Shows all players/planets
  - Different coordinate scaling
- `MessagesViewModel` - Message display and sending
  - Manages message history
  - Handles message composition

**Factory Pattern:**
- `ViewModelFactory` - Creates and configures ViewModels
  - Injects dependencies (Universe, command executor)
  - Ensures single source of truth

### 3. View Layer (`Shared/Views/`, platform-specific Views)

**Technology:** SwiftUI with Canvas-based rendering

**Key Views:**
- `TacticalView` - Main gameplay view (tactical map)
  - Canvas-based rendering for performance
  - Shows nearby ships, planets, weapons
- `StrategicView` - Galactic map view
  - Shows entire galaxy
  - Color-coded team territories
- `MessagesView` - Message log and input
- `StatisticsView` - Player statistics
- Entity views: `PlayerView`, `PlanetView`, `TorpedoView`, etc.

**Rendering Strategy:**
- Phase 2.1 migrated from individual SwiftUI views to Canvas-based rendering
- 60% reduction in memory usage
- Smoother frame rates

### 4. Manager Layer (`Shared/Managers/`)

**Purpose:** Coordinate business logic and state transitions

**Key Managers:**
- `ServerConnectionManager` - Network lifecycle
  - Owns `TcpReader`, `MetaServer`, `PacketAnalyzer`
  - Manages connection state
  - Sends login credentials
- `GameStateManager` - Game state machine
  - Transitions: `noServerSelected → serverSelected → serverConnected → serverSlotFound → loginAccepted → gameActive`
  - Manages team eligibility
- `GameTimerManager` - 20Hz game update loop
  - Triggers periodic UI updates
  - Manages timer lifecycle

### 5. Communication Layer (`Shared/Communication/`)

**Network Protocol:** Custom binary TCP protocol (Netrek protocol)

**Key Classes:**
- `TcpReader` - TCP socket wrapper
  - Uses Apple's `Network.framework` (NWConnection)
  - Async/await for modern concurrency
  - Calls delegate on data received
- `PacketAnalyzer` - Binary packet parser
  - Parses 60+ packet types
  - Updates Universe model
  - Dispatches to main thread for UI updates
- `MakePacket` - Outgoing packet builder
  - Creates binary packets for commands
  - Handles byte ordering (network endianness)
- `MetaServer` - Server list fetcher
  - Queries metaserver for active game servers

**Packet Protocol:**
- Fixed-length and variable-length packets
- Packet types defined in `PacketConstants.swift`
- Sizes: 4 to 524 bytes

### 6. Constants Layer (`Shared/Constants/`)

**Purpose:** Centralize magic numbers for maintainability

**Files:**
- `GameConstants.swift` - Game parameters
  - Galaxy size: 100,000 x 100,000 game units
  - Update rate: 20 Hz
  - Player/planet/weapon limits
  - Network buffer sizes
- `PacketConstants.swift` - Network protocol
  - `PacketType` enum (60+ types)
  - `PacketSize` lookup table
  - `PacketOffsets` for byte-level parsing

## Game State Machine

```
┌─────────────────────┐
│ noServerSelected    │
└──────────┬──────────┘
           │ connectToServer()
           ▼
┌─────────────────────┐
│ serverSelected      │
└──────────┬──────────┘
           │ TCP ready
           ▼
┌─────────────────────┐
│ serverConnected     │
└──────────┬──────────┘
           │ SP_YOU received
           ▼
┌─────────────────────┐
│ serverSlotFound     │
└──────────┬──────────┘
           │ sendLogin()
           ▼
┌─────────────────────┐
│ loginAccepted       │
└──────────┬──────────┘
           │ SP_PICKOK received
           ▼
┌─────────────────────┐
│ gameActive          │ ◄─── Main gameplay loop
└─────────────────────┘
```

## Data Flow

### Incoming Data (Server → Client)

```
Server
  ↓ TCP packets
TcpReader.receive()
  ↓ Data
PacketAnalyzer.analyze()
  ↓ Parse packets
Universe.updatePlayer/updatePlanet/etc.
  ↓ @Published changes
ViewModels observe Universe
  ↓ Filtered data
Views observe ViewModels
  ↓ Render
Canvas draws game entities
```

### Outgoing Commands (Client → Server)

```
User Input (keyboard/mouse)
  ↓
KeymapController.execute()
  ↓ Control enum
MakePacket.cpDirection/cpSpeed/etc.
  ↓ Binary Data
TcpReader.send()
  ↓ Network
Server
```

## Threading Model

- **Main Thread:** All UI updates, Universe changes
- **Background Threads:**
  - TCP receive operations (NWConnection queue)
  - Packet parsing dispatches to main for model updates
- **@MainActor:** GameStateManager, ViewModels use explicit main actor

## Logging Architecture

**System:** OSLog (Apple Unified Logging)

**Logger:** `GameLogger` enum in `Shared/Global/GameLogger.swift`

**Categories:**
- `.network` - TCP send/receive
- `.connection` - Connection lifecycle
- `.packets` - Packet parsing details
- `.gameState` - Universe state changes
- `.commands` - User command execution
- `.ui` - View lifecycle
- `.input` - User input handling
- `.performance` - Timing/performance metrics

**Usage:**
```swift
GameLogger.info("Connected to server", category: .connection)
GameLogger.debug("Received SP_PLAYER packet", category: .packets)
GameLogger.error("Invalid packet type", category: .network)
```

**Performance:** Debug logs automatically stripped in Release builds via `#if DEBUG`

## Dependency Injection

**Pattern:** Constructor injection with factory

**Flow:**
1. `ViewModelFactory.shared.configure()` - Called from AppDelegate
   - Injects `GameCommandExecuting` (KeymapController)
   - Injects `NetworkSending` (AppDelegate/ServerConnectionManager)
2. Views request ViewModels from factory
3. Factory creates ViewModels with injected dependencies

**Benefits:**
- Testable (inject mocks)
- SwiftUI Previews work (inject mock data)
- Decouples layers

## Testing Strategy

**Current State:** Manual testing only (no automated test suite)

**Test Infrastructure in Place:**
- Mock objects (`Shared/Mocks/`)
  - `MockPlayer`, `MockPlanet`, `MockUniverse`
  - Used for SwiftUI Previews
- Protocols enable dependency injection
  - `PlayerProviding`, `NetworkSending`, etc.

**Future Test Additions:**
- Unit tests for ViewModels
- Unit tests for packet parsing
- Integration tests for network flow

## Platform Differences

### macOS (`NetrekMacOS/`)
- **Window Management:** NSWindow-based
- **Input:** Keyboard + mouse
- **Entry Point:** `AppDelegate` (NSApplicationDelegate)
- **Menu Bar:** Native macOS menus
- **Update Loop:** Timer in AppDelegate

### iPadOS (`NetrekIPad/`)
- **Window Management:** UIWindow + SceneDelegate
- **Input:** Touch gestures
- **Entry Point:** `AppDelegate` + `SceneDelegate`
- **UI:** Touch-optimized layouts
- **Update Loop:** DisplayLink or Timer

### Shared Code (~85%)
Most game logic, networking, and models are 100% shared via the `Shared/` directory.

## Performance Optimizations

### Phase 2.1: Canvas Migration
- **Before:** Individual SwiftUI views for each entity
- **After:** Single Canvas with manual drawing
- **Result:** 62% memory reduction, smoother 60 FPS

### Phase 2.2: @Published Optimization
- Reduced unnecessary `@Published` properties
- 62% reduction in property observers
- Minimized reactive update overhead

### Network Buffer Management
- 16 KB receive buffer
- 32 KB max packet buffer
- Reuses Data objects to reduce allocations

## Key Design Decisions

### Why Singleton for Universe?
- **Pros:** Single source of truth, easy access
- **Cons:** Harder to test
- **Mitigation:** Protocols abstract access, mocks for previews

### Why Canvas Instead of Individual Views?
- **Reason:** 60+ entities updating 20x/second overwhelmed SwiftUI diffing
- **Trade-off:** Lost individual view animations, gained performance

### Why OSLog Instead of print()?
- **Categorization:** Filter logs by subsystem
- **Performance:** Zero cost in Release builds
- **Integration:** Works with Console.app and Instruments

### Why 20 Hz Update Rate?
- **Protocol Constraint:** Netrek servers send updates at 20 Hz
- **Display:** Decoupled from display refresh (60 Hz)

## Code Quality Metrics

- **Files:** 150+ Swift files
- **Lines of Code:** ~15,000 SLOC
- **Platforms:** macOS 12+, iPadOS 15+
- **Swift Version:** 5.9+
- **Dependencies:** Zero external (pure Swift/SwiftUI)

## Build Targets

- **Netrek (macOS)** - Main macOS app target
- **NetrekIPad (iOS)** - iPadOS app target
- Both link against shared code via Xcode target membership

## Resources

- **Images:** Ship/planet sprites in Assets.xcassets
- **Sounds:** (TODO: Document audio assets)
- **Localization:** English only

## Future Architecture Improvements

1. **Add Test Suite** - Unit tests for critical paths
2. **Extract Network Layer** - SPM package for protocol
3. **Improve Universe API** - Replace singleton with injected instance
4. **Add Analytics** - Track performance metrics
5. **SwiftUI Previews** - Enable for all major views

## References

- [Netrek Protocol Specification](http://www.netrek.org/)
- [Apple Network Framework](https://developer.apple.com/documentation/network)
- [SwiftUI Canvas](https://developer.apple.com/documentation/swiftui/canvas)
- [OSLog Best Practices](https://developer.apple.com/documentation/oslog)
