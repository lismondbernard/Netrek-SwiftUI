//
//  SceneDelegate.swift
//  NetrekIPad
//
//  Created by Darrell Root on 6/6/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    lazy var appDelegate = UIApplication.shared.delegate as! AppDelegate

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Get required components from AppDelegate
        guard let metaServer = appDelegate.metaServer else {
            fatalError("MetaServer should be initialized in AppDelegate before scene connects")
        }

        // Get managers from AppDelegate (these are initialized in AppDelegate.initializeManagers())
        guard let gameStateManager = appDelegate.gameStateManager,
              let connectionManager = appDelegate.serverConnectionManager else {
            fatalError("Managers should be initialized in AppDelegate before scene connects")
        }

        // Create ContentView using environment objects
        let contentView = ContentView(
            metaServer: metaServer,
            universe: Universe.universe
        )
        .environmentObject(Universe.universe)
        .environmentObject(gameStateManager)
        .environmentObject(connectionManager)
        .environmentObject(appDelegate.eligibleTeams)
        .environment(\.keymapController, appDelegate.keymapController)
        .environment(\.messagesController, appDelegate.messagesController)
        .environment(\.help, appDelegate.help)
        .environment(\.loginInformationController, appDelegate.loginInformationController)

        // Use a UIHostingController as window root view controller
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        appDelegate.refreshMetaserver()
        // Called as the scene transitions from the background to the foreground.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        appDelegate.gameStateManager?.newGameState(.noServerSelected)
        // Called as the scene transitions from the foreground to the background.
    }
}
