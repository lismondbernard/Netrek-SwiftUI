//
//  GameControllerInputState.swift
//  Netrek
//
//  Created by Claude on 1/23/26.
//  Copyright © 2026 Network Mom LLC. All rights reserved.
//

import Foundation
import CoreGraphics

/// Tracks the current state of analog stick inputs from game controllers
class GameControllerInputState {

    /// Dead zone threshold - inputs below this magnitude are ignored
    static let deadZone: Float = 0.15

    /// Left stick X axis value (-1.0 to 1.0)
    var leftStickX: Float = 0.0

    /// Left stick Y axis value (-1.0 to 1.0)
    var leftStickY: Float = 0.0

    /// Right stick X axis value (-1.0 to 1.0)
    var rightStickX: Float = 0.0

    /// Right stick Y axis value (-1.0 to 1.0)
    var rightStickY: Float = 0.0

    /// D-pad X axis value (-1.0 to 1.0)
    var dpadX: Float = 0.0

    /// D-pad Y axis value (-1.0 to 1.0)
    var dpadY: Float = 0.0

    /// Current aim location calculated from right stick (in Netrek coordinates)
    var currentAimLocation: CGPoint?

    /// Returns true if the left stick is outside the dead zone
    var leftStickActive: Bool {
        let magnitude = sqrt(leftStickX * leftStickX + leftStickY * leftStickY)
        return magnitude > GameControllerInputState.deadZone
    }

    /// Returns true if the right stick is outside the dead zone
    var rightStickActive: Bool {
        let magnitude = sqrt(rightStickX * rightStickX + rightStickY * rightStickY)
        return magnitude > GameControllerInputState.deadZone
    }

    /// Returns true if the D-pad has any input
    var dpadActive: Bool {
        return abs(dpadX) > 0.1 || abs(dpadY) > 0.1
    }

    /// Resets all input state to neutral
    func reset() {
        leftStickX = 0.0
        leftStickY = 0.0
        rightStickX = 0.0
        rightStickY = 0.0
        dpadX = 0.0
        dpadY = 0.0
        currentAimLocation = nil
    }
}
