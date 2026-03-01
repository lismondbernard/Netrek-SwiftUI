//
//  GameConstants.swift
//  Netrek
//
//  Centralized game configuration constants
//  Replaces scattered magic numbers throughout the codebase
//

import Foundation

/// Game-wide configuration constants
enum GameConstants {
    // MARK: - Game Timing

    /// Update rate for game loop (updates per second)
    /// Matches UPDATE_RATE in Globals.swift (20 Hz)
    static let updateRate: Double = 20.0

    /// Timer interval for main game loop
    static let timerInterval: Double = 1.0 / updateRate

    // MARK: - Network Configuration

    /// Default game server port
    static let defaultPort: Int = 2592

    /// Metaserver port for server list
    static let metaserverPort: Int = 3521

    /// Primary metaserver hostname
    static let metaserverPrimary = "metaserver.netrek.org"

    /// Backup metaserver hostname
    static let metaserverBackup = "metaserver2.netrek.org"

    /// Well-known port for pre-configured servers
    static let wellKnownPort: Int = 2592

    // MARK: - Debug Configuration

    #if DEBUG
    /// Whether to auto-connect to debug server on launch
    static let debugAutoConnect = false

    /// Debug server hostname for auto-connection
    static let debugServer = "localhost"
    #endif

    // MARK: - Client Features

    /// Client feature flags sent to server
    static let clientFeatures = ["FEATURE_PACKETS", "SHIP_CAP", "SP_GENERIC_32", "TIPS"]
}

// MARK: - Backward Compatibility Notes
//
// The following constants are still defined in Globals.swift:
// - UPDATE_RATE (20) - Use GameConstants.updateRate instead
// - WELLKNOWNPORT (2592) - Use GameConstants.wellKnownPort instead
// - WELLKNOWNSERVERS - Array of server hostnames
//
// These will be migrated to GameConstants in a future refactor.
// For now, GameConstants provides additional configuration that
// doesn't conflict with existing Globals.swift definitions.
