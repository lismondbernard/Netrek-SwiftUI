//
//  GameStateManager.swift
//  Netrek2
//
//  Created by Claude Code on 1/18/26.
//  Manages game state transitions with thread safety via @MainActor
//

import Foundation
import SwiftUI
import Combine

@MainActor
class GameStateManager: ObservableObject {

    @Published private(set) var gameState: GameState = .noServerSelected

    // Dependencies injected from App
    weak var connectionManager: ServerConnectionManager?
    weak var help: Help?
    var clientTypeSent = false

    var preferredTeam: Team = .federation
    var preferredShip: ShipType = .cruiser
    var initialTeamSet = false

    // Transition to new game state with side effects
    func newGameState(_ newState: GameState) {
        GameLogger.debug("Game State: moving from \(self.gameState.rawValue) to \(newState.rawValue)", category: .gameState)

        switch newState {

        case .noServerSelected:
            connectionManager?.resetConnection()
            help?.nextTip()
            Universe.universe.reset()
            self.gameState = newState
            Universe.universe.gotMessage("GameState \(newState) we may have been ghostbusted! Resetting. Try again")
            GameLogger.debug("GameState \(newState) we may have been ghostbusted! Resetting. Try again", category: .gameState)
            connectionManager?.refreshMetaserver()

        case .serverSelected:
            help?.nextTip()
            self.gameState = newState
            connectionManager?.createPacketAnalyzer()

        case .serverConnected:
            help?.nextTip()
            self.clientTypeSent = false
            self.gameState = newState

            guard let reader = connectionManager?.reader else {
                self.newGameState(.noServerSelected)
                return
            }

            let cpSocket = MakePacket.cpSocket()
            DispatchQueue.global(qos: .background).async {
                reader.send(content: cpSocket)
            }

            // Send client features
            let clientFeatures = ["FEATURE_PACKETS", "SHIP_CAP", "SP_GENERIC_32", "TIPS"]
            for feature in clientFeatures {
                let cpFeature: Data
                if feature == "SP_GENERIC_32" {
                    cpFeature = MakePacket.cpFeatures(feature: feature, arg1: 2)
                } else {
                    cpFeature = MakePacket.cpFeatures(feature: feature)
                }
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1) {
                    self.connectionManager?.reader?.send(content: cpFeature)
                }
            }

        case .serverSlotFound:
            self.gameState = newState
            GameLogger.debug("GameStateManager.newGameState: .serverSlotFound", category: .gameState)

            // Send login credentials
            connectionManager?.sendLogin()

        case .loginAccepted:
            help?.nextTip()
            self.gameState = newState

        case .gameActive:
            help?.noTip()
            self.gameState = newState

            if !clientTypeSent {
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"

                #if os(macOS)
                let platform = "MacOS"
                #elseif os(iOS)
                let platform = "iPadOS"
                #endif

                let data = MakePacket.cpMessage(
                    message: "I am using the Swift Netrek Client version \(appVersion) build \(buildVersion) on \(platform)",
                    team: .ogg,
                    individual: 0
                )
                clientTypeSent = true
                connectionManager?.reader?.send(content: data)
            }
        }
    }

    // Ship selection with network protocol
    func selectShip(_ ship: ShipType) {
        self.preferredShip = ship

        if self.gameState == .loginAccepted {
            guard let reader = connectionManager?.reader else { return }
            let cpUpdates = MakePacket.cpUpdates()
            reader.send(content: cpUpdates)
            let cpOutfit = MakePacket.cpOutfit(team: self.preferredTeam, ship: self.preferredShip)
            reader.send(content: cpOutfit)
        }

        if self.gameState == .gameActive {
            guard let reader = connectionManager?.reader else { return }
            let cpRefit = MakePacket.cpRefit(newShip: self.preferredShip)
            reader.send(content: cpRefit)
        }
    }

    // Team selection
    func selectTeam(_ team: Team) {
        self.preferredTeam = team
    }

    // Team eligibility update from server
    func updateTeamEligibility(mask: UInt8) {
        var eligible: [Team] = []

        for team in Team.allCases {
            if mask & UInt8(team.rawValue) != 0 {
                eligible.append(team)
            }
        }

        // Auto-select first eligible team on initial connection
        if !initialTeamSet && mask != 0 {
            if let firstEligible = eligible.first {
                self.preferredTeam = firstEligible
                self.initialTeamSet = true
                GameLogger.debug("Initial team set to \(firstEligible)", category: .gameState)
            }
        }
    }
}

// MARK: - GameStateProviding Conformance

extension GameStateManager: GameStateProviding {
    // Provides gameState to legacy components during transition
}
