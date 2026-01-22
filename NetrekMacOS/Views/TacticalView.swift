//
//  TacticalView.swift
//  Netrek2
//
//  Created by Darrell Root on 5/5/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import SwiftUI


struct TacticalView: View, TacticalOffset {
    @EnvironmentObject var universe: Universe
    @EnvironmentObject var keymapController: KeymapController
    @ObservedObject var help: Help
    @ObservedObject var preferencesController: PreferencesController

    var body: some View {
        return GeometryReader { geo in
            ZStack {
                // Phase 2.1: Canvas-based rendering replaces ForEach loops for performance
                TacticalCanvasView(
                    me: self.universe.players[self.universe.me],
                    screenWidth: geo.size.width,
                    screenHeight: geo.size.height
                )

                // Overlays
//                HelpView(help: self.help, preferencesController: self.preferencesController)

                // Interaction overlay - captures mouse/keyboard events
                Rectangle().opacity(0.01).pointingMouse { event, location in
                    GameLogger.debug("event \(event) location \(location)", category: .ui)
                    switch event.type {
                    case .leftMouseDown:
                        self.mouseDown(control: .leftMouse, eventLocation: location, size: geo.size)
                    case .leftMouseDragged:
                        self.mouseDown(control: .leftMouse, eventLocation: location, size: geo.size)
                    case .rightMouseDragged:
                        self.mouseDown(control: .leftMouse, eventLocation: location, size: geo.size)
                    case .rightMouseDown:
                        self.mouseDown(control: .rightMouse, eventLocation: location, size: geo.size)

                    case .keyDown:
                        GameLogger.debug("keydown not implemented", category: .ui)
                        self.keyDown(with: event, location: location)
                    case .otherMouseDown:
                        self.mouseDown(control: .otherMouse, eventLocation: location, size: geo.size)
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
        GameLogger.debug("mouse down location \(location)", category: .ui)
        keymapController.execute(control, location: location)
    }

    func keyDown(with event: NSEvent, location: CGPoint) {
        GameLogger.debug("TacticalScene.keyDown characters \(String(describing: event.characters))", category: .ui)

        switch event.characters?.first {
        case "0":
            keymapController.execute(.zeroKey, location: location)
        case "1":
            keymapController.execute(.oneKey, location: location)
        case "2":
            keymapController.execute(.twoKey, location: location)
        case "3":
            keymapController.execute(.threeKey, location: location)
        case "4":
            keymapController.execute(.fourKey, location: location)
        case "5":
            keymapController.execute(.fiveKey, location: location)
        case "6":
            keymapController.execute(.sixKey, location: location)
        case "7":
            keymapController.execute(.sevenKey, location: location)
        case "8":
            keymapController.execute(.eightKey, location: location)
        case "9":
            keymapController.execute(.nineKey, location: location)
        case ")":
            keymapController.execute(.rightParenKey, location: location)
        case "!": keymapController.execute(.exclamationMarkKey, location: location)
        case "@": keymapController.execute(.atKey, location: location)
        case "%": keymapController.execute(.percentKey, location: location)
        case "#": keymapController.execute(.poundKey, location: location)
        case "<":
            keymapController.execute(.lessThanKey, location: location)
        case ">":
            keymapController.execute(.greaterThanKey, location: location)
        case "]":
            keymapController.execute(.rightBracketKey, location: location)
        case "[":
            keymapController.execute(.leftBracketKey, location: location)
        case "{":
            keymapController.execute(.leftCurly, location: location)
        case "}":
            keymapController.execute(.rightCurly, location: location)
        case "_":
            keymapController.execute(.underscore, location: location)
        case "^":
            keymapController.execute(.carrot, location: location)
        case "$":
            keymapController.execute(.dollar, location: location)
        case ";":
            keymapController.execute(.semicolon, location: location)
        case "a":
            keymapController.execute(.aKey, location: location)
        case "b":
            keymapController.execute(.bKey, location: location)
        case "c":
            keymapController.execute(.cKey, location: location)
        case "d":
            keymapController.execute(.dKey, location: location)
        case "e":
            keymapController.execute(.eKey, location: location)
        case "f":
            keymapController.execute(.fKey, location: location)
        case "g":
            keymapController.execute(.gKey, location: location)
        case "h":
            keymapController.execute(.hKey, location: location)
        case "i":
            keymapController.execute(.iKey, location: location)
        case "j":
            keymapController.execute(.jKey, location: location)
        case "k":
            keymapController.execute(.kKey, location: location)
        case "l":
            keymapController.execute(.lKey, location: location)
        case "m":
            keymapController.execute(.mKey, location: location)
        case "n":
            keymapController.execute(.nKey, location: location)
        case "o":
            keymapController.execute(.oKey, location: location)
        case "p":
            keymapController.execute(.pKey, location: location)
        case "q":
            keymapController.execute(.qKey, location: location)
        case "r":
            keymapController.execute(.rKey, location: location)
        case "s":
            keymapController.execute(.sKey, location: location)
        case "t":
            keymapController.execute(.tKey, location: location)
        case "u":
            keymapController.execute(.uKey, location: location)
        case "v":
            keymapController.execute(.vKey, location: location)
        case "w":
            keymapController.execute(.wKey, location: location)
        case "x":
            keymapController.execute(.xKey, location: location)
        case "y":
            keymapController.execute(.yKey, location: location)
        case "z":
            keymapController.execute(.zKey, location: location)
        case "A":
            keymapController.execute(.AKey, location: location)
        case "B":
            keymapController.execute(.BKey, location: location)
        case "C":
            keymapController.execute(.CKey, location: location)
        case "D":
            keymapController.execute(.DKey, location: location)
        case "E":
            keymapController.execute(.EKey, location: location)
        case "F":
            keymapController.execute(.FKey, location: location)
        case "G":
            keymapController.execute(.GKey, location: location)
        case "H":
            keymapController.execute(.HKey, location: location)
        case "I":
            keymapController.execute(.IKey, location: location)
        case "J":
            keymapController.execute(.JKey, location: location)
        case "K":
            keymapController.execute(.KKey, location: location)
        case "L":
            keymapController.execute(.LKey, location: location)
        case "M":
            keymapController.execute(.MKey, location: location)
        case "N":
            keymapController.execute(.NKey, location: location)
        case "O":
            keymapController.execute(.OKey, location: location)
        case "P":
            keymapController.execute(.PKey, location: location)
        case "Q":
            keymapController.execute(.QKey, location: location)
        case "R":
            keymapController.execute(.RKey, location: location)
        case "S":
            keymapController.execute(.SKey, location: location)
        case "T":
            keymapController.execute(.TKey, location: location)
        case "U":
            keymapController.execute(.UKey, location: location)
        case "V":
            keymapController.execute(.VKey, location: location)
        case "W":
            keymapController.execute(.WKey, location: location)
        case "X":
            keymapController.execute(.XKey, location: location)
        case "Y":
            keymapController.execute(.YKey, location: location)
        case "Z":
            keymapController.execute(.ZKey, location: location)
        case "*":
            keymapController.execute(.asteriskKey, location: location)
        case " ":
            keymapController.execute(.spacebarKey, location: location)
        default:
            GameLogger.debug("TacticalScene.TacticalView.keyDown unknown key \(String(describing: event.characters))", category: .ui)
        }
    }
}

#if DEBUG
#Preview {
    let _ = PreviewHelpers.setupPreviewUniverse()
    let universe = Universe.universe

    return TacticalView(
        help: Help(),
        preferencesController: PreferencesController(defaults: .standard)
    )
    .environmentObject(universe)
    .frame(width: PreviewHelpers.screenWidthMac, height: PreviewHelpers.screenHeightMac)
}
#endif
