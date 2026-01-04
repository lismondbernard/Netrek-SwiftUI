//
//  MessagesViewModel.swift
//  Netrek
//
//  ViewModel for the messages/chat view
//

import Foundation
import SwiftUI
import Combine

@MainActor
class MessagesViewModel: ObservableObject {

    // MARK: - Dependencies

    private let universe: Universe
    private weak var networkSender: NetworkSending?
    private weak var gameStateProvider: GameStateProviding?

    // MARK: - Published State

    /// Messages to display
    @Published private(set) var messages: ArraySlice<String> = []

    /// New message being composed
    @Published var newMessage: String = ""

    /// Toggle for sending to all vs team only
    @Published var sendToAll: Bool = true

    // MARK: - Private State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(universe: Universe = .universe,
         networkSender: NetworkSending? = nil,
         gameStateProvider: GameStateProviding? = nil) {
        self.universe = universe
        self.networkSender = networkSender
        self.gameStateProvider = gameStateProvider

        setupBindings()
        refreshMessages()
    }

    // MARK: - Bindings

    private func setupBindings() {
        // Observe message updates
        universe.$recentMessages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshMessages()
            }
            .store(in: &cancellables)
    }

    private func refreshMessages() {
        messages = universe.activeMessages
    }

    // MARK: - Configuration

    /// Configure dependencies (called by factory after initialization)
    func configure(networkSender: NetworkSending?, gameStateProvider: GameStateProviding?) {
        self.networkSender = networkSender
        self.gameStateProvider = gameStateProvider
    }

    // MARK: - Computed Properties

    /// The current player's team
    var myTeam: Team {
        universe.players[universe.me].team
    }

    /// The current player
    private var me: Player {
        universe.players[universe.me]
    }

    // MARK: - Actions

    /// Send the current message
    func sendMessage() {
        sendMessage(message: newMessage, toAll: sendToAll)
    }

    /// Send a message
    /// - Parameters:
    ///   - message: The message text
    ///   - toAll: If true, sends to all players. If false, sends to team only.
    func sendMessage(message: String, toAll: Bool) {
        guard !message.isEmpty else { return }

        let data: Data
        if toAll {
            data = MakePacket.cpMessage(message: message, team: .independent, individual: 0)
        } else {
            data = MakePacket.cpMessage(message: message, team: myTeam, individual: 0)
        }

        networkSender?.send(content: data)
        newMessage = ""
    }

    /// Send a MAYDAY distress signal to team
    func sendMayday() {
        guard let planet = findClosestPlanet() else { return }

        let message = "MAYDAY near \(planet.name) shields \(me.shieldStrength) damage \(me.damage) armies \(me.armies)"
        sendMessage(message: message, toAll: false)
    }

    /// Send an escort request to team
    func sendEscortRequest() {
        guard let planet = findClosestPlanet() else { return }

        let message = "Request Escort near \(planet.name) shields \(me.shieldStrength) damage \(me.damage) armies \(me.armies)"
        sendMessage(message: message, toAll: false)
    }

    // MARK: - Helper Methods

    /// Find the closest planet to the current player
    private func findClosestPlanet() -> Planet? {
        let myLocation = CGPoint(x: me.positionX, y: me.positionY)
        var closestDistance = Int.max
        var closestPlanet: Planet?

        for planet in universe.planets {
            let distance = abs(planet.positionX - Int(myLocation.x)) + abs(planet.positionY - Int(myLocation.y))
            if distance < closestDistance {
                closestDistance = distance
                closestPlanet = planet
            }
        }

        return closestPlanet
    }
}

// MARK: - Preview Support

#if DEBUG
extension MessagesViewModel {
    /// Creates a MessagesViewModel with mock data for previews
    static var preview: MessagesViewModel {
        let vm = MessagesViewModel()
        return vm
    }
}
#endif
