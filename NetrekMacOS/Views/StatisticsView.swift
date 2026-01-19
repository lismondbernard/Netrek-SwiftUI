//
//  StatisticsView.swift
//  Netrek2
//
//  Created by Darrell Root on 5/9/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var universe: Universe
    var me: Player
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Speed \(me.speed)")
                Text("Shield \(me.shieldStrength)")
                Text("Damage \(me.damage)")
                Text("Armies \(me.armies)")
                Text("Fuel \(me.fuel)")
                Text("Etmp \(me.engineTemp / 10)")
                Text("Wtmp \(me.weaponsTemp / 10)")
            }.font(.system(.body, design: .monospaced))
            HStack {
                if me.tractorFlag { Text("Tractor") }
                if me.pressor { Text("Pressor")}
                if me.enginesOverheated { Text("EngineFail")}
            }.font(.system(.body, design: .monospaced))
            ForEach(self.universe.activePlayers, id: \.playerId) { player in
                HStack {
                    Text("\(NetrekMath.teamLetter(team: player.team))\(NetrekMath.playerLetter(playerId: player.playerId))")
                    Text("                ").overlay(Text(player.name))
                    //Text(player.name)
                    Text("               ").overlay(Text(player.rank.description))
                    //Text(player.rank.description)
                    Text(player.ship?.description ?? "??")
                    Text("Kills \(player.kills,specifier: "%.2f")")
                }.padding(.leading)
                    .font(.system(.body, design: .monospaced))
                .foregroundColor(NetrekMath.color(team: player.team))
            }
            Spacer()
        }.padding(10)
    }
}

#if DEBUG
#Preview {
    let _ = PreviewHelpers.setupPreviewUniverse()
    let universe = Universe.universe
    let me = universe.players[universe.me]

    StatisticsView(me: me)
        .environmentObject(universe)
}
#endif

