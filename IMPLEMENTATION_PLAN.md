# Netrek SwiftUI - Implementation Plan
## Code Quality & Architecture Improvements

**Generated**: 2026-01-18
**Status**: Ready for Review

---

## Executive Summary

This plan addresses the critical issues identified in the code review, organized into 6 phases. The plan prioritizes stability and safety first, followed by performance, modernization to SwiftUI lifecycle, architecture, and quality improvements.

**Total Scope**: ~70-90 individual tasks across 6 phases
**Risk Mitigation**: Each phase includes validation steps before proceeding

**NEW**: Phase 2.5 added for SwiftUI App/Scene lifecycle modernization - this will significantly simplify Phase 3 and align with modern SwiftUI best practices.

---

## Phase 1: Critical Stability & Safety
**Goal**: Eliminate crash risks and thread safety issues
**Priority**: CRITICAL - Must complete before production use
**Dependencies**: None - can start immediately

### 1.1 Force Unwrap Elimination (282 occurrences)

#### High-Risk Areas First
- [ ] **Network Layer** (Shared/Communication/)
  - [ ] PacketAnalyzer.swift - Replace `data[0]` with safe subscripting
  - [ ] TcpReader.swift - Safe delegate casting
  - [ ] MakePacket.swift - Bounds checking on all array access
  - [ ] Add validation: `guard data.count >= expectedSize else { return }`

- [ ] **AppDelegate Access** (9 files with `as! AppDelegate`)
  - [ ] Shared/Model/Player.swift:41-44
  - [ ] Shared/Model/Planet.swift:20-24
  - [ ] Shared/Model/Laser.swift, Plasma.swift, Torpedo.swift
  - [ ] Shared/Model/Explosion.swift, Phaser.swift
  - [ ] Replace with protocol-based dependency injection (see Phase 3)
  - [ ] **Quick fix**: Use `as? AppDelegate` with nil handling

- [ ] **Player/Universe Array Access**
  - [ ] Use existing `Collection[safe:]` extension consistently
  - [ ] Replace `Universe.universe.players[me]` with `players[safe: me]`
  - [ ] Add validation: `guard players.indices.contains(playerID) else { return }`

- [ ] **String/Data Parsing**
  - [ ] Message parsing with force unwrapping
  - [ ] Packet type casting
  - [ ] Add comprehensive guard statements

#### Validation
- [ ] Build with -Xfrontend -warn-long-expression-type-checking
- [ ] Search codebase: `grep -r "!" --include="*.swift"` should show significant reduction
- [ ] Run app through full game cycle, verify no crashes

---

### 1.2 Thread Safety - Universe Singleton

#### Current Problem
```swift
// Accessed from 3+ threads simultaneously:
// - Main thread (UI)
// - Network thread (TcpReader)
// - Timer thread (game loop)
static var universe = Universe()
```

#### Solution Options

**Option A: Actor Isolation (Recommended for iOS 15+)**
```swift
@MainActor
class Universe: ObservableObject {
    static let shared = Universe()
    // All access now guaranteed on main thread
}
```
- [ ] Add `@MainActor` to Universe class
- [ ] Ensure all PacketAnalyzer updates dispatch to main first
- [ ] Update 115+ call sites to use `await` where needed

**Option B: Serial Queue Protection (iOS 14 compatible)**
```swift
class Universe: ObservableObject {
    private let accessQueue = DispatchQueue(label: "universe.access")

    func updatePlayer(_ id: Int, updates: (Player) -> Void) {
        accessQueue.sync {
            updates(players[id])
        }
    }
}
```
- [ ] Add serial queue to Universe
- [ ] Wrap all mutations in queue.sync
- [ ] Wrap all reads in queue.sync (or use concurrent queue with barriers)

#### Implementation Steps
- [ ] Choose Option A or B based on deployment target
- [ ] Implement synchronization mechanism
- [ ] Audit all 115+ Universe.universe call sites
- [ ] Update PacketAnalyzer to respect synchronization
- [ ] Update game loop timer to respect synchronization
- [ ] Add thread sanitizer testing: Edit scheme → Diagnostics → Thread Sanitizer

#### Validation
- [ ] Run with Thread Sanitizer enabled
- [ ] No data races reported
- [ ] Full gameplay session without crashes

---

### 1.3 Fix TcpReader Receive Loop

#### Current Problem
```swift
// TcpReader.swift:68-86
connection.receive(...) { (content, context, isComplete, error) in
    if let content = content {
        self.delegate.gotData(data: content, from: self.hostname, port: self.port)
    }
    // ❌ Doesn't call receive() again!
}

// PacketAnalyzer calls receive() - wrong responsibility!
```

#### Solution
- [ ] **File**: Shared/Communication/TcpReader.swift:68-86
- [ ] Make receive() call itself recursively in completion handler:
```swift
private func startReceiving() {
    connection.receive(minimumIncompleteLength: 1, maximumLength: 16384) { [weak self] (content, context, isComplete, error) in
        guard let self = self else { return }

        if let error = error {
            self.delegate.connectionError(error: error, from: self.hostname, port: self.port)
            return
        }

        if let content = content {
            self.delegate.gotData(data: content, from: self.hostname, port: self.port)
        }

        if !isComplete {
            self.startReceiving() // ✅ Recursive call
        } else {
            self.delegate.connectionClosed(from: self.hostname, port: self.port)
        }
    }
}
```

- [ ] **File**: Shared/Communication/TcpReader.swift - Update connect():
```swift
func connect() {
    connection.start(queue: connectionQueue)
    startReceiving() // Start the receive loop
}
```

- [ ] **File**: Shared/Communication/PacketAnalyzer.swift - Remove receive() calls:
  - [ ] Remove `self.reader?.connection.receive(...)` calls
  - [ ] PacketAnalyzer should only process data, not control network

#### New Protocol Method Needed
- [ ] Add to TcpReaderDelegate protocol:
```swift
func connectionError(error: Error, from hostname: String, port: Int)
func connectionClosed(from hostname: String, port: Int)
```

- [ ] Implement in AppDelegate

#### Validation
- [ ] Connect to server successfully
- [ ] Receive continuous packet stream
- [ ] Handle connection drops gracefully
- [ ] Verify no receive() calls in PacketAnalyzer

---

### 1.4 Network Error Handling

- [ ] **File**: Shared/Communication/TcpReader.swift
  - [ ] Handle `error` parameter in receive closure
  - [ ] Handle `isComplete` for connection closure
  - [ ] Add connection timeout handling
  - [ ] Add retry logic with exponential backoff

- [ ] **File**: Shared/Communication/PacketAnalyzer.swift
  - [ ] Validate packet minimum size before parsing
  - [ ] Handle malformed packet data gracefully
  - [ ] Add error reporting to UI layer

- [ ] **File**: AppDelegate.swift
  - [ ] Implement TcpReaderDelegate error methods
  - [ ] Show user-facing error messages
  - [ ] Update GameState on network errors
  - [ ] Add reconnection UI/logic

- [ ] Add comprehensive guard statements:
```swift
guard data.count >= 2 else {
    debugPrint("Invalid packet: too short")
    return
}
let packetType = data[0]
let expectedSize = packetSizes[Int(packetType)] ?? 0
guard data.count >= expectedSize else {
    debugPrint("Invalid packet \(packetType): expected \(expectedSize), got \(data.count)")
    return
}
```

#### Validation
- [ ] Test with network interruption (turn off WiFi mid-game)
- [ ] Test with invalid/corrupted packet data
- [ ] Test server timeout scenario
- [ ] Verify user sees appropriate error messages

---

### 1.5 Phase 1 Validation Checklist

**Before proceeding to Phase 2, verify:**
- [ ] No force unwraps in critical paths (network, game loop)
- [ ] Thread Sanitizer shows no data races
- [ ] Full gameplay session (15+ minutes) without crashes
- [ ] Network error scenarios handled gracefully
- [ ] App builds with zero warnings
- [ ] Existing functionality unchanged (regression testing)

---

## Phase 2: Performance Optimization
**Goal**: Reduce CPU usage, improve frame rate, eliminate UI stutter
**Priority**: HIGH - Affects user experience
**Dependencies**: Phase 1 complete (stable foundation needed)

### 2.1 Fix 20Hz View Redraw Issue

#### Current Problem
```swift
// TacticalView redraws entire hierarchy 20 times/second
@ObservedObject var serverUpdate = Universe.universe.serverUpdate
// Triggers: 8 ForEach loops × 32 entities = 256+ view updates per tick
```

#### Solution Path A: Canvas Rendering (Recommended)
- [ ] **New File**: Shared/Views/TacticalCanvasView.swift
  - [ ] Create Canvas-based tactical display
  - [ ] Render all entities in single draw call
  - [ ] Use TimelineView for controlled updates
  - [ ] Cache entity positions/images

- [ ] **Implementation**:
```swift
TimelineView(.animation(minimumInterval: 1.0/20.0)) { timeline in
    Canvas { context, size in
        // Single render pass for all entities
        drawPlayers(context: context, size: size)
        drawPlanets(context: context, size: size)
        drawWeapons(context: context, size: size)
    }
}
```

- [ ] Replace ForEach-based rendering in:
  - [ ] NetrekMacOS/Views/TacticalView.swift:118-275
  - [ ] NetrekIPad/Views/TacticalView.swift (similar)

- [ ] Keep SwiftUI views only for:
  - [ ] UI controls (buttons, sliders)
  - [ ] Text overlays
  - [ ] Selection indicators

#### Solution Path B: Optimize Existing Views (If Canvas not feasible)
- [ ] **File**: Shared/Views/TacticalView.swift
  - [ ] Use TacticalViewModel with selective updates
  - [ ] Only publish changed entities
  - [ ] Use `.id()` on ForEach items for better diffing
  - [ ] Implement Equatable on view models

- [ ] **New**: Shared/ViewModels/TacticalViewModel.swift
```swift
class TacticalViewModel: ObservableObject {
    @Published private(set) var visiblePlayerIDs: Set<Int> = []
    @Published private(set) var changedPlayerIDs: Set<Int> = []

    func update() {
        // Only publish IDs that actually changed position/status
        let newVisible = calculateVisiblePlayers()
        changedPlayerIDs = newVisible.symmetricDifference(visiblePlayerIDs)
        visiblePlayerIDs = newVisible
    }
}
```

#### Measurement Before/After
- [ ] Profile with Instruments (Time Profiler)
- [ ] Measure CPU usage during active gameplay
- [ ] Target: <20% CPU usage during 20Hz updates

#### Validation
- [ ] Smooth 60fps rendering
- [ ] CPU usage significantly reduced
- [ ] No visual glitches or missing entities
- [ ] All game functionality preserved

---

### 2.2 Optimize @Published Usage

#### Audit and Reduce
- [ ] **File**: Shared/Model/Player.swift
  - Current: 7 @Published properties
  - [ ] Remove @Published from properties not observed by UI
  - [ ] Keep only: positionX, positionY, shieldsUp, teamColor, imageName
  - [ ] Regular properties for: internal flags, cloaking state, etc.

- [ ] **File**: Shared/Model/Planet.swift
  - [ ] Audit which properties UI actually observes
  - [ ] Remove @Published from internal state

- [ ] **File**: Shared/Model/Universe.swift
  - [ ] Remove @Published from computed properties (they already trigger on dependencies)
  - [ ] Consider single `@Published var updateTrigger: Int` instead of many properties

#### Implement Batched Updates
- [ ] **Pattern**: Collect changes, publish once
```swift
// Instead of:
@Published var positionX: Int
@Published var positionY: Int

// Use:
@Published var position: CGPoint
```

- [ ] Group related property changes
- [ ] Use `objectWillChange.send()` manually for fine control

#### Validation
- [ ] Grep for @Published count: should reduce from 142 to ~50
- [ ] Profile: fewer objectWillChange notifications
- [ ] UI still updates correctly for all visual changes

---

### 2.3 Batch Main Thread Updates

#### Current Problem
```swift
// PacketAnalyzer.swift - 35 separate dispatches per packet
DispatchQueue.main.async {
    self.positionX = newX
}
DispatchQueue.main.async {
    self.positionY = newY
}
// Result: 35 × 20 packets/sec = 700 dispatches/sec
```

#### Solution
- [ ] **File**: Shared/Communication/PacketAnalyzer.swift
  - [ ] Create update accumulator:
```swift
struct PlayerUpdate {
    var positionX: Int?
    var positionY: Int?
    var shields: Int?
    // ... all updateable properties
}

private var pendingUpdates: [Int: PlayerUpdate] = [:]

func applyPendingUpdates() {
    DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        for (playerID, update) in self.pendingUpdates {
            if let player = Universe.universe.players[safe: playerID] {
                update.apply(to: player)
            }
        }
        self.pendingUpdates.removeAll()
    }
}
```

- [ ] Batch updates per packet group
- [ ] Single main thread dispatch per packet or per frame

#### For Position Updates Specifically
- [ ] Consider interpolation for smooth movement
- [ ] Update positions at 60fps, not 20fps
- [ ] Interpolate between network updates

#### Validation
- [ ] Instruments shows 90% reduction in main thread dispatches
- [ ] No visual lag or stutter
- [ ] Position updates smooth and accurate

---

### 2.4 Optimize Hot Path Computations

#### Cache Computed Properties
- [ ] **File**: Shared/Model/Universe.swift
  - [ ] `visiblePlayers` - cache, invalidate on position changes
  - [ ] `alivePlayers` - cache, invalidate on death/respawn
  - [ ] `activePlanets` - rarely changes, cache aggressively

- [ ] **Implementation Pattern**:
```swift
private var _cachedVisiblePlayers: [Player]?
private var lastMyPosition: CGPoint = .zero

var visiblePlayers: [Player] {
    let myPos = players[me].position
    if _cachedVisiblePlayers == nil || myPos != lastMyPosition {
        _cachedVisiblePlayers = alivePlayers.filter { /*...*/ }
        lastMyPosition = myPos
    }
    return _cachedVisiblePlayers!
}
```

#### Pre-calculate View Geometry
- [ ] **File**: Shared/Views/PlayerView.swift:42
  - [ ] Move offset calculations to ViewModel
  - [ ] Pre-calculate in background
  - [ ] Expose as simple CGPoint to view

- [ ] **New**: Shared/ViewModels/PlayerViewModel.swift
```swift
class PlayerViewModel: ObservableObject {
    @Published private(set) var screenPosition: CGPoint = .zero

    func update(player: Player, camera: Camera, screenSize: CGSize) {
        // Calculate once, publish result
        screenPosition = calculateScreenPosition(/*...*/)
    }
}
```

#### Validation
- [ ] Profile shows filter operations no longer in hot path
- [ ] Consistent 60fps during intense gameplay (32 players visible)

---

### 2.5 Phase 2 Validation Checklist

**Performance targets:**
- [ ] CPU usage < 20% during active gameplay (current: measure baseline first)
- [ ] 60fps UI rendering without drops
- [ ] Battery drain < 5% per 10 minutes gameplay (iOS)
- [ ] No UI stutter when 32 players active
- [ ] Main thread dispatch count < 100/sec (from ~700/sec)

**Profile with Instruments:**
- [ ] Time Profiler: No functions > 5% CPU
- [ ] Allocations: No memory growth during gameplay
- [ ] System Trace: Main thread not blocked

---

## Phase 2.5: Modernize to SwiftUI App Lifecycle
**Goal**: Replace AppDelegate/SceneDelegate with modern SwiftUI App/Scene pattern
**Priority**: HIGH - Simplifies Phase 3 significantly, modern best practice
**Dependencies**: Phase 1 complete, Phase 2 recommended
**Platforms**: macOS 11+, iOS 14+ (both supported)

### Why This Matters

**Current Problem:**
- Using legacy `@NSApplicationMain` (macOS) and `@UIApplicationMain` (iOS)
- AppDelegate is 645 lines (macOS) / 318 lines (iOS) - god objects
- Mixing UIKit/AppKit lifecycle with SwiftUI views
- Not leveraging SwiftUI's declarative scene management

**Benefits:**
- Eliminates most AppDelegate code (~70% reduction)
- Forces proper separation of concerns
- Cross-platform by default
- Better SwiftUI integration
- Modern, declarative approach
- Makes Phase 3.2 much smaller (or unnecessary)

### 2.5.1 Create SwiftUI App Structure (macOS)

#### New File: NetrekMacOS/NetrekApp.swift
- [ ] **Create**: NetrekMacOS/NetrekApp.swift
```swift
import SwiftUI

@main
struct NetrekApp: App {
    // State management
    @StateObject private var universe = Universe.shared
    @StateObject private var gameStateManager = GameStateManager()
    @StateObject private var connectionManager: ServerConnectionManager
    @StateObject private var timerManager = GameTimerManager()

    // Legacy support (minimal)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Initialize dependencies
        let connManager = ServerConnectionManager()
        _connectionManager = StateObject(wrappedValue: connManager)

        // Force dark mode
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }

    var body: some Scene {
        WindowGroup {
            EverythingView()
                .environmentObject(universe)
                .environmentObject(gameStateManager)
                .environmentObject(connectionManager)
                .environmentObject(timerManager)
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            NetrekCommands()
        }

        #if DEBUG
        Settings {
            PreferencesView()
        }
        #endif
    }
}
```

#### New File: NetrekMacOS/NetrekCommands.swift
- [ ] **Create**: NetrekMacOS/NetrekCommands.swift
  - [ ] Move menu structure from AppDelegate
  - [ ] Use CommandMenu and CommandGroup
  - [ ] Example:
```swift
struct NetrekCommands: Commands {
    @FocusedBinding(\.gameState) var gameState

    var body: some Commands {
        // Server menu
        CommandMenu("Server") {
            Button("Disconnect") {
                gameState = .noServerSelected
            }
            .disabled(gameState == .noServerSelected)

            Divider()
            // Server list populated dynamically
        }

        // Team selection menu
        CommandMenu("Team") {
            TeamSelectionCommands()
        }
        .disabled(gameState != .serverSlotFound)

        // Ship selection menu
        CommandMenu("Ship") {
            ShipSelectionCommands()
        }
        .disabled(gameState != .loginAccepted)
    }
}
```

#### Migrate AppDelegate (macOS)
- [ ] **File**: NetrekMacOS/Global Group/AppDelegate.swift
  - [ ] Remove `@NSApplicationMain` (now in NetrekApp.swift)
  - [ ] Keep ONLY what can't be done in SwiftUI:
    - [ ] Low-level NSApplication delegate methods (if any)
    - [ ] Legacy API support (if any)
  - [ ] Move to managers:
    - [ ] Timer → GameTimerManager (Phase 3.2 or create now)
    - [ ] Network → ServerConnectionManager (Phase 3.2 or create now)
    - [ ] Game state → GameStateManager (Phase 3.2 or create now)
    - [ ] Window management → Built-in WindowGroup
    - [ ] Menu management → NetrekCommands
  - [ ] Result: AppDelegate < 50 lines or eliminated entirely

---

### 2.5.2 Create SwiftUI App Structure (iPadOS)

#### New File: NetrekIPad/NetrekApp.swift
- [ ] **Create**: NetrekIPad/NetrekApp.swift
```swift
import SwiftUI

@main
struct NetrekApp: App {
    // State management (same as macOS)
    @StateObject private var universe = Universe.shared
    @StateObject private var gameStateManager = GameStateManager()
    @StateObject private var connectionManager: ServerConnectionManager
    @StateObject private var timerManager = GameTimerManager()

    // Legacy support if needed (minimal or none)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        let connManager = ServerConnectionManager()
        _connectionManager = StateObject(wrappedValue: connManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(universe)
                .environmentObject(gameStateManager)
                .environmentObject(connectionManager)
                .environmentObject(timerManager)
        }
    }
}
```

#### Migrate AppDelegate (iPadOS)
- [ ] **File**: NetrekIPad/Global Group/AppDelegate.swift
  - [ ] Remove `@UIApplicationMain`
  - [ ] Keep ONLY legacy API support (if any)
  - [ ] Move timer, network, game state to managers
  - [ ] Result: AppDelegate < 30 lines or eliminated

#### Migrate or Eliminate SceneDelegate
- [ ] **File**: NetrekIPad/Global Group/SceneDelegate.swift
  - [ ] **Option A**: Eliminate entirely (SwiftUI handles scenes)
  - [ ] **Option B**: Keep minimal for custom scene configuration
  - [ ] WindowGroup in App handles scene lifecycle automatically
  - [ ] Recommendation: **Eliminate** unless specific scene customization needed

---

### 2.5.3 Create Essential Managers (if not done in Phase 3)

Since this phase eliminates AppDelegate, we need somewhere for the logic to go. Create lightweight managers now if Phase 3.2 hasn't been done:

#### GameStateManager (if doesn't exist)
- [ ] **New File**: Shared/Managers/GameStateManager.swift
```swift
import Foundation
import Combine

class GameStateManager: ObservableObject {
    @Published private(set) var gameState: GameState = .noServerSelected

    func transition(to newState: GameState) {
        // Validate transition is legal
        guard isValidTransition(from: gameState, to: newState) else {
            print("Invalid state transition: \(gameState) → \(newState)")
            return
        }
        gameState = newState
    }

    private func isValidTransition(from: GameState, to: GameState) -> Bool {
        // Define valid state machine transitions
        switch (from, to) {
        case (.noServerSelected, .serverSelected): return true
        case (.serverSelected, .serverConnected): return true
        case (.serverConnected, .serverSlotFound): return true
        case (.serverSlotFound, .loginAccepted): return true
        case (.loginAccepted, .gameActive): return true
        case (_, .noServerSelected): return true  // Can always disconnect
        default: return false
        }
    }
}
```

#### ServerConnectionManager (if doesn't exist)
- [ ] **New File**: Shared/Managers/ServerConnectionManager.swift
```swift
import Foundation
import Network

class ServerConnectionManager: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var currentServer: String?

    private var reader: TcpReader?
    private var analyzer: PacketAnalyzer?

    weak var gameStateManager: GameStateManager?

    func connect(to hostname: String, port: Int) {
        // TcpReader connection logic (moved from AppDelegate)
        reader = TcpReader(hostname: hostname, port: port, delegate: self)
        analyzer = PacketAnalyzer(appDelegate: self)  // Will fix in Phase 3
        reader?.connect()
    }

    func disconnect() {
        reader?.disconnect()
        reader = nil
        analyzer = nil
        isConnected = false
        currentServer = nil
    }
}
```

#### GameTimerManager (if doesn't exist)
- [ ] **New File**: Shared/Managers/GameTimerManager.swift
```swift
import Foundation
import Combine

class GameTimerManager: ObservableObject {
    @Published private(set) var tickCount: Int = 0

    private var timer: Timer?
    private let updateRate: Double = 20.0  // Hz

    private var universe = Universe.shared

    func start() {
        let interval = 1.0 / updateRate
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.timerFired()
        }
        timer?.tolerance = interval / 10.0
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func timerFired() {
        tickCount += 1
        universe.serverUpdate.increment()
    }
}
```

---

### 2.5.4 Update Views to Use Environment Objects

#### Remove Direct Singleton Access
- [ ] **Pattern**: Replace throughout app
```swift
// ❌ Before:
var universe = Universe.universe
let appDelegate = NSApplication.shared.delegate as! AppDelegate

// ✅ After:
@EnvironmentObject var universe: Universe
@EnvironmentObject var gameStateManager: GameStateManager
```

#### Update Key Views
- [ ] **File**: NetrekMacOS/Views/EverythingView.swift
  - [ ] Add `@EnvironmentObject var gameStateManager: GameStateManager`
  - [ ] Remove direct AppDelegate access
  - [ ] Pass environment objects to child views

- [ ] **File**: Shared/Views/TacticalView.swift
  - [ ] Add `@EnvironmentObject var universe: Universe`
  - [ ] Add `@EnvironmentObject var connectionManager: ServerConnectionManager`
  - [ ] Remove `Universe.universe` direct access
  - [ ] Remove `appDelegate` references

- [ ] Repeat for all major views

---

### 2.5.5 Handle Cross-Platform Differences

#### Platform-Specific Scenes
```swift
// macOS: Multiple window support
var body: some Scene {
    WindowGroup("Main Game") {
        EverythingView()
    }

    WindowGroup("Preferences") {
        PreferencesView()
    }
    .defaultSize(width: 600, height: 400)
}

// iOS: Single window, multiple views
var body: some Scene {
    WindowGroup {
        ContentView()  // Handles navigation internally
    }
}
```

#### Platform Adapters (from Phase 3.4, might need now)
- [ ] Create protocol for platform-specific features
```swift
protocol PlatformAdapter {
    func configureAppearance()
    func handleMemoryWarning()
}

class MacOSAdapter: PlatformAdapter {
    func configureAppearance() {
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }
    func handleMemoryWarning() { /* macOS handles automatically */ }
}

class IOSAdapter: PlatformAdapter {
    func configureAppearance() {
        // iOS appearance configuration
    }
    func handleMemoryWarning() {
        // Clear caches, etc.
    }
}
```

---

### 2.5.6 Migrate ViewModelFactory

#### Update Factory to Use Managers
- [ ] **File**: Shared/ViewModels/ViewModelFactory.swift
```swift
class ViewModelFactory {
    static let shared = ViewModelFactory()

    // NEW: Use managers instead of AppDelegate
    private var commandExecutor: GameCommandExecuting?
    private var networkSender: NetworkSending?
    private var gameStateManager: GameStateManager?  // Changed from GameStateProviding

    func configure(
        commandExecutor: GameCommandExecuting,
        networkSender: NetworkSending,
        gameStateManager: GameStateManager  // Updated
    ) {
        self.commandExecutor = commandExecutor
        self.networkSender = networkSender
        self.gameStateManager = gameStateManager
    }

    // ... rest of factory methods
}
```

#### Configure in App Init
- [ ] **File**: NetrekMacOS/NetrekApp.swift
```swift
init() {
    // ... other init code

    // Configure factory after managers created
    let keymapController = KeymapController()
    ViewModelFactory.shared.configure(
        commandExecutor: keymapController,
        networkSender: connectionManager,
        gameStateManager: gameStateManager
    )
}
```

---

### 2.5.7 Legacy APIs and Adapters

#### What Still Needs AppDelegate?

**macOS:**
- [ ] Audit: Check if any NSApplicationDelegate methods are actually used
- [ ] Common needs:
  - `applicationShouldTerminateAfterLastWindowClosed` → Can be in minimal AppDelegate
  - Custom URL schemes → Can be in minimal AppDelegate
  - Menu validation → Moved to Commands

**iOS:**
- [ ] Audit: Check if any UIApplicationDelegate methods are actually used
- [ ] Common needs:
  - Remote notifications → Keep in minimal AppDelegate if used
  - Background modes → Keep in minimal AppDelegate if used
  - Custom URL schemes → Can handle in App struct

#### Minimal AppDelegate Pattern
```swift
// If still needed, keep this minimal:
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    // Only other truly necessary legacy methods
}

// In App struct:
@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
```

---

### 2.5.8 Testing Migration

#### Manual Testing Checklist
- [ ] App launches successfully on macOS
- [ ] App launches successfully on iPadOS
- [ ] Main window appears and is functional
- [ ] Menu commands work (macOS)
- [ ] Game state transitions work
- [ ] Network connection works
- [ ] Timer fires at 20Hz
- [ ] All existing functionality preserved

#### Unit Tests
- [ ] Update tests that mock AppDelegate
- [ ] Create tests for GameStateManager
- [ ] Create tests for ServerConnectionManager
- [ ] Create tests for GameTimerManager
- [ ] Verify ViewModelFactory still works

---

### 2.5.9 Migration Strategy

#### Incremental Approach (Recommended)

**Step 1: macOS First (Lower Risk)**
- [ ] Create NetrekApp.swift for macOS
- [ ] Keep existing AppDelegate initially
- [ ] Use `@NSApplicationDelegateAdaptor`
- [ ] Verify app still works
- [ ] Gradually move logic from AppDelegate to managers
- [ ] Test after each move

**Step 2: Create Managers**
- [ ] Extract GameStateManager from AppDelegate
- [ ] Extract ServerConnectionManager
- [ ] Extract GameTimerManager
- [ ] Test each extraction

**Step 3: Wire Up Environment**
- [ ] Make managers @StateObject in App
- [ ] Inject as @EnvironmentObject to views
- [ ] Remove direct singleton access gradually
- [ ] Test after each view updated

**Step 4: Reduce AppDelegate**
- [ ] Move all movable logic to managers
- [ ] Delete AppDelegate properties one by one
- [ ] Verify tests pass
- [ ] Final AppDelegate should be < 50 lines

**Step 5: iOS Migration**
- [ ] Repeat steps 1-4 for iPadOS
- [ ] Share the managers (already cross-platform)
- [ ] Eliminate SceneDelegate if possible

#### Big Bang Approach (Higher Risk, Faster)
- [ ] Create all new files at once
- [ ] Update project to use @main in App.swift
- [ ] Remove @NSApplicationMain/@UIApplicationMain
- [ ] Fix all compilation errors
- [ ] Test extensively

**Recommendation**: Use **incremental approach** - safer and easier to debug

---

### 2.5.10 Phase 2.5 Validation Checklist

**Before proceeding to Phase 3:**

**Architecture:**
- [ ] No `@NSApplicationMain` or `@UIApplicationMain` (replaced with `@main`)
- [ ] App.swift exists for both platforms
- [ ] AppDelegate < 50 lines or eliminated
- [ ] SceneDelegate eliminated (iOS)
- [ ] Core managers created (GameState, Connection, Timer)

**Functionality:**
- [ ] App launches on both platforms
- [ ] All windows/scenes appear correctly
- [ ] Menus work (macOS)
- [ ] Game state machine functions
- [ ] Network connection works
- [ ] Timer runs at 20Hz
- [ ] All game features work identically

**Code Quality:**
- [ ] No direct Universe.universe in views (use @EnvironmentObject)
- [ ] No direct AppDelegate access in shared code
- [ ] Environment objects properly injected
- [ ] ViewModelFactory configured correctly

**Testing:**
- [ ] All existing tests pass
- [ ] New manager tests created
- [ ] Manual gameplay session (15+ minutes) successful
- [ ] Both platforms tested

**Benefits Realized:**
- [ ] Codebase more modern and maintainable
- [ ] Easier to test (managers injectable)
- [ ] Phase 3.2 significantly reduced in scope
- [ ] Cross-platform consistency improved

---

## Phase 3: Architecture Refactoring
**Goal**: Clean architecture, testability, maintainability
**Priority**: MEDIUM - Improves long-term maintainability
**Dependencies**: Phase 1 complete, Phase 2.5 HIGHLY recommended (eliminates much of 3.2)

**NOTE**: If Phase 2.5 completed, Phase 3.2 is significantly reduced or can be skipped.

### 3.1 Complete MVVM Migration

#### Remove Direct Universe Access from Views
- [ ] **Audit**: `grep -r "Universe.universe" --include="*.swift" Shared/Views/`
- [ ] Found in: TacticalView.swift:20, others

- [ ] **Pattern**: Views should only access ViewModels
```swift
// ❌ Remove this:
var universe = Universe.universe

// ✅ Replace with this:
@StateObject var viewModel: TacticalViewModel

// ViewModel injected via:
TacticalView(viewModel: ViewModelFactory.makeTactical())
```

- [ ] Update all views in:
  - [ ] Shared/Views/TacticalView.swift
  - [ ] Shared/Views/StrategicView.swift
  - [ ] Shared/Views/PlayerView.swift
  - [ ] Shared/Views/PlanetView.swift
  - [ ] Other view files with Universe access

#### Remove Direct AppDelegate Access
- [ ] **Pattern**: Use environment or dependency injection
```swift
// ❌ Remove this:
#if os(macOS)
lazy var appDelegate = NSApplication.shared.delegate as! AppDelegate
#endif

// ✅ Replace with protocol:
protocol GameStateProviding {
    var gameState: GameState { get }
    func selectTeam(_ team: Team)
    // ... only needed methods
}

// Inject via:
@EnvironmentObject var gameState: GameStateProvider
```

- [ ] Update 9 files with appDelegate:
  - [ ] Shared/Model/Player.swift
  - [ ] Shared/Model/Planet.swift
  - [ ] Shared/Model/Laser.swift, Plasma.swift, Torpedo.swift
  - [ ] Shared/Model/Explosion.swift, Phaser.swift

#### Create Missing ViewModels
- [ ] StrategicViewModel (for strategic map view)
- [ ] PlayerListViewModel (for player list)
- [ ] PlanetListViewModel (for planet status)
- [ ] MessageViewModel (for message board)
- [ ] ServerSelectionViewModel (for server browser)

#### Validation
- [ ] Zero direct Universe.universe calls in Shared/Views/
- [ ] Zero lazy appDelegate variables
- [ ] All views have corresponding ViewModels
- [ ] All ViewModels testable in isolation

---

### 3.2 Break Up God Objects

#### AppDelegate Refactoring (645 lines → ~200 lines)

**Extract: GameStateManager**
- [ ] **New File**: Shared/Managers/GameStateManager.swift
- [ ] Responsibilities:
  - GameState enum transitions
  - State validation (can only go A→B, not A→C)
  - State change notifications
- [ ] Move from AppDelegate:
  - [ ] `gameState` property
  - [ ] `updateGameState()` method
  - [ ] State transition logic

**Extract: ServerConnectionManager**
- [ ] **New File**: Shared/Managers/ServerConnectionManager.swift
- [ ] Responsibilities:
  - Server selection
  - Connection lifecycle
  - Reconnection logic
  - TcpReader management
  - PacketAnalyzer management
- [ ] Move from AppDelegate:
  - [ ] `tcpReader` property
  - [ ] `analyzer` property
  - [ ] `connectToServer()` methods (lines 278-323)
  - [ ] Connection state handling

**Extract: GameTimerManager**
- [ ] **New File**: Shared/Managers/GameTimerManager.swift
- [ ] Responsibilities:
  - 20Hz game loop timer
  - Timer start/stop
  - Update rate configuration
  - Frame timing
- [ ] Move from AppDelegate:
  - [ ] `timer` property
  - [ ] `UPDATE_RATE` constant
  - [ ] `setupTimer()` method (lines 498-525)
  - [ ] Timer callback logic

**Extract: WindowManager (macOS only)**
- [ ] **New File**: NetrekMacOS/Managers/WindowManager.swift
- [ ] Responsibilities:
  - Window creation/configuration
  - Window visibility state
  - Window position/size
  - Multi-window management
- [ ] Move from AppDelegate:
  - [ ] `mainWindow` property
  - [ ] `applicationDidFinishLaunching()` window setup (lines 67-120)
  - [ ] Window configuration methods

**Extract: MenuManager (macOS only)**
- [ ] **New File**: NetrekMacOS/Managers/MenuManager.swift
- [ ] Responsibilities:
  - Menu state updates
  - Menu item enable/disable
  - Menu selection handling
- [ ] Move from AppDelegate:
  - [ ] Menu outlets (lines 30-40)
  - [ ] `updateMenus()` method
  - [ ] Menu action methods

**Refactored AppDelegate Structure**
```swift
// Should look like this when done:
class AppDelegate: NSObject, NSApplicationDelegate {
    // Dependencies
    private let gameStateManager = GameStateManager()
    private let connectionManager: ServerConnectionManager
    private let timerManager = GameTimerManager()
    private let windowManager = WindowManager()
    private let menuManager = MenuManager()

    // Delegation
    func applicationDidFinishLaunching() {
        windowManager.createMainWindow()
        timerManager.start(delegate: self)
        menuManager.setup()
    }

    // ~50 lines total
}
```

#### Validation
- [ ] AppDelegate < 200 lines
- [ ] Each manager has single responsibility
- [ ] Managers are independently testable
- [ ] All functionality preserved

---

#### KeymapController Refactoring (571 lines → ~100 lines)

**Extract: Command Pattern**
- [ ] **New File**: Shared/Commands/GameCommand.swift
```swift
protocol GameCommand {
    func execute(universe: Universe, gameState: GameStateProviding)
}
```

- [ ] **New Directory**: Shared/Commands/
  - [ ] ThrustCommand.swift
  - [ ] TurnCommand.swift
  - [ ] FireTorpedoCommand.swift
  - [ ] FirePhaserCommand.swift
  - [ ] ShieldCommand.swift
  - [ ] CloakCommand.swift
  - [ ] LockCommand.swift
  - [ ] ... one file per command type

- [ ] **Example Implementation**:
```swift
struct FireTorpedoCommand: GameCommand {
    let direction: Int

    func execute(universe: Universe, gameState: GameStateProviding) {
        guard gameState.canFireTorpedo else { return }
        let me = universe.players[universe.me]
        let packet = MakePacket.fireTorpedo(direction: direction)
        gameState.send(packet)
    }
}
```

**Refactored KeymapController**
- [ ] **File**: NetrekMacOS/Controllers/KeymapController.swift
  - [ ] Replace giant switch with command mapping:
```swift
class KeymapController {
    private let commands: [String: GameCommand] = [
        "0": FireTorpedoCommand(direction: 0),
        "1": FireTorpedoCommand(direction: 1),
        // ...
        "k": ThrustCommand(change: .increase),
        // ...
    ]

    func handle(key: String, universe: Universe, gameState: GameStateProviding) {
        commands[key]?.execute(universe: universe, gameState: gameState)
    }
}
```

- [ ] Lines 149-end: Delete entire switch statement
- [ ] Result: ~100 lines total

#### Validation
- [ ] KeymapController < 150 lines
- [ ] Each command independently testable
- [ ] Easy to add new commands
- [ ] All keyboard commands work identically

---

#### PacketAnalyzer Refactoring (551 lines → ~150 lines)

**Extract: PacketHandler Protocol**
- [ ] **New File**: Shared/Communication/PacketHandlers/PacketHandler.swift
```swift
protocol PacketHandler {
    var packetType: UInt8 { get }
    var packetSize: Int { get }
    func handle(data: Data, universe: Universe, appDelegate: AppDelegate)
}
```

- [ ] **New Directory**: Shared/Communication/PacketHandlers/
  - [ ] PlayerPacketHandler.swift (SP_PLAYER)
  - [ ] PlayerInfoPacketHandler.swift (SP_PLAYER_INFO)
  - [ ] YouPacketHandler.swift (SP_YOU)
  - [ ] StatusPacketHandler.swift (SP_STATUS)
  - [ ] PlanetPacketHandler.swift (SP_PLANET)
  - [ ] TorpedoPacketHandler.swift (SP_TORP)
  - [ ] ... one file per packet type (~40 handlers)

- [ ] **Example Implementation**:
```swift
class PlayerPacketHandler: PacketHandler {
    let packetType: UInt8 = 1  // SP_PLAYER
    let packetSize: Int = 32

    func handle(data: Data, universe: Universe, appDelegate: AppDelegate) {
        guard data.count >= packetSize else { return }

        let playerID = Int(data[1])
        let positionX = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: Int32.self) }
        let positionY = data.withUnsafeBytes { $0.load(fromByteOffset: 8, as: Int32.self) }

        DispatchQueue.main.async {
            if let player = universe.players[safe: playerID] {
                player.updatePosition(x: Int(positionX), y: Int(positionY))
            }
        }
    }
}
```

**Refactored PacketAnalyzer**
- [ ] **File**: Shared/Communication/PacketAnalyzer.swift
  - [ ] Replace 450-line switch with handler lookup:
```swift
class PacketAnalyzer {
    private var handlers: [UInt8: PacketHandler] = [:]

    init() {
        registerHandlers()
    }

    private func registerHandlers() {
        let allHandlers: [PacketHandler] = [
            PlayerPacketHandler(),
            PlanetPacketHandler(),
            // ... register all
        ]
        for handler in allHandlers {
            handlers[handler.packetType] = handler
        }
    }

    func analyzeOnePacket(data: Data) {
        guard let packetType = data.first else { return }
        handlers[packetType]?.handle(data: data, universe: universe, appDelegate: appDelegate)
    }
}
```

- [ ] Lines 100-551: Delete giant switch statement
- [ ] Result: ~150 lines total

#### Validation
- [ ] PacketAnalyzer < 200 lines
- [ ] Each packet handler independently testable
- [ ] Easy to add new packet types
- [ ] All packets processed identically

---

### 3.3 Dependency Injection Throughout

#### Environment Objects for Views
- [ ] **File**: NetrekMacOS/Global Group/AppDelegate.swift
```swift
ContentView()
    .environmentObject(gameStateManager)
    .environmentObject(universe)  // or EnvironmentViewModel
```

- [ ] Update all views to receive via @EnvironmentObject
- [ ] Remove direct singleton access

#### Protocol-Based Dependencies
- [ ] Replace concrete types with protocols in init/properties:
```swift
// ❌ Before:
class PlayerView {
    let player: Player
}

// ✅ After:
class PlayerView {
    let player: PlayerProviding
}
```

- [ ] Use protocols for:
  - [ ] PlayerProviding, PlanetProviding (already exist!)
  - [ ] NetworkSending (already exists!)
  - [ ] GameCommandExecuting (already exists!)
  - [ ] GameStateProviding (need to create)
  - [ ] TimerProviding (need to create)

#### Validation
- [ ] No class directly instantiates another (use factories/injection)
- [ ] All dependencies mockable for testing
- [ ] Dependency graph is acyclic

---

### 3.4 Platform Code Deduplication

#### Extract Shared Game Logic
- [ ] **New File**: Shared/Managers/GameLoopManager.swift
  - [ ] Timer callback logic (identical between platforms)
  - [ ] Game state updates
  - [ ] Server update increment

- [ ] **Current Duplication**:
  - macOS AppDelegate lines 498-550
  - iPadOS AppDelegate lines 180-220
  - ~95% identical

#### Extract Shared Connection Logic
- [ ] **Already done via ServerConnectionManager in 3.2**
- [ ] Both platforms use same manager

#### Platform-Specific Adapters
- [ ] **File**: NetrekMacOS/Platform/MacOSPlatformAdapter.swift
```swift
protocol PlatformAdapter {
    func showWindow()
    func hideWindow()
    func updateMenus()
    // Platform-specific only
}

class MacOSPlatformAdapter: PlatformAdapter {
    // NSWindow management
}
```

- [ ] **File**: NetrekIPad/Platform/IOSPlatformAdapter.swift
```swift
class IOSPlatformAdapter: PlatformAdapter {
    // UIWindow/scene management
}
```

#### Result
- [ ] AppDelegate files reduce from 60% duplication to <10%
- [ ] macOS-specific: Menu management, NSWindow, keyboard
- [ ] iOS-specific: Scene management, UIWindow, touch gestures
- [ ] Everything else: Shared

#### Validation
- [ ] Both platforms build and run
- [ ] Shared code has zero platform-specific ifdefs
- [ ] Platform-specific code only in NetrekMacOS/ and NetrekIPad/

---

### 3.5 Phase 3 Validation Checklist

**Architecture Quality:**
- [ ] No files > 400 lines
- [ ] Each class/file has single responsibility
- [ ] Dependency graph documented and acyclic
- [ ] Zero global state access (except via DI)

**Testability:**
- [ ] All managers unit testable
- [ ] All ViewModels unit testable
- [ ] All commands unit testable
- [ ] All packet handlers unit testable

**Code Organization:**
- [ ] Shared/ has zero platform-specific code
- [ ] NetrekMacOS/ has only macOS-specific code
- [ ] NetrekIPad/ has only iOS-specific code
- [ ] Platform adapters clean and minimal

---

## Phase 4: Test Coverage
**Goal**: Comprehensive test coverage for critical components
**Priority**: MEDIUM - Can run parallel with Phase 3
**Dependencies**: Phase 1 complete, Phases 2.5 & 3 make testing easier

### 4.1 Network Layer Tests

#### TcpReader Tests
- [ ] **New File**: NetrekTests/Communication/TcpReaderTests.swift
  - [ ] Test successful connection
  - [ ] Test connection failure
  - [ ] Test connection timeout
  - [ ] Test receive loop continuation
  - [ ] Test disconnect handling
  - [ ] Test error propagation
  - [ ] Test delegate callbacks

#### PacketAnalyzer Tests
- [ ] **New File**: NetrekTests/Communication/PacketAnalyzerTests.swift
  - [ ] Test each packet type with valid data
  - [ ] Test malformed packets (too short, wrong size)
  - [ ] Test packet boundary handling
  - [ ] Test leftover data accumulation
  - [ ] Test empty data handling
  - [ ] Use mock data fixtures for all packet types

- [ ] **New Directory**: NetrekTests/Fixtures/PacketData/
  - [ ] player_packet.data
  - [ ] planet_packet.data
  - [ ] torpedo_packet.data
  - [ ] ... fixtures for all 40 packet types

#### PacketHandler Tests (After Phase 3.2)
- [ ] **New File**: NetrekTests/PacketHandlers/PlayerPacketHandlerTests.swift
  - [ ] One test file per handler
  - [ ] Test with MockUniverse
  - [ ] Verify correct property updates
  - [ ] Test boundary conditions

**Target**: 80% coverage of Communication layer

---

### 4.2 Model Tests

#### Player Tests
- [ ] **New File**: NetrekTests/Model/PlayerTests.swift
  - [ ] Test updateMe() with various flag combinations
  - [ ] Test position updates
  - [ ] Test throttle changes
  - [ ] Test shield state
  - [ ] Test image selection logic

#### Planet Tests
- [ ] **New File**: NetrekTests/Model/PlanetTests.swift
  - [ ] Test ownership changes
  - [ ] Test army updates
  - [ ] Test repair status

#### Universe Tests
- [ ] **New File**: NetrekTests/Model/UniverseTests.swift
  - [ ] Test player management (add/remove)
  - [ ] Test visibility calculations
  - [ ] Test message handling
  - [ ] Use MockPlayer, MockPlanet

**Target**: 70% coverage of Model layer

---

### 4.3 ViewModel Tests

#### TacticalViewModel Tests
- [ ] **New File**: NetrekTests/ViewModels/TacticalViewModelTests.swift
  - [ ] Test visible player filtering
  - [ ] Test position transformations
  - [ ] Test update cycle
  - [ ] Use mock dependencies

#### ServerSelectionViewModel Tests (if exists)
- [ ] Test server list fetching
- [ ] Test server selection
- [ ] Test connection initiation

#### Command Tests (After Phase 3.2)
- [ ] **New File**: NetrekTests/Commands/FireTorpedoCommandTests.swift
  - [ ] One test file per command
  - [ ] Test execution with mock universe
  - [ ] Test preconditions (can't fire when dead)
  - [ ] Test network packet generation

**Target**: 90% coverage of ViewModels (easiest to test)

---

### 4.4 Manager Tests (After Phase 3)

#### GameStateManager Tests
- [ ] **New File**: NetrekTests/Managers/GameStateManagerTests.swift
  - [ ] Test all valid state transitions
  - [ ] Test invalid transitions are rejected
  - [ ] Test state change notifications

#### ServerConnectionManager Tests
- [ ] Test connection lifecycle
- [ ] Test reconnection logic
- [ ] Test error handling
- [ ] Use mock TcpReader

#### GameTimerManager Tests
- [ ] Test timer start/stop
- [ ] Test update rate
- [ ] Test callback firing

**Target**: 85% coverage of Managers

---

### 4.5 Integration Tests

- [ ] **New File**: NetrekTests/Integration/ConnectionFlowTests.swift
  - [ ] Test full connection sequence:
    1. Meta-server query
    2. Server selection
    3. Server connection
    4. Player slot assignment
    5. Team selection
    6. Game start
  - [ ] Use mock network responses

- [ ] **New File**: NetrekTests/Integration/GameplayTests.swift
  - [ ] Test player movement
  - [ ] Test firing weapons
  - [ ] Test taking damage
  - [ ] Test death/respawn

---

### 4.6 Phase 4 Validation Checklist

**Coverage Targets:**
- [ ] Overall: > 60% code coverage
- [ ] Communication layer: > 80%
- [ ] ViewModels: > 90%
- [ ] Managers: > 85%
- [ ] Models: > 70%

**Quality:**
- [ ] All tests pass consistently
- [ ] No flaky tests
- [ ] Fast test execution (< 30 seconds for full suite)
- [ ] Tests run in CI/automated

**Documentation:**
- [ ] README includes test execution instructions
- [ ] Complex test scenarios documented

---

## Phase 5: Code Quality & Polish
**Goal**: Clean, maintainable, well-documented code
**Priority**: LOW - Nice to have
**Dependencies**: Phases 1-3 complete (Phase 2.5 recommended)

### 5.1 Replace Magic Numbers

#### Create Constants File
- [ ] **New File**: Shared/Constants/GameConstants.swift
```swift
enum GameConstants {
    // Map
    static let visualWidth: CGFloat = 3000 // Tactical view width in game units
    static let galaxyWidth: Int = 100000 // Full galaxy width
    static let galaxyHeight: Int = 100000 // Full galaxy height

    // Players
    static let maxPlayers: Int = 32
    static let maxTeams: Int = 4

    // Weapons
    static let maxTorpedoes: Int = 256 // 32 players × 8 torps
    static let maxPhasers: Int = 32
    static let torpedoSpeed: Int = 12
    static let torpedoFuse: Int = 40 // ticks until explosion

    // Timing
    static let updateRate: Int = 20 // Hz
    static let updateInterval: TimeInterval = 1.0 / 20.0

    // Network
    static let defaultServerPort: Int = 2592
    static let metaServerPort: Int = 3521
    static let packetBufferSize: Int = 16384
    static let connectionTimeout: TimeInterval = 10.0
}
```

- [ ] **New File**: Shared/Constants/PacketConstants.swift
```swift
enum PacketType: UInt8 {
    case player = 1  // SP_PLAYER
    case playerInfo = 2  // SP_PLAYER_INFO
    case you = 3  // SP_YOU
    // ... all packet types
}

enum PacketSize {
    static let player = 32
    static let playerInfo = 64
    // ... all packet sizes
}

enum PacketOffsets {
    enum Player {
        static let id = 1
        static let positionX = 4
        static let positionY = 8
        // ...
    }
}
```

#### Replace Throughout Codebase
- [ ] Search and replace all magic numbers
- [ ] Add documentation comments explaining why each value
- [ ] Group related constants together

---

### 5.2 Implement Proper Logging

#### Replace debugPrint
- [ ] **New File**: Shared/Utilities/Logger.swift
```swift
import OSLog

enum LogCategory: String {
    case network
    case gameState
    case packets
    case ui
    case performance
}

class GameLogger {
    static func log(_ message: String, category: LogCategory, level: OSLogType = .info) {
        let log = OSLog(subsystem: "com.netrek", category: category.rawValue)
        os_log("%{public}@", log: log, type: level, message)
    }

    static func error(_ message: String, category: LogCategory) {
        log(message, category: category, level: .error)
    }

    static func debug(_ message: String, category: LogCategory) {
        #if DEBUG
        log(message, category: category, level: .debug)
        #endif
    }
}
```

- [ ] Replace all 100+ debugPrint calls:
```swift
// ❌ Before:
debugPrint("Connected to server at \(hostname):\(port)")

// ✅ After:
GameLogger.log("Connected to server at \(hostname):\(port)", category: .network)
```

- [ ] Add log levels: debug, info, warning, error
- [ ] Only debug logs in DEBUG builds
- [ ] User-facing errors go to UI, not just logs

---

### 5.3 Documentation

#### Add HeaderDoc Comments
- [ ] **Pattern**:
```swift
/// Manages TCP connection to Netrek game servers.
///
/// Handles connection lifecycle, sending/receiving data, and error recovery.
/// All network operations run on a background queue to avoid blocking the main thread.
class TcpReader {

    /// Establishes a connection to the specified server.
    ///
    /// - Parameters:
    ///   - hostname: The server hostname or IP address
    ///   - port: The server port (typically 2592)
    /// - Returns: True if connection initiated successfully, false otherwise
    func connect(hostname: String, port: Int) -> Bool {
        // ...
    }
}
```

- [ ] Document all public classes and methods
- [ ] Document complex algorithms:
  - [ ] Coordinate transformations (NetrekMath)
  - [ ] Packet parsing logic
  - [ ] Game state machine transitions

#### Create Architecture Documentation
- [ ] **New File**: ARCHITECTURE.md
  - [ ] System overview diagram
  - [ ] Component descriptions
  - [ ] Data flow diagrams
  - [ ] Threading model
  - [ ] Network protocol summary

#### Update CLAUDE.md
- [ ] Add phase completion status
- [ ] Update architecture section
- [ ] Document new patterns/conventions

---

### 5.4 Clean Up TODOs

- [ ] Audit all TODO comments (5 found in review)
  - [ ] Laser.swift:75 - "hit plasma TODO"
  - [ ] PacketAnalyzer.swift:410 - "TODO need to process this data"
  - [ ] Others in MakePacket, packets.swift

- [ ] For each TODO:
  - [ ] Implement if critical
  - [ ] Create GitHub issue if not urgent
  - [ ] Remove if obsolete
  - [ ] Add ticket reference if keeping: `// TODO(#123): Description`

- [ ] Zero TODO comments without ticket references

---

### 5.5 Remove Dead Code

#### Commented-Out Code
- [ ] Search for large commented blocks
- [ ] Player.swift:173-176, 304-316
- [ ] Remove all commented code
- [ ] If needed for reference, use git history

#### Unused Properties/Methods
- [ ] Use Xcode "Find Call Hierarchy"
- [ ] Identify unused code
- [ ] Remove or mark as deprecated if keeping for future

#### Duplicate Code
- [ ] Use tool to find duplicates (simian, jscpd, etc.)
- [ ] Extract to shared functions
- [ ] Remove redundant implementations

---

### 5.6 Naming Consistency

#### Standardize Variable Names
- [ ] Decide on convention:
  - `me`, `myPlayerID`, or `myPlayerId` - pick one
  - `positionX` or `position_x` - pick one
  - `playerID` or `playerId` - pick one (recommend: `playerID`)

- [ ] Apply consistently across codebase
- [ ] Use Edit → Find → Replace in Scope

#### Method Naming
- [ ] Follow Swift API Design Guidelines
- [ ] Verb phrases for methods: `updatePlayer()`, not `playerUpdate()`
- [ ] Noun phrases for properties: `playerPosition`, not `getPlayerPosition`

---

### 5.7 SwiftLint Integration

- [ ] Add SwiftLint to project
- [ ] **New File**: .swiftlint.yml
```yaml
disabled_rules:
  - trailing_whitespace

opt_in_rules:
  - force_unwrapping  # Warn on !
  - explicit_init
  - closure_spacing

line_length: 120

identifier_name:
  min_length: 2
  max_length: 60

file_length:
  warning: 400
  error: 600
```

- [ ] Fix all SwiftLint warnings
- [ ] Add SwiftLint to build phases
- [ ] Enforce in PR reviews

---

### 5.8 Phase 5 Validation Checklist

**Code Quality:**
- [ ] Zero magic numbers (all in Constants)
- [ ] Zero debugPrint (all use Logger)
- [ ] Zero TODO without ticket reference
- [ ] Zero commented-out code blocks
- [ ] Zero SwiftLint warnings

**Documentation:**
- [ ] All public APIs documented
- [ ] ARCHITECTURE.md complete
- [ ] README updated with new structure
- [ ] Complex algorithms explained

**Consistency:**
- [ ] Naming conventions followed throughout
- [ ] Code style consistent
- [ ] File organization logical

---

## Cross-Cutting Concerns

### Git Strategy
**Branch Organization:**
```
master
├── phase-1-critical-fixes
│   ├── phase-1.1-force-unwraps
│   ├── phase-1.2-thread-safety
│   ├── phase-1.3-tcp-reader-fix
│   └── phase-1.4-error-handling
├── phase-2-performance
│   ├── phase-2.1-canvas-rendering
│   ├── phase-2.2-published-optimization
│   └── phase-2.3-batch-updates
├── phase-2.5-swiftui-modernization
│   ├── phase-2.5.1-create-app-structure
│   ├── phase-2.5.2-create-managers
│   ├── phase-2.5.3-migrate-views
│   └── phase-2.5.4-reduce-appdelegate
└── phase-3-architecture
    ├── phase-3.1-mvvm-completion
    ├── phase-3.2-refactor-god-objects (smaller if 2.5 done)
    └── phase-3.3-dependency-injection
```

**Commit Strategy:**
- Small, focused commits
- Each commit should build and pass tests
- Descriptive commit messages referencing plan sections

**PR Strategy:**
- One PR per phase (or sub-phase for large phases)
- Require review before merge
- Require all tests passing
- Include before/after metrics for performance changes

---

### Testing Strategy Per Phase

**Phase 1:** Manual testing + critical path testing
- Full connection/gameplay cycle after each change
- Thread Sanitizer for 1.2
- Network interruption testing for 1.3-1.4

**Phase 2:** Performance testing + manual testing
- Instruments profiling before/after
- Frame rate monitoring
- CPU/battery usage measurement

**Phase 3:** Unit testing + integration testing
- New unit tests for each extracted component
- Integration tests for manager interactions
- Regression testing for functionality

**Phase 4:** Test-driven
- Write tests first where possible
- Maintain > 80% coverage
- All tests pass before phase complete

**Phase 5:** Quality checks
- SwiftLint passing
- Documentation review
- Code review by another developer if available

---

### Risk Mitigation

**High-Risk Changes:**
1. Thread safety (Phase 1.2) - Could introduce deadlocks
   - **Mitigation**: Test extensively, use Thread Sanitizer

2. Canvas rendering (Phase 2.1) - Could break UI
   - **Mitigation**: Keep old code, A/B switch, parallel implementation

3. AppDelegate refactor (Phase 3.2) - Touches everything
   - **Mitigation**: Extract one manager at a time, test between each

**Rollback Plan:**
- Each phase branch can be abandoned if issues arise
- Master always stable
- Feature flags for new implementations

---

### Success Metrics

**Phase 1:**
- [ ] Zero crashes in 1-hour gameplay session
- [ ] Zero Thread Sanitizer warnings
- [ ] Network errors handled gracefully

**Phase 2:**
- [ ] 50% reduction in CPU usage
- [ ] Consistent 60fps during gameplay
- [ ] 70% reduction in main thread dispatches

**Phase 3:**
- [ ] 50% reduction in file sizes (AppDelegate, KeymapController, PacketAnalyzer)
- [ ] 90% test coverage of new managers
- [ ] Zero direct singleton access from views

**Phase 4:**
- [ ] > 60% overall code coverage
- [ ] > 80% Communication layer coverage
- [ ] All tests passing in < 30 seconds

**Phase 5:**
- [ ] Zero SwiftLint warnings
- [ ] Zero magic numbers
- [ ] All public APIs documented

---

## Appendix: File Organization After Refactoring

```
Netrek2/
├── Shared/
│   ├── Commands/                    # NEW - Phase 3.2
│   │   ├── GameCommand.swift
│   │   ├── FireTorpedoCommand.swift
│   │   ├── ThrustCommand.swift
│   │   └── ... (20+ command files)
│   │
│   ├── Communication/
│   │   ├── TcpReader.swift          # REFACTORED - Phase 1.3
│   │   ├── PacketAnalyzer.swift     # REFACTORED - Phase 3.2 (150 lines)
│   │   ├── MakePacket.swift
│   │   └── PacketHandlers/          # NEW - Phase 3.2
│   │       ├── PacketHandler.swift
│   │       ├── PlayerPacketHandler.swift
│   │       └── ... (40+ handler files)
│   │
│   ├── Constants/                   # NEW - Phase 5.1
│   │   ├── GameConstants.swift
│   │   └── PacketConstants.swift
│   │
│   ├── Managers/                    # NEW - Phase 3.2
│   │   ├── GameStateManager.swift
│   │   ├── ServerConnectionManager.swift
│   │   ├── GameTimerManager.swift
│   │   └── GameLoopManager.swift
│   │
│   ├── Model/
│   │   ├── Universe.swift           # REFACTORED - Phase 1.2 (@MainActor)
│   │   ├── Player.swift             # REFACTORED - Phase 1.1, 3.1
│   │   ├── Planet.swift             # REFACTORED - Phase 1.1, 3.1
│   │   └── ...
│   │
│   ├── Protocols/
│   │   ├── ModelProtocols.swift
│   │   ├── GameCommandProtocols.swift
│   │   ├── GameStateProviding.swift # NEW - Phase 3.1
│   │   └── TimerProviding.swift     # NEW - Phase 3.3
│   │
│   ├── Utilities/
│   │   ├── Logger.swift             # NEW - Phase 5.2
│   │   └── NetrekMath.swift
│   │
│   ├── ViewModels/
│   │   ├── TacticalViewModel.swift
│   │   ├── StrategicViewModel.swift # NEW - Phase 3.1
│   │   ├── PlayerViewModel.swift    # NEW - Phase 2.4
│   │   └── ViewModelFactory.swift   # EXPANDED - Phase 3.1
│   │
│   └── Views/
│       ├── TacticalCanvasView.swift # NEW - Phase 2.1
│       └── ... (refactored to use ViewModels)
│
├── NetrekMacOS/
│   ├── Global Group/
│   │   └── AppDelegate.swift        # REFACTORED - Phase 3.2 (200 lines)
│   │
│   ├── Controllers/
│   │   └── KeymapController.swift   # REFACTORED - Phase 3.2 (100 lines)
│   │
│   ├── Managers/                    # NEW - Phase 3.2
│   │   ├── WindowManager.swift
│   │   └── MenuManager.swift
│   │
│   └── Platform/                    # NEW - Phase 3.4
│       └── MacOSPlatformAdapter.swift
│
├── NetrekIPad/
│   ├── Global Group/
│   │   ├── AppDelegate.swift        # REFACTORED - Phase 3.2, 3.4
│   │   └── SceneDelegate.swift
│   │
│   └── Platform/                    # NEW - Phase 3.4
│       └── IOSPlatformAdapter.swift
│
└── NetrekTests/                     # EXPANDED - Phase 4
    ├── Communication/
    │   ├── TcpReaderTests.swift
    │   ├── PacketAnalyzerTests.swift
    │   └── PacketHandlers/
    │       └── ... (40+ test files)
    │
    ├── Commands/
    │   └── ... (20+ test files)
    │
    ├── Fixtures/
    │   └── PacketData/
    │       └── ... (40+ .data files)
    │
    ├── Integration/
    │   ├── ConnectionFlowTests.swift
    │   └── GameplayTests.swift
    │
    ├── Managers/
    │   ├── GameStateManagerTests.swift
    │   ├── ServerConnectionManagerTests.swift
    │   └── GameTimerManagerTests.swift
    │
    ├── Model/
    │   ├── PlayerTests.swift
    │   ├── PlanetTests.swift
    │   └── UniverseTests.swift
    │
    └── ViewModels/
        ├── TacticalViewModelTests.swift
        └── ... (5+ test files)
```

---

## Implementation Recommendations

### Phase Ordering
1. **Must do sequentially**: Phase 1 → Phase 2 → Phase 2.5 (stable base, then perf, then modernize)
2. **Highly recommended**: Phase 2.5 before Phase 3 (eliminates 70% of Phase 3.2 work)
3. **Can parallelize**: Phase 2 ‖ Phase 3 (if skipping 2.5, different areas)
4. **Can parallelize**: Phase 3 ‖ Phase 4 (tests support refactoring)
5. **Do last**: Phase 5 (polish after structure solid)

**Recommended Path**: 1 → 2 → **2.5** → 3 → 4 → 5 (includes modernization)
**Faster Path**: 1 → 2 → 3 → 5 (skip 2.5, but more Phase 3.2 work needed)

### Team Size Impact
- **Solo developer**: 4-5 months for all phases (including 2.5)
- **2 developers**: One on Phase 1→2→2.5, one on Phase 4→5, converge on Phase 3
- **3+ developers**: Parallel phases with clear ownership

### Minimum Viable Improvements
If limited resources, prioritize:
1. Phase 1.1 - Force unwraps (highest crash risk)
2. Phase 1.2 - Thread safety (data corruption risk)
3. Phase 2.1 - Canvas rendering (user experience)
4. **Phase 2.5 - SwiftUI App lifecycle (modernization, simplifies everything else)**
5. Phase 3.2 - AppDelegate refactor (maintainability) - **MUCH SMALLER if 2.5 done**

### When to Ship
- **After Phase 1**: Ready for broader testing (stable)
- **After Phase 2**: Ready for production (performant)
- **After Phase 2.5**: Ready for modern SwiftUI (clean architecture foundation) ⭐
- **After Phase 3**: Ready for team development (fully maintainable)
- **After Phase 4**: Ready for continuous development (tested)
- **After Phase 5**: Ready for open source (polished)

---

## Notes

- This plan is a living document - adjust based on discoveries during implementation
- Some tasks may reveal they're unnecessary once you start (feel free to skip)
- Some tasks may reveal additional work needed (add sub-tasks)
- Performance numbers are targets - measure and adjust
- Test coverage percentages are goals - focus on critical paths first

**Estimated Total Effort**: 250-350 hours of focused development work (including Phase 2.5)

**Priority**: If forced to choose, complete Phase 1 in full. It's the foundation for everything else. **Phase 2.5 is highly recommended** as it modernizes the architecture and makes Phase 3 much simpler.
