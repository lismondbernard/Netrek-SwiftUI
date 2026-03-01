//
//  MockPlanet.swift
//  Netrek
//
//  Mock implementation of PlanetProviding for previews and testing
//

import Foundation
import SwiftUI

#if DEBUG
class MockPlanet: PlanetProviding {
    let planetId: Int
    @Published var name: String
    @Published var shortName: String
    @Published var positionX: Int
    @Published var positionY: Int
    @Published var owner: Team
    @Published var armies: Int
    @Published var fuel: Bool
    @Published var repair: Bool
    @Published var agri: Bool

    private var seenBy: Set<Team>

    var id: Int { planetId }

    init(
        planetId: Int = 0,
        name: String = "Earth",
        positionX: Int = 2000,
        positionY: Int = 2000,
        owner: Team = .federation,
        armies: Int = 10,
        fuel: Bool = true,
        repair: Bool = true,
        agri: Bool = false,
        seenBy: Set<Team> = [.federation, .roman, .kazari, .orion]
    ) {
        self.planetId = planetId
        self.name = name
        self.shortName = String(name.prefix(3))
        self.positionX = positionX
        self.positionY = positionY
        self.owner = owner
        self.armies = armies
        self.fuel = fuel
        self.repair = repair
        self.agri = agri
        self.seenBy = seenBy
    }

    func imageName(myTeam: Team) -> String {
        guard seenBy.contains(myTeam) else { return "planet-unknown" }

        switch (repair, fuel, armies > 4) {
        case (false, false, false): return "planet-empty"
        case (false, false, true): return "planet-army"
        case (false, true, false): return "planet-fuel"
        case (false, true, true): return "planet-fuel-army"
        case (true, false, false): return "planet-repair"
        case (true, false, true): return "planet-repair-army"
        case (true, true, false): return "planet-repair-fuel"
        case (true, true, true): return "planet-repair-fuel-army"
        }
    }

    func isSeen(by team: Team) -> Bool {
        seenBy.contains(team)
    }

    // MARK: - Factory Methods

    /// Creates a Federation homeworld
    static func earth() -> MockPlanet {
        MockPlanet(
            planetId: 0,
            name: "Earth",
            positionX: 2000,
            positionY: 8000,
            owner: .federation,
            armies: 30,
            fuel: true,
            repair: true,
            agri: true
        )
    }

    /// Creates a Roman homeworld
    static func romulus() -> MockPlanet {
        MockPlanet(
            planetId: 10,
            name: "Rome",
            positionX: 8000,
            positionY: 8000,
            owner: .roman,
            armies: 30,
            fuel: true,
            repair: true,
            agri: true
        )
    }

    /// Creates a Kazari homeworld
    static func kazari() -> MockPlanet {
        MockPlanet(
            planetId: 20,
            name: "Kazari",
            positionX: 8000,
            positionY: 2000,
            owner: .kazari,
            armies: 30,
            fuel: true,
            repair: true,
            agri: true
        )
    }

    /// Creates an Orion homeworld
    static func orion() -> MockPlanet {
        MockPlanet(
            planetId: 30,
            name: "Orion",
            positionX: 2000,
            positionY: 2000,
            owner: .orion,
            armies: 30,
            fuel: true,
            repair: true,
            agri: true
        )
    }

    /// Creates an independent/neutral planet
    static func neutral(planetId: Int = 5) -> MockPlanet {
        MockPlanet(
            planetId: planetId,
            name: "Neutral",
            positionX: 5000,
            positionY: 5000,
            owner: .independent,
            armies: 5,
            fuel: false,
            repair: false,
            agri: false
        )
    }

    /// Creates a contested planet with armies
    static func contested(planetId: Int = 6) -> MockPlanet {
        MockPlanet(
            planetId: planetId,
            name: "Contested",
            positionX: 4500,
            positionY: 5500,
            owner: .roman,
            armies: 8,
            fuel: true,
            repair: false,
            agri: false
        )
    }

    /// Creates an unknown/unscanned planet
    static func unknown(planetId: Int = 7) -> MockPlanet {
        MockPlanet(
            planetId: planetId,
            name: "Unknown",
            positionX: 7000,
            positionY: 3000,
            owner: .independent,
            armies: 5,
            fuel: false,
            repair: false,
            agri: false,
            seenBy: [] // No team has scanned this planet
        )
    }

    /// Creates an agri planet (high value target)
    static func agriPlanet(planetId: Int = 8) -> MockPlanet {
        MockPlanet(
            planetId: planetId,
            name: "Agri",
            positionX: 3000,
            positionY: 6000,
            owner: .federation,
            armies: 15,
            fuel: false,
            repair: false,
            agri: true
        )
    }
}
#endif
