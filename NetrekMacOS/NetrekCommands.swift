//
//  NetrekCommands.swift
//  Netrek2
//
//  Created by Claude Code on 1/18/26.
//  Defines menu structure for macOS using SwiftUI Commands API
//

import SwiftUI

struct NetrekCommands: Commands {
    // Note: Commands don't receive @EnvironmentObject like views do
    // FUTURE: Inject ServerConnectionManager and GameStateManager via init
    // when menu functionality is fully restored

    var body: some Commands {
        // Server Menu
        CommandGroup(replacing: .newItem) {
            Menu("Server") {
                // Server list would be dynamically populated
                // For now, placeholder
                Button("Refresh Metaserver") {
                    // FUTURE: Call connectionManager.refreshMetaserver()
                    GameLogger.debug("Refresh Metaserver menu item clicked", category: .commands)
                }

                Divider()

                Button("Manually Choose Server...") {
                    // Open manual server window
                }
            }
        }

        // Team Menu
        // FUTURE: Connect to MakePacket.cpOutfit for team selection
        CommandMenu("Team") {
            Button("Federation") { }
                .keyboardShortcut("f")
            Button("Roman") { }
                .keyboardShortcut("r")
            Button("Kazari") { }
                .keyboardShortcut("k")
            Button("Orion") { }
                .keyboardShortcut("o")
        }

        // Ship Menu
        // FUTURE: Connect to MakePacket.cpOutfit for ship selection
        CommandMenu("Ship") {
            Button("Scout") { }.keyboardShortcut("s")
            Button("Destroyer") { }.keyboardShortcut("d")
            Button("Cruiser") { }.keyboardShortcut("c")
            Button("Battleship") { }.keyboardShortcut("b")
            Button("Assault") { }.keyboardShortcut("a")
            Button("Starbase") { }.keyboardShortcut("z")
            Button("Battlecruiser") { }.keyboardShortcut("x")
        }

        // Game Menu
        CommandMenu("Game") {
            Button("Disconnect") {
                // FUTURE: Call connectionManager.resetConnection()
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
