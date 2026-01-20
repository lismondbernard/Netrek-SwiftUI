//
//  TorpedoView.swift
//  Netrek2
//
//  Created by Darrell Root on 5/7/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI

struct TorpedoView: View, TacticalOffset {
    var torpedo: Torpedo
    var me: Player
    @EnvironmentObject var universe: Universe
    var screenWidth: CGFloat
    var screenHeight: CGFloat

    var body: some View {
		self.torpedo.color
			.frame(width: self.torpedoWidth(screenWidth: self.screenWidth, visualWidth: self.universe.visualWidth), height: self.torpedoWidth(screenWidth: self.screenWidth, visualWidth: self.universe.visualWidth))
				.contentShape(Rectangle())
			.offset(x: self.xOffset(positionX: self.torpedo.positionX, myPositionX: self.me.positionX, tacticalWidth: self.screenWidth, visualWidth: self.universe.visualWidth), y: self.yOffset(positionY: self.torpedo.positionY, myPositionY: self.me.positionY, tacticalHeight: self.screenHeight, visualHeight: self.universe.visualWidth * self.screenHeight / self.screenWidth))
	}
}

#if DEBUG
#Preview {
    let _ = PreviewHelpers.setupPreviewUniverse()
    let universe = Universe.universe
    let me = universe.players[universe.me]
    let torpedo = universe.torpedoes[0]

    return TorpedoView(
        torpedo: torpedo,
        me: me,
        screenWidth: PreviewHelpers.screenWidthMac,
        screenHeight: PreviewHelpers.screenHeightMac
    )
    .environmentObject(universe)
}
#endif
