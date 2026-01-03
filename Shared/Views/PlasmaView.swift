//
//  PlasmaView.swift
//  Netrek2
//
//  Created by Darrell Root on 5/7/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI

struct PlasmaView: View, TacticalOffset {
    @ObservedObject var plasma: Plasma
    @ObservedObject var me: Player
    @ObservedObject var universe: Universe
    var screenWidth: CGFloat
    var screenHeight: CGFloat

    var body: some View {
		self.plasma.color
			.frame(width: self.plasmaWidth(screenWidth: self.screenWidth, visualWidth: self.universe.visualWidth), height: self.plasmaWidth(screenWidth: self.screenHeight, visualWidth: self.universe.visualWidth))
				.contentShape(Rectangle())
			.offset(x: self.xOffset(positionX: self.plasma.positionX, myPositionX: self.me.positionX,tacticalWidth: self.screenWidth, visualWidth: self.universe.visualWidth), y: self.yOffset(positionY: self.plasma.positionY, myPositionY: self.me.positionY, tacticalHeight: self.screenHeight, visualHeight: self.universe.visualWidth * self.screenHeight / self.screenWidth))
		.opacity(self.plasma.status == 1 ? 1 : 0)
    }
}
