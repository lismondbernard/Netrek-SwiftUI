//
//  MockUniverse.swift
//  Netrek
//
//  Mock implementation of Universe for previews and testing
//

import Foundation
import SwiftUI

#if DEBUG

/// Mock Universe for SwiftUI previews and unit testing
/// Provides sample game data without requiring network connection
class MockUniverse: ObservableObject {

    // MARK: - Entity Collections

    var players: [MockPlayer]
    var planets: [MockPlanet]
    var torpedoes: [MockTorpedo]
    var lasers: [MockLaser]
    var plasmas: [MockPlasma]

    // MARK: - Published Properties

    @Published var me: Int
    @Published var visualWidth: CGFloat
    @Published var messages: [String]
    @Published var recentMessages: [String]
    @Published var waitQueue: Int
    @Published var selectionError: String

    // MARK: - Constants

    let maxPlayers = 32
    let maxPlanets = 40
    let maxTorpedoes = 256
    let maxLasers = 32
    let maxPlasma = 32

    // MARK: - Computed Properties (mirroring Universe)

    var activePlayers: [MockPlayer] {
        players.filter { $0.slotStatus != .free && $0.slotStatus != .observe }
    }

    var alivePlayers: [MockPlayer] {
        players.filter { $0.slotStatus == .alive }
    }

    var explodingPlayers: [MockPlayer] {
        players.filter { $0.slotStatus == .explode }
    }

    var visiblePlayers: [MockPlayer] {
        guard me < players.count else { return [] }
        let myPlayer = players[me]
        return alivePlayers.filter {
            abs($0.positionX - myPlayer.positionX) < Int(visualWidth / 2) &&
            abs($0.positionY - myPlayer.positionY) < Int(visualWidth / 2)
        }
    }

    var visiblePlanets: [MockPlanet] {
        guard me < players.count else { return planets }
        let myPlayer = players[me]
        return planets.filter {
            abs($0.positionX - myPlayer.positionX) < Int(visualWidth / 2) &&
            abs($0.positionY - myPlayer.positionY) < Int(visualWidth / 2)
        }
    }

    var activeTorpedoes: [MockTorpedo] {
        torpedoes.filter { $0.status == 1 }
    }

    var explodingTorpedoes: [MockTorpedo] {
        torpedoes.filter { $0.status == 2 || $0.status == 3 }
    }

    var visibleTorpedoes: [MockTorpedo] {
        guard me < players.count else { return activeTorpedoes }
        let myPlayer = players[me]
        return activeTorpedoes.filter {
            abs($0.positionX - myPlayer.positionX) < Int(visualWidth / 2) &&
            abs($0.positionY - myPlayer.positionY) < Int(visualWidth / 2)
        }
    }

    var activeLasers: [MockLaser] {
        lasers.filter { $0.status != 0 }
    }

    var visibleLasers: [MockLaser] {
        guard me < players.count else { return activeLasers }
        let myPlayer = players[me]
        return activeLasers.filter {
            abs($0.positionX - myPlayer.positionX) < Int(visualWidth / 2) &&
            abs($0.positionY - myPlayer.positionY) < Int(visualWidth / 2)
        }
    }

    var activePlasmas: [MockPlasma] {
        plasmas.filter { $0.status != 0 }
    }

    var explodingPlasmas: [MockPlasma] {
        plasmas.filter { $0.status == 2 || $0.status == 3 }
    }

    var visiblePlasmas: [MockPlasma] {
        guard me < players.count else { return activePlasmas }
        let myPlayer = players[me]
        return activePlasmas.filter {
            abs($0.positionX - myPlayer.positionX) < Int(visualWidth / 2) &&
            abs($0.positionY - myPlayer.positionY) < Int(visualWidth / 2)
        }
    }

    var visibleTractors: [MockPlayer] {
        [] // Simplified for mocks
    }

    var activeMessages: ArraySlice<String> {
        let messagesToDisplay = 20
        if messages.count >= messagesToDisplay {
            return messages[messages.count - messagesToDisplay ..< messages.count]
        } else {
            return messages[0 ..< messages.count]
        }
    }

    // MARK: - Initialization

    init(
        players: [MockPlayer] = [],
        planets: [MockPlanet] = [],
        torpedoes: [MockTorpedo] = [],
        lasers: [MockLaser] = [],
        plasmas: [MockPlasma] = [],
        me: Int = 0,
        visualWidth: CGFloat = 3000,
        messages: [String] = [],
        waitQueue: Int = 0
    ) {
        self.players = players
        self.planets = planets
        self.torpedoes = torpedoes
        self.lasers = lasers
        self.plasmas = plasmas
        self.me = me
        self.visualWidth = visualWidth
        self.messages = messages
        self.recentMessages = Array(messages.suffix(15))
        self.waitQueue = waitQueue
        self.selectionError = ""
    }

    // MARK: - Factory Methods

    /// Creates an empty universe with default values
    static func empty() -> MockUniverse {
        MockUniverse(
            players: [MockPlayer.federation(playerId: 0)],
            planets: [],
            torpedoes: [],
            lasers: [],
            plasmas: []
        )
    }

    /// Creates a universe with a game in progress
    /// Includes multiple players from different teams, planets, and weapons
    static func gameInProgress() -> MockUniverse {
        // Create players from all teams
        var players: [MockPlayer] = []

        // Federation players (player 0 is "me")
        let mePlayer = MockPlayer(
            playerId: 0,
            name: "You",
            team: .federation,
            ship: .cruiser,
            positionX: 5000,
            positionY: 5000,
            direction: 0,
            speed: 6,
            kills: 3.5,
            shieldsUp: true,
            shieldStrength: 85,
            damage: 15,
            fuel: 8500,
            slotStatus: .alive,
            alertCondition: .yellow,
            imageName: "mactrek-outlinefleet-ca"
        )
        players.append(mePlayer)

        players.append(MockPlayer(
            playerId: 1,
            name: "FedAlly",
            team: .federation,
            ship: .destroyer,
            positionX: 4800,
            positionY: 5200,
            direction: Double.pi / 4,
            speed: 8,
            kills: 2.0,
            slotStatus: .alive,
            imageName: "mactrek-outlinefleet-dd"
        ))

        // Roman enemies
        players.append(MockPlayer(
            playerId: 8,
            name: "RomEnemy",
            team: .roman,
            ship: .cruiser,
            positionX: 5500,
            positionY: 4800,
            direction: Double.pi,
            speed: 5,
            kills: 4.5,
            slotStatus: .alive,
            alertCondition: .red,
            imageName: "mactrek-redfleet-ca"
        ))

        players.append(MockPlayer(
            playerId: 9,
            name: "RomScout",
            team: .roman,
            ship: .scout,
            positionX: 5300,
            positionY: 5400,
            direction: Double.pi * 1.5,
            speed: 10,
            kills: 1.0,
            cloak: true,
            slotStatus: .alive,
            imageName: "mactrek-redfleet-sc"
        ))

        // Kazari players
        players.append(MockPlayer(
            playerId: 16,
            name: "KazWarrior",
            team: .kazari,
            ship: .battleship,
            positionX: 7000,
            positionY: 3000,
            direction: Double.pi / 2,
            speed: 4,
            kills: 8.5,
            slotStatus: .alive,
            imageName: "kli-bb"
        ))

        // Orion players
        players.append(MockPlayer(
            playerId: 24,
            name: "OriTrader",
            team: .orion,
            ship: .assault,
            positionX: 3000,
            positionY: 7000,
            direction: -Double.pi / 4,
            speed: 3,
            kills: 1.5,
            armies: 4,
            slotStatus: .alive,
            imageName: "ori-as"
        ))

        // Create planets
        var planets: [MockPlanet] = []

        // Federation planets (top-left quadrant)
        planets.append(MockPlanet.earth())
        planets.append(MockPlanet(
            planetId: 1,
            name: "Rigel",
            positionX: 1500,
            positionY: 7500,
            owner: .federation,
            armies: 20,
            fuel: true,
            repair: false,
            agri: false
        ))

        // Roman planets (top-right quadrant)
        planets.append(MockPlanet.romulus())
        planets.append(MockPlanet(
            planetId: 11,
            name: "Remus",
            positionX: 8500,
            positionY: 7500,
            owner: .roman,
            armies: 18,
            fuel: false,
            repair: true,
            agri: false
        ))

        // Kazari planets (bottom-right quadrant)
        planets.append(MockPlanet.kazari())
        planets.append(MockPlanet(
            planetId: 21,
            name: "Praxis",
            positionX: 8500,
            positionY: 2500,
            owner: .kazari,
            armies: 15,
            fuel: true,
            repair: true,
            agri: false
        ))

        // Orion planets (bottom-left quadrant)
        planets.append(MockPlanet.orion())
        planets.append(MockPlanet(
            planetId: 31,
            name: "Antares",
            positionX: 2500,
            positionY: 2500,
            owner: .orion,
            armies: 12,
            fuel: false,
            repair: false,
            agri: true
        ))

        // Neutral/contested planets in center
        planets.append(MockPlanet.neutral(planetId: 35))
        planets.append(MockPlanet.contested(planetId: 36))

        // Create some visible weapons
        var torpedoes: [MockTorpedo] = []
        torpedoes.append(contentsOf: MockTorpedo.friendlySpread(startId: 0, centerX: 5100, centerY: 5000))
        torpedoes.append(MockTorpedo.enemy(torpedoId: 64, positionX: 5400, positionY: 4900))
        torpedoes.append(MockTorpedo.enemy(torpedoId: 65, positionX: 5350, positionY: 4850))

        var lasers: [MockLaser] = []
        lasers.append(MockLaser.hit(laserId: 0, sourceX: 5000, sourceY: 5000, targetX: 5400, targetY: 4800))

        var plasmas: [MockPlasma] = []
        plasmas.append(MockPlasma.enemy(plasmaId: 8, positionX: 5300, positionY: 4900))

        // Create some messages
        let messages = [
            "Welcome to Netrek!",
            "Federation player You has entered the game.",
            "Roman player RomEnemy: Prepare to die, Fed scum!",
            "All: Good game everyone!",
            "Federation player FedAlly: Need escort to Earth"
        ]

        return MockUniverse(
            players: players,
            planets: planets,
            torpedoes: torpedoes,
            lasers: lasers,
            plasmas: plasmas,
            me: 0,
            visualWidth: 3000,
            messages: messages,
            waitQueue: 0
        )
    }

    /// Creates a tactical combat scenario
    static func combatScenario() -> MockUniverse {
        let mePlayer = MockPlayer(
            playerId: 0,
            name: "Fighter",
            team: .federation,
            ship: .cruiser,
            positionX: 5000,
            positionY: 5000,
            direction: 0,
            speed: 8,
            shieldsUp: true,
            shieldStrength: 60,
            damage: 40,
            fuel: 5000,
            slotStatus: .alive,
            alertCondition: .red,
            imageName: "mactrek-outlinefleet-ca"
        )

        let enemy = MockPlayer(
            playerId: 8,
            name: "Attacker",
            team: .roman,
            ship: .battleship,
            positionX: 5300,
            positionY: 4700,
            direction: Double.pi * 0.75,
            speed: 4,
            shieldsUp: true,
            slotStatus: .alive,
            imageName: "mactrek-redfleet-bb"
        )

        // Incoming torpedoes
        var torpedoes: [MockTorpedo] = []
        for i in 0..<8 {
            torpedoes.append(MockTorpedo(
                torpedoId: 64 + i,
                status: 1,
                positionX: 5200 + i * 20,
                positionY: 4800 + i * 30,
                color: .red
            ))
        }

        return MockUniverse(
            players: [mePlayer, enemy],
            planets: [MockPlanet.neutral()],
            torpedoes: torpedoes,
            lasers: [MockLaser.hit(laserId: 8, sourceX: 5300, sourceY: 4700, targetX: 5000, targetY: 5000)],
            plasmas: [],
            me: 0,
            visualWidth: 3000,
            messages: ["Red Alert! Enemy battleship attacking!"]
        )
    }

    /// Creates a strategic map view scenario
    static func strategicView() -> MockUniverse {
        var players: [MockPlayer] = []
        var planets: [MockPlanet] = []

        // Place players across the galaxy
        players.append(MockPlayer(playerId: 0, name: "Me", team: .federation, positionX: 2000, positionY: 8000, slotStatus: .alive))
        players.append(MockPlayer(playerId: 1, name: "Fed1", team: .federation, positionX: 2500, positionY: 7500, slotStatus: .alive))
        players.append(MockPlayer(playerId: 8, name: "Rom1", team: .roman, positionX: 8000, positionY: 8000, slotStatus: .alive))
        players.append(MockPlayer(playerId: 16, name: "Kaz1", team: .kazari, positionX: 8000, positionY: 2000, slotStatus: .alive))
        players.append(MockPlayer(playerId: 24, name: "Ori1", team: .orion, positionX: 2000, positionY: 2000, slotStatus: .alive))

        // Create all 40 planets spread across galaxy
        for i in 0..<40 {
            let team: Team
            switch i / 10 {
            case 0: team = .federation
            case 1: team = .roman
            case 2: team = .kazari
            default: team = .orion
            }

            let baseX = (i / 10) % 2 == 0 ? 2000 : 8000
            let baseY = (i / 10) < 2 ? 8000 : 2000

            planets.append(MockPlanet(
                planetId: i,
                name: "Planet\(i)",
                positionX: baseX + (i % 5) * 300 - 600,
                positionY: baseY + ((i % 10) / 5) * 300 - 150,
                owner: team,
                armies: 5 + (i % 10),
                fuel: i % 3 == 0,
                repair: i % 4 == 0,
                agri: i % 5 == 0
            ))
        }

        return MockUniverse(
            players: players,
            planets: planets,
            torpedoes: [],
            lasers: [],
            plasmas: [],
            me: 0,
            visualWidth: 10000 // Full galaxy view
        )
    }
}

#endif
