//
//  MessagesView.swift
//  Netrek2
//
//  Created by Darrell Root on 5/9/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var universe: Universe
    @EnvironmentObject var gameStateManager: GameStateManager
    @EnvironmentObject var connectionManager: ServerConnectionManager
    @State var newMessage: String = ""
    @State var sendToAll = true
    @FocusState var textFieldFocused

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                TextField("New Message", text: $newMessage, onCommit: sendMessage)
                    .focused($textFieldFocused)

                Text("Send To My Team")
                Toggle("", isOn: $sendToAll).toggleStyle(SwitchToggleStyle())
                Text("Send To All")
            }
            HStack {
                Button("Send MAYDAY") {
                    self.sendMayday()
                }
                Button("Request ESCORT") {
                    self.sendEscort()
                }
            }

            ForEach(universe.activeMessages, id: \.self) { message in
                Text(message)
            }
            Spacer()
        }.padding(10)
    }
    func sendMayday() {
        guard gameStateManager.gameState == .gameActive else { return }
        let me = universe.players[universe.me]
        let (planetOptional, _) = findClosestPlanet(location: CGPoint(x: me.positionX, y: me.positionY))
        guard let planet = planetOptional else { return }

        let message = "MAYDAY near \(planet.name) shields \(me.shieldStrength) damage \(me.damage) armies \(me.armies)"
        self.sendMessage(message: message, sendToAll: false)
    }
    func sendEscort() {
        guard gameStateManager.gameState == .gameActive else { return }
        let me = universe.players[universe.me]
        let (planetOptional, _) = findClosestPlanet(location: CGPoint(x: me.positionX, y: me.positionY))
        guard let planet = planetOptional else { return }

        let message = "Request Escort near \(planet.name) shields \(me.shieldStrength) damage \(me.damage) armies \(me.armies)"
        self.sendMessage(message: message, sendToAll: false)
    }

    func sendMessage() {
        self.sendMessage(message: newMessage, sendToAll: self.sendToAll)
    }
    func sendMessage(message: String, sendToAll: Bool) {
        if message.isEmpty {
            return
        }
        if sendToAll {
            let data = MakePacket.cpMessage(message: message, team: .independent, individual: 0)
            connectionManager.send(content: data)
            self.newMessage = ""
        } else {
            let data = MakePacket.cpMessage(message: message, team: self.universe.players[self.universe.me].team, individual: 0)
            connectionManager.send(content: data)
            self.newMessage = ""
        }
    }
    private func findClosestPlanet(location: CGPoint) -> (planet: Planet?, distance: Int) {
        var closestPlanetDistance = 10000
        var closestPlanet: Planet?
        for planet in universe.planets {
            let thisPlanetDistance = abs(planet.positionX - Int(location.x)) + abs(planet.positionY - Int(location.y))
            if thisPlanetDistance < closestPlanetDistance {
                closestPlanetDistance = thisPlanetDistance
                closestPlanet = planet
            }
        }
        return (closestPlanet, closestPlanetDistance)
    }
}

#if DEBUG
#Preview {
    let _ = PreviewHelpers.setupPreviewUniverse()
    let universe = Universe.universe

    return MessagesView()
        .environmentObject(universe)
}
#endif
