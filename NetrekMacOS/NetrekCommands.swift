//
//  NetrekCommands.swift
//  Netrek2
//
//  Created by Claude Code on 1/18/26.
//  Defines menu structure for macOS using SwiftUI Commands API
//

import SwiftUI

struct NetrekCommands: Commands {

    @EnvironmentObject var gameStateManager: GameStateManager
    @EnvironmentObject var connectionManager: ServerConnectionManager
    @EnvironmentObject var universe: Universe

    var body: some Commands {

        // Server Menu
        CommandGroup(replacing: .newItem) {
            Menu("Server") {
                // Server list would be dynamically populated
                // For now, placeholder
                Button("Refresh Metaserver") {
                    connectionManager.refreshMetaserver()
                }

                Divider()

                Button("Manually Choose Server...") {
                    // Open manual server window
                }
            }
        }

        // Team Menu
        CommandMenu("Team") {
            ForEach(Team.allCases, id: \.self) { team in
                if team != .independent && team != .ogg {
                    Button(team.description) {
                        gameStateManager.selectTeam(team)
                    }
                    .keyboardShortcut(keyEquivalent(for: team))
                }
            }
        }

        // Ship Menu
        CommandMenu("Ship") {
            ForEach(ShipType.allCases, id: \.self) { shipType in
                Button(shipType.description) {
                    gameStateManager.selectShip(shipType)
                }
                .keyboardShortcut(keyEquivalent(for: shipType))
                .disabled(gameStateManager.gameState != .loginAccepted &&
                         gameStateManager.gameState != .gameActive)
            }
        }

        // Game Menu
        CommandMenu("Game") {
            Button("Disconnect") {
                gameStateManager.newGameState(.noServerSelected)
            }
            .disabled(gameStateManager.gameState == .noServerSelected)

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

    // Helper functions for keyboard shortcuts
    private func keyEquivalent(for team: Team) -> KeyEquivalent {
        switch team {
        case .federation: return "f"
        case .roman: return "r"
        case .kazari: return "k"
        case .orion: return "o"
        default: return "f"
        }
    }

    private func keyEquivalent(for shipType: ShipType) -> KeyEquivalent {
        switch shipType {
        case .scout: return "s"
        case .destroyer: return "d"
        case .cruiser: return "c"
        case .battleship: return "b"
        case .assault: return "a"
        case .starbase: return "z"
        case .battlecruiser: return "x"
        }
    }
}
