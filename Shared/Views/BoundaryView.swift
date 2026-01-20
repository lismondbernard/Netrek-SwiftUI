//
//  BoundaryView.swift
//  Netrek2
//
//  Created by Darrell Root on 6/4/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI

struct BoundaryView: View, TacticalOffset {
    @ObservedObject var me: Player
    @EnvironmentObject var universe: Universe
    var screenWidth: CGFloat
    var screenHeight: CGFloat

    var body: some View {
        return GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: self.xOffset(positionX: 0, myPositionX: self.me.positionX, tacticalWidth: geo.size.width, visualWidth: self.universe.visualWidth), y: self.yOffset(positionY: 0, myPositionY: self.me.positionY, tacticalHeight: geo.size.width, visualHeight: self.universe.visualWidth * self.screenHeight / self.screenWidth)))
                path.addLine(to: CGPoint(x: self.xOffset(positionX: NetrekMath.galacticSize, myPositionX: self.me.positionX, tacticalWidth: geo.size.width, visualWidth: self.universe.visualWidth), y: self.yOffset(positionY: 0, myPositionY: self.me.positionY, tacticalHeight: geo.size.width, visualHeight: self.universe.visualWidth * self.screenHeight / self.screenWidth)))
                path.addLine(to: CGPoint(x: self.xOffset(positionX: NetrekMath.galacticSize, myPositionX: self.me.positionX, tacticalWidth: geo.size.width, visualWidth: self.universe.visualWidth), y: self.yOffset(positionY: NetrekMath.galacticSize, myPositionY: self.me.positionY, tacticalHeight: geo.size.width, visualHeight: self.universe.visualWidth * self.screenHeight / self.screenWidth)))
                path.addLine(to: CGPoint(x: self.xOffset(positionX: 0, myPositionX: self.me.positionX, tacticalWidth: geo.size.width, visualWidth: self.universe.visualWidth), y: self.yOffset(positionY: NetrekMath.galacticSize, myPositionY: self.me.positionY, tacticalHeight: geo.size.width, visualHeight: self.universe.visualWidth * self.screenHeight / self.screenWidth)))
                path.addLine(to: CGPoint(x: self.xOffset(positionX: 0, myPositionX: self.me.positionX, tacticalWidth: geo.size.width, visualWidth: self.universe.visualWidth), y: self.yOffset(positionY: 0, myPositionY: self.me.positionY, tacticalHeight: geo.size.width, visualHeight: self.universe.visualWidth * self.screenHeight / self.screenWidth)))
            }.offset(x: geo.size.width / 2, y: geo.size.height / 2)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: self.playerWidth(screenWidth: geo.size.width, visualWidth: self.universe.visualWidth)))
                .opacity(0.5)
                .animation(Animation.linear(duration: 0.1))
        }
    }
}

#if DEBUG
#Preview {
    let _ = PreviewHelpers.setupPreviewUniverse()
    let universe = Universe.universe
    let me = universe.players[universe.me]

    return BoundaryView(
        me: me,
        screenWidth: PreviewHelpers.screenWidthMac,
        screenHeight: PreviewHelpers.screenHeightMac
    )
    .environmentObject(universe)
}
#endif
