//
//  StatisticsViewModel.swift
//  Netrek
//
//  ViewModel for the player statistics view
//

import Foundation
import SwiftUI
import Combine

@MainActor
class StatisticsViewModel: ObservableObject {

    // MARK: - Dependencies

    private let universe: Universe

    // MARK: - Published State

    /// The current player
    @Published private(set) var me: Player

    /// All active players (for player list)
    @Published private(set) var activePlayers: [Player] = []

    // MARK: - Ship Status (derived from me)

    @Published private(set) var speed: Int = 0
    @Published private(set) var shieldStrength: Int = 0
    @Published private(set) var damage: Int = 0
    @Published private(set) var armies: Int = 0
    @Published private(set) var fuel: Int = 0
    @Published private(set) var engineTemp: Int = 0
    @Published private(set) var weaponsTemp: Int = 0
    @Published private(set) var tractorFlag: Bool = false
    @Published private(set) var pressor: Bool = false
    @Published private(set) var enginesOverheated: Bool = false

    // MARK: - Private State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(universe: Universe = .universe) {
        self.universe = universe
        self.me = universe.players[universe.me]

        setupBindings()
        refreshState()
    }

    // MARK: - Bindings

    private func setupBindings() {
        // Observe second updates for statistics refresh
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
                self.me = self.universe.players[newMe]
                self.refreshPlayerStats()
            }
            .store(in: &cancellables)
    }

    private func refreshState() {
        me = universe.players[universe.me]
        activePlayers = universe.activePlayers
        refreshPlayerStats()
    }

    private func refreshPlayerStats() {
        speed = me.speed
        shieldStrength = me.shieldStrength
        damage = me.damage
        armies = me.armies
        fuel = me.fuel
        engineTemp = me.engineTemp
        weaponsTemp = me.weaponsTemp
        tractorFlag = me.tractorFlag
        pressor = me.pressor
        enginesOverheated = me.enginesOverheated
    }

    // MARK: - Computed Properties

    /// Engine temperature as percentage (0-100 scale for display)
    var engineTempDisplay: Int {
        engineTemp / 10
    }

    /// Weapons temperature as percentage (0-100 scale for display)
    var weaponsTempDisplay: Int {
        weaponsTemp / 10
    }

    /// Check if any warning flags are active
    var hasWarningFlags: Bool {
        tractorFlag || pressor || enginesOverheated
    }

    // MARK: - Player List Helpers

    /// Get player letter for display (e.g., "Fa" for Federation player 0)
    func playerIdentifier(for player: Player) -> String {
        let teamLetter = NetrekMath.teamLetter(team: player.team)
        let playerLetter = NetrekMath.playerLetter(playerId: player.playerId)
        return "\(teamLetter)\(playerLetter)"
    }

    /// Get color for a team
    func teamColor(for team: Team) -> Color {
        NetrekMath.color(team: team)
    }
}

// MARK: - Preview Support

#if DEBUG
extension StatisticsViewModel {
    /// Creates a StatisticsViewModel with mock data for previews
    static var preview: StatisticsViewModel {
        StatisticsViewModel()
    }
}
#endif
