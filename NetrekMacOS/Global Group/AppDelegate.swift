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

// @NSApplicationMain - Disabled in favor of SwiftUI App lifecycle (NetrekApp.swift)
class AppDelegate: NSObject, NSApplicationDelegate {
    let defaults = UserDefaults.standard
    let preferencesController = PreferencesController(defaults: UserDefaults.standard)

    let universe = Universe.universe

    let help = Help()

    var serverFeatures: [String] = []
    var clientFeatures: [String] = ["FEATURE_PACKETS", "SHIP_CAP", "SP_GENERIC_32", "TIPS"]

    var everythingWindow: NSWindow!
    var manualServerWindows: [NSWindow] = []
    var preferencesWindows: [NSWindow] = []
    var loginWindows: [NSWindow] = []
    var detailedStatisticsWindows: [NSWindow] = []

    var metaServer: MetaServer?
    var reader: TcpReader?
    private(set) var gameState: GameState = .noServerSelected
    var analyzer: PacketAnalyzer?
    var clientTypeSent = false

    var serverByTag: [Int: String] = [:]

    // set this to true when we first set the preferred team, which we only do once
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

    let timerInterval = 1.0 / Double(UPDATE_RATE)
    var timer: Timer?
    var timerCount = 0

    @IBAction func disconnectGame(_ sender: NSMenuItem) {
        self.newGameState(.noServerSelected)
    }


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Always run in dark mode
        NSApp.appearance = NSAppearance(named: .darkAqua)

        self.keymapController = KeymapController()

        // Configure ViewModelFactory with dependencies
        ViewModelFactory.shared.configure(
            commandExecutor: self.keymapController,
            networkSender: self,
            gameStateProvider: self
        )

        setupBlankMenu()
        metaServer = MetaServer(primary: "metaserver.netrek.org", backup: "metaserver2.netrek.org", port: 3521)
        if let metaServer = metaServer {
            metaServer.update()
        }
        timer = Timer(timeInterval: timerInterval, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        timer?.tolerance = timerInterval / 10.0
        if let timer = timer {
            RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
        }
        self.updateTeamMenu()
        self.disableShipMenu()

        // Create the SwiftUI view that provides the window contents.
        let everythingView = EverythingView(help: help, preferencesController: preferencesController)

        everythingWindow = NSCommandedWindow(contentRect: NSRect(x: 0, y: 800, width: 1000, height: 800), styleMask: [.titled, .miniaturizable, .resizable, .fullSizeContentView],
                                             backing: .buffered, defer: false)
        everythingWindow.setFrameAutosaveName("temp37")
        everythingWindow.contentView = NSHostingView(rootView: everythingView)
        everythingWindow.standardWindowButton(NSWindow.ButtonType.closeButton)?.isHidden = true
        // The title name impacts the keypress location algorithm, see NSCommmandedWindow
        everythingWindow.title = "Netrek"
        everythingWindow.makeKeyAndOrderFront(nil)

        // Auto-connect to localhost in debug builds
        #if DEBUG
        if DEBUG_AUTO_CONNECT_LOCALHOST {
            GameLogger.info("DEBUG: Auto-connecting to \(DEBUG_SERVER)", category: .connection)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.connectToServer(server: DEBUG_SERVER)
            }
        }
        #endif
    }


    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: METASERVER
    func refreshMetaserver() {
        if let metaServer = metaServer {
            metaServer.update()
        }
    }
    @IBAction func refreshMetaserverNetrekOrg(_ sender: NSMenuItem) {
        metaServer = MetaServer(primary: "metaserver.netrek.org", backup: "metaserver1.netrek.org", port: 3521)
        if let metaServer = metaServer {
            metaServer.update()
        }
    }
    @IBAction func refreshMetaserver2NetrekOrg(_ sender: NSMenuItem) {
        metaServer = MetaServer(primary: "metaserver.netrek.org", backup: "metaserver2.netrek.org", port: 3521)
        if let metaServer = metaServer {
            metaServer.update()
        }
    }

    func setupBlankMenu() {
        serverMenu.removeAllItems()
        for (index, server) in WELLKNOWNSERVERS.enumerated() {
            let newItem = NSMenuItem(title: server, action: #selector(self.selectWellKnownServer), keyEquivalent: "")
            newItem.tag = index
            serverMenu.addItem(newItem)
        }
        let separator = NSMenuItem.separator()
        serverMenu.addItem(separator)
        let customItem = NSMenuItem(title: "Manually choose server by hostname", action: #selector(self.manualServer), keyEquivalent: "")
        serverMenu.addItem(customItem)
    }

    func metaserverUpdated() {
        GameLogger.debug("AppDelegate.metaserverUpdated", category: .ui)
        if let metaServer = metaServer {
            Universe.universe.gotMessage("Server list updated from metaserver")
            serverMenu.removeAllItems()
            let servers = Array(metaServer.servers.values).map { $0.hostname }.sorted()

            serverByTag = [:]

            for (index, serverName) in servers.enumerated() {
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
    }

    @IBAction func preferences(_ sender: NSMenuItem) {
        for (index, preferencesWindow) in preferencesWindows.enumerated().reversed() where !preferencesWindow.isVisible {
            preferencesWindows.remove(at: index)
        }
        if let firstPreferencesWindow = preferencesWindows.first {
            firstPreferencesWindow.makeKeyAndOrderFront(nil)
            return
        }
        // No existing preferencesWindows
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

    @IBAction func setLoginInformation(_ sender: NSMenuItem) {
        // there can only be one loginWindow!
        for (index, loginWindow) in loginWindows.enumerated().reversed() where !loginWindow.isVisible {
            loginWindows.remove(at: index)
        }
        if let firstLoginWindow = loginWindows.first {
            firstLoginWindow.makeKeyAndOrderFront(nil)
            return
        }
        // No existing loginwindows
        let loginView = LoginView(loginName: loginInformationController.loginName, loginPassword: loginInformationController.loginPassword, userInfo: loginInformationController.userInfo, loginInformationController: loginInformationController)
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
        for (index, manualServerWindow) in manualServerWindows.enumerated().reversed() where !manualServerWindow.isVisible {
            manualServerWindows.remove(at: index)
        }
        if let firstManualServerWindow = manualServerWindows.first {
            firstManualServerWindow.makeKeyAndOrderFront(nil)
            return
        }
        // No existing loginwindows

        let manualServerView = ManualServerView()
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

    func connectToServer(server: String) {
        guard self.gameState == .noServerSelected || self.gameState == .serverSelected else {
            GameLogger.debug("Can only connect if not connected", category: .ui)
            return
        }
        if let reader = TcpReader(hostname: server, port: 2592, delegate: self) {
               self.reader = reader
               self.newGameState(.serverSelected)
           } else {
               GameLogger.debug("AppDelegate failed to start reader", category: .ui)
           }
    }

    @objc func selectWellKnownServer(sender: NSMenuItem) {
        let tag = sender.tag
        if let server = WELLKNOWNSERVERS[safe: tag] {
            GameLogger.debug("starting game server \(server)", category: .ui)
           if reader != nil {
               self.resetConnection()
           }
           if let reader = TcpReader(hostname: server, port: WELLKNOWNPORT, delegate: self) {
               self.reader = reader
               self.newGameState(.serverSelected)
           } else {
               GameLogger.debug("AppDelegate failed to start reader", category: .ui)
           }
       }
    }

    @objc func selectServer(sender: NSMenuItem) {
        let tag = sender.tag
        if let serverName = serverByTag[tag], let server = metaServer?.servers[serverName] {
            GameLogger.debug("starting game server \(server.description)", category: .ui)
            if reader != nil {
                self.resetConnection()
            }
            if let reader = TcpReader(hostname: server.hostname, port: server.port, delegate: self) {
                self.reader = reader
                self.newGameState(.serverSelected)
            } else {
                GameLogger.debug("AppDelegate failed to start reader", category: .ui)
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
        for team in Team.allCases where tag == team.rawValue {
            self.preferredTeam = team
            self.updateTeamMenu()
        }
    }

    func selectShip(ship: ShipType) {
        self.preferredShip = ship
        if self.gameState == .loginAccepted {
            if let reader = self.reader {
                let cpUpdates = MakePacket.cpUpdates()
                    reader.send(content: cpUpdates)
                let cpOutfit = MakePacket.cpOutfit(team: self.preferredTeam, ship: self.preferredShip)
                reader.send(content: cpOutfit)
            }
        }
        if self.gameState == .gameActive {
            if let reader = self.reader {
                let cpRefit = MakePacket.cpRefit(newShip: self.preferredShip)
                reader.send(content: cpRefit)
            }
        }
    }
    @IBAction func selectShip(_ sender: NSMenuItem) {
        let tag = sender.tag
        for ship in ShipType.allCases where tag == ship.rawValue {
            selectShip(ship: ship)
            return
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

    func updateTeamMenu(mask: UInt8) {
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
            GameLogger.debug("initial team set", category: .ui)
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

    @objc func timerFired() {
        timerCount += 1
        // GameLogger.debug("AppDelegate.timerFired \(Date())", category: .ui)
        // self.universe.objectWillChange.send()
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
                // send cpUpdate once every 10 seconds to prevent ghostbust
                let cpUpdates = MakePacket.cpUpdates()
                reader?.send(content: cpUpdates)
            }
        }
    }


    func newGameState(_ newState: GameState ) {
        GameLogger.info("Game State: moving from \(self.gameState.rawValue) to \(newState.rawValue)\n", category: .gameState)
        switch newState {
        case .noServerSelected:
            self.resetConnection()
            help.nextTip()
            Universe.universe.reset()
            enableServerMenu()
            disableShipMenu()
            self.gameState = newState
            Universe.universe.gotMessage("AppDelegate GameState \(newState) we may have been ghostbusted!  Resetting.  Try again\n")
            GameLogger.warning("AppDelegate GameState \(newState) we may have been ghostbusted!  Resetting.  Try again\n", category: .gameState)
            self.refreshMetaserver()
        case .serverSelected:
            help.nextTip()
            disableShipMenu()
            disableServerMenu()
            self.gameState = newState
            // PacketAnalyzer creation moved to ServerConnectionManager
            // self.analyzer = PacketAnalyzer(connectionManager: nil)
            // no need to do anything here, handled in the menu function

        case .serverConnected:
            help.nextTip()
            disableShipMenu()
            disableServerMenu()
            self.clientTypeSent = false
            self.gameState = newState

            guard let reader = reader else {
                self.newGameState(.noServerSelected)
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

        case .serverSlotFound:
            disableShipMenu()
            disableServerMenu()
            self.gameState = newState
            GameLogger.debug("AppDelegate.newGameState: .serverSlotFound", category: .gameState)
            let cpLogin: Data
            if self.loginInformationController.loginAuthenticated == true && self.loginInformationController.validInfo {
                cpLogin = MakePacket.cpLogin(name: self.loginInformationController.loginName, password: self.loginInformationController.loginPassword, login: self.loginInformationController.userInfo)
            } else {
                cpLogin = MakePacket.cpLogin(name: "guest", password: "", login: "")
            }
            if let reader = reader {
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.2) {
                    reader.send(content: cpLogin)
                }
            } else {
                GameLogger.error("ERROR: AppDelegate.newGameState.serverSlot found: no reader", category: .gameState)
                self.newGameState(.noServerSelected)
            }
        case .loginAccepted:
            help.nextTip()
            self.enableShipMenu()
            self.disableServerMenu()
            self.gameState = newState

        case .gameActive:
            help.noTip()
            self.enableShipMenu()
            self.disableServerMenu()
            self.gameState = newState
            if !clientTypeSent {
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
                let data = MakePacket.cpMessage(message: "I am using the Swift Netrek Client version \(appVersion) build \(buildVersion) on MacOS", team: .ogg, individual: 0)
                    clientTypeSent = true
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
    // gameState is already a property on AppDelegate
}
