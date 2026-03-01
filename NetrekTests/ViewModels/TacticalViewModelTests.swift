//
//  TacticalViewModelTests.swift
//  NetrekTests
//
//  Unit tests for TacticalViewModel
//

import XCTest
@testable import Netrek

@MainActor
final class TacticalViewModelTests: XCTestCase {

    var sut: TacticalViewModel!
    var mockCommandExecutor: MockCommandExecutor!

    override func setUp() async throws {
        try await super.setUp()
        mockCommandExecutor = MockCommandExecutor()

        // Reset universe to known state
        let universe = Universe.universe
        universe.me = 0

        sut = TacticalViewModel(universe: universe, commandExecutor: mockCommandExecutor)
    }

    override func tearDown() async throws {
        sut = nil
        mockCommandExecutor = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization_SetsDefaultValues() {
        // Then
        XCTAssertNotNil(sut.me)
        XCTAssertEqual(sut.visualWidth, Universe.universe.visualWidth)
    }

    func testInitialization_WithoutCommandExecutor() {
        // When
        let viewModel = TacticalViewModel(universe: .universe, commandExecutor: nil)

        // Then
        XCTAssertNotNil(viewModel)
    }

    // MARK: - Command Execution Tests

    func testExecuteControl_CallsCommandExecutor() {
        // Given
        let location = CGPoint(x: 100, y: 200)

        // When - use pKey for phaser
        sut.executeControl(.pKey, at: location)

        // Then
        XCTAssertTrue(mockCommandExecutor.didExecuteCommand)
        XCTAssertEqual(mockCommandExecutor.executeCallCount, 1)
        XCTAssertEqual(mockCommandExecutor.lastExecutedCommand?.control, .pKey)
        XCTAssertEqual(mockCommandExecutor.lastExecutedCommand?.location, location)
    }

    func testExecuteControl_MultipleCommands() {
        // Given
        let location1 = CGPoint(x: 100, y: 100)
        let location2 = CGPoint(x: 200, y: 200)

        // When - use pKey for phaser, tKey for torpedo
        sut.executeControl(.pKey, at: location1)
        sut.executeControl(.tKey, at: location2)

        // Then
        XCTAssertEqual(mockCommandExecutor.executeCallCount, 2)
        XCTAssertTrue(mockCommandExecutor.didExecute(control: .pKey))
        XCTAssertTrue(mockCommandExecutor.didExecute(control: .tKey))
    }

    func testExecuteControl_WithNilCommandExecutor_DoesNotCrash() {
        // Given
        let viewModel = TacticalViewModel(universe: .universe, commandExecutor: nil)

        // When/Then - should not crash
        viewModel.executeControl(.pKey, at: CGPoint(x: 0, y: 0))
    }

    // MARK: - Coordinate Conversion Tests

    func testGamePosition_CenterOfScreen_ReturnsPlayerPosition() {
        // Given
        let screenSize = CGSize(width: 800, height: 600)
        let screenCenter = CGPoint(x: 400, y: 300)

        // When
        let gamePosition = sut.gamePosition(from: screenCenter, screenSize: screenSize)

        // Then - should be approximately at player's position
        let playerX = CGFloat(sut.me.positionX)
        let playerY = CGFloat(sut.me.positionY)

        // Allow some tolerance for integer rounding
        XCTAssertEqual(gamePosition.x, playerX, accuracy: 10)
        XCTAssertEqual(gamePosition.y, playerY, accuracy: 10)
    }

    // MARK: - Display Size Calculation Tests

    func testPlanetWidth_ReturnsPositiveValue() {
        // When
        let width = sut.planetWidth(screenWidth: 800)

        // Then
        XCTAssertGreaterThan(width, 0)
    }

    func testPlayerWidth_ReturnsPositiveValue() {
        // When
        let width = sut.playerWidth(screenWidth: 800)

        // Then
        XCTAssertGreaterThan(width, 0)
    }

    func testTorpedoWidth_ReturnsPositiveValue() {
        // When
        let width = sut.torpedoWidth(screenWidth: 800)

        // Then
        XCTAssertGreaterThan(width, 0)
    }

    func testPlasmaWidth_ReturnsPositiveValue() {
        // When
        let width = sut.plasmaWidth(screenWidth: 800)

        // Then
        XCTAssertGreaterThan(width, 0)
    }

    func testWidths_ScaleWithScreenSize() {
        // Given
        let smallScreen: CGFloat = 400
        let largeScreen: CGFloat = 800

        // When
        let smallPlanet = sut.planetWidth(screenWidth: smallScreen)
        let largePlanet = sut.planetWidth(screenWidth: largeScreen)

        // Then - larger screen should have larger planet
        XCTAssertGreaterThan(largePlanet, smallPlanet)
    }
}
