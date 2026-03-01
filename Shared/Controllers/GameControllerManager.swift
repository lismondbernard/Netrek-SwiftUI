//
//  GameControllerManager.swift
//  Netrek
//
//  Created by Claude on 1/23/26.
//  Copyright © 2026 Network Mom LLC. All rights reserved.
//

import Foundation
import GameController
import CoreGraphics

#if os(macOS)
import Cocoa
#elseif os(iOS)
import UIKit
#endif

/// Manages MFI game controller connections and input handling for Netrek
class GameControllerManager: ObservableObject {

    /// Singleton instance
    static let shared = GameControllerManager()

    /// Whether a game controller is currently connected
    @Published var isControllerConnected: Bool = false

    /// Dependencies for command execution and game state
    weak var keymapController: KeymapController?
    weak var gameStateProvider: (any GameStateProviding)?

    /// Current input state from analog sticks
    let inputState = GameControllerInputState()

    /// Currently connected controller
    private(set) var connectedController: GCController?

    /// Timer for processing continuous analog input at 20Hz
    private var inputTimer: Timer?

    /// Timer interval matching game update rate
    private let timerInterval = 1.0 / Double(UPDATE_RATE)

    private init() {
        setupNotifications()
    }

    deinit {
        stopInputTimer()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    /// Subscribe to controller connect/disconnect notifications
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect),
            name: .GCControllerDidConnect,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidDisconnect),
            name: .GCControllerDidDisconnect,
            object: nil
        )

        // Check for already connected controllers
        if let controller = GCController.controllers().first {
            connectController(controller)
        }
    }

    // MARK: - Controller Connection

    @objc private func controllerDidConnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        debugPrint("GameControllerManager: Controller connected - \(controller.vendorName ?? "Unknown")")
        connectController(controller)
    }

    @objc private func controllerDidDisconnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        debugPrint("GameControllerManager: Controller disconnected - \(controller.vendorName ?? "Unknown")")

        if connectedController === controller {
            disconnectController()
        }
    }

    private func connectController(_ controller: GCController) {
        connectedController = controller
        setupControllerHandlers(controller)
        startInputTimer()
        DispatchQueue.main.async {
            self.isControllerConnected = true
        }
        Universe.universe.gotMessage("Game controller connected: \(controller.vendorName ?? "Unknown")")
    }

    private func disconnectController() {
        stopInputTimer()
        inputState.reset()
        connectedController = nil
        DispatchQueue.main.async {
            self.isControllerConnected = false
        }
        Universe.universe.gotMessage("Game controller disconnected")
    }

    // MARK: - Controller Handlers

    private func setupControllerHandlers(_ controller: GCController) {
        guard let gamepad = controller.extendedGamepad else {
            debugPrint("GameControllerManager: Controller does not have extended gamepad profile")
            return
        }

        // A Button - Fire Torpedo
        gamepad.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                self?.executeCommand(.fireTorpedo, withAim: true)
            }
        }

        // B Button - Fire Laser/Phaser
        gamepad.buttonB.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                self?.executeCommand(.fireLaser, withAim: true)
            }
        }

        // X Button - Toggle Shields
        gamepad.buttonX.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                self?.executeCommand(.toggleShields, withAim: false)
            }
        }

        // Y Button - Toggle Cloak
        gamepad.buttonY.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                self?.executeCommand(.cloak, withAim: false)
            }
        }

        // Left Shoulder - Decrease Speed
        gamepad.leftShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                self?.executeCommand(.speedDecrease, withAim: false)
            }
        }

        // Right Shoulder - Increase Speed
        gamepad.rightShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                self?.executeCommand(.speedIncrease, withAim: false)
            }
        }

        // Left Trigger - Detonate Enemy Torps
        gamepad.leftTrigger.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                self?.executeCommand(.detEnemy, withAim: false)
            }
        }

        // Right Trigger - Fire Plasma
        gamepad.rightTrigger.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed {
                self?.executeCommand(.firePlasma, withAim: true)
            }
        }

        // Left Stick - continuous course input (handled in timer)
        gamepad.leftThumbstick.valueChangedHandler = { [weak self] _, xValue, yValue in
            self?.inputState.leftStickX = xValue
            self?.inputState.leftStickY = yValue
        }

        // Right Stick - continuous aim input (handled in timer)
        gamepad.rightThumbstick.valueChangedHandler = { [weak self] _, xValue, yValue in
            self?.inputState.rightStickX = xValue
            self?.inputState.rightStickY = yValue
        }

        // D-Pad - alternative course input (handled in timer)
        gamepad.dpad.valueChangedHandler = { [weak self] _, xValue, yValue in
            self?.inputState.dpadX = xValue
            self?.inputState.dpadY = yValue
        }
    }

    // MARK: - Input Timer

    private func startInputTimer() {
        stopInputTimer()
        inputTimer = Timer.scheduledTimer(
            timeInterval: timerInterval,
            target: self,
            selector: #selector(processAnalogInput),
            userInfo: nil,
            repeats: true
        )
        inputTimer?.tolerance = timerInterval / 10.0
        if let timer = inputTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    private func stopInputTimer() {
        inputTimer?.invalidate()
        inputTimer = nil
    }

    @objc private func processAnalogInput() {
        guard gameStateProvider?.gameState == .gameActive else { return }

        // Process left stick for course setting
        if inputState.leftStickActive {
            setCourseFromStick(x: inputState.leftStickX, y: inputState.leftStickY)
        }
        // Process D-pad as alternative course input
        else if inputState.dpadActive {
            setCourseFromStick(x: inputState.dpadX, y: inputState.dpadY)
        }

        // Update aim location from right stick
        if inputState.rightStickActive {
            updateAimLocation()
        } else {
            inputState.currentAimLocation = nil
        }
    }

    // MARK: - Command Execution

    /// Execute a game command, optionally using the current aim direction
    private func executeCommand(_ command: Command, withAim: Bool) {
        guard gameStateProvider?.gameState == .gameActive else { return }

        let location: CGPoint?
        if withAim {
            location = calculateAimLocation()
        } else {
            location = nil
        }

        DispatchQueue.main.async { [weak self] in
            self?.keymapController?.execute(command, location: location)
        }
    }

    /// Set course based on stick direction
    private func setCourseFromStick(x: Float, y: Float) {
        let location = calculateTargetLocation(x: x, y: y)
        DispatchQueue.main.async { [weak self] in
            self?.keymapController?.execute(.setCourse, location: location)
        }
    }

    /// Calculate a target location based on stick input and player position
    private func calculateTargetLocation(x: Float, y: Float) -> CGPoint {
        let me = Universe.universe.me
        let player = Universe.universe.players[me]

        // Convert stick direction to a point offset from player position
        // Netrek uses screen coordinates (Y increases downward)
        // GameController: stick up = +Y, stick down = -Y
        // So we negate X to match screen orientation, Y maps directly
        let distance: Float = 5000.0 // Arbitrary distance for direction calculation
        let targetX = Float(player.positionX) + (x * distance)
        let targetY = Float(player.positionY) + (y * distance)

        return CGPoint(x: CGFloat(targetX), y: CGFloat(targetY))
    }

    /// Update the aim location from right stick
    private func updateAimLocation() {
        if inputState.rightStickActive {
            inputState.currentAimLocation = calculateTargetLocation(
                x: inputState.rightStickX,
                y: inputState.rightStickY
            )
        }
    }

    /// Calculate aim location for weapon firing
    private func calculateAimLocation() -> CGPoint {
        // If right stick has active input, use that for aiming
        if inputState.rightStickActive {
            return calculateTargetLocation(
                x: inputState.rightStickX,
                y: inputState.rightStickY
            )
        }

        // Otherwise, use left stick direction or D-pad if active
        if inputState.leftStickActive {
            return calculateTargetLocation(
                x: inputState.leftStickX,
                y: inputState.leftStickY
            )
        }

        if inputState.dpadActive {
            return calculateTargetLocation(
                x: inputState.dpadX,
                y: inputState.dpadY
            )
        }

        // Fallback: aim in current ship direction (forward from player)
        let me = Universe.universe.me
        let player = Universe.universe.players[me]

        // Use player's current direction - convert Netrek direction (0-255) to radians
        let netrekDirection = Double(player.direction)
        let radians = (netrekDirection / 256.0) * 2.0 * Double.pi - Double.pi / 2.0

        let distance: Double = 5000.0
        let targetX = Double(player.positionX) + cos(radians) * distance
        let targetY = Double(player.positionY) + sin(radians) * distance

        return CGPoint(x: targetX, y: targetY)
    }
}
