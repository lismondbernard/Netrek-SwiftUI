//
//  GameStateManagerTests.swift
//  NetrekCoreTests
//
//  Tests for GameStateManager - the central game state machine.
//

import XCTest
@testable import Netrek

final class GameStateManagerTests: XCTestCase {

    // MARK: - Initial State Tests

    @MainActor
    func testInitialState_IsNoServerSelected() {
        let manager = GameStateManager()

        XCTAssertEqual(manager.gameState, .noServerSelected,
                      "Initial state should be noServerSelected")
    }

    @MainActor
    func testInitialPreferredTeam_IsFederation() {
        let manager = GameStateManager()

        XCTAssertEqual(manager.preferredTeam, .federation,
                      "Initial preferred team should be federation")
    }

    @MainActor
    func testInitialPreferredShip_IsCruiser() {
        let manager = GameStateManager()

        XCTAssertEqual(manager.preferredShip, .cruiser,
                      "Initial preferred ship should be cruiser")
    }

    @MainActor
    func testInitialTeamSet_IsFalse() {
        let manager = GameStateManager()

        XCTAssertFalse(manager.initialTeamSet,
                      "Initial team should not be set on creation")
    }

    @MainActor
    func testClientTypeSent_InitiallyFalse() {
        let manager = GameStateManager()

        XCTAssertFalse(manager.clientTypeSent,
                      "Client type should not be sent initially")
    }

    // MARK: - State Transition Tests

    @MainActor
    func testNewGameState_UpdatesState() {
        let manager = GameStateManager()

        manager.newGameState(.serverSelected)

        XCTAssertEqual(manager.gameState, .serverSelected)
    }

    @MainActor
    func testNewGameState_ServerSelected() {
        let manager = GameStateManager()

        manager.newGameState(.serverSelected)

        XCTAssertEqual(manager.gameState, .serverSelected,
                      "State should transition to serverSelected")
    }

    @MainActor
    func testNewGameState_LoginAccepted() {
        let manager = GameStateManager()

        manager.newGameState(.loginAccepted)

        XCTAssertEqual(manager.gameState, .loginAccepted,
                      "State should transition to loginAccepted")
    }

    @MainActor
    func testNewGameState_GameActive() {
        let manager = GameStateManager()

        manager.newGameState(.gameActive)

        XCTAssertEqual(manager.gameState, .gameActive,
                      "State should transition to gameActive")
    }

    @MainActor
    func testNewGameState_GameActive_SetsClientTypeSent() {
        let manager = GameStateManager()

        XCTAssertFalse(manager.clientTypeSent)

        manager.newGameState(.gameActive)

        XCTAssertTrue(manager.clientTypeSent,
                     "clientTypeSent should be true after entering gameActive")
    }

    @MainActor
    func testNewGameState_GameActive_OnlyFirstTimeSetsClientType() {
        let manager = GameStateManager()

        manager.newGameState(.gameActive)
        XCTAssertTrue(manager.clientTypeSent)

        // Transition away and back
        manager.newGameState(.loginAccepted)
        manager.newGameState(.gameActive)

        // clientTypeSent should still be true (not reset)
        XCTAssertTrue(manager.clientTypeSent,
                     "clientTypeSent should remain true on subsequent gameActive")
    }

    @MainActor
    func testNewGameState_ServerConnected_ResetsClientTypeSent() {
        let manager = GameStateManager()

        manager.newGameState(.gameActive)
        XCTAssertTrue(manager.clientTypeSent)

        manager.newGameState(.serverConnected)

        XCTAssertFalse(manager.clientTypeSent,
                      "clientTypeSent should reset when entering serverConnected")
    }

    // MARK: - Team Selection Tests

    @MainActor
    func testSelectTeam_UpdatesPreferredTeam() {
        let manager = GameStateManager()

        manager.selectTeam(.roman)

        XCTAssertEqual(manager.preferredTeam, .roman,
                      "Preferred team should be updated")
    }

    @MainActor
    func testSelectTeam_AllTeams() {
        let manager = GameStateManager()

        for team in Team.allCases {
            manager.selectTeam(team)
            XCTAssertEqual(manager.preferredTeam, team,
                          "Should be able to select \(team)")
        }
    }

    // MARK: - Ship Selection Tests

    @MainActor
    func testSelectShip_UpdatesPreferredShip() {
        let manager = GameStateManager()

        manager.selectShip(.battleship)

        XCTAssertEqual(manager.preferredShip, .battleship,
                      "Preferred ship should be updated")
    }

    @MainActor
    func testSelectShip_AllShipTypes() {
        let manager = GameStateManager()

        for ship in ShipType.allCases {
            manager.selectShip(ship)
            XCTAssertEqual(manager.preferredShip, ship,
                          "Should be able to select \(ship)")
        }
    }

    @MainActor
    func testSelectShip_InNoServerSelected_DoesNotSendPacket() {
        let manager = GameStateManager()

        // No connectionManager set, no crash expected
        manager.selectShip(.destroyer)

        XCTAssertEqual(manager.preferredShip, .destroyer,
                      "Ship should be selected even without connection")
    }

    // MARK: - Team Eligibility Tests

    @MainActor
    func testUpdateTeamEligibility_NoMask_DoesNotSetTeam() {
        let manager = GameStateManager()

        manager.updateTeamEligibility(mask: 0)

        XCTAssertFalse(manager.initialTeamSet,
                      "Team should not be set with zero mask")
    }

    @MainActor
    func testUpdateTeamEligibility_FederationEligible_SetsTeam() {
        let manager = GameStateManager()

        // Federation team raw value is typically 1
        manager.updateTeamEligibility(mask: UInt8(Team.federation.rawValue))

        XCTAssertTrue(manager.initialTeamSet,
                     "Team should be set when eligible")
        XCTAssertEqual(manager.preferredTeam, .federation,
                      "Should select first eligible team")
    }

    @MainActor
    func testUpdateTeamEligibility_OnlyOnce() {
        let manager = GameStateManager()

        // First call should set team
        manager.updateTeamEligibility(mask: UInt8(Team.federation.rawValue))
        XCTAssertEqual(manager.preferredTeam, .federation)

        // Second call should not change team
        manager.updateTeamEligibility(mask: UInt8(Team.roman.rawValue))
        XCTAssertEqual(manager.preferredTeam, .federation,
                      "Team should not change after initial set")
    }

    @MainActor
    func testUpdateTeamEligibility_MultipleTeamsEligible() {
        let manager = GameStateManager()

        // Both Federation (1) and Roman (2) eligible
        let mask = UInt8(Team.federation.rawValue | Team.roman.rawValue)
        manager.updateTeamEligibility(mask: mask)

        XCTAssertTrue(manager.initialTeamSet)
        // Should select first eligible team from allCases order
    }

    // MARK: - GameStateProviding Protocol Tests

    @MainActor
    func testGameStateProviding_Conformance() {
        let manager = GameStateManager()

        // GameStateManager conforms to GameStateProviding
        let provider: GameStateProviding = manager

        XCTAssertEqual(provider.gameState, .noServerSelected)

        manager.newGameState(.gameActive)

        XCTAssertEqual(provider.gameState, .gameActive)
    }

    // MARK: - Dependency Tests

    @MainActor
    func testConnectionManager_InitiallyNil() {
        let manager = GameStateManager()

        XCTAssertNil(manager.connectionManager,
                    "Connection manager should be nil initially")
    }

    @MainActor
    func testHelp_InitiallyNil() {
        let manager = GameStateManager()

        XCTAssertNil(manager.help,
                    "Help should be nil initially")
    }
}
