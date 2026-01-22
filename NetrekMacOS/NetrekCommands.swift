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

    var body: some Commands {
        // Server Menu
        CommandGroup(replacing: .newItem) {
            Menu("Server") {
                // Server list would be dynamically populated
                // For now, placeholder
                Button("Refresh Metaserver") {
                    connectionManager.refreshMetaserver()
                    GameLogger.debug("Refresh Metaserver menu item clicked", category: .commands)
                }

                Divider()

                Button("Manually Choose Server...") {
                    GameLogger.debug("Manual server selection not yet implemented", category: .commands)
                }
            }
        }

        // Team Menu
        CommandMenu("Team") {
            Button("Federation") {
                gameStateManager.selectTeam(.federation)
            }
            .keyboardShortcut("f")

            Button("Roman") {
                gameStateManager.selectTeam(.roman)
            }
            .keyboardShortcut("r")

            Button("Kazari") {
                gameStateManager.selectTeam(.kazari)
            }
            .keyboardShortcut("k")

            Button("Orion") {
                gameStateManager.selectTeam(.orion)
            }
            .keyboardShortcut("o")
        }

        // Ship Menu
        CommandMenu("Ship") {
            Button("Scout") {
                gameStateManager.selectShip(.scout)
            }
            .keyboardShortcut("s")

            Button("Destroyer") {
                gameStateManager.selectShip(.destroyer)
            }
            .keyboardShortcut("d")

            Button("Cruiser") {
                gameStateManager.selectShip(.cruiser)
            }
            .keyboardShortcut("c")

            Button("Battleship") {
                gameStateManager.selectShip(.battleship)
            }
            .keyboardShortcut("b")

            Button("Assault") {
                gameStateManager.selectShip(.assault)
            }
            .keyboardShortcut("a")

            Button("Starbase") {
                gameStateManager.selectShip(.starbase)
            }
            .keyboardShortcut("z")

            Button("Battlecruiser") {
                gameStateManager.selectShip(.battlecruiser)
            }
            .keyboardShortcut("x")
        }

        // Game Menu
        CommandMenu("Game") {
            Button("Disconnect") {
                connectionManager.resetConnection()
            }

            Divider()

            Button("Preferences...") {
                // Open preferences window
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Login Information...") {
                // Open login window
            }

            Divider()

            Button("Detailed Statistics...") {
                // Open statistics window
            }
        }
    }
}
