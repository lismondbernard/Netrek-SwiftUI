//
//  AppDelegate.swift
//  NetrekIPad
//
//  Created by Darrell Root on 6/6/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import UIKit
import SwiftUI

// @UIApplicationMain - Disabled in favor of SwiftUI App lifecycle (NetrekApp.swift)
class AppDelegate: UIResponder, UIApplicationDelegate, ObservableObject {
    let help = Help()
    var serverFeatures: [String] = []
    var clientFeatures: [String] = ["FEATURE_PACKETS", "SHIP_CAP", "SP_GENERIC_32", "TIPS"]

    var metaServer = MetaServer(primary: "metaserver.netrek.org", backup:
        "metaserver2.netrek.org", port: 3521)!

    var reader: TcpReader?

    @Published private(set) var gameState: GameState = .noServerSelected {
        didSet {
            switch gameState {
            case .noServerSelected:
                gameScreen = .noServerSelected
            case .serverSelected:
                gameScreen = .serverSelected
            case .serverConnected:
                gameScreen = .serverConnected
            case .serverSlotFound:
                gameScreen = .serverSlotFound
            case .loginAccepted:
                gameScreen = .loginAccepted
            case .gameActive:
                gameScreen = .gameActive
            }
        }
    }
    @Published var gameScreen: GameScreen = .noServerSelected
    var analyzer: PacketAnalyzer?
    var clientTypeSent = false
    var messagesController: MessagesController?

    @ObservedObject var eligibleTeams = EligibleTeams()

    var keymapController: KeymapController!

    let loginInformationController = LoginInformationController()

    let timerInterval = 1.0 / Double(UPDATE_RATE)
    var timer: Timer?
    var timerCount = 0


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let file = #file
        let function = #function
        GameLogger.debug("\(file):\(function)", category: .ui)

        self.keymapController = KeymapController()
        self.messagesController = MessagesController(universe: Universe.universe)

        // Configure ViewModelFactory with dependencies
        ViewModelFactory.shared.configure(
            commandExecutor: self.keymapController,
            networkSender: self,
            gameStateProvider: self
        )

        metaServer.update()

        timer = Timer(timeInterval: timerInterval, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        timer?.tolerance = timerInterval / 10.0
        if let timer = timer {
            RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
        }

        #if DEBUG
        if DEBUG_AUTO_CONNECT_LOCALHOST {
            GameLogger.info("DEBUG: Auto-connecting to \(DEBUG_SERVER)", category: .connection)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                _ = self.selectServer(hostname: DEBUG_SERVER)
            }
        }
        #endif

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let file = #file
        let function = #function
        GameLogger.debug("\(file):\(function)", category: .ui)
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        let file = #file
        let function = #function
        GameLogger.debug("\(file):\(function)", category: .ui)
    }

	// MARK: METASERVER
    func refreshMetaserver() {
        metaServer.update()
    }

    func resetConnection() {
        GameLogger.debug("AppDelegate.resetConnection", category: .ui)
        if gameState == .gameActive || gameState == .serverConnected || gameState == .serverSlotFound || gameState == .loginAccepted {
            let cp_bye = MakePacket.cpBye()
            self.reader?.send(content: cp_bye)
        }
        if self.reader != nil {
            self.reader?.resetConnection()
        }
        self.reader = nil
    }

    @objc func timerFired() {
        timerCount += 1
        if timerCount.isMultiple(of: Int(UPDATE_RATE)) {
            Universe.universe.seconds.increment()
        }
        switch self.gameState {
        case .noServerSelected:
            break
        case .serverSelected:
            break
        case .serverConnected:
            break
        case .serverSlotFound:
            break
        case .loginAccepted:
            break
        case .gameActive:
            if (timerCount % 100) == 0 {
                GameLogger.debug("Setting needs display for playerListViewController", category: .ui)
                // send cpUpdate once every 10 seconds to prevent ghostbust
                let cpUpdates = MakePacket.cpUpdates()
                reader?.send(content: cpUpdates)
            }
        }
    }

    func selectServer(hostname: String) -> Bool {
        guard gameState == .noServerSelected else {
            GameLogger.debug("AppDelegate.selectServer: Error cannot select server \(hostname) while gameState is \(self.gameState)", category: .ui)
            return false
        }

        if reader != nil {
            self.resetConnection()
        }

        if let server = metaServer.servers[hostname] {
            GameLogger.debug("starting game server \(hostname)", category: .ui)
            if let reader = TcpReader(hostname: hostname, port: server.port, delegate: self) {
                self.reader = reader
                self.newGameState(.serverSelected)
                return true
            } else {
                GameLogger.debug("AppDelegate failed to start reader", category: .ui)
                return false
            }
        } else {
            if let reader = TcpReader(hostname: hostname, port: WELLKNOWNPORT, delegate: self) {
                self.reader = reader
                self.newGameState(.serverSelected)
                return true
            } else {
                GameLogger.debug("AppDelegate failed to start reader", category: .ui)
                return false
            }
        }
    }

	func selectShip(ship: ShipType) {
        self.eligibleTeams.preferredShip = ship
        if self.gameState == .loginAccepted {
            if let reader = self.reader {
                let cpUpdates = MakePacket.cpUpdates()
                reader.send(content: cpUpdates)
                let cpOutfit = MakePacket.cpOutfit(team: self.eligibleTeams.preferredTeam, ship: self.eligibleTeams.preferredShip)
                reader.send(content: cpOutfit)
            }
        }
        if self.gameState == .gameActive {
            if let reader = self.reader {
                let cpRefit = MakePacket.cpRefit(newShip: self.eligibleTeams.preferredShip)
                reader.send(content: cpRefit)
            }
        }
    }

    func newGameState(_ newState: GameState ) {
        GameLogger.info("Game State: moving from \(self.gameState.rawValue) to \(newState.rawValue)\n", category: .gameState)
        switch newState {
        case .noServerSelected:
            self.resetConnection()
            self.help.nextTip()
            Universe.universe.reset()
            self.gameState = newState
            Universe.universe.gotMessage("AppDelegate GameState \(newState) we may have been ghostbusted!  Resetting.  Try again\n")
            GameLogger.warning("AppDelegate GameState \(newState) we may have been ghostbusted!  Resetting.  Try again\n", category: .gameState)
            self.refreshMetaserver()
        case .serverSelected:
            self.help.nextTip()
            self.gameState = newState
            // PacketAnalyzer creation moved to ServerConnectionManager
            // self.analyzer = PacketAnalyzer(connectionManager: nil)

        case .serverConnected:
            self.help.nextTip()
            self.clientTypeSent = false
            DispatchQueue.main.async {
                self.gameState = newState
            }

            guard let reader = self.reader else {
                self.newGameState(.noServerSelected)
                return
            }
            let cpSocket = MakePacket.cpSocket()
            DispatchQueue.global(qos: .background).async {
                reader.send(content: cpSocket)
            }
            for feature in self.clientFeatures {
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

        case .serverSlotFound:
            DispatchQueue.main.async {
                self.gameState = newState
            }
            GameLogger.debug("AppDelegate.newGameState: .serverSlotFound", category: .gameState)
            let cpLogin: Data
            if self.loginInformationController.loginAuthenticated == true && self.loginInformationController.validInfo {
                cpLogin = MakePacket.cpLogin(name: self.loginInformationController.loginName, password: self.loginInformationController.loginPassword, login: self.loginInformationController.userInfo)
            } else {
                cpLogin = MakePacket.cpLogin(name: "guest", password: "", login: "")
            }
            if let reader = self.reader {
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.2) {
                    reader.send(content: cpLogin)
                }
            } else {
                GameLogger.error("ERROR: AppDelegate.newGameState.serverSlot found: no reader", category: .gameState)
                self.newGameState(.noServerSelected)
            }

        case .loginAccepted:
            self.help.nextTip()
            DispatchQueue.main.async {
                self.gameState = newState
            }

        case .gameActive:
            self.help.noTip()
            DispatchQueue.main.async {
                self.gameState = newState
            }
            if !self.clientTypeSent {
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
                let data = MakePacket.cpMessage(message: "I am using the Swift Netrek Client version \(appVersion) build \(buildVersion) on iPadOS", team: .ogg, individual: 0)
                self.clientTypeSent = true
                self.reader?.send(content: data)
            }
        }
    }
}

extension AppDelegate: NetworkDelegate {
    func gotData(data: Data, from: String, port: Int) {
        GameLogger.debug("appdelegate got data \(data.count) bytes", category: .network)
        if !data.isEmpty {
            analyzer?.analyze(incomingData: data)
        }
    }
}

// MARK: - NetworkSending Conformance

extension AppDelegate: NetworkSending {
    func send(content: Data) {
        reader?.send(content: content)
    }
}

// MARK: - GameStateProviding Conformance

extension AppDelegate: GameStateProviding {
    // gameState is already a @Published property on AppDelegate
}
