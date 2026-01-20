//
//  GameConstants.swift
//  Netrek
//
//  Created as part of Phase 5.1: Replace Magic Numbers
//  Centralizes all game-related constants for maintainability
//

import Foundation
import CoreGraphics

/// Game-wide constants used throughout the Netrek client
enum GameConstants {
    // MARK: - Map and Galaxy

    /// Default tactical view width in game units
    /// Represents the visible area around the player's ship (30% of galactic scale)
    static let defaultVisualWidth: CGFloat = 3000

    /// Full galaxy width in game units
    static let galaxyWidth: Int = 100000

    /// Full galaxy height in game units
    static let galaxyHeight: Int = 100000

    /// Galactic scale (10,000 = 10% of full galaxy size)
    static let galacticScale: Int = 10000

    // MARK: - Players

    /// Maximum number of players in a game
    static let maxPlayers: Int = 32

    /// Maximum number of teams
    static let maxTeams: Int = 4

    /// Maximum length of player names
    static let nameLength: Int = 16

    // MARK: - Planets

    /// Maximum number of planets in the galaxy
    static let maxPlanets: Int = 40

    // MARK: - Weapons

    /// Maximum number of torpedoes (32 players × 8 torpedoes each)
    static let maxTorpedoes: Int = 256

    /// Number of torpedoes per player
    static let torpedoesPerPlayer: Int = 8

    /// Maximum number of phasers
    static let maxPhasers: Int = 32

    /// Maximum number of plasma torpedoes
    static let maxPlasmas: Int = 256

    /// Torpedo speed in game units per update
    static let torpedoSpeed: Int = 12

    /// Torpedo fuse time in ticks until automatic detonation
    static let torpedoFuse: Int = 40

    // MARK: - Timing

    /// Game update rate in Hz (updates per second)
    static let updateRate: Int = 20

    /// Game update interval in seconds (1/20 = 0.05)
    static let updateInterval: TimeInterval = 1.0 / 20.0

    // MARK: - Network

    /// Default Netrek server port
    static let defaultServerPort: Int = 2592

    /// Meta-server port for server list queries
    static let metaServerPort: Int = 3521

    /// Network receive buffer size (16KB)
    static let receiveBufferSize: Int = 16384

    /// Maximum packet buffer size (32KB)
    static let maxPacketBufferSize: Int = 32768

    /// Connection timeout in seconds
    static let connectionTimeout: TimeInterval = 10.0

    /// Socket protocol version
    static let socketVersion: UInt8 = 4

    /// UDP protocol version
    static let udpVersion: UInt8 = 10

    // MARK: - Well-Known Servers

    /// List of well-known Netrek servers
    static let wellKnownServers = [
        "pickled.netrek.org",
        "continuum.us.netrek.org"
    ]

    // MARK: - Debug Configuration

    #if DEBUG
    /// Auto-connect to localhost in debug builds
    static let debugAutoConnectLocalhost = true

    /// Debug server hostname
    static let debugServer = "localhost"
    #endif
}
