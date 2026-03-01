//
//  MockCommandExecutor.swift
//  NetrekTests
//
//  Mock implementation of GameCommandExecuting for unit tests
//

import Foundation
import CoreGraphics
@testable import Netrek

/// Mock command executor that captures executed commands for verification in tests
class MockCommandExecutor: GameCommandExecuting {

    // MARK: - Captured Commands

    /// Record of executed commands
    struct ExecutedCommand {
        let control: Control
        let location: CGPoint?
    }

    /// All commands that have been executed
    private(set) var executedCommands: [ExecutedCommand] = []

    /// Number of times execute was called
    var executeCallCount: Int {
        executedCommands.count
    }

    /// The last command that was executed
    var lastExecutedCommand: ExecutedCommand? {
        executedCommands.last
    }

    // MARK: - GameCommandExecuting

    func execute(_ control: Control, location: CGPoint?) {
        executedCommands.append(ExecutedCommand(control: control, location: location))
    }

    // MARK: - Test Helpers

    /// Clear all captured commands
    func reset() {
        executedCommands.removeAll()
    }

    /// Check if any commands were executed
    var didExecuteCommand: Bool {
        !executedCommands.isEmpty
    }

    /// Check if a specific control was executed
    func didExecute(control: Control) -> Bool {
        executedCommands.contains { $0.control == control }
    }

    /// Get all executions of a specific control
    func executions(of control: Control) -> [ExecutedCommand] {
        executedCommands.filter { $0.control == control }
    }
}
