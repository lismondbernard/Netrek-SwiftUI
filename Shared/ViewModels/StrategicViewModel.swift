//
//  StrategicViewModel.swift
//  Netrek
//
//  ViewModel for the strategic (galactic) view showing all entities
//

import Foundation
import SwiftUI
import Combine

@MainActor
class StrategicViewModel: ObservableObject {
    // MARK: - Dependencies

    private let universe: Universe
    private weak var commandExecutor: GameCommandExecuting?

    // MARK: - Published State

    /// The current player
    @Published private(set) var me: Player

    /// All players in the game
    @Published private(set) var players: [Player] = []

    /// All planets in the game
    @Published private(set) var planets: [Planet] = []

    /// Current alert condition
    @Published private(set) var alertCondition: AlertCondition = .green

    // MARK: - Constants

    let maxPlayers: Int
    let maxPlanets: Int

    // MARK: - Private State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(universe: Universe = .universe, commandExecutor: GameCommandExecuting? = nil) {
        self.universe = universe
        self.commandExecutor = commandExecutor
        self.me = universe.players[safe: universe.me] ?? Player(playerId: 0)
        self.maxPlayers = universe.maxPlayers
        self.maxPlanets = universe.maxPlanets

        setupBindings()
        refreshState()
    }

    // MARK: - Bindings

    private func setupBindings() {
        // Observe second updates for strategic view (lower frequency than tactical)
        universe.seconds.$count
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshState()
            }
            .store(in: &cancellables)

        // Observe changes to "me" index
        universe.$me
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMe in
                guard let self = self else { return }
                if let player = self.universe.players[safe: newMe] {
                    self.me = player
                }
            }
            .store(in: &cancellables)
    }

    private func refreshState() {
        if let player = universe.players[safe: universe.me] {
            me = player
        }
        players = universe.players
        planets = universe.planets
        alertCondition = me.alertCondition
    }

    // MARK: - Command Execution

    /// Configure the command executor (called by factory after initialization)
    func configure(commandExecutor: GameCommandExecuting?) {
        self.commandExecutor = commandExecutor
    }

    /// Execute a control action at a game location
    func executeControl(_ control: Control, at location: CGPoint) {
        commandExecutor?.execute(control, location: location)
    }

    // MARK: - Coordinate Conversion

    /// Convert screen coordinates to game coordinates for strategic map
    /// - Parameters:
    ///   - screenLocation: The location on screen (in view coordinates)
    ///   - screenSize: The size of the view
    /// - Returns: The corresponding game world coordinates
    func gamePosition(from screenLocation: CGPoint, screenSize: CGSize) -> CGPoint {
        let netrekX = CGFloat(NetrekMath.galacticSize) * screenLocation.x / screenSize.width
        let netrekY = CGFloat(NetrekMath.galacticSize) - (CGFloat(NetrekMath.galacticSize) * screenLocation.y / screenSize.height)
        return CGPoint(x: netrekX, y: netrekY)
    }

    /// Convert game coordinates to screen coordinates for strategic map
    /// - Parameters:
    ///   - netrekPosition: The game world position
    ///   - screenSize: The size of the view
    /// - Returns: The corresponding screen coordinates
    func screenPosition(from netrekPosition: CGPoint, screenSize: CGSize) -> CGPoint {
        let screenX = netrekPosition.x / CGFloat(NetrekMath.galacticSize) * screenSize.width
        let screenY = screenSize.height - (netrekPosition.y / CGFloat(NetrekMath.galacticSize) * screenSize.height)
        return CGPoint(x: screenX, y: screenY)
    }

    // MARK: - View Helper Methods

    /// Get player at specific index (for ForEach with indices)
    func player(at index: Int) -> Player? {
        guard index >= 0 && index < players.count else { return nil }
        return players[index]
    }

    /// Get planet at specific index (for ForEach with indices)
    func planet(at index: Int) -> Planet? {
        guard index >= 0 && index < planets.count else { return nil }
        return planets[index]
    }
}

// MARK: - Preview Support

#if DEBUG
extension StrategicViewModel {
    /// Creates a StrategicViewModel with mock data for previews
    static var preview: StrategicViewModel {
        StrategicViewModel()
    }
}
#endif
