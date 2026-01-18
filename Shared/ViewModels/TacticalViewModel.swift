//
//  TacticalViewModel.swift
//  Netrek
//
//  ViewModel for the tactical (local) view showing nearby entities
//

import Foundation
import SwiftUI
import Combine

@MainActor
class TacticalViewModel: ObservableObject {

    // MARK: - Dependencies

    private let universe: Universe
    private weak var commandExecutor: GameCommandExecuting?

    // MARK: - Published State

    /// The current player
    @Published private(set) var me: Player

    /// Visible entities within tactical range
    @Published private(set) var visiblePlayers: [Player] = []
    @Published private(set) var visiblePlanets: [Planet] = []
    @Published private(set) var visibleTorpedoes: [Torpedo] = []
    @Published private(set) var visibleLasers: [Laser] = []
    @Published private(set) var visiblePlasmas: [Plasma] = []

    /// Exploding entities for animation
    @Published private(set) var explodingPlayers: [Player] = []
    @Published private(set) var explodingTorpedoes: [Torpedo] = []
    @Published private(set) var explodingPlasmas: [Plasma] = []

    /// Tractor beam targets
    @Published private(set) var visibleTractors: [Player] = []

    /// Visual display width (zoom level)
    @Published private(set) var visualWidth: CGFloat = 3000

    /// Current alert condition
    @Published private(set) var alertCondition: AlertCondition = .green

    // MARK: - Private State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(universe: Universe = .universe, commandExecutor: GameCommandExecuting? = nil) {
        self.universe = universe
        self.commandExecutor = commandExecutor
        self.me = universe.players[safe: universe.me] ?? Player(playerId: 0)

        setupBindings()
        refreshState()
    }

    // MARK: - Bindings

    private func setupBindings() {
        // Observe server updates to refresh visible entities
        universe.serverUpdate.$count
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

        // Observe visual width changes
        universe.$visualWidth
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newWidth in
                self?.visualWidth = newWidth
            }
            .store(in: &cancellables)
    }

    private func refreshState() {
        if let player = universe.players[safe: universe.me] {
            me = player
        }
        visiblePlayers = universe.visiblePlayers
        visiblePlanets = universe.visiblePlanets
        visibleTorpedoes = universe.visibleTorpedoes
        visibleLasers = universe.visibleLasers
        visiblePlasmas = universe.visiblePlasmas
        explodingPlayers = universe.explodingPlayers
        explodingTorpedoes = universe.explodingTorpedoes
        explodingPlasmas = universe.explodingPlasmas
        visibleTractors = universe.visibleTractors
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

    /// Convert screen coordinates to game coordinates
    /// - Parameters:
    ///   - screenLocation: The location on screen (in view coordinates)
    ///   - screenSize: The size of the view
    /// - Returns: The corresponding game world coordinates
    func gamePosition(from screenLocation: CGPoint, screenSize: CGSize) -> CGPoint {
        let meX = me.positionX
        let meY = me.positionY
        let diffX = Int(screenLocation.x) - (Int(screenSize.width) / 2)
        let diffY = screenLocation.y - (screenSize.height / 2)
        let deltaX = NetrekMath.displayDistance * diffX / Int(screenSize.width)
        let aspectRatio = screenSize.width / screenSize.height
        let deltaY = (CGFloat(NetrekMath.displayDistance) / aspectRatio) * diffY / screenSize.height
        let finalX = meX + deltaX
        let finalY = meY - Int(deltaY)
        return CGPoint(x: finalX, y: finalY)
    }

    // MARK: - View Helper Methods

    /// Calculate planet display width based on screen and visual width
    func planetWidth(screenWidth: CGFloat) -> CGFloat {
        return screenWidth * 300 / visualWidth
    }

    /// Calculate player display width based on screen and visual width
    func playerWidth(screenWidth: CGFloat) -> CGFloat {
        return screenWidth * 160 / visualWidth
    }

    /// Calculate torpedo display width
    func torpedoWidth(screenWidth: CGFloat) -> CGFloat {
        return screenWidth * 30 / visualWidth
    }

    /// Calculate plasma display width
    func plasmaWidth(screenWidth: CGFloat) -> CGFloat {
        return screenWidth * 80 / visualWidth
    }
}

// MARK: - Preview Support

#if DEBUG
extension TacticalViewModel {
    /// Creates a TacticalViewModel with mock data for previews
    static var preview: TacticalViewModel {
        // For previews, we use the default universe
        // In Phase 4, we'll enhance this with proper mock injection
        TacticalViewModel()
    }
}
#endif
