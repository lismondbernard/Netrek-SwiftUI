//
//  MockLaser.swift
//  Netrek
//
//  Mock implementation of LaserProviding for previews and testing
//

import Foundation
import SwiftUI

#if DEBUG
class MockLaser: LaserProviding {
    let laserId: Int
    @Published var status: Int
    @Published var positionX: Int
    @Published var positionY: Int
    @Published var targetPositionX: Int
    @Published var targetPositionY: Int

    init(
        laserId: Int = 0,
        status: Int = 1,
        positionX: Int = 5000,
        positionY: Int = 5000,
        targetPositionX: Int = 5500,
        targetPositionY: Int = 5000
    ) {
        self.laserId = laserId
        self.status = status
        self.positionX = positionX
        self.positionY = positionY
        self.targetPositionX = targetPositionX
        self.targetPositionY = targetPositionY
    }

    // MARK: - Factory Methods

    /// Creates a laser that hit a target
    static func hit(laserId: Int = 0, sourceX: Int = 5000, sourceY: Int = 5000, targetX: Int = 5400, targetY: Int = 5000) -> MockLaser {
        MockLaser(
            laserId: laserId,
            status: 1, // 1 = hit
            positionX: sourceX,
            positionY: sourceY,
            targetPositionX: targetX,
            targetPositionY: targetY
        )
    }

    /// Creates a laser that missed
    static func miss(laserId: Int = 0, sourceX: Int = 5000, sourceY: Int = 5000, direction: Double = 0) -> MockLaser {
        let laserRange = 600.0
        return MockLaser(
            laserId: laserId,
            status: 2, // 2 = miss
            positionX: sourceX,
            positionY: sourceY,
            targetPositionX: sourceX + Int(cos(direction) * laserRange),
            targetPositionY: sourceY + Int(sin(direction) * laserRange)
        )
    }

    /// Creates an inactive laser
    static func inactive(laserId: Int = 0) -> MockLaser {
        MockLaser(
            laserId: laserId,
            status: 0,
            positionX: 0,
            positionY: 0,
            targetPositionX: 0,
            targetPositionY: 0
        )
    }
}
#endif
