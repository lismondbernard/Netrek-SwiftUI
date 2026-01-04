//
//  ViewModelFactory.swift
//  Netrek
//
//  Factory for creating and configuring ViewModels with their dependencies
//

import Foundation

/// Factory for creating ViewModels with proper dependency injection
/// This allows views to be decoupled from concrete implementations
/// and enables testing with mock dependencies.
@MainActor
class ViewModelFactory {

    // MARK: - Singleton

    /// Shared instance for production use
    static let shared = ViewModelFactory()

    // MARK: - Dependencies

    private var universe: Universe
    private weak var commandExecutor: GameCommandExecuting?
    private weak var networkSender: NetworkSending?
    private weak var gameStateProvider: GameStateProviding?

    // MARK: - Initialization

    private init() {
        self.universe = Universe.universe
    }

    // MARK: - Configuration

    /// Configure the factory with dependencies from AppDelegate
    /// Call this during app initialization after AppDelegate is set up
    /// - Parameters:
    ///   - commandExecutor: The command executor (typically KeymapController)
    ///   - networkSender: The network sender (typically AppDelegate or TcpReader)
    ///   - gameStateProvider: The game state provider (typically AppDelegate)
    func configure(
        commandExecutor: GameCommandExecuting?,
        networkSender: NetworkSending?,
        gameStateProvider: GameStateProviding? = nil
    ) {
        self.commandExecutor = commandExecutor
        self.networkSender = networkSender
        self.gameStateProvider = gameStateProvider
    }

    // MARK: - ViewModel Creation

    /// Create a TacticalViewModel configured with dependencies
    func makeTacticalViewModel() -> TacticalViewModel {
        let viewModel = TacticalViewModel(universe: universe, commandExecutor: commandExecutor)
        return viewModel
    }

    /// Create a StrategicViewModel configured with dependencies
    func makeStrategicViewModel() -> StrategicViewModel {
        let viewModel = StrategicViewModel(universe: universe, commandExecutor: commandExecutor)
        return viewModel
    }

    /// Create a MessagesViewModel configured with dependencies
    func makeMessagesViewModel() -> MessagesViewModel {
        let viewModel = MessagesViewModel(
            universe: universe,
            networkSender: networkSender,
            gameStateProvider: gameStateProvider
        )
        return viewModel
    }

    /// Create a StatisticsViewModel configured with dependencies
    func makeStatisticsViewModel() -> StatisticsViewModel {
        let viewModel = StatisticsViewModel(universe: universe)
        return viewModel
    }

    // MARK: - Testing Support

    #if DEBUG
    /// Create a factory configured for testing/previews
    /// - Parameters:
    ///   - universe: The universe to use (can be mock)
    ///   - commandExecutor: Optional command executor
    ///   - networkSender: Optional network sender
    /// - Returns: A configured factory for testing
    static func forTesting(
        universe: Universe = .universe,
        commandExecutor: GameCommandExecuting? = nil,
        networkSender: NetworkSending? = nil
    ) -> ViewModelFactory {
        let factory = ViewModelFactory()
        factory.universe = universe
        factory.commandExecutor = commandExecutor
        factory.networkSender = networkSender
        return factory
    }
    #endif
}
