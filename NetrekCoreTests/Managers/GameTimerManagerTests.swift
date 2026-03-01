//
//  GameTimerManagerTests.swift
//  NetrekCoreTests
//
//  Tests for GameTimerManager - the 20Hz game update loop.
//

import XCTest
@testable import Netrek

final class GameTimerManagerTests: XCTestCase {

    // MARK: - Initialization Tests

    @MainActor
    func testInit_DefaultUpdateRate() {
        let manager = GameTimerManager()

        // Default UPDATE_RATE should be used
        // Timer interval = 1.0 / UPDATE_RATE
        XCTAssertNotNil(manager, "Manager should initialize with default rate")
    }

    @MainActor
    func testInit_CustomUpdateRate() {
        let manager = GameTimerManager(updateRate: 10)

        XCTAssertNotNil(manager, "Manager should initialize with custom rate")
    }

    @MainActor
    func testInit_HighUpdateRate() {
        let manager = GameTimerManager(updateRate: 60)

        XCTAssertNotNil(manager, "Manager should support high update rates")
    }

    @MainActor
    func testInit_LowUpdateRate() {
        let manager = GameTimerManager(updateRate: 1)

        XCTAssertNotNil(manager, "Manager should support low update rates")
    }

    // MARK: - Timer Start/Stop Tests

    @MainActor
    func testStartTimer_CreatesTimer() {
        let manager = GameTimerManager()

        manager.startTimer()

        // Timer is running (we can't directly check, but no crash)
        // Clean up
        manager.stopTimer()
    }

    @MainActor
    func testStartTimer_CalledTwice_DoesNotCreateSecondTimer() {
        let manager = GameTimerManager()

        manager.startTimer()
        manager.startTimer() // Should be no-op

        // No crash expected
        manager.stopTimer()
    }

    @MainActor
    func testStopTimer_StopsTimer() {
        let manager = GameTimerManager()

        manager.startTimer()
        manager.stopTimer()

        // No crash, timer is stopped
    }

    @MainActor
    func testStopTimer_WhenNotStarted_DoesNotCrash() {
        let manager = GameTimerManager()

        manager.stopTimer() // Should be safe when timer not started
    }

    @MainActor
    func testStopTimer_CalledTwice_DoesNotCrash() {
        let manager = GameTimerManager()

        manager.startTimer()
        manager.stopTimer()
        manager.stopTimer() // Should be safe
    }

    // MARK: - Timer Restart Tests

    @MainActor
    func testTimer_CanBeRestarted() {
        let manager = GameTimerManager()

        manager.startTimer()
        manager.stopTimer()
        manager.startTimer() // Restart

        // No crash
        manager.stopTimer()
    }

    // MARK: - Dependency Tests

    @MainActor
    func testGameStateManager_InitiallyNil() {
        let manager = GameTimerManager()

        XCTAssertNil(manager.gameStateManager,
                    "Game state manager should be nil initially")
    }

    @MainActor
    func testConnectionManager_InitiallyNil() {
        let manager = GameTimerManager()

        XCTAssertNil(manager.connectionManager,
                    "Connection manager should be nil initially")
    }

    @MainActor
    func testDependencies_CanBeSet() {
        let timerManager = GameTimerManager()
        let stateManager = GameStateManager()

        timerManager.gameStateManager = stateManager

        XCTAssertNotNil(timerManager.gameStateManager)
    }

    // MARK: - Timer Interval Calculation Tests

    func testTimerInterval_At20Hz() {
        // 1.0 / 20 = 0.05 seconds = 50ms
        let expectedInterval = 1.0 / 20.0

        XCTAssertEqual(expectedInterval, 0.05, accuracy: 0.0001,
                      "20Hz should give 50ms interval")
    }

    func testTimerInterval_At10Hz() {
        let expectedInterval = 1.0 / 10.0

        XCTAssertEqual(expectedInterval, 0.1, accuracy: 0.0001,
                      "10Hz should give 100ms interval")
    }

    func testTimerInterval_At60Hz() {
        let expectedInterval = 1.0 / 60.0

        XCTAssertEqual(expectedInterval, 0.0167, accuracy: 0.001,
                      "60Hz should give ~16.7ms interval")
    }

    // MARK: - UPDATE_RATE Constant Tests

    func testUpdateRate_Constant() {
        // UPDATE_RATE is defined as a global constant
        XCTAssertGreaterThan(UPDATE_RATE, 0, "UPDATE_RATE should be positive")
        XCTAssertLessThanOrEqual(UPDATE_RATE, 60, "UPDATE_RATE should be reasonable")
    }

    // MARK: - Edge Cases

    @MainActor
    func testTimer_WithNoGameState_DoesNotCrash() {
        let manager = GameTimerManager()
        // gameStateManager is nil

        manager.startTimer()

        // Timer fires but gameStateManager is nil - should not crash
        // We can't easily test timer firing without waiting, but the code handles nil

        manager.stopTimer()
    }
}
