//
//  GameTimerManager.swift
//  Netrek2
//
//  Created by Claude Code on 1/18/26.
//  Manages the 20Hz game update loop
//

import Foundation
import SwiftUI
import Combine

@MainActor
class GameTimerManager: ObservableObject {

    private var timer: Timer?
    private var timerCount = 0
    private let timerInterval: TimeInterval

    // Dependencies
    weak var gameStateManager: GameStateManager?
    weak var connectionManager: ServerConnectionManager?

    init(updateRate: Int = UPDATE_RATE) {
        self.timerInterval = 1.0 / Double(updateRate)
    }

    // Start the game timer
    func startTimer() {
        guard timer == nil else {
            GameLogger.debug("GameTimerManager: Timer already running", category: .performance)
            return
        }

        GameLogger.debug("GameTimerManager: Starting timer at \(1.0/timerInterval)Hz", category: .performance)

        timer = Timer(
            timeInterval: timerInterval,
            target: self,
            selector: #selector(timerFired),
            userInfo: nil,
            repeats: true
        )
        timer?.tolerance = timerInterval / 10.0

        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    // Stop the game timer
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerCount = 0
        GameLogger.debug("GameTimerManager: Timer stopped", category: .performance)
    }

    // Timer callback - runs at 20Hz
    @objc private func timerFired() {
        timerCount += 1

        // Update Universe seconds once per second
        if timerCount % Int(UPDATE_RATE) == 0 {
            Universe.universe.seconds.increment()
        }

        // Send periodic updates in gameActive state
        if let state = gameStateManager?.gameState {
            switch state {
            case .gameActive:
                // Send cpUpdate once every 10 seconds to prevent ghostbust
                if (timerCount % 100) == 0 {
                    let cpUpdates = MakePacket.cpUpdates()
                    connectionManager?.reader?.send(content: cpUpdates)
                }
            default:
                break
            }
        }
    }
}
