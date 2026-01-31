//
//  AppDelegate.swift
//  Netrek2
//
//  Created by Darrell Root on 5/5/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import Cocoa
import SwiftUI
import Network
import GameController
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    
    let defaults = UserDefaults.standard
    let preferencesController = PreferencesController(defaults: UserDefaults.standard)
    
    let universe = Universe.universe
    
    let help = Help()
    

    var everythingWindow: NSCommandedWindow!
    //var tacticalWindow: NSWindow!
    //var strategicWindow: NSWindow!
    //var communicationsWindow: NSWindow!
    var manualServerWindows: [NSWindow] = []
    var preferencesWindows: [NSWindow] = []
    var loginWindows: [NSWindow] = []
    var detailedStatisticsWindows: [NSWindow] = []
    var gameControllerHelpWindows: [NSWindow] = []
    
    private(set) var gameState: GameState = .noServerSelected
    var clientTypeSent = false
    private var gameStateCancellable: AnyCancellable?
    //var soundController: SoundController?

    /// Game controller manager for MFI controller support
    var gameControllerManager: GameControllerManager?

    // MARK: - MVVM Managers
    var gameStateManager: GameStateManager?
    var gameTimerManager: GameTimerManager?
    var serverConnectionManager: ServerConnectionManager?

    // MARK: - Convenience Methods for Views
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

    var serverByTag: [Int:String] = [:]
    
    //set this to true when we first set the preferred team, which we only do once
    var initialTeamSet = false

    @IBOutlet weak var serverMenu: NSMenu!

    @IBOutlet weak var selectShipScout: NSMenuItem!
    @IBOutlet weak var selectShipDestroyer: NSMenuItem!
    @IBOutlet weak var selectShipCruiser: NSMenuItem!
    @IBOutlet weak var selectShipBattleship: NSMenuItem!
    @IBOutlet weak var selectShipAssault: NSMenuItem!
    @IBOutlet weak var selectShipStarbase: NSMenuItem!
    @IBOutlet weak var selectShipBattlecruiser: NSMenuItem!

    @IBOutlet weak var selectTeamFederation: NSMenuItem!
    @IBOutlet weak var selectTeamRoman: NSMenuItem!
    @IBOutlet weak var selectTeamKazari: NSMenuItem!
    @IBOutlet weak var selectTeamOrion: NSMenuItem!

    var preferredTeam: Team = .federation
    var preferredShip: ShipType = .cruiser
    var keymapController: KeymapController!
    let loginInformationController = LoginInformationController()

    @IBAction func disconnectGame(_ sender: NSMenuItem) {
        gameStateManager?.newGameState(.noServerSelected)
    }

    
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        //Always run in dark mode
        NSApp.appearance = NSAppearance(named: .darkAqua)

        //self.soundController = SoundController()
        self.keymapController = KeymapController()

        // Initialize game controller support
        self.gameControllerManager = GameControllerManager.shared
        GCController.startWirelessControllerDiscovery { }

        // Initialize MVVM managers
        initializeManagers()

        // Wire KeymapController to managers
        keymapController.networkSender = serverConnectionManager
        keymapController.gameStateProvider = gameStateManager

        // Wire GameControllerManager to managers
        gameControllerManager?.keymapController = keymapController
        gameControllerManager?.gameStateProvider = gameStateManager

        // Wire GameStateManager into Player models
        if let gsm = gameStateManager {
            Universe.universe.wireGameStateManager(gsm)
        }

        // Observe game state for menu management
        observeGameState()

        setupBlankMenu()
        // Wire metaserver callback for menu updates
        serverConnectionManager?.metaServer?.onMetaserverUpdated = { [weak self] in
            self?.metaserverUpdated()
        }
        // Use the manager's metaServer instead of creating a new one
        serverConnectionManager?.refreshMetaserver()
        self.updateTeamMenu()
        self.disableShipMenu()

        // Create the SwiftUI view that provides the window contents.
        //let tacticalView = TacticalView(help: help, preferencesController: preferencesController)
        //let strategicView = StrategicView()

        let everythingView = EverythingView(help: help, preferencesController: preferencesController)
            .environmentObject(gameStateManager!)
            .environmentObject(serverConnectionManager!)
            .environment(\.keymapController, keymapController)
        
        everythingWindow = NSCommandedWindow(contentRect: NSRect(x: 0, y: 800, width: 1000, height: 800),styleMask: [.titled, .miniaturizable, .resizable, .fullSizeContentView],
                                             backing: .buffered, defer: false)
        everythingWindow.keymapController = keymapController
        everythingWindow.setFrameAutosaveName("temp37")
        everythingWindow.contentView = NSHostingView(rootView: everythingView)
        everythingWindow.standardWindowButton(NSWindow.ButtonType.closeButton)?.isHidden = true
        //The title name impacts the keypress location algorithm, see NSCommmandedWindow
        everythingWindow.title = "Netrek"
        everythingWindow.makeKeyAndOrderFront(nil)

        /*// Create the window and set the content view.
        tacticalWindow = NSCommandedWindow(
            contentRect: NSRect(x: 0, y: 800, width: 500, height: 500),
            styleMask: [.titled, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        //tacticalWindow.center()
        tacticalWindow.setFrameAutosaveName("Tactical5")
        tacticalWindow.contentView = NSHostingView(rootView: tacticalView)
        tacticalWindow.standardWindowButton(NSWindow.ButtonType.closeButton)?.isHidden = true
        
        //The title name impacts the keypress location algorithm, see NSCommmandedWindow
        tacticalWindow.title = "Tactical"
        
        tacticalWindow.makeKeyAndOrderFront(nil)*/
        
        /*strategicWindow = NSCommandedWindow(
            contentRect: NSRect(x: 500, y: 800, width: 500, height: 500),
            styleMask: [.titled, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        //strategicWindow.center()
        strategicWindow.setFrameAutosaveName("Strategic5")
        
        //The title name impacts the keypress location algorithm, see NSCommmandedWindow
        strategicWindow.title = "Strategic"
        strategicWindow.standardWindowButton(NSWindow.ButtonType.closeButton)?.isHidden = true

        strategicWindow.contentView = NSHostingView(rootView: strategicView)
        strategicWindow.makeKeyAndOrderFront(nil)*/

        /*let communicationsView = CommunicationsView()
        communicationsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 320, width: 1000, height: 300),
            styleMask: [.titled, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        //communicationsWindow.center()
        communicationsWindow.setFrameAutosaveName("Communications5")
        communicationsWindow.title = "Communications"
        communicationsWindow.contentView = NSHostingView(rootView: communicationsView)
        communicationsWindow.makeKeyAndOrderFront(nil)
        communicationsWindow.standardWindowButton(NSWindow.ButtonType.closeButton)?.isHidden = true*/
    }
    

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        gameTimerManager?.stopTimer()
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
    @MainActor @IBAction func refreshMetaserverNetrekOrg(_ sender: NSMenuItem) {
        serverConnectionManager?.configureMetaserver(primary: "metaserver.netrek.org", backup: "metaserver1.netrek.org")
        serverConnectionManager?.metaServer?.onMetaserverUpdated = { [weak self] in
            self?.metaserverUpdated()
        }
    }
    @MainActor @IBAction func refreshMetaserver2NetrekOrg(_ sender: NSMenuItem) {
        serverConnectionManager?.configureMetaserver(primary: "metaserver.netrek.org", backup: "metaserver2.netrek.org")
        serverConnectionManager?.metaServer?.onMetaserverUpdated = { [weak self] in
            self?.metaserverUpdated()
        }
    }
    
    func setupBlankMenu() {
        serverMenu.removeAllItems()
        for (index,server) in WELLKNOWNSERVERS.enumerated() {
            let newItem = NSMenuItem(title: server, action: #selector(self.selectWellKnownServer), keyEquivalent: "")
            newItem.tag = index
            serverMenu.addItem(newItem)
        }
        let separator = NSMenuItem.separator()
        serverMenu.addItem(separator)
        let customItem = NSMenuItem(title: "Manually choose server by hostname", action: #selector(self.manualServer), keyEquivalent: "")
        serverMenu.addItem(customItem)
    }

    @MainActor public func metaserverUpdated() {
        //return // for testing blank menu only
        GameLogger.debug("AppDelegate.metaserverUpdated", category: .connection)
        guard let metaServer = serverConnectionManager?.metaServer else { return }
        Universe.universe.gotMessage("Server list updated from metaserver")
        serverMenu.removeAllItems()
        let servers = Array(metaServer.servers.values).map { $0.hostname}.sorted()

        serverByTag = [:]

        for (index,serverName) in servers.enumerated() {
            let newItem: NSMenuItem
            if let server = metaServer.servers[serverName] {
                newItem = NSMenuItem(title: server.description, action: #selector(self.selectServer), keyEquivalent: "")
            } else {
                newItem = NSMenuItem(title: serverName, action: #selector(self.selectServer), keyEquivalent: "")
            }
            newItem.tag = index
            serverByTag[index] = serverName
            serverMenu.addItem(newItem)
        }
        let separator = NSMenuItem.separator()
        serverMenu.addItem(separator)
        let customItem = NSMenuItem(title: "Manually choose server by hostname", action: #selector(self.manualServer), keyEquivalent: "")
        serverMenu.addItem(customItem)
    }
    
    @IBAction func preferences(_ sender: NSMenuItem) {
        //there can only be one preferencesWindow!
        for (index,preferencesWindow) in preferencesWindows.enumerated().reversed() {
            if !preferencesWindow.isVisible {
                preferencesWindows.remove(at: index)
            }
        }
        if let firstPreferencesWindow = preferencesWindows.first {
            firstPreferencesWindow.makeKeyAndOrderFront(nil)
            return
        }
        //No existing preferencesWindows
        let preferencesView = PreferencesView(keymapController: keymapController, preferencesController: preferencesController)
        let preferencesWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        preferencesWindow.center()
        preferencesWindow.isReleasedWhenClosed = false
        preferencesWindow.setFrameAutosaveName("Preferences")
        preferencesWindow.title = "Preferences"
        preferencesWindow.contentView = NSHostingView(rootView: preferencesView)
        preferencesWindow.makeKeyAndOrderFront(nil)
        self.preferencesWindows.append(preferencesWindow)
    }
    
    @IBAction func showDetailedStatistics(_ sender: NSMenuItem) {
        let detailedStatisticsView = DetailedStatisticsView()
        let detailedStatisticsWindow = NSWindow(
            contentRect: NSRect(x: 600, y: 600, width: 600, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        detailedStatisticsWindow.isReleasedWhenClosed = false
        detailedStatisticsWindow.setFrameAutosaveName("Detailed Statistics")
        detailedStatisticsWindow.title = "Detailed Statistics"
        detailedStatisticsWindow.contentView = NSHostingView(rootView: detailedStatisticsView)
        detailedStatisticsWindow.makeKeyAndOrderFront(nil)
        self.detailedStatisticsWindows.append(detailedStatisticsWindow)

    }

    @IBAction func showGameControllerHelp(_ sender: NSMenuItem) {
        // There can only be one game controller help window
        for (index, window) in gameControllerHelpWindows.enumerated().reversed() {
            if !window.isVisible {
                gameControllerHelpWindows.remove(at: index)
            }
        }
        if let firstWindow = gameControllerHelpWindows.first {
            firstWindow.makeKeyAndOrderFront(nil)
            return
        }

        let gameControllerHelpView = GameControllerHelpView()
        let gameControllerHelpWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        gameControllerHelpWindow.center()
        gameControllerHelpWindow.isReleasedWhenClosed = false
        gameControllerHelpWindow.setFrameAutosaveName("Game Controller Help")
        gameControllerHelpWindow.title = "Game Controller Help"
        gameControllerHelpWindow.contentView = NSHostingView(rootView: gameControllerHelpView)
        gameControllerHelpWindow.makeKeyAndOrderFront(nil)
        self.gameControllerHelpWindows.append(gameControllerHelpWindow)
    }

    @IBAction func setLoginInformation(_ sender: NSMenuItem) {
        // there can only be one loginWindow!
        for (index,loginWindow) in loginWindows.enumerated().reversed() {
            if !loginWindow.isVisible {
                loginWindows.remove(at: index)
            }
        }
        if let firstLoginWindow = loginWindows.first {
            firstLoginWindow.makeKeyAndOrderFront(nil)
            return
        }
        // No existing loginwindows
        let loginView = LoginView(loginName: loginInformationController.loginName,loginPassword: loginInformationController.loginPassword, userInfo: loginInformationController.userInfo, loginInformationController: loginInformationController)
        let loginWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        loginWindow.isReleasedWhenClosed = false
        loginWindow.setFrameAutosaveName("Login Information")
        loginWindow.title = "Login Information"
        loginWindow.contentView = NSHostingView(rootView: loginView)
        loginWindow.makeKeyAndOrderFront(nil)
        self.loginWindows.append(loginWindow)
    }

    @objc func manualServer(sender: NSMenuItem) {
        // There can only be one manualServerWindow!
        for (index,manualServerWindow) in manualServerWindows.enumerated().reversed() {
            if !manualServerWindow.isVisible {
                manualServerWindows.remove(at: index)
            }
        }
        if let firstManualServerWindow = manualServerWindows.first {
            firstManualServerWindow.makeKeyAndOrderFront(nil)
            return
        }
        // No existing loginwindows

        let manualServerView = ManualServerView()
            .environmentObject(serverConnectionManager!)
            .environmentObject(gameStateManager!)
        let manualServerWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        manualServerWindow.center()
        manualServerWindow.isReleasedWhenClosed = false
        manualServerWindow.setFrameAutosaveName("Manual Server")
        manualServerWindow.title = "Manual Server"
        manualServerWindow.contentView = NSHostingView(rootView: manualServerView)
        manualServerWindow.makeKeyAndOrderFront(nil)
        self.manualServerWindows.append(manualServerWindow)
    }
    
    @MainActor public func connectToServer(server: String) {
        guard self.gameState == .noServerSelected || self.gameState == .serverSelected else {
            GameLogger.debug("Can only connect if not connected", category: .connection)
            return
        }
        if serverConnectionManager?.connectToServer(hostname: server, port: 2592) != true {
            GameLogger.error("AppDelegate failed to start reader", category: .connection)
        }
    }

    @MainActor @objc func selectWellKnownServer(sender: NSMenuItem) {
        let tag = sender.tag
        if let server = WELLKNOWNSERVERS[safe: tag] {
            print("starting game server \(server)")
            serverConnectionManager?.resetConnection()
            if serverConnectionManager?.connectToServer(hostname: server) != true {
                GameLogger.error("AppDelegate failed to start reader", category: .connection)
            }
        }
    }

    @MainActor @objc func selectServer(sender: NSMenuItem) {
        let tag = sender.tag
        if let serverName = serverByTag[tag] {
            print("starting game server \(serverName)")
            serverConnectionManager?.resetConnection()
            if serverConnectionManager?.connectToServerFromMetaserver(hostname: serverName) != true {
                GameLogger.error("AppDelegate failed to start reader", category: .connection)
            }
        }
    }
    
    private func disableShipMenu() {
        DispatchQueue.main.async {
            GameLogger.debug("disable ship menu", category: .ui)
            self.selectShipScout.isEnabled = false
            self.selectShipDestroyer.isEnabled = false
            self.selectShipCruiser.isEnabled = false
            self.selectShipBattleship.isEnabled = false
            self.selectShipAssault.isEnabled = false
            self.selectShipStarbase.isEnabled = false
            self.selectShipBattlecruiser.isEnabled = false
        }
    }
    private func enableShipMenu() {
        DispatchQueue.main.async {
            GameLogger.debug("enable ship menu", category: .ui)
            self.selectShipScout.isEnabled = true
            self.selectShipDestroyer.isEnabled = true
            self.selectShipCruiser.isEnabled = true
            self.selectShipBattleship.isEnabled = true
            self.selectShipAssault.isEnabled = true
            self.selectShipStarbase.isEnabled = true
            self.selectShipBattlecruiser.isEnabled = true
        }
    }
    @IBAction func selectTeam(_ sender: NSMenuItem) {
        let tag = sender.tag
        for team in Team.allCases {
            if tag == team.rawValue {
                self.preferredTeam = team
                self.updateTeamMenu()
            }
        }
    }

    @MainActor func selectShip(ship: ShipType) {
        self.preferredShip = ship
        if self.gameState == .loginAccepted {
            let cpUpdates = MakePacket.cpUpdates()
            serverConnectionManager?.send(content: cpUpdates)
            let cpOutfit = MakePacket.cpOutfit(team: self.preferredTeam, ship: self.preferredShip)
            serverConnectionManager?.send(content: cpOutfit)
        }
        if self.gameState == .gameActive {
            let cpRefit = MakePacket.cpRefit(newShip: self.preferredShip)
            serverConnectionManager?.send(content: cpRefit)
        }
    }
    @MainActor @IBAction func selectShip(_ sender: NSMenuItem) {
        let tag = sender.tag
        for ship in ShipType.allCases {
            if tag == ship.rawValue {
                selectShip(ship: ship)
                return
            }
        }
    }

    
    private func disableServerMenu() {
        DispatchQueue.main.async {
            GameLogger.debug("disable server menu", category: .ui)
            for menuItem in self.serverMenu.items {
                GameLogger.debug("disabling server menu \(menuItem.title)", category: .ui)
                menuItem.isEnabled = false
            }
        }
    }

    private func enableServerMenu() {
        DispatchQueue.main.async {
            GameLogger.debug("enable server menu", category: .ui)
            for menuItem in self.serverMenu.items {
                menuItem.isEnabled = true
            }
        }
    }
    @MainActor func resetConnection() {
        GameLogger.debug("AppDelegate.resetConnection", category: .connection)
        serverConnectionManager?.resetConnection()
    }

    public func updateTeamMenu(mask: UInt8) {
        var fedEligible = true
        var romEligible = true
        var kazariEligible = true
        var oriEligible = true
        if mask & UInt8(Team.federation.rawValue) != 0 {
            self.selectTeamFederation.indentationLevel = 0
        } else {
            self.selectTeamFederation.indentationLevel = 1
            fedEligible = false
        }
        if mask & UInt8(Team.roman.rawValue) != 0 {
            self.selectTeamRoman.indentationLevel = 0
        } else {
            self.selectTeamRoman.indentationLevel = 1
            romEligible = false
        }
        if mask & UInt8(Team.kazari.rawValue) != 0 {
            self.selectTeamKazari.indentationLevel = 0
        } else {
            self.selectTeamKazari.indentationLevel = 1
            kazariEligible = false
        }
        if mask & UInt8(Team.orion.rawValue) != 0 {
            self.selectTeamOrion.indentationLevel = 0
        } else {
            self.selectTeamOrion.indentationLevel = 1
            oriEligible = false
        }
        if !self.initialTeamSet && mask != 0 {
            GameLogger.debug("initial team set", category: .gameState)
            if fedEligible {
                self.preferredTeam = .federation
                self.initialTeamSet = true
                self.updateTeamMenu()
                return
            }
            if romEligible {
                self.preferredTeam = .roman
                self.initialTeamSet = true
                self.updateTeamMenu()
                return
            }
            if kazariEligible {
                self.preferredTeam = .kazari
                self.initialTeamSet = true
                self.updateTeamMenu()
                return
            }
            if oriEligible {
                self.preferredTeam = .orion
                self.initialTeamSet = true
                self.updateTeamMenu()
                return
            }
        }
    }
    private func updateTeamMenu() {
        DispatchQueue.main.async {
            self.selectTeamFederation.state = .off
            self.selectTeamFederation.state = .off
            self.selectTeamRoman.state = .off
            self.selectTeamKazari.state = .off
            self.selectTeamOrion.state = .off
            switch self.preferredTeam {
            case .federation:
                self.selectTeamFederation.state = .on
            case .roman:
                self.selectTeamRoman.state = .on
            case .kazari:
                self.selectTeamKazari.state = .on
            case .orion:
                self.selectTeamOrion.state = .on
            case .independent:
                break
            case .ogg:
                break
            }
        }
    }

    /// Observe GameStateManager and update menus accordingly
    @MainActor private func observeGameState() {
        gameStateCancellable = gameStateManager?.$gameState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                MainActor.assumeIsolated {
                    self?.handleGameStateChange(newState)
                }
            }
    }

    @MainActor private func handleGameStateChange(_ newState: GameState) {
        GameLogger.info("AppDelegate: game state changed to \(newState.rawValue)", category: .gameState)
        self.gameState = newState

        switch newState {
        case .noServerSelected:
            enableServerMenu()
            disableShipMenu()

        case .serverSelected, .serverConnected, .serverSlotFound:
            disableShipMenu()
            disableServerMenu()

        case .loginAccepted:
            enableShipMenu()
            disableServerMenu()

        case .gameActive:
            enableShipMenu()
            disableServerMenu()
        }
    }
}


