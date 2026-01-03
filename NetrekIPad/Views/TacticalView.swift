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
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    let minHeight: CGFloat? = 500
    #elseif os(iOS)
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let minHeight: CGFloat? = nil
    #endif
    
    @ObservedObject var serverUpdate = Universe.universe.serverUpdate

    var universe: Universe
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
    var fakeTorpedo = Torpedo(torpedoId: 999)
    var fakeLaser = Laser(laserId: 999)
    var fakePlasma = Plasma(plasmaId: 999)
    
    func visualHeight(viewWidth: CGFloat, viewHeight: CGFloat) -> CGFloat {
        return self.universe.visualWidth * (viewHeight / viewWidth)
    }
    
    var body: some View {
        return GeometryReader { geo in
            
            return ZStack {
                ZStack {
                    Rectangle().colorInvert()
                    HelpView(help: self.help)
                    VStack {
                        Spacer()
                        Text(self.universe.lastMessage)
                            .font(self.bigText)
                    }
                    BoundaryView(me: self.universe.players[self.universe.me], universe: self.universe, screenWidth: geo.size.width, screenHeight: geo.size.height)
                    
                    Text(self.nextCommand)
                        .offset(y: -geo.size.height / 4)
                        .font(self.bigText)
                        .foregroundColor(Color.red)
                    
                    ForEach(self.universe.visibleTractors, id: \.playerId) { target in
                        TractorView(target: target, me: self.universe.players[self.universe.me], universe: self.universe, screenWidth: geo.size.width, screenHeight: geo.size.height)
                    }
                    
                    ForEach(self.universe.explodingPlayers, id: \.playerId) { player in
                        ExplosionView(player: player, me: self.universe.players[self.universe.me], universe: self.universe, screenWidth: geo.size.width, screenHeight: geo.size.height)
                    }
                     ForEach(self.universe.visibleTorpedoes, id: \.torpedoId) { torpedo in
                        
                        TorpedoView(torpedo: torpedo, me: self.universe.players[self.universe.me], universe: self.universe, screenWidth: geo.size.width, screenHeight: geo.size.height)
                    }
                    ForEach(self.universe.explodingTorpedoes, id: \.torpedoId) { torpedo in
                        DetonationView(torpedo: torpedo, me: self.universe.players[self.universe.me], universe: self.universe, screenWidth: geo.size.width, screenHeight: geo.size.height)
                    }
                    ForEach(self.universe.explodingPlasmas, id: \.plasmaId) { plasma in
                        DetonationPlasmaView(plasma: plasma, me: self.universe.players[self.universe.me], universe: self.universe, screenWidth: geo.size.width, screenHeight: geo.size.height)
                    }
                }

                ForEach(self.universe.visibleLasers, id: \.laserId) { laser in
                    LaserView(laser: laser, me: self.universe.players[self.universe.me], universe: self.universe,screenWidth: geo.size.width, screenHeight: geo.size.height)
                }
                ForEach(self.universe.visiblePlasmas, id: \.plasmaId) { plasma in
                    PlasmaView(plasma: plasma, me: self.universe.players[self.universe.me], universe: self.universe, screenWidth: geo.size.width, screenHeight: geo.size.height)
                }
                ForEach(self.universe.planets, id: \.planetId) { planet in
                    IosPlanetStrategicView(planet: planet, me: self.me, universe: self.universe, screenWidth: geo.size.width, screenHeight: geo.size.height)
                        .offset(x: IosPlanetStrategicView.xPos(me: self.me, planet: planet, size: geo.size),y: IosPlanetStrategicView.yPos(me: self.me, planet: planet, size: geo.size))
                }

                ForEach(self.universe.alivePlayers, id: \.playerId) { player in
                    IosPlayerStrategicView(player: player, me: self.me, universe: self.universe, screenWidth: geo.size.width, screenHeight: geo.size.height)
                        .offset(x: IosPlayerStrategicView.xPos(me: self.me, player: player, size: geo.size),y: IosPlayerStrategicView.yPos(me: self.me, player: player, size: geo.size))
                }
                ForEach(self.universe.visibleFriendlyPlayers, id: \.playerId) { player in
                    PlayerView(player: player, me: self.universe.players[self.universe.me], universe: self.universe, imageSize: self.playerWidth(screenWidth: geo.size.width, visualWidth: self.universe.visualWidth), screenWidth: geo.size.width, screenHeight: geo.size.height)
                        .frame(width: self.playerWidth(screenWidth: geo.size.width, visualWidth: self.universe.visualWidth) * 3, height: self.playerWidth(screenWidth: geo.size.height, visualWidth: self.universe.visualWidth) * 3)
                }

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
                ForEach(self.universe.visiblePlanets, id: \.planetId) { planet in
                    PlanetView(planet: planet, me: self.universe.players[self.universe.me], universe: self.universe, imageSize: self.planetWidth(screenWidth: geo.size.width, visualWidth: self.universe.visualWidth),screenWidth: geo.size.width, screenHeight: geo.size.height)
                        .frame(width: self.planetWidth(screenWidth: geo.size.width, visualWidth: self.universe.visualWidth) * 3, height: self.planetWidth(screenWidth: geo.size.width, visualWidth: self.universe.visualWidth) * 3)
                        .onTapGesture {
                            debugPrint("tap gesture planet lock on")
                            
                            self.appDelegate.keymapController.execute(.lKey, location: CGPoint(x: planet.positionX, y: planet.positionY))
                    }

                }

                ForEach(self.universe.visibleEnemyPlayers, id: \.playerId) { player in
                    PlayerView(player: player, me: self.universe.players[self.universe.me], universe: self.universe, imageSize: self.playerWidth(screenWidth: geo.size.width,visualWidth: self.universe.visualWidth), screenWidth: geo.size.width, screenHeight: geo.size.height)
                        .frame(width: self.playerWidth(screenWidth: geo.size.width, visualWidth: self.universe.visualWidth) * 3, height: self.playerWidth(screenWidth: geo.size.height,visualWidth: self.universe.visualWidth) * 3)
                        .onTapGesture {
                            debugPrint("tap gesture laser")
                            let PHASEDIST = 600
                            let ship = player.ship ?? .cruiser
                            let phaserRange = PHASEDIST * (self.universe.shipInfo[ship]?.phaserRange ?? 100) / 100 // cruiser ends up at 600, bb ends up at 630
                            let phaserRangeSquared = phaserRange * phaserRange
                            let timeSinceLaser = Date().timeIntervalSince(self.lastLaser)
                            let phaserRecharge = self.universe.shipInfo[ship]?.phaserRecharge ?? 1.0
                            let rangeSquared = (self.me.positionX - player.positionX) * (self.me.positionX - player.positionX) + (self.me.positionY - player.positionY) * (self.me.positionY - player.positionY)
                            
                            if rangeSquared < phaserRangeSquared && timeSinceLaser > phaserRecharge {
                                // fire phaser
                                debugPrint("phaser firing timeSinceLaser \(timeSinceLaser)")
                                if player.team != self.universe.players[self.universe.me].team {
                                    self.appDelegate.keymapController.execute(.otherMouse, location: CGPoint(x: player.positionX, y: player.positionY))
                                }
                                self.lastLaser = Date()
                            } else {
                                // fire torpedo
                                debugPrint("phaser not available, firing torpedo timeSinceLaser \(timeSinceLaser)")
                                if player.team != self.universe.players[self.universe.me].team {
                                    self.appDelegate.keymapController.execute(.leftMouse, location: CGPoint(x: player.positionX, y: player.positionY))
                                }
                            }
                            debugPrint("phaser me \(self.me.positionX) \(self.me.positionY) target \(player.positionX) \(player.positionY)")
                            debugPrint("phaser range \(sqrt(Double(rangeSquared)))")

                    }
                }
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
        self.appDelegate.keymapController.execute(control,location: location)
    }
    
}
