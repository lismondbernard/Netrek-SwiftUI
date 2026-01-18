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

    // Connect to a server
    func connectToServer(hostname: String, port: Int = WELLKNOWNPORT) -> Bool {
        guard gameStateManager?.gameState == .noServerSelected ||
              gameStateManager?.gameState == .serverSelected else {
            debugPrint("Cannot connect while in state \(gameStateManager?.gameState.rawValue ?? "unknown")")
            return false
        }

        if reader != nil {
            resetConnection()
        }

        debugPrint("Connecting to server \(hostname):\(port)")
        if let reader = TcpReader(hostname: hostname, port: port, delegate: self) {
            self.reader = reader
            gameStateManager?.newGameState(.serverSelected)
            return true
        } else {
            debugPrint("ServerConnectionManager failed to create TcpReader")
            return false
        }
    }

    // Create packet analyzer when connection is established
    func createPacketAnalyzer() {
        self.analyzer = PacketAnalyzer(connectionManager: self)
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
            debugPrint("ERROR: ServerConnectionManager.sendLogin: no reader")
            gameStateManager?.newGameState(.noServerSelected)
        }
    }

    // Reset and close connection
    func resetConnection() {
        debugPrint("ServerConnectionManager.resetConnection")

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
        debugPrint("ServerConnectionManager got data \(data.count) bytes")
        if data.count > 0 {
            Task { @MainActor in
                analyzer?.analyze(incomingData: data)
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
