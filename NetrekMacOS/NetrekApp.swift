//
//  NetrekApp.swift
//  Netrek2
//
//  Created by Claude Code on 1/18/26.
//  Main app entry point for macOS using SwiftUI App lifecycle
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
    private let preferencesController = PreferencesController(defaults: UserDefaults.standard)
    private let keymapController: KeymapController
    private let loginInformationController = LoginInformationController()

    init() {
        // Initialize connection manager
        let connManager = ServerConnectionManager(loginInformationController: loginInformationController)
        _connectionManager = StateObject(wrappedValue: connManager)

        // Initialize keymap controller
        self.keymapController = KeymapController()
    }

    var body: some Scene {
        WindowGroup {
            EverythingView(help: help, preferencesController: preferencesController)
                .environmentObject(universe)
                .environmentObject(gameStateManager)
                .environmentObject(connectionManager)
                .environmentObject(timerManager)
                .frame(minWidth: 1200, minHeight: 800)
                .onAppear {
                    setupDependencies()
                    startApp()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            NetrekCommands()
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
        // Force dark mode - safe to do here when app is fully initialized
        if let darkAppearance = NSAppearance(named: .darkAqua) {
            NSApp.appearance = darkAppearance
        }

        // Start metaserver
        connectionManager.refreshMetaserver()

        // Start game timer
        timerManager.startTimer()

        // Auto-connect to localhost in debug builds
        #if DEBUG
        if DEBUG_AUTO_CONNECT_LOCALHOST {
            debugPrint("DEBUG: Auto-connecting to \(DEBUG_SERVER)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                _ = connectionManager.connectToServer(hostname: DEBUG_SERVER, port: WELLKNOWNPORT)
            }
        }
        #endif
    }
}
