//
//  PlanetView.swift
//  Netrek2
//
//  Created by Darrell Root on 5/6/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI

struct PlanetView: View, TacticalOffset {
    @ObservedObject var planet: Planet
    @ObservedObject var me: Player
    @EnvironmentObject var universe: Universe

	var imageSize: CGFloat
    var screenWidth: CGFloat
    var screenHeight: CGFloat

    var body: some View {
            VStack {
                Text(" ").fontWeight(self.planet.armies > 4 ? .heavy : .light)
                Image(self.planet.imageName(myTeam: self.me.team))
                .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: self.planetWidth(screenWidth: self.screenWidth, visualWidth: self.universe.visualWidth), height: self.planetWidth(screenWidth: self.screenHeight, visualWidth: self.universe.visualWidth))
                    .colorMultiply(self.planet.seen[self.me.team]! ? NetrekMath.color(team: self.planet.owner) : Color.gray)
                    .contentShape(Rectangle())
                Text(self.planet.name).fontWeight((self.planet.armies > 4 && self.planet.seen[self.me.team]!) ? .heavy : .light)
            }
			.offset(x: self.xOffset(positionX: self.planet.positionX, myPositionX: self.me.positionX,tacticalWidth: self.screenWidth, visualWidth: self.universe.visualWidth), y: self.yOffset(positionY: self.planet.positionY, myPositionY: self.me.positionY, tacticalHeight: self.screenHeight, visualHeight: self.universe.visualWidth * self.screenHeight / self.screenWidth))
			.animation(Animation.linear(duration: 0.1))
    }
    
}

#if DEBUG
#Preview {
    let _ = PreviewHelpers.setupPreviewUniverse()
    let universe = Universe.universe
    let me = universe.players[universe.me]
    let planet = universe.planets[0]

    PlanetView(
        planet: planet,
        me: me,
        imageSize: PreviewHelpers.planetImageSize,
        screenWidth: PreviewHelpers.screenWidthMac,
        screenHeight: PreviewHelpers.screenHeightMac
    )
    .environmentObject(universe)
}
#endif
