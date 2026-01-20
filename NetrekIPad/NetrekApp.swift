//
//  NetrekApp.swift
//  Netrek2
//
//  Created by Claude Code on 1/18/26.
//  Main app entry point for iPadOS using SwiftUI App lifecycle
//

import SwiftUI

@main
struct NetrekApp: App {
    // Managers with @MainActor for thread safety
    @StateObject private var universe = Universe.universe
    @StateObject private var gameStateManager = GameStateManager()
    @StateObject private var connectionManager: ServerConnectionManager
    @StateObject private var timerManager = GameTimerManager()

    // Shared resources
    private let help = Help()
    private let keymapController: KeymapController
    private let loginInformationController = LoginInformationController()

    // iPad-specific
    @StateObject private var eligibleTeams = EligibleTeams()

    // Legacy AppDelegate for ContentView transition (temporary)
    @StateObject private var legacyAppDelegate: AppDelegate

    init() {
        // Initialize connection manager
        let connManager = ServerConnectionManager(loginInformationController: loginInformationController)
        _connectionManager = StateObject(wrappedValue: connManager)

        // Initialize keymap controller
        self.keymapController = KeymapController()

        // Initialize legacy AppDelegate (temporary for transition)
        let appDelegate = AppDelegate()
        _legacyAppDelegate = StateObject(wrappedValue: appDelegate)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                metaServer: connectionManager.metaServer!,
                universe: universe,
                appDelegate: legacyAppDelegate
            )
            .environmentObject(universe)
            .environmentObject(gameStateManager)
            .environmentObject(connectionManager)
            .environmentObject(timerManager)
            .environmentObject(eligibleTeams)
            .onAppear {
                setupDependencies()
                startApp()
            }
        }
    }

    // Setup bidirectional dependencies between managers
    private func setupDependencies() {
        // Wire up manager dependencies
        gameStateManager.connectionManager = connectionManager
        gameStateManager.help = help

        connectionManager.gameStateManager = gameStateManager

        timerManager.gameStateManager = gameStateManager
        timerManager.connectionManager = connectionManager

        // Configure ViewModelFactory
        ViewModelFactory.shared.configure(
            commandExecutor: keymapController,
            networkSender: connectionManager,
            gameStateProvider: gameStateManager
        )
    }

    // App startup sequence
    private func startApp() {
        // Start metaserver
        connectionManager.refreshMetaserver()

        // Start game timer
        timerManager.startTimer()

        // Auto-connect to localhost in debug builds
        #if DEBUG
        if DEBUG_AUTO_CONNECT_LOCALHOST {
            GameLogger.debug("DEBUG: Auto-connecting to \(DEBUG_SERVER)", category: .ui)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                _ = connectionManager.connectToServer(hostname: DEBUG_SERVER, port: WELLKNOWNPORT)
            }
        }
        #endif
    }
}
