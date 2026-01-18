//
//  GameCommandProtocols.swift
//  Netrek
//
//  Created for MVVM refactoring
//

import Foundation
import CoreGraphics

// MARK: - NetworkSending Protocol

/// Protocol for sending network data to the game server
/// Abstracts the network layer for testability
protocol NetworkSending: AnyObject {
    func send(content: Data)
}

// MARK: - GameCommandExecuting Protocol

/// Protocol for executing game commands
/// Used to abstract keyboard/mouse input handling
protocol GameCommandExecuting: AnyObject {
    /// Execute a control action (keyboard/mouse input)
    /// - Parameters:
    ///   - control: The control type to execute
    ///   - location: Optional game world location for positional commands
    func execute(_ control: Control, location: CGPoint?)
}

// MARK: - GameStateProviding Protocol

/// Protocol for providing game state information
/// Used to abstract the AppDelegate's game state management
protocol GameStateProviding: ObservableObject {
    var gameState: GameState { get }
}
