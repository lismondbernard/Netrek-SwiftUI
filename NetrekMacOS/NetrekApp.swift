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
    @StateObject private var keymapController = KeymapController()
    private let loginInformationController = LoginInformationController()
    @StateObject private var windowManager = WindowManager()

    // State for showing startup modal
    @State private var showingStartupModal = false

    init() {
        // Initialize connection manager
        let connManager = ServerConnectionManager(loginInformationController: loginInformationController)
        _connectionManager = StateObject(wrappedValue: connManager)
    }

    var body: some Scene {
        WindowGroup {
            EverythingView(help: help, preferencesController: preferencesController)
                .environmentObject(universe)
                .environmentObject(gameStateManager)
                .environmentObject(connectionManager)
                .environmentObject(timerManager)
                .environmentObject(keymapController)
                .frame(minWidth: 1200, minHeight: 800)
                .onAppear {
                    setupDependencies()
                    startApp()
                }
                .sheet(isPresented: $showingStartupModal) {
                    StartupModalView(
                        connectionManager: connectionManager,
                        onConnect: {
                            showingStartupModal = false
                        }
                    )
                }
                .sheet(isPresented: $windowManager.showingPreferences) {
                    PreferencesView(keymapController: keymapController, preferencesController: preferencesController)
                        .frame(width: 600, height: 400)
                }
                .sheet(isPresented: $windowManager.showingLogin) {
                    LoginView(
                        loginName: loginInformationController.loginName,
                        loginPassword: loginInformationController.loginPassword,
                        userInfo: loginInformationController.userInfo,
                        loginInformationController: loginInformationController
                    )
                    .frame(width: 400, height: 300)
                }
                .sheet(isPresented: $windowManager.showingStatistics) {
                    DetailedStatisticsView()
                        .environmentObject(universe)
                        .frame(width: 800, height: 600)
                }
                .sheet(isPresented: $windowManager.showingManualServer) {
                    ManualServerView()
                        .environmentObject(connectionManager)
                        .frame(width: 500, height: 150)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            NetrekCommands(
                connectionManager: connectionManager,
                gameStateManager: gameStateManager,
                windowManager: windowManager
            )
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

        // Wire up keymapController dependencies
        keymapController.connectionManager = connectionManager
        keymapController.gameStateManager = gameStateManager

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

        // Auto-connect to localhost in debug builds, or show modal
        #if DEBUG
        if DEBUG_AUTO_CONNECT_LOCALHOST {
            GameLogger.debug("DEBUG: Auto-connecting to \(DEBUG_SERVER)", category: .ui)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                _ = connectionManager.connectToServer(hostname: DEBUG_SERVER, port: WELLKNOWNPORT)
            }
        } else {
            // Show startup modal after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingStartupModal = true
            }
        }
        #else
        // Show startup modal in release builds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showingStartupModal = true
        }
        #endif
    }
}

// Manages window presentation state
@MainActor
class WindowManager: ObservableObject {
    @Published var showingPreferences = false
    @Published var showingLogin = false
    @Published var showingStatistics = false
    @Published var showingManualServer = false
}
