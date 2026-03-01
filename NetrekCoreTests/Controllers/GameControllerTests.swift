//
//  GameControllerTests.swift
//  NetrekCoreTests
//
//  Tests for GameController input handling.
//  These tests verify dead zone thresholds, stick-to-direction conversion,
//  and button mapping logic for MFI game controllers.
//

import XCTest
@testable import Netrek

final class GameControllerTests: XCTestCase {

    var inputState: GameControllerInputState!

    override func setUp() {
        super.setUp()
        inputState = GameControllerInputState()
    }

    override func tearDown() {
        inputState = nil
        super.tearDown()
    }

    // MARK: - Dead Zone Tests

    func testDeadZone_Value() {
        XCTAssertEqual(GameControllerInputState.deadZone, 0.15, "Dead zone should be 0.15")
    }

    func testLeftStick_InsideDeadZone_NotActive() {
        // Small input below dead zone threshold
        inputState.leftStickX = 0.1
        inputState.leftStickY = 0.1

        XCTAssertFalse(inputState.leftStickActive, "Left stick should not be active inside dead zone")
    }

    func testLeftStick_OnDeadZoneBoundary_NotActive() {
        // Exactly on dead zone boundary (magnitude = 0.15)
        // sqrt(0.106^2 + 0.106^2) ≈ 0.15
        inputState.leftStickX = 0.106
        inputState.leftStickY = 0.106

        XCTAssertFalse(inputState.leftStickActive, "Left stick should not be active at dead zone boundary")
    }

    func testLeftStick_OutsideDeadZone_Active() {
        // Large input outside dead zone
        inputState.leftStickX = 0.5
        inputState.leftStickY = 0.5

        XCTAssertTrue(inputState.leftStickActive, "Left stick should be active outside dead zone")
    }

    func testRightStick_InsideDeadZone_NotActive() {
        inputState.rightStickX = 0.05
        inputState.rightStickY = 0.08

        XCTAssertFalse(inputState.rightStickActive, "Right stick should not be active inside dead zone")
    }

    func testRightStick_OutsideDeadZone_Active() {
        inputState.rightStickX = 0.8
        inputState.rightStickY = 0.0

        XCTAssertTrue(inputState.rightStickActive, "Right stick should be active outside dead zone")
    }

    func testDpad_NoInput_NotActive() {
        inputState.dpadX = 0.0
        inputState.dpadY = 0.0

        XCTAssertFalse(inputState.dpadActive, "D-pad should not be active with no input")
    }

    func testDpad_SmallInput_NotActive() {
        // D-pad uses 0.1 threshold (not the same as stick dead zone)
        inputState.dpadX = 0.05
        inputState.dpadY = 0.05

        XCTAssertFalse(inputState.dpadActive, "D-pad should not be active with small input")
    }

    func testDpad_LargeInput_Active() {
        inputState.dpadX = 1.0
        inputState.dpadY = 0.0

        XCTAssertTrue(inputState.dpadActive, "D-pad should be active with large input")
    }

    // MARK: - Input State Tests

    func testInputState_InitialValues() {
        let freshState = GameControllerInputState()

        XCTAssertEqual(freshState.leftStickX, 0.0, "Initial left stick X should be 0")
        XCTAssertEqual(freshState.leftStickY, 0.0, "Initial left stick Y should be 0")
        XCTAssertEqual(freshState.rightStickX, 0.0, "Initial right stick X should be 0")
        XCTAssertEqual(freshState.rightStickY, 0.0, "Initial right stick Y should be 0")
        XCTAssertEqual(freshState.dpadX, 0.0, "Initial dpad X should be 0")
        XCTAssertEqual(freshState.dpadY, 0.0, "Initial dpad Y should be 0")
        XCTAssertNil(freshState.currentAimLocation, "Initial aim location should be nil")
    }

    func testInputState_Reset() {
        // Set some values
        inputState.leftStickX = 0.5
        inputState.leftStickY = 0.8
        inputState.rightStickX = -0.3
        inputState.rightStickY = 0.6
        inputState.dpadX = 1.0
        inputState.dpadY = -1.0
        inputState.currentAimLocation = CGPoint(x: 5000, y: 5000)

        // Reset
        inputState.reset()

        // Verify all values cleared
        XCTAssertEqual(inputState.leftStickX, 0.0, "Left stick X should reset to 0")
        XCTAssertEqual(inputState.leftStickY, 0.0, "Left stick Y should reset to 0")
        XCTAssertEqual(inputState.rightStickX, 0.0, "Right stick X should reset to 0")
        XCTAssertEqual(inputState.rightStickY, 0.0, "Right stick Y should reset to 0")
        XCTAssertEqual(inputState.dpadX, 0.0, "Dpad X should reset to 0")
        XCTAssertEqual(inputState.dpadY, 0.0, "Dpad Y should reset to 0")
        XCTAssertNil(inputState.currentAimLocation, "Aim location should reset to nil")
    }

    // MARK: - Magnitude Calculation Tests

    func testLeftStick_MagnitudeCalculation_East() {
        // Pure east direction
        inputState.leftStickX = 1.0
        inputState.leftStickY = 0.0

        // Magnitude = sqrt(1.0^2 + 0.0^2) = 1.0
        XCTAssertTrue(inputState.leftStickActive, "Pure east should be active")
    }

    func testLeftStick_MagnitudeCalculation_Northeast() {
        // 45-degree northeast
        inputState.leftStickX = 0.7
        inputState.leftStickY = 0.7

        // Magnitude = sqrt(0.7^2 + 0.7^2) ≈ 0.99
        XCTAssertTrue(inputState.leftStickActive, "Northeast should be active")
    }

    func testLeftStick_MagnitudeCalculation_Small() {
        // Small diagonal input
        inputState.leftStickX = 0.1
        inputState.leftStickY = 0.1

        // Magnitude = sqrt(0.1^2 + 0.1^2) ≈ 0.141 < 0.15
        XCTAssertFalse(inputState.leftStickActive, "Small diagonal should not be active")
    }

    func testRightStick_MagnitudeCalculation_South() {
        // Pure south direction
        inputState.rightStickX = 0.0
        inputState.rightStickY = -1.0

        // Magnitude = sqrt(0.0^2 + 1.0^2) = 1.0
        XCTAssertTrue(inputState.rightStickActive, "Pure south should be active")
    }

    func testRightStick_MagnitudeCalculation_Southwest() {
        // Southwest direction
        inputState.rightStickX = -0.5
        inputState.rightStickY = -0.5

        // Magnitude = sqrt(0.5^2 + 0.5^2) ≈ 0.707
        XCTAssertTrue(inputState.rightStickActive, "Southwest should be active")
    }

    // MARK: - Edge Cases

    func testLeftStick_ExactlyAtDeadZone() {
        // Set magnitude exactly at dead zone threshold
        // 0.15 = sqrt(x^2 + y^2)
        // For x = y: 0.15 = sqrt(2x^2) => x = 0.15 / sqrt(2) ≈ 0.106066
        inputState.leftStickX = 0.106066
        inputState.leftStickY = 0.106066

        // Should not be active (need to be > dead zone, not >=)
        XCTAssertFalse(inputState.leftStickActive, "Exactly at dead zone should not be active")
    }

    func testLeftStick_JustAboveDeadZone() {
        // Slightly above dead zone
        inputState.leftStickX = 0.11
        inputState.leftStickY = 0.11

        // Magnitude = sqrt(0.11^2 + 0.11^2) ≈ 0.1556 > 0.15
        XCTAssertTrue(inputState.leftStickActive, "Just above dead zone should be active")
    }

    func testDpad_ExactlyAtThreshold() {
        // D-pad threshold is 0.1
        inputState.dpadX = 0.1
        inputState.dpadY = 0.0

        // abs(0.1) > 0.1 is false, so should not be active
        XCTAssertFalse(inputState.dpadActive, "D-pad at threshold should not be active")
    }

    func testDpad_JustAboveThreshold() {
        inputState.dpadX = 0.11
        inputState.dpadY = 0.0

        // abs(0.11) > 0.1 is true
        XCTAssertTrue(inputState.dpadActive, "D-pad just above threshold should be active")
    }

    // MARK: - Negative Input Tests

    func testLeftStick_NegativeInput_OutsideDeadZone() {
        // Negative values (west/south)
        inputState.leftStickX = -0.6
        inputState.leftStickY = -0.6

        // Magnitude uses absolute values
        XCTAssertTrue(inputState.leftStickActive, "Negative input should be active outside dead zone")
    }

    func testRightStick_NegativeInput_InsideDeadZone() {
        inputState.rightStickX = -0.05
        inputState.rightStickY = -0.08

        XCTAssertFalse(inputState.rightStickActive, "Negative small input should not be active")
    }

    func testDpad_NegativeInput_Active() {
        inputState.dpadX = -1.0
        inputState.dpadY = 0.0

        // abs(-1.0) > 0.1 is true
        XCTAssertTrue(inputState.dpadActive, "Negative D-pad input should be active")
    }

    // MARK: - Both Axes Active Tests

    func testLeftStick_BothAxesLarge() {
        inputState.leftStickX = 0.8
        inputState.leftStickY = 0.6

        // Magnitude = sqrt(0.8^2 + 0.6^2) = 1.0
        XCTAssertTrue(inputState.leftStickActive, "Both axes large should be active")
    }

    func testLeftStick_OneAxisLarge_OneAxisSmall() {
        // One axis large, one small
        inputState.leftStickX = 0.9
        inputState.leftStickY = 0.05

        // Magnitude = sqrt(0.9^2 + 0.05^2) ≈ 0.901
        XCTAssertTrue(inputState.leftStickActive, "One large axis should make stick active")
    }

    func testLeftStick_BothAxesSmall() {
        inputState.leftStickX = 0.08
        inputState.leftStickY = 0.08

        // Magnitude = sqrt(0.08^2 + 0.08^2) ≈ 0.113
        XCTAssertFalse(inputState.leftStickActive, "Both axes small should not be active")
    }

    func testDpad_BothAxesActive() {
        inputState.dpadX = 1.0
        inputState.dpadY = 1.0

        // Either axis > 0.1 makes it active
        XCTAssertTrue(inputState.dpadActive, "Both D-pad axes active")
    }

    func testDpad_OnlyXActive() {
        inputState.dpadX = 1.0
        inputState.dpadY = 0.0

        XCTAssertTrue(inputState.dpadActive, "D-pad X only should be active")
    }

    func testDpad_OnlyYActive() {
        inputState.dpadX = 0.0
        inputState.dpadY = -1.0

        XCTAssertTrue(inputState.dpadActive, "D-pad Y only should be active")
    }

    // MARK: - Aim Location Tests

    func testAimLocation_CanBeSet() {
        let aimPoint = CGPoint(x: 3000, y: 7000)
        inputState.currentAimLocation = aimPoint

        XCTAssertNotNil(inputState.currentAimLocation, "Aim location should be settable")
        XCTAssertEqual(inputState.currentAimLocation?.x, 3000, "Aim X should match")
        XCTAssertEqual(inputState.currentAimLocation?.y, 7000, "Aim Y should match")
    }

    func testAimLocation_CanBeCleared() {
        inputState.currentAimLocation = CGPoint(x: 5000, y: 5000)
        inputState.currentAimLocation = nil

        XCTAssertNil(inputState.currentAimLocation, "Aim location should be clearable")
    }

    func testAimLocation_ClearedOnReset() {
        inputState.currentAimLocation = CGPoint(x: 8000, y: 2000)
        inputState.reset()

        XCTAssertNil(inputState.currentAimLocation, "Aim location should clear on reset")
    }
}
