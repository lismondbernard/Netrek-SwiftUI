//
//  MockGameStateProvider.swift
//  NetrekTests
//
//  Mock implementation of GameStateProviding for unit tests
//

import Foundation
import Combine
@testable import Netrek

/// Mock game state provider for testing
class MockGameStateProvider: GameStateProviding, ObservableObject {

    // MARK: - GameStateProviding

    @Published var gameState: GameState

    // MARK: - Initialization

    init(gameState: GameState = .noServerSelected) {
        self.gameState = gameState
    }

    // MARK: - Test Helpers

    /// Transition to a new game state
    func transition(to newState: GameState) {
        gameState = newState
    }

    /// Simulate full connection sequence
    func simulateConnection() {
        gameState = .serverSelected
        gameState = .serverConnected
        gameState = .serverSlotFound
        gameState = .loginAccepted
        gameState = .gameActive
    }

    /// Reset to initial state
    func reset() {
        gameState = .noServerSelected
    }
}
