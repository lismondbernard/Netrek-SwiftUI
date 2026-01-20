//
//  Laser.swift
//  Netrek
//
//  Created by Darrell Root on 3/5/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation
import SwiftUI

class Laser: ObservableObject, LaserProviding {
    // AppDelegate access removed in Phase 3.1 - models should not access app delegate

    private(set) var laserId: Int
    private(set) var status = 0
    private(set) var directionNetrek: UInt8 = 0 // 256= full circle
    private(set) var direction = 0.0 // radians
    private(set) var positionX = 0
    private(set) var positionY = 0
    private(set) var targetPositionX = 0
    private(set) var targetPositionY = 0
    private(set) var target = 0
    let laserRange = 600.0 // game units

    init(laserId: Int) {
        self.laserId = laserId
    }

    func reset() {
        self.positionX = 0
        self.positionY = 0
        self.targetPositionX = 0
        self.targetPositionY = 0
        self.status = 0
    }

    func update(laserId: Int, status: Int, directionNetrek: UInt8, positionX: Int, positionY: Int, target: Int) {
        DispatchQueue.main.async {
            self.laserId = laserId
            self.status = status
            self.directionNetrek = directionNetrek
            self.direction = 2.0 * Double.pi * Double(directionNetrek) / 256.0
            if let player = Universe.universe.players[safe: laserId] {
                self.positionX = player.positionX
                self.positionY = player.positionY
            }
            self.target = target
            if self.status != 0 {
                self.displayLaser()
            }
        }
    }
    func displayLaser() {
        guard let source = Universe.universe.players[safe: self.laserId] else { return }
        let me = Universe.universe.me
        guard let myPlayer = Universe.universe.players[safe: me] else { return }
        let taxiDistance = abs(myPlayer.positionX - source.positionX) + abs(myPlayer.positionY - source.positionY)
        guard taxiDistance < NetrekMath.displayDistance / 2 else { return }
        let volume = 1.0 - (2.0 * Float(taxiDistance) / (NetrekMath.displayDistanceFloat))
        SoundController.soundController.play(sound: .laser, volume: volume)
        switch self.status {
        case 1: // hit
            guard let target = Universe.universe.players[safe: target] else {
                return
            }
            self.targetPositionX = target.positionX
            self.targetPositionY = target.positionY
        case 2: // miss
            self.direction = NetrekMath.directionNetrek2radian(self.directionNetrek)
            self.targetPositionX = Int(Double(source.positionX) + cos(self.direction) * laserRange)
            self.targetPositionY = Int(Double(source.positionY) + sin(self.direction) * laserRange)
        case 4: // hit plasma
            guard let target = Universe.universe.plasmas[safe: target] else {
                return
            }
            self.targetPositionX = target.positionX
            self.targetPositionY = target.positionY

        default: // should not get here
            GameLogger.debug("Laser.displayLaser invalid status \(status)", category: .gameState)
        }
    }
}
