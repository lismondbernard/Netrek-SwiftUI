//
//  ServerConnectionManager.swift
//  Netrek2
//
//  Created by Claude Code on 1/18/26.
//  Manages server connections, TCP reader, and packet analysis
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ServerConnectionManager: ObservableObject {
    // Network components
    @Published var metaServer: MetaServer?
    var reader: TcpReader?
    var analyzer: PacketAnalyzer?

    // Server capabilities
    var serverFeatures: [String] = []
    let clientFeatures: [String] = ["FEATURE_PACKETS", "SHIP_CAP", "SP_GENERIC_32", "TIPS"]

    // Dependencies
    weak var gameStateManager: GameStateManager?
    var loginInformationController: LoginInformationController

    init(loginInformationController: LoginInformationController = LoginInformationController()) {
        self.loginInformationController = loginInformationController

        // Initialize metaserver
        self.metaServer = MetaServer(
            primary: "metaserver.netrek.org",
            backup: "metaserver2.netrek.org",
            port: 3521
        )
    }

    // Refresh metaserver list
    func refreshMetaserver() {
        metaServer?.update()
    }

    // Configure metaserver with specific hosts
    func configureMetaserver(primary: String, backup: String, port: Int = 3521) {
        self.metaServer = MetaServer(primary: primary, backup: backup, port: port)
        metaServer?.update()
    }

    // Connect to a server from metaserver list by hostname
    func connectToServerFromMetaserver(hostname: String) -> Bool {
        if let server = metaServer?.servers[hostname] {
            return connectToServer(hostname: server.hostname, port: server.port)
        } else {
            // Server not in metaserver list, try default port
            return connectToServer(hostname: hostname, port: WELLKNOWNPORT)
        }
    }

    // Connect to a server
    func connectToServer(hostname: String, port: Int = WELLKNOWNPORT) -> Bool {
        guard gameStateManager?.gameState == .noServerSelected ||
              gameStateManager?.gameState == .serverSelected else {
            GameLogger.debug("Cannot connect while in state \(gameStateManager?.gameState.rawValue ?? "unknown")", category: .connection)
            return false
        }

        if reader != nil {
            resetConnection()
        }

        GameLogger.debug("Connecting to server \(hostname):\(port)", category: .connection)
        if let reader = TcpReader(hostname: hostname, port: port, delegate: self) {
            self.reader = reader
            gameStateManager?.newGameState(.serverSelected)
            return true
        } else {
            GameLogger.debug("ServerConnectionManager failed to create TcpReader", category: .connection)
            return false
        }
    }

    // Create packet analyzer when connection is established
    func createPacketAnalyzer() {
        self.analyzer = PacketAnalyzer(delegate: self)
    }

    // Send login credentials to server
    func sendLogin() {
        let cpLogin: Data
        if loginInformationController.loginAuthenticated == true &&
           loginInformationController.validInfo {
            cpLogin = MakePacket.cpLogin(
                name: loginInformationController.loginName,
                password: loginInformationController.loginPassword,
                login: loginInformationController.userInfo
            )
        } else {
            cpLogin = MakePacket.cpLogin(name: "guest", password: "", login: "")
        }

        if let reader = reader {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.2) {
                reader.send(content: cpLogin)
            }
        } else {
            GameLogger.debug("ERROR: ServerConnectionManager.sendLogin: no reader", category: .connection)
            gameStateManager?.newGameState(.noServerSelected)
        }
    }

    // Send socket and feature packets when connection is established
    func sendSocketAndFeatures() {
        guard let reader = reader else {
            GameLogger.debug("ERROR: sendSocketAndFeatures: no reader", category: .connection)
            return
        }
        let cpSocket = MakePacket.cpSocket()
        DispatchQueue.global(qos: .background).async {
            reader.send(content: cpSocket)
        }
        for feature in clientFeatures {
            let cpFeature: Data
            if feature == "SP_GENERIC_32" {
                cpFeature = MakePacket.cpFeatures(feature: feature, arg1: 2)
            } else {
                cpFeature = MakePacket.cpFeatures(feature: feature)
            }
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1) {
                self.reader?.send(content: cpFeature)
            }
        }
    }

    // Reset and close connection
    func resetConnection() {
        GameLogger.debug("ServerConnectionManager.resetConnection", category: .connection)

        if let state = gameStateManager?.gameState {
            if state == .gameActive || state == .serverConnected ||
               state == .serverSlotFound || state == .loginAccepted {
                let cpBye = MakePacket.cpBye()
                reader?.send(content: cpBye)
            }
        }

        reader?.resetConnection()
        reader = nil
    }
}

// MARK: - NetworkDelegate

extension ServerConnectionManager: NetworkDelegate {
    nonisolated func gotData(data: Data, from: String, port: Int) {
        GameLogger.debug("ServerConnectionManager got data \(data.count) bytes", category: .connection)
        if !data.isEmpty {
            Task { @MainActor in
                analyzer?.analyze(incomingData: data)
            }
        }
    }

    nonisolated func connectionStateChanged(connected: Bool) {
        Task { @MainActor in
            if connected {
                GameLogger.debug("ServerConnectionManager: connection ready", category: .connection)
                gameStateManager?.newGameState(.serverConnected)
            } else {
                GameLogger.debug("ServerConnectionManager: connection failed/cancelled", category: .connection)
                gameStateManager?.newGameState(.noServerSelected)
            }
        }
    }
}

// MARK: - NetworkSending Conformance

extension ServerConnectionManager: NetworkSending {
    func send(content: Data) {
        reader?.send(content: content)
    }
}

// MARK: - PacketAnalyzerDelegate Conformance

extension ServerConnectionManager: PacketAnalyzerDelegate {
    var gameState: GameState {
        return gameStateManager?.gameState ?? .noServerSelected
    }

    func newGameState(_ state: GameState) {
        gameStateManager?.newGameState(state)
    }

    func triggerReceive() {
        reader?.receive()
    }

    func updateTeamEligibility(mask: UInt8) {
        gameStateManager?.updateTeamEligibility(mask: mask)
    }
}
