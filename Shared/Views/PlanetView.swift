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
    @ObservedObject var universe: Universe

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

#Preview {
    // Minimal mock implementations for preview purposes only
    // These should match the interfaces used by PlanetView.
    class MockUniverse: ObservableObject {
        @Published var visualWidth: CGFloat = 10000
    }
    class MockPlayer: ObservableObject {
        @Published var team: Int = 0
        @Published var positionX: CGFloat = 5000
        @Published var positionY: CGFloat = 5000
    }
    class MockPlanet: ObservableObject {
        @Published var name: String = "Earth"
        @Published var armies: Int = 5
        @Published var owner: Int = 0
        @Published var positionX: CGFloat = 5200
        @Published var positionY: CGFloat = 4800
        @Published var seen: [Int: Bool] = [0: true]
        func imageName(myTeam: Int) -> String { "planet" }
    }

    let planet = MockPlanet()
    let me = MockPlayer()
    let universe = MockUniverse()

    // Choose some reasonable preview sizes
    let screenWidth: CGFloat = 375
    let screenHeight: CGFloat = 667

    return PlanetView(
        planet: planet as! Planet, // If your real types exist, replace mocks with real sample instances
        me: me as! Player,
        universe: universe as! Universe,
        imageSize: 64,
        screenWidth: screenWidth,
        screenHeight: screenHeight
    )
}
