//
//  DetonationView.swift
//  Netrek2
//
//  Created by Darrell Root on 5/31/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI

struct DetonationView: View, TacticalOffset {
    @ObservedObject var torpedo: Torpedo
    @ObservedObject var me: Player
    @EnvironmentObject var universe: Universe
    var screenWidth: CGFloat
    var screenHeight: CGFloat

    @State var scale: CGFloat = 0.0
    @State var opacity: Double = 1.0
    
    var body: some View {
        return GeometryReader { geo in
            Circle()
                .scale(self.scale)
                .fill(Color.red)
                .opacity(self.opacity)
                .frame(width: self.torpedoWidth(screenWidth: geo.size.width,visualWidth: self.universe.visualWidth), height: self.torpedoWidth(screenWidth: geo.size.height, visualWidth: self.universe.visualWidth))
                .offset(x: self.xOffset(positionX: self.torpedo.positionX, myPositionX: self.me.positionX,tacticalWidth: self.screenWidth, visualWidth: self.universe.visualWidth), y: self.yOffset(positionY: self.torpedo.positionY, myPositionY: self.me.positionY, tacticalHeight: geo.size.height, visualHeight: self.universe.visualWidth * self.screenHeight / self.screenWidth))
        }.onAppear {
            return withAnimation(.linear(duration: 1.0)) {
                self.scale = 6
                self.opacity = 0.0
            }
        }
    }
}

#if DEBUG
#Preview {
    let _ = PreviewHelpers.setupPreviewUniverse()
    let universe = Universe.universe
    let me = universe.players[universe.me]
    let torpedo = universe.torpedoes[0]

    let _ = {
        torpedo.positionX = me.positionX + 500
        torpedo.positionY = me.positionY - 200
        torpedo.status = 2  // exploding
    }()

    DetonationView(
        torpedo: torpedo,
        me: me,
        screenWidth: PreviewHelpers.screenWidthMac,
        screenHeight: PreviewHelpers.screenHeightMac
    )
    .environmentObject(universe)
}
#endif
