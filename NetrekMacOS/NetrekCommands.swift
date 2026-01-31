//
//  NetrekCommands.swift
//  Netrek2
//
//  Created by Claude Code on 1/18/26.
//  Defines menu structure for macOS using SwiftUI Commands API
//

import SwiftUI

// MARK: - Commands

struct NetrekCommands: Commands {
    // Use @FocusedObject for reactive updates from ObservableObject managers
    @FocusedObject var gameStateManager: GameStateManager?
    @FocusedObject var connectionManager: ServerConnectionManager?
    @FocusedObject var windowManager: WindowManager?

    var body: some Commands {
        // Server Menu
        CommandGroup(replacing: .newItem) {
            Menu("Server") {
                Button("Refresh Metaserver") {
                    connectionManager?.refreshMetaserver()
                    GameLogger.debug("Refresh Metaserver menu item clicked", category: .commands)
                }
                .disabled(gameStateManager?.gameState != .noServerSelected)

                Divider()

                Button("Manually Choose Server...") {
                    windowManager?.showingManualServer = true
                }
                .disabled(gameStateManager?.gameState != .noServerSelected)
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
            let gameState = gameStateManager?.gameState
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
            .disabled(gameStateManager?.gameState == .noServerSelected || gameStateManager?.gameState == nil)

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

            Divider()

            Button("Game Controller Help...") {
                windowManager?.showingGameControllerHelp = true
            }
        }
    }
}
