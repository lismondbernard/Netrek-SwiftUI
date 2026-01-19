//
//  GameLogger.swift
//  Netrek
//
//  Created as part of Phase 5.2: Implement Proper Logging
//  Provides structured logging with categories and log levels
//

import Foundation
import OSLog

/// Log categories for different subsystems
enum LogCategory: String {
    case network = "Network"
    case gameState = "GameState"
    case packets = "Packets"
    case ui = "UI"
    case performance = "Performance"
    case commands = "Commands"
    case input = "Input"
    case connection = "Connection"
}

/// Centralized logging utility for Netrek
///
/// Provides structured logging using OSLog with support for different categories
/// and log levels. Debug logs are automatically stripped in release builds.
///
/// Usage:
/// ```
/// GameLogger.info("Connected to server", category: .network)
/// GameLogger.debug("Packet received: \(packetType)", category: .packets)
/// GameLogger.error("Connection failed: \(error)", category: .network)
/// ```
enum GameLogger {

    /// The subsystem identifier for all Netrek logs
    private static let subsystem = "com.networkmom.netrek"

    /// Get an OSLog instance for a specific category
    /// - Parameter category: The log category
    /// - Returns: An OSLog instance configured for the category
    private static func logger(for category: LogCategory) -> OSLog {
        return OSLog(subsystem: subsystem, category: category.rawValue)
    }

    // MARK: - Public Logging Methods

    /// Log a debug message (only in DEBUG builds)
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The log category
    ///   - file: The file where the log was called (auto-populated)
    ///   - function: The function where the log was called (auto-populated)
    ///   - line: The line number where the log was called (auto-populated)
    static func debug(
        _ message: String,
        category: LogCategory,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        let log = logger(for: category)
        let fileName = (file as NSString).lastPathComponent
        os_log("[%{public}@:%d %{public}@] %{public}@",
               log: log,
               type: .debug,
               fileName,
               line,
               function,
               message)
        #endif
    }

    /// Log an informational message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The log category
    static func info(_ message: String, category: LogCategory) {
        let log = logger(for: category)
        os_log("%{public}@", log: log, type: .info, message)
    }

    /// Log a warning message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The log category
    static func warning(_ message: String, category: LogCategory) {
        let log = logger(for: category)
        os_log("%{public}@", log: log, type: .default, message)
    }

    /// Log an error message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The log category
    static func error(_ message: String, category: LogCategory) {
        let log = logger(for: category)
        os_log("%{public}@", log: log, type: .error, message)
    }

    /// Log a fault message (critical errors)
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The log category
    static func fault(_ message: String, category: LogCategory) {
        let log = logger(for: category)
        os_log("%{public}@", log: log, type: .fault, message)
    }

    // MARK: - Convenience Methods

    /// Log a network event
    static func network(_ message: String) {
        info(message, category: .network)
    }

    /// Log a network error
    static func networkError(_ message: String) {
        error(message, category: .network)
    }

    /// Log a game state change
    static func gameState(_ message: String) {
        info(message, category: .gameState)
    }

    /// Log packet information (debug only)
    static func packet(_ message: String) {
        debug(message, category: .packets)
    }

    /// Log a command execution
    static func command(_ message: String) {
        debug(message, category: .commands)
    }

    /// Log user input
    static func input(_ message: String) {
        debug(message, category: .input)
    }

    /// Log performance metrics
    static func performance(_ message: String) {
        debug(message, category: .performance)
    }
}

// MARK: - Legacy Compatibility

/// Temporary bridge for gradual migration from debugPrint
/// Will be removed in future version
@available(*, deprecated, message: "Use GameLogger instead")
func logDebug(_ message: String, category: LogCategory = .ui) {
    GameLogger.debug(message, category: category)
}
