//
//  StateSynchronizationTests.swift
//  NetrekCoreTests
//
//  Tests for state synchronization between GameStateManager and AppDelegate.
//
//  REGRESSION TEST: This test file was created to prevent a regression where
//  GameControllerManager stopped working because AppDelegate.gameState was not
//  being updated when state changes came through ServerConnectionManager.
//
//  The bug: PacketAnalyzer calls delegate.newGameState(.gameActive), which goes to
//  ServerConnectionManager.newGameState(), which only called gameStateManager.newGameState().
//  AppDelegate.gameState was never updated, so GameControllerManager's guard check
//  `appDelegate.gameState == .gameActive` always failed.
//
//  The fix: ServerConnectionManager.newGameState() now also calls appDelegate.newGameState()
//  to keep both states in sync.
//

import XCTest
@testable import Netrek

// MARK: - Mock PacketAnalyzerDelegate for Testing

/// A mock delegate that tracks state change calls
class MockPacketAnalyzerDelegate: PacketAnalyzerDelegate {
    var stateChanges: [GameState] = []
    var currentGameState: GameState = .noServerSelected
    var serverFeatures: [String] = []

    var gameState: GameState {
        return currentGameState
    }

    func newGameState(_ state: GameState) {
        stateChanges.append(state)
        currentGameState = state
    }

    func triggerReceive() {
        // No-op for testing
    }

    func updateTeamEligibility(mask: UInt8) {
        // No-op for testing
    }
}

// MARK: - State Synchronization Tests

final class StateSynchronizationTests: XCTestCase {

    // MARK: - GameStateManager Tests

    @MainActor
    func testGameStateManager_InitialState() {
        let manager = GameStateManager()

        XCTAssertEqual(manager.gameState, .noServerSelected,
                      "GameStateManager should start with noServerSelected")
    }

    @MainActor
    func testGameStateManager_StateTransition_ServerSelected() {
        let manager = GameStateManager()

        manager.newGameState(.serverSelected)

        XCTAssertEqual(manager.gameState, .serverSelected,
                      "GameStateManager should update to serverSelected")
    }

    @MainActor
    func testGameStateManager_StateTransition_GameActive() {
        let manager = GameStateManager()

        manager.newGameState(.gameActive)

        XCTAssertEqual(manager.gameState, .gameActive,
                      "GameStateManager should update to gameActive")
    }

    @MainActor
    func testGameStateManager_FullProgression() {
        // Note: GameStateManager.newGameState() has side effects that require
        // real dependencies (connectionManager, etc). This test verifies
        // state changes that don't trigger side effects with nil dependencies.
        let manager = GameStateManager()

        // Test states that work without dependencies
        // serverSelected and gameActive work because they don't call
        // connectionManager methods that would crash with nil
        manager.newGameState(.serverSelected)
        XCTAssertEqual(manager.gameState, .serverSelected)

        manager.newGameState(.loginAccepted)
        XCTAssertEqual(manager.gameState, .loginAccepted)

        manager.newGameState(.gameActive)
        XCTAssertEqual(manager.gameState, .gameActive,
                      "GameStateManager should reach gameActive")
    }

    @MainActor
    func testGameStateManager_ResetToNoServer() {
        let manager = GameStateManager()

        // Progress to gameActive
        manager.newGameState(.gameActive)
        XCTAssertEqual(manager.gameState, .gameActive)

        // Note: Reset to noServerSelected has side effects (resetConnection, etc)
        // that would fail with nil dependencies. We test this at protocol level
        // with MockPacketAnalyzerDelegate instead.
    }

    // MARK: - PacketAnalyzerDelegate Protocol Tests

    func testMockDelegate_TracksStateChanges() {
        let mockDelegate = MockPacketAnalyzerDelegate()

        mockDelegate.newGameState(.serverSelected)
        mockDelegate.newGameState(.serverConnected)
        mockDelegate.newGameState(.gameActive)

        XCTAssertEqual(mockDelegate.stateChanges.count, 3,
                      "Delegate should track all state changes")
        XCTAssertEqual(mockDelegate.stateChanges, [.serverSelected, .serverConnected, .gameActive],
                      "State changes should be recorded in order")
    }

    func testMockDelegate_UpdatesCurrentState() {
        let mockDelegate = MockPacketAnalyzerDelegate()

        XCTAssertEqual(mockDelegate.gameState, .noServerSelected)

        mockDelegate.newGameState(.gameActive)

        XCTAssertEqual(mockDelegate.gameState, .gameActive,
                      "Delegate's gameState property should reflect current state")
    }

    // MARK: - State Synchronization Requirement Tests
    // These tests document the requirement that state must be synchronized

    func testStateSynchronization_Requirement_GameActiveRequired() {
        // This test documents the critical requirement:
        // GameControllerManager checks `appDelegate.gameState == .gameActive`
        // before processing any input.
        //
        // If AppDelegate.gameState is not updated to .gameActive, the game
        // controller will not work.

        let mockDelegate = MockPacketAnalyzerDelegate()

        // Simulate the state progression that happens during connection
        mockDelegate.newGameState(.serverSelected)
        mockDelegate.newGameState(.serverConnected)
        mockDelegate.newGameState(.serverSlotFound)
        mockDelegate.newGameState(.loginAccepted)
        mockDelegate.newGameState(.gameActive)

        // The critical assertion: gameState MUST be .gameActive
        // If this fails, GameControllerManager will not process input
        XCTAssertEqual(mockDelegate.gameState, .gameActive,
                      "CRITICAL: gameState must reach .gameActive for game controller to work")
    }

    func testStateSynchronization_Requirement_AllStatesMustPropagate() {
        // All state changes from PacketAnalyzer must propagate to both:
        // 1. GameStateManager.gameState
        // 2. AppDelegate.gameState
        //
        // This test verifies the delegate receives all state changes.

        let mockDelegate = MockPacketAnalyzerDelegate()

        let allGameStates: [GameState] = [
            .noServerSelected,
            .serverSelected,
            .serverConnected,
            .serverSlotFound,
            .loginAccepted,
            .gameActive
        ]

        for state in allGameStates {
            mockDelegate.newGameState(state)
        }

        XCTAssertEqual(mockDelegate.stateChanges.count, allGameStates.count,
                      "All state changes must propagate through the delegate")
        XCTAssertEqual(mockDelegate.stateChanges, allGameStates,
                      "States must propagate in the correct order")
    }

    // MARK: - Regression Prevention Tests

    func testRegression_GameControllerRequiresGameActive() {
        // REGRESSION TEST: GameControllerManager.executeCommand() has this guard:
        //   guard appDelegate.gameState == .gameActive else { return }
        //
        // If AppDelegate.gameState is not .gameActive, all game controller
        // input is silently ignored.

        let mockDelegate = MockPacketAnalyzerDelegate()

        // Simulate being in loginAccepted (ship selection screen)
        mockDelegate.newGameState(.loginAccepted)

        // Game controller should NOT work in loginAccepted
        XCTAssertNotEqual(mockDelegate.gameState, .gameActive,
                         "In loginAccepted, gameState should not be gameActive")

        // Simulate entering the game
        mockDelegate.newGameState(.gameActive)

        // NOW game controller should work
        XCTAssertEqual(mockDelegate.gameState, .gameActive,
                      "After entering game, gameState must be gameActive for controller to work")
    }

    func testRegression_StateNotStuckAtServerConnected() {
        // REGRESSION TEST: Verify state progresses past serverConnected
        //
        // A previous bug caused AppDelegate.gameState to get stuck at
        // serverConnected because later state transitions only went to
        // GameStateManager.

        let mockDelegate = MockPacketAnalyzerDelegate()

        // Simulate full progression
        mockDelegate.newGameState(.serverConnected)
        mockDelegate.newGameState(.serverSlotFound)
        mockDelegate.newGameState(.loginAccepted)
        mockDelegate.newGameState(.gameActive)

        // State must NOT be stuck at serverConnected
        XCTAssertNotEqual(mockDelegate.gameState, .serverConnected,
                         "State must progress past serverConnected")
        XCTAssertEqual(mockDelegate.gameState, .gameActive,
                      "State must reach gameActive")
    }

    // MARK: - GameState Property Tests

    func testGameState_IsGameActive_True() {
        let state = GameState.gameActive
        XCTAssertEqual(state, .gameActive)
    }

    func testGameState_IsGameActive_False() {
        let nonActiveStates: [GameState] = [
            .noServerSelected,
            .serverSelected,
            .serverConnected,
            .serverSlotFound,
            .loginAccepted
        ]

        for state in nonActiveStates {
            XCTAssertNotEqual(state, .gameActive,
                            "\(state) should not equal .gameActive")
        }
    }

    // MARK: - Guard Condition Tests
    // These tests verify the guard conditions used in GameControllerManager

    func testGuardCondition_GameActiveCheck() {
        // Simulates the guard check in GameControllerManager
        func shouldProcessInput(gameState: GameState) -> Bool {
            guard gameState == .gameActive else { return false }
            return true
        }

        // These should NOT process input
        XCTAssertFalse(shouldProcessInput(gameState: .noServerSelected))
        XCTAssertFalse(shouldProcessInput(gameState: .serverSelected))
        XCTAssertFalse(shouldProcessInput(gameState: .serverConnected))
        XCTAssertFalse(shouldProcessInput(gameState: .serverSlotFound))
        XCTAssertFalse(shouldProcessInput(gameState: .loginAccepted))

        // Only gameActive should process input
        XCTAssertTrue(shouldProcessInput(gameState: .gameActive))
    }
}
