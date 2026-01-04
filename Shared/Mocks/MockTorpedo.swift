//
//  MockTorpedo.swift
//  Netrek
//
//  Mock implementation of TorpedoProviding for previews and testing
//

import Foundation
import SwiftUI

#if DEBUG
class MockTorpedo: TorpedoProviding {
    let torpedoId: Int
    @Published var status: UInt8
    @Published var positionX: Int
    @Published var positionY: Int
    @Published var color: Color

    init(
        torpedoId: Int = 0,
        status: UInt8 = 1,
        positionX: Int = 5000,
        positionY: Int = 5000,
        color: Color = .green
    ) {
        self.torpedoId = torpedoId
        self.status = status
        self.positionX = positionX
        self.positionY = positionY
        self.color = color
    }

    // MARK: - Factory Methods

    /// Creates an active friendly torpedo
    static func friendly(torpedoId: Int = 0, positionX: Int = 5100, positionY: Int = 5000) -> MockTorpedo {
        MockTorpedo(
            torpedoId: torpedoId,
            status: 1,
            positionX: positionX,
            positionY: positionY,
            color: .green
        )
    }

    /// Creates an active enemy torpedo
    static func enemy(torpedoId: Int = 8, positionX: Int = 4900, positionY: Int = 5000) -> MockTorpedo {
        MockTorpedo(
            torpedoId: torpedoId,
            status: 1,
            positionX: positionX,
            positionY: positionY,
            color: .red
        )
    }

    /// Creates an exploding torpedo
    static func exploding(torpedoId: Int = 0, positionX: Int = 5000, positionY: Int = 5000) -> MockTorpedo {
        MockTorpedo(
            torpedoId: torpedoId,
            status: 2, // 2 = exploding
            positionX: positionX,
            positionY: positionY,
            color: .yellow
        )
    }

    /// Creates an inactive torpedo
    static func inactive(torpedoId: Int = 0) -> MockTorpedo {
        MockTorpedo(
            torpedoId: torpedoId,
            status: 0,
            positionX: 0,
            positionY: 0,
            color: .clear
        )
    }

    /// Creates a spread of friendly torpedoes
    static func friendlySpread(startId: Int = 0, centerX: Int = 5000, centerY: Int = 5000) -> [MockTorpedo] {
        return (0..<8).map { i in
            let angle = Double(i) * Double.pi / 4
            let distance = 100 + i * 50
            return MockTorpedo(
                torpedoId: startId + i,
                status: 1,
                positionX: centerX + Int(cos(angle) * Double(distance)),
                positionY: centerY + Int(sin(angle) * Double(distance)),
                color: .green
            )
        }
    }
}
#endif
