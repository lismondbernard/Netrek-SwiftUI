//
//  MockPlasma.swift
//  Netrek
//
//  Mock implementation of PlasmaProviding for previews and testing
//

import Foundation
import SwiftUI

#if DEBUG
class MockPlasma: PlasmaProviding {
    let plasmaId: Int
    @Published var status: Int
    @Published var positionX: Int
    @Published var positionY: Int
    @Published var color: Color

    init(
        plasmaId: Int = 0,
        status: Int = 1,
        positionX: Int = 5000,
        positionY: Int = 5000,
        color: Color = .green
    ) {
        self.plasmaId = plasmaId
        self.status = status
        self.positionX = positionX
        self.positionY = positionY
        self.color = color
    }

    // MARK: - Factory Methods

    /// Creates an active friendly plasma torpedo
    static func friendly(plasmaId: Int = 0, positionX: Int = 5200, positionY: Int = 5000) -> MockPlasma {
        MockPlasma(
            plasmaId: plasmaId,
            status: 1,
            positionX: positionX,
            positionY: positionY,
            color: .green
        )
    }

    /// Creates an active enemy plasma torpedo
    static func enemy(plasmaId: Int = 1, positionX: Int = 4800, positionY: Int = 5000) -> MockPlasma {
        MockPlasma(
            plasmaId: plasmaId,
            status: 1,
            positionX: positionX,
            positionY: positionY,
            color: .red
        )
    }

    /// Creates an exploding plasma torpedo
    static func exploding(plasmaId: Int = 0, positionX: Int = 5000, positionY: Int = 5000) -> MockPlasma {
        MockPlasma(
            plasmaId: plasmaId,
            status: 2, // 2 = exploding
            positionX: positionX,
            positionY: positionY,
            color: .orange
        )
    }

    /// Creates an inactive plasma torpedo
    static func inactive(plasmaId: Int = 0) -> MockPlasma {
        MockPlasma(
            plasmaId: plasmaId,
            status: 0,
            positionX: 0,
            positionY: 0,
            color: .clear
        )
    }
}
#endif
