//
//  NetrekCommands.swift
//  Netrek2
//
//  Created by Claude Code on 1/18/26.
//  Defines menu structure for macOS using SwiftUI Commands API
//

import SwiftUI

// MARK: - Focused Values for Commands

/// Key for passing game state to Commands
struct FocusedGameStateKey: FocusedValueKey {
    typealias Value = GameState
}

/// Key for passing GameStateManager to Commands
struct FocusedGameStateManagerKey: FocusedValueKey {
    typealias Value = GameStateManager
}

/// Key for passing ServerConnectionManager to Commands
struct FocusedConnectionManagerKey: FocusedValueKey {
    typealias Value = ServerConnectionManager
}

/// Key for passing WindowManager to Commands
struct FocusedWindowManagerKey: FocusedValueKey {
    typealias Value = WindowManager
}

extension FocusedValues {
    var gameState: GameState? {
        get { self[FocusedGameStateKey.self] }
        set { self[FocusedGameStateKey.self] = newValue }
    }

    var gameStateManager: GameStateManager? {
        get { self[FocusedGameStateManagerKey.self] }
        set { self[FocusedGameStateManagerKey.self] = newValue }
    }

    var connectionManager: ServerConnectionManager? {
        get { self[FocusedConnectionManagerKey.self] }
        set { self[FocusedConnectionManagerKey.self] = newValue }
    }

    var windowManager: WindowManager? {
        get { self[FocusedWindowManagerKey.self] }
        set { self[FocusedWindowManagerKey.self] = newValue }
    }
}

// MARK: - Commands

struct NetrekCommands: Commands {
    // Use @FocusedValue to reactively receive state updates from the focused view
    @FocusedValue(\.gameState) var gameState
    @FocusedValue(\.gameStateManager) var gameStateManager
    @FocusedValue(\.connectionManager) var connectionManager
    @FocusedValue(\.windowManager) var windowManager

    var body: some Commands {
        // Server Menu
        CommandGroup(replacing: .newItem) {
            Menu("Server") {
                Button("Refresh Metaserver") {
                    connectionManager?.refreshMetaserver()
                    GameLogger.debug("Refresh Metaserver menu item clicked", category: .commands)
                }
                .disabled(gameState != .noServerSelected)

                Divider()

                Button("Manually Choose Server...") {
                    windowManager?.showingManualServer = true
                }
                .disabled(gameState != .noServerSelected)
            }
        }

        // Team Menu
        CommandMenu("Team") {
            let preferredTeam = gameStateManager?.preferredTeam ?? .federation

            Button(preferredTeam == .federation ? "Federation ✓" : "Federation") {
                gameStateManager?.selectTeam(.federation)
            }

            Button(preferredTeam == .roman ? "Roman ✓" : "Roman") {
                gameStateManager?.selectTeam(.roman)
            }

            Button(preferredTeam == .kazari ? "Kazari ✓" : "Kazari") {
                gameStateManager?.selectTeam(.kazari)
            }

            Button(preferredTeam == .orion ? "Orion ✓" : "Orion") {
                gameStateManager?.selectTeam(.orion)
            }
        }

        // Ship Menu
        CommandMenu("Ship") {
            let preferredShip = gameStateManager?.preferredShip ?? .cruiser
            let canSelectShip = gameState == .loginAccepted || gameState == .gameActive

            Button(preferredShip == .scout ? "Scout ✓" : "Scout") {
                GameLogger.debug("Ship menu: Scout selected", category: .commands)
                gameStateManager?.selectShip(.scout)
            }
            .disabled(!canSelectShip)

            Button(preferredShip == .destroyer ? "Destroyer ✓" : "Destroyer") {
                GameLogger.debug("Ship menu: Destroyer selected", category: .commands)
                gameStateManager?.selectShip(.destroyer)
            }
            .disabled(!canSelectShip)

            Button(preferredShip == .cruiser ? "Cruiser ✓" : "Cruiser") {
                GameLogger.debug("Ship menu: Cruiser selected", category: .commands)
                gameStateManager?.selectShip(.cruiser)
            }
            .disabled(!canSelectShip)

            Button(preferredShip == .battleship ? "Battleship ✓" : "Battleship") {
                GameLogger.debug("Ship menu: Battleship selected", category: .commands)
                gameStateManager?.selectShip(.battleship)
            }
            .disabled(!canSelectShip)

            Button(preferredShip == .assault ? "Assault ✓" : "Assault") {
                GameLogger.debug("Ship menu: Assault selected", category: .commands)
                gameStateManager?.selectShip(.assault)
            }
            .disabled(!canSelectShip)

            Button(preferredShip == .starbase ? "Starbase ✓" : "Starbase") {
                GameLogger.debug("Ship menu: Starbase selected", category: .commands)
                gameStateManager?.selectShip(.starbase)
            }
            .disabled(!canSelectShip)

            Button(preferredShip == .battlecruiser ? "Battlecruiser ✓" : "Battlecruiser") {
                GameLogger.debug("Ship menu: Battlecruiser selected", category: .commands)
                gameStateManager?.selectShip(.battlecruiser)
            }
            .disabled(!canSelectShip)
        }

        // Game Menu
        CommandMenu("Game") {
            Button("Disconnect") {
                connectionManager?.resetConnection()
            }
            .disabled(gameState == .noServerSelected || gameState == nil)

            Divider()

            Button("Preferences...") {
                windowManager?.showingPreferences = true
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Login Information...") {
                windowManager?.showingLogin = true
            }

            Divider()

            Button("Detailed Statistics...") {
                windowManager?.showingStatistics = true
            }
        }
    }
}
