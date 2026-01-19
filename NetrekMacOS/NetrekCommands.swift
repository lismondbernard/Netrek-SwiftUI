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
    // TODO Phase 3.2: Pass managers as init parameters when refactoring menus
    // For now, use safe AppDelegate access as temporary solution

    var body: some Commands {

        // Server Menu
        CommandGroup(replacing: .newItem) {
            Menu("Server") {
                // Server list would be dynamically populated
                // For now, placeholder
                Button("Refresh Metaserver") {
                    // TODO: Access connectionManager when available
                    GameLogger.debug("Refresh Metaserver menu item clicked", category: .commands)
                }

                Divider()

                Button("Manually Choose Server...") {
                    // Open manual server window
                }
            }
        }

        // Team Menu
        // TODO Phase 3.2: Restore team selection functionality with proper manager access
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
        // TODO Phase 3.2: Restore ship selection functionality with proper manager access
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
                // TODO Phase 3.2: Implement disconnect
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
