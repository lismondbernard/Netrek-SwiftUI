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
    private let keymapController = KeymapController()
    private let loginInformationController = LoginInformationController()
    @StateObject private var windowManager = WindowManager()

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
                .environment(\.keymapController, keymapController)
                // Publish focused values for Commands to read reactively
                .focusedValue(\.gameState, gameStateManager.gameState)
                .focusedValue(\.gameStateManager, gameStateManager)
                .focusedValue(\.connectionManager, connectionManager)
                .focusedValue(\.windowManager, windowManager)
                .frame(minWidth: 1200, minHeight: 800)
                .onAppear {
                    setupDependencies()
                    startApp()
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
                .sheet(isPresented: $windowManager.showingGameControllerHelp) {
                    GameControllerHelpView()
                        .frame(width: 500, height: 600)
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

        // Wire up keymapController dependencies
        keymapController.networkSender = connectionManager
        keymapController.gameStateProvider = gameStateManager
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
    }
}
