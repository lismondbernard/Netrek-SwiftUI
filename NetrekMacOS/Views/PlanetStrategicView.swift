//
//  PlanetView.swift
//  Netrek2
//
//  Created by Darrell Root on 5/6/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI

struct PlanetStrategicView: View, StrategicOffset {
    var planet: Planet
    @EnvironmentObject var universe: Universe
    var me: Player
    var body: some View {
        return GeometryReader { geo in
            ZStack {
                Text(self.planet.shortName).foregroundColor(self.planet.seen[self.me.team]! ? NetrekMath.color(team: self.planet.owner) : .gray).fontWeight((self.planet.armies > 4 && self.planet.seen[self.me.team]!) ? .heavy : .regular)
            }
            .offset(x: self.screenX(netrekPositionX: self.planet.positionX, screenWidth: geo.size.width), y: self.screenY(netrekPositionY: self.planet.positionY, screenHeight: geo.size.height))
        }
    }
}

#if DEBUG
#Preview {
    let _ = PreviewHelpers.setupPreviewUniverse()
    let universe = Universe.universe
    let me = universe.players[universe.me]
    let planet = universe.planets[0]

    return PlanetStrategicView(planet: planet, me: me)
        .environmentObject(universe)
        .frame(width: PreviewHelpers.screenWidthMac, height: PreviewHelpers.screenHeightMac)
}
#endif
