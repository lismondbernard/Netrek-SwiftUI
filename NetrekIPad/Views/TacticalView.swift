//
//  TacticalView.swift
//  NetrekIPad
//
//  Created by Darrell Root on 6/7/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI

struct TacticalView: View, TacticalOffset {

    #if os(macOS)
    // Safe optional access - won't crash if delegate is nil or wrong type
    var appDelegate: AppDelegate? {
        return NSApplication.shared.delegate as? AppDelegate
    }
    let minHeight: CGFloat? = 500
    #elseif os(iOS)
    // Safe optional access - won't crash if delegate is nil or wrong type
    var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
    let minHeight: CGFloat? = nil
    #endif

    @EnvironmentObject var universe: Universe
    var me: Player
    @ObservedObject var help: Help
    @State var lastLaser = Date()
    @State var nextCommand = ""
    @Environment(\.horizontalSizeClass) var hSizeClass
    @Environment(\.verticalSizeClass) var vSizeClass

    @GestureState var scale: CGFloat = 1.0
    
    var bigText: Font {
        guard let vSizeClass = vSizeClass else {
            return Font.headline
        }
        switch vSizeClass {
        case .regular:
            return .title
        case .compact:
            return .headline
        }
    }
    var regularText: Font {
        guard let vSizeClass = vSizeClass else {
            return Font.body
        }
        switch vSizeClass {
            
        case .regular:
            return .headline
        case .compact:
            return Font.body
        }
    }

    
    @State var pt: CGPoint = CGPoint() {
        didSet {
            debugPrint("point \(pt)")
        }
    }

    func visualHeight(viewWidth: CGFloat, viewHeight: CGFloat) -> CGFloat {
        return self.universe.visualWidth * (viewHeight / viewWidth)
    }

    var body: some View {
        return GeometryReader { geo in

            return ZStack {
                // Phase 2.1: Canvas-based rendering replaces ForEach loops for performance
                TacticalCanvasView(
                    me: self.me,
                    screenWidth: geo.size.width,
                    screenHeight: geo.size.height
                )

                // UI Overlays
                HelpView(help: self.help)
                VStack {
                    Spacer()
                    Text(self.universe.lastMessage)
                        .font(self.bigText)
                }

                Text(self.nextCommand)
                    .offset(y: -geo.size.height / 4)
                    .font(self.bigText)
                    .foregroundColor(Color.red)

                // Strategic views (outside tactical range)
                ForEach(self.universe.planets, id: \.planetId) { planet in
                    IosPlanetStrategicView(planet: planet, me: self.me, screenWidth: geo.size.width, screenHeight: geo.size.height)
                        .offset(x: IosPlanetStrategicView.xPos(me: self.me, planet: planet, size: geo.size),y: IosPlanetStrategicView.yPos(me: self.me, planet: planet, size: geo.size))
                }

                ForEach(self.universe.alivePlayers, id: \.playerId) { player in
                    IosPlayerStrategicView(player: player, me: self.me, screenWidth: geo.size.width, screenHeight: geo.size.height)
                        .offset(x: IosPlayerStrategicView.xPos(me: self.me, player: player, size: geo.size),y: IosPlayerStrategicView.yPos(me: self.me, player: player, size: geo.size))
                }

                // Interaction overlay - captures gestures
                Rectangle().opacity(0.01)
                .gesture(MagnificationGesture()
                    .updating(self.$scale, body: { (value, scale, transaction) in
                        scale = value.magnitude
                        self.universe.visualWidth = 3000 / scale
                    })
            )
                    .gesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .local)
                        .onEnded { gesture in
                            self.nextCommand = ""
                            let startLocation = gesture.startLocation
                            let endLocation = gesture.predictedEndLocation
                            debugPrint("drag gesture startLocation \(startLocation) endLocation \(endLocation)")
                            let tapXfromCenter = abs(geo.size.width / 2 - endLocation.x)
                            let tapYfromCenter = abs(geo.size.height / 2 - endLocation.y)
                            let percentTapXFromCenter = tapXfromCenter / (geo.size.width / 2)
                            let percentTapYFromCenter = tapYfromCenter / (geo.size.height / 2)

                            let tapPercentSquared = percentTapXFromCenter * percentTapXFromCenter + percentTapYFromCenter * percentTapYFromCenter

                            let boundary: CGFloat = 0.3
                            if tapPercentSquared > boundary {
                                self.mouseDown(control: .rightMouse, eventLocation: endLocation, size: geo.size)
                            } else {
                                self.mouseDown(control: .leftMouse, eventLocation: endLocation, size: geo.size)
                            }
                        }
                )
            }
        }
        .frame(minWidth: 500, idealWidth: 800, maxWidth: nil, minHeight: minHeight, idealHeight: 800, maxHeight: nil, alignment: .center)
        .border(me.alertCondition.color)
    }
    
    func netrekLocation(eventLocation: CGPoint, size: CGSize) -> CGPoint {
        let meX = universe.players[universe.me].positionX
        let meY = universe.players[universe.me].positionY
        let diffX = Int(eventLocation.x) - (Int(size.width) / 2)
        let diffY = Int(eventLocation.y) - (Int(size.height) / 2)
        let deltaX = NetrekMath.displayDistance * diffX / Int(size.width)
        let deltaY = NetrekMath.displayDistance * diffY / Int(size.height)
        let finalX = meX + deltaX
        let finalY = meY - deltaY
        return CGPoint(x: finalX, y: finalY)
    }
	
    func mouseDown(control: Control, eventLocation: CGPoint, size: CGSize) {
        let location = netrekLocation(eventLocation: eventLocation, size: size)
        self.appDelegate?.keymapController.execute(control,location: location)
    }

}

#if DEBUG
#Preview {
    let _ = PreviewHelpers.setupPreviewUniverse()
    let universe = Universe.universe
    let me = universe.players[universe.me]

    TacticalView(
        me: me,
        help: Help()
    )
    .environmentObject(universe)
    .frame(width: PreviewHelpers.screenWidthiPad, height: PreviewHelpers.screenHeightiPad)
}
#endif
