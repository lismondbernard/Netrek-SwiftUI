//
//  ModelProtocols.swift
//  Netrek
//
//  Created for MVVM refactoring
//

import Foundation
import SwiftUI

// MARK: - PlayerProviding Protocol

/// Protocol defining the interface for a Player entity
/// Used by views and view models to abstract the concrete Player implementation
protocol PlayerProviding: ObservableObject, Identifiable {
    var playerId: Int { get }
    var name: String { get }
    var login: String { get }
    var team: Team { get }
    var ship: ShipType? { get }
    var positionX: Int { get }
    var positionY: Int { get }
    var direction: Double { get }
    var speed: Int { get }
    var kills: Double { get }
    var shieldsUp: Bool { get }
    var shieldStrength: Int { get }
    var damage: Int { get }
    var fuel: Int { get }
    var armies: Int { get }
    var cloak: Bool { get }
    var slotStatus: SlotStatus { get }
    var alertCondition: AlertCondition { get }
    var imageName: String { get }
    var rank: Rank { get }
    var throttle: Int { get }
    var tractor: Int { get }

    // Computed properties for display
    var playerStrategicText: String { get }

    // Stats
    var tournamentKills: Int { get }
    var tournamentLosses: Int { get }
    var maxKills: Double { get }
}

// MARK: - PlanetProviding Protocol

/// Protocol defining the interface for a Planet entity
protocol PlanetProviding: ObservableObject, Identifiable {
    var planetId: Int { get }
    var name: String { get }
    var shortName: String { get }
    var positionX: Int { get }
    var positionY: Int { get }
    var owner: Team { get }
    var armies: Int { get }
    var fuel: Bool { get }
    var repair: Bool { get }
    var agri: Bool { get }

    /// Returns the appropriate image name based on planet resources and visibility
    func imageName(myTeam: Team) -> String

    /// Checks if a planet has been scanned by a specific team
    func isSeen(by team: Team) -> Bool
}

// MARK: - TorpedoProviding Protocol

/// Protocol defining the interface for a Torpedo weapon
protocol TorpedoProviding: ObservableObject {
    var torpedoId: Int { get }
    var status: UInt8 { get }
    var positionX: Int { get }
    var positionY: Int { get }
    var color: Color { get }
}

// MARK: - LaserProviding Protocol

/// Protocol defining the interface for a Laser weapon
protocol LaserProviding: ObservableObject {
    var laserId: Int { get }
    var status: Int { get }
    var positionX: Int { get }
    var positionY: Int { get }
    var targetPositionX: Int { get }
    var targetPositionY: Int { get }
}

// MARK: - PlasmaProviding Protocol

/// Protocol defining the interface for a Plasma weapon
protocol PlasmaProviding: ObservableObject {
    var plasmaId: Int { get }
    var status: Int { get }
    var positionX: Int { get }
    var positionY: Int { get }
    var color: Color { get }
}
