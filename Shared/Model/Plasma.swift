//
//  Plasma.swift
//  Netrek
//
//  Created by Darrell Root on 3/5/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation
import SwiftUI

class Plasma: ObservableObject, PlasmaProviding {
    // AppDelegate access removed in Phase 3.1 - models should not access app delegate

    private(set) var plasmaId: Int
    private(set) var status = 0
    private(set) var war: [Team: Bool] = [:]
    private(set) var directionNetrek = 0
    private(set) var direction = 0.0
    private(set) var positionX = 0
    private(set) var positionY = 0
    var color = Color.red

    private var soundPlayed = false

    init(plasmaId: Int) {
        self.plasmaId = plasmaId
    }
    func reset() {
        self.positionX = 0
        self.positionY = 0
        self.status = 0
    }

    // from SP_PLASMA_INFO 8
    func update(plasmaId: Int, war: UInt8, status: Int) {
        DispatchQueue.main.async {
            self.plasmaId = plasmaId
            for team in Team.allCases {
                if UInt8(team.rawValue) & war != 0 {
                    self.war[team] = true
                } else {
                    self.war[team] = false
                }
            }
            if let myPlayer = Universe.universe.players[safe: Universe.universe.me] {
                let myTeam = myPlayer.team
                if self.war[myTeam] == true {
                    self.color = Color.red
                } else {
                    self.color = Color.green
                }
            }
            self.status = status
            if status == 1 {
                self.soundPlayed = false
            }
        }
    }
    // from SP_PLASMA 9
    func update(positionX: Int, positionY: Int) {
        DispatchQueue.main.async {
            self.positionX = positionX
            self.positionY = positionY
            if self.soundPlayed == false {
                let me = Universe.universe.me
                guard let myPlayer = Universe.universe.players[safe: me] else { return }
                let taxiDistance = abs(myPlayer.positionX - self.positionX) + abs(myPlayer.positionY - self.positionY)
                if taxiDistance < NetrekMath.displayDistance / 3 {
                    let volume = 1.0 - (3.0 * Float(taxiDistance) / (NetrekMath.displayDistanceFloat))
                    SoundController.soundController.play(sound: .plasma, volume: volume)
                    GameLogger.debug("playing plasma sound volume \(volume)", category: .gameState)
                    self.soundPlayed = true
                }
            }
        }
    }
}
