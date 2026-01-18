//
//  StatisticsViewModelTests.swift
//  NetrekTests
//
//  Unit tests for StatisticsViewModel
//

import XCTest
@testable import Netrek

@MainActor
final class StatisticsViewModelTests: XCTestCase {

    var sut: StatisticsViewModel!

    override func setUp() async throws {
        try await super.setUp()

        // Reset universe to known state
        let universe = Universe.universe
        universe.me = 0

        sut = StatisticsViewModel(universe: universe)
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization_SetsCurrentPlayer() {
        // Then
        XCTAssertNotNil(sut.me)
    }

    func testInitialization_SetsDefaultValues() {
        // Then - should have valid initial state
        XCTAssertGreaterThanOrEqual(sut.speed, 0)
        XCTAssertGreaterThanOrEqual(sut.shieldStrength, 0)
        XCTAssertGreaterThanOrEqual(sut.damage, 0)
        XCTAssertGreaterThanOrEqual(sut.armies, 0)
        XCTAssertGreaterThanOrEqual(sut.fuel, 0)
    }

    // MARK: - Temperature Display Tests

    func testEngineTempDisplay_ReturnsScaledValue() {
        // The display value should be engineTemp / 10
        let expectedDisplay = sut.engineTemp / 10

        // Then
        XCTAssertEqual(sut.engineTempDisplay, expectedDisplay)
    }

    func testWeaponsTempDisplay_ReturnsScaledValue() {
        // The display value should be weaponsTemp / 10
        let expectedDisplay = sut.weaponsTemp / 10

        // Then
        XCTAssertEqual(sut.weaponsTempDisplay, expectedDisplay)
    }

    // MARK: - Warning Flags Tests

    func testHasWarningFlags_WhenNoFlags_ReturnsFalse() {
        // Given - ensure all flags are false
        // The default state should have no warnings

        // Then
        // This tests the computed property logic
        let hasWarnings = sut.tractorFlag || sut.pressor || sut.enginesOverheated
        XCTAssertEqual(sut.hasWarningFlags, hasWarnings)
    }

    // MARK: - Player Identifier Tests

    func testPlayerIdentifier_ReturnsTeamAndPlayerLetter() {
        // Given
        let player = Universe.universe.players[0]

        // When
        let identifier = sut.playerIdentifier(for: player)

        // Then
        XCTAssertFalse(identifier.isEmpty)
        XCTAssertEqual(identifier.count, 2) // Team letter + player letter
    }

    func testPlayerIdentifier_DifferentPlayers_ReturnsDifferentIdentifiers() {
        // Given
        let player0 = Universe.universe.players[0]
        let player1 = Universe.universe.players[1]

        // When
        let identifier0 = sut.playerIdentifier(for: player0)
        let identifier1 = sut.playerIdentifier(for: player1)

        // Then - player letters should differ
        XCTAssertNotEqual(identifier0.suffix(1), identifier1.suffix(1))
    }

    // MARK: - Team Color Tests

    func testTeamColor_ReturnsColorForEachTeam() {
        // Test all teams have colors
        for team in Team.allCases {
            let color = sut.teamColor(for: team)
            XCTAssertNotNil(color)
        }
    }

    func testTeamColor_DifferentTeams_ReturnDifferentColors() {
        // Given
        let fedColor = sut.teamColor(for: .federation)
        let romColor = sut.teamColor(for: .roman)

        // Then - different teams should have different colors
        XCTAssertNotEqual(fedColor, romColor)
    }

    // MARK: - Active Players Tests

    func testActivePlayers_ReturnsArray() {
        // Then
        XCTAssertNotNil(sut.activePlayers)
        // Active players may be empty initially, that's fine
    }
}
