# SwiftUI App Lifecycle Refactor Summary

**Date:** January 2026
**Status:** ✅ Complete

## Overview

Netrek was refactored from the traditional AppDelegate-based app lifecycle to SwiftUI's modern App lifecycle. This refactor addressed critical bugs and improved code maintainability.

## Critical Issues Fixed

### 1. **Game Controls Broken** (CRITICAL)
**Problem:** All keyboard and mouse controls were non-functional because views were accessing `NSApplication.shared.delegate as? AppDelegate`, which returned `nil` (NetrekApp.swift is now the `@main` entry point).

**Solution:**
- Made `KeymapController` an `@MainActor` `ObservableObject`
- Added to environment in `NetrekApp.swift`
- Updated all views to use `@EnvironmentObject var keymapController`
- Views affected: TacticalView, StrategicView, MessagesView, PreferencesView

### 2. **Menu Commands Non-Functional** (HIGH)
**Problem:** Team/Ship selection menus and window management commands did nothing (empty closures with "FUTURE:" comments).

**Solution:**
- Wired `NetrekCommands` to receive `GameStateManager`, `ServerConnectionManager`, and `WindowManager`
- Connected team selection to `gameStateManager.selectTeam()`
- Connected ship selection to `gameStateManager.selectShip()`
- Created `WindowManager` to handle window presentation via SwiftUI sheets

### 3. **Window Management Missing** (HIGH)
**Problem:** Preferences, Login, Statistics windows couldn't be opened from menus.

**Solution:**
- Created `WindowManager` class with `@Published` properties for each window
- Added `.sheet()` modifiers to NetrekApp for each window type
- All windows now open as SwiftUI sheets with proper sizing

## Architecture Changes

### Active Code (SwiftUI App Lifecycle)

**Entry Point:**
- `NetrekApp.swift` - Marked with `@main`, creates WindowGroup

**Managers:**
- `GameStateManager` - Game state machine and state transitions
- `ServerConnectionManager` - Network connections and packet handling
- `GameTimerManager` - Game update loop
- `KeymapController` - Keyboard/mouse command mapping and execution
- `WindowManager` - Window presentation state

**Menu System:**
- `NetrekCommands.swift` - SwiftUI Commands API with proper state management

**Views:**
- All SwiftUI views use `@EnvironmentObject` for manager access
- No direct AppDelegate access anywhere in active code

### Legacy Code (Retained for Reference)

**Files Documented as Legacy:**
- `AppDelegate.swift` - Original NSApplicationDelegate (not used)
- `NSCommandedWindow.swift` - Custom NSWindow for keyboard handling (replaced by view modifiers)

These files are retained for reference but are not part of the active app execution.

## Key Improvements

### Menu State Management
- Ship menu disabled until `loginAccepted` or `gameActive` state
- Checkmarks (✓) show current team/ship selection
- Server menu disabled when connected
- Disconnect button disabled when not connected
- All menus context-aware and prevent invalid operations

### Window Management
- All windows use SwiftUI `.sheet()` presentation
- Proper sizing for each window type
- Clean separation of concerns via WindowManager

### Code Quality
- Removed ~800 lines of duplicate code
- Eliminated all `NSApplication.shared.delegate` anti-patterns
- Proper dependency injection via `@EnvironmentObject`
- Thread-safe with `@MainActor` annotations

## Migration Guide

### For Future Development

**DO:**
- Use `@EnvironmentObject` to access managers in views
- Add new windows to `WindowManager` as `@Published` properties
- Add menu commands to `NetrekCommands.swift`
- Use SwiftUI lifecycle patterns

**DON'T:**
- Access `NSApplication.shared.delegate` (returns nil)
- Modify `AppDelegate.swift` or `NSCommandedWindow.swift` (legacy)
- Create manual NSWindow instances (use WindowGroup/sheets)
- Use `@IBOutlet` for menus (use Commands API)

### Testing Checklist

✅ Keyboard controls work (0-9, a-z, special keys)
✅ Mouse controls work (left/right/middle click)
✅ Team selection menu works with visual feedback
✅ Ship selection menu works with state management
✅ Window commands open respective windows
✅ Server connection/disconnection works
✅ Startup modal appears with localhost default

## Files Modified

### Core Changes
- `NetrekApp.swift` - App entry point, environment setup, window management
- `NetrekCommands.swift` - Menu commands with state management
- `KeymapController.swift` - Converted to ObservableObject, removed AppDelegate access

### View Updates
- `TacticalView.swift` - Use @EnvironmentObject keymapController
- `StrategicView.swift` - Use @EnvironmentObject keymapController
- `MessagesView.swift` - Use @EnvironmentObject for managers
- `ManualServerView.swift` - Use @EnvironmentObject connectionManager
- `PreferencesView.swift` - Updated ActivePreference class
- `StartupModalView.swift` - New server selection modal

### Configuration
- `Globals.swift` - Disabled DEBUG_AUTO_CONNECT_LOCALHOST
- `.gitignore` - Improved xcuserdata patterns

## Remaining Work

None - refactor is complete and all functionality has been restored.

## References

- SwiftUI App Lifecycle: https://developer.apple.com/documentation/swiftui/app
- Commands API: https://developer.apple.com/documentation/swiftui/commands
- Environment Objects: https://developer.apple.com/documentation/swiftui/environmentobject
