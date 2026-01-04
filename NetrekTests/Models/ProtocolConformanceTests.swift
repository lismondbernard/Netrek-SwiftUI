//
//  ProtocolConformanceTests.swift
//  NetrekTests
//
//  Tests to verify model protocol conformance
//

import XCTest
@testable import Netrek

final class ProtocolConformanceTests: XCTestCase {

    // MARK: - Player Protocol Conformance

    func testPlayer_ConformsToPlayerProviding() {
        // Given
        let player = Universe.universe.players[0]

        // Then - accessing protocol properties should work
        let _: Int = player.playerId
        let _: String = player.name
        let _: Team = player.team
        let _: Int = player.positionX
        let _: Int = player.positionY
        let _: Double = player.direction
        let _: Int = player.speed
        let _: Double = player.kills
        let _: Bool = player.shieldsUp
        let _: Bool = player.cloak
        let _: SlotStatus = player.slotStatus
        let _: AlertCondition = player.alertCondition
        let _: String = player.imageName

        // If we get here without compiler errors, conformance is verified
        XCTAssertTrue(true)
    }

    func testPlayer_IsIdentifiable() {
        // Given
        let player = Universe.universe.players[0]

        // Then
        XCTAssertEqual(player.id, player.playerId)
    }

    // MARK: - Planet Protocol Conformance

    func testPlanet_ConformsToPlanetProviding() {
        // Given
        let planet = Universe.universe.planets[0]

        // Then - accessing protocol properties should work
        let _: Int = planet.planetId
        let _: String = planet.name
        let _: String = planet.shortName
        let _: Int = planet.positionX
        let _: Int = planet.positionY
        let _: Team = planet.owner
        let _: Int = planet.armies
        let _: Bool = planet.fuel
        let _: Bool = planet.repair
        let _: Bool = planet.agri
        let _: String = planet.imageName(myTeam: .federation)

        // If we get here without compiler errors, conformance is verified
        XCTAssertTrue(true)
    }

    func testPlanet_IsIdentifiable() {
        // Given
        let planet = Universe.universe.planets[0]

        // Then
        XCTAssertEqual(planet.id, planet.planetId)
    }

    func testPlanet_IsSeen_ReturnsBoolean() {
        // Given
        let planet = Universe.universe.planets[0]

        // When/Then - should not crash
        let _ = planet.isSeen(by: .federation)
        let _ = planet.isSeen(by: .roman)
        let _ = planet.isSeen(by: .kazari)
        let _ = planet.isSeen(by: .orion)

        XCTAssertTrue(true)
    }

    // MARK: - Torpedo Protocol Conformance

    func testTorpedo_ConformsToTorpedoProviding() {
        // Given
        let torpedo = Universe.universe.torpedoes[0]

        // Then - accessing protocol properties should work
        let _: Int = torpedo.torpedoId
        let _: Int = torpedo.positionX
        let _: Int = torpedo.positionY
        let _: UInt8 = torpedo.status

        XCTAssertTrue(true)
    }

    // MARK: - Laser Protocol Conformance

    func testLaser_ConformsToLaserProviding() {
        // Given
        let laser = Universe.universe.lasers[0]

        // Then - accessing protocol properties should work
        let _: Int = laser.laserId
        let _: Int = laser.positionX
        let _: Int = laser.positionY
        let _: Int = laser.targetPositionX
        let _: Int = laser.targetPositionY
        let _: Int = laser.status

        XCTAssertTrue(true)
    }

    // MARK: - Plasma Protocol Conformance

    func testPlasma_ConformsToPlasmaProviding() {
        // Given
        let plasma = Universe.universe.plasmas[0]

        // Then - accessing protocol properties should work
        let _: Int = plasma.plasmaId
        let _: Int = plasma.positionX
        let _: Int = plasma.positionY
        let _: Int = plasma.status

        XCTAssertTrue(true)
    }
}
