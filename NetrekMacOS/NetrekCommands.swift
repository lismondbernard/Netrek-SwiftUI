//
//  NetrekCommands.swift
//  Netrek2
//
//  Created by Claude Code on 1/18/26.
//  Defines menu structure for macOS using SwiftUI Commands API
//

import SwiftUI

struct NetrekCommands: Commands {
    let connectionManager: ServerConnectionManager
    let gameStateManager: GameStateManager
    let windowManager: WindowManager

    var body: some Commands {
        // Server Menu
        CommandGroup(replacing: .newItem) {
            Menu("Server") {
                let canSelectServer = gameStateManager.gameState == .noServerSelected

                Button("Refresh Metaserver") {
                    connectionManager.refreshMetaserver()
                    GameLogger.debug("Refresh Metaserver menu item clicked", category: .commands)
                }
                .disabled(!canSelectServer)

                Divider()

                Button("Manually Choose Server...") {
                    windowManager.showingManualServer = true
                }
                .disabled(!canSelectServer)
            }
        }

        // Team Menu
        CommandMenu("Team") {
            Button(gameStateManager.preferredTeam == .federation ? "Federation ✓" : "Federation") {
                gameStateManager.selectTeam(.federation)
            }
            .keyboardShortcut("f")

            Button(gameStateManager.preferredTeam == .roman ? "Roman ✓" : "Roman") {
                gameStateManager.selectTeam(.roman)
            }
            .keyboardShortcut("r")

            Button(gameStateManager.preferredTeam == .kazari ? "Kazari ✓" : "Kazari") {
                gameStateManager.selectTeam(.kazari)
            }
            .keyboardShortcut("k")

            Button(gameStateManager.preferredTeam == .orion ? "Orion ✓" : "Orion") {
                gameStateManager.selectTeam(.orion)
            }
            .keyboardShortcut("o")
        }

        // Ship Menu
        CommandMenu("Ship") {
            let canSelectShip = gameStateManager.gameState == .loginAccepted ||
                               gameStateManager.gameState == .gameActive

            Button(gameStateManager.preferredShip == .scout ? "Scout ✓" : "Scout") {
                gameStateManager.selectShip(.scout)
            }
            .keyboardShortcut("s")
            .disabled(!canSelectShip)

            Button(gameStateManager.preferredShip == .destroyer ? "Destroyer ✓" : "Destroyer") {
                gameStateManager.selectShip(.destroyer)
            }
            .keyboardShortcut("d")
            .disabled(!canSelectShip)

            Button(gameStateManager.preferredShip == .cruiser ? "Cruiser ✓" : "Cruiser") {
                gameStateManager.selectShip(.cruiser)
            }
            .keyboardShortcut("c")
            .disabled(!canSelectShip)

            Button(gameStateManager.preferredShip == .battleship ? "Battleship ✓" : "Battleship") {
                gameStateManager.selectShip(.battleship)
            }
            .keyboardShortcut("b")
            .disabled(!canSelectShip)

            Button(gameStateManager.preferredShip == .assault ? "Assault ✓" : "Assault") {
                gameStateManager.selectShip(.assault)
            }
            .keyboardShortcut("a")
            .disabled(!canSelectShip)

            Button(gameStateManager.preferredShip == .starbase ? "Starbase ✓" : "Starbase") {
                gameStateManager.selectShip(.starbase)
            }
            .keyboardShortcut("z")
            .disabled(!canSelectShip)

            Button(gameStateManager.preferredShip == .battlecruiser ? "Battlecruiser ✓" : "Battlecruiser") {
                gameStateManager.selectShip(.battlecruiser)
            }
            .keyboardShortcut("x")
            .disabled(!canSelectShip)
        }

        // Game Menu
        CommandMenu("Game") {
            let isConnected = gameStateManager.gameState != .noServerSelected

            Button("Disconnect") {
                connectionManager.resetConnection()
            }
            .disabled(!isConnected)

            Divider()

            Button("Preferences...") {
                windowManager.showingPreferences = true
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Login Information...") {
                windowManager.showingLogin = true
            }

            Divider()

            Button("Detailed Statistics...") {
                windowManager.showingStatistics = true
            }
        }
    }
}
