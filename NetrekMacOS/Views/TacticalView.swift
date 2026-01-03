//
//  TacticalView.swift
//  Netrek2
//
//  Created by Darrell Root on 5/5/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI


struct TacticalView: View, TacticalOffset {

    #if os(macOS)
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    #elseif os(iOS)
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    #endif
    
    var universe = Universe.universe
    @ObservedObject var serverUpdate = Universe.universe.serverUpdate
    @ObservedObject var help: Help
    @ObservedObject var preferencesController: PreferencesController

    var fakeTorpedo = Torpedo(torpedoId: 999)
    var fakeLaser = Laser(laserId: 999)
    var fakePlasma = Plasma(plasmaId: 999)
    
    var body: some View {
        return GeometryReader { geo in
            ZStack {
                ZStack { //more than 10 items in function builder}
                    Rectangle().colorInvert()
                    HelpView(help: self.help,preferencesController: self.preferencesController)
                    BoundaryView(me: self.universe.players[self.universe.me], universe: self.universe, screenWidth: geo.size.width, screenHeight: geo.size.height)
                    ForEach(self.universe.visiblePlanets, id: \.planetId) { planet in
                        PlanetView(planet: planet, me: self.universe.players[self.universe.me], universe: self.universe, imageSize: self.planetWidth(screenWidth: geo.size.width, visualWidth: self.universe.visualWidth),screenWidth: geo.size.width, screenHeight: geo.size.height)
                    }
                    ForEach(self.universe.visiblePlayers, id: \.playerId) { player in
                        PlayerView(player: player, me: self.universe.players[self.universe.me], universe: self.universe, imageSize: self.playerWidth(screenWidth: geo.size.width, visualWidth: self.universe.visualWidth),screenWidth: geo.size.width, screenHeight: geo.size.height)
                            .frame(width: self.playerWidth(screenWidth: geo.size.width, visualWidth: self.universe.visualWidth) * 3, height: self.playerWidth(screenWidth: geo.size.height, visualWidth: self.universe.visualWidth) * 3)
                                
                    }
                }
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
                ForEach(self.universe.visibleLasers, id: \.laserId) { laser in
                    LaserView(laser: laser, me: self.universe.players[self.universe.me], universe: self.universe, screenWidth: geo.size.width, screenHeight: geo.size.height)
                }
                ForEach(self.universe.visiblePlasmas, id: \.plasmaId) { plasma in
                    PlasmaView(plasma: plasma, me: self.universe.players[self.universe.me], universe: self.universe, screenWidth: geo.size.width, screenHeight: geo.size.height)
                }
                Rectangle().opacity(0.01).pointingMouse { event, location in
                    debugPrint("event \(event) location \(location)")
                    switch event.type {
                        
                    case .leftMouseDown:
                        self.mouseDown(control: .leftMouse,eventLocation: location, size: geo.size)
                    case .leftMouseDragged:
                        self.mouseDown(control: .leftMouse,eventLocation: location, size: geo.size)
                    case .rightMouseDragged:
                        self.mouseDown(control: .leftMouse,eventLocation: location, size: geo.size)
                    case .rightMouseDown:
                        self.mouseDown(control: .rightMouse,eventLocation: location, size: geo.size)

                    case .keyDown:
                        debugPrint("keydown not implemented")
                        self.keyDown(with: event, location: location)
                    case .otherMouseDown:
                        self.mouseDown(control: .otherMouse,eventLocation: location, size: geo.size)
                    default:
                        break
                    }
                }

                
            }
        }.frame(minWidth: 500, idealWidth: 800, maxWidth: nil, minHeight: 500, idealHeight: 800, maxHeight: nil, alignment: .center)
    }
    func mouseDown(control: Control, eventLocation: NSPoint, size: CGSize) {
        let meX = universe.players[universe.me].positionX
        let meY = universe.players[universe.me].positionY
        let diffX = Int(eventLocation.x) - (Int(size.width) / 2)
        let diffY = eventLocation.y - (size.height) / 2
        let deltaX = NetrekMath.displayDistance * diffX / Int(size.width)
        let aspectRatio = size.width / size.height
        let deltaY = (CGFloat(NetrekMath.displayDistance) / aspectRatio) * diffY / size.height
        let finalX = meX + deltaX
        let finalY = meY - Int(deltaY)
        let location = CGPoint(x: finalX, y: finalY)
        debugPrint("mouse down location \(location)")
        self.appDelegate.keymapController.execute(control,location: location)
    }
    
    func keyDown(with event: NSEvent, location: CGPoint) {
        debugPrint("TacticalScene.keyDown characters \(String(describing: event.characters))")
        guard let keymap = appDelegate.keymapController else {
            debugPrint("TacticalScene.keyDown unable to find keymapController")
            return
        }
       
        switch event.characters?.first {
        case "0":
            keymap.execute(.zeroKey, location: location)
        case "1":
            keymap.execute(.oneKey, location: location)
        case "2":
            keymap.execute(.twoKey, location: location)
        case "3":
            keymap.execute(.threeKey, location: location)
        case "4":
            keymap.execute(.fourKey, location: location)
        case "5":
            keymap.execute(.fiveKey, location: location)
        case "6":
            keymap.execute(.sixKey, location: location)
        case "7":
            keymap.execute(.sevenKey, location: location)
        case "8":
            keymap.execute(.eightKey, location: location)
        case "9":
            keymap.execute(.nineKey, location: location)
        case ")":
            keymap.execute(.rightParenKey, location: location)
        case "!": keymap.execute(.exclamationMarkKey, location: location)
        case "@": keymap.execute(.atKey, location: location)
        case "%": keymap.execute(.percentKey,location: location)
        case "#": keymap.execute(.poundKey,location: location)
        case "<":
            keymap.execute(.lessThanKey,location: location)
        case ">":
            keymap.execute(.greaterThanKey,location: location)
        case "]":
            keymap.execute(.rightBracketKey,location: location)
        case "[":
            keymap.execute(.leftBracketKey, location: location)
        case "{":
            keymap.execute(.leftCurly, location: location)
        case "}":
            keymap.execute(.rightCurly, location: location)
        case "_":
            keymap.execute(.underscore, location: location)
        case "^":
            keymap.execute(.carrot, location: location)
        case "$":
            keymap.execute(.dollar, location: location)
        case ";":
            keymap.execute(.semicolon, location: location)
        case "a":
            keymap.execute(.aKey, location: location)
        case "b":
            keymap.execute(.bKey, location: location)
        case "c":
            keymap.execute(.cKey, location: location)
        case "d":
            keymap.execute(.dKey, location: location)
        case "e":
            keymap.execute(.eKey, location: location)
        case "f":
            keymap.execute(.fKey, location: location)
        case "g":
            keymap.execute(.gKey, location: location)
        case "h":
            keymap.execute(.hKey, location: location)
        case "i":
            keymap.execute(.iKey, location: location)
        case "j":
            keymap.execute(.jKey, location: location)
        case "k":
            keymap.execute(.kKey, location: location)
        case "l":
            keymap.execute(.lKey, location: location)
        case "m":
            keymap.execute(.mKey, location: location)
        case "n":
            keymap.execute(.nKey, location: location)
        case "o":
            keymap.execute(.oKey, location: location)
        case "p":
            keymap.execute(.pKey, location: location)
        case "q":
            keymap.execute(.qKey, location: location)
        case "r":
            keymap.execute(.rKey, location: location)
        case "s":
            keymap.execute(.sKey, location: location)
        case "t":
            keymap.execute(.tKey, location: location)
        case "u":
            keymap.execute(.uKey, location: location)
        case "v":
            keymap.execute(.vKey, location: location)
        case "w":
            keymap.execute(.wKey, location: location)
        case "x":
            keymap.execute(.xKey, location: location)
        case "y":
            keymap.execute(.yKey, location: location)
        case "z":
            keymap.execute(.zKey, location: location)
        case "A":
            keymap.execute(.AKey, location: location)
        case "B":
            keymap.execute(.BKey, location: location)
        case "C":
            keymap.execute(.CKey, location: location)
        case "D":
            keymap.execute(.DKey, location: location)
        case "E":
            keymap.execute(.EKey, location: location)
        case "F":
            keymap.execute(.FKey, location: location)
        case "G":
            keymap.execute(.GKey, location: location)
        case "H":
            keymap.execute(.HKey, location: location)
        case "I":
            keymap.execute(.IKey, location: location)
        case "J":
            keymap.execute(.JKey, location: location)
        case "K":
            keymap.execute(.KKey, location: location)
        case "L":
            keymap.execute(.LKey, location: location)
        case "M":
            keymap.execute(.MKey, location: location)
        case "N":
            keymap.execute(.NKey, location: location)
        case "O":
            keymap.execute(.OKey, location: location)
        case "P":
            keymap.execute(.PKey, location: location)
        case "Q":
            keymap.execute(.QKey, location: location)
        case "R":
            keymap.execute(.RKey, location: location)
        case "S":
            keymap.execute(.SKey, location: location)
        case "T":
            keymap.execute(.TKey, location: location)
        case "U":
            keymap.execute(.UKey, location: location)
        case "V":
            keymap.execute(.VKey, location: location)
        case "W":
            keymap.execute(.WKey, location: location)
        case "X":
            keymap.execute(.XKey, location: location)
        case "Y":
            keymap.execute(.YKey, location: location)
        case "Z":
            keymap.execute(.ZKey, location: location)
        case "*":
            keymap.execute(.asteriskKey, location: location)
        case " ":
            keymap.execute(.spacebarKey, location: location)
        default:
            debugPrint("TacticalScene.TacticalView.keyDown unknown key \(String(describing: event.characters))")
        }
    }

}
