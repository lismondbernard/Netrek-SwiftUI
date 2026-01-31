//
//  NetrekApp.swift
//  NetrekIPad
//
//  SwiftUI App lifecycle entry point for iPadOS
//

import SwiftUI
import GameController

@main
struct NetrekApp: App {
    @UIApplicationDelegateAdaptor(AppDelegateAdaptor.self) var appDelegateAdaptor

    // Managers
    @StateObject private var gameStateManager = GameStateManager()
    @StateObject private var eligibleTeams = EligibleTeams()

    // Non-observable shared resources
    private let help = Help()
    private let keymapController: KeymapController
    private let loginInformationController = LoginInformationController()
    private let messagesController: MessagesController
    private let connectionManager: ServerConnectionManager
    private let timerManager: GameTimerManager
    private let gameControllerManager: GameControllerManager

    init() {
        let keymap = KeymapController()
        self.keymapController = keymap

        let connManager = ServerConnectionManager(loginInformationController: loginInformationController)
        self.connectionManager = connManager

        self.timerManager = GameTimerManager()

        self.messagesController = MessagesController(universe: Universe.universe)

        self.gameControllerManager = GameControllerManager.shared
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(
                metaServer: connectionManager.metaServer!,
                universe: Universe.universe
            )
            .environmentObject(Universe.universe)
            .environmentObject(gameStateManager)
            .environmentObject(connectionManager)
            .environmentObject(eligibleTeams)
            .environment(\.keymapController, keymapController)
            .environment(\.messagesController, messagesController)
            .environment(\.help, help)
            .environment(\.loginInformationController, loginInformationController)
            .onAppear {
                setupDependencies()
                startApp()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                connectionManager.refreshMetaserver()
            case .background:
                gameStateManager.newGameState(.noServerSelected)
            default:
                break
            }
        }
    }

    private func setupDependencies() {
        // Wire manager dependencies
        gameStateManager.connectionManager = connectionManager
        gameStateManager.help = help

        connectionManager.gameStateManager = gameStateManager

        timerManager.gameStateManager = gameStateManager
        timerManager.connectionManager = connectionManager

        // Wire KeymapController
        keymapController.networkSender = connectionManager
        keymapController.gameStateProvider = gameStateManager

        // Wire GameControllerManager
        gameControllerManager.keymapController = keymapController
        gameControllerManager.gameStateProvider = gameStateManager

        // Wire MessagesController
        messagesController.networkSender = connectionManager
        messagesController.gameStateProvider = gameStateManager

        // Wire GameStateManager into Player models
        Universe.universe.wireGameStateManager(gameStateManager)
    }

    private func startApp() {
        // Start game timer
        timerManager.startTimer()

        // Start metaserver refresh
        connectionManager.refreshMetaserver()

        // Start game controller discovery
        GCController.startWirelessControllerDiscovery { }
    }
}

// Minimal AppDelegate adaptor for background/foreground handling
class AppDelegateAdaptor: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}
