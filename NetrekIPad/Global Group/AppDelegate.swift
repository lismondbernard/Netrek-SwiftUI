//
//  AppDelegate.swift
//  NetrekIPad
//
//  Created by Darrell Root on 6/6/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import UIKit
import SwiftUI
import GameController

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ObservableObject {
    
    //let defaults = UserDefaults.standard
    
    let help = Help()
    //did not work
    //var audioController: AudioController?

    //Whenever gameState changes, gameScreen matches
    //But we can manually change gameScreen to go to help or credits without changing gameState
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
    var clientTypeSent = false
    //var soundController: SoundController?
    var messagesController: MessagesController?
    
    //set this to true when we first set the preferred team, which we only do once
    //var initialTeamSet = false
    
    @ObservedObject var eligibleTeams = EligibleTeams()
    
    var keymapController: KeymapController!
    
    let loginInformationController =  LoginInformationController()

    /// Game controller manager for MFI controller support
    var gameControllerManager: GameControllerManager?

    // MARK: - MVVM Managers
    var gameStateManager: GameStateManager?
    var gameTimerManager: GameTimerManager?
    var serverConnectionManager: ServerConnectionManager?

    // MARK: - Computed Properties for Views
    /// Returns the hostname of the connected server
    var connectedServerHostname: String? {
        return serverConnectionManager?.reader?.hostname
    }

    /// Returns the metaServer from the connection manager
    var metaServer: MetaServer? {
        return serverConnectionManager?.metaServer
    }

    /// Send data to the connected server (thread-safe)
    func sendData(_ data: Data) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                serverConnectionManager?.send(content: data)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.serverConnectionManager?.send(content: data)
            }
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let file = #file
        let function = #function
        debugPrint("\(file):\(function)")

        //self.soundController = SoundController()
        self.keymapController = KeymapController()
        self.messagesController = MessagesController(universe: Universe.universe)

        // Initialize game controller support
        self.gameControllerManager = GameControllerManager.shared
        self.gameControllerManager?.appDelegate = self
        GCController.startWirelessControllerDiscovery { }

        // Initialize MVVM managers
        initializeManagers()

        // Use the manager's metaServer
        serverConnectionManager?.refreshMetaserver()

        // Override point for customization after application launch.
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let file = #file
        let function = #function
        debugPrint("\(file):\(function)")
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        let file = #file
        let function = #function
        debugPrint("\(file):\(function)")
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    // MARK: - Manager Initialization

    @MainActor
    private func initializeManagers() {
        // Create managers
        let stateManager = GameStateManager()
        let connectionManager = ServerConnectionManager(loginInformationController: loginInformationController)
        let timerManager = GameTimerManager()

        // Wire up dependencies
        stateManager.connectionManager = connectionManager
        stateManager.help = help

        connectionManager.gameStateManager = stateManager

        timerManager.gameStateManager = stateManager
        timerManager.connectionManager = connectionManager

        // Store references
        self.gameStateManager = stateManager
        self.serverConnectionManager = connectionManager
        self.gameTimerManager = timerManager

        // Start the game timer
        timerManager.startTimer()

        GameLogger.info("MVVM managers initialized and timer started", category: .gameState)
    }

    //MARK: METASERVER
    @MainActor func refreshMetaserver() {
        serverConnectionManager?.refreshMetaserver()
    }

    @MainActor func resetConnection() {
        GameLogger.debug("AppDelegate.resetConnection", category: .connection)
        serverConnectionManager?.resetConnection()
    }

    @MainActor public func selectServer(hostname: String) -> Bool {
        guard gameState == .noServerSelected else {
            GameLogger.warning("AppDelegate.selectServer: Error cannot select server \(hostname) while gameState is \(self.gameState)", category: .connection)
            return false
        }

        serverConnectionManager?.resetConnection()
        GameLogger.info("starting game server \(hostname)", category: .connection)
        if serverConnectionManager?.connectToServerFromMetaserver(hostname: hostname) == true {
            self.newGameState(.serverSelected)
            return true
        }
        return false
    }
    /*func enableSpeech() {
        self.audioController = AudioController(keymapController: keymapController)
    }*/
    @MainActor func selectShip(ship: ShipType) {
        self.eligibleTeams.preferredShip = ship
        if self.gameState == .loginAccepted {
            let cpUpdates = MakePacket.cpUpdates()
            serverConnectionManager?.send(content: cpUpdates)
            let cpOutfit = MakePacket.cpOutfit(team: self.eligibleTeams.preferredTeam, ship: self.eligibleTeams.preferredShip)
            serverConnectionManager?.send(content: cpOutfit)
        }
        if self.gameState == .gameActive {
            let cpRefit = MakePacket.cpRefit(newShip: self.eligibleTeams.preferredShip)
            serverConnectionManager?.send(content: cpRefit)
        }
    }

    @MainActor public func newGameState(_ newState: GameState ) {
        GameLogger.info("Game State: moving from \(self.gameState.rawValue) to \(newState.rawValue)", category: .gameState)
        switch newState {
            
            
        case .noServerSelected:
            self.resetConnection()
            self.help.nextTip()
            Universe.universe.reset()
            //enableServerMenu()
            //disableShipMenu()
            self.gameState = newState
            Universe.universe.gotMessage("AppDelegate GameState \(newState) we may have been ghostbusted!  Resetting.  Try again\n")
            GameLogger.warning("AppDelegate GameState \(newState) we may have been ghostbusted! Resetting. Try again", category: .gameState)
            self.refreshMetaserver()
            break
            
        case .serverSelected:
            self.help.nextTip()
            //disableShipMenu()
            //disableServerMenu()
            self.gameState = newState
            serverConnectionManager?.createPacketAnalyzer()
            // no need to do anything here, handled in the menu function
            break

        case .serverConnected:
            self.help.nextTip()
            //disableShipMenu()
            //disableServerMenu()
            self.clientTypeSent = false
            DispatchQueue.main.async {
                self.gameState = newState
            }
            // Delegate socket and feature sending to the manager
            serverConnectionManager?.sendSocketAndFeatures()

        case .serverSlotFound:
            //disableShipMenu()
            //disableServerMenu()
            DispatchQueue.main.async {
                self.gameState = newState
            }
            GameLogger.debug("AppDelegate.newGameState: .serverSlotFound", category: .gameState)
            // Delegate login to the manager
            serverConnectionManager?.sendLogin()
            
        case .loginAccepted:
            self.help.nextTip()
            //self.enableShipMenu()
            //self.disableServerMenu()
            /*DispatchQueue.main.async {
             self.playerListViewController?.view.needsDisplay = true
             }*/
            DispatchQueue.main.async {
                self.gameState = newState
            }
            
        case .gameActive:
            self.help.noTip()
            //self.enableShipMenu()
            //self.disableServerMenu()
            /*DispatchQueue.main.async {
             self.playerListViewController?.view.needsDisplay = true
             }*/
            DispatchQueue.main.async {
                self.gameState = newState
            }
            if !self.clientTypeSent {
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
                let data = MakePacket.cpMessage(message: "I am using the Swift Netrek Client version \(appVersion) build \(buildVersion) on iPadOS", team: .ogg, individual: 0)
                self.clientTypeSent = true
                serverConnectionManager?.send(content: data)
            }
        }
    }
}

