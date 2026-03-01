//
//  MockPlayer.swift
//  Netrek
//
//  Mock implementation of PlayerProviding for previews and testing
//

import Foundation
import SwiftUI

#if DEBUG
class MockPlayer: PlayerProviding {
    let playerId: Int
    @Published var name: String
    @Published var login: String
    @Published var team: Team
    @Published var ship: ShipType?
    @Published var positionX: Int
    @Published var positionY: Int
    @Published var direction: Double
    @Published var speed: Int
    @Published var kills: Double
    @Published var shieldsUp: Bool
    @Published var shieldStrength: Int
    @Published var damage: Int
    @Published var fuel: Int
    @Published var armies: Int
    @Published var cloak: Bool
    @Published var slotStatus: SlotStatus
    @Published var alertCondition: AlertCondition
    @Published var imageName: String
    @Published var rank: Rank
    @Published var throttle: Int
    @Published var tractor: Int
    @Published var tournamentKills: Int
    @Published var tournamentLosses: Int
    @Published var maxKills: Double

    var id: Int { playerId }

    var playerStrategicText: String {
        if cloak {
            return "??"
        } else {
            let playerLetter = NetrekMath.playerLetter(playerId: playerId)
            let teamLetter = NetrekMath.teamLetter(team: team)
            return teamLetter + playerLetter
        }
    }

    init(
        playerId: Int = 0,
        name: String = "TestPlayer",
        login: String = "testlogin",
        team: Team = .federation,
        ship: ShipType? = .cruiser,
        positionX: Int = 5000,
        positionY: Int = 5000,
        direction: Double = 0,
        speed: Int = 5,
        kills: Double = 2.5,
        shieldsUp: Bool = true,
        shieldStrength: Int = 100,
        damage: Int = 0,
        fuel: Int = 10000,
        armies: Int = 0,
        cloak: Bool = false,
        slotStatus: SlotStatus = .alive,
        alertCondition: AlertCondition = .green,
        imageName: String? = nil,
        rank: Rank = .ensign,
        throttle: Int = 5,
        tractor: Int = 0,
        tournamentKills: Int = 10,
        tournamentLosses: Int = 5,
        maxKills: Double = 3.5
    ) {
        self.playerId = playerId
        self.name = name
        self.login = login
        self.team = team
        self.ship = ship
        self.positionX = positionX
        self.positionY = positionY
        self.direction = direction
        self.speed = speed
        self.kills = kills
        self.shieldsUp = shieldsUp
        self.shieldStrength = shieldStrength
        self.damage = damage
        self.fuel = fuel
        self.armies = armies
        self.cloak = cloak
        self.slotStatus = slotStatus
        self.alertCondition = alertCondition
        self.rank = rank
        self.throttle = throttle
        self.tractor = tractor
        self.tournamentKills = tournamentKills
        self.tournamentLosses = tournamentLosses
        self.maxKills = maxKills

        // Set default image name based on team and ship
        if let imageName = imageName {
            self.imageName = imageName
        } else {
            self.imageName = MockPlayer.defaultImageName(team: team, ship: ship ?? .cruiser)
        }
    }

    // MARK: - Factory Methods

    /// Creates a Federation player for previews
    static func federation(playerId: Int = 0) -> MockPlayer {
        MockPlayer(
            playerId: playerId,
            name: "FedPlayer",
            team: .federation,
            ship: .cruiser,
            imageName: "mactrek-outlinefleet-ca"
        )
    }

    /// Creates a Roman (enemy) player for previews
    static func roman(playerId: Int = 1) -> MockPlayer {
        MockPlayer(
            playerId: playerId,
            name: "RomanPlayer",
            team: .roman,
            ship: .destroyer,
            imageName: "mactrek-redfleet-dd"
        )
    }

    /// Creates a Kazari player for previews
    static func kazari(playerId: Int = 2) -> MockPlayer {
        MockPlayer(
            playerId: playerId,
            name: "KazariPlayer",
            team: .kazari,
            ship: .battleship,
            imageName: "kli-bb"
        )
    }

    /// Creates an Orion player for previews
    static func orion(playerId: Int = 3) -> MockPlayer {
        MockPlayer(
            playerId: playerId,
            name: "OrionPlayer",
            team: .orion,
            ship: .scout,
            imageName: "ori-sc"
        )
    }

    /// Creates a damaged player for testing damage display
    static func damaged(playerId: Int = 0) -> MockPlayer {
        MockPlayer(
            playerId: playerId,
            name: "DamagedShip",
            team: .federation,
            shieldStrength: 30,
            damage: 70,
            fuel: 3000,
            alertCondition: .red
        )
    }

    /// Creates a cloaked player for testing cloak display
    static func cloaked(playerId: Int = 0) -> MockPlayer {
        MockPlayer(
            playerId: playerId,
            name: "CloakedShip",
            team: .roman,
            cloak: true
        )
    }

    /// Creates a player carrying armies
    static func armyCarrier(playerId: Int = 0) -> MockPlayer {
        MockPlayer(
            playerId: playerId,
            name: "ArmyCarrier",
            team: .federation,
            ship: .assault,
            armies: 6,
            imageName: "mactrek-outlinefleet-as"
        )
    }

    /// Creates an exploding player
    static func exploding(playerId: Int = 0) -> MockPlayer {
        MockPlayer(
            playerId: playerId,
            name: "ExplodingShip",
            team: .roman,
            slotStatus: .explode
        )
    }

    // MARK: - Helper Methods

    private static func defaultImageName(team: Team, ship: ShipType) -> String {
        switch (team, ship) {
        case (.federation, .scout): return "mactrek-outlinefleet-sc"
        case (.federation, .destroyer): return "mactrek-outlinefleet-dd"
        case (.federation, .cruiser): return "mactrek-outlinefleet-ca"
        case (.federation, .battleship): return "mactrek-outlinefleet-bb"
        case (.federation, .assault): return "mactrek-outlinefleet-as"
        case (.federation, .starbase): return "mactrek-outlinefleet-sb"
        case (.federation, .battlecruiser): return "mactrek-outlinefleet-ca"

        case (.roman, .scout): return "mactrek-redfleet-sc"
        case (.roman, .destroyer): return "mactrek-redfleet-dd"
        case (.roman, .cruiser): return "mactrek-redfleet-ca"
        case (.roman, .battleship): return "mactrek-redfleet-bb"
        case (.roman, .assault): return "mactrek-redfleet-bb"
        case (.roman, .starbase): return "mactrek-redfleet-sb"
        case (.roman, .battlecruiser): return "mactrek-redfleet-ca"

        case (.kazari, .scout): return "kli-sc"
        case (.kazari, .destroyer): return "kli-dd"
        case (.kazari, .cruiser): return "kli-ca"
        case (.kazari, .battleship): return "kli-bb"
        case (.kazari, .assault): return "kli-as"
        case (.kazari, .starbase): return "kli-sb"
        case (.kazari, .battlecruiser): return "kli-ca"

        case (.orion, .scout): return "ori-sc"
        case (.orion, .destroyer): return "ori-dd"
        case (.orion, .cruiser): return "ori-ca"
        case (.orion, .battleship): return "ori-bb"
        case (.orion, .assault): return "ori-as"
        case (.orion, .starbase): return "ori-sb"
        case (.orion, .battlecruiser): return "ori-ca"

        default: return "mactrek-outlinefleet-ca"
        }
    }
}
#endif
