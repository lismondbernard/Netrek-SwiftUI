//
//  PreviewHelpers.swift
//  Netrek
//
//  Helper functions and extensions for SwiftUI Previews
//

import Foundation
import SwiftUI

#if DEBUG

/// Namespace for preview helper functions
enum PreviewHelpers {
    // MARK: - Universe Setup

    /// Configure the Universe singleton with mock data for previews
    /// Call this once before creating preview views
    /// Note: Uses public update methods to set properties on model objects
    static func setupPreviewUniverse() {
        let universe = Universe.universe
        universe.me = 0

        // Set up a sample "me" player (Federation) using public update methods
        let me = universe.players[0]
        me.update(shipType: ShipType.cruiser.rawValue)
        me.update(team: Team.federation.rawValue)
        me.update(directionNetrek: 0, speed: 5, positionX: 50000, positionY: 50000)
        me.update(kills: 2.5)
        me.update(rank: 0, name: "PreviewPlayer", login: "preview")

        // Set up an enemy player (Roman)
        let enemy = universe.players[1]
        enemy.update(shipType: ShipType.destroyer.rawValue)
        enemy.update(team: Team.roman.rawValue)
        enemy.update(directionNetrek: 32, speed: 8, positionX: 51000, positionY: 49000)
        enemy.update(kills: 1.5)
        enemy.update(rank: 0, name: "EnemyShip", login: "enemy")

        // Set up some torpedoes using public properties
        if !universe.torpedoes.isEmpty {
            let torp = universe.torpedoes[0]
            torp.positionX = 50500
            torp.positionY = 50200
            torp.status = 1  // active
        }

        if universe.torpedoes.count > 1 {
            let torp2 = universe.torpedoes[1]
            torp2.positionX = 50800
            torp2.positionY = 49800
            torp2.status = 1  // active
        }

        // Set visual width for preview
        universe.visualWidth = 5000
    }

    // MARK: - Preview Instances

    /// Get the "me" player for previews
    static var previewMe: Player {
        setupPreviewUniverse()
        return Universe.universe.players[Universe.universe.me]
    }

    /// Get an enemy player for previews
    static var previewEnemy: Player {
        setupPreviewUniverse()
        return Universe.universe.players[1]
    }

    /// Get a sample planet for previews
    static var previewPlanet: Planet {
        setupPreviewUniverse()
        return Universe.universe.planets[0]
    }

    /// Get a sample torpedo for previews
    static var previewTorpedo: Torpedo {
        setupPreviewUniverse()
        return Universe.universe.torpedoes[0]
    }

    /// Get the configured universe for previews
    static var previewUniverse: Universe {
        setupPreviewUniverse()
        return Universe.universe
    }

    // MARK: - Screen Dimensions

    /// Common preview screen widths
    static let screenWidthMac: CGFloat = 800
    static let screenHeightMac: CGFloat = 600
    static let screenWidthiPad: CGFloat = 1024
    static let screenHeightiPad: CGFloat = 768
    static let screenWidthiPhone: CGFloat = 390
    static let screenHeightiPhone: CGFloat = 844

    // MARK: - Image Sizes

    static let playerImageSize: CGFloat = 64
    static let planetImageSize: CGFloat = 80
}

#endif
